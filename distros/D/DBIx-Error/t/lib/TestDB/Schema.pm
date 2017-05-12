package TestDB::Schema;

use base qw ( DBIx::Class::Schema );
use DBIx::Error;
use strict;
use warnings;

__PACKAGE__->exception_action ( DBIx::Error->exception_action );
__PACKAGE__->load_namespaces();

1;
