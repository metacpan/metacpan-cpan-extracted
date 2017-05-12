#!perl -w -I../lib -I../blib/arch 
use feature ':5.12';
use strict;
use Test::More;
use warnings all=>'FATAL';

use DBM::Deep::Blue;
mkdir("memory");

 {my $m = DBM::Deep::Blue::file('memory/destroy.data');
  my $a = $m->allocArray();
  $a->[1] = 0; 
 }

ok 1;
done_testing;
