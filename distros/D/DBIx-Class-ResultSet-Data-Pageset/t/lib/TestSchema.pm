package TestSchema;

use base qw( DBIx::Class );

use strict;
use warnings;

use base qw( DBIx::Class::Schema );

__PACKAGE__->load_classes;

1;
