package TestSchema;
use strict;
use warnings;
use parent qw(DBIx::Class::Schema);

__PACKAGE__->load_namespaces( default_resultset_class => 'ResultSet' );

1;
