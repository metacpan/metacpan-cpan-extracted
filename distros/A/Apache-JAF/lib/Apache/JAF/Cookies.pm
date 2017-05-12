package Apache::JAF::Cookies;

use Apache;
use Apache::Cookie ();

sub new {
  my $class = shift;
  return bless { r => Apache->request, cookies => Apache::Cookie->fetch() }, $class;
}

sub bake {
  my $self = shift;
  Apache::Cookie->new($self->{r}, @_)->bake();
}

1;
