use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Clay::XS qw(:all);

# -----------------------------------------------------------------------------
# Transition handlers. Clay's transition callbacks carry no element id, so
# the binding installs one handler set per context that serves every
# transitioning element (see src/clay_perl.h).
#
# This test verifies:
#   - Clay_SetTransitionHandlers installs and replaces handlers cleanly
#   - the handler receives the transition arguments and what it writes
#     into current is what gets drawn
#   - Clay_EaseOut eases every selected property
#   - an exiting element keeps its text
# -----------------------------------------------------------------------------

my @handler_args;

my $ctx = Clay_Initialize(
    Clay_MinMemorySize(),
    { width => 100, height => 100 },
    sub { },
);
Clay_SetMeasureTextFunction(sub { return { width => 0, height => 0 } });

Clay_SetTransitionHandlers(
    # handler: return true (complete) after first call to keep the test deterministic
    sub ($args, $userdata) {
        push @handler_args, $args;
        return 1;
    },
    # setInitialState: identity
    sub ($target, $properties, $userdata) { return $target },
    # setFinalState: identity
    sub ($initial, $properties, $userdata) { return $initial },
    "transition-userdata",
);

# Frame 1: element with no transition.
sub build_frame ($bg) {
    Clay__OpenElementWithId( Clay_GetElementId("box") );
    Clay__ConfigureOpenElement({
        layout          => { sizing => { width => sizing_fixed(50), height => sizing_fixed(50) } },
        backgroundColor => $bg,
        transition => {
            duration   => 0.5,
            properties => CLAY_TRANSITION_PROPERTY_BACKGROUND_COLOR,
        },
    });
    Clay__CloseElement();
}

Clay_BeginLayout();
build_frame([255, 0, 0, 255]);
Clay_EndLayout(0.016);

# Frame 2: change the background colour - should trigger a transition.
Clay_BeginLayout();
build_frame([0, 255, 0, 255]);
my $cmds = Clay_EndLayout(0.016);

ok( ref($cmds) eq 'ARRAY', 'layout produced commands during transition' );
ok( scalar(@handler_args) >= 1, 'the handler ran for the background change' );
is( $handler_args[0]{target}{backgroundColor}, { r => 0, g => 255, b => 0, a => 255 },
    'it received the new colour as target' );
is( $handler_args[0]{properties}, CLAY_TRANSITION_PROPERTY_BACKGROUND_COLOR,
    'and the configured properties' );
is( [ sort keys %{ $handler_args[0] } ],
    [ sort map { $_->{name} } @{ Clay::XS::_struct_schemas()->{Clay_TransitionCallbackArguments} } ],
    'its argument hash has exactly the keys of the Clay_TransitionCallbackArguments schema' );

# Test removal: install null handlers; subsequent frames must still work.
Clay_SetTransitionHandlers(undef, undef, undef, undef);
Clay_BeginLayout();
build_frame([0, 0, 255, 255]);
my $cmds_after = Clay_EndLayout(0.016);
ok( ref($cmds_after) eq 'ARRAY', 'pipeline still works after handlers removed' );

# Test Clay_EaseOut helper.
# At elapsed=duration the lerp finishes; current.boundingBox.x should
# equal target.boundingBox.x and complete should be true.
my $finished = Clay_EaseOut({
    transitionState => CLAY_TRANSITION_STATE_TRANSITIONING,
    elapsedTime     => 1.0,
    duration        => 1.0,
    properties      => CLAY_TRANSITION_PROPERTY_X,
    initial => { boundingBox => { x =>  0, y => 0, width => 100, height => 100 } },
    target  => { boundingBox => { x => 50, y => 0, width => 100, height => 100 } },
});
ok( $finished->{complete}, 'Clay_EaseOut reports completion at elapsed == duration' );
is( $finished->{current}{boundingBox}{x}, 50,
    'eased x reaches target at completion' );

