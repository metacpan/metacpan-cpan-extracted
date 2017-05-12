#!perl -w

use strict;
use warnings;

# for perl < 5.10.0 (5.9.5) runs at CHECK time, otherwise at UNITCHECK time
use Check::UnitCheck sub {print "UNITCHECK\n"};

BEGIN { print "begin\n" }

# if you're using Perl with UNITCHECK:
# UNITCHECK { print "unitcheck\n" }

CHECK { print "check\n" }
INIT  { print "init\n" }
END   { print "end\n" }
