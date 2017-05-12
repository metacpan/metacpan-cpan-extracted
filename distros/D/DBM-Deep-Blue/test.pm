#!perl -w -Ilib -Iblib/arch 
use feature ':5.12';
use strict;
use Test::More;
use warnings all=>'FATAL';

eval {use DBM::Deep::Blue;};

ok !$@;

done_testing;
