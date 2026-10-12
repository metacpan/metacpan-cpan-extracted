use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Clay::XS qw(:all);

# -----------------------------------------------------------------------------
# Nested elements and text.
#
# Build a 3-level layout:
#
#     root  (220x140)
#       inner row (top-to-bottom)
#         label (text)
#         body  (filled rectangle)
#
# Confirm the render command stream contains:
#   - one rectangle for root
#   - one text command with the right contents
#   - one rectangle for body
# -----------------------------------------------------------------------------

my $ctx = Clay_Initialize(
    Clay_MinMemorySize(),
    { width => 320, height => 240 },
    sub ($err, $userdata) { },
);

Clay_SetMeasureTextFunction(sub ($text, $config, $userdata) {
    my $fs = $config->{fontSize} || 16;
    return { width => length($text) * $fs * 0.5, height => $fs };
});

Clay_BeginLayout();

Clay__OpenElementWithId( Clay_GetElementId("root") );
Clay__ConfigureOpenElement({
    layout => {
        sizing => {
            width  => sizing_fixed(220),
            height => sizing_fixed(140),
        },
        padding         => padding_all(10),
        childGap        => 6,
        layoutDirection => CLAY_TOP_TO_BOTTOM,
    },
    backgroundColor => [200, 200, 200, 255],
});

    Clay__OpenElementWithId( Clay_GetElementId("label") );
    Clay__OpenTextElement(
        "hello clay",
        { fontSize => 14, textColor => [0, 0, 0, 255] },
    );
    Clay__CloseElement();

    Clay__OpenElementWithId( Clay_GetElementId("body") );
    Clay__ConfigureOpenElement({
        layout          => { sizing => { width => sizing_grow(), height => sizing_grow() } },
        backgroundColor => [50, 100, 200, 255],
    });
    Clay__CloseElement();

Clay__CloseElement();

my $commands = Clay_EndLayout(0);

my %by_type;
push @{ $by_type{ $_->{commandType} } }, $_ for @$commands;

ok( exists $by_type{ +CLAY_RENDER_COMMAND_TYPE_RECTANGLE }, 'has rectangle commands' );
ok( exists $by_type{ +CLAY_RENDER_COMMAND_TYPE_TEXT },      'has at least one text command' );

is(
    scalar @{ $by_type{ +CLAY_RENDER_COMMAND_TYPE_RECTANGLE } },
    2,
    'two rectangles emitted (root + body)',
);

my $text_cmd = $by_type{ +CLAY_RENDER_COMMAND_TYPE_TEXT }[0];
is( $text_cmd->{renderData}{stringContents}, "hello clay", 'text contents preserved' );
is( $text_cmd->{renderData}{fontSize}, 14, 'text font size preserved' );

# Confirm element data lookups work post-layout.
my $body = Clay_GetElementData( Clay_GetElementId("body") );
ok( $body->{found}, 'body element found' );
ok( $body->{boundingBox}{height} > 0, 'body has nonzero height' );

# Element id hashing produces stable, repeatable values.
my $id_a = Clay__HashString("foo", 0);
my $id_b = Clay__HashString("foo", 0);
is( $id_a->{id}, $id_b->{id}, 'HashString is deterministic' );

my $id_c = Clay__HashStringWithOffset("foo", 1, 0);
isnt( $id_a->{id}, $id_c->{id}, 'HashStringWithOffset changes the hash' );

sub texts_of ($commands) {
    return map { $_->{renderData}{stringContents} }
           grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_TEXT } @$commands;
}

# -----------------------------------------------------------------------------
# Text copies stay valid for the whole frame, however much text it holds.
# -----------------------------------------------------------------------------

subtest 'more than 16 KiB of text in one frame round-trips' => sub {
    my @lines = map { sprintf "line %04d %s", $_, "abcdefghij" x 4 } 1 .. 400;
    Clay_SetLayoutDimensions({ width => 800, height => 20_000 });
    Clay_BeginLayout();
    Clay__OpenElementWithId( Clay_GetElementId("column") );
    Clay__ConfigureOpenElement({ layout => { layoutDirection => CLAY_TOP_TO_BOTTOM } });
    Clay__OpenTextElement($_, { fontSize => 10, wrapMode => CLAY_TEXT_WRAP_NONE }) for @lines;
    Clay__CloseElement();
    my @got = texts_of(Clay_EndLayout(0));
    Clay_SetLayoutDimensions({ width => 320, height => 240 });

    ok( length(join '', @lines) > 16 * 1024, 'the frame carries more than 16 KiB of text' );
    is( \@got, \@lines, 'every text command carries its own string' );
};

