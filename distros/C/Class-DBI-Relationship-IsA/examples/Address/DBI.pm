package Address::DBI;

use Class::DBI::Relationship::IsA;
use base qw(Class::DBI);
warn "a";
Address::DBI->connection('dbi:mysql:pint', 'root', '');
warn "b";
__PACKAGE__->add_relationship_type(is_a => "Class::DBI::Relationship::IsA");
warn "c";
1;
