
package DBIx::Romani::IdGenerator;

use strict;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $conn;

	if ( ref($args) eq 'HASH' )
	{
		$conn = $args->{conn};
	}
	else
	{
		$conn = $args;
	}

	my $self = {
		conn => $conn,
	};
	
	bless  $self, $class;
	return $self;
}

sub get_conn { return shift->{conn}; }

sub is_before_insert
{
	die "Abstract.";
}

sub is_after_insert
{
	die "Abstract.";
}

sub get_id_method
{
	die "Abstract.";
}

sub get_id
{
	die "Abstract.";
}

1;

