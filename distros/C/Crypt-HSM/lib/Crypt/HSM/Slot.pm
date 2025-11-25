package Crypt::HSM::Slot;
$Crypt::HSM::Slot::VERSION = '0.025';
use strict;
use warnings;

# Contains the actual implementation
use Crypt::HSM;

1;

#ABSTRACT: A PKCS11 slot

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::HSM::Slot - A PKCS11 slot

=head1 VERSION

version 0.025

=head1 SYNOPSIS

 my $session = $slot->open_session;

=head1 DESCRIPTION

This represents a slot on a PKCS implementation.

=head1 METHODS

=head2 open_session(%flags)

This opens a L<Crypt::HSM::Session|Crypt::HSM::Session> to this slot. It takes named arguments arguments, currently only one is defined:

=over 4

=item * C<rw-session>

If set to a true value, a read-write session is opened.

=back

=head2 mechanisms()

This returns all mechanisms supported by the token in the slot as L<Crypt::HSM::Mechanism|Crypt::HSM::Mechanism> objects.

=head2 mechanism($name)

This returns the named mechanism as a L<Crypt::HSM::Mechanism|Crypt::HSM::Mechanism> object.

=head2 id()

This returns the identifier of this slot.

=head2 close_all_sessions()

This closes all sessions on this slot.

=head2 info()

This returns a hash with information about the slot. This contains the following entries:

=over 4

=item * C<description>

Description of the slot.

=item * C<manufacturer-id>

ID of the slot manufacturer.

=item * C<flags>

Flags on the slot, this hash contains of the following entries""

=over 4

=item * C<token-present>

True if a token is present in the slot (e.g., a device is in the reader).

=item * C<removable-device>

True if the reader supports removable devices.

For a given slot, the value of this flag never changes. In addition, if this flag is not set for a given slot, then the C<token-present> flag for that slot is always set.  That is, if a slot does not support a removable device, then that slot always has a token in it.

=item * C<hw-slot>

True if the slot is a hardware slot, as opposed to a software slot implementing a “soft token”.

=back

=item * C<hardware-version>

Version number of the slot’s hardware

=item * C<firmware-version>

Version number of the slot’s firmware

=back

=head2 token_info()

This returns a hash with information about the token in the slot. This contains the following entries:

=over 4

=item * C<label>

Application-defined label, assigned during token initialization.

=item * C<manufacturer-id>

ID of the device manufacturer.

=item * C<model>

Model of the device.

=item * C<serial-number>

Serial number of the device.

=item * C<flags>

Flags on the slot, this hash contains the following entries:

=over 4

=item * C<rng>

True if the token has its own random number generator

=item * C<write-protected>

True if the token is write-protected (see below)

=item * C<login-required>

True if there are some cryptographic functions that a user MUST be logged in to perform

=item * C<user-pin-initialized>

True if the normal user’s PIN has been initialized

=item * C<restore-key-not-needed>

True if a successful save of a session’s cryptographic operations state always contains all keys needed to restore the state of the session

=item * C<clock-on-token>

True if token has its own hardware clock

=item * C<protected-authentication-path>

True if token has a “protected authentication path”, whereby a user can log into the token without passing a PIN through the Cryptoki library

=item * C<dual-crypto-operations>

True if a single session with the token can perform dual cryptographic operations

=item * C<token-initialized>

True if the token has been initialized using C<init_token> or an equivalent mechanism outside the scope of this standard. Calling C<init_token> when this flag is set will cause the token to be reinitialized.

=item * C<secondary-authentication>

True if the token supports secondary authentication for private key objects (deprecated).

=item * C<user-pin-count-low>

True if an incorrect user login PIN has been entered at least once since the last successful authentication.

=item * C<user-pin-final-try>

True if supplying an incorrect user PIN will cause it to become locked.

=item * C<user-pin-locked>

True if the user PIN has been locked. User login to the token is not possible.

=item * C<user-pin-to-be-changed>

True if the user PIN value is the default value set by token initialization or manufacturing, or the PIN has been expired by the card.

=item * C<so-pin-count-low>

True if an incorrect SO login PIN has been entered at least once since the last successful authentication.

=item * C<so-pin-final-try>

True if supplying an incorrect SO PIN will cause it to become locked.

=item * C<so-pin-locked>

True if the SO PIN has been locked. SO login to the token is not possible.

=item * C<so-pin-to-be-changed>

True if the SO PIN value is the default value set by token initialization or manufacturing, or the PIN has been expired by the card.

=item * C<error-state>

True if the token failed a FIPS 140-2 self-test and entered an error state.

=back

=item * C<max-session-count>

Maximum number of sessions that can be opened with the token at one time by a single application

=item * C<session-count>

Number of sessions that this application currently has open with the token

=item * C<max-rw-session-count>

Maximum number of read/write sessions that can be opened with the token at one time by a single application

=item * C<rw-session-count>

Number of read/write sessions that this application currently has open with the token

=item * C<max-pin-len>

Maximum length in bytes of the PIN

=item * C<min-pin-len>

Minimum length in bytes of the PIN

=item * C<total-public-memory>

The total amount of memory on the token in bytes in which public objects may be stored

=item * C<free-public-memory>

The amount of free (unused) memory on the token in bytes for public objects

=item * C<total-private-memory>

The total amount of memory on the token in bytes in which private objects may be stored

=item * C<free-private-memory>

The amount of free (unused) memory on the token in bytes for private objects

=item * C<hardware-version>

Version number of the slot’s hardware

=item * C<firmware-version>

Version number of the slot’s firmware

=item * C<utc-time>

Current time as a character-string of length 16, represented in the format YYYYMMDDhhmmssxx (4 characters for the year;  2 characters each for the month, the day, the hour, the minute, and the second; and 2 additional reserved ‘0’ characters).  The value of this field only makes sense for tokens equipped with a clock, as indicated in the token information flags.

=back

=head2 init_token($pin, $label)

This initializes a token on the slot, with the associalted C<$pin> and C<$label> (max 32 characters).

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
