package Crypt::NSS::PKCS11::Slot

use strict;
use warnings;

1;
__END__

=head1 NAME

Crypt::NSS::PKCS11::Slot - Represents a physical or logical PKCS#11 slot.

=head1 INTERFACE

=head2 INSTANCE METHODS

=over 4

=item slot_name ( ) : string

Returns the name of the slot.

=item token_name ( ) : string

Returns the name of the token.

=item is_hardware () : boolean

Returns whether the slot is implemented in hardware or software.

=item is_present ( ) : boolean

Returns whether the slot is available or not.

=item is_readonly ( ) : boolean

Returns whether the slot is read-only.

=back

=cut