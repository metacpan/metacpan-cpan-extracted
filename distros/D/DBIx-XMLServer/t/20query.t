use Test::More tests => 33;
use DBIx::XMLServer;

require 't/test-utils.pl';

our $db;
get_db();

SKIP: {
  skip "You haven't given me a database to use for testing", 32
    unless $db;

  my $dbh = open_db();

  ok(eval { $xml_server = new DBIx::XMLServer($dbh, 't/t20.xml') },
     "Create DBI::XMLServer object") or diag $@;
  isa_ok($xml_server, 'DBIx::XMLServer');
  
  try_query($xml_server, '@id>0', 't/o20-1.xml');
  try_query($xml_server, '@id>0&fields=name', 't/o20-2.xml');
  try_query($xml_server, 'department=Widget%20Marketing', 't/o20-3.xml');
  try_query($xml_server, 'department=Widget%20Marketing&fields=name', 
    't/o20-4.xml');
  try_query($xml_server, 'manager=John+Smith&fields=name', 't/o20-5.xml');
  try_query($xml_server, 'name=Ann*', 't/o20-6.xml');
  try_query($xml_server, 'name~M.*Mouse&fields=name', 't/o20-7.xml');

  close_db();

}

1;
