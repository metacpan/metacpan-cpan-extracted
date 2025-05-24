package Crop::Prop::Value::Type;
use base qw/ Crop::Object::Simple /;

=begin nd
Class: Crop::Prop::Value::Type
	Type of property Value.
=cut

use v5.14;
use warnings;

=begin nd
Variable: our %Attributes
	Class attributes:
	
	code        - code
	description - description
	field       - field
	id          - from <Crop::Object::Simple>
	name        - name
=cut
our %Attributes = (
	code        => {mode => 'read'},
	description => undef,
	field       => {mode => 'read'},
	name        => undef,
);

=begin nd
Method: Table ( )
	Table in Warehouse.

Returns:
	'valtype' string
=cut
sub Table { 'valtype' }

1;
