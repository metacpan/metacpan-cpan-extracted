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
use_ok('Bintray::API') || BAIL_OUT('Failed to load Bintray::API');

# Done
done_testing();
exit 0;
