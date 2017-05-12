#!/usr/local/bin/perl -w  

use strict;
use Test::More;

BEGIN {
	plan tests => 1;
}

#
#	CLearCase::Region cannot be loaded if Region.cfg does not exist
#	in at least one of the @INC directories.  So, this test used the
#	sample Region.cfg file found in the examples directory.
#
use lib qw(./examples);
use ClearCase::Region;
ok(1);

exit 
