#!/usr/bin/env perl

use strict;
use warnings;
use vars qw($VERSION);
use FindBin qw($Bin);
use lib "$Bin/../lib";

use Business::DK::CPR qw(calculate);

$VERSION = '0.01';

my $arg = $ARGV[0];
chomp $arg;
my @cprs = calculate($arg);

foreach (@cprs) {
    print "$_\n";
}

exit 0;
