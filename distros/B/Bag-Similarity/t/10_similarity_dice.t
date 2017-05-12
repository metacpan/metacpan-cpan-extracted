#!perl
use strict;
use warnings;

use lib qw(../lib/);

use Test::More;

my $class = 'Bag::Similarity::Dice';

use_ok($class);

#my $object = new_ok($class);

my $object = $class;

sub d3 { sprintf('%.3f',shift) }

is($object->from_tokens([],['a','b']),0,'empty, ab tokens');
is($object->from_tokens(['a','b'],[]),0,'ab, empty tokens');
is($object->from_tokens([],[]),1,'both empty tokens');
is($object->from_tokens([1],[1]),1,'equal tokens');


is($object->similarity(),1,'empty params');
is($object->similarity('a',),0,'a string');
is($object->similarity('a','b'),0,'a,b strings');

is($object->similarity([],['a','b']),0,'empty, ab tokens');
is($object->similarity(['a','b'],[]),0,'ab, empty tokens');
is($object->similarity([],[]),1,'both empty tokens');
is($object->similarity(['a','b'],['a','b']),1,'equal  ab tokens');
is($object->similarity(['a','b'],['c','d']),0,'ab unequal cd tokens');
is(d3($object->similarity(['a','b','a','a'],['b','c','c','c'])),'0.250','abaa 0.250 bccc tokens');
is(d3($object->similarity(['a','b','a','b'],['b','c','c','c'])),'0.250','abab 0.250 bccc tokens');

is($object->similarity('ab','ab'),1,'equal  ab strings');
is($object->similarity('ab','cd'),0,'ab unequal cd strings');
is(d3($object->similarity('abaa','bccc')),'0.250','abaa 0.250 bccc strings');
is(d3($object->similarity('abab','bccc')),'0.250','abab 0.225 bccc strings');

is($object->similarity('ab','ab',2),1,'equal  ab bigrams');
is($object->similarity('ab','cd',2),0,'ab unequal cd bigrams');
is($object->similarity('abaa','bccc',2),0,'abaa 0 bccc bigrams');
is(d3($object->similarity('abcabcf','bcccah',2)),'0.364','abcabcf 0.364 bcccah bigrams');

is(d3($object->similarity('Photographer','Fotograf')),'0.600','Photographer 0.600 Fotograf strings');
is(d3($object->similarity('Photographer','Fotograf',2)), '0.556','Photographer 0.556 Fotograf bigrams');
is(d3($object->similarity('Photographer','Fotograf',3)),'0.500','Photographer 0.5 Fotograf trigrams');


done_testing;