# Halfway through, current should be between initial and target.
my $mid = Clay_EaseOut({
    transitionState => CLAY_TRANSITION_STATE_TRANSITIONING,
    elapsedTime     => 0.25,
    duration        => 1.0,
    properties      => CLAY_TRANSITION_PROPERTY_X,
    initial => { boundingBox => { x =>  0, y => 0, width => 100, height => 100 } },
    target  => { boundingBox => { x => 50, y => 0, width => 100, height => 100 } },
});
ok( !$mid->{complete}, 'Clay_EaseOut reports in-progress when elapsed < duration' );
ok( $mid->{current}{boundingBox}{x} > 0
 && $mid->{current}{boundingBox}{x} < 50,
    'eased x is between initial and target during transition' );

# Colours and border widths ease too. At t = 0.5 the ease-out curve
# 1 - (1 - t)^3 gives a lerp amount of 0.875.
my $colour = Clay_EaseOut({
    elapsedTime => 0.5,
    duration    => 1.0,
    properties  => CLAY_TRANSITION_PROPERTY_BACKGROUND_COLOR | CLAY_TRANSITION_PROPERTY_BORDER_WIDTH,
    initial => { backgroundColor => [255, 0, 0, 255], borderWidth => { left => 0,  top => 8 } },
    target  => { backgroundColor => [0, 0, 255, 255], borderWidth => { left => 16, top => 0 } },
});
is( $colour->{current}{backgroundColor}, { r => 31.875, g => 0, b => 223.125, a => 255 },
    'backgroundColor eases between initial and target' );
is( $colour->{current}{borderWidth}{left}, 14, 'borderWidth eases (left)' );
is( $colour->{current}{borderWidth}{top},   1, 'borderWidth eases (top)' );

like( dies { Clay_EaseOut({ initial => [1, 2, 3] }) }, qr/^Clay_EaseOut: args\.initial: expected a hash reference/,
    'a non-hash initial croaks' );
like( dies { Clay_EaseOut({ current => 'oops' }) }, qr/^Clay_EaseOut: args\.current: expected a hash reference/,
    'a non-hash current croaks' );
like( dies { Clay_EaseOut(undef) }, qr/^Clay_EaseOut: args: expected a hash reference, got undef/,
    'undef arguments croak' );
my $bad_state = dies { Clay_EaseOut({ transitionState => CLAY_TRANSITION_STATE_EXITING + 1 }) };
isa_ok( $bad_state, 'Clay::XS::StructError' );
is( $bad_state->path, [ 'Clay_EaseOut: args', 'transitionState' ], 'a bad field croaks a struct error naming it' );

# -----------------------------------------------------------------------------
# An element playing its exit transition keeps rendering its own text while
# the rest of the frame's text changes.
# -----------------------------------------------------------------------------

subtest 'exiting element keeps its text' => sub {
    Clay_SetTransitionHandlers(sub { 0 }, undef, sub ($initial, $properties, $userdata) { $initial });
    my $frame = sub ($with_toast, $body) {
        Clay_BeginLayout();
        Clay__OpenElementWithId( Clay_GetElementId("page") );
        Clay__ConfigureOpenElement({ layout => { layoutDirection => CLAY_TOP_TO_BOTTOM } });
        if ($with_toast) {
            Clay__OpenElementWithId( Clay_GetElementId("toast") );
            Clay__ConfigureOpenElement({
                transition => { duration => 1, properties => CLAY_TRANSITION_PROPERTY_X,
                                exit => { hasSetFinal => 1 } },
            });
            Clay__OpenTextElement("TOAST-MESSAGE-TEXT", {});
            Clay__CloseElement();
        }
        Clay__OpenTextElement($body, {});
        Clay__CloseElement();
        return [ map { $_->{renderData}{stringContents} }
                 grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_TEXT } @{ Clay_EndLayout(0.016) } ];
    };
    $frame->(1, "first body");
    $frame->(1, "second body");
    for my $body ("X" x 40, "Y" x 40, "Z" x 40) {
        is( $frame->(0, $body), [ "TOAST-MESSAGE-TEXT", $body ], "exiting toast text intact next to '$body'" );
    }
    Clay_SetTransitionHandlers();
};

