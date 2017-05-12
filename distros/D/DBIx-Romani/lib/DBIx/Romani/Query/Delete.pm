
package DBIx::Romani::Query::Delete;

use strict;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $from;

	if ( ref($args) eq 'HASH' )
	{
		$from = $args->{from};
	}
	else
	{
		$from = $args;
	}
	
	my $self = {
		from   => $from,
		where  => undef
	};

	bless $self, $class;
	return $self;
}

sub get_from  { return shift->{from}; }
sub get_where { return shift->{where}; }

sub set_where
{
	my ($self, $where) = @_;
	$self->{where} = $where;
}

sub visit
{
	my ($self, $visitor) = @_;
	$visitor->visit_delete( $self );
}

sub clone
{
	my $self = shift;

	my $query = DBIx::Romani::Query::Delete->new({ from => $self->get_from() });

	if ( $self->get_where() )
	{
		$query->set_where( $self->get_where()->clone() );
	}

	return $query;
}

1;

