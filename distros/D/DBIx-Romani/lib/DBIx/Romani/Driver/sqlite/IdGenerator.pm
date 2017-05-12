
package DBIx::Romani::Driver::sqlite::IdGenerator;
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
	return $self->get_conn()->get_dbh()->func( 'last_insert_rowid' );
}

1;

