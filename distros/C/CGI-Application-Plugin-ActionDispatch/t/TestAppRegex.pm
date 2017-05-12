package TestAppRegex;

use base 'CGI::Application';
use CGI::Application::Plugin::ActionDispatch;

@TestApp::ISA = qw(CGI::Application);

sub product : Regex('^/products/books/war_and_peace/(\w+)/(\d+)/')  {
	my $self = shift;
	my($ch, $num) = $self->action_args();
	return "Runmode: product\nCategory: books\nProduct: war_and_peace\nArgs: $ch $num\n";
}
