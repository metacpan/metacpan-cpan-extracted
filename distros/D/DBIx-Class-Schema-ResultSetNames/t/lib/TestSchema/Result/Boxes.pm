package TestSchema::Result::Boxes;

use strict;
use warnings;
use base qw(DBIx::Class::Core);

__PACKAGE__->table('boxes');
__PACKAGE__->add_columns(qw(id created_at description));
__PACKAGE__->set_primary_key('id');

1;
