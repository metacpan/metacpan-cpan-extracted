use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;
use Scalar::Util qw(weaken);

use Clay::XS qw(:all);

# -----------------------------------------------------------------------------
# Per-element hover callbacks via Clay_OnHover.
#
# The trampoline forwards to Perl with (element_id, pointer_data, userdata).
# We register two different hover handlers on two different elements,
# move the pointer into each, and confirm only the matching one fires.
# -----------------------------------------------------------------------------

my $ctx = Clay_Initialize(
    Clay_MinMemorySize(),
    { width => 200, height => 200 },
    sub { },
);
Clay_SetMeasureTextFunction(sub { return { width => 0, height => 0 } });

my @red_calls;
my @blue_calls;

sub build () {
    Clay__OpenElementWithId( Clay_GetElementId("root") );
    Clay__ConfigureOpenElement({
        layout => {
            sizing          => { width => sizing_fixed(200), height => sizing_fixed(100) },
            layoutDirection => CLAY_LEFT_TO_RIGHT,
        },
    });

        Clay__OpenElementWithId( Clay_GetElementId("red") );
        Clay__ConfigureOpenElement({
            layout => { sizing => { width => sizing_fixed(100), height => sizing_fixed(100) } },
        });
        Clay_OnHover(sub ($id, $pointer, $userdata) {
            push @red_calls, { id => $id->{id}, pos => $pointer->{position}, ud => $userdata };
        }, "red-payload");
        Clay__CloseElement();

        Clay__OpenElementWithId( Clay_GetElementId("blue") );
        Clay__ConfigureOpenElement({
            layout => { sizing => { width => sizing_fixed(100), height => sizing_fixed(100) } },
        });
        Clay_OnHover(sub ($id, $pointer, $userdata) {
            push @blue_calls, { id => $id->{id}, pos => $pointer->{position}, ud => $userdata };
        }, "blue-payload");
        Clay__CloseElement();

    Clay__CloseElement();
}

# Frame 1: build geometry.
Clay_BeginLayout();
build();
Clay_EndLayout(0);

# Frame 2: hover over the red element.
Clay_SetPointerState({ x => 25, y => 25 }, 0);
Clay_BeginLayout();
build();
Clay_EndLayout(0);

is( scalar(@red_calls),  1, 'red handler fired once' );
is( scalar(@blue_calls), 0, 'blue handler not fired' );

is( $red_calls[0]{ud}, 'red-payload', 'red userdata payload received' );
is( $red_calls[0]{id}, Clay_GetElementId("red")->{id}, 'red callback got matching id' );

# Frame 3: hover over the blue element.
@red_calls = ();
Clay_SetPointerState({ x => 150, y => 25 }, 0);
Clay_BeginLayout();
build();
Clay_EndLayout(0);

is( scalar(@red_calls),  0, 'red handler no longer firing' );
is( scalar(@blue_calls), 1, 'blue handler fired once' );

# -----------------------------------------------------------------------------
# A hover callback that is not registered again is released after a few
# frames; one that is registered every frame is kept.
# -----------------------------------------------------------------------------

subtest 'hover callbacks that are not re-registered are released' => sub {
    my $weak_dropped;
    my $kept_calls = 0;
    my $frame = sub ($register_dropped) {
        Clay_BeginLayout();
        Clay__OpenElementWithId( Clay_GetElementId("sweep-kept") );
        Clay__ConfigureOpenElement({ layout => { sizing => { width => sizing_fixed(50), height => sizing_fixed(50) } } });
        Clay_OnHover(sub { $kept_calls++ }, undef);
        Clay__CloseElement();
        Clay__OpenElementWithId( Clay_GetElementId("sweep-dropped") );
        if ($register_dropped) {
            my $object = {};
            weaken($weak_dropped = $object);
            Clay_OnHover(sub { $object }, undef);
        }
        Clay__CloseElement();
        Clay_EndLayout(0);
    };
    $frame->(1);
    ok( defined $weak_dropped, 'a registered callback is held' );
    $frame->(0) for 1 .. 4;
    is( $weak_dropped, undef, 'the callback registered once was released' );
    Clay_SetPointerState({ x => 10, y => 10 }, 0);
    is( $kept_calls, 1, 'the callback registered every frame still fires' );
};

subtest 'hover entries are kept for one frame after their last registration' => sub {
    my $frame = sub ($register) {
        Clay_BeginLayout();
        my $entries = Clay::XS::_context_stats($ctx)->{hover_entries};
        Clay__OpenElementWithId( Clay_GetElementId("window-kept") );
        Clay_OnHover(sub { }, undef);
        Clay__CloseElement();
        if ($register) {
            Clay__OpenElementWithId( Clay_GetElementId("window-dropped") );
            Clay_OnHover(sub { }, undef);
            Clay__CloseElement();
        }
        Clay_EndLayout(0);
        return $entries;
    };
    $frame->(1) for 1 .. 3;
    my $kept = Clay::XS::_context_stats($ctx)->{hover_entries};
    is( $frame->(0), $kept,     'an entry is kept in the first frame without it' );
    is( $frame->(0), $kept - 1, 'and dropped when the second begins' );
};

done_testing;
