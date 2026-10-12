use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Clay::XS qw(:all);

# -----------------------------------------------------------------------------
# A rich ElementDeclaration passes through Clay's open/configure/close
# pipeline without raising errors. Clay has no inspector for the marshalled
# struct, so the check is "Clay accepts the declaration and produces the
# matching render commands": their shape verifies that borders, corner
# radius, etc. were marshalled correctly. Invalid input croaks with the
# struct and field named.
# -----------------------------------------------------------------------------

my @errors;
my $ctx = Clay_Initialize(
    Clay_MinMemorySize(),
    { width => 400, height => 300 },
    sub ($err, $userdata) { push @errors, $err },
);
Clay_SetMeasureTextFunction(sub { return { width => 0, height => 0 } });

Clay_BeginLayout();

Clay__OpenElementWithId( Clay_GetElementId("container") );
Clay__ConfigureOpenElement({
    layout => {
        sizing  => {
            width  => sizing_fixed(300),
            height => sizing_fixed(200),
        },
        padding         => { left => 10, right => 10, top => 5, bottom => 5 },
        childGap        => 4,
        childAlignment  => { x => CLAY_ALIGN_X_CENTER, y => CLAY_ALIGN_Y_CENTER },
        layoutDirection => CLAY_TOP_TO_BOTTOM,
    },
    backgroundColor => [40, 50, 60, 200],
    overlayColor    => [255, 0, 0, 50],
    cornerRadius    => { topLeft => 6, topRight => 6, bottomLeft => 0, bottomRight => 0 },
    border          => {
        color => [100, 100, 100, 255],
        width => { left => 1, right => 1, top => 1, bottom => 1, betweenChildren => 0 },
    },
});
Clay__CloseElement();

my $cmds = Clay_EndLayout(0);

is( scalar(@errors), 0, 'no Clay errors for rich declaration' );
ok( scalar(@$cmds) >= 2, 'at least 2 commands emitted (rect + border + overlay markers)' );

# A backgroundColor + cornerRadius produces a RECTANGLE command.
my ($rect) = grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_RECTANGLE } @$cmds;
ok( defined $rect, 'rectangle command present' );
is( $rect->{renderData}{backgroundColor}{r},   40, 'background r' );
is( $rect->{renderData}{cornerRadius}{topLeft}, 6, 'cornerRadius topLeft' );
is( $rect->{renderData}{cornerRadius}{bottomRight}, 0, 'cornerRadius bottomRight' );

# A border block produces a BORDER command.
my ($border) = grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_BORDER } @$cmds;
ok( defined $border, 'border command present' );
is( $border->{renderData}{color}{r}, 100, 'border color r' );
is( $border->{renderData}{width}{left}, 1, 'border width left' );

# An overlayColor produces OVERLAY_COLOR_START + END markers.
my @overlay = grep {
    $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_OVERLAY_COLOR_START
 || $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_OVERLAY_COLOR_END
} @$cmds;
is( scalar(@overlay), 2, 'overlay start + end markers emitted' );

# -----------------------------------------------------------------------------
# Floating element check.
# -----------------------------------------------------------------------------

Clay_BeginLayout();
Clay__OpenElementWithId( Clay_GetElementId("parent") );
Clay__ConfigureOpenElement({
    layout => { sizing => { width => sizing_fixed(200), height => sizing_fixed(200) } },
});
    Clay__OpenElementWithId( Clay_GetElementId("floater") );
    Clay__ConfigureOpenElement({
        layout   => { sizing => { width => sizing_fixed(50), height => sizing_fixed(50) } },
        floating => {
            attachTo     => CLAY_ATTACH_TO_PARENT,
            attachPoints => {
                element => CLAY_ATTACH_POINT_LEFT_TOP,
                parent  => CLAY_ATTACH_POINT_LEFT_TOP,
            },
            offset       => { x => 10, y => 10 },
            zIndex       => 5,
        },
        backgroundColor => [200, 200, 0, 255],
    });
    Clay__CloseElement();
Clay__CloseElement();

my $cmds2 = Clay_EndLayout(0);
my @floater_rects = grep {
       $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_RECTANGLE
    && $_->{boundingBox}{x} > 0
    && $_->{boundingBox}{width} == 50
} @$cmds2;
ok( scalar(@floater_rects) >= 1, 'floating rectangle emitted somewhere' );
is( $floater_rects[0]{zIndex}, 5, 'zIndex propagated from floating config' );

# -----------------------------------------------------------------------------
# Every value is range-checked at the boundary; errors name struct and field.
# -----------------------------------------------------------------------------

sub configure_error ($decl) {
    Clay_BeginLayout();
    Clay__OpenElementWithId( Clay_GetElementId("checked") );
    my $error = dies { Clay__ConfigureOpenElement($decl) };
    Clay__CloseElement();
    Clay_EndLayout(0);
    return $error;
}

