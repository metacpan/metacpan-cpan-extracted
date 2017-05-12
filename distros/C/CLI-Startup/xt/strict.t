#!/usr/bin/perl

use strict;
use warnings;
no warnings 'once';

use Test::More;

eval "use Test::Strict";
plan skip_all => "Test::Strict not installed" if $@;

# Also ensure that warnings are on
$Test::Strict::TEST_WARNINGS = 1;

all_perl_files_ok(qw( lib ));
