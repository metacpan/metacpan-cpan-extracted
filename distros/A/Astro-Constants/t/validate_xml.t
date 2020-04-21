use strict;
use Test::More;
eval "use XML::LibXML 2.0100";
plan skip_all => "XML::LibXML 2.0100 required for validating PhysicalConstants against the schema" 
	if $@;

my $schema_file = 'data/PhysicalConstants.xsd';
my $xml_file = 'data/PhysicalConstants.xml';
my $schema = XML::LibXML::Schema->new( location => $schema_file );

ok( -f $schema_file, "No schema file at $schema_file");
ok( -f $xml_file, "No xml file at $xml_file");

TODO: {
	local $TODO = 'Correct schema to validate PhysicalConstants.xml';
	eval { $schema->validate( XML::LibXML->load_xml(location => $xml_file) ); };
	ok( ! $@, "Couldn't validate $xml_file against $schema_file");
	# diag $@ if $@;
}

#### Test invalid XML #### 
#
# create xml directory and make one failure per file that the schema
# should catch and use a loop to test all the failure modes
#
# ##

done_testing();
