
package DBIx::Romani::Query::Variable;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $name;

	if ( ref($args) eq 'HASH' )
	{
		$name = $args->{name};
	}
	else
	{
		$name = $args;
	}

	my $self = {
		name => $name,
	};

	bless  $self, $class;
	return $self;
}

sub get_name { return shift->{name}; }

sub visit
{
	my ($self, $visitor) = @_;
	return $visitor->visit_variable( $self );
}

sub clone
{
	my $self = shift;

	my $args = {
		name => $self->get_name()
	};

	return DBIx::Romani::Query::Variable->new($args);
}

1;

