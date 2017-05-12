use Test::More tests => 32;
use DBIx::XMLServer;

require 't/test-utils.pl';

our $db;
get_db();

SKIP: {
  skip "You haven't given me a database to use for testing", 31
    unless $db;

  my $dbh = open_db();

  ok(eval { $xml_server = new DBIx::XMLServer(
	dbh => $dbh, 
	doc => 't/t51.xml',
        maxpagesize => 3) 
	},
     "Create DBI::XMLServer object") or diag $@;
  isa_ok($xml_server, 'DBIx::XMLServer');
  
  try_query($xml_server, '@id>1', 't/o51-1.xml');
  try_query($xml_server, '@id>1&page=1', 't/o51-2.xml');
  try_query($xml_server, '@id>1&page=2', 't/o51-3.xml');
  try_query($xml_server, '@id>1&pagesize=2', 't/o51-4.xml');
  try_query($xml_server, '@id>1&pagesize=2&page=1', 't/o51-5.xml');
  try_query($xml_server, '@id>1&pagesize=2&page=3', 't/o51-6.xml');
  try_error($xml_server, '@id>1&pagesize=5', qr/Invalid page size/);

  close_db();

}

1;
