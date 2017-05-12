#!perl
use strict;
use warnings;

use lib qw(../lib/);

use Test::More;

my $class = 'Bag::Similarity::Jaccard';

use_ok($class);

#my $object = new_ok($class);

my $object = $class;

sub d3 { sprintf('%.3f',shift) }

is($object->similarity(),1,'empty params');
is($object->similarity('a',),0,'a string');
is($object->similarity('a','b'),0,'a,b strings');

is($object->similarity([],['a','b']),0,'empty, ab tokens');
is($object->similarity(['a','b'],[]),0,'ab, empty tokens');
is($object->similarity([],[]),1,'both empty tokens');
is($object->similarity(['a','b'],['a','b']),1,'equal  ab tokens');
is($object->similarity(['a','b'],['c','d']),0,'ab unequal cd tokens');
is(d3($object->similarity(['a','b','a','a'],['b','c','c','c','d'])),'0.125','abaa 0.125 bcccd tokens');
is(d3($object->similarity(['a','b','a','b'],['b','c','c','c','d'])),'0.125','abab 0.125 bccc tokens');

is($object->similarity({},{'a' => 1,'b' => 1}),0,'empty, ab features');
is($object->similarity({'a' => 1,'b' => 1},{}),0,'ab, empty features');
is($object->similarity({},{}),1,'both empty features');
is($object->similarity({'a' => 1,'b' => 1},{'a' => 1,'b' => 1}),1,'equal  ab features');
is($object->similarity({'a' => 1,'b' => 1},{'c' => 1,'d' => 1}),0,'ab unequal cd features');

#is($object->similarity(['a','b','a','a'],['b','c','c','c','d']),0.25,'abaa 0.25 bcccd tokens');
#is($object->similarity(['a','b','a','b'],['b','c','c','c','d']),0.25,'abab 0.25 bccc tokens');


is($object->similarity('ab','ab'),1,'equal  ab strings');
is($object->similarity('ab','cd'),0,'ab unequal cd strings');
is(d3($object->similarity('abaa','bcccd')),'0.125','abaa 0.125 bccc strings');
is(d3($object->similarity('abab','bcccd')),'0.125','abab 0.125 bccc strings');
is(d3($object->similarity('ab','abcd')),'0.500','ab 0.5 abcd strings');

is($object->similarity('ab','ab',2),1,'equal  ab bigrams');
is($object->similarity('ab','cd',2),0,'ab unequal cd bigrams');
is($object->similarity('abaa','bccc',2),0,'abaa 0 bccc bigrams');
is(d3($object->similarity('abcabc','bccc',2)),'0.143','abcabcf 0.143 bcccah bigrams');
is(d3($object->similarity('abc','abcdef',2)),'0.400','abc 0.4 abcdef bigrams');

{
use utf8;
is($object->similarity('äb','äb',2),1,'equal  ab bigrams');
is($object->similarity('äb','cd',2),0,'ab unequal cd bigrams');
is($object->similarity('äbää','bccc',2),0,'abaa 0 bccc bigrams');
is(d3($object->similarity('äbcäbc','bccc',2)),'0.143','abcabcf 0.143 bcccah bigrams');
is(d3($object->similarity('äbc','äbcdef',2)),'0.400','abc 0.4 abcdef bigrams');
}

is(d3($object->similarity('Photographer','Fotograf')), '0.429','Photographer 0.429 Fotograf strings');

is(d3($object->similarity('Photographer','Fotograf',2)),  '0.385','Photographer 0.385 Fotograf bigrams');

is(d3($object->similarity('Photographer','Fotograf',3)), '0.333','Photographer 0.333 Fotograf trigrams');


done_testing;
