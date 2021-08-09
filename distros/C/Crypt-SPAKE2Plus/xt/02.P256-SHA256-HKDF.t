#!/usr/bin/perl
#spake2plus: https://www.potaroo.net/ietf/ids/draft-bar-cfrg-spake2plus-03.html
#SPAKE2+-P256-SHA256-HKDF draft-01
use strict;
use warnings;
use bigint;
use Smart::Comments;
use Test::More;

use lib '../lib';
use Crypt::SPAKE2Plus;


my $spake2plus = Crypt::SPAKE2Plus->new(curve_name => 'prime256v1');
my $curve_hr = $spake2plus->{curve_hr};
my $curve = $spake2plus->{curve};
my $M_Point = $spake2plus->init_M_or_N('M');
my $M = $spake2plus->encode_ec_point($M_Point);
my $N_Point = $spake2plus->init_M_or_N('N');
my $N = $spake2plus->encode_ec_point($N_Point);
my $P = $spake2plus->{P};

my $Context = 'SPAKE2+-P256-SHA256-HKDF draft-01';
### $Context
my $A = 'client';
### $A
my $B = '';
### $B

# A, B: w0, w1, L = w1*P
my $w0 = 'e6887cf9bdfb7579c69bf47928a84514b5e355ac034863f7ffaf4390e67d798c';
my $w0_bn = Crypt::Perl::BigInt->from_hex( $w0 );
### $w0
my $w1    = '24b5ae4abda868ec9336ffc3b78ee31c5755bef1759227ef5372ca139b94e512';
my $w1_bn   = Crypt::Perl::BigInt->from_hex( $w1 );
### $w1
my $L_Point = $spake2plus->calc_L($w1_bn);
my $L = $spake2plus->encode_ec_point($L_Point);
### L: unpack('H*', $L)

# A : X = x*P + w0*M
my $x       = 'ec82d9258337f61239c9cd68e8e532a3a6b83d12d2b1ca5d543f44def17dfb8d';
### $x
my $x_bn    = Crypt::Perl::BigInt->from_hex( $x );
my $X_Point = $spake2plus->A_calc_X($w0_bn, $x_bn);
my $X       = $spake2plus->encode_ec_point( $X_Point );
### X: unpack('H*', $X)

# B : Y = y*P + w0*N
my $y       = 'eac3f7de4b198d5fe25c443c0cd4963807add767815dd02a6f0133b4bc2c9eb0';
### $y
my $y_bn    = Crypt::Perl::BigInt->from_hex( $y );
my $Y_Point = $spake2plus->B_calc_Y($w0_bn, $y_bn);
my $Y       = $spake2plus->encode_ec_point( $Y_Point );
### Y: unpack('H*', $Y)

# A: Z = h*x*(Y - w0*N), V = h*w1*(Y - w0*N)
my ($A_Calc_Z_Point, $A_Calc_V_Point) = $spake2plus->A_calc_ZV($w0_bn, $w1_bn, $x_bn, $Y_Point);
my $A_Calc_Z       = $spake2plus->encode_ec_point( $A_Calc_Z_Point );
### A calc Z: unpack('H*', $A_Calc_Z)
my $A_Calc_V       = $spake2plus->encode_ec_point( $A_Calc_V_Point );
### A calc V: unpack('H*', $A_Calc_V)

# B: Z = h*y*(X - w0*M), V = h*y*L
my ($B_Calc_Z_Point, $B_Calc_V_Point) = $spake2plus->B_calc_ZV($w0_bn, $L_Point, $y_bn, $X_Point);
my $B_Calc_Z       = $spake2plus->encode_ec_point( $B_Calc_Z_Point );
### B calc Z: unpack('H*', $B_Calc_Z)
my $B_Calc_V       = $spake2plus->encode_ec_point( $B_Calc_V_Point );
### B calc V: unpack('H*', $B_Calc_V)

is($A_Calc_Z, $B_Calc_Z, 'A and B, Z');
is($A_Calc_V, $B_Calc_V, 'A and B, V');

# A/B calc TT
my $TT = $spake2plus->generate_TT($Context, $A, $B, $X_Point, $Y_Point, $A_Calc_Z_Point, $A_Calc_V_Point, $w0_bn);
### TT: unpack("H*", $TT)

#my ( $Ka, $Ke ) = $spake2plus->split_key( $TT_digest );
my ( $Ka, $Ke ) = $spake2plus->calc_Ka_and_Ke( $TT );
### Ka: unpack("H*", $Ka)
### Ke: unpack("H*", $Ke)

my ( $KcA, $KcB ) = $spake2plus->calc_KcA_and_KcB($Ka);
### KcA: unpack("H*", $KcA)
### KcB: unpack("H*", $KcB)

my $MacA = $spake2plus->A_calc_MacA($KcA, $Y);
### MacA: unpack("H*", $MacA)
my $MacB = $spake2plus->B_calc_MacB($KcB, $X);
### MacB: unpack("H*", $MacB)
is(unpack("H*", $MacA) , 'e1b9258807ba4750dae1d7f3c3c294f13dc4fa60cde346d5de7d200e2f8fd3fc', 'MacA');
is(unpack("H*", $MacB) , 'b9c39dfa49c47757de778d9bedeaca2448b905be19a43b94ee24b770208135e3', 'MacB');

done_testing;
