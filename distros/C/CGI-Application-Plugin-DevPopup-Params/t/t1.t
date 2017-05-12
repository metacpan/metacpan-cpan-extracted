#!/usr/env perl

# $Id: t1.t 13 2009-12-04 11:16:01Z stro $

use strict;
use warnings;

use Data::Dumper;

BEGIN { $ENV{'CAP_DEVPOPUP_EXEC'} = 1; }

{
	package My::App;
	use base qw/CGI::Application/;
	use CGI::Application::Plugin::DevPopup;
    use CGI::Application::Plugin::DevPopup::Params;

	sub setup
	{
		my $self = shift;
		$self->add_callback('devpopup_report', 'my_report');
		$self->start_mode('runmode');
		$self->run_modes([ qw/runmode/ ]);
		return;
	}

	sub runmode
	{
		my $self = shift;
		$self->param('ValueOne' => 'KeyOne');
		return '<html><body>Hi there!</body></html>';
	}

	sub my_report
	{
		my $self = shift;
		my $outputref = shift;
		$self->devpopup->add_report(
			title => 'Test 1',
			report => 'Test 1 report body',
		);
		return;
	}
}

$ENV{'CGI_APP_RETURN_ONLY'} = 1;
$ENV{'HTTP_HOST'} = undef; # RT #42315

eval 'use Test::More 0.88';

if (my $msg = $@) {
    # Skip all tests because we need Test::More 0.88
    $msg =~ s/\sat\s.*$//sx;
    print '1..0 # SKIP ', $msg, "\n";
} else {
	plan('tests' => 3);

	my $app    = My::App->new();
	my $output = $app->run();

	like($output, qr/Test 1 report body/, 'Report generated');
	like($output, qr!Parameters</th></thead><tbody>\s<tr><th>param</th><th>value</th></tr>!x, 'header is here');
	like($output, qr!ValueOne\s</td><td>\s+'KeyOne'\s</td></tr>!x, 'value is ok');
}
