#!perl

use strict;
use warnings;
use Test::More tests => 9;
use Test::Exception;

use lib './t';
do 'testlib.pm';

use Data::ModeMerge;

my $mm = Data::ModeMerge->new;

dies_ok(sub {$mm->remove_prefix([])}, 'invalid 1');
dies_ok(sub {$mm->remove_prefix({})}, 'invalid 2');

is_deeply([$mm->remove_prefix(  'a')],  [ 'a', 'NORMAL' ], 'remove none');
is_deeply([$mm->remove_prefix( '+a')],  [ 'a', 'ADD'    ], 'remove ADD 1');
is_deeply([$mm->remove_prefix('++a')],  ['+a', 'ADD'    ], 'remove ADD 2');
is_deeply([$mm->remove_prefix('+*a')],  ['*a', 'ADD'    ], 'remove ADD 3');

is_deeply($mm->remove_prefix_on_hash({a=>1, "+b"=>2, "++c"=>3, "+*d"=>4}),  {a=>1, b=>2, "+c"=>3, "*d"=>4}, 'oh 1');

dies_ok(sub {$mm->remove_prefix_on_hash(1 )}, 'oh invalid 1');
dies_ok(sub {$mm->remove_prefix_on_hash([])}, 'oh invalid 2');
