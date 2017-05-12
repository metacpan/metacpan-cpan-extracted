#
# $Id: basic.t,v 1.21 2012/08/19 13:29:26 dankogai Exp $
#
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
use strict;
my $Debug = 0;
BEGIN { plan tests => 16 };

use BSD::stat;
ok(1); # If we made it this far, we're ok.

my $stat;
$stat = BSD::stat::stat($0);
$! ? ok(0) : ok(1);
$stat = BSD::stat::stat('nonexistent');
$! ? ok(1) : ok(0);
$Debug and warn $!;

my @bsdstat = lstat($0);
my @perlstat = CORE::lstat($0);
for my $i (0..$#perlstat){
    $perlstat[$i] == $bsdstat[$i] ? ok(1) : ok(0);
}
$Debug and warn join(",", @bsdstat), "\n";
