package # hide from PAUSE
  Test::Schema::Result::Bar;

use strict;
use warnings;
use parent 'DBIx::Class';

__PACKAGE__->load_components(qw/Relationship::Predicate InflateColumn::DateTime Core/);
__PACKAGE__->table('bar');
__PACKAGE__->add_columns(
    name => {
        'data_type' => 'varchar',
        'size' => 255,
    },
    foo_id => { 'data_type' => 'integer' },
    published_at => {
        'data_type' => 'datetime',
        'is_nullable' => 1,
    },
);
__PACKAGE__->set_primary_key('name');

__PACKAGE__->belongs_to(
    'foo' => 'Test::Schema::Result::Foo',
    { 'foreign.id' => 'self.foo_id' }
);

__PACKAGE__->belongs_to(
    'foo_2' => 'Test::Schema::Result::Foo',
    { 'foreign.id' => 'self.foo_id' },
    {
        accessor => undef,
        is_foreign_key_constraint => 0,
    },
);

1;
