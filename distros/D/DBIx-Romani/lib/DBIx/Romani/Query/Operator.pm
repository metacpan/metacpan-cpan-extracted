
package DBIx::Romani::Query::Operator;

use strict;

our $ADD      = '+';
our $SUBTRACT = '-';
our $MULTIPLY = '*';
our $DIVIDE   = '/';

sub new
{
	my $class = shift;
	my $args  = shift;

	my $type;
	my $values_max;

	if ( ref($args) eq 'HASH' )
	{
		$type = $args->{type};
	}
	else
	{
		$type = $args;
	}

	my $self = {
		type       => $type,
		values     => [ ],
		values_max => $values_max,
	};

	bless  $self, $class;
	return $self;
}

sub get_type       { return shift->{type}; }
sub get_values     { return shift->{values}; }
sub get_values_max { return shift->{values_max}; }

sub add
{
	my ($self, $val) = @_;
	
	if ( defined $self->{values_max} )
	{
		if ( scalar @{$self->{values}} == $self->{values_max} )
		{
			die "Cannot add more than $self->{values_max} values to the $self->{type} operator";
		}
	}

	push @{$self->{values}}, $val;
}

sub visit
{
	my ($self, $visitor) = (shift, shift);
	return $visitor->visit_operator( $self, @_ );
}

sub copy_values
{
	my ($self, $other) = @_;

	foreach my $value ( @{$other->get_values()} )
	{
		$self->add( $value->clone() );
	}
}

sub clone
{
	my $self = shift;
	my $class = ref($self);

	my $clone;
	$clone = $class->new();
	$clone->copy_values( $self );

	return $clone;
}

1;

