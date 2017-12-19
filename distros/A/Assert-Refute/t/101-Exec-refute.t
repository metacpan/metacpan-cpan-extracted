#!perl

use strict;
use warnings;
use Test::More;

use Assert::Refute::Exec;

my $c = Assert::Refute::Exec->new;

ok $c->is_passing, "passing: empty = ok";
is $c->count, 0, "0 tests run";

ok $c->refute( 0, "right" ), "refute(false) yelds true";
ok $c->is_passing, "still passing";
ok !$c->refute( "foobared", "wrong" ), "refute(false) yelds true";
ok !$c->is_passing, "not passing now";
is $c->count, 2, "2 tests now";

like $c->as_tap, qr/^ok 1 - right\nnot ok 2 - wrong\n# .*foobared.*\n$/s,
    "as_tap looks like tap";

$c->done_testing;
like $c->as_tap, qr/\n1..2(\n|$)/, "Plan present";

eval {
    $c->done_testing;
};

like $@, qr/Assert::Refute::Exec->done_testing.*done_testing.*no more/
    , "done_testing locks execution log";

done_testing;