subtest 'an unfinished frame does not free text an exiting element shows' => sub {
    Clay_SetTransitionHandlers(sub { 0 }, undef, sub ($initial, $properties, $userdata) { $initial });
    my $toast_frame = sub ($with_toast) {
        Clay_BeginLayout();
        Clay__OpenElementWithId( Clay_GetElementId("page") );
        Clay__ConfigureOpenElement({});
        if ($with_toast) {
            Clay__OpenElementWithId( Clay_GetElementId("toast") );
            Clay__ConfigureOpenElement({ transition => { duration => 1, properties => CLAY_TRANSITION_PROPERTY_X,
                                                          exit => { hasSetFinal => 1 } } });
            Clay__OpenTextElement("TOAST-MESSAGE-TEXT", {});
            Clay__CloseElement();
        }
        Clay__CloseElement();
        return [ map { $_->{renderData}{stringContents} }
                 grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_TEXT } @{ Clay_EndLayout(0.016) } ];
    };
    $toast_frame->(1) for 1 .. 3;
    # Left open without the toast: the next Clay_BeginLayout finishes this
    # frame, and the toast starts its exit in it.
    Clay_BeginLayout();
    Clay__OpenElementWithId( Clay_GetElementId("page") );
    Clay__ConfigureOpenElement({});
    Clay__OpenTextElement("unfinished " . ("x" x 20_000), {});
    is( $toast_frame->(0), ["TOAST-MESSAGE-TEXT"], 'the exiting toast still shows its text' );
    is( $toast_frame->(0), ["TOAST-MESSAGE-TEXT"], 'also in the frame after' );
    Clay_SetTransitionHandlers();
};

subtest 'an exiting element removed after an unfinished frame finishes its exit' => sub {
    Clay_SetTransitionHandlers(sub { 0 }, undef, sub ($initial, $properties, $userdata) { $initial });
    my $exit = { duration => 1, properties => CLAY_TRANSITION_PROPERTY_BACKGROUND_COLOR, exit => { hasSetFinal => 1 } };
    my $box = sub ($name, $transition) {
        Clay__OpenElementWithId( Clay_GetElementId($name) );
        Clay__ConfigureOpenElement({ layout => { sizing => { width => sizing_fixed(20), height => sizing_fixed(20) } },
            backgroundColor => [200, 0, 0, 255], ($transition ? (transition => $transition) : ()) });
        Clay__CloseElement();
    };
    Clay_BeginLayout();
    $box->('X', $exit);
    Clay_EndLayout(0.016);
    ok( !eval { Clay_BeginLayout(); $box->('X', $exit); die "widget code failed\n" }, 'the second frame is left unfinished' );
    Clay_BeginLayout();
    $box->('P', undef);
    my $commands = Clay_EndLayout(0.016);
    is( scalar(grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_RECTANGLE } @$commands), 2,
        'the frame after it completes and draws P and the exiting X' );
    is( Clay::XS::_context_stats($ctx), hash { field layout_state => 'complete'; field open_depth => 0; etc },
        'and leaves nothing open' );
    Clay_SetTransitionHandlers();
};

subtest 'an element declared once without its transition loses its exit' => sub {
    Clay_SetTransitionHandlers(sub { 0 }, undef, sub ($initial, $properties, $userdata) { $initial });
    my $exit = { duration => 1, properties => CLAY_TRANSITION_PROPERTY_BACKGROUND_COLOR, exit => { hasSetFinal => 1 } };
    my $box = sub ($name, $transition, @children) {
        Clay__OpenElementWithId( Clay_GetElementId($name) );
        Clay__ConfigureOpenElement({ layout => { sizing => { width => sizing_fixed(20), height => sizing_fixed(20) } },
            backgroundColor => [200, 0, 0, 255], ($transition ? (transition => $transition) : ()) });
        $_->() for @children;
        Clay__CloseElement();
    };
    my $drawn = sub (@boxes) {
        Clay_BeginLayout();
        $_->() for @boxes;
        my %name_of = map { Clay_GetElementId($_)->{id} => $_ } qw(X Y C);
        return [ sort map { $name_of{ $_->{id} } // '?' }
                 grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_RECTANGLE } @{ Clay_EndLayout(0.016) } ];
    };
    my $y_with_child = sub { $box->('Y', $exit, sub { $box->('C', undef) }) };
    $drawn->(sub { $box->('Y', $exit) }, sub { $box->('X', $exit) });
    $drawn->($y_with_child, sub { $box->('X', undef) });
    is( $drawn->($y_with_child), [qw(C Y)], 'removing it next frame just removes it' );
    is( $drawn->(), [qw(C Y)], 'an element that kept its exit transition still exits' );
    Clay_SetTransitionHandlers();
};

