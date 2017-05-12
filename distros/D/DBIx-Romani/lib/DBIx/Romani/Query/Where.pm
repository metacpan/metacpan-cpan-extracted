
package DBIx::Romani::Query::Where;

use strict;

our $AND = 'AND';
our $OR  = 'OR';

sub new
{
	my $class = shift;
	my $args  = shift;

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
		$type = $AND;
	}

	if ( $type ne $AND and $type ne $OR )
	{
		die "Invalid SQL group type";
	}

	my $self = {
		type   => $type,
		values => [ ],
	};

	bless  $self, $class;
	return $self;
}

sub get_type   { return shift->{type}; }
sub get_values { return shift->{values}; }

sub add
{
	my ($self, $val) = @_;
	push @{$self->{values}}, $val;
}

sub visit
{
	my ($self, $visitor) = (shift, shift);
	return $visitor->visit_where( $self, @_ );
}

sub clone
{
	my $self = shift;

	my $clone = DBIx::Romani::Query::Where->new({ type => $self->get_type() });
	foreach my $value ( @{$self->get_values()} )
	{
		$clone->add( $value );
	}
	
	return $clone;
}

1;

