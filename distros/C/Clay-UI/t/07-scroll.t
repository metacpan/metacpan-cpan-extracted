use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Clay::XS qw(:all);

# -----------------------------------------------------------------------------
# Scrolling containers.
#
# Build a container with vertical clip enabled and contents taller than
# the container. Scroll downward and verify the scroll container data
# reflects the new offset.
# -----------------------------------------------------------------------------

my $ctx = Clay_Initialize(
    Clay_MinMemorySize(),
    { width => 100, height => 100 },
    sub { },
);
Clay_SetMeasureTextFunction(sub { return { width => 0, height => 0 } });

sub build () {
    Clay__OpenElementWithId( Clay_GetElementId("scroll") );
    Clay__ConfigureOpenElement({
        layout => {
            sizing          => { width => sizing_fixed(100), height => sizing_fixed(50) },
            layoutDirection => CLAY_TOP_TO_BOTTOM,
        },
        clip => { vertical => 1, childOffset => Clay_GetScrollOffset() },
    });
        for my $i (0 .. 19) {   # tall enough for a drag to glide
            Clay__OpenElementWithId( Clay_GetElementIdWithIndex("row", $i) );
            Clay__ConfigureOpenElement({
                layout          => { sizing => { width => sizing_fixed(100), height => sizing_fixed(20) } },
                backgroundColor => [50 * (1 + ($i % 2)), 60, 70, 255],
            });
            Clay__CloseElement();
        }
    Clay__CloseElement();
}

# Frame 1: build the layout so the scroll container exists.
Clay_BeginLayout();
build();
Clay_EndLayout(0);

# Frame 2: place the pointer over the scroll container so Clay routes
# wheel input there, then apply scroll, then rebuild.
Clay_SetPointerState({ x => 50, y => 25 }, 0);
Clay_UpdateScrollContainers(0, { x => 0, y => -5 }, 1.0);
Clay_BeginLayout();
build();
Clay_EndLayout(0);

my $scroll_id   = Clay_GetElementId("scroll");
my $scroll_data = Clay_GetScrollContainerData($scroll_id);

ok( $scroll_data->{found}, 'GetScrollContainerData found the container' );
ok( $scroll_data->{config}{vertical}, 'clip vertical is true' );
ok( $scroll_data->{contentDimensions}{height} > 50,
    'content is taller than container' );

is( $scroll_data->{scrollContainerDimensions}{width},  100, 'container width' );
is( $scroll_data->{scrollContainerDimensions}{height},  50, 'container height' );

# Negative wheel scroll means the content moves up (scrollPosition.y becomes negative).
ok( $scroll_data->{scrollPosition}{y} < 0,
    "scrollPosition.y is negative after scrolling down (got $scroll_data->{scrollPosition}{y})" );

# set_scroll_position writes Clay's scroll position; the children move on the
# next frame (build() feeds Clay_GetScrollOffset into clip.childOffset).
set_scroll_position($scroll_id, { x => 0, y => -30 });
Clay_BeginLayout();
build();
Clay_EndLayout(0);
is( Clay_GetElementData( Clay_GetElementIdWithIndex("row", 0) )->{boundingBox}{y}, -30,
    'set_scroll_position moves the children on the next frame' );
like( dies { set_scroll_position(Clay_GetElementId("nope"), [0, 0]) }, qr/not a known scroll container/,
    'set_scroll_position croaks for an unknown container' );

# A drag that is released keeps the container gliding (momentum);
# set_scroll_position stops the glide so the position stays put.
my $y_of = sub { Clay_GetScrollContainerData($scroll_id)->{scrollPosition}{y} };
sub drag_frame ($y, $down) {
    Clay_SetPointerState({ x => 50, y => $y }, $down);
    Clay_UpdateScrollContainers(1, [0, 0], 0.016);
    Clay_BeginLayout();
    build();
    Clay_EndLayout(0.016);
}
drag_frame(45, 1);
drag_frame(33, 1);
drag_frame(33, 0);
my $released_at = $y_of->();
drag_frame(33, 0);
ok( $y_of->() < $released_at, "the container glides on after the release ($released_at -> @{[ $y_of->() ]})" );
set_scroll_position($scroll_id, { x => 0, y => -30 });
drag_frame(33, 0);
is( $y_of->(), -30, 'set_scroll_position stops the glide' );

# Clay_UpdateScrollContainers drops the containers the last frame did not
# declare; a second run between frames changes nothing.
Clay_UpdateScrollContainers(0, [0, 0], 0.016);
Clay_UpdateScrollContainers(0, [0, 0], 0.016);
ok( Clay_GetScrollContainerData($scroll_id)->{found}, 'the container survives a second update without a frame in between' );
is( $y_of->(), -30, 'with its position' );

