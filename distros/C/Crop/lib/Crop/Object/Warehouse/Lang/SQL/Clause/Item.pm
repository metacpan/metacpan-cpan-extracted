package Crop::Object::Warehouse::Lang::SQL::Clause::Item;
use base qw/ Crop::Object /;

=begin nd
Class: Crop::Object::Warehouse::Lang::SQL::Clause::Item
	Single logical condition for WHERE.
=cut

use v5.14;
use warnings;

use Crop::Error;

=begin nd
Variable: my %Op
	All the known operators.
=cut
my %Op = (
	EQ => '=',
	GT => '>',
	GE => '>=',
	LE => '<=',
	LT => '<',
);

=begin nd
Variable: our %Attributes
	Class members:

	has_value - either item requires rhs
	lhs       - left operand
	operator  - such 'EQ', 'GE', so on
	rhs       - right operand
=cut
our %Attributes = (
	has_value => {mode => 'read', default => 1},
	lhs       => {mode => 'read'},
	operator  => undef,
	rhs       => {mode => 'read'},
);

=begin nd
Method: print_sql ( )
	Get SQL string corresponging to the clause.
	
Returns:
	the array of three elements, sql string, pseudo attribute, and attribute value
=cut
sub print_sql {
	my $self = shift;

	my @sql;
	if ($self->{operator} eq 'IN') {
		my $ph = join ', ', split '', '?' x @{$self->{rhs}};
		@sql = ("$self->{lhs} IN ($ph)", $self->{lhs}, $self->{rhs});
	} elsif ($self->{operator} eq 'NOTNULL') {
		$self->{has_value} = 0;
		@sql = ("$self->{lhs} IS NOT NULL", $self->{rhs});
	} elsif ($self->{operator} eq 'ISNULL') {
		$self->{has_value} = 0;
		@sql = ("$self->{lhs} IS NULL", $self->{rhs});
	} else {
		@sql = ("$self->{lhs} $Op{$self->{operator}} ?", $self->{lhs} => $self->{rhs});
	}
	
	@sql;
}

1;
