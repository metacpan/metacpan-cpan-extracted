package Crop::Rights::Role;
use base qw/ Crop::Object::Simple /;

=begin nd
Class: Crop::Rights::Realm
	Object the rights are linked to.
	
	The Role is presented by a Class name.
=cut

use v5.14;
use warnings;

=begin nd
Variable: our %Attributes
	Class attributes:

	active      - role is off
	description - description
	id          - id from <Crop::Object::Simple>
	name        - name
	privileges  - Collection of granted privileges
=cut
our %Attributes = (
	active      => undef,
	description => undef,
	name        => {mode => 'read'},
	privileges  => {mode => 'read', type => 'cache'},
	EXT => {
		privileges => {
			type => 'content',
			cross => [
				'Crop::Rights::Granted'   => {id => 'id_role'},
				'Crop::Rights::Privilege' => {id_realm => 'id_realm', id_perm => 'id_perm'}
			],
			view => 'privileges',
		}
	}
);

=begin nd
Method: Table ( )
	Table in Warehouse.

Returns:
	'role' string
=cut
sub Table { 'role' }

1;
