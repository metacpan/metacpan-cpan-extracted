package AnotherTestDB::OnePK::Schema;

use base 'DBIx::Class::Schema';


__PACKAGE__->load_namespaces( default_resultset_class => '+DBIx::Class::ResultSet::RecursiveUpdate' );

1;

