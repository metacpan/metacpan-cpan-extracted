package Crop::Unit;
use base qw/ Crop::Object::Simple /;

=begin nd
Class: Crop::Unit
	Units of phisical params.
=cut

use v5.14;
use warnings;

=begin nd
Variable: our %Attributes
	Class attributes:
	
	name  - name for use as the code of unit
	value - output format; enum (asis,int)
=cut
our %Attributes = (
	name  => {mode => 'read'},
	value => {mode => 'read'},
);

=begin nd
Method: Table ( )
	Table in Warehouse.

Returns:
	'unit' string
=cut
sub Table { 'unit' }

1;
