
package DBIx::Romani::Query::Function::Now;
use base qw(DBIx::Romani::Query::Function);

use DBIx::Romani::Query::SQL::Column;
use DBIx::Romani::Query::SQL::Literal;
use strict;

sub new
{
	my $class = shift;
	my $args  = shift;

	my $self = $class->SUPER::new();

	bless  $self, $class;
	return $self;
}

sub add
{
	my ($self, $value) = @_;
	
	die "Now function cannot have any arguments";
}

sub visit
{
	my ($self, $visitor) = @_;
	return $visitor->visit_function_now( $self );
}

1;

