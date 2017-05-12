#!perl -w -I../lib -I../blib/arch 
use feature ':5.12';
use strict;
use Test::More;
use Time::HiRes qw(time);
use warnings all=>'FATAL';

use DBM::Deep::Blue;

mkdir("memory");
my $f = "memory/clear.data";

for(1..10)
  {my $m = DBM::Deep::Blue::file($f);
   my $db = $m->allocGlobalArray();

    ##
    # put/get many keys
    ##
    my $max_keys = 4000;

    for ( 0 .. $max_keys ) {
        $db->[$_] = $_ * 2;
    }

    my $count = -1;
    for ( 0 .. $max_keys ) {
        $count = $_;
        unless ( $db->[$_ ] == $_ * 2 ) {
            last;
        };
    }
    is( $count, $max_keys, "We read $count keys" );

    cmp_ok( scalar(@$db), '==', $max_keys + 1, "Number of elements is correct" );
    @$db = ();
    cmp_ok( scalar(@$db), '==', 0, "Number of elements after clear() is correct" );
  }

done_testing;
