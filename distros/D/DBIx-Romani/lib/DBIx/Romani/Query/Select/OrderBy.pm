
package DBIx::Romani::Query::Select::OrderBy;

use strict;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $value;
	my $dir;

	if ( ref($args) eq 'HASH' )
	{
		$value  = $args->{value};
		$dir    = $args->{dir};
	}
	else
	{
		$value  = $args;
		$dir    = shift;
	}

	if ( not defined $dir )
	{
		$dir = "asc";
	}

	my $self = {
		value  => $value,
		dir    => $dir
	};

	bless  $self, $class;
	return $self;
}

sub get_dir   { return shift->{dir}; }
sub get_value { return shift->{value}; }

sub clone
{
	my $self = shift;

	my $args = {
		value => $self->get_value(),
		dir   => $self->get_dir()
	};

	return DBIx::Romani::Query::Select::OrderBy->new($args);
}

1;

