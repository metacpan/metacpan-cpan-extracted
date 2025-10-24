package Crypt::OpenSSL3::BigNum;
$Crypt::OpenSSL3::BigNum::VERSION = '0.002';
use strict;
use warnings;

use Crypt::OpenSSL3;

1;

# ABSTRACT: Big Numbers

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::OpenSSL3::BigNum - Big Numbers

=head1 VERSION

version 0.002

=head1 DESCRIPTION

This class represents an arbitrarily large number. This is mainly useful when dealing with algorihtms based on such large numbers, such as RSA and Diffie-Hellman.

=head1 METHODS

=head2 new

=head2 abs_is_word

=head2 add

=head2 add_word

=head2 are_coprime

=head2 bin2bn

=head2 bn2bin

=head2 bn2binpad

=head2 bn2dec

=head2 bn2hex

=head2 bn2lebinpad

=head2 bn2mpi

=head2 bn2nativepad

=head2 check_prime

=head2 clear

=head2 clear_bit

=head2 cmp

=head2 copy

=head2 dec2bn

=head2 div

=head2 div_word

=head2 dup

=head2 exp

=head2 gcd

=head2 generate_prime

=head2 get_word

=head2 hex2bn

=head2 is_bit_set

=head2 is_odd

=head2 is_one

=head2 is_word

=head2 is_zero

=head2 lebin2bn

=head2 lshift

=head2 lshift1

=head2 mask_bits

=head2 mod

=head2 mod_add

=head2 mod_exp

=head2 mod_mul

=head2 mod_sqr

=head2 mod_sqrt

=head2 mod_sub

=head2 mod_word

=head2 mpi2bn

=head2 mul

=head2 mul_word

=head2 native2bn

=head2 nnmod

=head2 num_bits

=head2 num_bytes

=head2 print

=head2 rand

=head2 rand_ex

=head2 rshift

=head2 rshift1

=head2 secure_new

=head2 set_word

=head2 signed_bin2bn

=head2 signed_bn2bin

=head2 signed_bn2lebin

=head2 signed_bn2native

=head2 signed_lebin2bn

=head2 signed_native2bn

=head2 sqr

=head2 sub

=head2 sub_word

=head2 ucmp

=head1 CONSTANTS

=over 4

=item RAND_BOTTOM_ANY

=item RAND_BOTTOM_ODD

=item RAND_TOP_ANY

=item RAND_TOP_ONE

=item RAND_TOP_TWO

=back

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2025 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
