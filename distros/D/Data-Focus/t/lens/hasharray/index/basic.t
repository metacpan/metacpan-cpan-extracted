use strict;
use warnings FATAL => "all";
use Test::More;
use Scalar::Util qw(refaddr);
use Data::Focus qw(focus);
use Data::Focus::Lens::HashArray::Index;
use lib "t";
use testlib::SampleObject;
use testlib::Identity qw(identical);

sub params {
    my ($index, $immutable, $allow_blessed) = @_;
    return (index => $index,
            immutable => $immutable,
            allow_blessed => $allow_blessed);
}

sub lens {
    return Data::Focus::Lens::HashArray::Index->new(@_);
}

sub make_label {
    my ($target, $key, $immutable, $allow_blessed) = @_;
    my $imm_str = $immutable ? "immutable" : "mutable";
    $allow_blessed ||= 0;
    return "$target, " . join(":", ref($key) ? @$key : $key) . " ($imm_str, allow_blessed=$allow_blessed)";
}

sub eval_if_code {
    my ($maybe_code, @params) = @_;
    return ref($maybe_code) eq "CODE" ? $maybe_code->(@params) : $maybe_code;
}

my %targets = (
    scalar => sub { "aaa" },
    hash => sub {
        +{
            foo => "bar",
            undef => undef,
            aa => [0,1,2],
        }
    },
    array => sub {
        +[20, undef, "AAA", bb => {hoge => "HOGE"}]
    },
    scalar_ref => sub {
        my $s = 999;
        return \$s;
    },
    obj => sub {
        my $d = testlib::SampleObject->new;
        $d->set(foo => "bar");
        return $d;
    },
    undef => sub { undef },
);

note("--- get() / list()");

foreach my $case (
    {target => "hash", key => "foo", exp_g => "bar", exp_l => ["bar"]},
    {target => "hash", key => "undef", exp_g => undef, exp_l => [undef]},
    {target => "hash", key => "non-existent", exp_g => undef, exp_l => [undef]},
    {target => "hash", key => ["undef", "foo", "non-existent"], exp_g => undef, exp_l => [undef, "bar", undef]},
    {target => "hash", key => ["foo", "foo", "foo", "foo"], exp_g => "bar", exp_l => ["bar", "bar", "bar", "bar"]},
    {target => "array", key => 0, exp_g => 20, exp_l => [20]},
    {target => "array", key => 1, exp_g => undef, exp_l => [undef]},
    {target => "array", key => 2.4, exp_g => "AAA", exp_l => ["AAA"]},
    {target => "array", key => -3, exp_g => "AAA", exp_l => ["AAA"]},
    {target => "array", key => 20, exp_g => undef, exp_l => [undef]},
    {target => "array", key => [3, 10, 0], exp_g => "bb", exp_l => ["bb", undef, 20]},
    {target => "array", key => [2,2,2,2], exp_g => "AAA", exp_l => [("AAA") x 4]},
    {target => "scalar", key => "aaa", exp_g => undef, exp_l => []},
    {target => "scalar_ref", key => "aaa", exp_g => undef, exp_l => []},
    {target => "undef", key => "str", exp_g => undef, exp_l => [undef]},
    {target => "undef", key => 10, exp_g => undef, exp_l => [undef]},
    {target => "undef", key => ["key", 10, 11], exp_g => undef, exp_l => [undef, undef, undef]},
    {target => "obj", key => "aaa",
     exp_g => undef, exp_l => sub { my (%params) = @_; $params{allow_blessed} ? [undef] : [] }},
    {target => "obj", key => "foo",
     exp_g => sub { my (%params) = @_; $params{allow_blessed} ? "bar" : undef },
     exp_l => sub { my (%params) = @_; $params{allow_blessed} ? ["bar"] : [] }},
) {
    foreach my $allow_blessed (0, 1) {
        foreach my $immutable (0, 1) {
            my $label = make_label($case->{target}, $case->{key}, $immutable, $allow_blessed);
            subtest $label => sub {
                my $gen = $targets{$case->{target}};
                my $target = $gen->();
                my @params = params($case->{key}, $immutable, $allow_blessed);
                my $lens = lens(@params);
                my $got_g = focus($target)->get($lens);
                my $exp_g = eval_if_code($case->{exp_g}, @params);
                is_deeply $got_g, $exp_g, "get()";
                my @got_l = focus($target)->list($lens);
                my $exp_l = eval_if_code($case->{exp_l}, @params);
                is_deeply \@got_l, $exp_l, "list()";
                is_deeply $target, $gen->(), "target is not modified by getters";
            };
        }
    }
}

note("--- set()");

