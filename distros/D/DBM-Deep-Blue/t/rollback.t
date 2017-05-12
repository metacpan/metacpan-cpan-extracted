#!perl -w -I../lib -I../blib/arch 
use feature ':5.12';
use strict;
use Test::More;
use Time::HiRes qw(time);
use warnings all=>'FATAL';

use DBM::Deep::Blue;

my $N = 1_000_000;
   $N = 1_000;       ## Temporaily for faster testing
my $T = time();

#Time: 41.2493140697479
#gdb --args c:/strawberry/perl/bin/perl.exe rollback.t
#-----------------------------------------------------------------------
# Array
#-----------------------------------------------------------------------

 {my $m = DBM::Deep::Blue::new();
  my $a = $m->allocArray();
  my $size = $m->size();
     $a->[0] = 'a';
  ok scalar(@$a) == 1,       "Scalar(a) at start == 1";
  is $a->[0],     'a',       "Array contains a at start";

  $m->begin_work;
  for(1..$N)
   {push @$a, $_;
   }

  ok $#$a == $N,             "#a before rollback == $N";
  ok $a->[$N] == $N,         "a->[N] == N";
  is $a->[0],   'a',         "Array contains a before rollback";

  ok $m->size() > $size,     "Size has increased";
  $m->rollback();
  ok scalar(@$a) == 1,       "Scalar(a) after  rollback == 1";
  is $a->[0], 'a',           "Array contains a after rollback";
  ok $m->size() < $size+1,   "Size has returned to within one of original value";
 }

#-----------------------------------------------------------------------
# Hash
#-----------------------------------------------------------------------

 {my $m = DBM::Deep::Blue::new();
  my $h = $m->allocHash();
  my $size = $m->size();

  $h->{a} = 'a';
  is $h->{a}, 'a', "Hash contains a at start";

  $m->begin_work;
  for(2..$N)
   {$h->{$_} = $_;
   }

  ok scalar(keys %$h) == $N, "Scalar(keys h) before rollback == $N";
  is $h->{$N}, $N, 'h->{N} == N';
  is $h->{a}, 'a',           "Hash contains a after load";
  ok $m->size() > $size,     "Size has increased";

  $m->rollback();
  ok scalar(keys %$h) ==  1, "Scalar(keys h) after rollback == 1";
  is $h->{a}, 'a',           "Hash contains a after rollback";
  ok $m->size() < $size+2,   "Size has returned to within two of original value";
 }

say "Time: ", time() - $T;

done_testing;