# -----------------------------------------------------------------------------
# Strings are characters in and out.
# -----------------------------------------------------------------------------

subtest 'non-ASCII text and ids round-trip as characters' => sub {
    use utf8;
    my @strings = ("日本語 テキスト", "déjà vu", "ключ");
    Clay_BeginLayout();
    Clay__OpenElementWithId( Clay_GetElementId("ключ") );
    Clay__OpenTextElement($_, { fontSize => 10 }) for @strings;
    Clay__CloseElement();
    my @got = texts_of(Clay_EndLayout(0));
    is( join(' ', @got), join(' ', @strings), 'render commands carry the same characters' );

    my $id = Clay_GetElementId("ключ");
    is( $id->{stringId}, "ключ", 'Clay_GetElementId returns the character id' );
    ok( Clay_GetElementData($id)->{found}, 'the element declared with a Cyrillic id is found' );
};

# -----------------------------------------------------------------------------
# Element ids reach Clay's debug view.
# -----------------------------------------------------------------------------

subtest 'debug mode labels elements with their id' => sub {
    Clay_SetLayoutDimensions({ width => 900, height => 600 });
    Clay_SetDebugModeEnabled(1);
    for my $frame (1 .. 2) {
        Clay_BeginLayout();
        Clay__OpenElementWithId( Clay_GetElementId("labelled-root") );
        Clay__ConfigureOpenElement({ backgroundColor => [1, 2, 3, 255] });
        Clay__CloseElement();
        my @texts = texts_of(Clay_EndLayout(0));
        ok( ( grep { $_ eq 'labelled-root' } @texts ), "frame $frame shows the id label" );
    }
    Clay_SetDebugModeEnabled(0);
    Clay_SetLayoutDimensions({ width => 320, height => 240 });
};

# -----------------------------------------------------------------------------
# Culling drops elements outside the layout dimensions.
# -----------------------------------------------------------------------------

subtest 'culling drops off-screen elements unless disabled' => sub {
    my $row = sub () {
        Clay_BeginLayout();
        Clay__OpenElementWithId( Clay_GetElementId("row") );
        Clay__ConfigureOpenElement({ layout => { childGap => 20 } });
        for my $name (qw(visible offscreen)) {
            Clay__OpenElementWithId( Clay_GetElementId($name) );
            Clay__ConfigureOpenElement({
                layout          => { sizing => { width => sizing_fixed(320), height => sizing_fixed(10) } },
                backgroundColor => [1, 2, 3, 255],
            });
            Clay__CloseElement();
        }
        Clay__CloseElement();
        return scalar grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_RECTANGLE } @{ Clay_EndLayout(0) };
    };
    is( $row->(), 1, 'the element beyond the right edge is culled' );
    Clay_SetCullingEnabled(0);
    is( $row->(), 2, 'with culling disabled it is drawn' );
    Clay_SetCullingEnabled(1);
};

# -----------------------------------------------------------------------------
# Open/close balance is enforced; a frame interrupted mid-element can still be
# ended and the next frame renders normally.
# -----------------------------------------------------------------------------

