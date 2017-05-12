use strict;
use Test::More tests => 24;
use Test::Exception;

BEGIN {
  use lib 't';
  use_ok('PgLinkTestUtil');
  use_ok('DBIx::PgLink::Adapter');
  use_ok('DBIx::PgLink::Adapter::Pg');
}

# base Adapter class
{

  my $db = DBIx::PgLink::Adapter->new();
  ok($db, 'adapter instance created');

  can_ok($db, 'connect', 'install_roles', 'prepare', 'ping');


  ok( 
    $db->connect($Test->{TEST}->{dsn}, $Test->{TEST}->{user}, $Test->{TEST}->{password}, {}),
    'adapter connected'
  );
  ok(defined $db->dbh, 'attribute dbh exists');

  {
    my $sth = $db->prepare("SELECT 'hello, ' || ?");
    ok($sth, 'statement prepared');
    ok($sth->execute('world'), 'statement executed');
    my $value = $sth->fetchrow_array;
    is($value, 'hello, world', 'got the right value');
  }

}

# base Adapter class with run-time roles
{

  my $db = DBIx::PgLink::Adapter::Pg->new();
  ok($db, 'adapter instance created');
  can_ok($db, 'connect', 'install_roles', 'prepare', 'ping');

  lives_ok { $db->install_roles(qw/NestedTransaction StatementCache/); } 'role installed';
  isa_ok($db, 'DBIx::PgLink::Adapter'); # still descendant class

  can_ok($db, 'transaction_counter', 'statement_cache_size');

  ok( 
    $db->connect($Test->{TEST}->{dsn}, $Test->{TEST}->{user}, $Test->{TEST}->{password}, {}),
    'adapter connected'
  );

}

# base Adapter class + TraceDBI
{

  my $db = DBIx::PgLink::Adapter->new();
  ok($db, 'adapter instance created');

  lives_ok { $db->install_roles(qw/TraceDBI/); } 'role installed';

  ok( 
    $db->connect($Test->{TEST}->{dsn}, $Test->{TEST}->{user}, $Test->{TEST}->{password}, {}),
    'adapter connected'
  );

  is( $db->dbi_trace_level, 0, 'get dbi_trace_level');

  is( $db->dbi_trace_level(1), 1, 'set dbi_trace_level');

  is( $db->dbi_trace_level, 1, 'get dbi_trace_level');

  lives_ok { $db->do("SELECT now()") } 'do() traced';

  is( $db->dbi_trace_level(0), 0, 'set dbi_trace_level');

}
