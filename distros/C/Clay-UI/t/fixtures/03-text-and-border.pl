use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Clay::XS qw(:all);

# A bordered card with a text element. Exercises text measurement
# callbacks and BORDER render commands. The measurer is deterministic
# (monospace fontSize * length) so the fixture is portable.

sub {
    my $ctx = Clay_Initialize(
        Clay_MinMemorySize(),
        { width => 300, height => 200 },
        sub { },
    );
    Clay_SetMeasureTextFunction(sub ($text, $config, $userdata) {
        my $fs = $config->{fontSize} || 16;
        return { width => length($text) * $fs * 0.5, height => $fs };
    });

    Clay_BeginLayout();
    Clay__OpenElementWithId( Clay_GetElementId("card") );
    Clay__ConfigureOpenElement({
        layout => {
            sizing          => { width => sizing_fixed(180), height => sizing_fixed(80) },
            padding         => padding_all(10),
            childAlignment  => { x => CLAY_ALIGN_X_CENTER, y => CLAY_ALIGN_Y_CENTER },
        },
        backgroundColor => [30, 30, 30, 255],
        border          => { color => [200, 200, 200, 255], width => border_all(2) },
        cornerRadius    => corner_radius_all(8),
    });
        Clay__OpenTextElement(
            "hi clay",
            { fontSize => 14, textColor => [255, 255, 255, 255] },
        );
    Clay__CloseElement();
    return Clay_EndLayout(0);
};
