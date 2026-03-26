#!/usr/bin/env perl

use strict;
use warnings;

use Business::UDC;

if (@ARGV < 1) {
       print STDERR "Usage: $0 udc_string\n";
       exit 1;
}
my $udc_string = $ARGV[0];

# Object.
my $obj = Business::UDC->new($udc_string);

print "UDC string $udc_string ";
if ($obj->is_valid) {
       print "is valid\n";
} else {
       print "is not valid\n";
}

# Output for '821.111(73)-31"19"':
# UDC string 821.111(73)-31"19" is valid

# Output for '821.111(73)-31"19':
# UDC string 821.111(73)-31"19 is not valid