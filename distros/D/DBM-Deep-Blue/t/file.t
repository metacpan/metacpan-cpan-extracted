#!perl -w -I../lib -I../blib/arch 
use feature ':5.12';
use strict;
use Test::More;
use Time::HiRes qw(time);
use warnings all=>'FATAL';

use DBM::Deep::Blue;
mkdir("memory");

#-----------------------------------------------------------------------
# Open a bad backing file
#-----------------------------------------------------------------------

 {local $@;
  eval { DBM::Deep::Blue::file("memory2/file.data") };
  ok $@ =~ /Cannot create file .*, do you need to create the path/, 'Bad file error message';
 } 

#-----------------------------------------------------------------------
# Open a good backing file
#-----------------------------------------------------------------------

my $f= "memory/file.data";

 {my $m = DBM::Deep::Blue::file($f);
  my $a = $m->allocGlobalArray;
  $a->[1] = 1;
  is $a->[1], 1, 'Loaded file';
 } 

#-----------------------------------------------------------------------
# Open again
#-----------------------------------------------------------------------

 {my $m = DBM::Deep::Blue::file($f);
  my $a = $m->allocGlobalArray;
  is $a->[1], 1, 'Reloaded file';
  $a->[2] = 'a' x 1e4;
 } 

#-----------------------------------------------------------------------
# Open again 2
#-----------------------------------------------------------------------

 {my $m = DBM::Deep::Blue::file($f);
  my $a = $m->allocGlobalArray;
  is $a->[1], 1, 'Loaded file';
  is $a->[2], 'a' x 1e4, 'Expanded';
  $m->dump('zz');
 } 

done_testing;
