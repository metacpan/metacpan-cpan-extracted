use Test::More tests => 3;
BEGIN { use_ok('DBIx::XMLServer'); };

my $dbh = { foo => 'bar' };

# Try creating the object without a database handle
my $xml_server = new DBIx::XMLServer($dbh, 't/t01.xml');
isa_ok($xml_server, 'DBIx::XMLServer');

# Try the named parameters form
$xml_server = new DBIx::XMLServer(dbh => $dbh, doc => 't/t01.xml');
isa_ok($xml_server, 'DBIx::XMLServer');

1;
