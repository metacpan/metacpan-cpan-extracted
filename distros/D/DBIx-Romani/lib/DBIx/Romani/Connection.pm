
package DBIx::Romani::Connection;
use base qw(DBIx::Romani::Connection::Base);

use strict;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $dbh;
	my $driver;
	my $disconnect;
	
	if ( ref($args) eq 'HASH' )
	{
		$driver     = $args->{driver};
		$dbh        = $args->{dbh};
		$disconnect = $args->{disconnect}
	}
	else
	{
		$driver = $args;
		$dbh    = shift;
	}

	if ( not defined $disconnect )
	{
		$disconnect = 1;
	}
	
	my $self = $class->SUPER::new({ dbh => $dbh, driver => $driver });

	# store our disconnect state
	$self->{disconnect} = $disconnect;

	bless  $self, $class;
	return $self;
}

sub disconnect
{
	my $self = shift;

	if ( $self->{disconnect} )
	{
		$self->SUPER::disconnect();
	}

	$self->{dbh} = undef;
}

1;

