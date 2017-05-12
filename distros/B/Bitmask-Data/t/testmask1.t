# -*- perl -*-

# t/testmask1.t - check testmask 1

use Test::More tests=>68;
use Test::NoWarnings;

use strict;
use warnings;

use Math::BigInt;

use lib qw(t/lib);
use_ok( 'Testmask1' );

my $tm = Testmask1->new();
my $tm2 = Testmask1->new('value4');

isa_ok($tm,'Bitmask::Data');
isa_ok($tm,'Testmask1');
isa_ok($tm2,'Bitmask::Data');
isa_ok($tm2,'Testmask1');
is($tm->length,0);
is($tm2->length,1);
ok($tm->add('value1',2));
ok($tm2->add('value1'));
is($tm->has_all('value1','value2'),1);
is($tm2->has_all('value1','value4'),1);
is($tm->has_any('value1'),1);
is($tm->has_any('value3'),0);
is($tm->has_any('value3'),0);
is($tm->has_all('value1'),1);
is($tm->has_exact('value1'),0);
is($tm->has_exact('value1','value2'),1);
is($tm->has_exact('value1','value4'),0);
is($tm->has_exact('value1','value2','value5'),0);
is($tm2->has_exact('value1'),0);
is($tm->has_all('value1','value2','value3'),0);
is($tm->length,2);
is($tm->integer,0b0000000000000011);
ok($tm->add('value3','value7'));
is($tm->length,4);
ok($tm->add(2));
is($tm->length,4);
is($tm->integer,0b1000000000001011);
ok($tm->remove(0b0000000000000011));
is($tm->length,2);
is($tm->integer,0b1000000000001000);
is($tm->first,'value7');
is($tm->string,'1000000000001000');
my @sqlsearch1 = $tm->sqlfilter_all('field');
is($sqlsearch1[0],"bitand( field, B'1000000000001000' )");
is(${$sqlsearch1[1]}," = B'1000000000001000'");

my @sqlsearch2 = $tm->sqlfilter_any('field');
is($sqlsearch2[0],"bitand( field, B'1000000000001000' )");
is(${$sqlsearch2[1]}," <> B'0000000000000000'");

is($tm->sqlstring,"B'1000000000001000'::bit(16)");

$tm->reset;
is($tm->length,0);
ok($tm->add(0b1000000000111111));
is($tm->length,7);
is($tm->integer,0b1000000000111111);
ok($tm->remove(32768,[ 0b0000000000000101 ]));
is($tm->length,4);
is($tm->integer,0b0000000000111010);
$tm->set([0b0000000000000010],[0b0000000000100010]);
is($tm->integer,0b0000000000100010);
$tm->add($tm2);
ok($tm->has_any('value4'));
my $tm3 = $tm->clone();
$tm->remove('value4');
ok(! $tm->has_any('value4'));
ok($tm3->has_any('value4'));
is($tm->length + 1,$tm3->length);

my $tm4 = Testmask1->new();
is($tm4->first,undef);
$tm4->add($tm2,Math::BigInt->new('256'));
is($tm4->first,'value1');
my $list1 = $tm4->list();
my @list1 = $tm4->list();
isa_ok($list1,'ARRAY');
is(scalar @list1,3);
is($tm4->length,3);
my $list2 = $tm4->list();
my @list2 = $tm4->list();
isa_ok($list2,'ARRAY');
is(scalar @list2,3);
ok('value1' ~~ $list2);
ok('value4' ~~ $list2);
ok('value9' ~~ $list2);
is($tm4->bitmask,"\0\0\0\0\0\0\0\1\0\0\0\0\0\1\0\1");

my $tm5 = Testmask1->new();
$tm5->add('000000000000000');
$tm5->add();
isa_ok($tm5,'Testmask1');
is($tm5->length,0);
$tm5->add(undef);
is($tm5->length,0);
$tm5->add('000000000000001');
ok($tm5->has_exact('value1'));
is($tm5->length,1);
$tm5->reset;
is($tm5->length,0);
