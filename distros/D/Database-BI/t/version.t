#!/usr/bin/env perl

# Author test: every module must carry a $VERSION, and any version stated in
# the POD must agree with it.  A module that ships without a version -- or with
# two different ones -- is a packaging defect that the rest of the suite does
# not notice, because the tests load the modules from lib/ and never ask what
# they claim to be.
#
# Skips without Test::Version, and does not run unless AUTHOR_TESTING is set.
#
#   AUTHOR_TESTING=1 prove -l t/version.t

use strict;
use warnings;
use Test::DescribeMe qw(author);
use Test::Most;
use Test::Needs 'Test::Version';

Test::Version->import();

# 'lib' is named explicitly: left to itself, Test::Version checks blib/ when a
# build directory exists, which is stale the moment lib/ is edited.
#
# done_testing() needs Test::More (Test::Most above), and is needed because
# version_all_ok() reports one test per module and a summary but never declares
# a plan of its own -- without it the harness sees a test file that ran tests
# and produced no plan, and reports a failure for a distribution in perfect
# health.
version_all_ok('lib');
done_testing();
