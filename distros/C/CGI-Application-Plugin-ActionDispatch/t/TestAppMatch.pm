package TestAppMatch;

use base 'CGI::Application';
use CGI::Application::Plugin::ActionDispatch;

@TestApp::ISA = qw(CGI::Application);

sub setup {
	my $self = shift;
	$self->mode_param('test_rm');
	$self->run_modes( 
		basic_runmode => 'basic_runmode'
	);
}

sub basic_runmode {
	my $self = shift;
	return "Runmode: basic_runmode\n";
}

sub starter_rm : Default {
	return "Runmode: starter_rm\n";
}

sub products : Runmode {
	my $self = shift;
	return "Runmode: products\n";
}

sub product : Path('products/') {
	my $self = shift;

	my($category, $product) = $self->action_args();
	return "Runmode: product\nCategory: $category\nProduct: $product\n";
}

sub music : Path('products/music/') {
	my $self = shift;
	my $product = $self->action_args();
	return "Runmode: music\nProduct: $product\n";
}

sub beatles : Regex('^/products/music/beatles\/?')  {
	my $self = shift;
	return "Runmode: beatles\n";
}
