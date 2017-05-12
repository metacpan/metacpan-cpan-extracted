use strict;
use warnings FATAL => "all";
use Test::More;
use Test::Fatal;
use Data::Focus qw(focus);
use Data::Focus::Lens::Dynamic;
use Data::Focus::Lens::HashArray::Index;
use Data::Focus::Lens::Composite;

package OK;
sub new { return bless {data => [1,2,3]}, shift }
sub Lens {
    return Data::Focus::Lens::HashArray::Index->new(index => "data", allow_blessed => 1)
        . Data::Focus::Lens::HashArray::Index->new(index => $_[1]);
}

package NoLensMethod;
sub new { return bless {}, shift }

package Throwing;
sub new { return bless {}, shift }
sub Lens { die "Lens() dies" }

package NotALens;
sub new { return bless {}, shift }
sub Lens { return "foo" }


package main;

sub dlens {
    return Data::Focus::Lens::Dynamic->new(shift);
}

is focus({a => "A"})->get(dlens("a")), "A", "hash-ref OK";
is focus([3,4,5])->get(dlens(1)), 4, "array-ref OK";
is focus(OK->new)->get(dlens(2)), 3, "blessed OK";

is focus(undef)->get(dlens("foo")), undef, "undef get OK";
is_deeply focus(undef)->set(dlens("foo"), "bar"), {foo => "bar"}, "undef set autovivification OK";

{
    my $nested = {
        a => [9, 10, OK->new]
    };
    is focus($nested)->get(map { dlens($_) } "a", 2, 0), 1, "nested data OK";
    is focus($nested)->get(Data::Focus::Lens::Composite->new(map { dlens($_) } "a", 2, 0)), 1, "nested data (triple composite) OK";
}

subtest "Lens() throwing an exception", sub {
    my $target = Throwing->new;
    like exception { focus($target)->get(dlens(1)) }, qr{Lens\(\) dies}, "The thrown error propagates to the top";
};

subtest "Lens() returning a non-lens", sub {
    my $target = NotALens->new;
    like exception { focus($target)->get(dlens(1)) }, qr{Lens method did not return a Data::Focus::Lens},
        "it should raise an exception";
};

subtest "zero focal points", sub {
    my $scalar = "hoge";
    foreach my $case (
        {label => "string", target => "string"},
        {label => "int", target => 10},
        {label => "scalar-ref", target => \$scalar},
        {label => "no Lens method", target => NoLensMethod->new},
    ) {
        my $target = $case->{target};
        my @ret = focus($target)->list(dlens(10));
        is_deeply \@ret, [], "$case->{label}: zero focal points";
    }
};

done_testing;
