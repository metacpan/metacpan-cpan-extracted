use Test2::V0 '!meta', '!pass';
use Scalar::Util qw/blessed/;

# Pure-function tests for DBIx::QuickORM::Util. No database needed.
# Assertions follow the documented behavior in the EXPORTS POD of
# DBIx::QuickORM::Util.

use DBIx::QuickORM::Util qw{
    column_key
    literal_write_value
    load_class
    find_modules
    merge_hash_of_objs
    clone_hash_of_objs
    parse_conflate_args
};

# A minimal object that records merge()/clone() calls, used to prove the
# blessed-value branches of merge_hash_of_objs / clone_hash_of_objs.
{
    package t::Obj;
    sub new   { my ($c, %a) = @_; bless {%a}, $c }
    sub merge { my ($self, $other, %p) = @_; t::Obj->new(%$self, merged => 1, merge_params => {%p}) }
    sub clone { my ($self, %p) = @_; t::Obj->new(%$self, cloned => 1, clone_params => {%p}) }
}

subtest exports => sub {
    can_ok(
        __PACKAGE__,
        [qw/column_key literal_write_value load_class find_modules merge_hash_of_objs clone_hash_of_objs parse_conflate_args/],
        "requested functions imported",
    );
};

subtest column_key => sub {
    # POD: sorts the names and joins with ', '; order-independent.
    is(column_key('c', 'a', 'b'), 'a, b, c', "sorts and joins with ', '");
    is(column_key('b', 'c', 'a'), column_key('a', 'b', 'c'), "same set, any order -> same key");
    is(column_key('x'), 'x', "single name");
    is(column_key(), '', "no names -> empty string");

    # Sorting is plain string sort.
    is(column_key('Z', 'a', 'B'), 'B, Z, a', "ASCII-betical sort");
};

subtest literal_write_value => sub {
    # POD: a scalar ref of SQL, or an arrayref led by a scalar ref of SQL plus
    # its bind values, is an intentional literal; everything else is data.
    ok(literal_write_value(\'NOW()'),        "scalar ref of SQL is a literal");
    ok(literal_write_value([\'col + ?', 1]), "arrayref led by a scalar ref is a literal");

    ok(!literal_write_value('NOW()'),          "plain string is data");
    ok(!literal_write_value(42),               "number is data");
    ok(!literal_write_value(undef),            "undef is data");
    ok(!literal_write_value({a => 1}),         "hashref is data");
    ok(!literal_write_value([1, 2]),           "plain arrayref is data");
    ok(!literal_write_value(bless {}, 't::Obj'), "blessed object is data");
};

