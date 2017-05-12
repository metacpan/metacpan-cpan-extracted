package DBSchemaMoose;

use strict;
use warnings;

use base 'DBSchemaBase';

__PACKAGE__->load_namespaces(
    result_namespace => '+DBSchema::Result',
    default_resultset_class => '+DBSchemaMoose::ResultSet',
);

1;
