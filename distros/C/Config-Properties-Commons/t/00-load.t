#!perl

####################
# LOAD CORE MODULES
####################
use strict;
use warnings FATAL => 'all';
use Test::More;

# Autoflush ON
local $| = 1;

# Test _use_
use_ok('Config::Properties::Commons')
  || BAIL_OUT('Failed to load Config::Properties::Commons');

# Done
done_testing();
exit 0;
