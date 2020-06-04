package Crypt::OpenSSL::PKCS12;

use strict;
use Exporter;

our $VERSION = '1.3';
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(NOKEYS NOCERTS INFO CLCERTS CACERTS);

use XSLoader;

XSLoader::load 'Crypt::OpenSSL::PKCS12', $VERSION;

END {
  __PACKAGE__->__PKCS12_cleanup();
}

1;

__END__

=head1 NAME

Crypt::OpenSSL::PKCS12 - Perl extension to OpenSSL's PKCS12 API.

=head1 SYNOPSIS

  use Crypt::OpenSSL::PKCS12;

  my $pass   = "your password";
  my $pkcs12 = Crypt::OpenSSL::PKCS12->new_from_file('cert.p12');

  print $pkcs12->certificate($pass);
  print $pkcs12->private_key($pass);

  if ($pkcs12->mac_ok($pass)) {
  ....

  $pkcs12->create('test-cert.pem', 'test-key.pem', $pass, 'out.p12', "friendly name");

=head1 ABSTRACT

  Crypt::OpenSSL::PKCS12 - Perl extension to OpenSSL's PKCS12 API.

=head1 DESCRIPTION

  This implements a small bit of OpenSSL's PKCS12 API.

=head1 FUNCTIONS

=over 4

=item * new( )

=item * new_from_string( $string )

=item * new_from_file( $filename )

Create a new Crypt::OpenSSL::PKCS12 instance.

=item * certificate( [$pass] )

Get the Base64 representation of the certificate.

=item * private_key( [$pass] )

Get the Base64 representation of the private key.

=item * as_string( [$pass] )

Get the binary represenation as a string.

=item * mac_ok( [$pass] )

Verifiy the certificates Message Authentication Code

=item * changepass( $old, $new )

Change a certificate's password.

=item * create( $cert, $key, $pass, $output_file, $friendly_name )

Create a new PKCS12 certificate. $cert & $key may either be strings or filenames.

$friendly_name is optional.

=back

=head1 EXPORT

None by default.

On request:

=over 4

=item * NOKEYS

=item * NOCERTS

=item * INFO

=item * CLCERTS

=item * CACERTS

=back

=head1 SEE ALSO

OpenSSL(1), Crypt::OpenSSL::X509, Crypt::OpenSSL::RSA, Crypt::OpenSSL::Bignum

=head1 AUTHOR

Dan Sully, E<lt>daniel@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2018 by Dan Sully

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
