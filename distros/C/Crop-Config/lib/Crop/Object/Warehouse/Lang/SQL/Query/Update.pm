package Crop::Object::Warehouse::Lang::SQL::Query::Update;
use base qw/ Crop::Object::Warehouse::Lang::SQL::Query /;

=begin nd
Class: Crop::Object::Warehouse::Lang::SQL::Query::Update
	The Update query.
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
	new_val - hash of $attr=>$newval
	table   - table name
=cut
our %Attributes = (
	clause  => undef,
	new_val => undef,
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
# 	debug 'CROPOBJECTWAREHOUSELANGSQLQUERYUPDATE_NEW_IN=', \%in;

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
	the array of two element, SQL string, and arrayref of values for placeholders
=cut
sub print_sql {
	my $self = shift;
# 	debug 'CROPOBJECTWAREHOUSELANGSQLQUERYUPDATE_PRINTSQL_SELF=', $self;
	
	my $sql = "UPDATE $self->{table} SET ";
	
	my (@set, @values);
	while (my ($attr, $newval) = each %{$self->{new_val}}) {
		if (ref $newval eq 'SCALAR') {
# 			...;
			push @set, "$attr = $$newval";
		} else {
			push @set, "$attr = ?";
			push @values, $attr, $newval;
		}
	}
	return warn 'OBJECT: Nothing to Update' unless @set;
	
	{
		local $" = ', ';
		$sql .= "@set ";
	}

	if ($self->{clause}) {
		my ($where, $val) = $self->{clause}->print_sql;
		
		if ($where) {
			$sql .= " WHERE $where ";
			push @values, @$val;
		}
	}
	
	($sql, \@values);
}

1;
