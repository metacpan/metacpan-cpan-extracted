#!perl

use 5.010001;
use strict;
use warnings;
use Test::Deep;
use Test::Exception;
use Test::More 0.98;
use Test::Needs;

use Data::Dmp;
use Data::Sah::Resolve qw(resolve_schema);

subtest "unknown" => sub {
    test_resolve(
        name   => "unknown -> dies",
        schema => "foo",
        dies => 1,
    );
};

subtest "tests that need Sah-Schemas-Examples distribution" => sub {
    test_needs "Sah::Schemas::Examples"; # for Sah::Schema::example::recurse1 et al
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
};

subtest "tests that need Data-Sah distribution" => sub {
    test_needs "Data::Sah"; # for Data::Sah::Type::int

    test_resolve(
        schema => "int",
        result => {
            v => 2,
            type=>"int",
            clsets_after_type => [{}],
            "clsets_after_type.alt.merge.merged" => [],
            base=>"int",
            clsets_after_base => [],
            resolve_path => ["int"],
        },
    );
    test_resolve(
        schema => ["int"],
        result => {
            v => 2,
            type=>"int",
            clsets_after_type => [{}],
            "clsets_after_type.alt.merge.merged" => [],
            base=>"int",
            clsets_after_base => [],
            resolve_path => ["int"],
        },
    );
    test_resolve(
        schema => ["int", {}],
        result => {
            v => 2,
            type=>"int",
            clsets_after_type => [{}],
            "clsets_after_type.alt.merge.merged" => [],
            base=>"int",
            clsets_after_base => [],
            resolve_path => ["int"],
        },
    );
    test_resolve(
        schema => ["int", min=>2],
        result => {
            v => 2,
            type=>"int",
            clsets_after_type => [{min=>2}],
            "clsets_after_type.alt.merge.merged" => [{min=>2}],
            base=>"int",
            clsets_after_base => [{min=>2}],
            resolve_path => ["int"],
        },
    );

    subtest "tests that need Sah-Schemas-Int" => sub {
        test_needs "Sah::Schemas::Int"; # provides Sah::Schema::posint, et al

        test_resolve(
            schema => "posint",
            result => {
                v => 2,
                type=>"int",
                clsets_after_type => [superhashof({min=>1}),{}],
                "clsets_after_type.alt.merge.merged" => [superhashof({min=>1})],
                base=>"int",
                clsets_after_base => [superhashof({min=>1})],
                resolve_path => ["int","posint"],
            },
        );
        test_resolve(
            name => "posint opt:allow_base_with_no_additional_clauses=1",
            schema => "posint",
            opts => {allow_base_with_no_additional_clauses=>1},
            result => {
                v => 2,
                type=>"int",
                clsets_after_type => [superhashof({min=>1}),{}],
                "clsets_after_type.alt.merge.merged" => [superhashof({min=>1})],
                base=>"posint",
                clsets_after_base => [],
                resolve_path => ["int","posint"],
            },
        );
        test_resolve(
            schema => ["posint", min=>10],
            result => {
                v => 2,
                type=>"int",
                clsets_after_type => [superhashof({min=>1}),{min=>10}],
                "clsets_after_type.alt.merge.merged" => [superhashof({min=>1}), {min=>10}],
                base=>"posint",
                clsets_after_base => [{min=>10}],
                resolve_path => ["int","posint"],
            },
        );
        test_resolve(
            schema => ["posint", "merge.delete.min"=>undef],
            result => {
                v => 2,
                type=>"int",
                clsets_after_type => [superhashof({min=>1}),{"merge.delete.min"=>undef}],
                "clsets_after_type.alt.merge.merged" => [superhashof({})],
                base=>"int",
                clsets_after_base => [superhashof({min=>1}),{"merge.delete.min"=>undef}],
                resolve_path => ["int","posint"],
            },
        );

        test_resolve(
            name => "poseven opt:allow_base_with_no_additional_clauses=1",
            schema => ["poseven"],
            opts => {allow_base_with_no_additional_clauses=>1},
            result => {
                v => 2,
                type=>"int",
                clsets_after_type => [superhashof({min=>1}),superhashof({div_by=>2}),{}],
                "clsets_after_type.alt.merge.merged" => [superhashof({min=>1}),superhashof({div_by=>2})],
                base=>"poseven",
                clsets_after_base => [],
                resolve_path => ["int","posint","poseven"],
            },
        );
        test_resolve(
            schema => ["poseven", min=>10, div_by=>3],
            result => {
                v => 2,
                type=>"int",
                clsets_after_type => [superhashof({min=>1}),superhashof({div_by=>2}),{min=>10,div_by=>3}],
                "clsets_after_type.alt.merge.merged" => [superhashof({min=>1}),superhashof({div_by=>2}),{min=>10,div_by=>3}],
                base=>"poseven",
                clsets_after_base => [{min=>10,div_by=>3}],
                resolve_path => ["int","posint","poseven"],
            },
        );

        subtest "tests that need Sah-Schemas-Examples" => sub {
            test_needs "Sah::Schemas::Examples"; # provides Sah::Schema::example::has_merge et al
            test_resolve(
                name   => "2 merges",
                schema => ["example::has_merge", {"merge.normal.div_by"=>3}],
                result => {
                    v => 2,
                    type=>"int",
                    clsets_after_type => [superhashof({min=>1}),superhashof({div_by=>2}),{"merge.normal.div_by"=>3}],
                    "clsets_after_type.alt.merge.merged" => [superhashof({div_by=>3})],
                    base=>"int",
                    clsets_after_base => [superhashof({min=>1}),superhashof({div_by=>2}),{"merge.normal.div_by"=>3}],
                    resolve_path => ["int","posint","example::has_merge"],
                },
            );
        };
    };
};

# XXX test error in merging -> dies

DONE_TESTING:
done_testing;

sub test_resolve {
    my %args = @_;

    subtest(($args{name} // dmp($args{schema})), sub {
        my $res;
        my $opts = $args{opts} // {};
        if ($args{dies}) {
            dies_ok { resolve_schema($opts, $args{schema}) } "resolve dies"
                or return;
        } else {
            lives_ok { $res = resolve_schema($opts, $args{schema}) } "resolve lives"
                or return;
        }
        if ($args{result}) {
            cmp_deeply($res, $args{result}, "result")
                or diag explain $res;
        }
    });
}
