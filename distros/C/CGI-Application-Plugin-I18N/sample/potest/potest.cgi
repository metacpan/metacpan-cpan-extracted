#!/usr/bin/perl -w
BEGIN {
    use FindBin qw ($RealBin $RealScript);
    use lib $FindBin::RealBin;
    use lib "$FindBin::RealBin/cpanlib";
    chdir $RealBin;
}#BEGIN

$| = 1;

use potest;
use strict;

my $potest = potest->new();
$potest->run();