package AuthServer::Controller::Root;
use Moose;

BEGIN { extends 'Catalyst::Controller' }

sub passthrulogin :Local {
  my($self) = @_;
}

1;
