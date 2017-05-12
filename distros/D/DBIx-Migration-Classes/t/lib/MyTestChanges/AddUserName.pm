package MyTestChanges::AddUserName;
use base qw(DBIx::Migration::Classes::Change);

sub after { "MyTestChanges::CreateTableUser" }
sub perform {
	my ($self) = @_;
	$self->alter_table_add_column('user', 'name', 'varchar(8)', null => 1);
	return 1;
}
1;
