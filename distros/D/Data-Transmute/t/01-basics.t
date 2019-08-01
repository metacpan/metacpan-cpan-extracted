#!perl

use 5.010;
use strict;
use warnings;
#use Test::Exception;
use Test::More 0.98;

use Data::Transmute qw(transmute_data reverse_rules);

sub test_transmute_data {
    my %args = @_;

    my $res;
    subtest $args{name} => sub {
        eval {
            $res = transmute_data(
                (data => $args{data})   x !!(exists $args{data}),
                (rules => $args{rules}) x !!(exists $args{rules}),
            );
        };

        if ($args{dies}) {
            ok($@, "dies");
            return;
        } else {
            ok(!$@, "doesn't die") or diag $@;
        }

        if (exists $args{result}) {
            is_deeply($res, $args{result}, "result")
                or diag explain $res;
        }
    };
}

subtest transmute_data => sub {
    test_transmute_data(
        name   => "missing data -> dies",
        rules  => [],
        dies   => 1,
    );
    test_transmute_data(
        name   => "missing rules -> dies",
        data   => {},
        dies   => 1,
    );
    test_transmute_data(
        name   => "unknown rule -> dies",
        data   => {},
        rules  => [ ['foo'=>{}] ],
        dies   => 1,
    );
    test_transmute_data(
        name   => "empty rules -> noop",
        data   => {foo=>1},
        rules  => [],
        result => {foo=>1},
    );
    test_transmute_data(
        name   => "composite rules",
        data   => {foo=>1},
        rules  => [
            [rename_hash_key => {from=>'foo', to=>'bar'}],
            [rename_hash_key => {from=>'bar', to=>'baz'}],
            [create_hash_key => {name=>'foo', value=>10}],
        ],
        result => {foo=>10, baz=>1},
    );

    subtest "rule: create_hash_key" => sub {
        test_transmute_data(
            name   => "data not hash -> noop",
            data   => ["bar"],
            rules  => [ [create_hash_key=>{name=>'bar', value=>2}] ],
            result => ["bar"],
        );
        test_transmute_data(
            name   => "create bar",
            data   => {foo=>1},
            rules  => [ [create_hash_key=>{name=>'bar', value=>2}] ],
            result => {foo=>1, bar=>2},
        );
        test_transmute_data(
            name   => "foo already exists -> dies",
            data   => {foo=>1},
            rules  => [ [create_hash_key=>{name=>'foo', value=>2}] ],
            dies   => 1,
        );
        test_transmute_data(
            name   => "foo already exists + ignore -> noop",
            data   => {foo=>1},
            rules  => [ [create_hash_key=>{name=>'foo', value=>2, ignore=>1}] ],
            result => {foo=>1},
        );
        test_transmute_data(
            name   => "foo already exists + replace -> replaced",
            data   => {foo=>1},
            rules  => [ [create_hash_key=>{name=>'foo', value=>2, replace=>1}] ],
            result => {foo=>2},
        );
        # XXX test conflict between ignore & replace
    };

    subtest "rule: rename_hash_key" => sub {
        test_transmute_data(
            name   => "data not hash -> noop",
            data   => ["foo"],
            rules  => [ [rename_hash_key=>{from=>'foo', to=>'bar'}] ],
            result => ["foo"],
        );
        test_transmute_data(
            name   => "rename foo",
            data   => {foo=>1},
            rules  => [ [rename_hash_key=>{from=>'foo', to=>'bar'}] ],
            result => {bar=>1},
        );
        test_transmute_data(
            name   => "foo doesn't exist -> dies",
            data   => {baz=>1},
            rules  => [ [rename_hash_key=>{from=>'foo', to=>'bar'}] ],
            dies   => 1,
        );
        test_transmute_data(
            name   => "foo doesn't exist + ignore_missing_from -> noop",
            data   => {baz=>1},
            rules  => [ [rename_hash_key=>{from=>'foo', to=>'bar', ignore_missing_from=>1}] ],
            result => {baz=>1},
        );
        test_transmute_data(
            name   => "bar exists -> dies",
            data   => {foo=>1, bar=>1},
            rules  => [ [rename_hash_key=>{from=>'foo', to=>'bar'}] ],
            dies   => 1,
        );
        test_transmute_data(
            name   => "bar exists + ignore_existing_target -> noop",
            data   => {foo=>1, bar=>2},
            rules  => [ [rename_hash_key=>{from=>'foo', to=>'bar', ignore_existing_target=>1}] ],
            result => {foo=>1, bar=>2},
        );
        test_transmute_data(
            name   => "bar exists + replace -> replaced",
            data   => {foo=>1, bar=>2},
            rules  => [ [rename_hash_key=>{from=>'foo', to=>'bar', replace=>1}] ],
            result => {bar=>1},
        );
    };

    subtest "rule: delete_hash_key" => sub {
        test_transmute_data(
            name   => "data not hash -> noop",
            data   => ["foo"],
            rules  => [ [delete_hash_key=>{name=>'foo'}] ],
            result => ["foo"],
        );
        test_transmute_data(
            name   => "delete foo",
            data   => {foo=>1},
            rules  => [ [delete_hash_key=>{name=>'foo'}] ],
            result => {},
        );
        test_transmute_data(
            name   => "foo doesn't exist -> noop",
            data   => {bar=>1},
            rules  => [ [delete_hash_key=>{name=>'foo'}] ],
            result => {bar=>1},
        );
    };

    subtest "rule: transmute_array_elems" => sub {
        test_transmute_data(
            name   => "data not array -> noop",
            data   => {foo=>{bar=>1}},
            rules  => [ [transmute_array_elems=>{rules=>[ [delete_hash_key=>{name=>'bar'}] ]}] ],
            result => {foo=>{bar=>1}},
        );
        test_transmute_data(
            name   => "basic",
            data   => [{bar=>1}, {bar=>2}, {baz=>3}],
            rules  => [ [transmute_array_elems=>{rules=>[ [delete_hash_key=>{name=>'bar'}] ]}] ],
            result => [{}, {}, {baz=>3}],
        );
    };

    subtest "rule: transmute_hash_values" => sub {
        test_transmute_data(
            name   => "data not hash -> noop",
            data   => [{bar=>1}],
            rules  => [ [transmute_hash_values=>{rules=>[ [delete_hash_key=>{name=>'bar'}] ]}] ],
            result => [{bar=>1}],
        );
        test_transmute_data(
            name   => "basic",
            data   => {k1=>{bar=>1}, k2=>{bar=>2}, k3=>{baz=>3}},
            rules  => [ [transmute_hash_values=>{rules=>[ [delete_hash_key=>{name=>'bar'}] ]}] ],
            result => {k1=>{}, k2=>{}, k3=>{baz=>3}},
        );
    };
};

subtest reverse_rules => sub {
    is_deeply(
        reverse_rules(rules => [ [create_hash_key=>{name=>"foo"}], [rename_hash_key=>{from=>"bar", to=>"baz"}] ] ),
        [ [rename_hash_key=>{from=>"baz", to=>"bar"}], [delete_hash_key=>{name=>"foo"}] ],
    );
};

DONE_TESTING:
done_testing;
