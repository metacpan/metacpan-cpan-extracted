package AuditTest2::Schema::ResultSet::User;

use base 'DBIx::Class::ResultSet';

__PACKAGE__->load_components('ResultSet::AuditLog');

1;
