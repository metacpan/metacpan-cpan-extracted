use strict;
use warnings FATAL => "all";
use Test::More;
use Data::Focus qw(focus);
use Data::Focus::Lens::HashArray::Index;

sub lens {
    return Data::Focus::Lens::HashArray::Index->new(index => shift);
}

sub target {
    +[
        {foo => 1, bar => 11},
        {foo => 2, bar => 12},
        {foo => 3, bar => 13},
    ]
}

note("--- over() method");

foreach my $case (
    {label => "existent, 1 focal point", keys => [0, "foo"]},
    {label => "array non-existent, 1 focal point", keys => [4],
     exp_target => [{foo => 1, bar => 11}, {foo => 2, bar => 12}, {foo => 3, bar => 13}, undef, undef]},
    {label => "hash non-existent, 1 focal point", keys => [0, "hoge"],
     exp_target => [{foo => 1, bar => 11, hoge => undef}, {foo => 2, bar => 12}, {foo => 3, bar => 13}]},
    {label => "slice", keys => [[0,1]]},
    {label => "slice of slice", keys => [[0,1,2], ["foo", "bar"]]},
    {label => "slice of slice (non-existent)", keys => [[0,3], ["foo", "hoge"]],
     exp_target => [{foo => 1, bar => 11, hoge => undef}, {foo => 2, bar => 12}, {foo => 3, bar => 13}, {foo => undef, hoge => undef}]},
) {
    my @lenses = map { lens($_) } @{$case->{keys}};
    my @over_args = ();
    my $got = focus(target())->over(@lenses, sub {
        push @over_args, [@_];
        return $_[0];
    });
    my $exp = exists($case->{exp_target}) ? $case->{exp_target} : target();
    is_deeply $got, $exp, "$case->{label}: over() result OK";
    is_deeply \@over_args, [map { [$_] } focus(target())->list(@lenses)], "$case->{label}: over() args is the same as list() result";
}

done_testing;
