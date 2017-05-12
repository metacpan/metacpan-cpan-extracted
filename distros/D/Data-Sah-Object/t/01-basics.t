#!perl

use 5.010;
use strict;
use warnings;

use Test::More 0.98;
#use Test::Exception;

use Data::Sah::Object;

subtest "string" => sub {
    my $osch = sah("foo");
    is($osch->type, "foo");
    ok(!$osch->clause('req'));
    ok(!$osch->req);
};

subtest "string*" => sub {
    my $osch = sah("foo*");
    is($osch->type, "foo");
    ok($osch->clause('req'));
    ok($osch->req);
};

subtest "array" => sub {
    my $osch = sah(['foo']);
    is($osch->type, "foo");
    ok(!$osch->clause('req'));
};

subtest "array*" => sub {
    my $osch = sah(['foo*']);
    is($osch->type, "foo");
    ok($osch->clause('req'));
};

subtest "array with clauses" => sub {
    my $osch = sah(['foo*', bar=>2]);
    is($osch->type, "foo");
    is($osch->clause('bar'), 2);
};

subtest "array with clause set" => sub {
    my $osch = sah(['foo*', {bar=>2}]);
    is($osch->type, "foo");
    is($osch->clause('bar'), 2);
};

subtest "array with clause set (sahn)" => sub {
    my $osch = sahn(['foo', {bar=>2}]);
    is($osch->type, "foo");
    is($osch->clause('bar'), 2);

    # set methods

    $osch->type('baz');
    is($osch->type, "baz");

    $osch->clause('bar', 3);
    is($osch->clause('bar'), 3);

    $osch->req(1);
    ok($osch->req);

    $osch->delete_clause('bar');
    ok(!$osch->clause('bar'));
};

DONE_TESTING:
done_testing;
