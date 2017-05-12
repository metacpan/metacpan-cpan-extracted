#!perl

use strict;
use warnings;
use Config::Validator qw(treeify treeval);
use Test::More tests => 16;

our(%hash);

%hash = ();
treeify(\%hash);
is(scalar(keys(%hash)), 0, "treeify(empty)");

%hash = (
    "foo" => { "abc" => 1 },
    "foo-def" => 2,
    "foo-ghi" => 3,
    "bar-abc" => 4,
    "abc" => 5,
);

is(treeval(\%hash, "abc"), 5, "treeval(abc)");
is(treeval(\%hash, "bar-abc"), 4, "treeval(bar-abc)");
is(treeval(\%hash, "foo-ghi"), 3, "treeval(foo-ghi)");
is(treeval(\%hash, "foo-abc"), 1, "treeval(foo-abc)");

treeify(\%hash);
is(scalar(keys(%hash)), 3, "treeify(hash).size");
is(join("|", sort(keys(%hash))), "abc|bar|foo", "treeify(hash).keys");
is($hash{abc}, 5, "treeify(hash.abc)");
is(scalar(keys(%{$hash{bar}})), 1, "treeify(hash.bar).size");
is(join("|", sort(keys(%{$hash{bar}}))), "abc", "treeify(hash.bar).keys");
is(scalar(keys(%{$hash{foo}})), 3, "treeify(hash.foo).size");
is(join("|", sort(keys(%{$hash{foo}}))), "abc|def|ghi", "treeify(hash.foo).keys");

is(treeval(\%hash, "abc"), 5, "treeval(abc)");
is(treeval(\%hash, "bar-abc"), 4, "treeval(bar-abc)");
is(treeval(\%hash, "foo-ghi"), 3, "treeval(foo-ghi)");
is(treeval(\%hash, "foo-abc"), 1, "treeval(foo-abc)");
