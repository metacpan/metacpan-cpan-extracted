package FirstSchemaWithout::Result::Car;

use strict;
use warnings;
use base qw(DBIx::Class::Core);

__PACKAGE__->table('cars');
__PACKAGE__->add_columns(qw(id model human));
__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to('human' => 'FirstSchemaWithout::Result::Human', 'human');

1;
