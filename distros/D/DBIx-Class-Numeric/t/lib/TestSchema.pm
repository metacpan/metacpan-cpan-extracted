package TestSchema;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_classes(qw/TestTable BoundedTable/);

1;