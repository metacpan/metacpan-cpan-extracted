
use Test::More tests => 4;
BEGIN { use_ok('Data::VString', 'vstring_cmp') };

ok(vstring_cmp('0', '==', '0'));
ok(!vstring_cmp('0', '==', '1'));
ok(vstring_cmp('1', '>', '0'));

