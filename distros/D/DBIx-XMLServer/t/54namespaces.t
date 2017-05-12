use Test::More tests => 20;
use DBIx::XMLServer;

require 't/test-utils.pl';

our $db;
get_db();

SKIP: {
  skip "You haven't given me a database to use for testing", 19
    unless $db;

  my $dbh = open_db();

  ok(eval { $xml_server = new DBIx::XMLServer($dbh, 't/t54.xml') },
     "Create DBI::XMLServer object") or diag $@;
  isa_ok($xml_server, 'DBIx::XMLServer');
  
  try_query($xml_server, 'name=John*', 't/o54-1.xml');
  try_query($xml_server, 'm:name=John*', 't/o54-2.xml');
  try_query($xml_server, 'y:login=john', 't/o54-3.xml');
  try_error($xml_server, 'login=john',  qr/Unknown field/);

  close_db();

}

1;
