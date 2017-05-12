use strict;
use warnings;
use File::Spec;
use Test::More;
use English qw(-no_match_vars);

if ($ENV{TEST_COVERAGE}) {
    plan( skip_all => 'Disabled when testing coverage.' );
}

if ( not $ENV{ALIEN_CODEPRESS_AUTHOR} ) {
    my $msg = 'Author test.  Set $ENV{ALIEN_CODEPRESS_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval 'use Test::MinimumVersion'; ## no critic

if ( $EVAL_ERROR ) {
    my $msg = 'Test::MinimumVersion required';
    plan( skip_all => $msg );
}


Test__MinimumVersion->import;
all_minimum_version_ok('5.006000');
