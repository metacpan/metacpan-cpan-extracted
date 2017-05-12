#!perl

package CGI::JSONRPC::Dispatcher::Test;

use strict;
use warnings;
use CGI::JSONRPC::Obj;

use base q(CGI::JSONRPC::Obj);

return 1;

sub test_protected : DontDispatch {
  my $self = shift;
  return([$self->{id}, " so there ", @_]);
}

sub test_good {
  my($self, @args) = @_;
  return $self->test_protected(@args);
}
