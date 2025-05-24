package Crop::Rights::Realm;
use base qw/ Crop::Object::Simple /;

=begin nd
Class: Crop::Rights::Realm
	Object the rights are linked to.
=cut

use v5.14;
use warnings;

=begin nd
Variable: our %Attributes
	Class attributes:

	id          - id from <Crop::Object::Simple>
	name        - name
	description - description
=cut
our %Attributes = (
	name        => {mode => 'read'},
	description => undef,
);

=begin nd
Method: Table ( )
	Table in Warehouse.

Returns:
	'realm' string
=cut
sub Table { 'realm' }

1;