subtest 'a duplicate id without a transition leaves the transition of the first element alone' => sub {
    my $own = Clay_Initialize(Clay_MinMemorySize(), { width => 100, height => 100 }, sub { });
    my $calls = 0;
    Clay_SetTransitionHandlers(sub ($args, $userdata) { $calls++; 0 }, sub ($target, $properties, $userdata) { $target });
    my $enter = { duration => 1, properties => CLAY_TRANSITION_PROPERTY_BACKGROUND_COLOR, enter => { hasSetInitial => 1 } };
    my $box = sub ($transition) {
        Clay__OpenElementWithId( Clay_GetElementId('twin') );
        Clay__ConfigureOpenElement({ layout => { sizing => { width => sizing_fixed(20), height => sizing_fixed(20) } },
            backgroundColor => [200, 0, 0, 255], ($transition ? (transition => $transition) : ()) });
        Clay__CloseElement();
    };
    my $frame = sub (@boxes) {
        Clay_BeginLayout();
        Clay__OpenElementWithId( Clay_GetElementId('twins') );
        Clay__ConfigureOpenElement({});
        $_->() for @boxes;
        Clay__CloseElement();
        Clay_EndLayout(0.016);
    };
    $frame->();
    $frame->(sub { $box->($enter) });                                  # twin enters
    $frame->(sub { $box->($enter) }, sub { $box->(undef) });           # and a second twin has no transition
    is( $calls, 1, 'the enter transition of the first twin runs on' );
    Clay_SetCurrentContext($ctx);
};

# A context with a small element count and an error handler collecting
# error types. Clay_Initialize takes the counts of the current context, so
# they are set on $ctx for the call and restored.
sub small_context ($element_count, $errors) {
    my ($elements, $words) = (Clay_GetMaxElementCount(), Clay_GetMaxMeasureTextCacheWordCount());
    Clay_SetMaxElementCount($element_count);
    Clay_SetMaxMeasureTextCacheWordCount(64);
    my $small = Clay_Initialize(Clay_MinMemorySize(), { width => 400, height => 300 },
        sub ($error, $userdata) { push @$errors, $error->{errorType} });
    Clay_SetCurrentContext($ctx);
    Clay_SetMaxElementCount($elements);
    Clay_SetMaxMeasureTextCacheWordCount($words);
    Clay_SetCurrentContext($small);
    return $small;
}

subtest 'exiting elements that do not fit into the element count lose their exit' => sub {
    my @errors;
    my $small = small_context(64, \@errors);
    Clay_SetTransitionHandlers(sub { 0 }, undef, sub ($initial, $properties, $userdata) { $initial });
    my $exit = { duration => 1, properties => CLAY_TRANSITION_PROPERTY_BACKGROUND_COLOR, exit => { hasSetFinal => 1 } };
    my $box = sub ($name, $transition, @children) {
        Clay__OpenElementWithId( Clay_GetElementId($name) );
        Clay__ConfigureOpenElement({ layout => { sizing => { width => sizing_fixed(5), height => sizing_fixed(5) } },
            backgroundColor => [200, 0, 0, 255], ($transition ? (transition => $transition) : ()) });
        $_->() for @children;
        Clay__CloseElement();
    };
    my @pointer_over;
    for my $frame (1 .. 4) {
        Clay_BeginLayout();
        $box->('E', $exit, sub { $box->("e$_", undef) for 1 .. 20 }) if $frame < 3;    # 21 clones next to 57 elements
        $box->("p$_", undef) for 1 .. 35;
        Clay_EndLayout(0.016);
        my $target = Clay_GetElementData( Clay_GetElementId('p30') )->{boundingBox};
        Clay_SetPointerState([ $target->{x} + 1, $target->{y} + 1 ], 0);
        push @pointer_over, [ map { $_->{stringId} } @{ Clay_GetPointerOverIds() } ];
    }
    is( $errors[0], CLAY_ERROR_TYPE_ELEMENTS_CAPACITY_EXCEEDED, 'the error handler hears that the clones do not fit' );
    is( \@pointer_over, [ [], [], ([ 'Clay__RootContainer', 'p30' ]) x 2 ],
        'Clay ignores the pointer after those frames, and finds p30 once E is gone' );
    Clay_SetCurrentContext($ctx);
};

