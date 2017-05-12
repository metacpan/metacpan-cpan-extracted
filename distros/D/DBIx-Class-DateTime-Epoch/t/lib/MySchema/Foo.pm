package MySchema::Foo;

use strict;
use warnings;

use base qw( DBIx::Class );

__PACKAGE__->load_components( qw( DateTime::Epoch TimeStamp Core ) );
__PACKAGE__->table( 'foo' );
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
        data_type        => 'bigint',
        inflate_datetime => 1,
    },
    baz => { # epoch stored as a string
        data_type        => 'varchar',
        size             => 50,
        inflate_datetime => 'epoch',
    },
    dt => { # regular datetime field -- should not conflict
        data_type => 'datetime',
        inflate_datetime => 1,
    },
    # working in conjunction with DBIx::Class::TimeStamp
    creation_time => {
        data_type        => 'bigint',
        inflate_datetime => 1,
        set_on_create    => 1,
    },
    modification_time => {
        data_type        => 'bigint',
        inflate_datetime => 1,
        set_on_create    => 1,
        set_on_update    => 1,
    }
);

__PACKAGE__->set_primary_key( 'id' );

1;
