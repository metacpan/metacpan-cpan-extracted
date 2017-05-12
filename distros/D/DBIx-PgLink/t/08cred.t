use strict;
use Test::More tests => 15;

use lib 't';
use PgLinkTestUtil;

my $dbh = PgLinkTestUtil::connect();

PgLinkTestUtil::init_test();


$dbh->do(<<'END_OF_SQL');
create or replace function test_credentials(_conn_name text, _logon_mode d_logon_mode) 
returns text language plperlu security definer as $body$
  my $conn_name = shift;
  my $logon_mode = shift;
  use DBIx::PgLink::Connector;

  my $conn = DBIx::PgLink::Connector->new(conn_name => $conn_name, no_connect=>1);

  my $cred = $conn->load_credentials($logon_mode);
  return $cred->{remote_user};
$body$;
END_OF_SQL

sub cred {
  scalar($dbh->selectrow_array('SELECT test_credentials(?,?)', {}, @_));
}

sub session_user {
  scalar($dbh->selectrow_array('SELECT session_user'));
}

is(session_user(), $Test->{TEST}->{user}, 'session_user is test user');
is(cred('TEST', 'deny'), undef, 'no mapping, strict logon mode');
is(cred('TEST', 'empty'), '', 'no mapping, use empty');
is(cred('TEST', 'current'), $Test->{TEST}->{user}, 'no mapping, use current user');
is(cred('TEST', 'default'), $Test->{TEST}->{user}, 'no mapping, use default');

$dbh->do(q/set session authorization test_pglink1/);
is(session_user(), 'test_pglink1', 'new session_user set');
is(cred('TEST', 'deny'), 'test_pglink2', 'mapped, strict logon mode');
is(cred('TEST', 'empty'), 'test_pglink2', 'mapped, use empty');
is(cred('TEST', 'current'), 'test_pglink2', 'mapped, use current user');
is(cred('TEST', 'default'), 'test_pglink2', 'mapped, use default');

$dbh->do(q/set session authorization test_pglink2/);
is(session_user(), 'test_pglink2', 'new session_user set');
is(cred('TEST', 'deny'), undef, 'no mapping, strict logon mode');
is(cred('TEST', 'empty'), '', 'no mapping, use empty');
is(cred('TEST', 'current'), 'test_pglink2', 'no mapping, use current user');
is(cred('TEST', 'default'), $Test->{TEST}->{user}, 'no mapping, use default');
