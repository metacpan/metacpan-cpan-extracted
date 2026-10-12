use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Clay::XS qw(:all);

# A wrap container of fixed size with tags of different widths. Exercises
# line breaking with padding, childGap and lineGap, a GROW tag filling the
# rest of its line, per-line centering, leftover height shared between the
# lines (CLAY_LINE_SIZING_GROW) and betweenChildren borders within and
# between lines.

sub {
    my $ctx = Clay_Initialize(
        Clay_MinMemorySize(),
        { width => 300, height => 200 },
        sub { },
    );
    Clay_SetMeasureTextFunction(sub { return { width => 0, height => 0 } });

    Clay_BeginLayout();
    Clay__OpenElementWithId( Clay_GetElementId("tags") );
    Clay__ConfigureOpenElement({
        layout => {
            sizing          => { width => sizing_fixed(240), height => sizing_fixed(150) },
            padding         => padding_all(10),
            childGap        => 8,
            lineGap         => 6,
            childAlignment  => { x => CLAY_ALIGN_X_CENTER, y => CLAY_ALIGN_Y_CENTER },
            layoutDirection => CLAY_LEFT_TO_RIGHT_WRAP,
        },
        backgroundColor => [30, 30, 30, 255],
        border          => { color => [200, 200, 200, 255], width => { betweenChildren => 2 } },
    });

    my @tags = ( [ 60, 20 ], [ 90, 30 ], [ 70, 20 ], [ 40, 20 ], [ 0, 24 ], [ 120, 20 ] );
    for my $i (0 .. $#tags) {
        my ($width, $height) = @{ $tags[$i] };
        Clay__OpenElementWithId( Clay_GetElementIdWithIndex("tag", $i) );
        Clay__ConfigureOpenElement({
            layout => {
                sizing => {
                    width  => $width ? sizing_fixed($width) : sizing_grow(50),
                    height => sizing_fixed($height),
                },
            },
            backgroundColor => [80 + 25 * $i, 120, 160, 255],
        });
        Clay__CloseElement();
    }

    Clay__CloseElement();
    return Clay_EndLayout(0);
};
