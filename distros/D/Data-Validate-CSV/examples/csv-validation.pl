use v5.12;
use strict;
use warnings;

use Data::Validate::CSV;
use Data::Validate::CSV::Types -types;
use Data::Dumper;
use Text::CSV;

my ($CSV, $SCHEMA) = (<<'CSV', <<'JSON');
GID,On Street,Species,Trim Cycle,Inventory Date
1,ADDISON AV,Celtis australis,Large Tree Routine Prune,10/18/2010
2000,EMERSON ST,Liquidambar styraciflua,Large Tree Routine Prune;Watering,6/2/2010
"1",TEST RD,Blah blah,Foo manchu,not a date
CSV
{
  "@context": ["http://www.w3.org/ns/csvw", {"@language": "en"}],
  "url": "tree-ops.csv",
  "dc:title": "Tree Operations",
  "dcat:keyword": ["tree", "street", "maintenance"],
  "dc:publisher": {
    "schema:name": "Example Municipality",
    "schema:url": {"@id": "http://example.org"}
  },
  "dc:license": {"@id": "http://opendefinition.org/licenses/cc-by/"},
  "dc:modified": {"@value": "2010-12-31", "@type": "xsd:date"},
  "tableSchema": {
    "columns": [{
      "name": "GID",
      "titles": ["GID", "Generic Identifier"],
      "dc:description": "An identifier for the operation on a tree.",
      "datatype": { "base": "integer", "maximum": 1000 },
      "required": true
    }, {
      "name": "on_street",
      "titles": "On Street",
      "dc:description": "The street that the tree is on.",
      "datatype": "string"
    }, {
      "name": "species",
      "titles": "Species",
      "dc:description": "The species of the tree.",
      "datatype": "string"
    }, {
      "name": "trim_cycle",
      "titles": "Trim Cycle",
      "dc:description": "The operation performed on the tree.",
      "datatype": "string",
      "separator": ";"
    }, {
      "name": "inventory_date",
      "titles": "Inventory Date",
      "dc:description": "The date of the operation that was performed.",
      "datatype": {"base": "date", "format": "M/d/yyyy"}
    }],
    "primaryKey": ["GID"],
    "aboutUrl": "#gid-{GID}"
  }
}
JSON

my $table = Table->new(
	schema     => \$SCHEMA,
	input      => \$CSV,
	has_header => !!1,
);

for my $row ($table->all_rows) {
	say Dumper [@$row];
	say $row->key_string;
	say Dumper $row->errors;
	say $row->get('species')->value;
}

