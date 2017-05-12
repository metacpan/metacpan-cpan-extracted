#!/usr/bin/env perl

use Test::More tests => 1;

BEGIN {
    use_ok( 'DBIx::MultiStatementDo' ) || print "Bail out!
";
}

diag(
"Testing DBIx::MultiStatementDo $DBIx::MultiStatementDo::VERSION, Perl $], $^X"
);
