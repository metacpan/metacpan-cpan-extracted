#!perl

####################
# LOAD MODULES
####################
use strict;
use warnings FATAL => 'all';
use Test::More;

# Autoflush ON
local $| = 1;

# Test _use_
use_ok('CASCM::CLI') || BAIL_OUT('Failed to load CASCM::CLI');

# Done
done_testing();
exit 0;
