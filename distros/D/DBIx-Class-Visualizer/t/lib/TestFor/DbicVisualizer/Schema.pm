package TestFor::DbicVisualizer::Schema;

use base 'DBIx::Class::Schema';

sub schema_version { 2 }

__PACKAGE__->load_namespaces;

1;
