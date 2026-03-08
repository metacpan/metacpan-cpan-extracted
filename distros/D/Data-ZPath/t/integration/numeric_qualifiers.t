use Test2::V0;
use Test2::Require::Module 'XML::LibXML';

use Data::ZPath;
use XML::LibXML;

my $perl_root = {
	body => {
		table => {
			tr => [ 'row0', 'row1', 'row2' ],
		},
	},
};

my @perl_nodes = Data::ZPath->new('/body/table/tr[1]')->evaluate($perl_root);

is(
	scalar @perl_nodes,
	1,
	'Perl map/list data path resolves to exactly one node',
);

is(
	$perl_nodes[0]->string_value,
	'row1',
	'Perl map/list data uses [1] to pick table/tr child',
);

my $xml_root = XML::LibXML->load_xml(
	string => '<root><body><table><tr>row0</tr><tr>row1</tr><tr>row2</tr></table></body></root>',
);

my @xml_nodes = Data::ZPath->new('/body/table/tr[1]')->evaluate($xml_root);

is(
	scalar @xml_nodes,
	1,
	'XML path resolves to exactly one node',
);

is(
	$xml_nodes[0]->string_value,
	'row1',
	'XML data uses [1] to pick the second <tr> sibling',
);

done_testing;