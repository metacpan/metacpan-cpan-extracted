use strict;
use warnings;

use Data::MARC::Leader;
use English;
use Error::Pure::Utils qw(clean);
use Test::More 'tests' => 18;
use Test::NoWarnings;

# Test.
my $obj = Data::MARC::Leader->new;
isa_ok($obj, 'Data::MARC::Leader');

# Test.
$obj = Data::MARC::Leader->new(
	'bibliographic_level' => 'm',
	'char_coding_scheme' => 'a',
	'data_base_addr' => 541,
	'descriptive_cataloging_form' => 'i',
	'encoding_level' => ' ',
	'impl_def_portion_len' => 0,
	'indicator_count' => 2,
	'length' => 2200,
	'length_of_field_portion_len' => 4,
	'multipart_resource_record_level' => ' ',
	'raw' => '02200cem a2200541 i 4500',
	'starting_char_pos_portion_len' => 5,
	'status' => 'c',
	'subfield_code_count' => 2,
	'type' => 'e',
	'type_of_control' => ' ',
	'undefined' => 0,
);
isa_ok($obj, 'Data::MARC::Leader');

# Test.
eval {
	Data::MARC::Leader->new(
		'bibliographic_level' => 'x',
	);
};
is($EVAL_ERROR, "Parameter 'bibliographic_level' must be one of defined strings.\n",
	"Parameter 'bibliographic_level' must be one of defined strings (x).");
clean();

# Test.
eval {
	Data::MARC::Leader->new(
		'char_coding_scheme' => 'x',
	);
};
is($EVAL_ERROR, "Parameter 'char_coding_scheme' must be one of defined strings.\n",
	"Parameter 'char_coding_scheme' must be one of defined strings (x).");
clean();

# Test.
eval {
	Data::MARC::Leader->new(
		'descriptive_cataloging_form' => 'x',
	);
};
is($EVAL_ERROR, "Parameter 'descriptive_cataloging_form' must be one of defined strings.\n",
	"Parameter 'descriptive_cataloging_form' must be one of defined strings (x).");
clean();

# Test.
eval {
	Data::MARC::Leader->new(
		'encoding_level' => 'x',
	);
};
is($EVAL_ERROR, "Parameter 'encoding_level' must be one of defined strings.\n",
	"Parameter 'encoding_level' must be one of defined strings (x).");
clean();

# Test.
eval {
	Data::MARC::Leader->new(
		'impl_def_portion_len' => 'x',
	);
};
is($EVAL_ERROR, "Parameter 'impl_def_portion_len' must be one of defined strings.\n",
	"Parameter 'impl_def_portion_len' must be one of defined strings (x).");
clean();

# Test.
eval {
	Data::MARC::Leader->new(
		'indicator_count' => 'x',
	);
};
is($EVAL_ERROR, "Parameter 'indicator_count' must be one of defined strings.\n",
	"Parameter 'indicator_count' must be one of defined strings (x).");
clean();

# Test.
eval {
	Data::MARC::Leader->new(
		'length_of_field_portion_len' => 'x',
	);
};
is($EVAL_ERROR, "Parameter 'length_of_field_portion_len' must be one of defined strings.\n",
	"Parameter 'length_of_field_portion_len' must be one of defined strings (x).");
clean();

# Test.
eval {
	Data::MARC::Leader->new(
		'multipart_resource_record_level' => 'x',
	);
};
is($EVAL_ERROR, "Parameter 'multipart_resource_record_level' must be one of defined strings.\n",
	"Parameter 'multipart_resource_record_level' must be one of defined strings (x).");
clean();

# Test.
eval {
	Data::MARC::Leader->new(
		'raw' => 'bad',
	);
};
is($EVAL_ERROR, "Parameter 'raw' has length different than '24'.\n",
	"Parameter 'raw' has length different than '24' (bad).");
clean();

# Test.
eval {
	Data::MARC::Leader->new(
		'starting_char_pos_portion_len' => 'x',
	);
};
is($EVAL_ERROR, "Parameter 'starting_char_pos_portion_len' must be one of defined strings.\n",
	"Parameter 'starting_char_pos_portion_len' must be one of defined strings (x).");
clean();

# Test.
eval {
	Data::MARC::Leader->new(
		'status' => 'x',
	);
};
is($EVAL_ERROR, "Parameter 'status' must be one of defined strings.\n",
	"Parameter 'status' must be one of defined strings (x).");
clean();

# Test.
eval {
	Data::MARC::Leader->new(
		'subfield_code_count' => 'x',
	);
};
is($EVAL_ERROR, "Parameter 'subfield_code_count' must be one of defined strings.\n",
	"Parameter 'subfield_code_count' must be one of defined strings (x).");
clean();

# Test.
eval {
	Data::MARC::Leader->new(
		'type' => 'x',
	);
};
is($EVAL_ERROR, "Parameter 'type' must be one of defined strings.\n",
	"Parameter 'type' must be one of defined strings (x).");
clean();

# Test.
eval {
	Data::MARC::Leader->new(
		'type_of_control' => 'x',
	);
};
is($EVAL_ERROR, "Parameter 'type_of_control' must be one of defined strings.\n",
	"Parameter 'type_of_control' must be one of defined strings (x).");
clean();

# Test.
eval {
	Data::MARC::Leader->new(
		'undefined' => 'x',
	);
};
is($EVAL_ERROR, "Parameter 'undefined' must be one of defined strings.\n",
	"Parameter 'undefined' must be one of defined strings (x).");
clean();
