package Crypt::OpenSSL::PKCS12;

use warnings;
use strict;
use Exporter;

our $VERSION = '1.98';
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(NOKEYS NOCERTS INFO CLCERTS CACERTS);

use XSLoader;

XSLoader::load 'Crypt::OpenSSL::PKCS12', $VERSION;

END {
  __PACKAGE__->__PKCS12_cleanup();
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL::PKCS12 - Perl extension to OpenSSL's PKCS12 API.

=head1 SYNOPSIS

  use Crypt::OpenSSL::PKCS12;

  my $pass   = "your password";
  my $pkcs12 = Crypt::OpenSSL::PKCS12->new_from_file('cert.p12');

  print $pkcs12->certificate($pass);
  print $pkcs12->private_key($pass);

  if ($pkcs12->mac_ok($pass)) {
    # MAC verification passed
  }

  # Creating a file
  $pkcs12->create('test-cert.pem', 'test-key.pem', $pass, 'out.p12', 'friendly name');


  # Creating a string
  my $pkcs12_data = $pkcs12->create_as_string('test-cert.pem', 'test-key.pem', $pass, 'friendly name');

  # Reproducing OpenSSL's info
  my $info = $pkcs12->info($pass);

  # Accessing OpenSSL's info as a hash
  my $info_hash = $pkcs12->info_as_hash($pass);

=head1 VERSION

This documentation describes version 1.97 of Crypt::OpenSSL::PKCS12

=head1 DESCRIPTION

PKCS12 is a file format for storing cryptography objects as a single file or string. PKCS12 is commonly used to bundle a private key with its X.509 certificate or to bundle all the members of a chain of trust.

This distribution implements a subset of OpenSSL's PKCS12 API.

=head1 SUBROUTINES/METHODS

=over 4

=item * new( )

Create an empty Crypt::OpenSSL::PKCS12 object. Use C<new_from_string()> or
C<new_from_file()> to load an existing PKCS12 structure.

=item * legacy_support ( )

Returns true if the legacy provider has been successfully loaded by a prior
constructor call (C<new_from_string()> or C<new_from_file()>). Always returns
true on OpenSSL 1.x (where the legacy provider concept does not apply). On
OpenSSL 3.x, returns true only if the legacy provider was loaded during the
most recent constructor call; calling C<legacy_support()> before constructing
an object may return false even if the provider is loadable.

=item * new_from_string( C<$string> )

=item * new_from_file( C<$filename> )

Create a new Crypt::OpenSSL::PKCS12 instance from a binary PKCS12 string or
from a file path respectively. Both forms croak on error (invalid format,
unreadable file, OpenSSL parse failure). The binary string passed to
C<new_from_string()> must not carry Perl's UTF-8 flag; use
C<Encode::encode('octets', $str)> if needed.

=item * certificate( [C<$pass>] )

Returns the end-entity certificate as a PEM-encoded string (Base64 with
C<-----BEGIN CERTIFICATE-----> / C<-----END CERTIFICATE-----> headers).
C<$pass> is required when the PKCS12 file is password-protected. Returns an
empty string if the password is wrong or no client certificate is present.

=item * ca_certificate( [C<$pass>] )

Returns any CA certificates in the chain as a concatenated PEM string.
Returns an empty string if no CA certificates are present. C<$pass> is
required when the PKCS12 file is password-protected.

=item * private_key( [C<$pass>] )

Returns the private key as a PEM-encoded string. C<$pass> is required when
the PKCS12 file is password-protected. Returns an empty string if no private
key is present or if decryption fails (wrong password).

=item * as_string( )

Returns the PKCS12 structure as a raw binary DER string. Useful for writing
to a file or transmitting over a network without touching the filesystem.
The in-memory structure is serialized as-is; no password is needed or accepted.

=item * mac_ok( [C<$pass>] )

Verifies the Message Authentication Code (MAC) of the PKCS12 structure using
C<$pass>. Returns true if the MAC is valid. Croaks on failure (wrong
password, corrupted file, or OpenSSL error).

=item * changepass( C<$old>, C<$new> )

Re-encrypts the PKCS12 structure with a new password. C<$old> is the current
password; C<$new> is the replacement. Returns false on failure.

B<Note:> Changing the PKCS12 password is not reliably supported on OpenSSL
3.x; C<changepass()> may return false or fail silently. Consider
re-creating the PKCS12 structure with C<create()> instead.

=item * create( C<$cert>, C<$key>, C<$pass>, C<$output_file>, C<$friendly_name> )

Creates a new PKCS12 file at C<$output_file>. C<$cert> and C<$key> may each be
either a PEM string (detected by a C<"-----"> prefix) or a filesystem path.
C<$pass> is used to encrypt the private key. C<$friendly_name> is optional and
sets the C<friendlyName> bag attribute. Croaks on any OpenSSL error.

=item * create_as_string( C<$cert>, C<$key>, C<$pass>, C<$friendly_name> )

Same as C<create()> but returns the PKCS12 structure as a raw binary DER string
instead of writing to a file. C<$cert> and C<$key> may each be a PEM string or
a filesystem path. C<$friendly_name> is optional. Croaks on any OpenSSL error.

=item * info( C<$pass> )

Returns a string containing the output of information about the pkcs12 file in
the same format as produced by the openssl command:

    openssl pkcs12 -in certs/test_le_1.1.p12 -info -nodes

=item * info_as_hash( C<$pass> )

Places the information about the pkcs12 file, the certificates and keys
in a hash.

The format of the hash is complex to represent the data in the PKCS12 file:

Essentially, the hash follows the format of the -info output.

1. pkcs7_data and pkcs7_encrypted_data are arrays as more than one of each can exist
2. mac provieds the top level mac parameters for the file
3. safe_contents_bag is an array that contains an array of bags
4. bags is an array of bags
5. a bag is a container for a key or certificate

Each bag has a type and the following are available:

1. key_bag
2. certificate_bag
3. shrouded_keybag
4. secret_bag
5. safe_contents_bag

{
    mac                    {
        digest        "sha1",
        iteration     2048,
        length        20,
        salt_length   20
    },
    pkcs7_data             [
        [0] {
                bags   [
                    [0] {
                            bag_attributes   {
                                friendlyName   "...",
                                localKeyID     "54"
                            },
                            key              "...",
                            key_attributes   {
                                "X509v3 Key Usage"   10
                            },
                            parameters       {
                                iteration        10000,
                                nid_long_name    "PBKDF2",
                                nid_short_name   "PBKDF2"
                            },
                            type             "shrouded_keybag"
                        }
                ]
            },
        [1] {
                safe_contents_bag   [
                    [0] {
                            bags   [
                                [0] {
                                        bag_attributes   {
                                            localKeyID   "01"
                                            friendlyName   "",
                                        },
                                        cert             "...".
                                        issuer           "...",
                                        subject          "...",
                                        type             "certificate_bag"
                                        }
                            ],
                            type   "safe_contents_bag"
                        }
                ]
            },
        [2] {
                bags   [
                    [0] {
                            bag_attributes   {
                                localKeyID   "02"
                            },
                            cert             "...",
                            issuer           "...",
                            subject          "...",
                            type             "certificate_bag"
                        }
                ]
            },
    ],
    pkcs7_encrypted_data   [
        [0] {
                bags         [
                    [0] {
                            bag_attributes   {
                                2.16.840.1.113894.746875.1.1   "<Unsupported tag 6>",
                                friendlyName                   "..."
                            },
                            cert             "...",
                            issuer           "...",
                            subject          "...",
                            type             "certificate_bag"
                        },
                    [1] {
                            bag_attributes   {
                                friendlyName   "...",
                                localKeyID     "54"
                            },
                            cert             "...",
                            issuer           "...",
                            subject          "...",
                            type             "certificate_bag"
                        }
                ],
                parameters   {
                    iteration        10000,
                    nid_long_name    "PBKDF2",
                    nid_short_name   "PBKDF2"
                }
            }
    ]
}

Attributes such as C<localKeyID> are stored as plain hex strings (e.g.
C<"54">, C<"01">). Always treat these values as strings in code.

=back

=head1 EXPORTS

None by default.

On request:

=over 4

=item * C<NOKEYS>

Flag: suppress output of private keys.

=item * C<NOCERTS>

Flag: suppress output of certificates.

=item * C<INFO>

Flag: enable structural info output (used internally by C<info()> and
C<info_as_hash()>; output is returned as a string or hash, not printed).

=item * C<CLCERTS>

Flag: output only client (end-entity) certificates.

=item * C<CACERTS>

Flag: output only CA certificates.

=back

These flags mirror the corresponding C<-nokeys>, C<-nocerts>, C<-info>,
C<-clcerts>, and C<-cacerts> options of the C<openssl pkcs12> command.

=head1 DIAGNOSTICS

=over 4

=item * B<"OpenSSL error: ..."> — an OpenSSL call failed. The trailing
message is taken from C<ERR_reason_error_string()> and identifies the
specific failure (e.g. C<"bad decrypt"> for a wrong password).

=item * B<"Error opening ..."> — C<create()> could not open the specified
output file path for writing.

=back

=head1 CONFIGURATION AND ENVIRONMENT

No special environment or configuration is required.

=head1 DEPENDENCIES

This distribution has the following dependencies

=over

=item * An installation of OpenSSL, either version 1.X.X or version 3.X.X

=item * Perl 5.14

=back

=head1 SEE ALSO

=over

=item * OpenSSL(1) (L<HTTP version with OpenSSL.org|https://www.openssl.org/docs/manmaster/man1/openssl.html>)

=item * L<Crypt::OpenSSL::X509|https://metacpan.org/pod/Crypt::OpenSSL::X509>

=item * L<Crypt::OpenSSL::RSA|https://metacpan.org/pod/Crypt::OpenSSL::RSA>

=item * L<Crypt::OpenSSL::Bignum|https://metacpan.org/pod/Crypt::OpenSSL::Bignum>

=item * L<OpenSSL.org|https://www.openssl.org/>

=item * L<Wikipedia: OpenSSL|https://en.wikipedia.org/wiki/OpenSSL>

=item * L<Wikipedia: PKCS12|https://en.wikipedia.org/wiki/PKCS_12>

=item * L<RFC:7292: "PKCS #12: Personal Information Exchange Syntax v1.1"|https://datatracker.ietf.org/doc/html/rfc7292>

=back

=head1 INCOMPATIBILITIES

Currently the library has been updated to support both OpenSSL 1.X.X and OpenSSL 3.X.X

=head1 BUGS AND LIMITATIONS

Please see the L<GitHub repository|https://github.com/dsully/perl-crypt-openssl-pkcs12/issues> for known issues.

=head1 AUTHOR

=over

=item * Dan Sully, E<lt>daniel@cpan.orgE<gt>

=back

Current maintainer

=over

=item * jonasbn

=back

=head1 CONTRIBUTORS

In alphabetical order, contributors, bug reporters and all

=over

=item * @mmuehlenhoff

=item * @sectokia

=item * @SmartCodeMaker

=item * Alexandr Ciornii, @chorny

=item * Christopher Hoskin, @mans0954

=item * Daisuke Murase, @typester

=item * Darko Prelec, @dprelec

=item * David Steinbrunner, @dsteinbrunner

=item * Gianni Ceccarelli, @dakkar

=item * Giuseppe Di Terlizzi, @giterlizzi

=item * H.Merijn Brand, @tux

=item * Hakim, @osfameron

=item * J. Nick Koston, @bdraco

=item * James Rouzier, @jrouzierinverse

=item * jonasbn. @jonasbn

=item * Kelson, @kelson42

=item * Lance Wicks, @lancew

=item * Leonid Antonenkov

=item * Masayuki Matsuki, @songmu

=item * Mikołaj Zalewski

=item * Shoichi Kaji

=item * Slaven Rezić

=item * Timothy Legge, @timlegge

=item * Todd Rinaldo, @toddr

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2004 by Dan Sully

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
