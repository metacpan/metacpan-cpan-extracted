# -*- perl -*-

# t/overload.t - overload params

use Test::More tests => 35;
use Test::NoWarnings;

use strict;
use warnings;

use lib qw(t/lib);
use_ok( 'Testmask5' );

my $tm1 = Testmask5->new('value2');
my $tm2 = Testmask5->new('value1','value5');

is($tm2,'10001','Stringify');
ok((0+$tm1) == 2,'Numify');

my $tm3 = $tm1 + $tm2;
isa_ok($tm3,'Testmask5');
is($tm3->string,'10011','New bitmask is correct');

my $tm4 = $tm3 - $tm1;

isa_ok($tm4,'Testmask5');
is($tm4->string,'10001','New bitmask is correct');

$tm3 -= $tm1;
is($tm3->string,'10001','Bitmask has been updated correctly');

$tm3 += $tm1;
is($tm3->string,'10011','Bitmask has been updated correctly');

my $tm5 = Testmask5->new();
if ($tm5) {
    fail('Mask evals false');
} else {
    pass('Mask evals false');
}
ok($tm4,'Mask evals true');

my $tm6 = $tm3 & $tm1;
is($tm6->string,'00010','New bitmask is correct');

my $tm7 = $tm3 | $tm1;
is($tm7->string,'10011','New bitmask is correct');

my $tm8 = $tm3 ^ $tm1;
is($tm8->string,'10001','New bitmask is correct');

$tm8 &= $tm2;
is($tm8->string,'10001','Bitmask has been updated correctly');

$tm6 |= 17;
is($tm6->string,'10011','Bitmask has been updated correctly');

$tm6 ^= '0b01010';
is($tm6->string,'11001','Bitmask has been updated correctly');

my $tm9 = ~ $tm6;
is($tm9->string,'00110','New bitmask is correct');

my $tm10 = Testmask5->new('value2');
ok($tm10 == 'value2','Comparison works');

ok(scalar($tm10->list) ~~ ['value2'],'List smartmatch');
ok($tm10 ~~ ['value2'],'Overload smartmatch');
ok($tm10 ~~ ['value2'],'Overload smartmatch single');
ok($tm10 ~~ ['value2','value3'],'Overload smartmatch multiple');
$tm10->add('value3');
ok($tm10 ~~ $tm10->clone,'Overload smartmatch object');
ok($tm10 ~~ '00110','Overload smartmatch string');
ok($tm10 ~~ 6,'Overload smartmatch integer');
ok(($tm10 ~~ ['value3','value4']),'Overload smartmatch partial');
ok(! ($tm10 ~~ ['value5','value4']),'Overload no match');

my $tm11 = Testmask5->new('value1');
my $tm12 = Testmask5->new('value2');
my $tm13 = Testmask5->new('value3');
my $tm14 = Testmask5->new('value1');

ok(($tm11 < $tm12),'Compare works');
ok(($tm13 > $tm12),'Compare works');
ok(($tm11 >= $tm14),'Compare works');
is(($tm11 cmp $tm14),0,'Compare works');
is(($tm11 cmp $tm12),-1,'Compare works');
is(($tm12 cmp $tm11),1,'Compare works');

#ok(Testmask5->new('value1') == 1);
#ok(Testmask5->new('value1') != 2);
#ok(Testmask5->new('value1','value5') eq '10001');
#ok(Testmask5->new('value1','value5') ne '10011');
#is($tm2 -= 1,'10000');