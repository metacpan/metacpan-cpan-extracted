# Test fetching

use Test::More;
use DBD::PgPP;
use strict;

# These are white-box tests; they rely on knowledge of the internals.  That
# seems fine for this purpose (ensuring we can deal with all queries, even
# pathologically hard-to-parse ones) given that we have other tests which
# ensure we can substitute quoted argument values for query placeholders.

my @TESTS;

sub range { join '', map { chr } $_[0] .. $_[1] }

BEGIN {
    if ($] >= 5.008) {
        binmode Test::More->builder->output,         ':utf8';
        binmode Test::More->builder->failure_output, ':utf8';
    }

    @TESTS = (
        [''],
        ["x"],
        ["-- ? \n"],
        [" foo '?' bar "],
        [' foo "?" bar '],
        ['\\'],
        ["'\\'?'"],
        [' a /* ? */ b'],
        [' a /* ? /* b */ c ? */'],
        [' a /* ? /* b /* c */ d ? */ e ? */'],
        [' "/* ? /*'],
        [q['?'?'?'?'?'?'], [q['?'], \0, q['?'], \1, q['?'], \2, q[']]],
        [q['?'''?'?'?'?'?'''], [q['?'''], \0, q['?'], \1, q['?'], \2, q[''']]],
        ['?', [\0]],
        ['??', [\0, \1]],
        ['???', [\0, \1, \2]],
        [q['foo?' ? "bar?" ?], [q['foo?' ], \0, q[ "bar?" ], \1]],
        [range(0, 255), [range(0, 62), \0, range(64, 255)]],
        [range(0, 511), [range(0, 62), \0, range(64, 511)]],
    );

    plan tests => scalar @TESTS;
}

for (@TESTS) {
    my ($statement, $expected) = @$_;
    $expected = [$statement] if !$expected;
    my $parsed = DBD::PgPP::Protocol->parse_statement($statement);
    is_deeply($parsed, $expected, "Correct parse for q[$statement]");
}
