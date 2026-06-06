#!/usr/bin/env perl

use strict;
use warnings;

use Check::Term qw(check_term_capabilities $ERROR_MESSAGE);

if (check_term_capabilities('parm_ich')) {
        print "We could use terminal 'parm_ich' capability.\n";
} else {
        print "We couldn't use terminal 'parm_ich' capability.\n";
        print "Error message: $ERROR_MESSAGE\n";
}

# Output with 'parm_ich' capability:
# We could use terminal 'parm_ich' capability.

# Output without 'parm_ich' capability:
# We couldn't use terminal 'parm_ich' capability.
# Error message: Terminal capability 'parm_ich' ins't supported.