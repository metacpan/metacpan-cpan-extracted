#!/usr/bin/perl
#spake2plus: https://www.potaroo.net/ietf/ids/draft-bar-cfrg-spake2plus-03.html
#SPAKE2+-P256-SHA256-HKDF draft-01
use strict;
use warnings;
#use bigint;
use Test::More;

#use Smart::Comments;

use lib '../lib';
use Crypt::Protocol::SPAKE2Plus;
use Crypt::OpenSSL::BaseFunc;


my $spake2plus = Crypt::Protocol::SPAKE2Plus->new(curve_name => 'prime256v1');
my $curve_hr = $spake2plus->{curve_hr};
my $curve = $spake2plus->{curve};
my $M = $spake2plus->init_M_or_N('M');
#my $M = $spake2plus->encode_ec_point($M_Point);
my $N = $spake2plus->init_M_or_N('N');
#my $N = $spake2plus->encode_ec_point($N_Point);
my $P = $spake2plus->{P};

my $Context = 'SPAKE2+-P256-SHA256-HKDF draft-01';
### $Context
my $A = 'client';
### $A
my $B = 'server';
### $B

# A, B: w0, w1, L = w1*P
my $w0 = 'e6887cf9bdfb7579c69bf47928a84514b5e355ac034863f7ffaf4390e67d798c';
my $w0_bn = hex2bn( $w0 );
### $w0
my $w1    = '24b5ae4abda868ec9336ffc3b78ee31c5755bef1759227ef5372ca139b94e512';
my $w1_bn   = hex2bn( $w1 );
### $w1

my $L_Point = $spake2plus->calc_L($w1_bn);
my $L = point2hex($spake2plus->{curve_name}, $L_Point, 4);
### $L 
is($L, '0495645CFB74DF6E58F9748BB83A86620BAB7C82E107F57D6870DA8CBCB2FF9F7063A14B6402C62F99AFCB9706A4D1A143273259FE76F1C605A3639745A92154B9', 'L');

# A : X = x*P + w0*M
my $x       = '8b0f3f383905cf3a3bb955ef8fb62e24849dd349a05ca79aafb18041d30cbdb6';
my $x_bn    = hex2bn( $x );
my $X_Point = $spake2plus->A_calc_X($w0_bn, $x_bn);
my $X       = point2hex($spake2plus->{curve_name}, $X_Point, 4);
### $X
is($X, '04AF09987A593D3BAC8694B123839422C3CC87E37D6B41C1D630F000DD64980E537AE704BCEDE04EA3BEC9B7475B32FA2CA3B684BE14D11645E38EA6609EB39E7E', 'X');

# B : Y = y*P + w0*N
my $y       = '2e0895b0e763d6d5a9564433e64ac3cac74ff897f6c3445247ba1bab40082a91';
### $y
my $y_bn    = hex2bn( $y );
my $Y_Point = $spake2plus->B_calc_Y($w0_bn, $y_bn);
#my $Y       = $spake2plus->encode_ec_point( $Y_Point );
my $Y       = point2hex($spake2plus->{curve_name}, $Y_Point, 4);
#### $Y
is( $Y, '04417592620AEBF9FD203616BBB9F121B730C258B286F890C5F19FEA833A9C900CBE9057BC549A3E19975BE9927F0E7614F08D1F0A108EEDE5FD7EB5624584A4F4', 'Y');

# A: Z = h*x*(Y - w0*N), V = h*w1*(Y - w0*N)
my ($A_Calc_Z_Point, $A_Calc_V_Point) = $spake2plus->A_calc_ZV($w0_bn, $w1_bn, $x_bn, $Y_Point);
my $A_Calc_Z       = point2hex($spake2plus->{curve_name}, $A_Calc_Z_Point, 4);
my $A_Calc_V       = point2hex($spake2plus->{curve_name}, $A_Calc_V_Point, 4);
is($A_Calc_Z, '0471A35282D2026F36BF3CEB38FCF87E3112A4452F46E9F7B47FD769CFB570145B62589C76B7AA1EB6080A832E5332C36898426912E29C40EF9E9C742EEE82BF30', 'A, Z');
is($A_Calc_V, '046718981BF15BC4DB538FC1F1C1D058CB0EECECF1DBE1B1EA08A4E25275D382E82B348C8131D8ED669D169C2E03A858DB7CF6CA2853A4071251A39FBE8CFC39BC', 'A, V');

