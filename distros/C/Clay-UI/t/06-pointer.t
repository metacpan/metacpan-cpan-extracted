use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Clay::XS qw(:all);

# -----------------------------------------------------------------------------
# Pointer state, Hovered(), PointerOver(), GetPointerOverIds().
#
# Clay's pointer detection walks the most recent layout tree to populate
# pointerOverIds. That means the conventional usage is:
#
#     Clay_SetPointerState(...);   # walks the *previous* frame's tree
#     Clay_BeginLayout();
#     ... declare elements ...
#     Clay_EndLayout(...);          # builds the new tree
#
# A pointer interaction therefore requires at least one prior frame to
# have built a tree. The test below runs a two-frame sequence: frame 1
# defines geometry, frame 2 places the pointer.
# -----------------------------------------------------------------------------

my $ctx = Clay_Initialize(
    Clay_MinMemorySize(),
    { width => 200, height => 200 },
    sub { },
);
Clay_SetMeasureTextFunction(sub { return { width => 0, height => 0 } });

sub build_layout () {
    Clay__OpenElementWithId( Clay_GetElementId("root") );
    Clay__ConfigureOpenElement({
        layout => {
            sizing => { width => sizing_fixed(100), height => sizing_fixed(100) },
        },
    });
        Clay__OpenElementWithId( Clay_GetElementId("button") );
        Clay__ConfigureOpenElement({
            layout => {
                sizing => { width => sizing_fixed(80), height => sizing_fixed(80) },
            },
        });
        Clay__CloseElement();
    Clay__CloseElement();
}

is( Clay_GetPointerState()->{state}, CLAY_POINTER_DATA_RELEASED, 'a new context starts with a released pointer' );

# ----- Frame 1: build geometry, no pointer interaction yet -------------------
Clay_BeginLayout();
build_layout();
Clay_EndLayout(0);

# The first press is a press "this frame", not a continued one.
Clay_SetPointerState({ x => 30, y => 30 }, 1);
is( Clay_GetPointerState()->{state}, CLAY_POINTER_DATA_PRESSED_THIS_FRAME, 'the first press reads as pressed this frame' );

# ----- Frame 2: place pointer inside button, rebuild ------------------------
Clay_SetPointerState({ x => 30, y => 30 }, 0);
Clay_BeginLayout();
build_layout();
Clay_EndLayout(0);

my $button_id = Clay_GetElementId("button");

ok( Clay_PointerOver($button_id), 'PointerOver detects pointer inside button' );

my $over = Clay_GetPointerOverIds();
ok( ref($over) eq 'ARRAY', 'GetPointerOverIds returns an arrayref' );
ok( ( grep { $_->{id} == $button_id->{id} } @$over ),
    'button id is in pointer-over list' );

# ----- Frame 3: move pointer far away ---------------------------------------
Clay_SetPointerState({ x => 500, y => 500 }, 0);
Clay_BeginLayout();
build_layout();
Clay_EndLayout(0);

ok( !Clay_PointerOver($button_id), 'PointerOver false when pointer is outside' );

# ----- Pointer-over ids keep their string ids across frames -----------------
Clay_SetPointerState({ x => 30, y => 30 }, 0);
Clay_BeginLayout();
build_layout();
Clay_EndLayout(0);
Clay_BeginLayout();
my @names = sort map { $_->{stringId} // '' } @{ Clay_GetPointerOverIds() };
Clay_EndLayout(0);
is( \@names, [ 'Clay__RootContainer', 'button', 'root' ],
    'pointer-over ids carry their string ids after the next Clay_BeginLayout' );

# ----- Queries about the open element ----------------------------------------
Clay_BeginLayout();
build_layout();
Clay_EndLayout(0);
Clay_SetPointerState({ x => 30, y => 30 }, 0);
Clay_BeginLayout();
Clay__OpenElementWithId( Clay_GetElementId("root") );
Clay__ConfigureOpenElement({ layout => { sizing => { width => sizing_fixed(100), height => sizing_fixed(100) } } });
    Clay__OpenElementWithId( Clay_GetElementId("button") );
    is( Clay_GetOpenElementId(), Clay_GetElementId("button")->{id}, 'Clay_GetOpenElementId names the open element' );
    ok( Clay_Hovered(), 'Clay_Hovered is true for the element under the pointer' );
    Clay__ConfigureOpenElement({ layout => { sizing => { width => sizing_fixed(80), height => sizing_fixed(80) } } });
    Clay__CloseElement();
    Clay__OpenElementWithId( Clay_GetElementId("elsewhere") );
    ok( !Clay_Hovered(), 'and false for an element the pointer is not over' );
    Clay__CloseElement();
Clay__CloseElement();
Clay_EndLayout(0);

# ----- Pointer input needs a completed frame --------------------------------
Clay_BeginLayout();
build_layout();
like( dies { Clay_SetPointerState({ x => 30, y => 30 }, 0) },
    qr/Clay_SetPointerState: cannot be called between Clay_BeginLayout and Clay_EndLayout/,
    'Clay_SetPointerState croaks mid-frame' );
like( dies { Clay_UpdateScrollContainers(0, [0, 0], 0) }, qr/Clay_UpdateScrollContainers: cannot be called between/,
    'so does Clay_UpdateScrollContainers' );
Clay_EndLayout(0);

Clay_SetMeasureTextFunction(sub { die "measure failed\n" });
Clay_BeginLayout();
Clay__OpenTextElement("unfinished", {});
like( dies { Clay_SetPointerState({ x => 30, y => 30 }, 0) },
    qr/^Clay_SetPointerState: cannot be called between Clay_BeginLayout and Clay_EndLayout; end the frame first \(Clay_EndLayout, or Clay_BeginLayout, which finishes an unfinished frame\)/,
    'Clay_SetPointerState croaks while a frame is unfinished, saying how to end it' );
like( dies { Clay_BeginLayout() }, qr/^measure failed \(from the previous unfinished frame\)/,
    'Clay_BeginLayout finishes the frame and re-throws its error' );
Clay_SetMeasureTextFunction(sub { return { width => 0, height => 0 } });
ok( lives { Clay_SetPointerState({ x => 30, y => 30 }, 0) }, 'and Clay_SetPointerState works again at once' );

# ----- Pointer state round-trip ---------------------------------------------
Clay_SetPointerState({ x => 10, y => 20 }, 1);
my $state = Clay_GetPointerState();
is( $state->{position}{x}, 10, 'pointer x preserved' );
is( $state->{position}{y}, 20, 'pointer y preserved' );
is( $state->{state}, CLAY_POINTER_DATA_PRESSED_THIS_FRAME,
    'pointer state went pressed-this-frame on first press' );

done_testing;
