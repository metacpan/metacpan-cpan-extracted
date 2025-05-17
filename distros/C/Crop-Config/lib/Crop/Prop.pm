package Crop::Prop;
use base qw/ Crop::Object::Simple /;

=begin nd
Class: Crop::Prop
	Property.
	
	It's used for all the classes that use properties of any form.
	
	You could subclass Property by project-specific class if the EXT funcionality is required.
=cut

use v5.14;
use warnings;

use Crop::Error;

use Crop::Debug;

=begin nd
Variable: our %Attributes
	Class attributes:
	
	code        - unique code of prop
	description - description
	id          - from <Crop::Object::Simple>
	id_proptype - type of prop; exemplar of <Crop::Prop::Type>
	name        - name
	proptype    - extra object <Crop::Prop::Type> for attribute 'id_proptype'
=cut
our %Attributes = (
	code        => {mode => 'read'},
	description => undef,
	id_proptype => {mode => 'read', key => 'extern'},
	name        => undef,
);

=begin nd
Method: Table ( )
	Table in the Warehouse.

Returns:
	'prop' string
=cut
sub Table { 'prop' }

1;
