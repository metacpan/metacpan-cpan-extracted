package Crypt::UnixCrypt_XS;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our @EXPORT_OK = ( qw/crypt crypt_rounds fold_password base64_to_block
		block_to_base64 base64_to_int24 int24_to_base64
		base64_to_int12 int12_to_base64/ );

our @EXPORT = qw(
	
);

our $VERSION = '0.11';

require XSLoader;
XSLoader::load('Crypt::UnixCrypt_XS', $VERSION);

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Crypt::UnixCrypt_XS - perl xs interface for a portable traditional 
F<crypt> function. 


=head1 SYNOPSIS

  use Crypt::UnixCrypt_XS qw/crypt/;
  my $hashed = crypt( $password, $salt );

  use Crypt::UnixCrypt_XS qw/crypt_rounds fold_password
      base64_to_block block_to_base64
      base64_to_int24 int24_to_base64
      base64_to_int12 int12_to_base64/;
  $block = crypt_rounds( $password, $nrounds, $saltnum, $block );
  $password = fold_password( $password );
  $block = base64_to_block( $base64 );
  $base64 = block_to_base64( $block );
  $saltnum = base64_to_int24( $base64 );
  $base64 = int24_to_base64( $saltnum );
  $saltnum = base64_to_int12( $base64 );
  $base64 = int12_to_base64( $saltnum );

=head1 DESCRIPTION

This module implements the DES-based Unix F<crypt> function.  For those who need to construct non-standard variants of F<crypt>, the various building blocks used in F<crypt> are also supplied separately.

=head1 FUNCTIONS

=over

=item crypt( PASSWORD, SALT )

This is the conventional F<crypt> interface.  I<PASSWORD> and I<SALT> are both strings.  The password will be hashed, in a manner determined by the salt, and a string is returned containing the salt and hash.  The salt is at the beginning of the returned string, and only the beginning of the salt string is examined, so it is acceptable to use a string returned by F<crypt> as a salt argument.  Three different types of hashing may occur:

If the salt is an empty string, then the password is ignored and an empty string is returned.  The empty salt/hash string is thus used to not require a password.

If the salt string starts with two base 64 digits (from the set [./0-9A-Za-z]), then the password is hashed using the traditional DES-based algorithm.  The salt is used to modify the DES algorithm in one of 4096 different ways.  The first eight characters of the password are used as a DES key, to encrypt a block of zeroes through 25 iterations of the modified DES.  The block output by the final iteration is the hash, and it is returned in base 64 (as eleven digits).

If the salt string starts with an underscore character and then eight base 64 digits then the password is hashed using the extended DES-based algorithm from BSDi.  The first four base 64 digits specify how many encryption rounds are to be performed.  The next four base 64 digits are used to modify the DES algorithm in one of 16777216 different ways.  If the password is longer than eight characters, it is hashed down to eight characters before being used as a key, so all characters of the password are significant.

=item crypt_rounds( PASSWORD, NROUNDS, SALTNUM, BLOCK )

This is the core of the DES-based F<crypt> algorithm, exposed here to allow variant hash functions to be built.  I<PASSWORD> is a string; its first eight characters are used as a DES key.  I<SALTNUM> is an integer; its low 24 bits are used to modify the DES algorithm.  I<BLOCK> must be a string exactly eight bytes long.  The data block is passed through I<NROUNDS> iterations of the modified DES, and the final output block (also a string of exactly eight bytes) is returned.

=item fold_password( PASSWORD )

This is the pre-hashing algorithm used in the extended DES algorithm to fold a long password to the size of a DES key.  It takes a password of any length, and returns a password of eight characters which is completely equivalent in the extended DES algorithm.  Note: the password returned may contain NUL characters.  The functions in this module correctly handle NULs in password strings, but a normal C library F<crypt> cannot.  If you need the short password to contain no NULs, perform the substitution C<s/\0/\x80/g>: the top bit of each password character is ignored, so the result is equivalent.

=item base64_to_block( BASE64 )

This converts a data block from a string of eleven base 64 digits to a raw string of eight bytes.

=item block_to_base64( BLOCK )

This converts a data block from a raw string of eight bytes to a string of eleven base 64 digits.

=item base64_to_int24( BASE64 )

This converts a 24-bit integer from a string of four base 64 digits to a Perl integer.

=item int24_to_base64( VALUE )

This converts a 24-bit integer from a Perl integer to a string of four base 64 digits.

=item base64_to_int12( BASE64 )

This converts a 12-bit integer from a string of two base 64 digits to a Perl integer.

=item int12_to_base64( VALUE )

This converts a 12-bit integer from a Perl integer to a string of two base 64 digits.

=back

=head2 EXPORT

None by default.

=head1 RATIONALE

Crypt::UnixCrypt_XS provide a fast portable crypt function. Perl's internal crypt is not present at every system. Perl calls the F<crypt> function of the system's C library. This may lead to trouble if the system's crypt presents different results for the same key and salt, but different processid's. L<Crypt::UnixCrypt> is the cure here, but it is to slow. On my computer L<Crypt::UnixCrypt_XS> is about 800 times faster than L<Crypt::UnixCrypt>.

=head1 SEE ALSO

C<crypt(3)>, L<Crypt::UnixCrypt>

=head1 AUTHOR

Boris Zentner, E<lt>bzm@2bz.deE<gt>, the original C source code was 
written by Eric Young, eay@psych.uq.oz.au.

=head1 CREDITS

Fixes, Bug Reports, Docs have been generously provided by:

  Andrew Main (Zefram) <zefram@fysh.org>
  Guenter Knauf
Thanks!

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004, 2005, 2006, 2007 by Boris Zentner

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.

=cut
