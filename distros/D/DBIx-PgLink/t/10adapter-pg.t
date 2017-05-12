use strict;
use Test::More tests => 24;
use Test::Exception;

BEGIN {
  use lib 't';
  use_ok('PgLinkTestUtil');
  use_ok('DBIx::PgLink::Adapter');
  use_ok('DBIx::PgLink::Adapter::Pg');
}

# Adapter::Pg subclass

my $db = DBIx::PgLink::Adapter::Pg->new();
ok($db, 'adapter instance created');
isa_ok($db, 'DBIx::PgLink::Adapter');

can_ok($db, 'connect', 'install_roles', 'prepare', 'ping', 'is_disconnected');

ok( 
  $db->connect($Test->{TEST}->{dsn}, $Test->{TEST}->{user}, $Test->{TEST}->{password}, {}),
  'adapter connected'
);
ok(defined $db->dbh, 'attribute dbh exists');
ok($db->ping, 'pinged');

{
  my $sth = $db->prepare("SELECT 'hello, ' || ?");
  ok($sth, 'statement prepared');
  ok($sth->execute('world'), 'statement executed');
  my $value = $sth->fetchrow_array;
  is($value, 'hello, world', 'got the right value');
}

lives_ok { $db->selectrow_array('') } 'empty query string';

# quote
my @quote = do "t/quote-pg";

for my $q (@quote) {
  is( $db->quote($q->{value}), $q->{exp}, 
    "quote " . (defined $q->{value} ? $q->{value} : '<undef>'));
}
