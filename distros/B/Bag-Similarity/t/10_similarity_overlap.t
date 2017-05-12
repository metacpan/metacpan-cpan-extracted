#!perl
use strict;
use warnings;

use lib qw(../lib/);

use Test::More;

my $class = 'Bag::Similarity::Overlap';

use_ok($class);

#my $object = new_ok($class);

my $object = $class;

is($object->similarity(),1,'empty params');
is($object->similarity('a',),0,'a string');
is($object->similarity('a','b'),0,'a,b strings');

is($object->similarity([],['a','b']),0,'empty, ab tokens');
is($object->similarity(['a','b'],[]),0,'ab, empty tokens');
is($object->similarity([],[]),1,'both empty tokens');
is($object->similarity(['a','b'],['a','b']),1,'equal  ab tokens');
is($object->similarity(['a','b'],['c','d']),0,'ab unequal cd tokens');
is($object->similarity(['a','b','a','a'],['b','c','c','c']),0.25,'abaa 0.25 bccc tokens');
is($object->similarity(['a','b','a','b'],['b','c','c','c']),0.25,'abab 0.25 bccc tokens');

is($object->similarity('ab','ab'),1,'equal  ab strings');
is($object->similarity('ab','cd'),0,'ab unequal cd strings');
is($object->similarity('abaa','bccc'),0.25,'abaa 0.25 bccc strings');
is($object->similarity('abab','bccc'),0.25,'abab 0.25 bccc strings');
is($object->similarity('ab','abcd'),1,'ab 1 abcd strings');

is($object->similarity('ab','ab',2),1,'equal  ab bigrams');
is($object->similarity('ab','cd',2),0,'ab unequal cd bigrams');
is($object->similarity('abaa','bccc',2),0,'abaa 0 bccc bigrams');
is($object->similarity('abcabcf','bcccah',2),0.4,'abcabcf 0.4 bcccah bigrams');
is($object->similarity('abc','abcdef',2),1,'abc 1 abcdef bigrams');

ok($object->similarity('Photographer','Fotograf') > 0.71,'Photographer 0.714 Fotograf strings');
ok($object->similarity('Photographer','Fotograf',2) > 0.71,'Photographer 0.714 Fotograf bigrams');
ok($object->similarity('Photographer','Fotograf',3) > 0.66,'Photographer 0.666 Fotograf bigrams');


done_testing;
