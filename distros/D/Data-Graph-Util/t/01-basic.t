#!perl

use 5.010001;
use strict;
use warnings;

use Data::Graph::Util qw(toposort is_cyclic is_acyclic);
use Test::Exception;
use Test::More 0.98;

subtest "toposort" => sub {
    is_deeply([toposort({})], []);
    is_deeply([toposort({a=>[]})], ["a"]);
    is_deeply([toposort({a=>["b"]})], ["a", "b"]);

    is_deeply([toposort({a=>["b"], b=>["c","d"], c=>[], d=>["c"]})],
              [qw/a b d c/]);
    is_deeply([toposort({a=>["b"], b=>["c","d"],        d=>["c"]})],
              [qw/a b d c/]);
    dies_ok { toposort({a=>["b"], b=>["c"], c=>["a"]}) };

    is_deeply([toposort({a=>["b"], b=>["c","d"], d=>["c"]},
                        [qw/b a/])],
              [qw/a b/]);
    is_deeply([toposort({a=>["b"], b=>["c","d"], d=>["c"]},
                        [qw/e a b a/])],
              [qw/a a b e/]);

};

subtest "is_cyclic" => sub {
    ok(!is_cyclic({}));
    ok(!is_cyclic({a=>[]}));
    ok(!is_cyclic({a=>["b"]}));

    ok(!is_cyclic({a=>["b"], b=>["c"]}));
    ok( is_cyclic({a=>["b"], b=>["a"]}));
    ok(!is_cyclic({a=>["b"], b=>["c"], c=>[]}));
    ok( is_cyclic({a=>["b"], b=>["a"], c=>["a"]}));
};

subtest "is_acyclic" => sub {
    ok( is_acyclic({}));
    ok( is_acyclic({a=>[]}));
    ok( is_acyclic({a=>["b"]}));

    ok( is_acyclic({a=>["b"], b=>["c"]}));
    ok(!is_acyclic({a=>["b"], b=>["a"]}));
    ok( is_acyclic({a=>["b"], b=>["c"], c=>[]}));
    ok(!is_acyclic({a=>["b"], b=>["a"], c=>["a"]}));
};

done_testing;
