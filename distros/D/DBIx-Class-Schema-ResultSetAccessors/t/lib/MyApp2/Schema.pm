package MyApp2::Schema;
use base qw/DBIx::Class::Schema/;

__PACKAGE__->load_components('Schema::ResultSetAccessors');
__PACKAGE__->load_namespaces();


1;