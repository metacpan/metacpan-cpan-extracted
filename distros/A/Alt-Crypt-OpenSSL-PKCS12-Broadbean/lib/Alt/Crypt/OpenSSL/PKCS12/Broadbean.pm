package Alt::Crypt::OpenSSL::PKCS12::Broadbean;
use strict;
use warnings;
our $VERSION='1.02';
our $CRYPT_OPENSSL_PKCS12_VERSION='1.93';

__END__

=head1 NAME

Alt::Crypt::OpenSSL::PKCS12::Broadbean - extend Crypt::OpenSSL::PKCS12 to extract CA certs

=head1 SYNOPSIS

  cpanm Alt::Crypt::OpenSSL::PKCS12::Broadbean
  perl -MCrypt::OpenSSL::PKCS12 -e1

=head1 DESCRIPTION

This fork adds the C<ca_certificate> method to extract the CA
certificate chain from a PKCS#12 input.

=head1 GLOBALS

=head2 C<$VERSION>

The version of this module

=head2 C<$CRYPT_OPENSSL_PKCS12_VERSION>

The version of L<Crypt::OpenSSL::PKCS12> that ships with this module

=head1 RELEASING

  cpanm Dist::Zilla
  dzil authordeps --missing | cpanm
  dzil listdeps | cpanm
  dzil release

=head1 SEE ALSO

C<Alt::*> namespace

L<Crypt::OpenSSL::PKCS12> for the credits
