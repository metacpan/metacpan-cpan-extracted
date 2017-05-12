use Test::More tests => 27;
use DBIx::XMLServer;

require 't/test-utils.pl';

our $db;
get_db();

SKIP: {
  skip "You haven't given me a database to use for testing", 41
    unless $db;

  my $dbh = open_db();

  ok(eval { $xml_server = new DBIx::XMLServer($dbh, 't/t33.xml') },
     "Create DBI::XMLServer object") or diag $@;
  isa_ok($xml_server, 'DBIx::XMLServer');
  
  try_query($xml_server, 'id=1', 't/o33-1.xml');
  try_query($xml_server, 'seen < 2004-10-01', 't/o33-2.xml');
  try_query($xml_server, 'seen=2004-10-01T12:00:00', 't/o33-3.xml');
  try_query($xml_server, 'seen >= 2004-10-01', 't/o33-4.xml');
  try_error($xml_server, 'seen~bla', qr/Unrecognised.*condition/);
  try_error($xml_server, 'seen=29 Feb 1977', qr/Unrecognised date/);

  close_db();

}

1;
