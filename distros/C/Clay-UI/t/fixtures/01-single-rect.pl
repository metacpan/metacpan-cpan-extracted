use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Clay::XS qw(:all);

# Smallest possible layout: one fixed-size root with a background colour.

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
        layout          => { sizing => { width => sizing_fixed(120), height => sizing_fixed(60) } },
        backgroundColor => [255, 128, 0, 255],
        cornerRadius    => corner_radius_all(4),
    });
    Clay__CloseElement();
    return Clay_EndLayout(0);
};
