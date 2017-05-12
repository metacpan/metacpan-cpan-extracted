#!/usr/bin/perl
use strict; use warnings FATAL => 'all'; 
use Test::More;use utf8;

use DTL::Fast;

my $seq = DTL::Fast::eval_sequence();

eval 'my $ab = 1;';

is( DTL::Fast::eval_sequence(), ++$seq, 'Start sequence');

done_testing();
