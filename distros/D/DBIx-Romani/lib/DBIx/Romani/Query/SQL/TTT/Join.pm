
package DBIx::Romani::Query::SQL::TTT::Join;

use strict;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $self = {
		values => [ ],
	};

	bless  $self, $class;
	return $self;
}

sub get_values { return shift->{values}; }

sub add
{
	my ($self, $value) = @_;
	push @{$self->{values}}, $value;
}

sub visit
{
	my ($self, $visitor) = (shift, shift);
	return $visitor->visit_ttt_join( $self, @_ );
}

sub clone
{
	my $self = shift;

	my $clone = DBIx::Romani::Query::SQL::TTT::Join->new();
	foreach my $value ( @{$self->get_values()} )
	{
		$clone->add( $value );
	}

	return $clone;
}

1;

