#
# file: t/use.t
#
use strict;
use Test;

# use a BEGIN block so we print our plan before FileSystem is loaded
BEGIN { plan tests => 1 }

# load your module...
use DBIx::FileSystem;

print "# currently no usefull test available for an interactive shell\n";
ok(1); # success
