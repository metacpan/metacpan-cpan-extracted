package TestAppPath;

use base 'CGI::Application';
use CGI::Application::Plugin::ActionDispatch;

@TestApp::ISA = qw(CGI::Application);

sub test_rm : Path('/products/music/rolling_stones/') {
  my $self = shift;
  my( @args ) = $self->action_args();
  return "Runmode: test_rm\nArgs: " . join(" ", @args);
}

sub test_rm_exact : Path('products/music/miles_davis') {
  my $self = shift;
  my @args = $self->action_args();
  my $return = join(" ", @args) if @args;
  return "Runmode: test_rm_exact\nArgs: " . $return . "no args";
}

sub test_rm_partial : Path('products/music/beatles') {
  my $self = shift;
  my( @args ) = $self->action_args();
  return "Runmode: test_rm_partial\nArgs: " . join(" ", @args);
}
