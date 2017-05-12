
package DBIx::Romani::Query::SQL::Column;

sub new
{
	my $class = shift;
	my $args  = shift;

	# TODO: Column should have an optional table part!!

	my $table_name;
	my $column_name;

	if ( ref($args) eq 'HASH' )
	{
		$table_name  = $args->{table};
		$column_name = $args->{name};
	}
	else
	{
		$table_name  = $args;
		$column_name = shift;
	}

	my $self = {
		table => $table_name,
		name  => $column_name,
	};

	bless $self, $class;
	return $self;
}

sub get_table { return shift->{table}; }
sub get_name  { return shift->{name}; }

sub visit
{
	my ($self, $visitor) = @_;
	return $visitor->visit_sql_column( $self );
}

sub clone
{
	my $self = shift;

	my $args = {
		table => $self->get_table(),
		name  => $self->get_name()
	};

	return DBIx::Romani::Query::SQL::Column->new($args);
}

1;

