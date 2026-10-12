use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Clay::XS qw(:all);

# Y-axis sizing groups. Two rows of cells share one height group per row;
# the cells are TOP_TO_BOTTOM containers with fillers of different heights,
# so each row's cells equalize to the tallest filler in that row. A
# stacked pair of cells (group 30) is equalized along its parent's axis.
#
#   row 0: [20] [45]        -> both 45 high
#   row 1: [30] [10]        -> both 30 high
#   stack: [15] over [25]   -> both 25 high

sub {
    my $ctx = Clay_Initialize(
        Clay_MinMemorySize(),
        { width => 400, height => 400 },
        sub { },
    );
    Clay_SetMeasureTextFunction(sub { return { width => 0, height => 0 } });

    my $box = sub ($name, $decl, @children) {
        Clay__OpenElementWithId( Clay_GetElementId($name) );
        Clay__ConfigureOpenElement({ backgroundColor => [30, 60, 90, 255], %$decl });
        $_->() for @children;
        Clay__CloseElement();
    };
    my $cell = sub ($name, $group, $height) {
        return sub {
            $box->($name, { layout => { layoutDirection => CLAY_TOP_TO_BOTTOM }, sizingGroup => { height => $group } }, sub {
                $box->("$name-filler", { layout => { sizing => { width => sizing_fixed(20), height => sizing_fixed($height) } } });
            });
        };
    };
    my $row = sub ($name, @cells) {
        return sub { $box->($name, { layout => { layoutDirection => CLAY_LEFT_TO_RIGHT, childGap => 5 } }, @cells) };
    };

    Clay_BeginLayout();
    $box->('page', { layout => { layoutDirection => CLAY_TOP_TO_BOTTOM, childGap => 5 } },
        $row->('row0', $cell->('r0c0', 10, 20), $cell->('r0c1', 10, 45)),
        $row->('row1', $cell->('r1c0', 11, 30), $cell->('r1c1', 11, 10)),
        sub {
            $box->('stack', { layout => { layoutDirection => CLAY_TOP_TO_BOTTOM } },
                $cell->('s0', 30, 15), $cell->('s1', 30, 25));
        },
    );
    return Clay_EndLayout(0);
};
