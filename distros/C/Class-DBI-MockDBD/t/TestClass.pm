package TestClass;

use base qw(Class::DBI::MockDBD);

__PACKAGE__->table('testing123');
__PACKAGE__->columns(Primary => qw/foo_id/);
__PACKAGE__->columns(All => qw/foo_id foo_name foo_bar/);

1;
