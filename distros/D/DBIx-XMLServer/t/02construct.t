use Test::More tests => 17;
BEGIN { 
  use_ok('DBIx::XMLServer');
  use_ok('XML::LibXML');
};

my $dbh = { foo => 'bar' };

# Try passing an XML filename
my $xml_server = new DBIx::XMLServer($dbh, 't/t01.xml');
isa_ok($xml_server, 'DBIx::XMLServer');

# Try passing a ready-parsed document
my $parser = new XML::LibXML;
isa_ok($parser, 'XML::LibXML');
my $doc = $parser->parse_file('t/t01.xml');
isa_ok($doc, 'XML::LibXML::Document');
my ($template) = $doc->documentElement->getChildrenByTagNameNS
  ('http://boojum.org.uk/NS/XMLServer', 'template');
$xml_server = new DBIx::XMLServer($dbh, $doc);
isa_ok($xml_server, 'DBIx::XMLServer');
is($xml_server->{dbh}, $dbh, "dbh is correct");
ok($doc->isSameNode($xml_server->{doc}), "doc is correct");
ok($template->isSameNode($xml_server->{template}), "template is correct");

# Try passing a template element
$xml_server = new DBIx::XMLServer($dbh, $doc, $template);
isa_ok($xml_server, 'DBIx::XMLServer');
is($xml_server->{dbh}, $dbh, "dbh is correct");
ok($doc->isSameNode($xml_server->{doc}), "doc is correct");
ok($template->isSameNode($xml_server->{template}), "template is correct");

# And try it with named arguments
$xml_server = new DBIx::XMLServer(dbh => $dbh,
				  doc => $doc, 
				  template => $template);
isa_ok($xml_server, 'DBIx::XMLServer');
is($xml_server->{dbh}, $dbh, "dbh is correct");
ok($doc->isSameNode($xml_server->{doc}), "doc is correct");
ok($template->isSameNode($xml_server->{template}), "template is correct");

1;
