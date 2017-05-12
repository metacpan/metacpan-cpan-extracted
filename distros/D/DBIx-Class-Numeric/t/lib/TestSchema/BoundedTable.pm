package TestSchema::BoundedTable;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/Numeric Core/);

__PACKAGE__->table('BoundedTable');

__PACKAGE__->add_columns(qw/lower upper both bound_col_1 bound_col_2/);

__PACKAGE__->set_primary_key(qw/lower/);

__PACKAGE__->numeric_columns(
	lower => { lower_bound_col => 'bound_col_1', },
	upper => { upper_bound_col => 'bound_col_2', },
	both  => { lower_bound_col => 'bound_col_1', upper_bound_col => 'bound_col_2' },
);

1;