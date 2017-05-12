use Test::More tests => 27;
use DBIx::XMLServer;

require 't/test-utils.pl';

our $db;
get_db();

SKIP: {
  skip "You haven't given me a database to use for testing", 26
    unless $db;

  my $dbh = open_db();

  ok(eval { $xml_server = new DBIx::XMLServer($dbh, 't/t50.xml') },
     "Create DBI::XMLServer object") or diag $@;
  isa_ok($xml_server, 'DBIx::XMLServer');

  my ($t1, $t2) = $xml_server->{doc}->findnodes('/sql:spec/sql:template');
  isa_ok($t1, 'XML::LibXML::Element');
  isa_ok($t2, 'XML::LibXML::Element');
  ok($t1->getAttributeNS(undef, 'id') eq '1',
     "First template has correct ID");
  ok($t2->getAttributeNS(undef, 'id') eq '2',
     "Second template has correct ID");
  
  try_query($xml_server, 'name=John Smith', 't/o50-1.xml');
  try_query($xml_server, 'name=John Smith', 't/o50-2.xml',
	    template => $t2 );
  try_query($xml_server, 'name=John Smith&format=2', 't/o50-3.xml',
	    userformat => 1 );
  try_error($xml_server, 'name=John Smith&format=3', qr/^Unknown field/);
  try_error($xml_server, 'name=John Smith&format=3', qr/'1', '2'/,
	    userformat => 1 );

  close_db();

}

1;
