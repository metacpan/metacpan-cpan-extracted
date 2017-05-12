
package DBIx::Romani::ResultSet;

use strict;

use constant FETCHMODE_ASSOC => 1;
use constant FETCHMODE_NUM   => 2;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $conn;
	my $sth;
	my $mode;

	if ( ref($conn) eq 'HASH' )
	{
		$conn = $args->{conn};
		$sth  = $args->{sth};
		$mode = $args->{fetchmode};
	}
	else
	{
		$conn = $args;
		$sth  = shift;
		$mode = shift;
	}

	if ( not defined $mode )
	{
		$mode = FETCHMODE_ASSOC;
	}

	my $self = {
		conn => $conn,
		sth  => $sth,
		row  => undef,
		mode => $mode,
	};

	bless  $self, $class;
	return $self;
}

sub get_conn      { return shift->{conn}; }
sub get_row       { return shift->{row}; }
sub get_fetchmode { return shift->{mode}; }

sub next
{
	my $self = shift;

	if ( $self->get_fetchmode() == FETCHMODE_NUM )
	{
		$self->{row} = $self->{sth}->fetchrow_arrayref();
	}
	else
	{
		$self->{row} = $self->{sth}->fetchrow_hashref();
	}

	# return true if we still have data
	return defined( $self->{row} );
}

sub get
{
	my ($self, $column) = @_;

	if ( $self->get_fetchmode() == FETCHMODE_NUM )
	{
		return $self->{row}->[$column];
	}
	else
	{
		return $self->{row}->{$column};
	}
}


# TODO: implement these:
#
# TODO: Or, maybe, I could provide these with an AUTOLOAD and then if
# the child class overrides it, then cool.  Otherwise just get().
#
#   * sub get_blob($column)
#   * sub get_clob($column)
#   * sub get_date($column)
#   * sub get_time($column)
#   * sub get_timestamp($column)

1;

