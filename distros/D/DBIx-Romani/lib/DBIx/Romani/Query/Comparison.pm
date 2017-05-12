
package DBIx::Romani::Query::Comparison;

use strict;

# comparison types
our $EQUAL         = '=';
our $NOT_EQUAL     = '<>';
our $GREATER_THAN  = '>';
our $GREATER_EQUAL = '>=';
our $LESS_THAN     = '<';
our $LESS_EQUAL    = '<=';
our $LIKE          = 'LIKE';
our $NOT_LIKE      = 'NOT LIKE';
our $ILIKE         = 'ILIKE';
our $NOT_ILIKE     = 'NOT ILIKE';
our $BETWEEN       = 'BETWEEN';
our $IN            = 'IN';
our $NOT_IN        = 'NOT IN';
our $IS_NULL       = 'IS NULL';
our $IS_NOT_NULL   = 'IS NOT NULL';

sub new
{
	my $class = shift;
	my $args  = shift;

	my $rvalues_max;
	my $type;

	if ( ref($args) eq 'HASH' )
	{
		$type = $args->{type};
	}
	else
	{
		$type = $args;
	}

	if ( not defined $type )
	{
		$type = $EQUAL;
	}

	if ( $type eq $BETWEEN )
	{
		$rvalues_max = 2;
	}
	elsif ( $type eq $IS_NULL or $type eq $IS_NOT_NULL )
	{
		$rvalues_max = 0;
	}
	elsif ( $type eq $IN or $type eq $NOT_IN )
	{
		# no limit!
		$rvalues_max = undef;
	}
	else
	{
		$rvalues_max = 1;
	}

	my $self = {
		lvalue      => undef,
		type        => $type,
		rvalues_max => $rvalues_max,
		rvalues     => [ ],
	};

	bless  $self, $class;
	return $self;
}

sub get_type { return shift->{type}; }

sub get_lvalue { return shift->{lvalue}; }
sub get_rvalue
{
	my $self = shift;

	# deal with camparisons with strict limits
	if ( defined $self->{rvalues_max} )
	{
		if ( $self->{rvalues_max} == 1 )
		{
			if ( scalar @{$self->{rvalues}} == 0 )
			{
				return undef;
			}
			else
			{
				return $self->{rvalues}->[0];
			}
		}
		if ( $self->{rvalues_max} == 0 )
		{
			return undef;
		}
	}

	return $self->{rvalues};
}

sub get_values
{
	my $self = shift;
	return [ $self->{lvalue}, @{$self->{rvalues}} ];
}

sub add
{
	my ($self, $val) = @_;
	
	if ( not defined $self->{lvalue} )
	{
		$self->{lvalue} = $val;
	}
	else
	{
		if ( defined $self->{rvalues_max} )
		{
			if ( scalar @{$self->{rvalues}} == $self->{rvalues_max} )
			{
				my $name;
				$name = ref($self);
				$name =~ s/.*:://;

				die "Cannot add more than $self->{rvalues_max} rvalues to the $name comparison";
			}
		}

		push @{$self->{rvalues}}, $val;
	}
}

sub visit
{
	my ($self, $visitor) = (shift, shift);
	return $visitor->visit_comparison( $self, @_ );
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

