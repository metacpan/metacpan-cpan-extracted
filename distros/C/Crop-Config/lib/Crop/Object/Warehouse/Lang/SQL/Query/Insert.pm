package Crop::Object::Warehouse::Lang::SQL::Query::Insert;
use base qw/ Crop::Object::Warehouse::Lang::SQL::Query /;

=begin nd
Class: Crop::Object::Warehouse::Lang::SQL::Query::Insert
	The Insert query.
=cut

use v5.14;
use warnings;

use Crop::Error;

use Crop::Debug;

=begin nd
Variable: our %Attributes
	Class members:

	attr      - hash of attr=>values; or undef
	returning - resulting attr to return
	table     - table
=cut
our %Attributes = (
	attr      => {default => {}},
	returning => undef,
	table     => undef,
);

=begin nd
Method: print_sql ( )
	Compose query prepared string based on inner presentation.
	
Returns:
	the array of two element, SQL string, and arrayref of values for placeholders
=cut
sub print_sql {
	my $self = shift;
	
# 	debug 'INSERT_PRINTSQL_SELF=', $self;
	
	my $sql = "INSERT INTO $self->{table} ";
	my @val;

	if (keys %{$self->{attr}}) {
		my @attr;
		while (my ($attr, $val) = each %{$self->{attr}}) {
			push @attr, $attr;
			push @val, $attr, $val;
		}
		
		my @ph = split '', '?' x @attr;
		{
			local $" = ', ';
			$sql .= "(@attr) VALUES (@ph)";
		}
	} else {
		$sql .= "(id) VALUES (default)";
	}
	
	$sql .= " RETURNING $self->{returning}" if defined $self->{returning};

	($sql, \@val);
}

1;
