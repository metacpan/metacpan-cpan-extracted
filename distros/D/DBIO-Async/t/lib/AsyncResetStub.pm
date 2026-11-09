package AsyncResetStub;
# The reset a mock transport answers: the session of a released connection is
# "reset" at once. DBIO::Async ships no reset of its own (a driver supplies
# _reset_pool_connection, core k398), so a mock that counts on a connection
# coming back to the pool states it here.
#
#   package MyMock;
#   use base 'DBIO::Async::Storage';
#   use AsyncResetStub;       # installs _reset_pool_connection into MyMock

use strict;
use warnings;

sub import {
  my ($class) = @_;
  my $target = caller;
  no strict 'refs';
  *{"${target}::_reset_pool_connection"} = \&reset_pool_connection;
  return;
}

sub reset_pool_connection {
  my ($self, $conn) = @_;
  return $self->future_class->done;
}

1;
