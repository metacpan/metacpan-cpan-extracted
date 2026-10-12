use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Clay::XS qw(:all);

# -----------------------------------------------------------------------------
# The full Init -> BeginLayout -> Element -> EndLayout cycle.
#
# We declare a single root rectangle of fixed size and confirm exactly one
# RECTANGLE render command is emitted with the bounding box we expect.
# -----------------------------------------------------------------------------

my @errors;
my $ctx = Clay_Initialize(
    Clay_MinMemorySize(),
    { width => 320, height => 240 },
    sub ($err, $userdata) { push @errors, $err },
);

ok( defined $ctx, 'Clay_Initialize returned a context' );
isa_ok( $ctx, ['Clay::XS::Context'], 'context is blessed' );

Clay_SetMeasureTextFunction(sub ($text, $config, $userdata) {
    # Cheap monospace approximation. Sufficient for our test, which
    # does not declare any text elements.
    my $fs = $config->{fontSize} || 16;
    return { width => length($text) * $fs, height => $fs };
});

Clay_BeginLayout();

Clay__OpenElementWithId( Clay_GetElementId("root") );
Clay__ConfigureOpenElement({
    layout => {
        sizing => {
            width  => sizing_fixed(200),
            height => sizing_fixed(100),
        },
    },
    backgroundColor => { r => 10, g => 20, b => 30, a => 255 },
    cornerRadius    => corner_radius_all(4),
});
Clay__CloseElement();

my $commands = Clay_EndLayout(0);

ok( defined $commands && ref($commands) eq 'ARRAY', 'EndLayout returns an arrayref' );
is( scalar(@errors), 0, 'no errors during layout' )
    or diag( "errors: ", join("; ", map { $_->{errorText} } @errors) );

is( scalar(@$commands), 1, 'one render command emitted' );

my $cmd = $commands->[0];
is( $cmd->{commandType}, CLAY_RENDER_COMMAND_TYPE_RECTANGLE, 'command type is RECTANGLE' );
is( $cmd->{boundingBox}{width},  200, 'bounding box width' );
is( $cmd->{boundingBox}{height}, 100, 'bounding box height' );

is( $cmd->{renderData}{backgroundColor}{r}, 10, 'background r' );
is( $cmd->{renderData}{backgroundColor}{a}, 255, 'background a' );
is( $cmd->{renderData}{cornerRadius}{topLeft}, 4, 'corner radius topLeft' );

# Confirm Clay_GetElementData can find the element after end_layout.
my $data = Clay_GetElementData( Clay_GetElementId("root") );
ok( $data->{found}, 'GetElementData found the element' );
is( $data->{boundingBox}{width}, 200, 'GetElementData width matches' );

# -----------------------------------------------------------------------------
# The frame module: frame state and what it retains, seen through
# Clay::XS::_context_stats.
# -----------------------------------------------------------------------------

sub stats ($context) { Clay::XS::_context_stats($context) }

subtest 'frame state' => sub {
    my $context = Clay_Initialize(Clay_MinMemorySize(), [100, 100]);
    Clay_SetMeasureTextFunction(sub { die "measure failed\n" });
    is( stats($context), hash {
        field layout_state => 'complete'; field open_depth => 0; field completed_frames => 0; etc;
    }, 'a new context has completed no frame' );

    Clay_BeginLayout();
    Clay__OpenElement();
    Clay__OpenTextElement('unmeasurable', {});
    is( stats($context), hash { field layout_state => 'declaring'; field open_depth => 1; etc },
        'a begun frame is declaring, with its open elements' );

    like( dies { Clay_BeginLayout() }, qr/^measure failed \(from the previous unfinished frame\)/,
        'the next Clay_BeginLayout re-throws the held error' );
    is( stats($context), hash {
        field layout_state => 'complete'; field open_depth => 0; field completed_frames => 1; etc;
    }, 'after finishing the unfinished frame, with nothing open' );

    Clay_SetMeasureTextFunction(sub { return [1, 1] });
    Clay_BeginLayout();
    Clay_EndLayout();
    is( stats($context), hash { field layout_state => 'complete'; field completed_frames => 2; etc },
        'a completed frame is counted' );
};

subtest 'interned element ids are kept while Clay may still read them' => sub {
    my $context = Clay_Initialize(Clay_MinMemorySize(), [100, 100]);
    my $frame = sub (@names) {
        Clay_BeginLayout();
        my $interned = stats($context)->{interned_ids};
        for my $name (@names) {
            Clay__OpenElementWithId(Clay_GetElementId($name));
            Clay__ConfigureOpenElement({ layout => { sizing => { width => sizing_fixed(50), height => sizing_fixed(50) } } });
            Clay__CloseElement();
        }
        Clay_EndLayout();
        return $interned;
    };
    $frame->('kept', 'gone') for 1 .. 3;
    is( $frame->('kept'), 2, 'an id is kept in the first frame without it' );
    is( $frame->('kept'), 2, 'and in the second' );
    is( $frame->('kept'), 1, 'and dropped when the third begins' );

    $frame->('kept', 'hovered') for 1 .. 3;
    Clay_SetPointerState([60, 10], 0);
    ok( ( grep { $_->{stringId} eq 'hovered' } @{ Clay_GetPointerOverIds() } ), 'the pointer is over an element' );
    is( [ map { $frame->('kept') } 1 .. 4 ], [ 2, 2, 2, 2 ], 'its id is kept while it is in the pointer-over list' );
    Clay_SetPointerState([60, 10], 0);
    is( $frame->('kept'), 1, 'and dropped once it is not' );
};

done_testing;
