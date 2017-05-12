use strict;
use warnings FATAL => "all";
use Test::More;
use Data::Focus qw(focus);
use Data::Focus::Lens::Accessor;
use Data::Focus::LensTester;
use lib "t";
use testlib::AccessorSample;

my $tester = Data::Focus::LensTester->new(
    test_whole => sub { my ($w1,$w2) = @_; is_deeply($w1, $w2) },
    test_part => sub { my ($p1,$p2) = @_; is_deeply($p1, $p2) },
    parts => [undef, 10, "foo", [], {foo => "bar"}, testlib::AccessorSample->new]
);

{
    my $target_code = sub { testlib::AccessorSample->new };
    foreach my $case (
        {label => "existent method", method => "foo", exp_focal_points => 1},
        {label => "non-existent method", method => "hogehoge", exp_focal_points => 0},
    ) {
        subtest $case->{label}, sub {
            $tester->test_lens_laws(
                lens => Data::Focus::Lens::Accessor->new(method => $case->{method}),
                target => $target_code,
                exp_focal_points => $case->{exp_focal_points}
            );
        };
    }
    subtest "list returning method (it doesnt hold get-set law)", sub {
        my %args = (
            lens => Data::Focus::Lens::Accessor->new(method => "list"),
            target => $target_code,
            exp_focal_points => 1,
        );
        $tester->test_set_get(%args);
        $tester->test_set_set(%args);
    };
}


foreach my $case (
    {label => "undef", target => sub { undef }},
    {label => "scalar", target => sub { "" }},
    {label => "array-ref", target => sub { [] }},
    {label => "hash-ref", target => sub { {} }},
    {label => "scalar-ref", target => sub { my $s = ""; \$s }},
) {
    subtest "non-blessed ($case->{label})", sub {
        $tester->test_lens_laws(
            lens => Data::Focus::Lens::Accessor->new(method => "foo"),
            target => $case->{target},
            exp_focal_points => 0
        );
    };
}

done_testing;
