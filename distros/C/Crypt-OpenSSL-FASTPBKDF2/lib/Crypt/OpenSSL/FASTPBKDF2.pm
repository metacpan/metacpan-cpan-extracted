package Crypt::OpenSSL::FASTPBKDF2;

use 5.020002;
use strict;
use warnings;
use vars qw($VERSION @ISA);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);

our @EXPORT_OK = qw(
  fastpbkdf2_hmac_sha1 fastpbkdf2_hmac_sha256 fastpbkdf2_hmac_sha512
);

$VERSION = '0.01';

sub dl_load_flags { 0x01 }
# Preloaded methods go here.
__PACKAGE__->bootstrap($VERSION);

1;
__END__

=head1 NAME

Crypt::OpenSSL::FASTPBKDF2 - Perl wrapper for PBKDF2 keys derivation function of the OpenSSL library using fastpbkdf2

=head1 SYNOPSIS

  use Crypt::OpenSSL::FASTPBKDF2 qw/fastpbkdf2_hmac_sha1 fastpbkdf2_hmac_sha256 fastpbkdf2_hmac_sha512/;

  # Initialize parameters for password, salt, number of iterations, and desired output length (in bytes)
  my ($password, $salt, $num_iterations, $output_len) = ('password', 'salt', 100, 32);

  # Initialize buffer array (optional argument)
  my @buffer;

  # Set hash results into scalar variables
  my $hash_sha1 = fastpbkdf2_hmac_sha1($password, $salt, $num_iterations, $output_len, @buffer);        #= 0x8595d7aea0e7c952a35af9a838cc6b393449307cfcc7bd340e7e32ee90115650
  my $hash_sha256 = fastpbkdf2_hmac_sha256($password, $salt, $num_iterations, $output_len, @buffer);    #= 0x07e6997180cf7f12904f04100d405d34888fdf62af6d506a0ecc23b196fe99d8
  my $hash_sha512 = fastpbkdf2_hmac_sha512($password, $salt, $num_iterations, $output_len, @buffer);    #= 0xfef7276b107040a0a713bcbec9fd3e191cc6153249e245a3e1a22087dbe61606

  # Print the contents of the buffer as HEX
  print unpack('H*', join('', @buffer)); # "8595d7aea0e7c952a35af9a838cc6b393449307cfcc7bd340e7e32ee9011565007e6997180cf7f12904f04100d405d34888fdf62af6d506a0ecc23b196fe99d8fef7276b107040a0a713bcbec9fd3e191cc6153249e245a3e1a22087dbe61606"

=head1 DESCRIPTION

PBKDF2 applies a pseudorandom function, such as hash-based message authentication code (HMAC), to the input password or passphrase along with a salt value and repeats the process many times to produce a derived key, which can then be used as a cryptographic key in subsequent operations. The added computational work makes password cracking much more difficult, and is known as key stretching.
fastpbkdf2 is a fast PBKDF2-HMAC-{SHA1,SHA256,SHA512} implementation in C. It uses OpenSSL's hash functions, but out-performs OpenSSL's own PBKDF2 thanks to various optimisations in the inner loop.

Crypt::OpenSSL::FASTPBKDF2 is a set of Perl bindings for fastpbkdf2.

=head1 Static Methods

=head2 fastpbkdf2_hmac_sha1 ($password, $salt, $iterations, $output_len, :@buffer)

Executes PBKDF2 via HMAC_SHA1 to hash C<$password> with C<$salt> repeatedly, C<$iterations> times, to derive and return a hash that is C<$output_len> bytes long.
If the optional C<@buffer> param is provided, the result will also be appended onto the array.

=head2 fastpbkdf2_hmac_sha256 ($password, $salt, $iterations, $output_len, :@buffer)

Same as C<fastpbkdf2_hmac_sha1> but instead uses HMAC_SHA256

=head2 fastpbkdf2_hmac_sha512 ($password, $salt, $iterations, $output_len, :@buffer)

Same as C<fastpbkdf2_hmac_sha1> but instead uses HMAC_SHA512

=head1 SEE ALSO

NIST-PBKDF2 L<http://nvlpubs.nist.gov/nistpubs/Legacy/SP/nistspecialpublication800-132.pdf>

Joseph Birr-Pixton - fastpbkdf2 L<https://github.com/ctz/fastpbkdf2>

=head1 AUTHOR

Duane Hutchins - Univeral Printing Company E<lt>duanehutchins@hotmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 Duane Hutchins - Univeral Printing Company

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.16 or,
at your option, any later version of Perl 5 you may have available.

=cut
