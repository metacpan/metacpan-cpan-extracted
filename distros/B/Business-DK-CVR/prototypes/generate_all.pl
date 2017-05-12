#!/usr/bin/perl

# $Id: generate_all.pl,v 1.1 2008-06-11 08:08:00 jonasbn Exp $

use strict;
use warnings;

use Business::DK::CVR qw(validate);

my $valid = 0;

for (1 .. 99999999) {
    my $cvr = sprintf "%08d", $_;
    
    if (validate($cvr)) {
        $valid++;
        #print "$cvr\n";
    }
    
    
}
print STDERR "Total count of valid CVRs = $valid\n";

exit(0);
