package Crop::Rights::Privilege;
use base qw/ Crop::Object /;

=begin nd
Class: Crop::Rights::Perm
	Permissions of Realm.
=cut

use v5.14;
use warnings;

=begin nd
Variable: our %Attributes
	Class attributes:

	description - description
	id_perm     - permission
	id_realm    - realm
	name        - name
	perm        - extra object <Crop::Rights::Perm> for attribute 'id_perm'
	realm       - extra object <Crop::Rights::Realm> for attribute 'id_realm'
=cut
our %Attributes = (
	description => undef,
	id_perm     => {key => 'extern'},
	id_realm    => {key => 'extern'},
	name        => undef,
	perm        => {mode => 'read', type => 'cache'},
	realm       => {mode => 'read', type => 'cache'},
	
	EXT => {
		perm  => {
			type  => 'refbook',
			class => 'Crop::Rights::Perm',
			xattr => {id_perm => 'id'},
			view  => 'perm',
		},
		realm => {
			type  => 'refbook',
			class => 'Crop::Rights::Realm',
			xattr => {id_realm => 'id'},
			view  => 'realm',
		},
		
	}
);

=begin nd
Method: Table ( )
	Table in Warehouse.

Returns:
	'privilege' string
=cut
sub Table { 'privilege' }

1;
