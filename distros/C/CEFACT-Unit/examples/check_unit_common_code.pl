#!/usr/bin/env perl

use strict;
use warnings;

use CEFACT::Unit;

if (@ARGV < 1) {
        print STDERR "Usage: $0 unit_common_code\n";
        exit 1;
}
my $unit_common_code = $ARGV[0];

# Object.
my $obj = CEFACT::Unit->new;

# Check unit common code.
my $bool = $obj->check_common_code($unit_common_code);

# Print out.
print "Unit '$unit_common_code' is ".($bool ? 'valid' : 'invalid')."\n";

# Output for 'KGM':
# Unit 'KGM' is valid

# Output for 'XXX':
# Unit 'XXX' is invalid