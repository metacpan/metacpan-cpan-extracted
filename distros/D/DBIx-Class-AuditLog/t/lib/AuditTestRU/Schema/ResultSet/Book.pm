package AuditTestRU::Schema::ResultSet::Book;

use base 'DBIx::Class::ResultSet::RecursiveUpdate';

__PACKAGE__->load_components('ResultSet::AuditLog');
1;
