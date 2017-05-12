use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/lib";

use Test::More tests => 1;

# This fails for me on 5.8.8 with the following module versions:
#
# Class:C3                 0.21
# Class::C3::Componentised 1.0005
# DBIx::Class              0.08013 (0.08099_05 works)

use TestAppC3Fail;

