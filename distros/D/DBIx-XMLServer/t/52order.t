use Test::More tests => 36;
use DBIx::XMLServer;

require 't/test-utils.pl';

our $db;
get_db();

SKIP: {
  skip "You haven't given me a database to use for testing", 35
    unless $db;

  my $dbh = open_db();

  ok(eval { $xml_server = new DBIx::XMLServer($dbh, 't/t52.xml') },
     "Create DBI::XMLServer object") or diag $@;
  isa_ok($xml_server, 'DBIx::XMLServer');
  
  try_query($xml_server, '@id>0&order=name', 't/o52-1.xml');
  try_query($xml_server, '@id>0&order=@id', 't/o52-2.xml');
  try_query($xml_server, '@id>0&order=department,name', 't/o52-3.xml');
  try_query($xml_server, '@id>0&order=name ascending', 't/o52-4.xml');
  try_query($xml_server, '@id>0&order=name descending', 't/o52-5.xml');
  try_query($xml_server, '@id>0&order=department ascending,name descending', 
	't/o52-6.xml');
  try_query($xml_server, '@id>0&order=name|department', 't/o52-7.xml');

  try_error($xml_server, '@id>0&order=foo', qr/Invalid field/);

  close_db();

}

1;
