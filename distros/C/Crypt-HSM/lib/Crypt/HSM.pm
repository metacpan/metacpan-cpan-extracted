package Crypt::HSM;
$Crypt::HSM::VERSION = '0.008';
use strict;
use warnings;

use XSLoader;
XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

1;

#ABSTRACT: A PKCS11 interface for Perl

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::HSM - A PKCS11 interface for Perl

=head1 VERSION

version 0.008

=head1 SYNOPSIS

 my $hsm = Crypt::HSM->load('/usr/lib/pkcs11/libsofthsm2.so');
 my ($slot) = $hsm->slots;
 my $session = $hsm->open_session($slot);
 $session->login('user', '1234');

 my ($key) = $session->find_objects({ class => 'secret-key', label => "my-key" });
 my $ciphertext = $session->encrypt('aes-gcm', $key, $plaintext, $iv);

=head1 DESCRIPTION

This module interfaces with any PKCS11 library to use its cryptography.

=head1 METHODS

=head2 load($path)

This loads the pkcs11 found a $path, and returns it as a new Crypt::HSM object.

=head2 slots($available = 1)

This lists the slots of this interface. If C<$available> is true only slots with a token available will be listed.

=head2 mechanisms($slot)

This returns all mechanisms supported by the token in the slot.

=head2 mechanism_info($slot, $mechanism)

This returns more information about the mechanism. This includes the following fields.

=over 4

=item * min-key-size

The minimum key size

=item * max-key-size

The maximum key size

=item * flags

This array lists properties of the mechanism. It may contain values like C<'encrypt'>, C<'decrypt'>, C<'sign'>, C<'verify'>, C<'generate'>, C<'wrap'> and C<'unwrap'>.

=back

=head2 open_session($slot, $flags = [])

This opens a session to C<$slot>. C<$flag> is an optional array that may currenlt contain the value C<'rw-session'> to enable writing to the token. This returns a Crypt::HSM::Session object.

=head2 close_all_sessions($slot)

This closes all sessions on C<$slot>.

=head2 info()

This returns a hash with information about the HSM.

=head2 slot_info($slot)

This returns a hash with information about the slot.

=head2 token_info($slot)

This returns a hash with information about the token in the slot.

=head2 init_token($slot, $pin, $label)

This initializes a token on C<$slot>, with the associalted C<$pin> and C<$label> (max 32 characters).

=head1 AUTHOR

Leon Timmermans <leont@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
