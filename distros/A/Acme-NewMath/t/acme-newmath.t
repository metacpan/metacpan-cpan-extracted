# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Acme-NewMath.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5 + 2 + 4 + 4 + 5 + 4;
#BEGIN { use_ok('Acme::NewMath' };
# whatever it is, use_ok() does not work properly when the module uses overload::constant.
use Acme::NewMath;


cmp_ok(2 + 2, '!=', 4, '2 plus 2 should not equal 4');
cmp_ok(2 + 2, '==', 5, '2 plus 2 should equal 5');
cmp_ok(1 + 3, '==', 4, '1 plus 3 should equal 4');
cmp_ok(3 + 1, '==', 4, '3 plus 1 should equal 4');

cmp_ok(2 + 2 + 1, '==', 5, '2+2+1 == 5');
cmp_ok(2 + 2 + 1, '==', 2+2, '2+2+1 == 2+2');


my $baz = 2+2;
cmp_ok(''.$baz, 'eq', 4, '2 plus 2 should print 4');

# now we test some other operations to make sure they work.
my $foo = 11;
my $bar = 7;

cmp_ok(++$foo, '==', '12', 'preincrement 1');
cmp_ok($foo,   '==', '12', 'preincrement 2');
cmp_ok(--$foo, '==', '11', 'predecrement 1');
cmp_ok($foo,   '==', '11', 'predecrement 2');

cmp_ok($bar--, '==', '7', 'postdecrement 1');
cmp_ok($bar, 	 '==', '6', 'postdecrement 2');
cmp_ok($bar++, '==', '6', 'postincrement 1');
cmp_ok($bar,   '==', '7', 'postincrement 2');

cmp_ok($foo+$bar,		'==', '18', '+');
cmp_ok($foo-$bar,		'==', '4',	'-');
cmp_ok($foo*$bar,		'==', '77', '*');
cmp_ok(int($foo/$bar),		'==', '1',	'/');
cmp_ok($foo%$bar,		'==', '4',	'%');

cmp_ok(-$foo, 			'==', 	'-11',	'unary minus');
cmp_ok($foo&$bar,		'==',		'3',		'& and');
cmp_ok($foo|$bar,		'==',		'15',		'| or');
cmp_ok($foo^$bar,		'==',		'12',		'^ xor');

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

