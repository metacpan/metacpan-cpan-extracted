package TestSchema::TestTable;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/Numeric Core/);

__PACKAGE__->table('TestTable');

__PACKAGE__->add_columns(qw/baz simple with_args/);

__PACKAGE__->set_primary_key(qw/simple/);

__PACKAGE__->numeric_columns(
	baz => {min_value => 5, max_value => 10},
);
__PACKAGE__->numeric_columns('simple', 'with_args' => {max_value => 99});

1;