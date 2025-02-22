#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

BEGIN { use_ok('Array::Iterator::BiDirectional') }

my @set = qw/ one two three four /;
my $iterator = Array::Iterator::BiDirectional->new(@set);

cmp_ok($iterator->getNext(), 'eq', 'one');
cmp_ok($iterator->getNext(), 'eq', 'two');
cmp_ok($iterator->getNext(), 'eq', 'three');
cmp_ok($iterator->getPrevious(), 'eq', 'two');
cmp_ok($iterator->getPrevious(), 'eq', 'one');
ok(!$iterator->hasPrevious(), '... we should have no more');
ok($iterator->hasNext(), '... we should have more');

done_testing();
