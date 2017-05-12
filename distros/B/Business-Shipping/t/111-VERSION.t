#!/bin/env perl

# Check that VERSION is set correctly.

use strict;
use warnings;
use Test::More 'no_plan';
use Business::Shipping;

ok($Business::Shipping::VERSION > 0, "Business::Shipping::VERSION set");
