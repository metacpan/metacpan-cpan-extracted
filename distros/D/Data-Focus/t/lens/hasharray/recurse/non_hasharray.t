use strict;
use warnings FATAL => "all";
use Test::More;
use Data::Focus qw(focus);
use Data::Focus::Lens::HashArray::Recurse;
use lib "t";
use testlib::Identity qw(identical);

note("--- if target is not hash/array, the lens is no-op");

foreach my $case (
    {label => "scalar", target => "aaa"},
    {label => "scalar_ref", target => \(100)},
    {label => "code_ref", target => sub { "hoge" }},
    {label => "undef", target => undef}
) {
    subtest $case->{label} => sub {
        my @got = focus($case->{target})->list(Data::Focus::Lens::HashArray::Recurse->new);
        is scalar(@got), 1, "1 focal point";
        if(ref($case->{target})) {
            identical $got[0], $case->{target}, "same instance";
        }else {
            is $got[0], $case->{target}, "same value";
        }
    };
}

done_testing;

