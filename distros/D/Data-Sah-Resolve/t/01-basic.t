#!perl

use 5.010001;
use strict;
use warnings;

use Data::Dmp;
use Data::Sah::Resolve qw(resolve_schema);
use Test::Exception;
use Test::More 0.98;
use Test::Needs;
use Test::Deep;

subtest "unknown" => sub {
    test_resolve(
        name   => "unknown -> dies",
        schema => "foo",
        dies => 1,
    );
};

subtest "recursion" => sub {
    test_resolve(
        schema => "example::recurse1",
        dies => 1,
    );
    test_resolve(
        schema => "example::recurse2a",
        dies => 1,
    );
    test_resolve(
        schema => "example::recurse2b",
        dies => 1,
    );
};

subtest "Data::Sah" => sub {
    # we need Data::Sah::Type::int which is currently included in the Data-Sah
    # distribution
    test_needs "Data::Sah::Type::int";

    test_resolve(
        schema => "int",
        result => ["int", []],
    );
    test_resolve(
        schema => ["int"],
        result => ["int", []],
    );
    test_resolve(
        schema => ["int", {}],
        result => ["int", []],
    );
    test_resolve(
        schema => ["int", min=>2],
        result => ["int", [{min=>2}]],
    );

    test_resolve(
        schema => "posint",
        result => ["int", [superhashof({summary=>"Positive integer (1, 2, ...)", min=>1})]],
    );
    test_resolve(
        schema => ["posint", min=>10],
        result => ["int", [superhashof({summary=>"Positive integer (1, 2, ...)", min=>1}), {min=>10}]],
    );
    test_resolve(
        schema => ["posint", "merge.delete.min"=>undef],
        result => ["int", [superhashof({summary=>"Positive integer (1, 2, ...)"})]],
    );

    test_resolve(
        schema => ["poseven"],
        result => ["int", [superhashof({summary=>"Positive integer (1, 2, ...)", min=>1}), superhashof({summary=>"Positive even number", div_by=>2})]],
    );
    test_resolve(
        schema => ["poseven", min=>10, div_by=>3],
        result => ["int", [superhashof({summary=>"Positive integer (1, 2, ...)", min=>1}), superhashof({summary=>"Positive even number", div_by=>2}), superhashof({min=>10, div_by=>3})]],
    );
    test_resolve(
        name   => "2 merges",
        schema => ["example::has_merge", {"merge.normal.div_by"=>3}],
        result => ["int", [superhashof({summary=>"Even integer", div_by=>3})]],
    );
};

# XXX test error in merging -> dies

DONE_TESTING:
done_testing;

sub test_resolve {
    my %args = @_;

    subtest(($args{name} // dmp($args{schema})), sub {
        my $res;
        if ($args{dies}) {
            dies_ok { resolve_schema($args{schema}) } "resolve dies"
                or return;
        } else {
            lives_ok { $res = resolve_schema($args{schema}) } "resolve lives"
                or return;
        }
        if ($args{result}) {
            cmp_deeply($res, $args{result}, "result")
                or diag explain $res;
        }
    });
}
