#!perl -T

use strict;
use warnings;
use Test::More tests => 5;

use Data::NestedSet;


diag( "Testing Data::NestedSet instantiation and return values" );

my $data = [
       [1,'MUSIC',0],
       [2,'M-GUITARS',1],
       [3,'M-G-GIBSON',2],
       [4,'M-G-G-SG',3],
       [5,'M-G-FENDER',2],
       [6,'M-G-F-TELECASTER',3],
       [7,'M-PIANOS',1]
];

my $nodes   = new Data::NestedSet($data,2)->create_nodes();

ok($nodes->[0]->[-2] == 1,'root left value equals 1');
ok($nodes->[0]->[-1] == @{$data}*2,'root right values equals array length * 2');
ok($nodes->[0]->[-1] == 14,'root right values equals 14');
ok($nodes->[1]->[-1] == 11,'second entry right values equals 11');
ok($nodes->[-1]->[-1] == 13,'last entry right values equals 13');

