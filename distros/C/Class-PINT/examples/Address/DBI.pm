package Address::DBI;

use base qw(Class::PINT Class::DBI::mysql);

Address::DBI->connection('dbi:mysql:pint', 'root', '');
__PACKAGE__->add_relationship_type(is_a => "Class::DBI::Relationship::IsA");

1;
