package # hide from PAUSE
  Test::Schema::Result::Buzz;

use strict;
use warnings;
use parent 'DBIx::Class::Core';

__PACKAGE__->table('buzz');
__PACKAGE__->add_columns(
    foo_id => { 'data_type' => 'integer' },
    name => {
        'data_type' => 'varchar',
        'size' => 50,
    },
);
__PACKAGE__->set_primary_key('foo_id');

__PACKAGE__->belongs_to(
    'foo' => 'Test::Schema::Result::Foo',
    { 'foreign.id' => 'self.foo_id' },
);

1;
