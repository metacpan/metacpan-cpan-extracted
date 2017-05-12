package TestDB::Snafu;

use strict;
use warnings;
use base 'DBIx::Class';

__PACKAGE__->load_components(qw/InflateColumn::Boolean PK::Auto Core/);
__PACKAGE__->table('snafu');
__PACKAGE__->true_is('Y');
__PACKAGE__->add_columns(
    id => {
        data_type => 'int',
	is_nullable => 0,
	extras => {unsigned => 1 },
	is_auto_increment => 1,
    },
    foo => {
        data_type => 'varchar',
	size => 1,
	is_nullable => 0,
        is_boolean  => 1,
    },
    bar => {
        data_type => 'varchar',
	size => 1,
	is_nullable => 0,
        is_boolean  => 1,
        true_is     => qr/^(?:yes|ja|oui|si)$/i,
    },
    baz => {
        data_type => 'int',
        is_boolean  => 1,
        false_is    => ['0', '-1'],
    },
);

__PACKAGE__->set_primary_key('id');

1;
