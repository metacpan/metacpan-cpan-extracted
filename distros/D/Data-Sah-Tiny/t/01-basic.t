#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;
#use Test::Warn;

use Data::Sah::Tiny qw(
                          gen_validator
                          normalize_schema
                  );

subtest normalize_schema => sub {
    is_deeply(normalize_schema("int"), ["int", {}]);
    is_deeply(normalize_schema(["int*"]), ["int", {req=>1}]);
};

subtest gen_validator => sub {
    subtest "unknown opt -> dies" => sub {
        dies_ok { gen_validator("int", {foo=>1}) };
    };

    subtest "opt: source=1" => sub {
        my $v = gen_validator("int", {source=>1});
        ok(defined $v);
        ok(!ref($v));
    };

    subtest "opt: schema_is_normalized" => sub {
        dies_ok  { gen_validator("int", {schema_is_normalized=>1}) };
        lives_ok { gen_validator(["int", {}], {schema_is_normalized=>1}) };
    };

    subtest "unknown type -> dies" => sub {
        dies_ok { gen_validator("foo") };
    };

    subtest "clause:req" => sub {
        my $v = gen_validator("int");
        ok( $v->(undef));
        $v = gen_validator("int*");
        ok(!$v->(undef));
    };

    subtest "clause:forbidden" => sub {
        my $v = gen_validator(["int", forbidden=>1]);
        ok( $v->(undef));
        ok(!$v->(1));
    };

    subtest "unknown clause -> dies" => sub {
        dies_ok { gen_validator(["int", foo=>1]) };
    };

    subtest "clause:default, opt:return_type=bool_valid+val" => sub {
        my ($v, $res);

        $v = gen_validator("int", {return_type=>'bool_valid+val'});
        $res = $v->(undef);
        ok($res->[0]);
        is_deeply($res->[1], undef);

        $v = gen_validator(["int", default=>2], {return_type=>'bool_valid+val'});
        $res = $v->(undef);
        ok($res->[0]);
        is_deeply($res->[1], 2);
        $res = $v->(3);
        ok($res->[0]);
        is_deeply($res->[1], 3);
        $res = $v->("a");
        ok(!$res->[0]);
    };

    subtest "type int" => sub {
        my $v;

        $v = gen_validator("int");
        ok( $v->(0));
        ok(!$v->("a"));

        subtest "clause:min" => sub {
            my $v = gen_validator([int => min=>2]);
            ok(!$v->(1));
            ok( $v->(2));
            ok( $v->(3));
        };
        subtest "clause:max" => sub {
            my $v = gen_validator([int => max=>2]);
            ok( $v->(1));
            ok( $v->(2));
            ok(!$v->(3));
        };
    };

    subtest "type str" => sub {
        subtest "clause:min_len" => sub {
            my $v = gen_validator([str => min_len=>2]);
            ok(!$v->("a"));
            ok( $v->("aa"));
            ok( $v->("aaa"));
        };
        subtest "clause:max_len" => sub {
            my $v = gen_validator([str => max_len=>2]);
            ok( $v->("a"));
            ok( $v->("aa"));
            ok(!$v->("aaa"));
        };
    };

    subtest "type array" => sub {
        my $v;

        $v = gen_validator("array");
        ok(!$v->(0));
        ok(!$v->("a"));
        ok( $v->([]));

        subtest "clause:min_len" => sub {
            my $v = gen_validator([array => min_len=>2]);
            ok(!$v->([]));
            ok(!$v->([1]));
            ok( $v->([1,2]));
            ok( $v->([1,2,3]));
        };
        subtest "clause:max_len" => sub {
            my $v = gen_validator([array => max_len=>2]);
            ok( $v->([]));
            ok( $v->([1]));
            ok( $v->([1,2]));
            ok(!$v->([1,2,3]));
        };
        subtest "clause:of" => sub {
            my $v;

            $v = gen_validator([array => of=>"int*"]);
            ok( $v->([]));
            ok( $v->([1,2,3,4]));
            ok(!$v->([1,2,undef,4]));
            ok(!$v->([1,2,"a",4]));
            ok(!$v->([1,2,[],4]));

            $v = gen_validator([array => of=>["array*", of=>"int*"]]);
            ok( $v->([]));
            ok( $v->([[],[1],[2],[]]));
            ok(!$v->([[],[1], 2 ,[]]));
            ok(!$v->([[],[1], undef ,[]]));
            ok(!$v->([[],[1], [[]] ,[]]));
        };
    };
};

DONE_TESTING:
done_testing;
