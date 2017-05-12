# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should
# work as `perl 02-code-snippet.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 2;

my $g_expected_lines;
BEGIN {
    $g_expected_lines = 98;
    eval 'require Blueprint';
    unless ($@) {
        # We add two lines of decoration if we are using certain build systems
        $g_expected_lines +=3;
    }
}

BEGIN { use_ok('C::Scan::Constants') };                        # 1

my $snippet = C::Scan::Constants::_suggested_code_snippets();
my @snippet_lines = split q{\n}, $snippet;
is( scalar @snippet_lines, $g_expected_lines,
    "Number of snippet lines matches expected number" );       # 2
