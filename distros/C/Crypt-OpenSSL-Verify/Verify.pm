package Crypt::OpenSSL::Verify;

use strict;
use warnings;

require 5.010;

our $VERSION = '0.23';

use Crypt::OpenSSL::X509;

BOOT_XS: {
    require DynaLoader;

    # DynaLoader calls dl_load_flags as a static method.
    *dl_load_flags = DynaLoader->can('dl_load_flags');

    do { __PACKAGE__->can('bootstrap') || \&DynaLoader::bootstrap }
      ->( __PACKAGE__, $VERSION );
}

# Register the sub pcb1
register_verify_cb( \&verify_callback );

sub verify_callback {
    my ( $ok, $ctx ) = @_;
    my $cert_error = ctx_error_code($ctx);

    if ( !$ok ) {
        if ( $cert_error == 10 ) {
            # X509_V_ERR_CERT_HAS_EXPIRED:
            $ok = 1;
        }
        elsif ( $cert_error == 18 ) {
            # X509_V_ERR_DEPTH_ZERO_SELF_SIGNED_CERT:
            $ok = $ok; # Disabled not in Verify509
        }
        elsif ( $cert_error == 24 ) {
            # X509_V_ERR_INVALID_CA:
            $ok = 1;
        }
        elsif ( $cert_error == 25 ) {
            # X509_V_ERR_PATH_LENGTH_EXCEEDED:
            $ok = 1;
        }
        elsif ( $cert_error == 26 ) {
            # X509_V_ERR_INVALID_PURPOSE:
            $ok = 1;
        }
        elsif ( $cert_error == 12 ) {
            # X509_V_ERR_CRL_HAS_EXPIRED:
            $ok = 1;
        }
        elsif ( $cert_error == 11 ) {
            # X509_V_ERR_CRL_NOT_YET_VALID:
            $ok = 1;
        }
        elsif ( $cert_error == 34 ) {
            # X509_V_ERR_UNHANDLED_CRITICAL_EXTENSION:
            $ok = 1;
        }

        # Disabled for Crypt::OpenSSL::VerifyX509 Compatability
        #elsif ($cert_error == 21) {
        #    # X509_V_ERR_UNABLE_TO_VERIFY_LEAF_SIGNATURE:
        #    $ok = 1;
        #}
        #elsif ($cert_error == 20) {
        #    # X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT_LOCALLY:
        #    $ok = 1;
        #}
        #elsif ($cert_error == 43) {
        #    # X509_V_ERR_NO_EXPLICIT_POLICY
        #    $ok = 1;
        #}
        #elsif ($cert_error == 37) {
        #    # X509_V_ERR_INVALID_NON_CA:
        #    $ok = 1;
        #}
    }

    return $ok;

}

END {
    __PACKAGE__->__X509_cleanup;
}

1;

__END__

=pod

=head1 NAME

Crypt::OpenSSL::Verify - OpenSSL Verify certificate verification in XS.

=head1 SYNOPSIS

  use Crypt::OpenSSL::Verify;
  use Crypt::OpenSSL::X509;

  my $ca = Crypt::OpenSSL::Verify->new(
      't/cacert.pem', # or undef
      {
          CApath   => '/etc/ssl/certs',    # Optional
          noCAfile => 1,                   # Optional
          noCApath => 0                    # Optional
      }
  );

  # Backward compatible with Crypt::OpenSSL:VerifyX509
  my $ca = Crypt::OpenSSL::Verify->new('t/cacert.pem');

  # Using the defaults of your OS:
  my $ca = Crypt::OpenSSL::Verify->new();

  # and later on..

  my $cert = Crypt::OpenSSL::X509->new(...);
  $ca->verify($cert);


The object created is similar to running the following command with the
C<openssl verify> command line tool: C<< openssl verify [ -CApath /path/to/certs ]
[ -noCApath ] [ -noCAfile ] [ -CAfile /path/to/file ] cert.pem >>

=head1 DESCRIPTION

Given a CA certificate and another untrusted certificate, will show
whether the CA signs the certificate. This is a useful thing to have
if you're signing with X509 certificates, but outside of SSL.

A specific example is where you're working with XML signatures, and
need to verify that the signing certificate is valid.

=head1 METHODS

=head2 new()

Constructor. Returns an OpenSSL Verify instance, set up with the given CA.

    my $ca = Crypt::OpenSSL::Verify->new(
        't/cacert.pem',   # or undef
        {
            # Path to a directory containg hashed CA Certificates
            CApath => $ca_path,

            # Default CAfile should not be loaded if TRUE, defaults to FALSE
            noCAfile => 0,

            # Default CApath should not be loaded if TRUE, defaults to FALSE
            noCApath => 0,

            # Do not override any OpenSSL verify errors if FALSE, defaults to TRUE
            strict_certs => 1,
        }
    );

    # Backward compatible with Crypt::OpenSSL:VerifyX509
    my $ca = Crypt::OpenSSL::Verify->new('t/cacert.pem', {strict_certs => 0 });

    # Using the defaults of your OS:
    my $ca = Crypt::OpenSSL::Verify->new();

=head2 verify($cert)

Verify the certificate is signed by the CA. Returns true if so, and
croaks with the verification error if not.

Arguments:

 * $cert - a Crypt::OpenSSL::X509 object for the certificate to verify.

=head2 ctx_error_code($ctx)

Calls the C code to obtain the OpenSSL error code of the verify and
returns an integer value

Arguments:

  * $ctx - a long unsigned integer containing the  pointer to the
        X509_STORE_CTX that was passed to the callback function
        during the certificate verification

=head2 register_verify_cb(\&verify_callback);

Registers a Perl Sub as the callback function for OpenSSL to call
during the registration process

Arguments:

  * \&verify_callback - a reference to the verify_callback sub

=head2 verify_callback($ok, $ctx)

Called directly by OpenSSL and in the case of an acceptable error will
change the response to 1 to signify no error

Arguements:

  $ok - Error (0) or Success (1) from the OpenSSL certificate verification
        results

  $ctx - value of the pointer to the Certificate Store CTX used to access the
        error codes that OpenSSL returned

=head1 AUTHOR

=over

=item Timothy Legge <timlegge@gmail.com>

=item Wesley Schwengle <waterkip@cpan.org>

=back

=head1 COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

=over

=item Copyright 2020 Timothy Legge

=item Copyright 2020 Wesley Schwengle

=back

Based on the Original Crypt::OpenSSL::VerifyX509 by

=over

=item Copyright 2010 Chris Andrews <chrisandrews@venda.com>

=back

=head1 LICENCE

This library is free software; you can redistribute it and/or modify
it under the same terms as OpenSSL and is covered by the dual
OpenSSL and SSLeay license.

=cut
