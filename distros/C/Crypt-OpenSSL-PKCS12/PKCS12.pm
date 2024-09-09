package Crypt::OpenSSL::PKCS12;

use warnings;
use strict;
use Exporter;

our $VERSION = '1.92';
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
  ...

  # Creating a file
  $pkcs12->create('test-cert.pem', 'test-key.pem', $pass, 'out.p12', 'friendly name');


  # Creating a string
  my $pksc12_data = $pkcs12->create_as_string('test-cert.pem', 'test-key.pem', $pass, 'friendly name');

  # Reproducing OpenSSL's info
  my $info = $pkcs12->info($pass);

  # Accessing OpenSSL's info as a hash
  my $info_hash = $pkcs12->info_as_hash($pass);

=head1 VERSION

This documentation describes version 1.92

=head1 DESCRIPTION

PKCS12 is a file format for storing cryptography objects as a single file or string. PKCS12 is commonly used to bundle a private key with its X.509 certificate or to bundle all the members of a chain of trust.

This distribution implements a subset of OpenSSL's PKCS12 API.

=head1 SUBROUTINES/METHODS

=over 4

=item * new( )

=item * new_from_string( C<$string> )

=item * new_from_file( C<$filename> )

Create a new Crypt::OpenSSL::PKCS12 instance.

=item * certificate( [C<$pass>] )

Get the Base64 representation of the certificate.

=item * private_key( [C<$pass>] )

Get the Base64 representation of the private key.

=item * as_string( [C<$pass>] )

Get the binary represenation as a string.

=item * mac_ok( [C<$pass>] )

Verifiy the certificates Message Authentication Code

=item * changepass( C<$old>, C<$new> )

Change a certificate's password.

=item * create( C<$cert>, C<$key>, C<$pass>, C<$output_file>, C<$friendly_name> )

Create a new PKCS12 certificate. $cert & $key may either be strings or filenames.

C<$friendly_name> is optional.

=item * create_as_string( C<$cert>, C<$key>, C<$pass>, C<$friendly_name> )

Create a new PKCS12 certificate string. $cert & $key may either be strings or filenames.

C<$friendly_name> is optional.

Returns a string holding the PKCS12 certicate.

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
                                localKeyID     "..." (dualvar: 54)
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
                                            localKeyID   "01" (dualvar: 1)
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
                                localKeyID   "02" (dualvar: 2)
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
                                localKeyID     "..." (dualvar: 54)
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

=back

=head1 EXPORTS

None by default.

On request:

=over 4

=item * C<NOKEYS>

=item * C<NOCERTS>

=item * C<INFO>

=item * C<CLCERTS>

=item * C<CACERTS>

=back

=head1 DIAGNOSTICS

No diagnostics are documented at this time

=head1 CONFIGURATION AND ENVIRONMENT

No special environment or configuration is required.

=head1 DEPENDENCIES

This distribution has the following dependencies

=over

=item * An installation of OpenSSL, either version 1.X.X or version 3.X.X

=item * Perl 5.8

=back

=head1 SEE ALSO

=over

=item * OpenSSL(1) (L<HTTP version with OpenSSL.org|https://www.openssl.org/docs/man1.1.1/man1/openssl.html>)

=item * L<Crypt::OpenSSL::X509|https://metacpan.org/pod/Crypt::OpenSSL::X509>

=item * L<Crypt::OpenSSL::RSA|https://metacpan.org/pod/Crypt::OpenSSL::RSA>

=item * L<Crypt::OpenSSL::Bignum|https://metacpan.org/pod/Crypt::OpenSSL::Bignum>

=item * L<OpenSSL.org|https://www.openssl.org/>

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

Copyright 2004-2024 by Dan Sully

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
