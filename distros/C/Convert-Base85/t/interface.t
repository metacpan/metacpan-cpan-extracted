#!perl

use warnings;
use strict;

use Test::More tests => 19;

require_ok('Convert::Base85');

ok defined &Convert::Base85::encode;
ok defined &Convert::Base85::decode;
ok !defined &encode;
ok !defined &decode;
ok !defined &base85_encode;
ok !defined &base85_decode;

use_ok('Convert::Base85');

ok !defined &encode;
ok !defined &decode;
ok !defined &base85_encode;
ok !defined &base85_decode;

use_ok('Convert::Base85', qw(base85_encode base85_decode));

ok !defined &encode;
ok !defined &decode;
ok defined &base85_encode;
ok defined &base85_decode;

ok \&base85_encode == \&Convert::Base85::encode;
ok \&base85_decode == \&Convert::Base85::decode;
