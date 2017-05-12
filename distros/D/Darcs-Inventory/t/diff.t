#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use List::Util;
use Darcs::Inventory;
use Darcs::Inventory::Diff;

plan tests => 4;

my $have_darcs = `darcs --version` =~ /^[2-9]/; # Need version 2 for this test.

mkdir "t/darcs-diff-test";
chdir "t/darcs-diff-test" or die "# t/darcs-diff-test: $!";
if ($have_darcs) {
    # This test has to make a repo complicated enough that unpulling a
    # patch affects the line numbers of other patches.
    my $setup = <<'SETUP';
rm -rf _darcs a
darcs init --hashed
printf "1\n2\n3\n4\n5\n" > a
darcs add a
darcs record --ignore-times --all --author="test" -m "1"
printf "1\n2\nb\n3\n4\n5\n" > a
darcs record --ignore-times --all --author="test" -m "2"
printf "1\n2\nb\n3\n4\d\n5\n" > a
darcs record --ignore-times --all --author="test" -m "3"
printf "1\n2\nb\n3\n4\d\n5\n6\n" > a
darcs record --ignore-times --all --author="test" -m "4"

chmod +w inventory_old inventory_new
cp _darcs/hashed_inventory inventory_old
/bin/echo -n nnyd | darcs unpull
cp _darcs/hashed_inventory inventory_new
SETUP

    print("# $_\n"), system $_ for split(/\n/, $setup);
} else {
    die "No darcs and no cached darcs output" unless -f "inventory_old" && -f "inventory_new";
}

my $old = Darcs::Inventory->load("inventory_old"); isnt($old, undef, "old inventory loaded");
my $new = Darcs::Inventory->load("inventory_new"); isnt($new, undef, "new inventory loaded");
my ($not_in_old, $not_in_new) = darcs_inventory_diff($old, $new);

is(scalar @$not_in_old, 0, "Correct number of patches pushed");
is(scalar @$not_in_new, 1, "Correct number of patches unpulled");
