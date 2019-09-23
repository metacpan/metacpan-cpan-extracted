#!/usr/bin/env perl

use strict;
use warnings;

use English qw(-no_match_vars);
use FindBin qw($Bin);
use lib ("$Bin/../t", 't');

use Test::More;
use Test::Fatal qw(dies_ok);

## no critic ( ProhibitStringyEval ProhibitComplexRegexes RequireDotMatchAnything RequireLineBoundaryMatching RequireExtendedFormatting)

local $EVAL_ERROR = q{}; # protect existing $@ ($EVAL_ERROR)
my $rv = eval 'use Example::Abstractionless';

diag("Diagnostics ($rv): ", $EVAL_ERROR);

like($EVAL_ERROR, qr/Class Example::Abstractionless must define is_holiday, holidays for class Date::Holidays::Abstract at/, 'abstraction not implemented, we observe a compilation error');

done_testing();
