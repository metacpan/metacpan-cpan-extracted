package Crop::File::Warehouse;
use base qw/ Crop::Object::Simple /;

=begin nd
Class: Crop::File::Warehouse
	Warehouse type the files are stored.
	
	Subclasses could present application-specific file trees. Place thus warehouses
	to <Table>.
=cut

use v5.14;
use warnings;

=begin nd
Variable: our %Attributes
	Class attributes:
	
	code - code the programmer uses (LOCAL, CDN); consider <Crop::File> descendant
	name - short name
=cut
our %Attributes = (
	code => {mode => 'read'},
	name => undef,
);

=begin nd
Method: Table ( )
	Table in the Warehouse.

Returns:
	'filewarehouse' string
=cut
sub Table { 'filewarehouse' }

1;