subtest 'memory stays bounded while exit transitions keep running' => sub {
    Clay_SetTransitionHandlers(sub ($args, $userdata) { $args->{elapsedTime} >= $args->{duration} }, undef,
        sub ($initial, $properties, $userdata) { $initial });
    for my $frame (1 .. 200) {
        Clay_BeginLayout();
        Clay__OpenElementWithId( Clay_GetElementId("toast$frame") );
        Clay__ConfigureOpenElement({ transition => { duration => 0.1, properties => CLAY_TRANSITION_PROPERTY_X,
                                                     exit => { hasSetFinal => 1 } } });
        Clay__OpenTextElement("toast $frame " . ("x" x 5000), {});
        Clay__CloseElement();
        Clay_EndLayout(0.016);
    }
    my $chunks = Clay::XS::_context_stats($ctx)->{arena_chunks};
    ok( $chunks <= 16, "a new exiting toast every frame keeps $chunks text chunks, not one per frame" );
    Clay_SetTransitionHandlers();
};

subtest 'exits survive frames over the element cap' => sub {
    Clay_SetTransitionHandlers(sub { 0 }, undef, sub ($initial, $properties, $userdata) { $initial });
    my $small = Clay_Initialize(Clay_MinMemorySize(), { width => 100, height => 100 }, sub { });
    Clay_SetMeasureTextFunction(sub { return { width => 8, height => 10 } });
    for my $frame (1 .. 3) {
        Clay_BeginLayout();
        Clay__OpenElementWithId( Clay_GetElementId("E") );
        Clay__ConfigureOpenElement({ transition => { duration => 1, properties => CLAY_TRANSITION_PROPERTY_X,
                                                     exit => { hasSetFinal => 1 } } });
        Clay__OpenTextElement("text of E", {});
        for (1 .. 10_000) { Clay__OpenElement(); Clay__CloseElement() }
        Clay__CloseElement();
        Clay_EndLayout(0.016);
    }
    pass( 'three frames over the cap with an exiting element' );
    Clay_SetCurrentContext($ctx);
    Clay_SetTransitionHandlers();
};

# -----------------------------------------------------------------------------
# What the handler writes into current is what gets drawn.
# -----------------------------------------------------------------------------

subtest 'the state the handler writes is drawn' => sub {
    Clay_SetTransitionHandlers(sub ($args, $userdata) {
        $args->{current}{backgroundColor} = { r => 1, g => 2, b => 3, a => 255 };
        return 0;
    });
    my $colour_of = sub ($bg) {
        Clay_BeginLayout();
        build_frame($bg);
        my ($rect) = grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_RECTANGLE } @{ Clay_EndLayout(0.016) };
        return $rect->{renderData}{backgroundColor};
    };
    $colour_of->([255, 0, 0, 255]);
    is( $colour_of->([0, 255, 0, 255]), { r => 1, g => 2, b => 3, a => 255 },
        'the rectangle has the colour the handler set' );
    Clay_SetTransitionHandlers();
};

