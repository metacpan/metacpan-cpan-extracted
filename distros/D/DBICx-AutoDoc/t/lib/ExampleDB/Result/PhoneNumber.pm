package # hide from PAUSE
    ExampleDB::Result::PhoneNumber;
use strict;
use warnings;
our $VERSION = 1;
use base qw( DBIx::Class );

__PACKAGE__->load_components(qw( Core ));

__PACKAGE__->table( 'phone_numbers' );
__PACKAGE__->add_columns(
    id          => {
        data_type           => 'integer',
        is_nullable         => 0,
        is_auto_increment   => 1,
    },
    person_id   => {
        data_type           => 'integer',
        is_nullable         => 0,
        is_foreign_key      => 1,
    },
    name        => {
        data_type           => 'varchar',
        size                => 64,
        is_nullable         => 0,
        default_value       => 'Home',
        comment             => 'Home, work, etc',
    },
    phone_number    => {
        data_type           => 'varchar',
        size                => 32,
        is_nullable         => 0,
    },
);
__PACKAGE__->set_primary_key( 'id' );
__PACKAGE__->belongs_to( 'person', 'ExampleDB::Result::Person', 'person_id' );

1;
