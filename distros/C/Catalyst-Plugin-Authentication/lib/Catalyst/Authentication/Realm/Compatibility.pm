package Catalyst::Authentication::Realm::Compatibility;

use strict;
use warnings;

use base qw/Catalyst::Authentication::Realm/;

## very funky - the problem here is that we can't do real realm initialization
## but we need a real realm object to function.  So - we kinda fake it - we
## create an empty object -
sub setup_store {}
sub setup_credential {}

__PACKAGE__;

__END__

=pod

=for Pod::Coverage setup_credential setup_store

=head1 NAME

Catalyst::Authentication::Realm::Compatibility - Compatibility realm object

=head1 DESCRIPTION

An empty realm object for compatibility reasons.

=head1 METHODS

=head2 new( )

Returns a, basically empty, realm object.

=cut
