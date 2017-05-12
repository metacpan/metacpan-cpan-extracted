
package DBIx::Romani::Query::SQL::TTT::Operator;

use DBIx::Romani::Query::SQL::Column;
use DBIx::Romani::Query::SQL::Literal;
use strict;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $op;

	if ( ref($args) eq 'HASH' )
	{
		$op = $args->{op};
	}
	else
	{
		$op = $args;
	}

	my $self = {
		op     => $op,
		values => [ ],
	};

	bless  $self, $class;
	return $self;
}

sub get_operator { return shift->{op}; }
sub get_values   { return shift->{values}; }

sub add
{
	my ($self, $value) = @_;
	push @{$self->{values}}, $value;
}

sub visit
{
	my ($self, $visitor) = (shift, shift);
	return $visitor->visit_ttt_operator( $self, @_ );
}

sub clone
{
	my $self = shift;

	my $clone = DBIx::Romani::Query::SQL::TTT::Operator->new({ op => $self->get_operator() });
	foreach my $value ( @{$self->get_values()} )
	{
		$clone->add( $value );
	}

	return $clone;
}

1;

