use strict;
use warnings;
use Data::Monad::List;
use Test::More;

sub roll_dice {
    my @v = @_;
    Data::Monad::List->new(map { [@v, $_] } 1 .. 6);
}

my $roll_dice_until_more_than_3 = list_unit->while(sub {
    my $sum = 0;
    $sum += $_ for @_;
    $sum < 3;
}, \&roll_dice);

is_deeply $roll_dice_until_more_than_3, [
    [1, 1, 1], [1, 1, 2], [1, 1, 3], [1, 1, 4], [1, 1, 5], [1, 1, 6],
    [1, 2], [1, 3], [1, 4], [1, 5], [1, 6],
    [2, 1], [2, 2], [2, 3], [2, 4], [2, 5], [2, 6],
    [3], [4], [5], [6],
];

done_testing;
