package Crop::Object::Warehouse::Lang::SQL::Query::Delete;
use base qw/ Crop::Object::Warehouse::Lang::SQL::Query /;

=begin nd
Class: Crop::Object::Warehouse::Lang::SQL::Query::Delete
	The Delete query.
=cut

use v5.14;
use warnings;

use Crop::Error;
use Crop::Object::Warehouse::Lang::SQL::Clause;

use Crop::Debug;

=begin nd
Variable: our %Attributes
	Class members:

	clause  - exemplar of <Crop::Object::Warehouse::Lang::SQL::Clause>
	table   - table name
=cut
our %Attributes = (
	clause  => undef,
	table   => undef,
);

=begin nd
Constructor: new ( )
	Build clause.
	
Returns:
	$self
=cut
sub new {
	my ($class, %in) = @_;

	my @clause = ();
	my $self = $class->SUPER::new(
		%in,
		exists $in{clause} ?
			  (clause => Crop::Object::Warehouse::Lang::SQL::Clause->new($in{clause}))
			: ()
		,
	);
	
	$self;
}

=begin nd
Method: print_sql ( )
	Compose query prepared string based on inner presentation.
	
Returns:
	the array of two elements, SQL string, and arrayref of values for placeholders
=cut
sub print_sql {
	my $self = shift;
	
	my $sql = "DELETE FROM $self->{table} ";

	my $values;
	if ($self->{clause}) {
		my $where;
	
		($where, $values) = $self->{clause}->print_sql;
		
		$sql .= " WHERE $where " if $where;
	}

	($sql, $values);
}

1;
