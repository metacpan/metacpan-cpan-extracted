#!perl -w -I../lib -I../blib/arch 
use feature ':5.12';
use strict;
use Test::More;
use Data::Dump qw(dump);
use warnings all=>'FATAL';

use DBM::Deep::Blue;

#-----------------------------------------------------------------------
# Show that memory structure si sumpable with Data::Dump::dump
#-----------------------------------------------------------------------

my $m = DBM::Deep::Blue::new();

 {my $h = $m->allocHash();
     $h = {qw(a 1 b 2 c 3 d 4)};
     $h->{x} = {qw(a 1 b 2 c 3 d 4)};
     $h->{x}{c} = [1..10];
     $h->{x}{c}[5] = [1..10];
     $h->{x}{c}[5][2] = {aaaaaaaaaaaa=>111111111};
     $h->{x}{c}[5][3] = {('b' x 1000) => ('2' x 1000)};

  my $s = dump($h);
  my $H = eval $s;
  my $S = dump($H);

  is $s, $S, "Dumps match";
 }

done_testing;
