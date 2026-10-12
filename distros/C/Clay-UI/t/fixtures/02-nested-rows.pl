use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Clay::XS qw(:all);

# Three rows stacked top-to-bottom with even gaps. Exercises padding,
# childGap, and TOP_TO_BOTTOM layout direction.

sub {
    my $ctx = Clay_Initialize(
        Clay_MinMemorySize(),
        { width => 200, height => 200 },
        sub { },
    );
    Clay_SetMeasureTextFunction(sub { return { width => 0, height => 0 } });

    Clay_BeginLayout();
    Clay__OpenElementWithId( Clay_GetElementId("root") );
    Clay__ConfigureOpenElement({
        layout => {
            sizing          => { width => sizing_fixed(200), height => sizing_fixed(200) },
            padding         => padding_all(8),
            childGap        => 4,
            layoutDirection => CLAY_TOP_TO_BOTTOM,
        },
    });

    for my $i (0 .. 2) {
        Clay__OpenElementWithId( Clay_GetElementIdWithIndex("row", $i) );
        Clay__ConfigureOpenElement({
            layout          => {
                sizing => { width => sizing_grow(), height => sizing_fixed(40) },
            },
            backgroundColor => [100 + 50 * $i, 100, 100, 255],
        });
        Clay__CloseElement();
    }

    Clay__CloseElement();
    return Clay_EndLayout(0);
};
