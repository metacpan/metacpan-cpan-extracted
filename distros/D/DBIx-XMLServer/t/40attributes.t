use Test::More tests => 19;
use DBIx::XMLServer;

require 't/test-utils.pl';

our $db;
get_db();

SKIP: {
  skip "You haven't given me a database to use for testing", 18
    unless $db;

  my $dbh = open_db();

  ok(eval { $xml_server = new DBIx::XMLServer($dbh, 't/t40.xml') },
     "Create DBI::XMLServer object") or diag $@;
  isa_ok($xml_server, 'DBIx::XMLServer');
  
  try_query($xml_server, 'name=John Smith', 't/o40-1.xml');
  try_query($xml_server, '@id=1', 't/o40-2.xml');
  try_error($xml_server, '@foo=bar', qr/isn't a field/);
  try_error($xml_server, '@name=Fred', qr/Unknown field/);

  close_db();

}

1;
