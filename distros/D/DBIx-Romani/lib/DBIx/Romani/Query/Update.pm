
package DBIx::Romani::Query::Update;

use strict;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $table;

	if ( ref($args) eq 'HASH' )
	{
		$table = $args->{table};
	}
	else
	{
		$table = $args;
	}
	
	my $self = {
		table  => $table,
		values => [ ],
		where  => undef
	};

	bless $self, $class;
	return $self;
}

sub get_table  { return shift->{table}; }
sub get_values { return shift->{values}; }
sub get_where  { return shift->{where}; }

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

sub set_where
{
	my ($self, $where) = @_;
	$self->{where} = $where;
}

sub visit
{
	my ($self, $visitor) = @_;
	$visitor->visit_update( $self );
}

sub clone
{
	my $self = shift;

	my $query = DBIx::Romani::Query::Update->new({ table => $self->get_table() });

	foreach my $value ( @{$self->{values}} )
	{
		$query->set_value( $value->{column}, $value->{value} );
	}

	if ( $self->get_where() )
	{
		$query->set_where( $self->get_where()->clone() );
	}

	return $query;
}

1;

