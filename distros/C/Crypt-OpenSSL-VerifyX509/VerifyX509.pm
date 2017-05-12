package Crypt::OpenSSL::VerifyX509;

use strict;
use warnings;

require 5.008_001;

our $VERSION = '0.10';

use Crypt::OpenSSL::X509;

BOOT_XS: {
	require DynaLoader;
	
	# DynaLoader calls dl_load_flags as a static method.
	*dl_load_flags = DynaLoader->can('dl_load_flags');
	
	do {__PACKAGE__->can('bootstrap') || \&DynaLoader::bootstrap}->(__PACKAGE__, $VERSION);
}

END {
	__PACKAGE__->__X509_cleanup;
}

1;

__END__

=pod

=head1 NAME

Crypt::OpenSSL::VerifyX509 - simple certificate verification

=head1 SYNOPSIS

  use Crypt::OpenSSL::VerifyX509;
  use Crypt::OpenSSL::X509;

  my $ca = Crypt::OpenSSL::VerifyX509->new('t/cacert.pem');

  my $cert = Crypt::OpenSSL::X509->new(...);
  $ca->verify($cert);

=head1 DESCRIPTION

Given a CA certificate and another untrusted certificate, will show
whether the CA signs the certificate. This is a useful thing to have
if you're signing with X509 certificates, but outside of SSL.

A specific example is where you're working with XML signatures, and
need to verify that the signing certificate is valid. 

You could use Crypt::OpenSSL::CA to do this, but it is based on
Inline::C, which can be troublesome in some situations. This module
provides an XS alternative for the certificate verify feature.

=head1 METHODS

=head2 new($ca_path)

Constructor. Returns a VerifyX509 instance, set up with the given CA. 

Arguments:

 * $ca_path - path to a file containing the CA certificate

=head2 verify($cert)

Verify the certificate is signed by the CA. Returns true if so, and
croaks with the verification error if not.

Arguments:

 * $cert - a Crypt::OpenSSL::X509 object for the certificate to verify.

=head1 AUTHOR

Chris Andrews <chrisandrews@venda.com>

=head1 COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright 2010 Venda Ltd.

=head1 LICENCE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
