package Example;

{
  package Example::Log;

  use Moose;
  extends 'Catalyst::Log';

  sub _log { }  # kill errors to STDOUT 

  1;
}

use Catalyst;
use Moose;

__PACKAGE__->setup_plugins([qw//]);
__PACKAGE__->log( Example::Log->new ) unless $ENV{CATALYST_DEBUG};
__PACKAGE__->config();

__PACKAGE__->setup();
__PACKAGE__->meta->make_immutable();
