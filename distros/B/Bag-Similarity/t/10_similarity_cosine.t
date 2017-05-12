#!perl
use strict;
use warnings;

use lib qw(../lib/);

use Test::More;
use Data::Dumper;

my $class = 'Bag::Similarity::Cosine';

use_ok($class);

my $object = new_ok($class);

#my $object = $class;

sub d3 { sprintf('%.3f',shift) }

is($object->similarity(),1,'empty params');
is($object->similarity('a',),0,'a string');
is($object->similarity('a','b'),0,'a,b strings');

is($object->similarity([],['a','b']),0,'empty, ab tokens');
is($object->similarity(['a','b'],[]),0,'ab, empty tokens');
is($object->similarity([],[]),1,'both empty tokens');


is($object->similarity(['a','b'],['a','b']),1,'equal  ab tokens');
is($object->similarity(['a','b'],['c','d']),0,'ab unequal cd tokens');
is(d3($object->similarity(['a','b'],['b','c'])),'0.500','ab 0.5 bc tokens');

is(d3($object->similarity(['a','b','a','a'],['b','c','c','c'])),'0.100','abaa 0.1 bccc tokens');
is(d3($object->similarity(['a','b','a','b'],['b','c','c','c'])),'0.224','abab 0.224 bccc tokens');


is($object->similarity('ab','ab'),1,'equal  ab strings');
is($object->similarity('ab','cd'),0,'ab unequal cd strings');
is(d3($object->similarity('ab','bc')),'0.500','ab 0.5 bc strings');
is(d3($object->similarity('abaa','bccc')),'0.100','abaa 0.1 bccc strings');

is(d3($object->similarity('abab','bccc')),'0.224','abab 0.224 bccc strings');
is(d3($object->similarity('ab','abcd')),'0.707','ab 0.707 abcd strings');

is($object->similarity('ab','ab',2),1,'equal  ab bigrams');
is($object->similarity('ab','cd',2),0,'ab unequal cd bigrams');
is($object->similarity('abaa','bccc',2),0,'abaa 0 bccc bigrams');
is(d3($object->similarity('abcabcf','bcccah',2)),'0.359','abcabcf 0.359 bcccah bigrams');
is(d3($object->similarity('abc','abcdef',2)),'0.632','abc 0.632 abcdef bigrams');

is(d3($object->similarity('Photographer','Fotograf')),'0.671','Photographer 0.671 Fotograf strings');
is(d3($object->similarity('Photographer','Fotograf',2)),'0.570','Photographer 0.570 Fotograf bigrams');
is(d3($object->similarity('Photographer','Fotograf',3)),'0.516','Photographer 0.516 Fotograf trigrams');


done_testing;
