#!perl

####################
# LOAD MODULES
####################
use strict;
use warnings FATAL => 'all';

use Test::More;
use Test::Pod;

# Autoflush ON
local $| = 1;

# Test POD
my $ok = all_pod_files_ok();

# Done
done_testing();
exit 1 if not $ok;
exit 0;