subtest load_class => sub {
    is(load_class('DBIx::QuickORM::Affinity'), 'DBIx::QuickORM::Affinity', "loads a real class, returns its name");

    # With a prefix, the prefix is prepended.
    is(load_class('Affinity', 'DBIx::QuickORM'), 'DBIx::QuickORM::Affinity', "prefix prepended");

    # A leading '+' suppresses the prefix (absolute form).
    is(
        load_class('+DBIx::QuickORM::Affinity', 'DBIx::QuickORM'),
        'DBIx::QuickORM::Affinity',
        "leading '+' suppresses prefix, '+' stripped",
    );

    # Already-prefixed name is not double-prefixed.
    is(
        load_class('DBIx::QuickORM::Affinity', 'DBIx::QuickORM'),
        'DBIx::QuickORM::Affinity',
        "name already under prefix is left alone",
    );

    subtest failure => sub {
        my $ret = load_class('DBIx::QuickORM::NoSuchModuleZZZ');
        ok(!$ret, "returns false on load failure");
        like($@, qr/Can't locate/, "\$@ is set to the require error");
    };
};

subtest find_modules => sub {
    my @mods = find_modules('DBIx::QuickORM::Dialect');
    ok(scalar(@mods) > 0, "finds modules under a prefix");
    ok((grep { $_ eq 'DBIx::QuickORM::Dialect::SQLite' } @mods), "includes the SQLite dialect");
    ok((!grep { $_ !~ /^DBIx::QuickORM::Dialect\b/ } @mods), "all results are under the requested prefix");

    is([find_modules()], [], "no prefixes -> empty list");
};

subtest merge_hash_of_objs => sub {
    subtest empty_and_undef => sub {
        is(merge_hash_of_objs(),               {}, "no args -> empty hashref");
        is(merge_hash_of_objs(undef, undef),   {}, "undef inputs -> empty hashref");
        is(merge_hash_of_objs({a => 1}, undef), {a => 1}, "undef second hash -> first preserved");
    };

    subtest scalars => sub {
        my $out = merge_hash_of_objs({a => 1, b => 2}, {b => 3, c => 4});
        is($out, {a => 1, b => 3, c => 4}, "second hash's scalar wins on conflict");
    };

    subtest hashrefs_both => sub {
        # When both sides are plain hashrefs, they shallow-merge (second wins).
        my $out = merge_hash_of_objs({h => {x => 1, y => 2}}, {h => {y => 9, z => 3}});
        is($out->{h}, {x => 1, y => 9, z => 3}, "hashref values shallow-merged, second wins per key");
    };

    subtest arrayrefs_both => sub {
        # Documented: second array wins (copied, not aliased).
        my $second = [9, 8];
        my $out = merge_hash_of_objs({a => [1, 2]}, {a => $second});
        is($out->{a}, [9, 8], "second array wins");
        ref_is_not($out->{a}, $second, "result array is a copy, not the same ref");
    };

    subtest mixed_types_second_wins => sub {
        # Dispatch on the winner ($b). A mixed-type merge used to crash because
        # the branch was chosen by ref($a) while the value was built from $b.
        is(merge_hash_of_objs({k => [1, 2]},        {k => 'scalar'})->{k}, 'scalar',      "array then scalar: scalar wins");
        is(merge_hash_of_objs({k => 's'},           {k => [3, 4]})->{k},   [3, 4],         "scalar then array: array wins");
        is(merge_hash_of_objs({k => {x => 1}},      {k => 'plain'})->{k},  'plain',        "hash then scalar: scalar wins");
        is(merge_hash_of_objs({k => 'plain'},       {k => {y => 2}})->{k}, {y => 2},       "scalar then hash: hash wins");
    };

    subtest blessed_both => sub {
        # Both sides blessed -> a->merge(b, %params) is invoked.
        my $a = t::Obj->new(n => 1);
        my $b = t::Obj->new(n => 2);
        my $out = merge_hash_of_objs({o => $a}, {o => $b}, {flag => 5});
        is($out->{o}{merged}, 1, "merge() was called on the first object");
        is($out->{o}{merge_params}, {flag => 5}, "merge params passed through");
    };

    subtest blessed_one_side => sub {
        # Only one side present and it is blessed -> clone(%params).
        my $a = t::Obj->new(n => 1);
        my $out = merge_hash_of_objs({o => $a}, {}, {flag => 7});
        is($out->{o}{cloned}, 1, "single-side blessed value is cloned");
        is($out->{o}{clone_params}, {flag => 7}, "clone params passed through");
        ref_is_not($out->{o}, $a, "result is a fresh object, not the original");
    };

    subtest arrayref_one_side => sub {
        my $arr = [1, 2, 3];
        my $out = merge_hash_of_objs({a => $arr}, {});
        is($out->{a}, [1, 2, 3], "single-side arrayref copied through");
        ref_is_not($out->{a}, $arr, "arrayref copied, not aliased");
    };

    subtest hashref_one_side => sub {
        # Single-side hashref is deep-cloned via clone_hash_of_objs, preserving
        # plain scalar values as well as blessed/ARRAY/HASH values.
        my $a = t::Obj->new(n => 1);
        my $out = merge_hash_of_objs({h => {o => $a, s => 'scalar'}}, {});
        is($out->{h}{o}{cloned}, 1, "nested blessed value cloned");
        is($out->{h}{s}, 'scalar', "plain scalar inside a nested hash is preserved by deep clone");
    };

    subtest falsey_values => sub {
        my $out = merge_hash_of_objs({zero => 9, empty => 'x', undef_v => 1}, {zero => 0, empty => '', undef_v => undef});
        is($out, {zero => 0, empty => '', undef_v => undef}, "second hash wins even when its values are falsey");
    };
};

subtest clone_hash_of_objs => sub {
    subtest types => sub {
        my $obj = t::Obj->new(n => 1);
        my $arr = [1, 2];
        my $out = clone_hash_of_objs({o => $obj, a => $arr, h => {n => [5]}, s => 'plain'}, {p => 1});

        is($out->{o}{cloned}, 1, "blessed value cloned via clone()");
        is($out->{o}{clone_params}, {p => 1}, "clone params passed through");

        is($out->{a}, [1, 2], "arrayref copied");
        ref_is_not($out->{a}, $arr, "arrayref is a copy");

        is($out->{h}, {n => [5]}, "nested hashref deep-cloned");

        is($out->{s}, 'plain', "plain scalar values are preserved");
    };

    subtest falsey_values_preserved => sub {
        my $out = clone_hash_of_objs({zero => 0, empty => '', undef_v => undef, real => [1]});
        is($out, {zero => 0, empty => '', undef_v => undef, real => [1]}, "falsey-valued keys are preserved");
    };

    subtest empty => sub {
        is(clone_hash_of_objs({}), {}, "empty hash -> empty hashref");
    };

    subtest non_hash_croaks => sub {
        like(
            dies { clone_hash_of_objs([1, 2]) },
            qr/Need a hashref/,
            "non-hashref argument croaks",
        );
        like(
            dies { clone_hash_of_objs('scalar') },
            qr/Need a hashref/,
            "scalar argument croaks",
        );
    };
};

subtest parse_conflate_args => sub {
    subtest plain_kv => sub {
        my $p = parse_conflate_args(value => 42);
        is($p->{value}, 42, "value taken from kv");
        is($p->{class}, __PACKAGE__, "class defaults to caller when value is unblessed");
    };

    subtest proto_scalar_is_value => sub {
        # A scalar proto that is not a loaded class name is treated as a value.
        my $p = parse_conflate_args('hello');
        is($p->{value}, 'hello', "scalar proto -> value");
    };

    subtest proto_loaded_class => sub {
        # A scalar proto that IS a loaded class name is treated as class.
        my $p = parse_conflate_args('DBIx::QuickORM::Util', value => 9);
        is($p->{class}, 'DBIx::QuickORM::Util', "loaded-class proto -> class");
        is($p->{value}, 9, "value still taken from kv");
    };

    subtest proto_blessed_is_value => sub {
        my $obj = bless {}, 'DBIx::QuickORM::Util';
        my $p = parse_conflate_args($obj);
        ok(blessed($p->{value}), "blessed proto -> value");
        is($p->{class}, 'DBIx::QuickORM::Util', "class derived from blessed value");
    };

    subtest affinity_short_circuits => sub {
        # When affinity is already present, source/dialect/field are ignored.
        my $p = parse_conflate_args(value => 1, affinity => 'numeric', source => 'X', dialect => 'Y', field => 'z');
        is($p->{affinity}, 'numeric', "explicit affinity preserved without touching source");
    };

    subtest missing_value_croaks => sub {
        like(
            dies { parse_conflate_args() },
            qr/'value' argument must be present/,
            "no determinable value croaks",
        );
    };

    subtest type_instance_invocant => sub {
        # $Type->qorm_inflate($raw) and $instance->qorm_inflate($raw) reach
        # parse_conflate_args as (class-or-instance, $raw). Both must be parsed
        # as (class => invocant, value => $raw), not rejected.
        require DBIx::QuickORM::Type::JSON;

        my $by_class = parse_conflate_args('DBIx::QuickORM::Type::JSON', '{"x":1}');
        is($by_class->{class}, 'DBIx::QuickORM::Type::JSON', "class-name invocant kept as class");
        is($by_class->{value}, '{"x":1}',                    "the following argument is the value");

        my $inst = bless {}, 'DBIx::QuickORM::Type::JSON';
        my $by_inst = parse_conflate_args($inst, '{"y":2}');
        ref_is($by_inst->{class}, $inst, "blessed type instance kept as the class/invocant");
        is($by_inst->{value}, '{"y":2}', "and its following argument is the value");
    };
};

subtest merge_hash_of_objs_explicit_undef => sub {
    # Regression: an explicit undef in the second hash must win (second wins)
    # without dereferencing the undef, even when the first hash holds a ref.
    my $out;
    ok(
        lives { $out = merge_hash_of_objs({k => [1, 2], h => {a => 1}}, {k => undef, h => undef}) },
        "explicit-undef second value does not crash the ref branches",
    ) or note $@;
    ok(!defined $out->{k}, "array-vs-undef: second (undef) wins");
    ok(!defined $out->{h}, "hash-vs-undef: second (undef) wins");
};

done_testing;
