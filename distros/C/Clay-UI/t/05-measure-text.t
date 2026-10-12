use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use lib "t/lib";
use Clay::Test::ChildPerl qw(child_perl);

use Clay::XS qw(:all);

# -----------------------------------------------------------------------------
# The Perl-side text measurement callback.
#
# Install a measurer that records every call, returns a deterministic
# size, and verifies the contract: each text element emitted in the
# layout triggers at least one measurement, and the returned text
# render command reflects the measured size.
# -----------------------------------------------------------------------------

my @calls;

my $ctx = Clay_Initialize(
    Clay_MinMemorySize(),
    { width => 800, height => 200 },
    sub { },
);

Clay_SetMeasureTextFunction(sub ($text, $config, $userdata) {
    push @calls, {
        text       => $text,
        font_size  => $config->{fontSize},
        font_id    => $config->{fontId},
        user_data  => $userdata,
    };
    return { width => length($text) * $config->{fontSize}, height => $config->{fontSize} };
}, "user-payload-42");

Clay_BeginLayout();
Clay__OpenElementWithId( Clay_GetElementId("root") );
Clay__ConfigureOpenElement({
    layout => { sizing => { width => sizing_grow(), height => sizing_grow() } },
});
    Clay__OpenTextElement(
        "hello",
        { fontSize => 20, fontId => 7, textColor => [0,0,0,255] },
    );
Clay__CloseElement();
my $cmds = Clay_EndLayout(0);

# The measurer must have been called at least once.
ok( scalar(@calls) > 0, 'measurer was invoked' );

# Every call must have observed the configured fontSize, fontId, and userdata.
my $first = $calls[0];
is( $first->{font_size},  20, 'fontSize propagates to measurer' );
is( $first->{font_id},     7, 'fontId propagates to measurer' );
is( $first->{user_data}, 'user-payload-42', 'userdata propagates' );

# The emitted text command should reflect the measured dimensions.
my ($text_cmd) = grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_TEXT } @$cmds;
ok( defined $text_cmd, 'text render command emitted' );
is( $text_cmd->{renderData}{fontSize}, 20, 'text command fontSize matches' );

sub text_frame ($text, $config) {
    Clay_BeginLayout();
    Clay__OpenElementWithId( Clay_GetElementId("root") );
    Clay__ConfigureOpenElement({
        layout => { sizing => { width => sizing_grow(), height => sizing_grow() } },
    });
        Clay__OpenTextElement($text, $config);
    Clay__CloseElement();
    my $frame = Clay_EndLayout(0);
    my ($cmd) = grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_TEXT } @$frame;
    return $cmd;
}

# A failing measurer makes Clay_EndLayout croak with its error; once the
# measurer works again the text is measured afresh (no cached zero size).
Clay_SetMeasureTextFunction(sub { die "measurer exploded\n" });
like( dies { text_frame("ouch", { fontSize => 12 }) }, qr/^measurer exploded$/,
    'Clay_EndLayout croaks with the measurer error' );

Clay_SetMeasureTextFunction(sub ($text, $config, $userdata) {
    return { width => length($text) * 10, height => 12 };
});
is( text_frame("ouch", { fontSize => 12 })->{boundingBox}{width}, 40,
    'a working measurer measures the same text correctly on the next frame' );

# Strings are characters: the measurer sees the decoded text.
{
    use utf8;
    my @seen;
    Clay_SetMeasureTextFunction(sub ($text, $config, $userdata) {
        push @seen, $text;
        return { width => length($text), height => 10 };
    });
    text_frame("日本語 déjà", { fontSize => 10 });
    ok( ( grep { $_ eq "日本語" } @seen ), 'measurer receives CJK characters' );
    ok( ( grep { $_ eq "déjà" } @seen ),   'measurer receives accented characters' );
}

# A measurer that calls Clay_GetElementId while Clay reads the text must not
# disturb the text Clay holds.
Clay_SetMeasureTextFunction(sub ($text, $config, $userdata) {
    Clay_GetElementId("measure-" . ("x" x 64)) for 1 .. 50;
    return { width => length($text), height => 10 };
});
is( text_frame("unchanged words here", { fontSize => 10 })->{renderData}{stringContents},
    "unchanged words here", 'text survives id lookups from inside the measurer' );

Clay_SetMeasureTextFunction(sub { return });
like( dies { text_frame("forgotten", { fontSize => 10 }) },
    qr/measure_text callback result: expected a hash or array reference, got undef/,
    'a measurer that returns nothing croaks instead of measuring 0x0' );

# In a fresh process, before any context installed a measurer, text is
# reported all the same (Clay's measure function pointer is process-wide).
my $code = <<'PERL';
use Clay::XS qw(:all);
my $ctx = Clay_Initialize(Clay_MinMemorySize(), [10, 10]);
Clay_BeginLayout(); Clay__OpenTextElement('x', {});
print eval { Clay_EndLayout(); 1 } ? "no error\n" : $@;
PERL
open my $child, '-|', child_perl($code) or die "cannot run $^X: $!";
my $fresh = do { local $/; <$child> };
close $child;
like( $fresh, qr/text measured but no measure_text function is installed for this context/,
    'a fresh process without a measurer croaks' );

# CLAY_TEXT_WRAP_NONE never breaks a line, lineHeight boxes stack from the
# top (patches/0004-clay-upstream-fixes.patch).
Clay_SetMeasureTextFunction(sub ($text, $config, $userdata) {
    return { width => 5 * length($text), height => $config->{fontSize} };
});

