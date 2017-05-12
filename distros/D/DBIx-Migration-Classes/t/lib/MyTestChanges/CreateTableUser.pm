package MyTestChanges::CreateTableUser;
use base qw(DBIx::Migration::Classes::Change);

sub after { "" }
sub perform {
	my ($self) = @_;
	$self->create_table('user');
	$self->alter_table_add_column('user', 'id', 'varchar(42)', null => 1, primary_key => 1);
	return 1;
}
1;
