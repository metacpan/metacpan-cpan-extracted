#!perl

use 5.010;
use strict;
use warnings;

use Test::Config::IOD::Common;
use Test::More 0.98;

$Test::Config::IOD::Common::CLASS = "Config::IOD";
Test::Config::IOD::Common::test_common_iod();

DONE_TESTING:
done_testing;
