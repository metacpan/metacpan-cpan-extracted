#!/usr/bin/perl -w

use Test::More tests => 44;

use strict;
BEGIN {
    $|++;
    use_ok('Audio::LADSPA::Buffer');
}

my $buffer;
ok($buffer = Audio::LADSPA::Buffer->new(10),"size 10 buffer");

$buffer->set_list(0,1,2,3,4,5,6,7,8,9);

my @vals = $buffer->get_list();
my $i = 0;
for (@vals) {
    is($_,$i++,"precondition $i");
}

$buffer *= 10;

ok(1,"is_mult smoke");

@vals = $buffer->get_list();
$i = 0;
for (@vals) {
    is($_,$i++ * 10,"is_mult $i");
}

$buffer->set_list(0,1,2,3,4,5,6,7,8,9);
my $copy = $buffer->undef_copy();

is($copy->filled,0,"undef_copy");

@vals = $buffer->get_list();
$i = 0;
for (@vals) {
    is($_,$i++,"integrity of original after undef_copy $i");
}


$i=0;
my $result = $buffer * 10;
for ($result->get_list) {
    is($_,$i++ * 10,"mult $i");
}