subtest 'CLAY_TEXT_WRAP_NONE keeps newlines on one line' => sub {
    my $cmd = text_frame("hi\nworld foo bar", { fontSize => 10, wrapMode => CLAY_TEXT_WRAP_NONE });
    is( $cmd->{renderData}{stringContents}, "hi\nworld foo bar", 'one TEXT command with the whole text' );
    is( $cmd->{boundingBox}{width}, 80, 'measured as one string' );
    is( text_frame("hi\nworld foo bar", { fontSize => 10, wrapMode => CLAY_TEXT_WRAP_NEWLINES })->{renderData}{stringContents}, 'hi',
        'NEWLINES still breaks there' );
};

subtest 'lineHeight boxes stay inside the element' => sub {
    Clay_BeginLayout();
    Clay__OpenElementWithId( Clay_GetElementId("root") );
    Clay__ConfigureOpenElement({ layout => { sizing => { width => sizing_fixed(200), height => sizing_fit() } } });
        Clay__OpenTextElement("one\ntwo", { fontSize => 10, lineHeight => 30, wrapMode => CLAY_TEXT_WRAP_NEWLINES });
    Clay__CloseElement();
    my @lines = grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_TEXT } @{ Clay_EndLayout(0) };
    is( Clay_GetElementData( Clay_GetElementId("root") )->{boundingBox}{height}, 60, 'two lines of 30' );
    is( [ map { [ $_->{boundingBox}{y}, $_->{boundingBox}{height} ] } @lines ], [ [0, 30], [30, 30] ], 'boxes at 0 and 30, each 30 tall' );
};

# stringOffset is where each wrapped line starts in the element's text,
# counted in characters.
subtest 'stringOffset locates every line in the text' => sub {
    Clay_BeginLayout();
    Clay__OpenElementWithId( Clay_GetElementId("root") );
    Clay__ConfigureOpenElement({ layout => { sizing => { width => sizing_fixed(30), height => sizing_fit() } } });
        Clay__OpenTextElement("\x{e9}t\x{e9} chaud\nnuit froide", { fontSize => 10 });
    Clay__CloseElement();
    my @lines = grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_TEXT } @{ Clay_EndLayout(0) };
    is( [ map { [ $_->{renderData}{stringOffset}, $_->{renderData}{stringContents} ] } @lines ],
        [ [ 0, "\x{e9}t\x{e9}" ], [ 4, 'chaud' ], [ 10, 'nuit' ], [ 15, 'froide' ] ],
        'offsets count characters, not bytes, across wraps and newlines' );
    is( text_frame("whole", { fontSize => 10 })->{renderData}{stringOffset}, 0, 'an unbroken text starts at 0' );
};

subtest 'Latin-1 strings reach Clay as characters and are never upgraded' => sub {
    my ($text, $id) = ("caf\x{e9}", "n\x{e9}");
    my ($upgraded_text, $upgraded_id) = ($text, $id);
    utf8::upgrade($_) for $upgraded_text, $upgraded_id;
    is( Clay__HashString($id, 7), Clay__HashString($upgraded_id, 7), 'Clay__HashString hashes the characters' );
    is( Clay_GetElementId($id), Clay_GetElementId($upgraded_id), 'so does Clay_GetElementId' );
    is( text_frame($text, { fontSize => 10 })->{renderData}{stringContents}, $upgraded_text, 'text arrives as its characters' );

    Clay_BeginLayout();
    Clay__OpenElementWithId({ %{ Clay_GetElementId($upgraded_id) }, stringId => $id });
    Clay__ConfigureOpenElement({ layout => { sizing => { width => sizing_fixed(10), height => sizing_fixed(10) } } });
    Clay__CloseElement();
    Clay_EndLayout(0);
    Clay_SetPointerState([1, 1], 0);
    is( [ map { $_->{stringId} } @{ Clay_GetPointerOverIds() } ], [ 'Clay__RootContainer', $upgraded_id ],
        'an interned id string keeps its characters' );
    ok( !utf8::is_utf8($text) && !utf8::is_utf8($id), 'neither caller string was upgraded' );
};

subtest 'stringOffset counts every text from its own start' => sub {
    Clay_BeginLayout();
    Clay__OpenElementWithId( Clay_GetElementId("root") );
    Clay__ConfigureOpenElement({ layout => { sizing => { width => sizing_fixed(30), height => sizing_fit() },
                                             layoutDirection => CLAY_TOP_TO_BOTTOM } });
        Clay__OpenTextElement("one two three", { fontSize => 10 });
        Clay__OpenTextElement("\x{fc}ber \x{e4}rger", { fontSize => 10 });
        Clay__OpenTextElement("four five", { fontSize => 10 });
    Clay__CloseElement();
    my @lines = grep { $_->{commandType} == CLAY_RENDER_COMMAND_TYPE_TEXT } @{ Clay_EndLayout(0) };
    is( [ map { [ $_->{renderData}{stringOffset}, $_->{renderData}{stringContents} ] } @lines ],
        [ [ 0, 'one' ], [ 4, 'two' ], [ 8, 'three' ], [ 0, "\x{fc}ber" ], [ 5, "\x{e4}rger" ], [ 0, 'four' ], [ 5, 'five' ] ],
        'ASCII and non-ASCII texts in a row, each line at its character offset' );
};

done_testing;
