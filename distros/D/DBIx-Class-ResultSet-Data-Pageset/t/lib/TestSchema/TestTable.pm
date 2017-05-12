package TestSchema::TestTable;

use strict;
use warnings;

use base qw( DBIx::Class );

__PACKAGE__->load_components( qw( Core ) );
__PACKAGE__->table( 'test' );
__PACKAGE__->resultset_class( 'DBIx::Class::ResultSet::Data::Pageset' );
__PACKAGE__->add_columns(
    id => {
        data_type         => 'bigint',
        is_auto_increment => 0,
        is_nullable       => 0,
    },
);

1;
