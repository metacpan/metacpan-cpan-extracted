package # hide from PAUSE
  Test::Schema::Result::Baz;

use strict;
use warnings;
use parent 'DBIx::Class::Core';

__PACKAGE__->table('baz');
__PACKAGE__->add_columns(
    id => {
        'data_type' => 'integer',
        'is_auto_increment' => 1,
    },
    name => {
        'data_type' => 'varchar',
        'size' => 255,
    },
    description => {
        'data_type' => 'text',
        'is_nullable' => 1,
    },
);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(
    'foo_baz' => 'Test::Schema::Result::FooBaz',
    { 'foreign.baz_id' => 'self.id' },
);
__PACKAGE__->many_to_many('foo_list' => 'foo_baz' => 'foo');

1;
