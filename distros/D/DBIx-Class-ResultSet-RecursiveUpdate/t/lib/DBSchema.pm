package DBSchema;

use strict;
use warnings;

use base 'DBSchemaBase';

__PACKAGE__->load_namespaces( default_resultset_class => '+DBIx::Class::ResultSet::RecursiveUpdate' );

1;

