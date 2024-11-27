#!/usr/bin/perl
use warnings;
use strict;

package
    My;

use ARGV::OrDATA;

print ARGV::OrDATA::is_using_argv() ? 1 : 0;
print ARGV::OrDATA::is_using_data() ? 1 : 0;
print "\n";

__DATA__
1
