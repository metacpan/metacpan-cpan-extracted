#!/usr/bin/env perl


use strict;
use warnings;

use Test::More;
use Test::CheckDeps;

check_dependencies();

BAIL_OUT("Missing dependencies")   unless Test::More->builder->is_passing;

done_testing();
