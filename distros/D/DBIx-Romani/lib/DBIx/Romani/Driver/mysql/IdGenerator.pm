
package DBIx::Romani::Driver::mysql::IdGenerator;
use base qw(DBIx::Romani::IdGenerator);

use strict;

sub is_before_insert
{
	return 0;
}

sub is_after_insert
{
	return 1;
}

sub get_id_method
{
	return "auto_increment";
}

sub get_id
{
	my $self = shift;

	my $rs;
	$rs = $self->get_conn()->execute_query('SELECT LAST_INSERT_ID() as last_insert_id');
	$rs->next();

	my $row = $rs->get_row();
	return $row->{last_insert_id};
}

1;

