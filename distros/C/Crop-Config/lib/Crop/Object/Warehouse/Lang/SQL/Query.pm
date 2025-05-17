package Crop::Object::Warehouse::Lang::SQL::Query;
use base qw/ Crop::Object /;

=begin nd
Class: Crop::Object::Warehouse::Lang::SQL::Query
	SQL query builder.
	
	Compose SQL query based on an object related structure.
	
	Many of the modules such Pg, MySQL, or MSSQL can use general SQL queries.
=cut

use v5.14;
use warnings;
no warnings 'experimental::smartmatch';

use Crop::Error;

=begin nd
Variable: our %Attributes
	Class members:

	where - where clause in
# 	type - type of query such as 'select', 'update', etc.
=cut
our %Attributes = (
);

=begin nd
Constructor: new ( )
	Pure virtual class builder.
	
	Prevents creation of this class.
=cut
sub new {
	my $class = shift;
	
	return warn 'DBASE: Query constructor must be redefined by subclass' if $class eq __PACKAGE__;
	
	$class->SUPER::new(@_);
}

=begin nd
Method: print_sql ( )
	Print SQL string.
	
	Pure virtual, must be redefined by subclass.
	
Returns:
	undef
=cut
sub print_sql { warn 'DBASE: print_sql() must be redefined by subclass' }

1;
