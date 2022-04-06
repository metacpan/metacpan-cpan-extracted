#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Acme::Inabajunmr::Utils;

is(sum(1,2,3,4), 10, '1+2+3=6');
is(sum(), 0, 'empty list is 0');
