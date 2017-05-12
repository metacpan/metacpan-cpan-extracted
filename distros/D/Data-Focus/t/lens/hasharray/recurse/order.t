use strict;
use warnings FATAL => "all";
use Test::More;
use Data::Focus qw(focus);
use Data::Focus::Lens::HashArray::Recurse;

{
    my $target = [
        [],
        [
            0, 1,
            [
                2, 3,
                [
                    4
                ],
                5,
                6
            ],
            7,
        ],
        [
            8, 9,
            [
                10,
            ]
        ],
        [
            [],
            [
                11
            ]
        ],
        12,
    ];
    my $lens = Data::Focus::Lens::HashArray::Recurse->new;
    is focus($target)->get($lens), 0, "get() first item";
    is_deeply [focus($target)->list($lens)], [0 .. 12], "list() all items. depth-first search by default";
}

done_testing;

