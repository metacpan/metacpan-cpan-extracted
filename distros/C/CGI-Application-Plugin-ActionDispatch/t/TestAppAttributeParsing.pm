package TestAppAttributeParsing;

use base 'CGI::Application';
use CGI::Application::Plugin::ActionDispatch;

@TestApp::ISA = qw(CGI::Application);

sub single_quotes_space : Path( '/single_quotes_space' ) {
	my $self = shift;
	return "Runmode: single_quotes_space\n";
}

sub double_quotes_space : Path( "/double_quotes_space" ) {
	my $self = shift;
	return "Runmode: double_quotes_space\n";
}

sub single_quotes_tab : Path(	'/single_quotes_tab'	) {
	my $self = shift;
	return "Runmode: single_quotes_tab\n";
}

sub double_quotes_tab : Path(	"/double_quotes_tab"	) {
	my $self = shift;
	return "Runmode: double_quotes_tab\n";
}

sub single_quotes_tab_space : Path(    '/single_quotes_tab_space'     ) {
        my $self = shift;
        return "Runmode: single_quotes_tab_space\n";
}

sub double_quotes_tab_space : Path(    "/double_quotes_tab_space"     ) {
        my $self = shift;
        return "Runmode: double_quotes_tab_space\n";
}


sub failed : Default {
	my $self = shift;
	return "Failed: fell back to default runmode\n";
}
