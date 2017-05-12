#!perl

use warnings;
use strict;

use Test::More tests => 19;

require_ok('Convert::Ascii85');

ok defined &Convert::Ascii85::encode;
ok defined &Convert::Ascii85::decode;
ok !defined &encode;
ok !defined &decode;
ok !defined &ascii85_encode;
ok !defined &ascii85_decode;

use_ok('Convert::Ascii85');

ok !defined &encode;
ok !defined &decode;
ok !defined &ascii85_encode;
ok !defined &ascii85_decode;

use_ok('Convert::Ascii85', qw(ascii85_encode ascii85_decode));

ok !defined &encode;
ok !defined &decode;
ok defined &ascii85_encode;
ok defined &ascii85_decode;

ok \&ascii85_encode == \&Convert::Ascii85::encode;
ok \&ascii85_decode == \&Convert::Ascii85::decode;