subtest 'unbalanced open/close croaks instead of crashing' => sub {
    Clay_BeginLayout();
    ok( !eval { Clay__OpenElementWithId( Clay_GetElementId("abandoned") ); die "user error\n"; 1 },
        'an exception leaves an element open' );
    like( dies { Clay_EndLayout(0) },
        qr/1 element still open at Clay_EndLayout \(unbalanced Clay__OpenElement\/Clay__CloseElement\)/,
        'Clay_EndLayout croaks cleanly' );

    Clay_BeginLayout();
    Clay__OpenElementWithId( Clay_GetElementId("healthy") );
    Clay__ConfigureOpenElement({ backgroundColor => [9, 9, 9, 255],
                                 layout => { sizing => { width => sizing_fixed(10), height => sizing_fixed(10) } } });
    Clay__CloseElement();
    my @rects = grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_RECTANGLE } @{ Clay_EndLayout(0) };
    is( scalar(@rects), 1, 'the next frame renders normally' );

    Clay_BeginLayout();
    like( dies { Clay__CloseElement() }, qr/Clay__CloseElement: no element is open/,
        'closing with nothing open croaks' );
    like( dies { Clay__ConfigureOpenElement({}) }, qr/Clay__ConfigureOpenElement: no element is open/,
        'configuring with nothing open croaks' );
    like( dies { Clay_OnHover(sub { }) }, qr/Clay_OnHover: no element is open/,
        'registering hover with nothing open croaks' );
    Clay_EndLayout(0);

    like( dies { Clay_EndLayout(0) }, qr/Clay_EndLayout: called without a matching Clay_BeginLayout/,
        'Clay_EndLayout without Clay_BeginLayout croaks' );
    like( dies { Clay__OpenTextElement("stray", {}) }, qr/called outside Clay_BeginLayout\/Clay_EndLayout/,
        'text outside a frame croaks' );
};

subtest 'an element is configured once, right after it is opened' => sub {
    Clay_BeginLayout();
    Clay__OpenElementWithId( Clay_GetElementId("twice") );
    Clay__ConfigureOpenElement({});
    like( dies { Clay__ConfigureOpenElement({}) }, qr/Clay__ConfigureOpenElement: the open element is already configured/,
        'a second configuration croaks' );
    Clay__OpenTextElement("child", {});
    Clay__CloseElement();
    Clay__OpenElementWithId( Clay_GetElementId("late") );
    Clay__OpenElementWithId( Clay_GetElementId("inner") );
    Clay__CloseElement();
    like( dies { Clay__ConfigureOpenElement({}) }, qr/already configured or has children/,
        'so does configuring after a child' );
    Clay__CloseElement();
    ok( lives { Clay_EndLayout(0) }, 'the frame still ends' );
};

subtest 'undef text and ids croak' => sub {
    like( dies { Clay_GetElementId(undef) }, qr/Clay_GetElementId: element id string must be defined/,
        'undef id string' );
    Clay_BeginLayout();
    like( dies { Clay__OpenTextElement(undef, {}) }, qr/text must be a defined string/, 'undef text' );
    my $missing;
    like( dies { Clay__OpenElementWithId($missing) },
        qr/Clay__OpenElementWithId: element id: expected an element id hash reference .*got undef/,
        'Clay__OpenElementWithId with an undef id' );
    like( dies { Clay__OpenElementWithId('box') }, qr/expected an element id hash reference/,
        'Clay__OpenElementWithId with a plain string' );
    Clay_EndLayout(0);
    for my $query (\&Clay_GetElementData, \&Clay_PointerOver, \&Clay_GetScrollContainerData) {
        like( dies { $query->($missing) }, qr/element id: expected an element id hash reference/,
            'id queries croak for an undef id' );
    }
    like( dies { set_scroll_position($missing, [0, 0]) }, qr/set_scroll_position: element id: expected/,
        'set_scroll_position croaks for an undef id' );
};

# -----------------------------------------------------------------------------
# Render command details fixed by patches/0004-clay-upstream-fixes.patch.
# -----------------------------------------------------------------------------

sub element ($name, $config, @children) {
    Clay__OpenElementWithId( Clay_GetElementId($name) );
    Clay__ConfigureOpenElement($config);
    $_->() for @children;
    Clay__CloseElement();
}

sub command_types ($body) {
    Clay_BeginLayout();
    $body->();
    return [ map { $_->{commandType} } @{ Clay_EndLayout(0) } ];
}

my $square = { sizing => { width => sizing_fixed(10), height => sizing_fixed(10) } };

subtest 'an image or custom element emits no background rectangle' => sub {
    is( command_types(sub { element('img', { layout => $square, image => { imageData => 7 }, backgroundColor => [1, 2, 3, 255] }) }),
        [CLAY_RENDER_COMMAND_TYPE_IMAGE], 'the colour travels in the IMAGE command only' );
    is( command_types(sub { element('cst', { layout => $square, custom => { customData => 7 }, backgroundColor => [1, 2, 3, 255] }) }),
        [CLAY_RENDER_COMMAND_TYPE_CUSTOM], 'and in the CUSTOM command only' );
};

