use Test::More tests => 27;
use DBIx::XMLServer;

require 't/test-utils.pl';

our $db;
get_db();

SKIP: {
  skip "You haven't given me a database to use for testing", 26
    unless $db;

  my $dbh = open_db();

  ok(eval { $xml_server = new DBIx::XMLServer($dbh, 't/t32.xml') },
     "Create DBI::XMLServer object") or diag $@;
  isa_ok($xml_server, 'DBIx::XMLServer');
  
  try_query($xml_server, 'id=1', 't/o32-1.xml');
  try_query($xml_server, 'birthday < 1960', 't/o32-2.xml');
  try_query($xml_server, 'birthday=28 Feb 1976', 't/o32-3.xml');
  try_query($xml_server, 'birthday >= 1960', 't/o32-4.xml');
  try_error($xml_server, 'birthday~bla', qr/Unrecognised date condition/);
  try_error($xml_server, 'birthday=29 Feb 1977', qr/Unrecognised date:/);

  close_db();

}

1;
