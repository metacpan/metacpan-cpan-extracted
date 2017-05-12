package TestVersion::Schema::Result::Tree;
use base 'DBIx::Class::Core';
use strict;
use warnings;

__PACKAGE__->table('trees');

__PACKAGE__->add_columns(
    "trees_id" => {
        data_type         => 'integer',
        is_auto_increment => 1,
        versioned         => { renamed_from => 'foos_id' }
    },
    "age"   => { data_type => "integer", is_nullable => 1 },
    "width" => { data_type => "integer", is_nullable => 0, default_value => 1 },
    "bars_id" =>
      { data_type => 'integer', is_foreign_key => 1, is_nullable => 1 },
);

__PACKAGE__->set_primary_key('trees_id');

__PACKAGE__->belongs_to( 'bar', 'TestVersion::Schema::Result::Bar',
    'bars_id', );

__PACKAGE__->resultset_attributes(
    { versioned => { since => '0.003', renamed_from => 'foos' } } );

1;
