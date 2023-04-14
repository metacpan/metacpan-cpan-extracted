#! perl

use Test2::V0;

use CXC::Number::Grid;

my $grid = CXC::Number::Grid->new(
    edges   => [ 0, 2, 4, 8, 12, 16 ],
    include => [ 0, 0, 1, 1, 0 ],
);

is(
    $grid->combine_bins,
    object {
        call edges => array {
            item 0;
            item 4;
            item 12;
            item 16;
        };
        call include => array {
            item 0;
            item 1;
            item 0;
        }
    },
    'combined'
);

# original, for sanity
is(
    $grid,
    object {
        call edges => array {
            item 0;
            item 2;
            item 4;
            item 8;
            item 12;
            item 16;
        };
        call include => array {
            item 0;
            item 0;
            item 1;
            item 1;
            item 0;
        }
    },
    'original'
);


done_testing;
