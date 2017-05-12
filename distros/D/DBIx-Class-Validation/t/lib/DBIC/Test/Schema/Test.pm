# $Id$
package DBIC::Test::Schema::Test;
use strict;
use warnings;

BEGIN {
    use base qw/DBIx::Class::Core/;
};

__PACKAGE__->load_components(qw/Validation InflateColumn::DateTime PK::Auto Core/);
__PACKAGE__->table('test');
__PACKAGE__->add_columns(
    'id' => {
        data_type => 'int',
        is_nullable => 0,
        is_auto_increment => 1,
    },
    'name' => {
        data_type => 'varchar',
        size => 100,
        is_nullable => 1,
    },
    'email' => {
        data_type => 'varchar',
        size => 100,
        is_nullable => 1,
    },
    'createts' => {
        data_type => 'timestamp',
        size => 14,
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key('id');

1;
