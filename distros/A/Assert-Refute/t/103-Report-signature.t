#!perl

use strict;
use warnings;
BEGIN{ delete @ENV{qw(NDEBUG PERL_NDEBUG)} };
use Test::More;

use Assert::Refute::Report;

my $c = Assert::Refute::Report->new;

is $c->get_sign, "tr", "Start with 0 tests";

$c->refute(0);
is $c->get_sign, "t1r", "Still running";

$c->refute(0);
is $c->get_sign, "t2r", "Passes compacter";

$c->refute(1);
is $c->get_sign, "t2Nr", "Failing test added";

$c->refute(0) for 1 .. 3;
is $c->get_sign, "t2N3r", "3 more tests";

$c->done_testing;
is $c->get_sign, "t2N3d", "Done testing added";

my $live = eval {
    $c->done_testing("Dies afterwards");
    1;
};
is $live, 1, "done_testing with error lives"
    or diag "Exception was: $@";

is $c->get_sign, "t2N3E", "Exception added - so E at the end";

done_testing;
