use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Clay::XS qw(:all);

# A 2x3 grid where columns auto-fit their widest cell. Uses low-level
# Clay primitives so the fixture has no dependency on the Clay::UI layer;
# this exercises the C-level sizing-group machinery directly.
#
# Each cell is a FIT-width container with a fixed-width filler child;
# the cell's natural fit-width therefore equals the filler's width.
# Column N's width should converge to max(filler widths across rows).
#
#   Row 0: col widths [20, 60, 30]
#   Row 1: col widths [40, 80, 10]
#   Expected column widths after equalization: [40, 80, 30]

sub {
    my $ctx = Clay_Initialize(
        Clay_MinMemorySize(),
        { width => 400, height => 300 },
        sub { },
    );
    Clay_SetMeasureTextFunction(sub { return { width => 0, height => 0 } });

    my @cells = (
        [ 20, 60, 30 ],
        [ 40, 80, 10 ],
    );
    my $cell_h = 25;

    Clay_BeginLayout();
    Clay__OpenElementWithId( Clay_GetElementId("grid") );
    Clay__ConfigureOpenElement({
        layout => {
            sizing          => { width => sizing_fit(), height => sizing_fit() },
            layoutDirection => CLAY_TOP_TO_BOTTOM,
            childGap        => 0,
        },
    });

    for my $r (0 .. $#cells) {
        my $widths = $cells[$r];
        Clay__OpenElementWithId( Clay_GetElementIdWithIndex("row", $r) );
        Clay__ConfigureOpenElement({
            layout => {
                sizing          => { width => sizing_fit(), height => sizing_fit() },
                layoutDirection => CLAY_LEFT_TO_RIGHT,
                childGap        => 0,
            },
        });
        for my $c (0 .. $#$widths) {
            Clay__OpenElementWithId( Clay_GetElementIdWithIndex("cell-$r", $c) );
            Clay__ConfigureOpenElement({
                layout      => {
                    sizing => { width => sizing_fit(), height => sizing_fixed($cell_h) },
                },
                sizingGroup => { width => $c + 1, height => $r + 10 },
                backgroundColor => [50 + 70 * $c, 50 + 70 * $r, 100, 255],
            });
            # Filler child gives the cell its natural fit-width.
            Clay__OpenElementWithId( Clay_GetElementIdWithIndex("filler-$r-$c", 0) );
            Clay__ConfigureOpenElement({
                layout => {
                    sizing => { width => sizing_fixed($widths->[$c]), height => sizing_fixed($cell_h) },
                },
            });
            Clay__CloseElement();
            Clay__CloseElement();
        }
        Clay__CloseElement();
    }

    Clay__CloseElement();
    return Clay_EndLayout(0);
};
