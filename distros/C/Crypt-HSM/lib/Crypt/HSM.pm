package Crypt::HSM;
$Crypt::HSM::VERSION = '0.023';
use strict;
use warnings;

use XSLoader;
XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

# Pure-perl backwards compatibility methods
use Crypt::HSM::Mechanism;

1;

#ABSTRACT: A PKCS11 interface for Perl

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::HSM - A PKCS11 interface for Perl

=head1 VERSION

version 0.023

=head1 SYNOPSIS

 my $provider = Crypt::HSM->load('/usr/lib/pkcs11/libsofthsm2.so');
 my ($slot) = $provider->slots or die "No slots available";
 my $session = $slot->open_session;
 $session->login('user', '1234');

 my %key_attrs = (label => 'my-key', class => 'secret-key');
 my ($key) = $session->find_objects(\%key_attrs)
     or die "No such key 'my-key'";
 my $iv = $session->generate_random(16);
 my $ciphertext = $session->encrypt('aes-gcm', $key, $plaintext, $iv);

=head1 DESCRIPTION

This module interfaces with any PKCS11 library to use its cryptography.

=over 4

=item * L<Provider|Crypt::HSM::Provider>

This represents a PKCS11 provider, typically a piece of cryptographic hardware. A provider may have one or more slots.

=item * L<Slot|Crypt::HSM::Slot>

This represents a slot on the provider. A slot may or may not contain a token; this distinction is only relevant on providers that can swap tokens (e.g. smartcard readers), on others there will always be a token in the slot that can't be swapped. A token is a data container, and as such performs cryptographic operations for its sessions.

=item * L<Session|Crypt::HSM::Session>

This represents a session on a token / slot. It may be read-only or read-write; It may or may not be authenticated. It may contain session data (e.g. keys not stored on the token) in addition to the token data.

=item * L<Stream|Crypt::HSM::Stream>

This represents a cryptographic stream. There are two types of stream that produce a result of similar length as the input: L<encrypt|Crypt::HSM::Encrypt> and L<decrypt|Crypt::HSM::Decrypt>; and 2 that return a fixed sized product: L<digest|Crypt::HSM::Digest> and L<sign|Crypt::HSM::Sign>; and one that returns a bool: L<verify|Crypt::HSM::Verify>.

=back

=head1 METHODS

=head2 load($path)

This loads the pkcs11 found a $path, and returns it as a new L<Crypt::HSM::Provider|Crypt::HSM::Provider> object.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2023 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
