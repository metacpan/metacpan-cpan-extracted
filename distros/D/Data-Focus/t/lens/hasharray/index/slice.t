use strict;
use warnings FATAL => "all";
use Test::More;
use Data::Focus qw(focus);
use Data::Focus::Lens::HashArray::Index;

sub set_multi {
    my ($target, $indices, $vals_ref) = @_;
    my @vals = @$vals_ref;
    my $lens = Data::Focus::Lens::HashArray::Index->new(index => $indices);
    my @over_arg = ();
    my $ret = focus($target)->over($lens, sub {
        push @over_arg, shift;
        return shift @vals;
    });
    return [$ret, \@over_arg];
}

note("--- slice set/over order");

is_deeply(
    set_multi([], [2,1,0], [12,11,10]),
    [[10,11,12], [undef, undef, undef]],
    "array slice over()"
);
is_deeply(
    set_multi({}, [qw(c b a)], [12,11,10]),
    [{a => 10, b => 11, c => 12}, [undef, undef, undef]],
    "hash slice over()"
);

is_deeply(
    set_multi([], [1,1,1], [3,4,5]),
    [[undef, 5], [undef, undef, undef]],
    "array duplicate slice over(). The last value wins. Every over() is passed the same snapshot value."
);

is_deeply(
    set_multi({}, ["a", "a", "a"], [3,4,5]),
    [{a => 5}, [undef, undef, undef]],
    "hash duplicate slice over(). The last value wins. Every over() is passed the same snapshot value."
);

done_testing;
