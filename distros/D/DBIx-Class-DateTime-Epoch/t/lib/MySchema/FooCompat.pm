package MySchema::FooCompat;

use strict;
use warnings;

use base qw( DBIx::Class );

__PACKAGE__->load_components( qw( DateTime::Epoch Core ) );
__PACKAGE__->table( 'foo_compat' );
__PACKAGE__->add_columns(
    id => {
        data_type         => 'bigint',
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    name => {
        data_type   => 'varchar',
        size        => 10,
        is_nullable => 1,
    },
    bar => { # epoch stored as an int
        data_type => 'bigint',
        epoch     => 1,
    },
    baz => { # epoch stored as a string
        data_type => 'varchar',
        size      => 50,
        epoch     => 1,
    },
    # working in conjunction with DBIx::Class::TimeStamp
    creation_time => {
        data_type => 'bigint',
        epoch     => 'ctime',
    },
    modification_time => {
        data_type => 'bigint',
        epoch     => 'mtime',
    }
);

__PACKAGE__->set_primary_key( 'id' );

1;
