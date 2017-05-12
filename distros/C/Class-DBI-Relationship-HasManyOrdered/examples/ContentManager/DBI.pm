package ContentManager::DBI;
use base 'Class::DBI';

__PACKAGE__->connection('dbi:mysql:dbdname', 'username', 'password');
__PACKAGE__->add_relationship_type(has_many_ordered => 'Class::DBI::Relationship::HasManyOrdered');

1;