foreach my $case (
    {target => "hash", key => "aa", val => 10, exp => {foo => "bar", undef => undef, aa => 10}},
    {target => "hash", key => "non-existent", val => "aaa",
     exp => {foo => "bar", undef => undef, aa => [0,1,2], "non-existent" => "aaa"}},
    {target => "hash", key => [0, 5, "aa"], val => 18,
     exp => {foo => "bar", undef => undef, aa => 18, 0 => 18, 5 => 18}},
    {target => "hash", key => ["foo", "foo", "foo"], val => 0,
     exp => {foo => 0, undef => undef, aa => [0,1,2]}},
    {target => "array", key => 4, val => [],
     exp => [20, undef, "AAA", "bb", []]},
    {target => "array", key => 6, val => "foo",
     exp => [20, undef, "AAA", "bb", {hoge => "HOGE"}, undef, "foo"]},
    {target => "array", key => -3, val => "aaa",
     exp => [20, undef, "aaa", "bb", {hoge => "HOGE"}]},
    {target => "array", key => [0, 2, 4], val => 80,
     exp => [80, undef, 80, "bb", 80]},
    {target => "array", key => [3, 7, 5], val => "xx",
     exp => [20, undef, "AAA", "xx", {hoge => "HOGE"}, "xx", undef, "xx"]},
    {target => "array", key => [-2, -1, -2, -1], val => "xx",
     exp => [20, undef, "AAA", "xx", "xx"]},

    ## negative index and positive out-of-range index. It expands the array for each key.
    {target => "array", key => [7, -2, 10, -2], val => "xx",
     exp => [20, undef, "AAA", "bb", {hoge => "HOGE"}, undef, "xx", "xx", undef, "xx", "xx"]},

    {target => "scalar", key => "hoge", val => "XXX", exp => "aaa"},
    {target => "scalar_ref", key => "hoge", val => "XXX", exp => \(999), exp_same_instance => 1},
    
    {target => "obj", key => "hoge", val => "XXX",
     exp => sub {
         my (%params) = @_;
         if($params{allow_blessed}) {
             if($params{immutable}) {
                 return {foo => "bar", hoge => "XXX"};
             }else {
                 my $exp = $targets{obj}->();
                 $exp->set(hoge => "XXX");
                 return $exp;
             }
         }else {
             return $targets{obj}->();
         }
     },
     exp_same_instance => sub {
         my (%params) = @_;
         return !$params{allow_blessed} || !$params{immutable};
     }},
) {
    foreach my $allow_blessed (0, 1) {
        foreach my $immutable (0, 1) {
            my $label = make_label($case->{target}, $case->{key}, $immutable, $allow_blessed);
            subtest $label => sub {
                my $gen = $targets{$case->{target}};
                my $target = $gen->();
                my @params = params($case->{key}, $immutable, $allow_blessed);
                my $lens = lens(@params);
                my $got = focus($target)->set($lens, $case->{val});
                my $exp = eval_if_code($case->{exp}, @params);
                is_deeply $got, $exp, "set()";
                if(ref($target)) {
                    if(!defined($case->{exp_same_instance})) {
                        $case->{exp_same_instance} = sub { my (%params) = @_; return !$params{immutable} };
                    }
                    my $exp_same_instance = eval_if_code($case->{exp_same_instance}, @params);
                    if($exp_same_instance) {
                        identical $got, $target, "destructive update (or not modified at all)";
                    }else {
                        isnt refaddr($got), refaddr($target), "non-destructive update";
                        is_deeply $target, $gen->(), "target is preserved";
                    }
                }
            };
        }
    }
}

note("--- set() with autovivification");

foreach my $case (
    {key => "str", val => 10, exp => {str => 10}},
    {key => 3, val => 5, exp => [undef, undef, undef, 5]},
    {key => ["a", 4, "b"], val => "x", exp => {a => "x", 4 => "x", b => "x"}},
    {key => -3, val => "x", exp => {-3 => "x"}},
    {key => [4, 3, 4, 0], val => "x", exp => ["x", undef, undef, "x", "x"]},
    {key => "+1", val => "x", exp => {"+1" => "x"}},
) {
    foreach my $immutable (0, 1) {
        my $label = make_label("undef", $case->{key}, $immutable);
        subtest $label => sub {
            my $lens = lens(params($case->{key}, $immutable));
            my $got = focus(undef)->set($lens, $case->{val});
            is_deeply $got, $case->{exp};
        };
    }
}

subtest "by default, immutable=0, allow_blessed=0", sub {
    my $lens = Data::Focus::Lens::HashArray::Index->new(index => "foo");
    my $hash_target = $targets{hash}->();
    focus($hash_target)->set($lens, "HOGE");
    is $hash_target->{foo}, "HOGE", "destructive set()";
    my $obj_target = $targets{obj}->();
    is focus($obj_target)->get($lens), undef, "not focus into blessed objects";
};

done_testing;
