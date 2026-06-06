#!/usr/bin/env perl

use strict;
use warnings;

use Check::Term qw(check_term_capabilities);
use Test::More 'tests' => 1;

SKIP: {
        skip $Check::Term::ERROR_MESSAGE, 1
                unless check_term_capabilities('parm_ich');

        ok(1, "Terminal 'parm_ich' capability test");
};

# Output with 'parm_ich' capability:
# 1..1
# ok 1 - Terminal 'parm_ich' capability test

# Output without 'parm_ich' capability:
# 1..1
# ok 1 # skip Terminal capability 'parm_ich' ins't supported.