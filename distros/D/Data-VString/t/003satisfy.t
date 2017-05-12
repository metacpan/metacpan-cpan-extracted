
use Test::More tests => 11;
BEGIN { use_ok('Data::VString', 'vstring_satisfy') };


# test internal comparison function
ok(Data::VString::_vstring_cmp('0', '==', '0'));
ok(!Data::VString::_vstring_cmp('0', '==', '1'));
ok(Data::VString::_vstring_cmp('1', '>', '0'));

# and now &vstring_satisfy which is exportable
ok(vstring_satisfy('0', '0'), "'0' satisfies '0'");
ok(vstring_satisfy('2.03', '2.3'), "'2.03' satisfies '2.3'");
ok(!vstring_satisfy('1', '0'), "'1' doesn't satisfy '0'");
ok(vstring_satisfy('1', '> 0'), "'1' satisfies '> 0'");
ok(vstring_satisfy('0.1.2', '0.1..0.2'), "'0.1.2' satisfies '0.1..0.2'");

ok(vstring_satisfy('1', '> 0, < 2'), "'1' satisfies '> 0, < 2'");
ok(vstring_satisfy('1.02.30', '1.01.27 .. 1.02.31, != 1.02.29'), 
	"'1.02.30' satisfies '1.01.27 .. 1.02.31, != 1.02.29'");
