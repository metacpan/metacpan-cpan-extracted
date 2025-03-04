#!perl
#
# This file is part of App-SpreadRevolutionaryDate
#
# This software is Copyright (c) 2019-2024 by Gérald Sédrati.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

use Test::More 0.96 tests => 1;
eval { require Test::Vars };

SKIP: {
    skip 1 => 'Test::Vars required for testing for unused vars'
        if $@;
    Test::Vars->import;

    subtest 'unused vars' => sub {
all_vars_ok();
    };
};
