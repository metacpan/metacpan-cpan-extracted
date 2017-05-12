
package DBIx::Romani::Query::SQL::Literal;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $value;

	if ( ref($args) eq 'HASH' )
	{
		$value = $args->{value};
	}
	else
	{
		$value = $args;
	}

	my $self = {
		value => $value,
	};

	bless  $self, $class;
	return $self;
}

sub get_value { return shift->{value}; }

sub visit
{
	my ($self, $visitor) = @_;
	return $visitor->visit_sql_literal( $self );
}

sub clone
{
	my $self = shift;

	my $args = {
		value => $self->get_value()
	};

	return DBIx::Romani::Query::SQL::Literal->new($args);
}

1;

