#!perl

use warnings;
use strict;

use Test::More tests => 19;

require_ok('Convert::Base81');

ok defined &Convert::Base81::encode;
ok defined &Convert::Base81::decode;
ok !defined &encode;
ok !defined &decode;
ok !defined &base81_encode;
ok !defined &base81_decode;

use_ok('Convert::Base81');

ok !defined &encode;
ok !defined &decode;
ok !defined &base81_encode;
ok !defined &base81_decode;

use_ok('Convert::Base81', qw(base81_encode base81_decode));

ok !defined &encode;
ok !defined &decode;
ok defined &base81_encode;
ok defined &base81_decode;

ok \&base81_encode == \&Convert::Base81::encode;
ok \&base81_decode == \&Convert::Base81::decode;
