package # hide from PAUSE
  Test::Schema::Result::FooBaz;

use strict;
use warnings;
use parent 'DBIx::Class::Core';

__PACKAGE__->table('foo_baz');
__PACKAGE__->add_columns(
    foo_id => { 'data_type' => 'integer' },
    baz_id => { 'data_type' => 'integer' },
);
__PACKAGE__->set_primary_key(qw/foo_id baz_id/);

__PACKAGE__->belongs_to(
    'foo' => 'Test::Schema::Result::Foo',
    { 'foreign.id' => 'self.foo_id' }
);

__PACKAGE__->belongs_to(
    'baz' => 'Test::Schema::Result::Baz',
    { 'foreign.id' => 'self.baz_id' }
);

1;
