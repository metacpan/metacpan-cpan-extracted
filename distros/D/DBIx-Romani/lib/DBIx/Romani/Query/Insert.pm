
package DBIx::Romani::Query::Insert;

use strict;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $into;

	if ( ref($args) eq 'HASH' )
	{
		$into = $args->{into};
	}
	else
	{
		$into = $args;
	}
	
	my $self = {
		into     => $into,
		values   => [ ]
	};

	bless $self, $class;
	return $self;
}

sub get_into   { return shift->{into}; }
sub get_values { return shift->{values}; }

sub set_value
{
	my ($self, $column, $value) = @_;

	# attempt to remove the old value
	for (my $i = 0; $i < scalar @{$self->{values}}; $i++ )
	{
		if ( $self->{values}->[$i]->{column} eq $column )
		{
			delete $self->{values}->[$i];
			last;
		}
	}

	push @{$self->{values}}, { column => $column, value => $value };
}

sub visit
{
	my ($self, $visitor) = @_;
	$visitor->visit_insert( $self );
}

sub clone
{
	my $self = shift;

	my $query = DBIx::Romani::Query::Insert->new({ into => $self->get_into() });

	foreach my $value ( @{$self->{values}} )
	{
		$query->set_value( $value->{column}, $value->{value} );
	}

	return $query;
}

1;

