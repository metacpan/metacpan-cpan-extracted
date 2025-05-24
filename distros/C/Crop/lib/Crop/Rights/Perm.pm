package Crop::Rights::Perm;
use base qw/ Crop::Object::Simple /;

=begin nd
Class: Crop::Rights::Perm
	Action such a 'READ','WRITE', and so on.
=cut

use v5.14;
use warnings;

=begin nd
Variable: our %Attributes
	Class attributes:

	id          - id from <Crop::Object::Simple>
	code        - CODE for perl use
	name        - name
	description - description
	id_file     - icon
=cut
our %Attributes = (
	code        => {mode => 'read'},
	name        => undef,
	description => undef,
	id_file     => undef,
);

=begin nd
Method: Table ( )
	Table in Warehouse.

Returns:
	'perm' string
=cut
sub Table { 'perm' }

1;
