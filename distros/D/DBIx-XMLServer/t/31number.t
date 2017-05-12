use Test::More tests => 42;
use DBIx::XMLServer;

require 't/test-utils.pl';

our $db;
get_db();

SKIP: {
  skip "You haven't given me a database to use for testing", 41
    unless $db;

  my $dbh = open_db();

  ok(eval { $xml_server = new DBIx::XMLServer($dbh, 't/t31.xml') },
     "Create DBI::XMLServer object") or diag $@;
  isa_ok($xml_server, 'DBIx::XMLServer');
  
  try_query($xml_server, 'name=John Smith', 't/o31-1.xml');
  try_query($xml_server, 'id=2', 't/o31-2.xml');
  try_query($xml_server, 'id>4', 't/o31-3.xml');
  try_query($xml_server, 'id>=4', 't/o31-4.xml');
  try_query($xml_server, 'id<2', 't/o31-5.xml');
  try_query($xml_server, 'id<=2', 't/o31-6.xml');
  try_query($xml_server, 'id=1,3', 't/o31-7.xml');
  try_error($xml_server, 'id=two', qr/Unrecognised number/);
  try_error($xml_server, 'id~7', qr/Unrecognised number condition/);
  try_error($xml_server, 'id>>8', qr/Unrecognised number comparison/);

  close_db();

}

1;
