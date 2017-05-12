use strict;
use warnings FATAL => "all";
use Test::More;
use Data::Focus qw(focus);
use Data::Focus::LensTester;
use Data::Focus::Lens::HashArray::Index;
use lib "t";
use testlib::SampleObject;
use testlib::Identity qw(check_identity);

sub make_label {
    my ($target, $key, $immutable, $allow_blessed) = @_;
    my $keys = ref($key) ? join(":", @$key) : $key;
    my $imm_str = $immutable ? "immutable" : "mutable";
    $allow_blessed ||= 0;
    return "$target, $keys ($imm_str, allow_blessed=$allow_blessed)";
}

my $tester = Data::Focus::LensTester->new(
    test_whole => sub {
        is_deeply(@_);
    },
    test_part  => sub { is_deeply(@_) },
    parts => [
        undef, 10, "aaa", \("bbb"),
        [10, 20], {}, {foo => "bar"},
        {hoge => [8, 9], buzz => {a => "A"}},
    ]
);

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
        testlib::SampleObject->new;
    },
    undef => sub { undef },
);

foreach my $case (
    {target => "scalar", key => "hoge", exp_focal_points => 0},
    {target => "hash", key => "foo", exp_focal_points => 1},
    {target => "hash", key => "undef", exp_focal_points => 1},
    {target => "hash", key => "aa", exp_focal_points => 1},
    {target => "hash", key => ["foo", "undef", "non-existent"], exp_focal_points => 3},
    {target => "hash", key => ["foo", "foo", "foo", "foo"], exp_focal_points => 4},
    {target => "array", key => 0, exp_focal_points => 1},
    {target => "array", key => 1, exp_focal_points => 1},
    {target => "array", key => 2.5, exp_focal_points => 1}, ## cast to int. without warning.
    {target => "array", key => -3, exp_focal_points => 1}, ## in-range negative index. writable.
    {target => "array", key => [1, 10, 0], exp_focal_points => 3},
    {target => "array", key => [2,2,2,2], exp_focal_points => 4},
    {target => "scalar_ref", key => "foo", exp_focal_points => 0},
    {target => "obj", key => "bar", exp_focal_points => 0, test_if => sub {
        my (%params) =  @_;
        return !$params{allow_blessed};
    }},
) {
    foreach my $allow_blessed (0, 1) {
        foreach my $immutable (0, 1) {
            my @params = (index => $case->{key}, immutable => $immutable, allow_blessed => $allow_blessed);
            next if $case->{test_if} && !$case->{test_if}->(@params);
            
            my $lens = Data::Focus::Lens::HashArray::Index->new(@params);
            my $label = make_label($case->{target}, $case->{key}, $immutable, $allow_blessed);
            subtest $label => sub {
                $tester->test_lens_laws(
                    lens => $lens, target => $targets{$case->{target}},
                    exp_focal_points => $case->{exp_focal_points},
                );
            };
            subtest "$label, set() mutation" => sub {
                foreach my $part ($tester->parts) {
                    my $target = $targets{$case->{target}}->();
                    my $result = focus($target)->set($lens, $part);
                    check_identity($result, $target, ($case->{exp_focal_points} == 0 ? 1 : !$immutable));
                }
            };
        }
    }
}

note("--- cases where get-set law breaks because of autovivification and auto-expansion");
foreach my $case (
    {target => "undef", key => "str", exp_focal_points => 1},
    {target => "undef", key => 5, exp_focal_points => 1},
    {target => "undef", key => ["foo", "bar"], exp_focal_points => 2},
    {target => "undef", key => [0, 3, 7], exp_focal_points => 3},
    {target => "undef", key => ["a", "a", "a"], exp_focal_points => 3},
    {target => "undef", key => [1,1,1], exp_focal_points => 3},
    {target => "hash", key => "non-existent", exp_focal_points => 1},
    {target => "array", key => 20, exp_focal_points => 1}, ## out-of-range positive index. writable.
    {target => "obj", key => "bar", exp_focal_points => 1, test_if => sub {
        my (%params) =  @_;
        return $params{allow_blessed};
    }}
) {
    foreach my $allow_blessed (0, 1) {
        foreach my $immutable (0, 1) {
            my @params = (index => $case->{key}, immutable => $immutable, allow_blessed => $allow_blessed);
            next if $case->{test_if} && !$case->{test_if}->(@params);
            
            my $lens = Data::Focus::Lens::HashArray::Index->new(@params);
            my $label = make_label($case->{target}, $case->{key}, $immutable, $allow_blessed);
            my %test_args = (
                lens => $lens, target => $targets{$case->{target}},
                exp_focal_points => $case->{exp_focal_points},
            );
            subtest $label => sub {
                $tester->test_set_set(%test_args);
                $tester->test_set_get(%test_args);
            };
            subtest "$label, set() mutation" => sub {
                foreach my $part ($tester->parts) {
                    my $target = $targets{$case->{target}}->();
                    my $result = focus($target)->set($lens, $part);
                    check_identity($result, $target, ($case->{target} eq "undef" ? 0 : !$immutable));
                }
            };
        }
    }
}

done_testing;
