#!/usr/bin/perl -w

use Test::More tests => 14;

BEGIN {
	use_ok('FileHandle');
	use_ok('F1L3H4NDL3');
}

ok(1,'success');
ok(0,'failure');

diag('This is a comment.');

is('a','a','a eq a');
is('a','b','a eq b');

cmp_ok('1','<','2','one less than two');
cmp_ok('1','>','2','one greater than two');

like('abc',qr/b/,'b in abc');
like('abc',qr/d/,'d in abc');

is_deeply({a=>1},{a=>1},'refs have equal data');
is_deeply({a=>1},{b=>2},'refs are different');

isa_ok(FileHandle->new,'FileHandle');
isa_ok('FileHandle','FileHandle');

