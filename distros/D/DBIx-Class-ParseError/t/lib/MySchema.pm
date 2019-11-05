package MySchema::Foo;

use strict;
use warnings;
use Moo;

extends 'DBIx::Class::Core';

__PACKAGE__->table('foo');
__PACKAGE__->add_columns(
    id => {
        data_type => 'int',
        is_auto_increment => 1,
    },
    name => {
        data_type => 'varchar',
        size => 100,
    },
    is_foo => {
        data_type => 'tinyint',
    },
    bar_id => {
        data_type => 'int',
        is_foreign_key => 1,
    },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint(['name']);

__PACKAGE__->belongs_to(
    bar => 'MySchema::Bar',
    { 'foreign.id' => 'self.bar_id' },
);

package MySchema::Bar;

use strict;
use warnings;
use Moo;

extends 'DBIx::Class::Core';

__PACKAGE__->table('bar');
__PACKAGE__->add_columns(
    id => {
        data_type => 'int',
        is_auto_increment => 1,
    },
);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(
    foos => 'MySchema::Foo',
    { 'foreign.bar_id' => 'self.id' },
);

package MySchema::Baz;

use strict;
use warnings;
use Moo;

extends 'DBIx::Class::Core';

__PACKAGE__->table('baz');
__PACKAGE__->add_columns(
    id => {
        data_type => 'int',
        is_auto_increment => 1,
    },
    name => {
        data_type => 'varchar',
        size => 50,
    },
    other_name => {
        data_type => 'varchar',
        size => 50,
    },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint([qw(name other_name)]);

package MySchema;

use strict;
use warnings;
use Moo;

extends 'DBIx::Class::Schema';

__PACKAGE__->register_class('Foo', 'MySchema::Foo');
__PACKAGE__->register_class('Bar', 'MySchema::Bar');
__PACKAGE__->register_class('Baz', 'MySchema::Baz');

1;