# B: Z = h*y*(X - w0*M), V = h*y*L
my ($B_Calc_Z_Point, $B_Calc_V_Point) = $spake2plus->B_calc_ZV($w0_bn, $L_Point, $y_bn, $X_Point);
my $B_Calc_Z       = point2hex($spake2plus->{curve_name}, $B_Calc_Z_Point, 4);
my $B_Calc_V       = point2hex($spake2plus->{curve_name}, $B_Calc_V_Point, 4);
is($A_Calc_Z, $B_Calc_Z, 'B, Z');
is($A_Calc_V, $B_Calc_V, 'B, V');

## A/B calc TT
my $TT = $spake2plus->generate_TT($Context, $A, $B, $X_Point, $Y_Point, $A_Calc_Z_Point, $A_Calc_V_Point, $w0_bn);
### TT: unpack("H*", $TT)
is(unpack('H*', $TT), '21000000000000005350414b45322b2d503235362d5348413235362d484b44462064726166742d30310600000000000000636c69656e740600000000000000736572766572410000000000000004886e2f97ace46e55ba9dd7242579f2993b64e16ef3dcab95afd497333d8fa12f5ff355163e43ce224e0b0e65ff02ac8e5c7be09419c785e0ca547d55a12e2d20410000000000000004d8bbd6c639c62937b04d997f38c3770719c629d7014d49a24b4f98baa1292b4907d60aa6bfade45008a636337f5168c64d9bd36034808cd564490b1e656edbe7410000000000000004af09987a593d3bac8694b123839422c3cc87e37d6b41c1d630f000dd64980e537ae704bcede04ea3bec9b7475b32fa2ca3b684be14d11645e38ea6609eb39e7e410000000000000004417592620aebf9fd203616bbb9f121b730c258b286f890c5f19fea833a9c900cbe9057bc549a3e19975be9927f0e7614f08d1f0a108eede5fd7eb5624584a4f441000000000000000471a35282d2026f36bf3ceb38fcf87e3112a4452f46e9f7b47fd769cfb570145b62589c76b7aa1eb6080a832e5332c36898426912e29c40ef9e9c742eee82bf304100000000000000046718981bf15bc4db538fc1f1c1d058cb0eececf1dbe1b1ea08a4e25275d382e82b348c8131d8ed669d169c2e03a858db7cf6ca2853a4071251a39fbe8cfc39bc2000000000000000e6887cf9bdfb7579c69bf47928a84514b5e355ac034863f7ffaf4390e67d798c', 'TT');

##my ( $Ka, $Ke ) = $spake2plus->split_key( $TT_digest );
my ( $Ka, $Ke ) = $spake2plus->calc_Ka_and_Ke( $TT );
### Ka: unpack("H*", $Ka)
### Ke: unpack("H*", $Ke)
is(unpack('H*', $Ka), 'f9cab9adcc0ed8e5a4db11a8505914b2', 'Ka');
is(unpack('H*', $Ke), '801db297654816eb4f02868129b9dc89', 'Ke');

my ( $KcA, $KcB ) = $spake2plus->calc_KcA_and_KcB($Ka);
### KcA: unpack("H*", $KcA)
### KcB: unpack("H*", $KcB)
is(unpack("H*", $KcA) , '0d248d7d19234f1486b2efba5179c52d', 'KcA');
is(unpack("H*", $KcB) , '556291df26d705a2caedd6474dd0079b', 'KcB');

my $MacA = $spake2plus->A_calc_MacA($KcA, pack("H*", $Y));
### MacA=hmac(KcA, Y): unpack("H*", $MacA)
is(unpack("H*", $MacA), 'd4376f2da9c72226dd151b77c2919071155fc22a2068d90b5faa6c78c11e77dd', 'MacA');

my $MacB = $spake2plus->B_calc_MacB($KcB, pack("H*", $X));
### MacB=hmac(KcB, X): unpack("H*", $MacB)
is(unpack("H*", $MacB), '0660a680663e8c5695956fb22dff298b1d07a526cf3cc591adfecd1f6ef6e02e', 'MacB');


done_testing;
