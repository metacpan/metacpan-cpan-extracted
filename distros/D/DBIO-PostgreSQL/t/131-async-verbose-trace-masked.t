use strict;
use warnings;
use Test::More;

use DBIO::PostgreSQL::Storage::Async;

# k133: under $Carp::Verbose _pg_raise writes a stack trace; the arguments of
# its frames must not show the password of connect info.

my $secret = 'tr0ub4dor-k133';

sub _connect_like {
  my ($dsn, $user, $pass) = @_;
  DBIO::PostgreSQL::Storage::Async::_pg_raise('connect failed');
}

{
  local $Carp::Verbose = 1;
  eval { _connect_like("dbi:Pg:dbname=x;host=h;password=$secret", 'u', $secret) };
  my $err = $@;
  like $err, qr/connect failed/, 'the message is there';
  like $err, qr/_connect_like/, 'a stack trace was written';
  unlike $err, qr/\Q$secret\E/, 'the password is not in the trace';
}

{
  local $Carp::Verbose = 0;
  eval { _connect_like('dbi:Pg:dbname=x', 'u', $secret) };
  is $@, "connect failed\n", 'without verbose: message and newline only';
}

# k120 (maintainer's decision 2026-10-16): the transport's own refusals are
# DBIO::Exception objects; under $Carp::Verbose their trace is core's
# (DBIO::Exception->throw with a stack trace), and k133 holds for it too. The
# password here is in no DSN a frame shows -- only the answer the refusal is
# about holds it, and a frame of the caller's that has it as a plain value.
# The refusal hands the connect info it was given to the trace, so that one is
# masked as well.
{
  package K133::Answer;
  sub refuse {
    my ($password) = @_;
    DBIO::PostgreSQL::Storage::Async->new(undef)->_pg_broker_conninfo_hash(
      { dbname => '', user => 'app', password => $password },
    );
  }
  sub no_dsn {
    my ($password) = @_;
    DBIO::PostgreSQL::Storage::Async->_pg_connect({ user => 'app', password => $password });
  }
}

for my $way (qw( refuse no_dsn )) {
  local $Carp::Verbose = 1;
  eval { K133::Answer->can($way)->($secret) };
  my $err = $@;
  isa_ok $err, 'DBIO::Exception', "$way under verbose: the refusal";
  like "$err", qr/K133::Answer::\Q$way\E\(/, "$way: ... a stack trace was written, the caller's frame in it";
  unlike "$err", qr/\Q$secret\E/, "$way: ... and the password is not in it";
}

done_testing;
