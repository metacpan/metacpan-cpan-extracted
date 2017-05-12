use Test::More tests => 28;
use DBIx::XMLServer;

require 't/test-utils.pl';

our $db;
get_db();

SKIP: {
  skip "You haven't given me a database to use for testing", 27
    unless $db;

  my $dbh = open_db();

  ok(eval { $xml_server = new DBIx::XMLServer($dbh, 't/t30.xml') },
     "Create DBI::XMLServer object") or diag $@;
  isa_ok($xml_server, 'DBIx::XMLServer');
  
  try_query($xml_server, 'name=John Smith', 't/o30-1.xml');
  try_query($xml_server, 'name=John Sm?th', 't/o30-2.xml');
  try_query($xml_server, 'name=John*', 't/o30-3.xml');
  try_query($xml_server, 'name~Mi(nnie|ckey) Mouse', 't/o30-4.xml');
  try_query($xml_server, 'name', 't/o30-5.xml');
  try_error($xml_server, 'name>2', qr/Unrecognised condition.*>2/);

  close_db();

}

1;
