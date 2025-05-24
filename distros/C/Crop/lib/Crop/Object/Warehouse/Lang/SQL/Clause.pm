package Crop::Object::Warehouse::Lang::SQL::Clause;
use base qw/ Crop::Object /;

=begin nd
Class: Crop::Object::Warehouse::Lang::SQL::Clause
	Complex logical condition for WHERE.
	
	Clause contains Collection of <Crop::Object::Warehouse::Lang::SQL::Clause::Item>.
=cut

use v5.14;
use warnings;

use Crop::Error;
use Crop::Object::Collection;
use Crop::Object::Warehouse::Lang::SQL::Clause::Item;

use Crop::Debug;

=begin nd
Variable: our %Attributes
	Class members:

	items - Collection of clause items
=cut
our %Attributes = (
	items  => {default => Crop::Object::Collection->new('Crop::Object::Warehouse::Lang::SQL::Clause::Item')},
);

=begin nd
Constructor: new ($clause)
=cut
sub new {
	my ($class, $clause) = @_;
	
	my $self = $class->SUPER::new;
	
	my @clause;
	if (ref $clause eq 'HASH') {
		@clause = %$clause;
	} elsif (ref $clause eq 'ARRAY') {
		@clause = @$clause;
	} else {
		return warn 'DBASE: clause must be an Array either Hash ref';
	}
	
	while (@clause) {
		my ($attr, $expr) = splice @clause, 0, 2;

		my $item;
		unless (defined $expr) {
			$item = Crop::Object::Warehouse::Lang::SQL::Clause::Item->new(
				lhs      => $attr,
				operator => 'ISNULL',
			);
		} elsif (ref $expr eq 'HASH') {
			unless (keys %$expr) {  # attr=>{}
				$item = Crop::Object::Warehouse::Lang::SQL::Clause::Item->new(
					lhs      => $attr,
					operator => 'NOTNULL',
				);
			} else {
				my ($sign, $val) = %$expr;
				$item = Crop::Object::Warehouse::Lang::SQL::Clause::Item->new(
					lhs      => $attr,
					operator => $sign,
					rhs      => $val,
				);
			}
		} elsif (ref $expr eq 'ARRAY') {
			$item = Crop::Object::Warehouse::Lang::SQL::Clause::Item->new(
				lhs      => $attr,
				operator => 'IN',
				rhs      => $expr,
			);
		} else {
			$item = Crop::Object::Warehouse::Lang::SQL::Clause::Item->new(
				lhs      => $attr,
				operator => 'EQ',
				rhs      => $expr,
			);
		}
		$self->{items}->Push($item);
	}
	
	$self;
}

=begin nd
Method: add ($item)
	Add an $item to the Clause.
	
Parameters:
	$item - hashref presents >Crop::Object::Warehouse::Lang::SQL::Clause::Item>
	
Returns:
	$self
=cut
sub add {
	my ($self, $item) = @_;

	
	$self->{items}->Push(Crop::Object::Warehouse::Lang::SQL::Clause::Item->new($item));
	
	$self;
}

=begin nd
Method: print_sql ($table)
	Get string corresponging to the clause.
	
Parameters:
	$table - defines prefix for attribites; optional
	
Returns:
	the two element list of SQL string and array of values
=cut
sub print_sql {
	my ($self, $table) = @_;
	
	my $table_prefix = '';
	$table_prefix = "$table." if defined $table;
	
	my (@sql, @val);
	for ($self->{items}->List) {
		my ($sql, $attr, $val) = $_->print_sql;

		push @sql, $table_prefix . $sql;

		if ($_->has_value) {
			if (ref $val eq 'ARRAY') {
				for (@$val) {
					push @val, "$table_prefix$attr", $_;
				}
			} else {
				push @val, "$table_prefix$attr", $val;
			}
		}
	}
	
	my $result;
	{
		local $" = ' AND ';
		$result = "@sql";
	}
	
	($result, \@val);
}

1;
