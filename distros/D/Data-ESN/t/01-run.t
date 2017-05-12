#!perl

use Test::More tests => 17;
use Test::Warn;

use Data::ESN qw( esn_to_hex esn_to_dec esn_valid esn_is_hex esn_is_dec );


#  known ESN equivalents
my $hex_esn = 'CA266D8A';
my $dec_esn = '20202518410';


#  convert dec ESN to hex
ok( esn_to_hex($dec_esn) =~ m/$hex_esn/i, "convert dec $dec_esn ESN to hex " . esn_to_hex($dec_esn) . ":$hex_esn ESN" );


#  convert hex ESN to dec
ok( esn_to_dec($hex_esn) =~ m/$dec_esn/i, "convert hex $hex_esn ESN to dec $dec_esn ESN" );


#  identify that hex ESN detectd properly
ok( esn_valid($hex_esn) eq "hex", "detected hex $hex_esn ESN" );
ok( esn_is_hex($hex_esn),         "detected hex $hex_esn ESN" );
isnt( esn_is_hex(undef),          "return 0 on undef ESN" );
isnt( esn_is_hex('0000'),         "return 0 on bad length hex ESN: 0000" );
isnt( esn_is_hex('0000000z'),     "return 0 no invalid ESN digiti:0000000z" );


#  identify that dec ESN detected properly
ok( esn_valid($dec_esn)  eq "dec", "detected dec ESN" );
ok( esn_is_dec($dec_esn), "detected dec ESN: $dec_esn" );
isnt( esn_is_dec(undef),           "return 0 on undef ESN" );
isnt( esn_is_dec('0000'),          "return 0 on bad length dec ESN" );
isnt( esn_is_dec('0123456789a'),   "return 0 no invalid ESN digit" );
isnt( esn_is_dec('99900000000'),   "return 0 invalid dec ESN manufacturer" );
isnt( esn_is_dec('25499999999'),   "return 0 invalid dec ESN device" );


#  test if ESN is valid for bogus ESN
isnt( esn_valid('0'), "invalid ESN detected" );


#  test CARP
warning_like { esn_to_hex($hex_esn) } qr/invalid ESN/i, "invalid ESN warning detected";
warning_like { esn_to_dec($dec_esn) } qr/invalid ESN/i, "invalid ESN warning detected";





