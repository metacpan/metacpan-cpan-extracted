#!perl -w -I../lib -I../blib/arch 
use feature ':5.12';
use strict;
use Test::More;
use Time::HiRes qw(time);
use warnings all=>'FATAL';

use DBM::Deep::Blue;

my $N = 2e3;
my $T = time();

#-----------------------------------------------------------------------
# Array
#-----------------------------------------------------------------------

 {my $m = DBM::Deep::Blue::new();
  my $a = $m->allocArray();

  my $s = '';
  for(0..$N)
   {my $t = 'a'x$_;
 
    push @$a, $t;
    $s .= $t;

    next if $_ % 1e2;
    my $S = ''; $S .= $_ for @$a;
    is $s, $S, "Array matchs at $_";
   }
 }

#-----------------------------------------------------------------------
# Hash
#-----------------------------------------------------------------------

 {my $m = DBM::Deep::Blue::new();
  my $h = $m->allocHash();

  my $s = '';
  for(0..$N)
   {my $t = 'a'x$_;
 
    $h->{$t} = $t;
    $s .= $t;

    next if $_ % 1e2;
    my $S = ''; $S .= $_ for keys %$h;
    is $s, $S, "Hash matchs at $_";
   }
 }

say "Time: ", time() - $T;

done_testing;
