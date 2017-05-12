
package DBIx::Romani::Connection::Base;

use DBIx::Romani::PreparedQuery;
use Exception::Class::DBI;
use strict;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $driver;
	my $dbh;

	if ( ref($args) eq 'HASH' )
	{
		$driver = $args->{driver};
		$dbh    = $args->{dbh};
	}
	else
	{
		$driver = $args;
		$dbh    = shift;
	}

	if ( $dbh )
	{
		$dbh->{'HandleError'} = Exception::Class::DBI->handler,
		$dbh->{'PrintError'} = 0;
		$dbh->{'RaiseError'} = 0;
		$dbh->{'AutoCommit'} = 1;
	}

	my $self = {
		dbh    => $dbh,
		driver => $driver,
	};

	bless  $self, $class;
	return $self;
}

sub get_dbh    { return shift->{dbh}; }
sub get_driver { return shift->{driver}; }

sub create_id_generator
{
	my $self = shift;
	return $self->get_driver()->create_id_generator( $self );
}

sub apply_limit
{
	my $self = shift;
	return $self->get_driver()->apply_limit( @_ );
}

sub prepare
{
	my ($self, $query) = @_;

	if ( ref($query) )
	{
		return DBIx::Romani::PreparedQuery->new( $self, $query );
	}
	else
	{
		return $self->get_driver()->create_prepared_statement( $self, $query );
	}
}

sub execute
{
	my ($self, $query, $fetchmode) = @_;

	my $sql = $self->generate_sql( $query );
	if ( $query->isa( 'DBIx::Romani::Query::Select' ) )
	{
		return $self->execute_query( $sql, $fetchmode );
	}
	else
	{
		return $self->execute_update( $sql );
	}
}

sub execute_query
{
	my ($self, $sql, $fetchmode) = @_;
	
	my $sth;
	$sth= $self->get_dbh()->prepare( $sql );
	$sth->execute();

	return $self->get_driver()->create_result_set( $self, $sth, $fetchmode );
}

sub execute_update
{
	my ($self, $sql) = @_;

	# returns the number of affected rows
	return $self->get_dbh()->do( $sql );
}

sub generate_sql
{
	my $self = shift;

	my $sql = $self->get_driver()->generate_sql( @_ );
	#print STDERR "$sql\n";

	return $sql;
}

sub begin    { shift->get_dbh()->begin_work(); }
sub commit   { shift->get_dbh()->commit(); }
sub rollback { shift->get_dbh()->rollback(); }

sub disconnect
{
	my $self = shift;

	$self->{dbh}->disconnect();
	$self->{dbh} = undef;
}

1;

