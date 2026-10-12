use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Clay::XS qw(:all);

# A FIT stack container (CLAY_BACK_TO_FRONT) inside a row: a GROW
# background, a card and a badge overlap, aligned bottom right. Exercises
# sizing from the largest child on both axes, GROW filling the inner size,
# per-child alignment, back-to-front draw order and a sibling placed after
# the stack.

sub {
    my $ctx = Clay_Initialize(
        Clay_MinMemorySize(),
        { width => 300, height => 200 },
        sub { },
    );
    Clay_SetMeasureTextFunction(sub { return { width => 0, height => 0 } });

    my $box = sub ($name, $sizing, $color) {
        Clay__OpenElementWithId( Clay_GetElementId($name) );
        Clay__ConfigureOpenElement({ layout => { sizing => $sizing }, backgroundColor => $color });
        Clay__CloseElement();
    };

    Clay_BeginLayout();
    Clay__OpenElementWithId( Clay_GetElementId("row") );
    Clay__ConfigureOpenElement({ layout => { padding => padding_all(5), childGap => 10 } });

    Clay__OpenElementWithId( Clay_GetElementId("stack") );
    Clay__ConfigureOpenElement({
        layout => {
            padding         => padding_all(4),
            childGap        => 50,
            childAlignment  => { x => CLAY_ALIGN_X_RIGHT, y => CLAY_ALIGN_Y_BOTTOM },
            layoutDirection => CLAY_BACK_TO_FRONT,
        },
        border => { color => [200, 200, 200, 255], width => { left => 1, right => 1, top => 1, bottom => 1, betweenChildren => 2 } },
    });
    $box->('background', { width => sizing_grow(),      height => sizing_grow() },      [30, 30, 30, 255]);
    $box->('card',       { width => sizing_fixed(120),  height => sizing_fixed(60) },   [80, 120, 160, 255]);
    $box->('badge',      { width => sizing_fixed(20),   height => sizing_fixed(90) },   [220, 60, 60, 255]);
    Clay__CloseElement();

    $box->('after', { width => sizing_fixed(30), height => sizing_fixed(30) }, [60, 160, 60, 255]);

    Clay__CloseElement();
    return Clay_EndLayout(0);
};