subtest 'without handlers a transition key changes nothing: the new value shows at once' => sub {
    my $colour_of = sub ($bg) {
        Clay_BeginLayout();
        build_frame($bg);
        my ($rect) = grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_RECTANGLE } @{ Clay_EndLayout(0.016) };
        return $rect->{renderData}{backgroundColor};
    };
    $colour_of->([255, 0, 0, 255]);
    is( $colour_of->([0, 0, 255, 255]), { r => 0, g => 0, b => 255, a => 255 }, 'the frame after a change shows the new colour' );

    # Handlers removed while a transition runs: the element shows what it
    # declares, not a stale mid-transition value.
    Clay_SetTransitionHandlers(sub ($args, $userdata) { $args->{current}{backgroundColor} = { r => 9, g => 9, b => 9, a => 255 }; return 0 });
    $colour_of->([255, 0, 0, 255]);
    is( $colour_of->([0, 255, 0, 255]), { r => 9, g => 9, b => 9, a => 255 }, 'with a handler, its state is drawn' );
    Clay_SetTransitionHandlers();
    is( $colour_of->([0, 0, 255, 255]), { r => 0, g => 0, b => 255, a => 255 }, 'without it, the declared colour is drawn again' );
};

# -----------------------------------------------------------------------------
# Two upstream transition bugs fixed by patches/0004-clay-upstream-fixes.patch.
# -----------------------------------------------------------------------------

sub chip ($name, $transition) {
    Clay__OpenElementWithId( Clay_GetElementId($name) );
    Clay__ConfigureOpenElement({
        layout          => { sizing => { width => sizing_fixed(10), height => sizing_fixed(10) } },
        backgroundColor => [9, 9, 9, 255],
        transition      => { properties => CLAY_TRANSITION_PROPERTY_BACKGROUND_COLOR, %$transition },
    });
    Clay__CloseElement();
}

sub chips_frame (@chips) {
    Clay_BeginLayout();
    Clay__OpenElementWithId( Clay_GetElementId("root") );
    Clay__ConfigureOpenElement({ layout => { sizing => { width => sizing_fixed(100), height => sizing_fixed(100) } } });
        chip(@$_) for @chips;
    Clay__CloseElement();
    Clay_EndLayout(0.1);
}

subtest 'a completing exit does not skip another running transition' => sub {
    my @calls;    # handler calls per frame
    Clay_SetTransitionHandlers(sub ($args, $userdata) { $calls[-1]++; return $args->{elapsedTime} >= $args->{duration} },
        undef, sub ($initial, $properties, $userdata) { return $initial });
    my $exiting  = [ A => { duration => 0.25, exit => { hasSetFinal => 1 } } ];
    my $entering = [ B => { duration => 1, enter => { hasSetInitial => 1 } } ];
    push @calls, 0; chips_frame($exiting);
    push @calls, 0; chips_frame($exiting);
    for (1 .. 6) { push @calls, 0; chips_frame($entering) }
    is( [ @calls[3 .. 7] ], [ 2, 2, 2, 1, 1 ], 'B is handled in the frame A\'s exit completes' );
    Clay_SetTransitionHandlers();
};

subtest 'an exit right after the enter transition starts from the current look' => sub {
    my @exit_initial_alpha;
    Clay_SetTransitionHandlers(
        sub ($args, $userdata) {
            push @exit_initial_alpha, $args->{initial}{backgroundColor}{a} if $args->{transitionState} == CLAY_TRANSITION_STATE_EXITING;
            my $eased = Clay_EaseOut($args);
            $args->{current} = $eased->{current};
            return $eased->{complete};
        },
        sub ($target,  $properties, $userdata) { return { backgroundColor => [0, 0, 0, 0] } },
        sub ($initial, $properties, $userdata) { return { backgroundColor => [0, 0, 0, 0] } },
    );
    my $fading = [ C => { duration => 0.2, enter => { hasSetInitial => 1 }, exit => { hasSetFinal => 1 } } ];
    chips_frame();
    chips_frame($fading) for 1 .. 4;    # the enter runs 0.2 s and completes
    chips_frame() for 1 .. 2;           # removed right after
    is( $exit_initial_alpha[0], 255, 'the exit fades out from opaque, not from the transparent enter state' );
    Clay_SetTransitionHandlers();
};

done_testing;
