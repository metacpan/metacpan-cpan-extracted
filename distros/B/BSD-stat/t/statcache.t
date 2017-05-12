#
# $Id: statcache.t,v 1.21 2012/08/19 13:29:26 dankogai Exp $
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
use strict;
my $Debug = $ARGV[0] || 0;
BEGIN { plan tests => 27 };

use BSD::stat ();

BSD::stat::lstat($0); ok((-r _) == (-r $0));
BSD::stat::lstat($0); ok((-w _) == (-w $0));
BSD::stat::lstat($0); ok((-x _) == (-x $0));
BSD::stat::lstat($0); ok((-o _) == (-o $0));
BSD::stat::lstat($0); ok((-R _) == (-R $0));
BSD::stat::lstat($0); ok((-W _) == (-W $0));
BSD::stat::lstat($0); ok((-X _) == (-X $0));
BSD::stat::lstat($0); ok((-O _) == (-O $0));
BSD::stat::lstat($0); ok((-e _) == (-e $0));
BSD::stat::lstat($0); ok((-z _) == (-z $0));
BSD::stat::lstat($0); ok((-s _) == (-s $0)); 
BSD::stat::lstat($0); ok((-f _) == (-f $0));
BSD::stat::lstat($0); ok((-d _) == (-d $0));

# -l _ should only work on lstat so we test that, too.

BSD::stat::lstat($0); ok((-l _) == (-l $0));
eval {BSD::stat::stat($0); (-l _)}; ok($@);

BSD::stat::lstat($0); ok((-p _) == (-p $0));
BSD::stat::lstat($0); ok((-S _) == (-S $0));
BSD::stat::lstat($0); ok((-b _) == (-b $0));
BSD::stat::lstat($0); ok((-c _) == (-c $0));

# Stat cache does not work on -t so this one is commented out.
# BSD::stat::lstat(*STDIN); (-t _) == (-t STDIN));

BSD::stat::lstat($0); ok((-u _) == (-u $0));
BSD::stat::lstat($0); ok((-g _) == (-g $0));
BSD::stat::lstat($0); ok((-k _) == (-k $0));
BSD::stat::lstat($0); ok((-T _) == (-T $0));
BSD::stat::lstat($0); ok((-B _) == (-B $0));
BSD::stat::lstat($0); ok((-M _) == (-M $0));
BSD::stat::lstat($0); ok((-A _) == (-A $0));
BSD::stat::lstat($0); ok((-C _) == (-C $0));

if ($Debug){
   my @lstat = BSD::stat::lstat(*STDIN);
   warn join(",", @lstat), "\n";
}

