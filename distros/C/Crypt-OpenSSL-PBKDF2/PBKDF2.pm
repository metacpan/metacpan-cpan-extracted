package Crypt::OpenSSL::PBKDF2;

use strict;
use Carp;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

require Exporter;
require DynaLoader;
use AutoLoader;

@ISA = qw(Exporter DynaLoader);

@EXPORT_OK = qw( derive derive_bin );

$VERSION = '0.11';

bootstrap Crypt::OpenSSL::PBKDF2 $VERSION;

1;
__END__

=head1 NAME

Crypt::OpenSSL::PBKDF2 - wrapper for PBKDF2 keys derivation function of the OpenSSL library

=head1 SYNOPSIS

  use Crypt::OpenSSL::PBKDF2 qw( derive derive_bin );

  # using SHA1 hashing
  $key1 = Crypt::OpenSSL::PBKDF2::derive($pass, $salt, $salt_len, $iter, $key_len);
  $key2 = Crypt::OpenSSL::PBKDF2::derive_bin($pass_bin, $pass_len, $salt, $salt_len, $iter, $key_len);

  # using alternate hashing algorithms
  $key3 = Crypt::OpenSSL::PBKDF2::derive($pass, $salt, $salt_len, $iter, $key_len, 'sha512');
  $key4 = Crypt::OpenSSL::PBKDF2::derive_bin($pass_bin, $pass_len, $salt, $salt_len, $iter, $key_len, 'md5');
  $key5 = Crypt::OpenSSL::PBKDF2::derive_bin($pass_bin, $pass_len, $salt, $salt_len, $iter, $key_len, 'shake256');

=head1 DESCRIPTION

Crypt::OpenSSL::PBKDF2 provides the ability to securely derive a key from a 
password using PBKDF2 function from OpenSSL library (very fast!).
It requires the OpenSSL library is installed on the system.

=head2 EXPORT

None by default.

=head1 Static Methods

=over 2

=item derive

This function returns a derived key that is supposed to be cryptographically 
strong.
The binary output key will be generated from a textual password B<$pass> using
a salt block B<$salt> (usually binary data) of length B<$salt_len>; the 
algorithm perform the number of iterations specified by B<$iter> (usually > 
1000, better if > 4000). If the salt is empty (or undef) the salt length must 
be 0. The output is binary data with length (in bytes) specified by the 
B<$key_len> parameter.
The function will not ever attempt to auto-calculate the length of the salt 
because it is not assumed to be a NULL terminated value, so its length is 
always required.
The hashing is performed using the default algorithm SHA1, but an alternate 
algortithm may be specified using the (optional) parameter B<alg>; the allowed
values are the textual names as defined in OpenSSL (a list may be obtained 
with the command: openssl dgst -list); so right now you may use:

	'blake2b512', 'blake2s256', 'md4', 'md5', 'md5sha1', 'ripemd', 'ripemd160',
	'rmd160', 'sha1', 'sha224', 'sha256', 'sha3224', 'sha3256', 'sha3384', 
	'sha3512', 'sha384', 'sha512', 'sha512224', 'sha512256', 'shake128', 
	'shake256', 'sm3', 'ssl3md5', 'ssl3sha1', 'whirlpool'

and any other algorithm that will be added to OpenSSL in the future.
The derive function croaks if any error occurs.

=item derive_bin

This function is similar to B<derive>, but accepts a binary password 
B<$pass_bin> with a given length B<$pass_len>. It's useful if you want to use 
an already hashed password (or other binary data) for password.
If B<$pass_len> is set to -1, then the password is assumed to be a string and
length is automatically calculated; in this case only textual passwords are 
allowed (or they will be truncated on the first NUL occurrence).
The derive_bin function croaks too if any error occurs.

=back 

=head1 SUPPORT

To get some help or report bugs you may try to contact the author.

=head1 AUTHOR

Riccardo Scussat E<lt>rscussat@dsplabs.netE<gt>

=head1 LICENSE

Crypt::OpenSSL::PBKDF2 is free software; you may redistribute it and/or modify
it under the terms of GNU GPLv3 (or later version) or Artistic License.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 COPYRIGHT

Copyright 2009-2026 R.Scussat.
=cut
