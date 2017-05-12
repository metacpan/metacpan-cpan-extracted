package TestVersion::Schema::Result::Bar;
use base 'DBIx::Class::Core';
use strict;
use warnings;

__PACKAGE__->table('bars');

__PACKAGE__->add_columns(
    "bars_id" => {
        data_type         => 'integer',
        is_auto_increment => 1,
    },
    "age" => {
        data_type   => "integer",
        is_nullable => 1,
        versioned   => {
            since   => '0.003',
            changes => {
                '0.004' => {
                    data_type     => "integer",
                    is_nullable   => 0,
                    default_value => 18
                },
            }
        }
    },
    "height" => {
        data_type   => "integer",
        is_nullable => 1,
        versioned   => { since => '0.003' }
    },
    "weight" => {
        data_type   => "integer",
        is_nullable => 1,
        versioned   => { until => '0.400' }
    },
);

__PACKAGE__->set_primary_key('bars_id');

__PACKAGE__->has_many(
    trees => 'TestVersion::Schema::Result::Tree',
    'bars_id', { versioned => { since => '0.003' } },
);

__PACKAGE__->resultset_attributes( { versioned => { since => '0.002' } } );

1;
