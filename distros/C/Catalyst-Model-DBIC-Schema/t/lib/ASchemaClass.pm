package ASchemaClass;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_classes;

use Moose;
has a_schema_option => (is => 'rw');

1;
