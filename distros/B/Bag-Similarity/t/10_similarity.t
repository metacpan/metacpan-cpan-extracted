#!perl
use strict;
use warnings;

use lib qw(../lib/ );

use Test::More;
use Test::Exception;

my $class = 'Bag::Similarity';

use_ok($class);

my $object = new_ok($class);

dies_ok { $object->from_bags() } ;

ok($object->new());
ok($object->new(1,2));
ok($object->new({}));
ok($object->new({a => 1}));


is_deeply([$object->ngrams('',0)],[''],'zerogram empty string is empty string');
is_deeply([$object->ngrams('a',0)],['a'],'o-gram string a is 1-gram string a');
is_deeply([$object->ngrams('ab',0)],['a','b'],'o-gram string ab is 1-gram a,b');
is_deeply([$object->ngrams('a',0.3)],['a'],'o.3-gram string a is 1-gram string a');
is_deeply([$object->ngrams('ab',0.3)],['a','b'],'o.3-gram string ab is 1-gram a,b');

is_deeply([$object->ngrams('a',1)],['a'],'monogram single character');
is_deeply([$object->ngrams('ab',1)],['a','b'],'monogram two characters');
is_deeply([$object->ngrams('',2)],[''],'bigram empty string is empty string');
is_deeply([$object->ngrams('a',2)],['a'],'bigram single character is single char');
is_deeply([$object->ngrams('ab',2)],['ab'],'bigram two characters');
is_deeply([$object->ngrams('abc',2)],['ab','bc'],'bigram three characters');

is_deeply($object->_any('',0),[''],'o-gram empty string is empty string');
is_deeply($object->_any('a',0),['a'],'o-gram string a is 1-gram string a');
is_deeply($object->_any('ab',0),['a','b'],'o-gram string ab is 1-gram ab');
is_deeply($object->_any('a',1),['a'],'1-gram string a');
is_deeply($object->_any('ab',1),['a','b'],'1-gram ab');
is_deeply($object->_any('',2),[''],'bigram empty string is empty string');
is_deeply($object->_any('a',2),['a'],'bigram single character is single character');
is_deeply($object->_any('ab',2),['ab'],'bigram two characters');
is_deeply($object->_any('abc',2),['ab','bc'],'bigram three characters');

is_deeply($object->_any(),[''],'empty param is empty string');
is_deeply($object->_any(sub {}),[],'coderef is empty list');
is_deeply($object->_any({}),[],'empty hashref is empty list');
is_deeply($object->_any({'a' => 1}),['a'],'hash a => 1');
is_deeply( [sort @{$object->_any({'a'=>1,'b'=>1})}],['a','b'],'hash a,b');

done_testing;
