use Test::More qw(no_plan);

use strict;
use warnings;

use Attribute::Generator;

sub itself:Generator {
    yield $_ for @_;
}

{
    my $gen = itself(1, 2, 3);
    is_deeply([@$gen], [1, 2, 3]);
}

{
    my $gen = itself(2, 3, 4, 5);
    my @result;
    while(<$gen>) {
        push @result, $_;
    }
    is_deeply(\@result, [2, 3, 4, 5]);
}

sub flatten:Generator {
    yield @$_ for @_;
}

{
    my $gen = flatten([1,2],[11,12,13],[100]);
    is_deeply([@$gen], [1,2,11,12,13,100]);
}
