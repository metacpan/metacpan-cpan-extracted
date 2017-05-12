use Test::More tests => 29;
use DBIx::XMLServer;

require 't/test-utils.pl';

our $db;
get_db();

SKIP: {
  skip "You haven't given me a database to use for testing", 28
    unless $db;

  my $dbh = open_db();

  ok(eval { $xml_server = new DBIx::XMLServer($dbh, 't/t45.xml') },
     "Create DBI::XMLServer object") or diag $@;
  isa_ok($xml_server, 'DBIx::XMLServer');
  
  try_query($xml_server, '@id=2&fields=name', 't/o45-1.xml');
  try_query($xml_server, '@id=2&fields=name|department', 't/o45-2.xml');
  try_query($xml_server, '@id=2&fields=name|manager', 't/o45-3.xml');
  try_query($xml_server, '@id=2', 't/o45-4.xml');
  try_query($xml_server, 'department=Widget Marketing', 't/o45-5.xml');
  try_query($xml_server, 'manager=Minnie*', 't/o45-6.xml');

  close_db();

}

1;
