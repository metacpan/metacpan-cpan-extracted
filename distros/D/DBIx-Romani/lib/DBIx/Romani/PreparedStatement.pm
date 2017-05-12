
package DBIx::Romani::PreparedStatement;

use DBIx::Romani::ResultSet;
use DBI qw(:sql_types);
use strict;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $conn;
	my $sql;

	if ( ref($args) eq 'HASH' )
	{
		$conn = $args->{conn};
		$sql  = $args->{sql};
	}
	else
	{
		$conn = $args;
		$sql  = shift;
	}

	my $sth = $conn->get_dbh()->prepare( $sql );

	my $self = {
		conn => $conn,
		sql  => $sql,
		sth  => $sth,
	};

	bless  $self, $class;
	return $self;
}

sub get_conn         { return shift->{conn}; }
sub get_sth          { return shift->{sth}; }

sub execute_query
{
	my $self = shift;

	my $params;
	my $fetchmode;

	my $args = $_[0];
	if ( ref($args) eq 'HASH' )
	{
		$fetchmode = $args->{fetchmode};
		$params    = $args->{params};
	}
	else
	{
		$params = \@_;
	}

	$self->{sth}->execute( @$params );

	return $self->{conn}->get_driver()->create_result_set( $self->{conn}, $self->{sth}, $fetchmode );
}

sub execute_update
{
	my $self = shift;
	return $self->{sth}->execute( @_ );
}

sub set
{
	my ($self, $index, $value) = @_;
	$self->{sth}->bind_param( $index, $value );
}

# 
# TODO: Implement these:
#
#   * sub set_clob
#   * sub set_blob
#

sub set_date
{
	my ($self, $index, $value) = @_;

	# TODO: convert date into ODBC format!
	
	$self->{sth}->bind_param( $index, $value, SQL_DATE );
}

sub set_time
{
	my ($self, $index, $value) = @_;

	# TODO: convert date into ODBC format!

	$self->{sth}->bind_param( $index, $value, SQL_TIME );
}

sub set_datetime
{
	my ($self, $index, $value) = @_;

	# TODO: convert date into ODBC format!

	$self->{sth}->bind_param( $index, $value, SQL_DATETIME );
}

1;

