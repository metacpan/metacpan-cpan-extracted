use strict;
use Test::More tests => 4;
use Test::Exception;

BEGIN {
  use lib 't';
  use_ok('PgLinkTestUtil');
}

my $dbh = PgLinkTestUtil::connect();
PgLinkTestUtil::init_test();

ok( $dbh->do(<<'END_OF_SQL'), 'create test_connect function');
create or replace function test_connect(_conn_name text) 
returns text language plperlu security definer as $body$
  use strict;
  use DBIx::PgLink;
  my $conn_name = shift;

  my $conn = DBIx::PgLink->connect($conn_name);
  my $result = $conn->adapter->dbh->{Driver}->{Name};
  DBIx::PgLink->disconnect($conn);
  return $result;
$body$;
END_OF_SQL

dies_ok {
  $dbh->selectrow_array('SELECT test_connect(?)', {}, 'dummy');
} 'no such connection';

is(
  scalar($dbh->selectrow_array('SELECT test_connect(?)', {}, 'TEST')), 
  'Pg',
  'connect to TEST'
);
