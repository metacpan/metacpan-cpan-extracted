package TestDB;

use base qw/DBIx::Class::Schema/;
use strict;

# Load all of the classes
__PACKAGE__->load_classes(qw/Role User UserRole/);


1;