subtest 'out-of-range values croak with struct and field' => sub {
    like( configure_error({ layout => { padding => { left => -8 } } }),
        qr/Clay_ElementDeclaration\.layout\.padding\.left: expected an integer in 0\.\.65535, got '-8'/,
        'negative padding (uint16)' );
    isa_ok( configure_error({ layout => { childGap => -1 } }), 'Clay::XS::StructError' );
    like( configure_error({ layout => { childGap => 70000 } }),
        qr/layout\.childGap: expected an integer in 0\.\.65535/, 'childGap above 65535' );
    like( configure_error({ layout => { layoutDirection => 257 } }),
        qr/layout\.layoutDirection: expected an integer in 0\.\.3/, 'enum out of range' );
    like( configure_error({ floating => { zIndex => 40000 } }),
        qr/floating\.zIndex: expected an integer in -32768\.\.32767/, 'zIndex beyond int16' );
    like( configure_error({ sizingGroup => { width => -1 } }),
        qr/sizingGroup\.width: expected an integer in 0\.\.4294967295/, 'negative sizing group (uint32)' );
    like( configure_error({ border => { width => { top => 1.5 } } }),
        qr/border\.width\.top: expected an integer/, 'fractional border width' );
    like( configure_error({ backgroundColor => [ 'red', 0, 0, 255 ] }),
        qr/backgroundColor\.r: expected a number in 0\.\.255, got 'red'/, 'non-numeric colour channel' );
    like( configure_error({ cornerRadius => 9**9**9 }),
        qr/cornerRadius: expected a number >= 0/, 'infinite corner radius' );
    Clay_BeginLayout();
    like( dies { Clay__OpenTextElement("x", { fontSize => -1 }) },
        qr/Clay_TextElementConfig\.fontSize: expected an integer in 0\.\.65535/, 'negative fontSize' );
    Clay_EndLayout(0);
    like( dies { Clay_GetElementData({ id => -1 }) },
        qr/element id\.id: expected an integer in 0\.\.4294967295/, 'negative element id' );
};

subtest 'wrong-typed nested values croak' => sub {
    like( configure_error({ floating => { attachPoints => [ 1, 2 ] } }),
        qr/floating\.attachPoints: expected a hash reference/, 'attachPoints must be a hash' );
    like( configure_error({ transition => { duration => 1, enter => 'fade' } }),
        qr/transition\.enter: expected a hash reference, got 'fade'/, 'transition.enter must be a hash' );
    like( configure_error({ transition => { duration => 1, exit => [] } }),
        qr/transition\.exit: expected a hash reference/, 'transition.exit must be a hash' );
    like( configure_error({ layout => { padding => 8 } }),
        qr/layout\.padding: expected a hash reference, got '8'/, 'scalar padding' );
};

subtest 'pointer-sized integers round-trip exactly' => sub {
    my $declare = sub ($user_data) {
        Clay_BeginLayout();
        Clay__OpenElement();
        my $ok = eval {
            Clay__ConfigureOpenElement({ userData => $user_data, backgroundColor => [1, 1, 1, 255],
                layout => { sizing => { width => sizing_fixed(5), height => sizing_fixed(5) } } });
            1;
        };
        my $error = $@;
        Clay__CloseElement();
        my ($rect) = grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_RECTANGLE } @{ Clay_EndLayout() };
        die $error unless $ok;
        return $rect->{userData};
    };
    is( $declare->(2**63), '9223372036854775808', '2**63 comes back unsigned' );
    is( $declare->('18446744073709551615'), '18446744073709551615', 'the largest pointer value as a string' );
    like( dies { $declare->(-1) }, qr/userData: expected an integer in 0\.\./, 'a negative value croaks' );
    like( dies { $declare->(1e30) }, qr/userData: expected an integer in 0\.\./, 'a value beyond a pointer croaks' );
};

subtest 'floating.parentId accepts an element id hash' => sub {
    Clay_BeginLayout();
    Clay__OpenElementWithId( Clay_GetElementId("anchor") );
    Clay__ConfigureOpenElement({
        layout => { sizing => { width => sizing_fixed(40), height => sizing_fixed(40) } },
    });
    Clay__CloseElement();
    Clay__OpenElementWithId( Clay_GetElementId("attached") );
    Clay__ConfigureOpenElement({
        layout   => { sizing => { width => sizing_fixed(10), height => sizing_fixed(10) } },
        floating => {
            attachTo     => CLAY_ATTACH_TO_ELEMENT_WITH_ID,
            parentId     => Clay_GetElementId("anchor"),
            attachPoints => { element => CLAY_ATTACH_POINT_LEFT_TOP, parent => CLAY_ATTACH_POINT_RIGHT_TOP },
        },
    });
    Clay__CloseElement();
    Clay_EndLayout(0);
    is( Clay_GetElementData( Clay_GetElementId("attached") )->{boundingBox}{x}, 40,
        'attached to the right edge of the element named by the id hash' );
};

subtest 'an exiting element is drawn underneath its siblings by default' => sub {
    Clay_SetTransitionHandlers(sub { 0 }, undef, sub ($initial, $properties, $userdata) { $initial });
    my $frame = sub ($with_leaving) {
        Clay_BeginLayout();
        Clay__OpenElementWithId( Clay_GetElementId("row") );
        Clay__OpenElementWithId( Clay_GetElementId("staying") );
        Clay__ConfigureOpenElement({
            layout          => { sizing => { width => sizing_fixed(30), height => sizing_fixed(10) } },
            backgroundColor => [1, 1, 1, 255],
        });
        Clay__CloseElement();
        if ($with_leaving) {
            Clay__OpenElementWithId( Clay_GetElementId("leaving") );
            Clay__ConfigureOpenElement({
                layout          => { sizing => { width => sizing_fixed(20), height => sizing_fixed(10) } },
                backgroundColor => [2, 2, 2, 255],
                transition      => { duration => 1, properties => CLAY_TRANSITION_PROPERTY_X, exit => { hasSetFinal => 1 } },
            });
            Clay__CloseElement();
        }
        Clay__CloseElement();
        return [ map { $_->{renderData}{backgroundColor}{r} }
                 grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_RECTANGLE } @{ Clay_EndLayout(0.016) } ];
    };
    is( $frame->(1), [1, 2], 'declared order while both are present' ) for 1 .. 2;
    is( $frame->(0), [2, 1],
        'the exiting element is drawn first (CLAY_EXIT_TRANSITION_ORDERING_UNDERNEATH_SIBLINGS, the C default)' );
    Clay_SetTransitionHandlers();
};

done_testing;
