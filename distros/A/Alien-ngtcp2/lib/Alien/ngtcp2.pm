package Alien::ngtcp2;

use strict;
use warnings;
use parent 'Alien::Base';

our $VERSION = '0.03';

sub crypto_backend {
    my ($class) = @_;

    return $class->runtime_prop->{my_crypto_backend};
}

sub crypto_package {
    my ($class) = @_;

    return $class->runtime_prop->{my_crypto_package};
}

sub crypto_cflags {
    my ($class) = @_;

    my $flags
        = $class->alt($class->crypto_package)->cflags;
    my $openssl
        = $class->runtime_prop->{my_openssl_cflags} || '';

    return join ' ', grep { length } $flags, $openssl;
}

sub crypto_libs {
    my ($class) = @_;

    my $helper = $class->alt($class->crypto_package);
    my $picotls = $class->runtime_prop->{my_picotls_libs} || '';
    my $openssl = $class->runtime_prop->{my_openssl_libs} || '';

    return join ' ', grep { length }
        $helper->libs,
        $picotls,
        $class->libs,
        $openssl;
}

1;

__END__

=head1 NAME

Alien::ngtcp2 - Find or build the native libraries needed for QUIC

=head1 SYNOPSIS

    use Alien::ngtcp2;

    my $cflags = Alien::ngtcp2->cflags;
    my $libs   = Alien::ngtcp2->libs;

    my $crypto_cflags = Alien::ngtcp2->crypto_cflags;
    my $crypto_libs   = Alien::ngtcp2->crypto_libs;

=head1 DESCRIPTION

Alien::ngtcp2 supplies the native ngtcp2 libraries needed by Perl QUIC
distributions.

QUIC needs two native pieces:

=over 4

=item * C<libngtcp2>, which handles the QUIC protocol

=item * a TLS helper, which connects ngtcp2 to TLS 1.3

=back

Alien::ngtcp2 uses Picotls for the TLS helper. Picotls is small, designed for
TLS 1.3, and works well with QUIC.

OpenSSL is used underneath Picotls for cryptography and X.509 certificate
handling. OpenSSL is not used as the QUIC TLS implementation.

=head1 HOW INSTALLATION WORKS

Alien::ngtcp2 builds a tested pair:

    ngtcp2 1.25.0
    Picotls commit f07f1c8c68b237f1468bc1f1fe1b68aba3ff23b4

The pair is built together instead of reusing an arbitrary system
C<libngtcp2_crypto_picotls>. The system helper does not record which Picotls
revision it was built against.

On Unix-like systems, a system OpenSSL 1.1.1 or newer is used when available.
If no suitable OpenSSL development installation is available,
L<Alien::OpenSSL> can provide one.

=head2 Windows

On Windows, Alien::ngtcp2 uses the OpenSSL that belongs to the active Perl and
compiler toolchain.

If that OpenSSL is older than 1.1.1, installation stops with a clear error.
Alien::ngtcp2 does not silently install a second TLS stack on Windows.

Historical Strawberry Perl 5.28 contains OpenSSL 1.1.0j and is therefore too
old. Strawberry Perl 5.30 and newer meet the required baseline.

=head1 METHODS

=head2 cflags

Returns compiler flags for the core C<libngtcp2> library.

=head2 libs

Returns linker flags for the core C<libngtcp2> library.

=head2 crypto_backend

Returns C<picotls>.

This method remains available so downstream distributions written for
Alien::ngtcp2 0.02 do not need an API change.

=head2 crypto_package

Returns C<libngtcp2_crypto_picotls>.

=head2 crypto_cflags

Returns the compiler flags needed to use the ngtcp2 Picotls helper.

=head2 crypto_libs

Returns the linker flags needed to use the ngtcp2 Picotls helper.

=head1 VERSIONS

Alien::ngtcp2 requires Perl 5.20 or newer and Alien::Build 2.84 or newer.

The bundled ngtcp2 source is version 1.25.0.

=head1 BUNDLED PICOTLS SOURCE

Alien::ngtcp2 contains the MIT-licensed Picotls TLS core and OpenSSL binding
from commit:

  f07f1c8c68b237f1468bc1f1fe1b68aba3ff23b4

This is the Picotls revision documented by ngtcp2 1.25.0.

The Picotls minicrypto backend and its third-party dependencies are not
included.

=head1 SEE ALSO

L<Alien::Base>

L<Alien::OpenSSL>

L<https://github.com/ngtcp2/ngtcp2>

L<https://github.com/h2o/picotls>

=head1 AUTHOR

Joshua S. Day

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Joshua S. Day.

This is free software, licensed under:

    The MIT (X11) License

=cut
