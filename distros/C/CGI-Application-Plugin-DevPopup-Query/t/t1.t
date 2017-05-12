#!/usr/env perl

# $Id: t1.t 30 2011-06-10 04:48:54Z stro $

use strict;
use warnings;

use Data::Dumper;

BEGIN { $ENV{'CAP_DEVPOPUP_EXEC'} = 1; }

{
    package My::App;
    use base qw/CGI::Application/;
    use CGI;
    use CGI::Application::Plugin::DevPopup;
    use CGI::Application::Plugin::DevPopup::Query;

    sub setup
    {
        my $self = shift;
        $self->add_callback('devpopup_report', 'my_report');
        $self->start_mode('runmode');
        $self->run_modes([ qw/runmode/ ]);

        my $query = CGI->new({'dinosaur' => 'barney'});
        $self->query($query);

        return;
    }

    sub runmode
    {
        my $self = shift;
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
    plan('tests' => 5);

    my $app    = My::App->new();
    my $output = $app->run();

    like($output, qr/Test 1 report body/, 'Report generated');
    like($output, qr!Current\sRun\sMode!x, 'run mode header is here');
    like($output, qr!<h3>runmode</h3>!x, 'runmode value is ok');
    like($output, qr!CGI\sQuery</a>\s-\sCGI\srequest\sparameters!x, 'query header is here');
    like($output, qr!\sdinosaur\s</td><td>\sbarney\s</td></tr>!x, 'query value is ok');
}
