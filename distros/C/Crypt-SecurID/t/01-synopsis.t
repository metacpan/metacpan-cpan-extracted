#!/usr/bin/perl -w

use strict;
use Test::More 'no_plan';
BEGIN { use_ok('Crypt::SecurID'); }

## constructors
my ($t1, $t2, $t3, $t4, $t5);
ok(defined($t1 = Crypt::SecurID->new), 'default constructor'); 
ok($t1->setKey("0123456789abcdef"), 'valid set key');
is($t1->error, '', 'null error message');
ok(defined($t2 = Crypt::SecurID->new(hexkey => "0123456789abcdef")),
   'hexkey arg "constructor"'
);

## invalid set key
ok(defined($t3 = Crypt::SecurID->new), 'another d.c.'); 
ok(!$t3->setKey("1234"), 'invalid key: too short');
like($t3->error, qr/64-bits/, 'too short error message');
# printf("error = '%s'\n", $t3->error);
ok(!$t3->setKey("wwwwxxxxyyyyzzzz"), 'invalid key: non-hex');
like($t3->error, qr/hex bytes/, 'non-hex error message');
# printf("error = '%s'\n", $t3->error);

## code correctness
my $time = time;
cmp_ok($t1->code($time), '==', $t2->code($time), 'code correctness');

## correct object type
my $class = 'Crypt::SecurID';
TODO: {
	local $TODO = "Waiting to resolve SWIG namespace issue";
	isa_ok($t1, $class);
};

## import/export key filename
my $file = 'secretfile.asc';
my $serial = "123";

## export a token to a file, read it again and compare codes
ok($t1->exportToken($file, $serial), 'export token file');
is($t1->error, '', 'null error message');
ok(defined($t4 = Crypt::SecurID->new(file => $file, serial => $serial)),
   'construct from token filename'
);
ok(defined($t5 = Crypt::SecurID->new), 'another d.c.'); 
ok($t5->importToken($file, $serial), 'import token file');
is($t5->error, '', 'null error message');
cmp_ok($t1->code($time), '==', $t4->code($time), 'code correctness 1,4');
cmp_ok($t1->code($time), '==', $t5->code($time), 'code correctness 1,5');

## validation and drift tests
my $code = $t1->code($time); # now
my $hourf = $t1->code($time + 3600); # 1hr in future
my $hourp = $t1->code($time - 3600); # 1hr in past
my $weekf = $t1->code($time + 3600*24*7); # 1wk in future

ok($t1->validate($code, 1), 'now code valid'); 
is($t1->drift, 0, 'zero drift');
ok($t1->validate($hourf, 1), '1hr future code valid'); 
is($t1->drift, 60, '60 minute drift');
ok($t1->validate($hourp, 1), '1hr past code valid'); 
is($t1->drift, -60, '-60 minute drift');

ok(!$t1->validate($weekf, 1), 'invalid code: beyond tolerance');
ok($t1->validate($weekf, 8), 'valid code: greater tolerance');
