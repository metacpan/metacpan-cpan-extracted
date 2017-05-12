use strict;
use warnings FATAL => 'all';

package Apache::SWIT::Security::DB::User;
use base 'Apache::SWIT::DB::Base';

sub swit_startup {
	my $class = shift;
	$class->set_up_table('users', { ColumnGroup => 'Essential' });
	$class->columns(TEMP => qw(role_id));
}

__PACKAGE__->set_fetch_sql('role_ids', <<ENDS
select role_id from user_roles where user_id = ?
ENDS
	, undef, 'id');

__PACKAGE__->set_sql('all_with_roles', <<ENDS);
select __ESSENTIAL__, role_id from users 
	left outer join user_roles on id = user_id
ENDS

sub role_ids {
	return map { $_->[0] } @{ shift()->fetch_role_ids };
}

sub add_role_id {
	my ($self, $role_id) = @_;
	$self->db_Main->do('INSERT INTO user_roles (user_id, role_id)
			VALUES (?, ?)', undef, $self->id, $role_id);
}

sub delete_role_id {
	my ($self, $role_id) = @_;
	$self->db_Main->do('DELETE FROM user_roles WHERE 
		user_id = ? and role_id = ?', undef, $self->id, $role_id);
}

1;