subtest 'a border is emitted for its width, whatever the alpha of its colour' => sub {
    is( command_types(sub { element('b', { layout => $square, border => { width => border_all(2), color => [1, 2, 3, 0] } }) }),
        [CLAY_RENDER_COMMAND_TYPE_BORDER], 'a transparent colour still emits the BORDER: renderers may draw it in a default colour' );
    is( command_types(sub { element('b', { layout => $square, border => { width => border_all(0), color => [1, 2, 3, 255] } }) }),
        [], 'a width of 0 emits nothing' );
};

subtest 'every command of a floating element carries its zIndex' => sub {
    Clay_BeginLayout();
    element('root', { layout => { sizing => { width => sizing_fixed(100), height => sizing_fixed(100) } } }, sub {
        element('f', { layout => { sizing => { width => sizing_fixed(50), height => sizing_fixed(50) }, layoutDirection => CLAY_TOP_TO_BOTTOM },
                        floating => { attachTo => CLAY_ATTACH_TO_PARENT, zIndex => 4 }, clip => { vertical => 1 },
                        backgroundColor => [1, 1, 1, 255], border => { width => { left => 1, betweenChildren => 1 }, color => [1, 1, 1, 255] } },
            sub { element('k1', { layout => $square }) }, sub { element('k2', { layout => $square }) });
    });
    my $commands = Clay_EndLayout(0);
    is( [ map { $_->{commandType} } @$commands ],
        [ CLAY_RENDER_COMMAND_TYPE_SCISSOR_START, CLAY_RENDER_COMMAND_TYPE_RECTANGLE, CLAY_RENDER_COMMAND_TYPE_BORDER,
          CLAY_RENDER_COMMAND_TYPE_RECTANGLE, CLAY_RENDER_COMMAND_TYPE_SCISSOR_END ],
        'scissor, background, border, bar between children, scissor end' );
    is( [ map { $_->{zIndex} } @$commands ], [ (4) x 5 ], 'all with zIndex 4' );
};

subtest 'a culled clip container still clips its children' => sub {
    is( command_types(sub {
        element('root', { layout => { sizing => { width => sizing_fixed(100), height => sizing_fixed(100) } } }, sub {
            element('clip', { layout => { sizing => { width => sizing_fixed(100), height => sizing_fixed(50) } }, clip => { horizontal => 1 },
                               floating => { attachTo => CLAY_ATTACH_TO_PARENT, offset => { x => -150, y => 0 } } },
                sub { element('wide', { layout => { sizing => { width => sizing_fixed(300), height => sizing_fixed(10) } }, backgroundColor => [1, 1, 1, 255] }) });
        });
    }), [ CLAY_RENDER_COMMAND_TYPE_SCISSOR_START, CLAY_RENDER_COMMAND_TYPE_RECTANGLE, CLAY_RENDER_COMMAND_TYPE_SCISSOR_END ],
        'the offscreen container emits its scissor commands around the visible child' );
};

