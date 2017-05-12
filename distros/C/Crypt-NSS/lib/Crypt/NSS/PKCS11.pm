package Crypt::NSS::PKCS11;

use strict;
use warnings;

our $DefaultPinArg;

1;
__END__

=head1 NAME

Crypt::NSS::PKCS11 - Functions needed for communicating with PKCS#11 cryptographic modules

=head1 DESCRIPTION

PKCS#11 is a API for interfacing with cryptographic modules such as software tokens, smart cards. 
This module provides functions for obtaining certificates, keys, passwords etc.

=head1 INTERFACE

=head2 GLOBAL VARIABLES

=over 4

=item $DefaultPinArg

The default PKCS#11 pin arg that can be set on C<Net::NSS::SSL> instances. This is useful when you want to 
set a PKCS#11 pin arg on sockets where you can't control directly what's set to C<new>. This is mostly used when 
you use NSS with LWP.

=back

=head2 CLASS METHODS

=over

=item set_password_hook ( $hook : code | string )

Sets the function to call when a PKCS#11 module needs a password. The argument I<CALLBACK> must be either 
a code reference or a fully qualified function name.

=item find_cert_by_nickname ( $nickname : string, $arg : scalar ) : Crypt::NSS::Certificate

Finds a certificate by nickname. The argument I<$arg> is passed to the hook set by C<set_password_hook>.

=item find_key_by_any_cert ( $certificate : Crypt::NSS::Certificate, $arg : scalar ) : Crypt::NSS::PrivateKey

Finds a private key for a certificate. The argument I<$arg> is passed to the hook set by C<set_password_hook>.

=back

=cut