# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Convert-XText.t'

#########################

use Test::More tests => 3;
BEGIN { use_ok('Convert::XText') };

#########################

is( Convert::XText::encode_xtext(' +='.chr(133)), '+20+2B+3D+85', 'encode_xtext' );
is( Convert::XText::decode_xtext('+14+3D+2B+85'), chr(20).'=+'.chr(133), 'decode_xtext' );
