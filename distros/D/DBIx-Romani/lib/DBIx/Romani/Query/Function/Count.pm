
package DBIx::Romani::Query::Function::Count;
use base qw(DBIx::Romani::Query::Function);

use DBIx::Romani::Query::SQL::Column;
use DBIx::Romani::Query::SQL::Literal;
use strict;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $distinct = 0;
	
	if ( ref($args) eq 'HASH' )
	{
		$distinct = $args->{distinct} || $distinct;
	}
	
	my $self = $class->SUPER::new();
	$self->{distinct} = $distinct;

	bless  $self, $class;
	return $self;
}

sub get_distinct { return shift->{distinct}; }

sub set_distinct
{
	my ($self, $distinct) = @_;
	$self->{distinct} = $distinct;
}

sub add
{
	my ($self, $value) = @_;
	
	if ( scalar @{$self->get_arguments()} == 1 )
	{
		die "Cannot set more than one argument for the COUNT function";
	}

	$self->SUPER::add( $value );
}

sub visit
{
	my ($self, $visitor) = @_;
	return $visitor->visit_function_count( $self );
}

sub clone
{
	my $self = shift;

	my $add;
	$add = DBIx::Romani::Query::Function::Count->new({ distinct => $self->get_distinct() });
	$add->copy_arguments( $self );

	return $add;
}

1;

