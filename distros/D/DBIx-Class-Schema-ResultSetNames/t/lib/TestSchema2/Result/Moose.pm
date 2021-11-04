package TestSchema2::Result::Moose;

use strict;
use warnings;
use base qw(DBIx::Class::Core);

__PACKAGE__->table('moose');
__PACKAGE__->add_columns(qw(id color height gender));
__PACKAGE__->set_primary_key('id');

1;
