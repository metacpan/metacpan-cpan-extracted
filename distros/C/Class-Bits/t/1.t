use Test::More tests => 20;
BEGIN { use_ok('Class::Bits') };

package Foo;

use Class::Bits;
make_bits(foo=>1, bar=>'s4', dor=> 2);

package Bar;

use Class::Bits;
make_bits(foo=>32, doz=>16, bar=>'s32', dor=>'s16');


package main;


my $obj=Foo->new();

is($obj->length, 10, 'length');

is($obj->dor, 0, 'init to 0');

is($obj->bar(3), 3, 'set to 3');

is($obj->bar, 3, 'get 3');

is($obj->bar(255), -1, 'set out of range');

is($$obj, "\xf0\x00", 'as string');


my $o2=Foo->new("\xf0\x01");

is($o2->dor, 1, "init from string");


my $o3=Foo->new(foo=>1, bar=>2, dor=>2);

is($o3->bar, 2, "init from array");

is($$o3, "\x21\x02", "as string 3");


my $o4=Bar->new();

is ($o4->foo(4294967295), 4294967295, "4294967295 to u32 4294967295");

is ($o4->foo(-1), 4294967295, "-1 to u32 4294967295");

is ($o4->bar(-1), -1, "-1 to s32 -1");

is ($o4->bar(4294967295), -1, "4294967295 to s32 -1");

is ($o4->dor(4294967295), -1, "4294967295 to s16 -1");

is ($o4->dor(-1), -1, "-1 to s16 -1");

is ($o4->doz(4294967295), 65535, "4294967295 to u16 65535");

is ($o4->doz(-1), 65535, "-1 to u16 65535");

my @k=sort $o4->keys;

is ($k[0], 'bar', 'keys bar');

is ($k[3], 'foo', 'keys foo');