use Test::More tests => 4;
use Data::Dumper;

BEGIN { $ENV{CAP_DEVPOPUP_EXEC} = 1; }

{
	package My::App;
	use base qw/CGI::Application/;
	use CGI::Application::Plugin::DevPopup;
    use CGI::Application::Plugin::DevPopup::HTTPHeaders;

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
$ENV{HTTP_HOST} = undef; # RT #42315

my $app    = My::App->new;
my $output = $app->run;

like($output, qr/Test 1 report body/, 'Report generated');

like($output, qr/resizable/, 'Window is resizable');
like($output, qr/scrollbars/, 'Window has scrollbars'); # See RT #16012
like($output, qr{\QHTTP_HOST </td><td>  </td>}, 'see http headers, no warning');

__END__
