use strict;
use warnings;

package TestAppDBICSchema::Schema::Result::Foo;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/Core/);

__PACKAGE__->table('foo');

1;
