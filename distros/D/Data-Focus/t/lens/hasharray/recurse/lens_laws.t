use strict;
use warnings FATAL => "all";
use Test::More;
use Data::Focus qw(focus);
use Data::Focus::Lens::HashArray::Recurse;
use Data::Focus::LensTester;
use lib "t";
use testlib::SampleObject;
use testlib::Identity qw(check_identity);

my $tester = Data::Focus::LensTester->new(
    test_whole => sub { is_deeply($_[0], $_[1]) },
    test_part => sub { is_deeply($_[0], $_[1]) },
    parts => [
        undef, 1, "str", \(100), testlib::SampleObject->new,
        ## [], {}, # if we mix hash/array, set-set law breaks.
    ]
);

my %targets = (
    scalar => sub { "aaa" },
    scalar_ref => sub { \(100) },
    obj => sub { testlib::SampleObject->new },
    undef => sub { undef },
    
    empty_hash => sub { +{} },
    hash => sub { +{foo => "bar", fizz => "buzz"} },

    empty_array => sub { +[] },
    array => sub { +[0, 1, 2, 3] },

    nested => sub { +{foo => [0, {bar => "buzz"}, [], 11], hoge => {FOO => [9, {}]}} },
);

foreach my $case (
    {target => "scalar", exp_focal_points => 1, exp_replace => 1},
    {target => "scalar_ref", exp_focal_points => 1, exp_replace => 1},
    {target => "obj", exp_focal_points => 1, exp_replace => 1},
    {target => "undef", exp_focal_points => 1, exp_replace => 1},
    {target => "empty_hash", exp_focal_points => 0},
    {target => "hash", exp_focal_points => 2},
    {target => "empty_array", exp_focal_points => 0},
    {target => "array", exp_focal_points => 4},
    {target => "nested", exp_focal_points => 4},
) {
    foreach my $immutable (0, 1) {
        my $lens = Data::Focus::Lens::HashArray::Recurse->new(immutable => $immutable);
        my $label = "$case->{target}, immutable=$immutable";
        my %test_args = (
            lens => $lens, target => $targets{$case->{target}},
            exp_focal_points => $case->{exp_focal_points},
            ## exp_mutate => exists($case->{exp_mutate}) ? $case->{exp_mutate} : !$immutable,
        );
        subtest $label => sub {
            $tester->test_lens_laws(%test_args);
        };
        subtest "$label, set() mutation" => sub {
            foreach my $part ($tester->parts) {
                my $target = $targets{$case->{target}}->();
                my $result = focus($target)->set($lens, $part);
                check_identity($result, $target,
                               $case->{exp_replace} ? 0
                               : $case->{exp_focal_points} == 0 ? 1
                               : !$immutable);
            }
        };
    }
}

done_testing;