# The update that removes a vanished container still scrolls the one that
# took its slot.
sub build_page (@containers) {
    Clay__OpenElementWithId( Clay_GetElementId("page") );
    Clay__ConfigureOpenElement({ layout => { layoutDirection => CLAY_TOP_TO_BOTTOM } });
        for my $name (@containers) {
            Clay__OpenElementWithId( Clay_GetElementId($name) );
            Clay__ConfigureOpenElement({ layout => { sizing => { width => sizing_fixed(100), height => sizing_fixed(50) } }, clip => { vertical => 1 } });
                Clay__OpenElementWithId( Clay_GetElementId("$name-content") );
                Clay__ConfigureOpenElement({ layout => { sizing => { width => sizing_fixed(100), height => sizing_fixed(200) } } });
                Clay__CloseElement();
            Clay__CloseElement();
        }
    Clay__CloseElement();
}
Clay_BeginLayout();
build_page("first", "second");
Clay_EndLayout(0);
Clay_BeginLayout();
build_page("second");
Clay_EndLayout(0);
Clay_SetPointerState({ x => 50, y => 25 }, 0);
Clay_UpdateScrollContainers(0, { x => 0, y => -2 }, 0.016);
ok( !Clay_GetScrollContainerData(Clay_GetElementId("first"))->{found}, 'the vanished container is dropped' );
is( Clay_GetScrollContainerData(Clay_GetElementId("second"))->{scrollPosition}{y}, -20, 'the remaining one scrolled in the same update' );

# With external scroll handling, Clay asks the query function for the offset.
my @queried;
like( dies { Clay_SetExternalScrollHandlingEnabled(1) }, qr/Clay_SetQueryScrollOffsetFunction first/,
    'external handling needs a query function' );
Clay_SetQueryScrollOffsetFunction(sub ($element_id, $userdata) {
    push @queried, [ $element_id, $userdata ];
    return { x => 0, y => -12 };
}, 'query-payload');
Clay_SetExternalScrollHandlingEnabled(1);
Clay_BeginLayout();
build();
Clay_EndLayout(0);
is( $queried[0], [ $scroll_id->{id}, 'query-payload' ], 'query function receives the element id and userdata' );
is( Clay_GetScrollContainerData($scroll_id)->{scrollPosition}{y}, -12,
    'the returned offset becomes the scroll position' );
Clay_SetExternalScrollHandlingEnabled(0);

# Mid-frame, Clay reads the clip config through the element slot the
# container had in its last frame, which another element may hold by
# then; the config key is only there once the frame has declared the
# container (scrollmid.pl of the review).
subtest 'mid-frame scroll data has a config only once the container is declared' => sub {
    my ($scroller, $other) = map { Clay_GetElementId($_) } qw(S other);
    my $clip_box = sub ($id, $clip) {
        Clay__OpenElementWithId($id);
        Clay__ConfigureOpenElement({ clip => $clip, layout => { sizing => { width => sizing_fixed(50), height => sizing_fixed(50) } } });
        Clay__CloseElement();
    };
    my $s_clip = { vertical => 1, childOffset => [0, -7] };
    Clay_BeginLayout();
    $clip_box->($scroller, $s_clip);
    Clay_EndLayout(0);
    my $between = Clay_GetScrollContainerData($scroller);
    is( $between->{config}, { horizontal => 0, vertical => 1, childOffset => { x => 0, y => -7 } },
        'between frames the config is the container\'s own' );

    Clay_BeginLayout();
    $clip_box->($other, { horizontal => 1, childOffset => [99, 99] });    # takes S's element slot
    my $before = Clay_GetScrollContainerData($scroller);
    ok( !exists $before->{config}, 'before the frame declares the container there is no config key' );
    is( [ @{$before}{qw(found scrollContainerDimensions)} ], [ 1, { width => 50, height => 50 } ],
        'but found and the dimensions are there' );
    ok( exists $before->{scrollPosition} && exists $before->{contentDimensions}, 'and so are the position and content' );
    $clip_box->($scroller, { vertical => 1, childOffset => [0, -3] });
    is( Clay_GetScrollContainerData($scroller)->{config}, { horizontal => 0, vertical => 1, childOffset => { x => 0, y => -3 } },
        'once declared, the config is this frame\'s clip declaration' );
    ok( lives { set_scroll_position($scroller, [0, 0]) }, 'set_scroll_position works mid-frame' );
    Clay_EndLayout(0);
    ok( exists Clay_GetScrollContainerData($scroller)->{config}, 'and between frames again' );
    ok( !exists Clay_GetScrollContainerData( Clay_GetElementId('nowhere') )->{config}, 'an unknown id has no config' );
};

# A container that is no longer declared keeps a record pointing at its
# old element slot until Clay_UpdateScrollContainers drops it; a new
# container in that slot must still get its own scroll data.
subtest 'a new container in the slot of a vanished one gets its own dimensions' => sub {
    my $container = sub ($name, $width, $height) {
        Clay__OpenElementWithId( Clay_GetElementId($name) );
        Clay__ConfigureOpenElement({ clip => { vertical => 1 },
                                     layout => { sizing => { width => sizing_fixed($width), height => sizing_fixed($height) } } });
        Clay__CloseElement();
    };
    Clay_BeginLayout();
    $container->('vanishing', 60, 20);
    Clay_EndLayout(0);
    Clay_BeginLayout();
    $container->('arriving', 40, 30);
    Clay_EndLayout(0);
    is( Clay_GetScrollContainerData( Clay_GetElementId('arriving') )->{scrollContainerDimensions}, { width => 40, height => 30 },
        'the dimensions of the frame that declared it' );
};

done_testing;
