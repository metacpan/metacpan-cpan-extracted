package Crop::Rights::Granted;
use base qw/ Crop::Object /;

=begin nd
Class: Crop::Rights::Granted
	Privileges granted to Role.
=cut

use v5.14;
use warnings;

=begin nd
Variable: our %Attributes
	Class attributes:

	id_role     - role
	id_realm    - privilege realm
	id_perm     - privilege permission
	negative    - cancel previous granted privilege
	description - why granted?
=cut
our %Attributes = (
	id_role     => {key => 'extern'},
	id_realm    => {key => 'extern'},
	id_perm     => {key => 'extern'},
	negative    => undef,
	description => undef,
);

=begin nd
Method: Table ( )
	Table in Warehouse.

Returns:
	'granted' string
=cut
sub Table { 'granted' }

1;
