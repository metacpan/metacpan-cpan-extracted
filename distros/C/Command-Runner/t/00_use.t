use strict;
use warnings;
use Test::More tests => 1;
use Command::Runner;

use Command::Runner::Timeout;
diag "Command::Runner::Timeout::_USE_CLOCK_MONOTONIC = $Command::Runner::Timeout::_USE_CLOCK_MONOTONIC";

pass "happy hacking!";
