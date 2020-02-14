#!perl

use 5.010;
use strict;
use warnings;
#use Test::Exception;
use Test::More 0.98;

use Data::Transmute qw(transmute_data reverse_rules);
use Storable qw(dclone);

sub test_transmute_data {
    my %args = @_;

    subtest $args{name} => sub {
        my $data = $args{data};
        my $orig; $orig = ref($data) ? dclone($data) : $data;

        my $transmuted1;
        eval {
            $transmuted1 = transmute_data(
                (data => $data)                       x !!(exists $args{data}),
                (rules        => $args{rules})        x !!(exists $args{rules}),
                (rules_module => $args{rules_module}) x !!(exists $args{rules_module}),
            );
        };
        $transmuted1 = dclone $transmuted1 if ref $transmuted1;

        if ($args{dies}) {
            ok($@, "dies");
            return;
        } else {
            ok(!$@, "doesn't die") or diag $@;
        }

        if (exists $args{result}) {
            is_deeply($transmuted1, $args{result}, "result")
                or diag explain $transmuted1;
        }

        subtest reverse_rules => sub {
            my $revrules;
            eval {
                $revrules = reverse_rules(
                    (rules        => $args{rules})        x !!(exists $args{rules}),
                    (rules_module => $args{rules_module}) x !!(exists $args{rules_module}),
                );
            };

            if ($args{reverse_dies}) {
                ok($@, "reverse_rules dies");
                return;
            } else {
                ok(!$@, "reverse_rules doesn't die") or diag $@;
            }

            return unless $args{test_reverse} // 1;

            eval {
                transmute_data(
                    data => $data,
                    rules => $revrules,
                );
            };
            if ($@) {
                ok(0, "transmute step 2 (with reverse rules & data from step 1) dies: $@");
                return;
            }
            my $transmuted2 = dclone $data;

            is_deeply($transmuted2, $orig, "transmuted data becomes the original when applied with reverse rules")
                or diag explain({
                    orig => $orig,
                    rules => $args{rules},
                    rules_reverse => $revrules,
                    transmuted1 => $transmuted1,
                    transmuted2 => $transmuted2,
                });
        };
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
            [rename_hash_key => {from=>'foo', to=>'bar'}], #1
            [rename_hash_key => {from=>'bar', to=>'baz'}], #2
            [create_hash_key => {name=>'foo', value=>10}], #3
        ],
        result => {foo=>10, baz=>1},
    );
    test_transmute_data(
        name   => "rules_module",
        data   => {c=>3},
        rules_module => 'Example',
        result => {a=>1, b=>2, d=>3},
    );

    subtest "rule: create_hash_key" => sub {
        test_transmute_data(
            name   => "data not hash -> noop",
            data   => ["bar"],
            rules  => [ [create_hash_key=>{name=>'bar', value=>2}] ],
            result => ["bar"],
        );
        test_transmute_data(
            name   => "required argument: name",
            data   => {},
            rules  => [ [create_hash_key=>{value=>2}] ],
            dies   => 1,
        );
        test_transmute_data(
            name   => "required argument: value|value_code",
            data   => {},
            rules  => [ [create_hash_key=>{name=>'bar'}] ],
            dies   => 1,
        );
        test_transmute_data(
            name   => "create bar",
            data   => {foo=>1},
            rules  => [ [create_hash_key=>{name=>'bar', value=>2}] ],
            result => {foo=>1, bar=>2},
        );
        test_transmute_data(
            name   => "opt:transmute_object=1 (the default)",
            data   => bless({foo=>1}, "Class"),
            rules  => [ [create_hash_key=>{name=>'bar', value=>2}] ],
            result => bless({foo=>1, bar=>2}, "Class"),
        );
        test_transmute_data(
            name   => "opt:transmute_object=0",
            data   => bless({foo=>1}, "Class"),
            rules  => [ [create_hash_key=>{name=>'bar', value=>2, transmute_object=>0}] ],
            result => bless({foo=>1}, "Class"),
        );
        test_transmute_data(
            name   => "create bar (with value_code)",
            data   => {foo=>1},
            rules  => [ [create_hash_key=>{name=>'bar', value_code=>sub {1+1} }] ],
            result => {foo=>1, bar=>2},
            reverse_dies => 1,
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
            reverse_dies => 1,
        );
        test_transmute_data(
            name   => "foo already exists + replace -> replaced",
            data   => {foo=>1},
            rules  => [ [create_hash_key=>{name=>'foo', value=>2, replace=>1}] ],
            result => {foo=>2},
            reverse_dies => 1,
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
            name   => "required argument: from",
            data   => {foo=>1},
            rules  => [ [rename_hash_key=>{to=>'bar'}] ],
            dies   => 1,
        );
        test_transmute_data(
            name   => "required argument: to",
            data   => {foo=>1},
            rules  => [ [rename_hash_key=>{from=>'foo'}] ],
            dies   => 1,
        );
        test_transmute_data(
            name   => "rename foo",
            data   => {foo=>1},
            rules  => [ [rename_hash_key=>{from=>'foo', to=>'bar'}] ],
            result => {bar=>1},
        );
        test_transmute_data(
            name   => "opt:transmute_object=1 (the default)",
            data   => bless({foo=>1}, "Class"),
            rules  => [ [rename_hash_key=>{from=>'foo', to=>'bar'}] ],
            result => bless({bar=>1}, "Class"),
        );
        #test_transmute_data(
        #    name   => "opt:transmute_object=0",
        #    data   => bless({foo=>1}, "Class"),
        #    rules  => [ [rename_hash_key=>{from=>'foo', to=>'bar', transmute_object=>0}] ],
        #    result => bless({foo=>1}, "Class"),
        #);
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
            reverse_dies => 1,
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
            reverse_dies => 1,
        );
        test_transmute_data(
            name   => "bar exists + replace -> replaced",
            data   => {foo=>1, bar=>2},
            rules  => [ [rename_hash_key=>{from=>'foo', to=>'bar', replace=>1}] ],
            result => {bar=>1},
            reverse_dies => 1,
        );
    };

    subtest "rule: modify_hash_value" => sub {
        test_transmute_data(
            name   => "data not hash -> noop",
            data   => ["foo"],
            rules  => [ [modify_hash_value=>{name=>"a", from=>1, to=>2}] ],
            result => ["foo"],
        );
        test_transmute_data(
            name   => "required argument: name",
            data   => {a=>1},
            rules  => [ [modify_hash_value=>{from=>1, to=>2}] ],
            dies   => 1,
        );
        test_transmute_data(
            name   => "key (name) does not exist -> dies",
            data   => {b=>1},
            rules  => [ [modify_hash_value=>{name=>"a", from=>1, to=>2}] ],
            dies   => 1,
        );
        test_transmute_data(
            name   => "original value does not equal 'from' -> dies",
            data   => {a=>3},
            rules  => [ [modify_hash_value=>{name=>"a", from=>1, to=>2}] ],
            dies   => 1,
        );
        test_transmute_data(
            name   => "modify a",
            data   => {a=>1},
            rules  => [ [modify_hash_value=>{name=>"a", from=>1, to=>2}] ],
            result => {a=>2},
        );
        test_transmute_data(
            name   => "opt:transmute_object=1 (the default)",
            data   => bless({a=>1}, "Class"),
            rules  => [ [modify_hash_value=>{name=>"a", from=>1, to=>2}] ],
            result => bless({a=>2}, "Class"),
        );
        test_transmute_data(
            name   => "opt:transmute_object=0",
            data   => bless({a=>1}, "Class"),
            rules  => [ [modify_hash_value=>{name=>"a", from=>1, to=>2, transmute_object=>0}] ],
            result => bless({a=>1}, "Class"),
        );
        test_transmute_data(
            name   => "modify a (with to_code)",
            data   => {a=>1},
            rules  => [ [modify_hash_value=>{name=>"a", from=>1, to_code=>sub {1+1}}] ],
            result => {a=>2},
            reverse_dies => 1,
        );
        test_transmute_data(
            name   => "from is optional",
            data   => {a=>3},
            rules  => [ [modify_hash_value=>{name=>"a", to=>2}] ],
            result => {a=>2},
            reverse_dies => 1,
        );
    };

    subtest "rule: delete_hash_key" => sub {
        test_transmute_data(
            name   => "data not hash -> noop",
            data   => ["foo"],
            rules  => [ [delete_hash_key=>{name=>'foo'}] ],
            result => ["foo"],
            reverse_dies => 1,
        );
        test_transmute_data(
            name   => "required argument: name",
            data   => {foo=>1},
            rules  => [ [delete_hash_key=>{}] ],
            dies   => 1,
        );
        test_transmute_data(
            name   => "delete foo",
            data   => {foo=>1},
            rules  => [ [delete_hash_key=>{name=>'foo'}] ],
            result => {},
            reverse_dies => 1,
        );
        test_transmute_data(
            name   => "opt:transmute_object=1 (the default)",
            data   => bless({foo=>1}, "Class"),
            rules  => [ [delete_hash_key=>{name=>'foo'}] ],
            result => bless({}, "Class"),
            reverse_dies => 1,
        );
        test_transmute_data(
            name   => "opt:transmute_object=0",
            data   => bless({foo=>1}, "Class"),
            rules  => [ [delete_hash_key=>{name=>'foo', transmute_object=>0}] ],
            result => bless({foo=>1}, "Class"),
            reverse_dies => 1,
        );
        test_transmute_data(
            name   => "foo doesn't exist -> noop",
            data   => {bar=>1},
            rules  => [ [delete_hash_key=>{name=>'foo'}] ],
            result => {bar=>1},
            reverse_dies => 1,
        );
    };

    subtest "rule: transmute_array_elems" => sub {
        test_transmute_data(
            name   => "data not array -> noop",
            data   => {k1=>{a=>1}},
            rules  => [ [transmute_array_elems=>{rules=>[ [create_hash_key=>{name=>'b', value=>2}] ]}] ],
            result => {k1=>{a=>1}},
        );
        test_transmute_data(
            name   => "required argument: rules/rules_module",
            data   => [],
            rules  => [ [transmute_array_elems=>{}] ],
            dies   => 1,
        );
        test_transmute_data(
            name   => "basic",
            data   => [{a=>1}, {a=>2}, {}],
            rules  => [ [transmute_array_elems=>{rules=>[ [create_hash_key=>{name=>'b', value=>2}] ]}] ],
            result => [{a=>1,b=>2}, {a=>2,b=>2}, {b=>2}],
        );
        test_transmute_data(
            name   => "opt:transmute_object=1 (the default)",
            data   => bless([{a=>1}, {a=>2}, {}], "Class"),
            rules  => [ [transmute_array_elems=>{rules=>[ [create_hash_key=>{name=>'b', value=>2}] ]}] ],
            result => bless([{a=>1,b=>2}, {a=>2,b=>2}, {b=>2}], "Class"),
        );
        test_transmute_data(
            name   => "opt:transmute_object=0",
            data   => bless([{a=>1}, {a=>2}, {}], "Class"),
            rules  => [ [transmute_array_elems=>{rules=>[ [create_hash_key=>{name=>'b', value=>2}] ], transmute_object=>0}] ],
            result => bless([{a=>1}, {a=>2}, {}], "Class"),
        );
        test_transmute_data(
            name   => "rules_module",
            data   => [{c=>3}],
            rules  => [ [transmute_array_elems=>{rules_module=>'Example'}] ],
            result => [{a=>1, b=>2, d=>3}],
        );
        test_transmute_data(
            name   => "arg:index_is",
            data   => [{a=>1}, {a=>2}, {a=>3}],
            rules  => [ [transmute_array_elems=>{index_is=>1, rules=>[ [create_hash_key=>{name=>'b', value=>2}] ]}] ],
            result => [{a=>1}, {a=>2,b=>2}, {a=>3}],
        );
        test_transmute_data(
            name   => "arg:index_in",
            data   => [{a=>1}, {a=>2}, {a=>3}],
            rules  => [ [transmute_array_elems=>{index_in=>[0,1], rules=>[ [create_hash_key=>{name=>'b', value=>2}] ]}] ],
            result => [{a=>1,b=>2}, {a=>2,b=>2}, {a=>3}],
        );
        test_transmute_data(
            name   => "arg:index_match",
            data   => [{a=>1}, {a=>2}, {a=>3}],
            rules  => [ [transmute_array_elems=>{index_match=>qr/[01]/, rules=>[ [create_hash_key=>{name=>'b', value=>2}] ]}] ],
            result => [{a=>1,b=>2}, {a=>2,b=>2}, {a=>3}],
        );
        test_transmute_data(
            name   => "arg:index_filter",
            data   => [{a=>1}, {a=>2}, {a=>3}],
            rules  => [ [transmute_array_elems=>{index_filter=>sub{ my %args=@_; $args{index} <= 1 }, rules=>[ [create_hash_key=>{name=>'b', value=>2}] ]}] ],
            result => [{a=>1,b=>2}, {a=>2,b=>2}, {a=>3}],
        );
    };

    subtest "rule: transmute_hash_values" => sub {
        test_transmute_data(
            name   => "data not hash -> noop",
            data   => [{a=>1}],
            rules  => [ [transmute_hash_values=>{rules=>[ [create_hash_key=>{name=>'b',value=>2}] ]}] ],
            result => [{a=>1}],
        );
        test_transmute_data(
            name   => "required argument: rules/rules_module",
            data   => {},
            rules  => [ [transmute_hash_values=>{}] ],
            dies   => 1,
        );
        test_transmute_data(
            name   => "basic",
            data   => {k1=>{a=>1}, k2=>{a=>2}, k3=>{a=>3}},
            rules  => [ [transmute_hash_values=>{rules=>[ [create_hash_key=>{name=>'b',value=>2}] ]}] ],
            result => {k1=>{a=>1,b=>2}, k2=>{a=>2,b=>2}, k3=>{a=>3,b=>2}},
        );
        test_transmute_data(
            name   => "opt:transmute_object=1 (the default)",
            data   => bless({k1=>{a=>1}, k2=>{a=>2}, k3=>{a=>3}}, "Class"),
            rules  => [ [transmute_hash_values=>{rules=>[ [create_hash_key=>{name=>'b',value=>2}] ]}] ],
            result => bless({k1=>{a=>1,b=>2}, k2=>{a=>2,b=>2}, k3=>{a=>3,b=>2}}, "Class"),
        );
        test_transmute_data(
            name   => "opt:transmute_object=0",
            data   => bless({k1=>{a=>1}, k2=>{a=>2}, k3=>{a=>3}}, "Class"),
            rules  => [ [transmute_hash_values=>{rules=>[ [create_hash_key=>{name=>'b',value=>2}] ], transmute_object=>0}] ],
            result => bless({k1=>{a=>1}, k2=>{a=>2}, k3=>{a=>3}}, "Class"),
        );
        test_transmute_data(
            name   => "rules_module",
            data   => {k1=>{c=>3}},
            rules  => [ [transmute_hash_values=>{rules_module=>'Example'}] ],
            result => {k1=>{a=>1, b=>2, d=>3}},
        );
        test_transmute_data(
            name   => "arg:key_is",
            data   => {k1=>{a=>1}, k2=>{a=>2}, k3=>{a=>3}},
            rules  => [ [transmute_hash_values=>{key_is=>'k2', rules=>[ [create_hash_key=>{name=>'b',value=>2}] ]}] ],
            result => {k1=>{a=>1}, k2=>{a=>2,b=>2}, k3=>{a=>3}},
        );
        test_transmute_data(
            name   => "arg:key_in",
            data   => {k1=>{a=>1}, k2=>{a=>2}, k3=>{a=>3}},
            rules  => [ [transmute_hash_values=>{key_in=>['k1','k2'], rules=>[ [create_hash_key=>{name=>'b',value=>2}] ]}] ],
            result => {k1=>{a=>1,b=>2}, k2=>{a=>2,b=>2}, k3=>{a=>3}},
        );
        test_transmute_data(
            name   => "arg:key_match",
            data   => {k1=>{a=>1}, k2=>{a=>2}, k3=>{a=>3}},
            rules  => [ [transmute_hash_values=>{key_match=>qr/[12]/, rules=>[ [create_hash_key=>{name=>'b',value=>2}] ]}] ],
            result => {k1=>{a=>1,b=>2}, k2=>{a=>2,b=>2}, k3=>{a=>3}},
        );
        test_transmute_data(
            name   => "arg:key_filter",
            data   => {k1=>{a=>1}, k2=>{a=>2}, k3=>{a=>3}},
            rules  => [ [transmute_hash_values=>{key_filter=>sub{my %args=@_; $args{key} =~ /[12]/}, rules=>[ [create_hash_key=>{name=>'b',value=>2}] ]}] ],
            result => {k1=>{a=>1,b=>2}, k2=>{a=>2,b=>2}, k3=>{a=>3}},
        );
    };

    subtest "rule: transmute_nodes" => sub {

        my $tree = {id=>1, parent=>undef, children=>[ {id=>2, children=>[]}, {id=>3, children=>[ {id=>4, children=>[] } ]} ]};
        $tree->{children}[0]{parent} = $tree;
        $tree->{children}[1]{parent} = $tree;
        $tree->{children}[1]{children}[0]{parent} = $tree->{children}[1];

        my $transmuted_tree = {id=>1, parent=>"foo", children=>[ {id=>2, children=>[], parent=>"foo"}, {id=>3, children=>[ {id=>4, children=>[], parent=>"foo" } ], parent=>"foo"} ]};

        test_transmute_data(
            name   => "tree",
            data   => $tree,
            rules  => [ [transmute_nodes=>{rules=>[ [create_hash_key=>{name=>'parent', replace=>1, value=>'foo'}] ]}] ],
            result => $transmuted_tree,
            reverse_dies => 1,
        );

        test_transmute_data(
            name   => "opt:recurse_object=0 (the default)",
            data   => bless([{}], "Class"),
            rules  => [ [transmute_nodes=>{rules=>[ [create_hash_key=>{name=>'a', value=>1}] ]}] ],
            result => bless([{}], "Class"),
            reverse_dies => 1,
        );
        test_transmute_data(
            name   => "opt:recurse_object=1",
            data   => bless([{}], "Class"),
            rules  => [ [transmute_nodes=>{rules=>[ [create_hash_key=>{name=>'a', value=>1}] ], recurse_object=>1}] ],
            result => bless([{a=>1}], "Class"),
            reverse_dies => 1,
        );
    };

};

DONE_TESTING:
done_testing;
