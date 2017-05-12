use Test::More tests => 1;
use Data::Dumper;

# make sure the outer environment doesn't set our flag
delete $ENV{'CAP_DEVPOPUP_EXEC'};

{
	package My::App;
	use base qw/CGI::Application/;
	use CGI::Application::Plugin::DevPopup;

	sub setup
	{
		my $self = shift;
		$self->add_callback('devpopup_report', 'my_report');
		$self->start_mode('runmode');
		$self->run_modes([ qw/runmode/ ]);
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
	}
}

$ENV{CGI_APP_RETURN_ONLY} = 1;

my $app    = My::App->new;
my $output = $app->run;

unlike($output, qr/Test 1 report body/, 'Report not turned on');

__END__
1..1
ok 1 - Report not turned on
