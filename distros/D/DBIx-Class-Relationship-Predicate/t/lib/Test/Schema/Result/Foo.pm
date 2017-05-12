package # hide from PAUSE
  Test::Schema::Result::Foo;

use strict;
use warnings;
use parent 'DBIx::Class';

__PACKAGE__->load_components(qw/Relationship::Predicate Core/);
__PACKAGE__->table('foo');
__PACKAGE__->add_columns(
    id => {
        'data_type' => 'integer',
        'is_auto_increment' => 1,
    },
    first_name => {
        'data_type' => 'varchar',
        'size' => 255,
    },
    last_name => {
        'data_type' => 'varchar',
        'size' => 255,
    },
);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(
    'bars' => 'Test::Schema::Result::Bar',
    { 'foreign.foo_id' => 'self.id' },
);

__PACKAGE__->might_have(
    'buzz' => 'Test::Schema::Result::Buzz',
    { 'foreign.foo_id' => 'self.id' },
    { 'predicate' => 'got_a_buzz' },
);

__PACKAGE__->has_many(
    'foo_baz' => 'Test::Schema::Result::FooBaz',
    { 'foreign.foo_id' => 'self.id' },
    { 'predicate' => undef },
);
__PACKAGE__->many_to_many('bazes' => 'foo_baz' => 'baz');

1;
