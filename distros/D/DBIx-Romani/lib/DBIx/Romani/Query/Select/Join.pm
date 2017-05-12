
package DBIx::Romani::Query::Select::Join;

use strict;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $type;
	my $table_name;
	my $on;

	if ( ref($args) eq 'HASH' )
	{
		$type       = $args->{type};
		$table_name = $args->{table};
		$on         = $args->{on};
	}
	else
	{
		$type       = $args;
		$table_name = shift;
		$on         = shift;
	}

	my $self = {
		type       => $type,
		table_name => $table_name,
		on         => $on,
	};

	bless  $self, $class;
	return $self;
}

sub get_type  { return shift->{type}; }
sub get_table { return shift->{table_name}; }
sub get_on    { return shift->{on}; }

sub clone
{
	my $self = shift;

	my $args = {
		type  => $self->get_type(),
		table => $self->get_table(),
		on    => $self->get_on()
	};

	return DBIx::Romani::Query::Select::Join->new($args);
}

1;

