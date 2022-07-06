package TestSchema::Result::Car;

use strict;
use warnings;
use base qw(DBIx::Class::Core);

__PACKAGE__->table('cars');
__PACKAGE__->add_columns(qw(id model human));
__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to('human' => 'TestSchema::Result::Human', 'human');

1;
