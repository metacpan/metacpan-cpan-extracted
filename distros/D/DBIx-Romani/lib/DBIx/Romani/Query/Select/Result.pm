
package DBIx::Romani::Query::Select::Result;

use strict;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $value;
	my $alias_name;

	if ( ref($args) eq 'HASH' )
	{
		$value      = $args->{value};
		$alias_name = $args->{as};
	}
	else
	{
		$value      = $args;
		$alias_name = shift;
	}

	my $self = {
		value      => $value,
		alias_name => $alias_name,
	};

	bless  $self, $class;
	return $self;
}

sub get_name  { return shift->{alias_name}; }
sub get_value { return shift->{value}; }

sub clone
{
	my $self = shift;

	my $args = {
		value => $self->get_value(),
		as    => $self->get_name()
	};

	return DBIx::Romani::Query::Select::Result->new($args);
}

1;

