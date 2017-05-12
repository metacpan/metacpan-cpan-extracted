
package DBIx::Romani::PreparedQuery;

use DBIx::Romani::ResultSet;
use strict;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $conn;
	my $query;

	if ( ref($args) eq 'HASH' )
	{
		$conn  = $args->{conn};
		$query = $args->{query};
	}
	else
	{
		$conn  = $args;
		$query = shift;
	}

	my $self = {
		conn  => $conn,
		query => $query,
	};

	bless  $self, $class;
	return $self;
}

sub get_conn  { return shift->{conn}; }
sub get_query { return shift->{query}; }

sub execute
{
	my ($self, $values, $fetchmode) = @_;

	my $sql = $self->get_conn->generate_sql( $self->get_query(), $values );
	if ( $self->get_query()->isa( 'DBIx::Romani::Query::Select' ) )
	{
		return $self->get_conn()->execute_query( $sql, $fetchmode );
	}
	else
	{
		return $self->get_conn()->execute_update( $sql );
	}
}

1;