subtest 'a floating element may attach to an element declared later in the frame' => sub {
    my @errors;
    my $ctx = Clay_Initialize(Clay_MinMemorySize(), { width => 200, height => 200 }, sub ($err, $userdata) { push @errors, $err->{errorType} });
    Clay_SetMeasureTextFunction(sub { return { width => 0, height => 0 } });
    my $frame = sub {
        Clay_BeginLayout();
        element('root', { layout => { sizing => { width => sizing_fixed(200), height => sizing_fixed(200) } } },
            sub { element('f', { layout => $square, backgroundColor => [1, 1, 1, 255],
                                 floating => { attachTo => CLAY_ATTACH_TO_ELEMENT_WITH_ID, parentId => Clay_GetElementId('t'), clipTo => CLAY_CLIP_TO_ATTACHED_PARENT } },
                sub { element('kid', { layout => $square }) }) },
            sub { element('clip', { layout => { sizing => { width => sizing_fixed(50), height => sizing_fixed(50) }, layoutDirection => CLAY_TOP_TO_BOTTOM }, clip => { vertical => 1 } },
                sub { element('pad', { layout => { sizing => { width => sizing_fixed(10), height => sizing_fixed(45) } } }) },
                sub { element('t', { layout => $square, backgroundColor => [2, 2, 2, 255] }) }) });
        return Clay_EndLayout(0);
    };
    my @commands = map { $frame->() } 1 .. 3;
    is( \@errors, [], 'three frames report no error' );
    is( [ map { $_->{commandType} } @{ $commands[-1] } ],
        [ CLAY_RENDER_COMMAND_TYPE_SCISSOR_START, CLAY_RENDER_COMMAND_TYPE_RECTANGLE, CLAY_RENDER_COMMAND_TYPE_SCISSOR_END,
          CLAY_RENDER_COMMAND_TYPE_SCISSOR_START, CLAY_RENDER_COMMAND_TYPE_RECTANGLE, CLAY_RENDER_COMMAND_TYPE_SCISSOR_END ],
        'the floating element is clipped like its target' );
    is( $commands[-1][4]{boundingBox}, { x => 0, y => 45, width => 10, height => 10 }, 'and positioned at it' );
    Clay_SetPointerState({ x => 5, y => 48 }, 0);
    is( [ map { $_->{stringId} } @{ Clay_GetPointerOverIds() } ], [ 'f', 'kid' ], 'its subtree is under a pointer inside the clip' );
    Clay_SetPointerState({ x => 5, y => 53 }, 0);
    is( [ map { $_->{stringId} } @{ Clay_GetPointerOverIds() } ], [ 'Clay__RootContainer', 'root' ], 'but not outside it' );

    Clay_BeginLayout();
    element('root', { layout => $square },
        sub { element('g', { layout => $square, floating => { attachTo => CLAY_ATTACH_TO_ELEMENT_WITH_ID, parentId => Clay_GetElementId('nope') } }) });
    Clay_EndLayout(0);
    is( \@errors, [CLAY_ERROR_TYPE_FLOATING_CONTAINER_PARENT_NOT_FOUND], 'a target that is never declared is still reported' );
};

# -----------------------------------------------------------------------------
# Frames that reach the element count (fixed by
# patches/0004-clay-upstream-fixes.patch).
# -----------------------------------------------------------------------------

# A context with a small element count. Clay_Initialize takes the counts of
# the current context, so they are set on $ctx for the call and restored.
sub small_context ($element_count) {
    my ($elements, $words) = (Clay_GetMaxElementCount(), Clay_GetMaxMeasureTextCacheWordCount());
    Clay_SetMaxElementCount($element_count);
    Clay_SetMaxMeasureTextCacheWordCount(32);
    my $small = Clay_Initialize(Clay_MinMemorySize(), { width => 800, height => 600 }, sub { });
    Clay_SetCurrentContext($ctx);
    Clay_SetMaxElementCount($elements);
    Clay_SetMaxMeasureTextCacheWordCount($words);
    Clay_SetCurrentContext($small);
    Clay_SetMeasureTextFunction(sub { return [10, 10] });
    return $small;
}

subtest 'the debug view of a frame that nearly fills the element count' => sub {
    my $small = small_context(64);
    Clay_SetDebugModeEnabled(1);
    Clay_BeginLayout();
    for (1 .. 62) { Clay__OpenElement(); Clay__ConfigureOpenElement({}); Clay__CloseElement() }
    my $commands = Clay_EndLayout();
    is( [ map { $_->{renderData}{stringContents} } @$commands ],
        ['Clay Error: Debug view caused layout element count to exceed Clay__maxElementCount'],
        'reports that the debug view did not fit' );
    Clay_SetCurrentContext($ctx);
};

subtest 'elements past the element count configure nothing' => sub {
    my $small = small_context(64);
    Clay_BeginLayout();
    element('P', { layout => $square }, sub {
        for (1 .. 70) { Clay__OpenElement(); Clay__ConfigureOpenElement({ clip => { vertical => 1 } }); Clay__CloseElement() }
    });
    Clay_EndLayout();
    ok( !Clay_GetScrollContainerData( Clay_GetElementId('P') )->{found}, 'their parent did not take their clip' );

    my $tiny = small_context(1);    # not even Clay's root element fits
    Clay_BeginLayout();
    Clay__OpenElement();
    Clay__ConfigureOpenElement({});
    ok( lives { Clay_OnHover(sub { }) }, 'Clay_OnHover does nothing for them, also with no element open' );
    Clay__CloseElement();
    Clay_EndLayout();
    Clay_SetCurrentContext($ctx);
};

done_testing;
