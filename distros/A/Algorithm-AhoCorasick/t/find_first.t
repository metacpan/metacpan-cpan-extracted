#!perl -T

use strict;
use warnings;
use Test::More tests => 16;

use Algorithm::AhoCorasick qw(find_first);

my ($pos, $keyword) = find_first("To be or not to be", "be");
is($pos, 3);
is($keyword, "be");

my @pair = find_first("To be or not to be", "be");
is(scalar(@pair), 2);
is($pair[0], 3);
is($pair[1], "be");

my $pair = find_first("To be or not to be", "be");
is(scalar(@$pair), 2);
is($pair->[0], 3);
is($pair->[1], "be");

my @mismatch = find_first("To be or not to be", "bet");
ok(!scalar(@mismatch));

my $mismatch = find_first("To be or not to be", "bet");
ok(!defined($mismatch));

sub test_fail {
    my $name = shift;

    eval {
	find_first(@_);
	fail($name);
    };
    if ($@) {
	ok(1, $name);
    }
}

test_fail("0 args");
test_fail("0 keywords", "To be or not to be");
test_fail("empty keyword", "To be or not to be", "be", "");

($pos, $keyword) = find_first("To be or not to be", "be", "be");
is($pos, 3);
is($keyword, "be");

$mismatch = find_first("To be or not to be", 0);
ok(!defined($mismatch));
