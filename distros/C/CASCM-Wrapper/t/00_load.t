#!/usr/bin/perl

#####################
# LOAD CORE MODULES
#####################
use strict;
use warnings;
use Test::More;

# Autoflush
local $| = 1;

# What are we testing?
my $module = "CASCM::Wrapper";

# Check loading
use_ok($module) or BAIL_OUT("Failed to load $module. Pointless to continue");

# Check Object creation
new_ok($module)
  or BAIL_OUT("Cannot initialize object for $module. Stopping tests");

done_testing();
