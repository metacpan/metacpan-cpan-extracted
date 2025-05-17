package Crop::Type::Status;
use base qw/ Crop::Object::Simple Exporter /;

=begin nd
Class: Crop::Type::Status
	Status of any Object.

	Status are:

	- ACTIVE
	- DEL
	- HIDE
	- ARCH
    - WAIT

=cut

use v5.14;
use warnings;

our @EXPORT = qw/ STATUS_ACTIVE STATUS_DEL STATUS_HIDE STATUS_ARCH /;

use constant {
	STATUS_ACTIVE => 1,
	STATUS_DEL    => 2,
	STATUS_HIDE   => 3,
	STATUS_ARCH   => 4,
	STATUS_WAIT   => 5,
};

=begin nd
Variable: our %Attributes
	Attributes:

	code        - for use in Perl
	description - description
	id          - from <Crop::Object::Simple>
	name        - unique name
=cut
our %Attributes = (
	code        => undef,
	description => undef,
	name        => undef,
);

=begin nd
Method: Table ( )
        Table in Warehouse.

Returns:
        'status' string
=cut
sub Table { 'status' }

1;
