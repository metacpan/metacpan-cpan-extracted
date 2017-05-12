package # hide from PAUSE
    ExampleDB;
use strict;
use warnings;
our $VERSION = 1;
use base qw( DBIx::Class::Schema );

__PACKAGE__->load_namespaces;

1;
