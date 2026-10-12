package Clay::XS;

use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Exporter 5.57 'import';
use XSLoader;

our $VERSION = '0.06';

XSLoader::load(__PACKAGE__, $VERSION);

# -----------------------------------------------------------------------------
# Every function in the XS wrapper guard table (one row per exported
# function) and every constant BOOT installed, under its bare name. Both
# lists come from the XS module, so this runs after XSLoader::load and
# before any import.
#
# The export tag :all gives a caller a flat namespace identical to the
# C header. Most users will want this. Use individual imports if you
# need finer control.
# -----------------------------------------------------------------------------

our @EXPORT_OK = ((sort keys %{ _wrapper_guards() }), _constant_names());

our %EXPORT_TAGS = (
    all => [ @EXPORT_OK ],
);

# A context belongs to the interpreter that created it. Threads must not
# inherit a copy: its DESTROY would free the parent's context.
package Clay::XS::Context {
    sub CLONE_SKIP { 1 }
}

# What src/marshal.c croaks for a struct value it cannot use. Always true,
# so `$@ || ...` keeps it; stringifies like a plain croak message.
package Clay::XS::StructError {
    use overload '""' => \&as_string, bool => sub { 1 }, fallback => 1;

    sub path         ($self) { $self->{path} }
    sub expected     ($self) { $self->{expected} }
    sub got          ($self) { $self->{got} }
    sub hint         ($self) { $self->{hint} }
    sub unknown_keys ($self) { $self->{unknown_keys} }
    sub known_keys   ($self) { $self->{known_keys} }
    sub file         ($self) { $self->{file} }
    sub line         ($self) { $self->{line} }

    sub message ($self) {
        my $message = join('.', @{ $self->{path} }) . ": expected $self->{expected}, got $self->{got}";
        $message .= " ($self->{hint})" if defined $self->{hint};
        return $message;
    }

    sub as_string ($self, @) {
        return $self->message . " at $self->{file} line $self->{line}.\n";
    }
}

1;

__END__

=pod

=head1 NAME

Clay::XS - low-level Perl binding for the Clay C layout library

=head1 SYNOPSIS

    use v5.22;
    use warnings;
    use feature 'signatures';
    no warnings 'experimental::signatures';

    use Clay::XS qw(:all);

    # One context: an independent Clay instance with its own memory.
    my $ctx = Clay_Initialize(
        Clay_MinMemorySize(),
        { width => 800, height => 600 },
        sub ($error, $userdata) { die "Clay error: $error->{errorText}\n" },
    );

    # Clay cannot measure text itself. This fake measurer assumes every
    # character is half as wide as the font size.
    Clay_SetMeasureTextFunction(sub ($text, $config, $userdata) {
        return { width => length($text) * $config->{fontSize} / 2, height => $config->{fontSize} };
    });

    # One frame: declare the whole tree, then collect the render commands.
    Clay_BeginLayout();

    Clay__OpenElementWithId(Clay_GetElementId('root'));
    Clay__ConfigureOpenElement({
        layout => {
            sizing          => { width => sizing_grow(), height => sizing_grow() },
            padding         => padding_all(16),
            childGap        => 8,
            layoutDirection => CLAY_TOP_TO_BOTTOM,
        },
        backgroundColor => [240, 240, 240, 255],
    });
    Clay__OpenTextElement('Hello, Clay', { fontSize => 24, textColor => [0, 0, 0, 255] });
    Clay__CloseElement();

    my $commands = Clay_EndLayout(1 / 60);

    for my $command (@$commands) {
        my $box = $command->{boundingBox};
        if ($command->{commandType} == CLAY_RENDER_COMMAND_TYPE_RECTANGLE) {
            say "rectangle at $box->{x},$box->{y} size $box->{width}x$box->{height}";
        }
        elsif ($command->{commandType} == CLAY_RENDER_COMMAND_TYPE_TEXT) {
            say "text '$command->{renderData}{stringContents}' at $box->{x},$box->{y}";
        }
    }

=head1 DESCRIPTION

=head2 What Clay is

Clay (L<https://github.com/nicbarker/clay>) is a small C library that
computes user interface layouts. You describe a tree of boxes (with
sizes, padding, gaps, alignment, borders, text and so on) and Clay
computes where every box goes. Clay draws nothing. It returns a flat
list of drawing instructions, the I<render commands>, which your own
code draws with any graphics library.

Clay works in I<immediate mode>: you declare the complete tree again
for every frame. Clay remembers what it needs between frames (element
positions for hit testing, scroll positions, text measurements,
transitions) on its own.

This distribution vendors Clay v0.14 together with four patches. Three
add features: sizing groups, a wrapping flow layout and a stack layout
(see L</SIZING GROUPS>, L</FLOW LAYOUT> and L</STACK LAYOUT>). The
fourth fixes upstream bugs and so changes some of Clay's behaviour: every
render command of a floating element carries its C<zIndex>, a culled
clip container still emits its scissor commands,
C<CLAY_TEXT_WRAP_NONE> never breaks a line, C<lineHeight> boxes stack
from the element's top, an image or custom element gets no background
rectangle, an exit transition starts from the element's current look,
a floating element may attach to an element declared later in the
frame, and frames that reach the element count, exit transitions and
large sizes can no longer crash or hang Clay (see
L</FUNCTIONS: TRANSITIONS> and L</SIZING GROUPS>). No system library is
needed.

=head2 What this module is

C<Clay::XS> is a thin binding that keeps Clay's names. Every function
in the L</FUNCTIONS> sections that starts with C<Clay_> or C<Clay__>
does what the function of the same name in F<clay.h> does, with these
differences:

=over 4

=item *

Structs are Perl hashes whose keys are the exact C field names
(C<backgroundColor>, C<layoutDirection>, ...). The compact types
C<Clay_Color>, C<Clay_Vector2> and C<Clay_Dimensions> also accept
arrayrefs (C<[r, g, b, a]>, C<[x, y]>, C<[width, height]>). A missing
or undef field means the C zero value, exactly like a C designated
initialiser. Functions that return a struct return a new hash
reference. Every key is listed in L<Clay::XS::Structs>.

=item *

Every value is checked when it crosses into Clay. A bad value croaks
instead of corrupting memory (see L</ELEMENTS AND FRAMES> and
L</STRUCT ERRORS>).

=item *

C<Clay_Initialize> takes an arena capacity in bytes and allocates and
owns the arena itself, so C<Clay_CreateArenaWithCapacityAndMemory> is
not bound. It takes the error handler and its userdata as two separate
arguments and returns a C<Clay::XS::Context> object (see L</CONTEXTS>).

=item *

C<Clay_EndLayout> returns the render commands as an array reference of
hashes (see L</RENDER COMMANDS>), so C<Clay_RenderCommandArray_Get> is
not bound. Its delta time argument is optional.

=item *

Callbacks are Perl code references and userdata is any Perl scalar (see
L</CALLBACKS>).

=item *

C<Clay_SetExternalScrollHandlingEnabled> is bound although F<clay.h>
implements it without declaring it.

=item *

The C macros (C<CLAY()>, C<CLAY_TEXT()>, C<CLAY_ID()>, C<CLAY_SIZING_GROW()>,
...) have no direct Perl form. L</MAPPING C MACROS TO PERL> shows how to
spell each one; the snake_case helpers (C<sizing_grow>, C<padding_all>,
...) replace the value-building macros.

=item *

C<set_scroll_position> replaces the C idiom of writing through the
pointer that C<Clay_GetScrollContainerData> returns, and C<check_struct>
validates a struct without calling Clay.

=back

=head2 Where to go next

=over 4

=item *

L<Clay::UI> is the widget layer of this distribution. You build a tree
of widget objects once, and C<< Clay::UI->render >> declares it to
Clay every frame and turns pointer input into widget events. Most
applications want Clay::UI instead of calling Clay::XS directly.

=item *

L<Clay::Manual> explains Clay's layout model (sizing, padding, gaps,
alignment, floating elements, scrolling, text) step by step.

=item *

L<Clay::Cookbook> has short recipes for common layouts and tasks.

=item *

L<Clay::XS::Structs> documents every struct and every key a
declaration takes, for example L<Clay::XS::Structs/layout>.

=back

=head2 Terms

=over 4

=item context

One independent Clay instance, a C<Clay::XS::Context> object. Almost
every function works on the I<current context>.

=item frame

One pass from C<Clay_BeginLayout> to C<Clay_EndLayout>, during which
you declare the whole tree.

=item element

One box in the layout tree. A I<text element> is a leaf that holds
text.

=item element id

A hash reference C<< { id, offset, baseId, stringId } >> that names an
element, made by C<Clay_GetElementId> and its relatives. Functions that
take an element id want this hash reference.

=item declaration

The hash reference passed to C<Clay__ConfigureOpenElement>; its keys
are those of C<Clay_ElementDeclaration> (see L<Clay::XS::Structs>).

=item layout axis, off axis

The I<layout axis> of an element is the axis along which its
C<layoutDirection> arranges the children: horizontal for
C<CLAY_LEFT_TO_RIGHT> and C<CLAY_LEFT_TO_RIGHT_WRAP>, vertical for
C<CLAY_TOP_TO_BOTTOM>. The I<off axis> is the other one. (Other
layout systems call them the I<main axis> and the I<cross axis>.) Along the
layout axis the children follow one another, so their sizes and the
C<childGap>s add up; on the off axis each child is sized and aligned on
its own within the parent's inner size. C<CLAY_BACK_TO_FRONT> has no layout axis:
it treats both axes as off axes (see L</STACK LAYOUT>).

=item render command

One hash in the array reference C<Clay_EndLayout> returns.

=item renderer

Your code that draws the render commands.

=item callback

A code reference that Clay calls while one of its own functions runs:
the error handler, the measure function, the query-scroll function,
hover callbacks and transition handlers.

=item held error

An exception a callback threw, kept by the context until Clay returns
(see L</ERRORS FROM CALLBACKS>).

=back

=head1 IMPORTING

Nothing is exported by default. Import what you need by name, or
everything with the C<:all> tag:

    use Clay::XS qw(:all);                        # every function and constant
    use Clay::XS qw(Clay_BeginLayout Clay_EndLayout CLAY_TOP_TO_BOTTOM);

C<:all> gives you a flat namespace that matches the C header. Without
an import, call the fully qualified name, for example
C<Clay::XS::Clay_BeginLayout()> or C<Clay::XS::CLAY_TOP_TO_BOTTOM()>.

All constants are plain integer constant subs (see L</CONSTANTS>).

=head1 FUNCTIONS

This section and the next ones describe every exported function, one
heading per function, grouped by topic. Each entry ends with a line of
rules:

=over 4

=item I<Context>

C<none>: works without a context. C<current>: needs a current context
and croaks C<< <function>: no current Clay context; call Clay_Initialize first >> without one. C<optional>: uses the current context when there
is one.

=item I<Frame>

C<any time>; C<inside a frame> (between C<Clay_BeginLayout> and
C<Clay_EndLayout>); C<element open> (inside a frame, with an element
open); C<completed frame> (outside a frame, and the last frame was
finished; see L</ELEMENTS AND FRAMES>).

=item I<In a callback>

C<allowed> or C<refused> (see L</What a callback may do>).

=item I<Held errors>

C<re-thrown> (once the function's Clay call has returned) or C<never>
(see L</ERRORS FROM CALLBACKS>).

=back

Every function that needs a context also croaks
C<< <function>: the current Clay::XS context belongs to a different interpreter/thread (Clay has one process-wide current context) >>, and
C<< <function>: element/word counts changed since Clay_Initialize; call Clay_Initialize again >> (see L</Element and word counts>). The
functions that manage contexts and counts never croak the second
message: C<Clay_Initialize>, C<Clay_SetCurrentContext>,
C<Clay_GetCurrentContext>, C<Clay_MinMemorySize>,
C<Clay_SetMaxElementCount>, C<Clay_GetMaxElementCount>,
C<Clay_SetMaxMeasureTextCacheWordCount> and
C<Clay_GetMaxMeasureTextCacheWordCount>.

A function whose entry names no return value returns nothing (an empty
list in list context, undef in scalar context).

Plain arguments that are not structs (counts, sizes, callbacks) croak
plain strings of the form C<< <function>: <argument>: expected <what>, got <value> >>. Struct arguments croak a L</STRUCT ERRORS> object.

=head1 FUNCTIONS: CONTEXTS AND CAPACITY

=head2 Clay_MinMemorySize

Returns the number of bytes Clay needs for a context.

    my $bytes = Clay_MinMemorySize();

The size depends on the element and measure-cache word counts that the
next C<Clay_Initialize> will use: those of the current context, or
Clay's process-wide defaults (8192 elements and 16384 words, unless
changed with C<Clay_SetMaxElementCount> or
C<Clay_SetMaxMeasureTextCacheWordCount>) when no context is current.

Croaks C<< Clay_MinMemorySize: <n> elements and <m> measure-cache words need about <bytes> bytes of arena; Clay's arena arithmetic is limited to 4 GiB >> for counts that large.

I<Context:> none. I<Frame:> any time. I<In a callback:> allowed.
I<Held errors:> never.

=head2 Clay_Initialize

Creates a new context, makes it current and returns it.

    my $ctx = Clay_Initialize($capacity, $dimensions);
    my $ctx = Clay_Initialize($capacity, $dimensions, $error_handler, $userdata);

=over 4

=item C<$capacity>

The arena size in bytes: an integer of at least C<Clay_MinMemorySize()>.
Clay::XS allocates the arena and frees it with the context.

=item C<$dimensions>

The layout size, a C<Clay_Dimensions> (C<< { width => 800, height => 600 } >>
or C<[800, 600]>). Undef means 0 x 0. Change it later with
L</Clay_SetLayoutDimensions>.

=item C<$error_handler>

Undef or a code reference that receives Clay's error reports (see
L</CALLBACKS>). Without one, Clay errors are ignored, as in C.

=item C<$userdata>

Any scalar; a copy is passed to the error handler as its last argument.

=back

Returns a C<Clay::XS::Context>. Keep it: the context is freed when the
last reference goes away (see L</CONTEXTS>).

The new context is sized for the counts of the current context, or for
Clay's process-wide defaults when no context is current (see
L</Clay_SetMaxElementCount>).

Croaks:

=over 4

=item *

C<Clay_Initialize: capacity must be a non-negative integer number of bytes, got '...'> and C<< Clay_Initialize: capacity <n> is below Clay_MinMemorySize() = <m> bytes >>.

=item *

C<Clay_Initialize: dimensions: ...> and C<Clay_Initialize: error handler: expected a CODE reference or undef, got ...>.

=item *

C<< Clay_Initialize: <n> measure-cache words are below the minimum of 32 ... >> and C<< Clay_Initialize: <n> measure-cache words need <b> hash buckets but only <e> elements are configured; ... >>: the configured
counts do not fit together (see L</Clay_SetMaxElementCount>).

=item *

C<< Clay_Initialize: cannot allocate <n> bytes >> and C<Clay_Initialize: Clay could not create a context in the arena>.

=item *

When the error handler dies while Clay initialises the context,
C<Clay_Initialize> croaks with that error, frees the new context and
leaves the previous context current.

=back

I<Context:> optional. I<Frame:> any time. I<In a callback:> refused.
I<Held errors:> only its own (see above).

=head2 Clay_SetCurrentContext

Makes a context the current one.

    Clay_SetCurrentContext($ctx);

C<$ctx> must be a live C<Clay::XS::Context> from C<Clay_Initialize> or
C<Clay_GetCurrentContext>. Anything else (undef, a L<Storable> copy, a
hand-blessed object) croaks C<Clay::XS: argument is not a live Clay::XS::Context>. A context of another thread croaks
C<Clay_SetCurrentContext: Clay::XS context used from a different interpreter/thread>. There is no way to make "no context" current.

I<Context:> none. I<Frame:> any time. I<In a callback:> refused.
I<Held errors:> never.

=head2 Clay_GetCurrentContext

Returns the current context, or undef when there is none.

    my $ctx = Clay_GetCurrentContext();

The result is another reference to the same object: it compares equal
to the reference C<Clay_Initialize> returned (C<==>), and it keeps the
context alive like any other reference.

I<Context:> optional. I<Frame:> any time. I<In a callback:> allowed.
I<Held errors:> never.

=head2 Clay_SetMaxElementCount

Sets the maximum number of elements for the next C<Clay_Initialize>.

    Clay_SetMaxElementCount($count);

C<$count> is an integer in C<1 .. 2**31 - 1>. The count bounds the
elements, text lines and render commands of one frame, together with
the copies Clay keeps of elements with exit transitions (see
L</FUNCTIONS: TRANSITIONS>).

=over 4

=item *

With a current context, the setter changes that context's count, which
C<Clay_MinMemorySize> and the next C<Clay_Initialize> read. The live
context itself cannot grow: every function that uses it croaks
C<< <function>: element/word counts changed since Clay_Initialize; call Clay_Initialize again >> until you create a new context (or set the
count back). Only the context and count functions keep working
(C<Clay_Initialize>, C<Clay_SetCurrentContext>,
C<Clay_GetCurrentContext>, C<Clay_MinMemorySize> and the count setters
and getters); C<Clay_GetLayoutDimensions>, for example, croaks.

=item *

Without a current context, it changes Clay's process-wide default,
which every later C<Clay_Initialize> uses. As in Clay, it then also sets
the measure-cache word count to twice the element count, so call
C<Clay_SetMaxMeasureTextCacheWordCount> afterwards if you want another
word count.

=back

C<Clay_Initialize> refuses counts that do not fit together: fewer than
32 words, or more than 32 words per element (Clay sizes one part of its
measure cache by C<words / 32> and indexes it by element).

Croaks C<Clay_SetMaxElementCount: expected an integer in 1..2147483647, got ...>, C<< Clay_SetMaxElementCount: <n> elements would overflow Clay's default measure-cache word count (2 x elements) >>
and, for counts whose arena would exceed 4 GiB, C<< Clay_SetMaxElementCount: <n> elements and <m> measure-cache words need about <bytes> bytes of arena; ... >>.

    Clay_SetMaxElementCount(20_000);              # no context yet
    Clay_SetMaxMeasureTextCacheWordCount(32_768);
    my $ctx = Clay_Initialize(Clay_MinMemorySize(), [800, 600]);

I<Context:> optional. I<Frame:> any time. I<In a callback:> refused.
I<Held errors:> never.

=head2 Clay_GetMaxElementCount

Returns the element count of the current context (or what a setter
changed it to); without a context, the process-wide default the next
C<Clay_Initialize> uses.

    my $count = Clay_GetMaxElementCount();

I<Context:> optional, and keeps working after a count change.
I<Frame:> any time. I<In a callback:> allowed. I<Held errors:> never.

=head2 Clay_SetMaxMeasureTextCacheWordCount

Sets the number of measured words Clay's text measurement cache holds,
for the next C<Clay_Initialize>.

    Clay_SetMaxMeasureTextCacheWordCount($count);

C<$count> is an integer in C<32 .. 2**31 - 1>. The rules of
L</Clay_SetMaxElementCount> apply: with a current context it changes
that context's count and the live context then refuses to work until
the next C<Clay_Initialize>; without one it changes the process-wide
default.

Croaks C<Clay_SetMaxMeasureTextCacheWordCount: expected an integer in 32..2147483647, got ...> and, for counts whose arena would exceed
4 GiB, C<< Clay_SetMaxMeasureTextCacheWordCount: <n> elements and <m> measure-cache words need about <bytes> bytes of arena; ... >>.

I<Context:> optional. I<Frame:> any time. I<In a callback:> refused.
I<Held errors:> never.

=head2 Clay_GetMaxMeasureTextCacheWordCount

Returns the measure-cache word count of the current context (or what a
setter changed it to); without a context, the process-wide default the
next C<Clay_Initialize> uses.

    my $count = Clay_GetMaxMeasureTextCacheWordCount();

I<Context:> optional, and keeps working after a count change.
I<Frame:> any time. I<In a callback:> allowed. I<Held errors:> never.

=head2 Clay_SetLayoutDimensions

Sets the size of the layout, for example after the window was resized.

    Clay_SetLayoutDimensions({ width => 1024, height => 768 });
    Clay_SetLayoutDimensions([1024, 768]);

Takes a C<Clay_Dimensions>; missing keys and undef mean 0. The root
element takes its size from the dimensions when a frame begins, and
culling (see L</Clay_SetCullingEnabled>) tests against them, so set
them before C<Clay_BeginLayout>.

Croaks C<Clay_SetLayoutDimensions: dimensions: expected a hash or array reference, got ...>.

I<Context:> current. I<Frame:> any time. I<In a callback:> refused.
I<Held errors:> re-thrown.

=head2 Clay_GetLayoutDimensions

Returns the layout size as C<< { width => $w, height => $h } >>.

    my $size = Clay_GetLayoutDimensions();

I<Context:> current. I<Frame:> any time. I<In a callback:> allowed.
I<Held errors:> re-thrown.

=head1 FUNCTIONS: FRAMES AND ELEMENTS

=head2 Clay_BeginLayout

Starts a frame.

    Clay_BeginLayout();

Clay opens its own root element (id C<Clay__RootContainer>, sized to
the layout dimensions); every element you open at the top level becomes
its child.

If the previous frame was never ended (an exception interrupted its
declaration, say), C<Clay_BeginLayout> finishes it first: it closes the
elements still open and lets Clay end that frame, discarding its render
commands (see L</ELEMENTS AND FRAMES>). If the unfinished frame holds a
callback error, C<Clay_BeginLayout> then croaks with that error plus the
suffix C< (from the previous unfinished frame)> and does not start a
frame; call it again to start one.

I<Context:> current. I<Frame:> any time. I<In a callback:> refused.
I<Held errors:> re-throws one held by an unfinished frame (see above).

=head2 Clay_EndLayout

Ends the frame, computes the layout and returns the render commands.

    my $commands = Clay_EndLayout();
    my $commands = Clay_EndLayout($delta_time);

C<$delta_time> is the time in seconds since the previous frame, a
finite number (default 0). Clay uses it to advance transitions.

Returns an array reference of render command hashes in drawing order
(see L</RENDER COMMANDS>).

Croaks:

=over 4

=item *

C<Clay_EndLayout: called without a matching Clay_BeginLayout> outside a
frame, and C<Clay_EndLayout: deltaTime: expected a finite number, got ...>.

=item *

C<< <n> element(s) still open at Clay_EndLayout (unbalanced Clay__OpenElement/Clay__CloseElement) >> when elements were left open.
It closes them first, so Clay finishes the frame and the next frame
works.

=item *

Any error a callback threw during the frame (see L</ERRORS FROM
CALLBACKS>). The render commands of a frame whose C<Clay_EndLayout>
croaked are discarded.

=back

I<Context:> current. I<Frame:> inside a frame. I<In a callback:>
refused. I<Held errors:> re-thrown.

=head2 Clay__OpenElement

Opens a new element whose id Clay derives automatically, like the C
C<CLAY_AUTO_ID()> macro.

    Clay__OpenElement();

The automatic id is derived from the parent's id and the element's
position among its siblings, so it changes when siblings are added or
removed before it. Use L</Clay__OpenElementWithId> for elements you
want to find again. Configure the element next, declare its children,
then close it with L</Clay__CloseElement>.

Croaks C<Clay__OpenElement: called outside Clay_BeginLayout/Clay_EndLayout>.

I<Context:> current. I<Frame:> inside a frame. I<In a callback:>
refused. I<Held errors:> never.

=head2 Clay__OpenElementWithId

Opens a new element with the given element id, like the C C<CLAY(id, ...)>
macro.

    Clay__OpenElementWithId(Clay_GetElementId('sidebar'));

The argument must be an element id hash reference (see
L</FUNCTIONS: ELEMENT IDS>). Clay::XS reads its C<id>, C<offset>,
C<baseId> and C<stringId> keys; it keeps a private copy of the string.
Two elements with the same id in one frame make Clay report
C<CLAY_ERROR_TYPE_DUPLICATE_ID> to the error handler.

Croaks C<Clay__OpenElementWithId: called outside Clay_BeginLayout/Clay_EndLayout>, and a L</STRUCT ERRORS> object
C<Clay__OpenElementWithId: element id: expected an element id hash reference (from Clay_GetElementId), got ...> for anything but a hash
reference, undef included.

I<Context:> current. I<Frame:> inside a frame. I<In a callback:>
refused. I<Held errors:> never.

=head2 Clay__ConfigureOpenElement

Configures the element that was just opened.

    Clay__ConfigureOpenElement(\%declaration);

C<%declaration> is a C<Clay_ElementDeclaration>: C<layout>,
C<backgroundColor>, C<overlayColor>, C<cornerRadius>, C<aspectRatio>,
C<image>, C<floating>, C<custom>, C<clip>, C<border>, C<transition>,
C<sizingGroup> and C<userData>. L<Clay::XS::Structs> documents every
key. Undef or C<{}> leaves every field at its zero value. Unknown keys
are ignored; use L</check_struct> to catch typos.

Call it at most once per element, right after opening it and before
declaring any child (as the C C<CLAY()> macro does). An element you
never configure keeps the zero declaration. Once a frame has more
elements than the element count allows, Clay drops every further
element, and configuring one changes nothing (the declaration is still
parsed and checked).

Croaks:

=over 4

=item *

C<Clay__ConfigureOpenElement: no element is open (unbalanced Clay__OpenElement/Clay__CloseElement)>.

=item *

C<Clay__ConfigureOpenElement: the open element is already configured or has children; configure an element once, right after opening it>.

=item *

A L</STRUCT ERRORS> object for a value Clay cannot use, for example
C<Clay_ElementDeclaration.layout.padding.left: expected an integer in 0..65535, got '-8'>.

=back

I<Context:> current. I<Frame:> element open. I<In a callback:>
refused. I<Held errors:> never.

=head2 Clay__CloseElement

Closes the innermost open element.

    Clay__CloseElement();

Croaks C<Clay__CloseElement: no element is open (unbalanced Clay__OpenElement/Clay__CloseElement)>.

I<Context:> current. I<Frame:> element open. I<In a callback:>
refused. I<Held errors:> never.

=head2 Clay__OpenTextElement

Adds a text element to the open element, like the C C<CLAY_TEXT()>
macro.

    Clay__OpenTextElement($text);
    Clay__OpenTextElement($text, \%text_config);

A text element is a leaf: it has no children and needs no
C<Clay__CloseElement>. C<$text> is a character string; Clay::XS copies
it, so you may change or free your variable at once (see L</STRINGS>).
C<%text_config> is a C<Clay_TextElementConfig> (C<textColor>,
C<fontId>, C<fontSize>, C<letterSpacing>, C<lineHeight>, C<wrapMode>,
C<textAlignment>, C<userData>; see L<Clay::XS::Structs>); undef means
the zero config.

Clay measures the text's words during this call, so the measure
function (see L</Clay_SetMeasureTextFunction>) may run here. Its errors
are held and re-thrown by C<Clay_EndLayout>.

Croaks C<Clay__OpenTextElement: called outside Clay_BeginLayout/Clay_EndLayout>, C<Clay__OpenTextElement: text must be a defined string>, C<< Clay__OpenTextElement: text length <n> exceeds INT32_MAX >> and L</STRUCT ERRORS> objects such as
C<Clay_TextElementConfig.fontSize: expected an integer in 0..65535, got '-1'>.

I<Context:> current. I<Frame:> inside a frame. I<In a callback:>
refused. I<Held errors:> never.

=head2 Clay_GetOpenElementId

Returns the numeric id of the innermost open element.

    my $id = Clay_GetOpenElementId();

Useful for the ids of elements opened with C<Clay__OpenElement> and as
the seed of local ids (see L</Clay__HashString>). With no element of
yours open it returns the id of Clay's root element.

Croaks C<Clay_GetOpenElementId: called outside Clay_BeginLayout/Clay_EndLayout>.

I<Context:> current. I<Frame:> inside a frame. I<In a callback:>
refused. I<Held errors:> never.

=head2 Clay_GetElementData

Returns the bounding box Clay computed for an element.

    my $data = Clay_GetElementData(Clay_GetElementId('sidebar'));
    # { boundingBox => { x => 0, y => 0, width => 200, height => 600 }, found => 1 }

=over 4

=item C<boundingBox> (Clay_GetElementData)

The element's box from the last completed frame, in layout coordinates
(relative to the layout's top left corner).

=item C<found>

1 when Clay knows the id; 0 otherwise, and the box is all zero.

=back

See L<Clay::XS::Structs/Clay_ElementData>.

Croaks a L</STRUCT ERRORS> object C<Clay_GetElementData: element id: expected an element id hash reference (from Clay_GetElementId), got ...>.

I<Context:> current. I<Frame:> any time. I<In a callback:> allowed.
I<Held errors:> re-thrown.

=head1 FUNCTIONS: ELEMENT IDS

All id functions return an element id hash reference:

    {
        id       => 3230707630,   # the hash Clay uses to find the element
        offset   => 0,            # the index of the WithIndex/WithOffset forms
        baseId   => 3230707630,   # the hash of the string and seed, before the offset
        stringId => 'root',       # the string; absent for an empty string
    }

They need no context and work anywhere, inside callbacks too. Id
strings may contain any Unicode characters (see L</STRINGS>); undef
croaks C<< <function>: element id string must be defined >>.

=head2 Clay_GetElementId

Returns the element id for a string, like the C C<CLAY_ID()> macro.

    my $id = Clay_GetElementId('sidebar');

The same string always gives the same id. It equals
C<Clay__HashString($string, 0)>.

I<Context:> none. I<Frame:> any time. I<In a callback:> allowed.
I<Held errors:> never.

=head2 Clay_GetElementIdWithIndex

Returns the element id for a string and an index, like the C
C<CLAY_IDI()> macro.

    my $id = Clay_GetElementIdWithIndex('row', $i);

Use it for elements made in a loop. C<$index> is an integer in
C<0 .. 2**32 - 1>; C<offset> holds it and C<baseId> is the id of the
string alone. Croaks C<Clay_GetElementIdWithIndex: index: expected an integer in 0..4294967295, got ...>.

I<Context:> none. I<Frame:> any time. I<In a callback:> allowed.
I<Held errors:> never.

=head2 Clay__HashString

Returns the element id for a string and a seed.

    my $id = Clay__HashString($string);
    my $id = Clay__HashString($string, $seed);

C<$seed> is an integer in C<0 .. 2**32 - 1> (default 0). With the open
element's id as seed it gives an id that is local to that element, like
the C C<CLAY_ID_LOCAL()> macro:

    my $id = Clay__HashString('label', Clay_GetOpenElementId());

Croaks C<Clay__HashString: seed: expected an integer in 0..4294967295, got ...>.

I<Context:> none. I<Frame:> any time. I<In a callback:> allowed.
I<Held errors:> never.

=head2 Clay__HashStringWithOffset

Returns the element id for a string, an offset and a seed, like the C
C<CLAY_IDI_LOCAL()> macro when the seed is the open element's id.

    my $id = Clay__HashStringWithOffset($string, $offset);
    my $id = Clay__HashStringWithOffset($string, $offset, $seed);

C<$offset> (required) and C<$seed> (default 0) are integers in
C<0 .. 2**32 - 1>.

I<Context:> none. I<Frame:> any time. I<In a callback:> allowed.
I<Held errors:> never.

=head1 FUNCTIONS: TEXT MEASUREMENT

=head2 Clay_SetMeasureTextFunction

Installs the current context's measure function, which tells Clay how
large a piece of text is.

    Clay_SetMeasureTextFunction($callback);
    Clay_SetMeasureTextFunction($callback, $userdata);
    Clay_SetMeasureTextFunction(undef);             # remove it

The callback is called as

    $callback->($text, \%text_config, $userdata)

and must return C<< { width => $w, height => $h } >> or C<[$w, $h]>.
C<%text_config> is the text element's C<Clay_TextElementConfig> with
every key filled in. Clay measures word by word: C<$text> is usually a
single word (text between ASCII spaces and newlines) or a single space.
Clay caches the results by the text together with C<fontId>,
C<fontSize>, C<letterSpacing> and whether C<wrapMode> is
C<CLAY_TEXT_WRAP_NONE> (see L</Clay_ResetMeasureTextCache>). The other
keys of C<%text_config> are not part of the cache key: a measure
function whose result depends on C<userData> or C<lineHeight>, say,
gets the cached result of another config that differs only there.

Every context that lays out text needs its own measure function.
Measuring text without one is a held error
(C<Clay::XS: text measured but no measure_text function is installed for this context>), and so is a result of undef (C<measure_text callback result: expected a hash or array reference, got undef (did the callback return its result?)>) or of a plain number. See L</CALLBACKS> for the
general rules.

Croaks C<Clay_SetMeasureTextFunction: callback: expected a CODE reference or undef, got ...>.

I<Context:> current. I<Frame:> any time. I<In a callback:> refused.
I<Held errors:> re-thrown.

=head2 Clay_ResetMeasureTextCache

Empties Clay's text measurement cache, so the next frame measures all
text again.

    Clay_ResetMeasureTextCache();

Call it when fonts change. Clay::XS resets the cache itself after a
measure function failed.

I<Context:> current. I<Frame:> any time. I<In a callback:> refused.
I<Held errors:> re-thrown.

=head1 FUNCTIONS: POINTER AND HOVER

Clay tests the pointer against the layout of the last completed frame.
A test therefore needs one completed frame first, and an element shows
up as hovered one frame after it appeared.

=head2 Clay_SetPointerState

Tells Clay where the pointer (mouse or touch) is and whether it is
pressed.

    Clay_SetPointerState({ x => $x, y => $y }, $is_down);
    Clay_SetPointerState([$x, $y], $is_down);

C<$position> is a C<Clay_Vector2> in layout coordinates; C<$is_down> is
any Perl boolean. The call:

=over 4

=item 1.

finds every element under the pointer (the I<pointer-over list>, see
L</Clay_GetPointerOverIds>) and runs their hover callbacks (see
L</Clay_OnHover>);

=item 2.

then updates the pointer state: while pressed, the state goes from
C<CLAY_POINTER_DATA_PRESSED_THIS_FRAME> to C<CLAY_POINTER_DATA_PRESSED>;
while released, from C<CLAY_POINTER_DATA_RELEASED_THIS_FRAME> to
C<CLAY_POINTER_DATA_RELEASED>.

=back

A new context starts with a released pointer
(C<CLAY_POINTER_DATA_RELEASED>: C<Clay_Initialize> sets it, where
Clay's zero value would read as pressed), so the first call with
C<$is_down> true gives C<CLAY_POINTER_DATA_PRESSED_THIS_FRAME>.

While the last frame had more elements than the element count allows,
Clay ignores the call.

Croaks C<Clay_SetPointerState: cannot be called between Clay_BeginLayout and Clay_EndLayout; end the frame first (Clay_EndLayout, or Clay_BeginLayout, which finishes an unfinished frame)>
(see L</ELEMENTS AND FRAMES>), and re-throws errors from hover
callbacks.

I<Context:> current. I<Frame:> completed frame (or before the first
frame). I<In a callback:> refused. I<Held errors:> re-thrown.

=head2 Clay_GetPointerState

Returns the pointer state.

    my $pointer = Clay_GetPointerState();
    # { position => { x => 10, y => 20 }, state => CLAY_POINTER_DATA_PRESSED }

=over 4

=item C<position>

The last position given to C<Clay_SetPointerState>, C<< { x, y } >>.

=item C<state>

One of the L</Pointer data states>.

=back

A new context reports C<< { x => 0, y => 0 } >> and
C<CLAY_POINTER_DATA_RELEASED> until the first C<Clay_SetPointerState>
(see L</Clay_SetPointerState>).

I<Context:> current. I<Frame:> any time. I<In a callback:> allowed.
I<Held errors:> re-thrown.

=head2 Clay_Hovered

Returns true when the pointer is over the open element.

    my $hovered = Clay_Hovered();

It looks for the open element's id in the pointer-over list of the last
C<Clay_SetPointerState>, so you can style an element while you declare
it:

    Clay__OpenElementWithId(Clay_GetElementId('button'));
    Clay__ConfigureOpenElement({
        backgroundColor => Clay_Hovered() ? [90, 90, 255, 255] : [60, 60, 200, 255],
    });

Returns a Perl boolean. Croaks C<Clay_Hovered: called outside Clay_BeginLayout/Clay_EndLayout>.

I<Context:> current. I<Frame:> inside a frame. I<In a callback:>
refused. I<Held errors:> never.

=head2 Clay_OnHover

Registers a hover callback for the open element.

    Clay_OnHover($callback);
    Clay_OnHover($callback, $userdata);

Once the frame is complete, every C<Clay_SetPointerState> calls

    $callback->(\%element_id, \%pointer, $userdata)

when the pointer is over the element, until the next frame completes
(calling C<Clay_SetPointerState> three times between two frames runs the
callback up to three times). C<%element_id> is the element's
id hash; C<%pointer> is C<< { position => { x, y }, state => ... } >>
with the new position and the state from before the call.

Clay forgets an element's hover callback whenever the element is
declared again, so call C<Clay_OnHover> in every frame.
C<Clay_SetPointerState> runs the callbacks registered while declaring
the last completed frame.

Croaks C<Clay_OnHover: no element is open (unbalanced Clay__OpenElement/Clay__CloseElement)>, C<Clay_OnHover: callback: expected a CODE reference, got ...> (undef included) and
C<Clay_OnHover: the open element has no id>. The last one only happens
when the open element's numeric id is 0, which in practice no id
function produces. Once a frame has more elements than the element
count allows, Clay drops every further element, and C<Clay_OnHover>
does nothing for them (as C<Clay__ConfigureOpenElement> configures
nothing). Errors the callback
throws are re-thrown by C<Clay_SetPointerState>.

I<Context:> current. I<Frame:> element open. I<In a callback:>
refused. I<Held errors:> never.

=head2 Clay_PointerOver

Returns true when the pointer is over the element with the given id.

    if (Clay_PointerOver(Clay_GetElementId('button'))) { ... }

It looks the id up in the pointer-over list of the last
C<Clay_SetPointerState>. Returns a Perl boolean. Croaks a
L</STRUCT ERRORS> object C<Clay_PointerOver: element id: expected an element id hash reference (from Clay_GetElementId), got ...>.

I<Context:> current. I<Frame:> any time. I<In a callback:> allowed.
I<Held errors:> re-thrown.

=head2 Clay_GetPointerOverIds

Returns the pointer-over list: the element ids of every element under
the pointer, as found by the last C<Clay_SetPointerState>.

    my $ids = Clay_GetPointerOverIds();
    say $_->{stringId} // $_->{id} for @$ids;

Returns an array reference of element id hashes (see
L</FUNCTIONS: ELEMENT IDS>). Elements opened with C<Clay__OpenElement>
have no C<stringId>. The order is:

=over 4

=item *

Floating element trees first, the one drawn on top (highest C<zIndex>)
first, and the main tree last. Clay's root element
(C<Clay__RootContainer>) heads the main tree's part.

=item *

Within one tree, parents before their children.

=item *

A floating tree whose C<pointerCaptureMode> is
C<CLAY_POINTER_CAPTURE_MODE_CAPTURE> (the default) ends the list when
the pointer is over it: trees below it are not tested.

=back

An element counts only when the pointer is also inside the element
that clips it (if any). Elements in an exit transition are skipped, and
so are elements whose transition disables interactions (see
L</Transition interaction handling>).

I<Context:> current. I<Frame:> any time. I<In a callback:> allowed.
I<Held errors:> re-thrown.

=head1 FUNCTIONS: SCROLLING

An element becomes a I<scroll container> when its declaration enables
C<clip> on an axis (see L<Clay::XS::Structs/clip>). Clay keeps a scroll
position for every scroll container. Positions are 0 at the start and
negative when scrolled: C<< { x => 0, y => -40 } >> means the content
moved 40 units up. C<Clay_UpdateScrollContainers> clamps them to
C<0 .. -(content size - container size)>; a position written with
L</set_scroll_position> is used as given (also by
C<Clay_GetScrollOffset>) until the next C<Clay_UpdateScrollContainers>
clamps it.

Clay does not move the content by itself: pass the position as the
container's C<childOffset> every frame:

    Clay__OpenElementWithId(Clay_GetElementId('list'));
    Clay__ConfigureOpenElement({
        clip => { vertical => 1, childOffset => Clay_GetScrollOffset() },
    });

=head2 Clay_UpdateScrollContainers

Applies scroll input and momentum to the scroll containers.

    Clay_UpdateScrollContainers($enable_drag_scrolling, $scroll_delta, $delta_time);

All three arguments are required.

=over 4

=item C<$enable_drag_scrolling>

A Perl boolean. When true and the pointer is pressed, dragging the
pointer scrolls the container under it (touch-style), with momentum
after release.

=item C<$scroll_delta>

A C<Clay_Vector2> (C<< { x => 0, y => -4 } >> or C<[0, -4]>), usually
the mouse wheel movement since the last call; undef means no movement.
Clay multiplies it by 10: a delta of C<< { y => -4 } >> scrolls 40
layout units down. It goes to the innermost scroll container under the
pointer (as of the last C<Clay_SetPointerState>), on each axis that
container clips and whose content is larger than the container.

=item C<$delta_time>

The time in seconds since the last call, a finite number.

=back

Call it once per frame, after C<Clay_SetPointerState> and before
C<Clay_BeginLayout>. Clay drops the scroll state of every container
that the last completed frame did not declare; calling it again before
the next frame changes nothing more.

Croaks C<Clay_UpdateScrollContainers: cannot be called between Clay_BeginLayout and Clay_EndLayout; ...> (see L</Clay_SetPointerState>) and
C<Clay_UpdateScrollContainers: deltaTime: expected a finite number, got ...>.

I<Context:> current. I<Frame:> completed frame (or before the first
frame). I<In a callback:> refused. I<Held errors:> re-thrown.

=head2 Clay_GetScrollOffset

Returns the scroll position of the open element as C<< { x, y } >>.

    my $offset = Clay_GetScrollOffset();

Returns C<< { x => 0, y => 0 } >> when the open element is not a known
scroll container (for example in the first frame it appears). With
external scroll handling on, it returns the offset the query function
reported when the container was last configured; in the usual order
(C<Clay_GetScrollOffset> before C<Clay__ConfigureOpenElement>) that is
the previous frame's result (see
L</Clay_SetExternalScrollHandlingEnabled>).

Croaks C<Clay_GetScrollOffset: called outside Clay_BeginLayout/Clay_EndLayout>.

I<Context:> current. I<Frame:> inside a frame. I<In a callback:>
refused. I<Held errors:> never.

=head2 Clay_GetScrollContainerData

Returns the state of a scroll container.

    my $data = Clay_GetScrollContainerData(Clay_GetElementId('list'));

Returns a hash reference:

    {
        scrollPosition            => { x => 0, y => -40 },
        scrollContainerDimensions => { width => 200, height => 300 },
        contentDimensions         => { width => 200, height => 900 },
        config                    => { horizontal => 0, vertical => 1,
                                       childOffset => { x => 0, y => -40 } },
        found                     => 1,
    }

=over 4

=item C<scrollPosition>

The current scroll offset, C<< { x, y } >>. It is a copy; write it with
L</set_scroll_position>.

=item C<scrollContainerDimensions>

The container's size, C<< { width, height } >>.

=item C<contentDimensions>

The size of the container's content (including the container's
padding), C<< { width, height } >>.

=item C<config>

The container's C<clip> declaration, present only while it is the
container's own: between frames when the last completed frame declared
the container, and during a frame once that frame has declared it.
Before that, Clay would read it through the container's place in the
element list, which may hold another element by then, so the key is
left out (it is absent, not undef). It is also absent when C<found> is
0.

=item C<found> (Clay_GetScrollContainerData)

1 when the id names a scroll container Clay knows; 0 otherwise, and
everything else is zero.

=back

See L<Clay::XS::Structs/Clay_ScrollContainerData>.

The other keys are kept on Clay's own record of the container, so they
can be read at any time: in the middle of a frame they describe the
container as the last completed frame laid it out, with the scroll
input applied since (the usual way to draw a scroll bar while declaring
the frame).

Croaks a L</STRUCT ERRORS> object for anything but an element id hash
reference.

I<Context:> current. I<Frame:> any time (C<config> between frames and,
during a frame, once the container has been declared). I<In a
callback:> allowed. I<Held errors:> re-thrown.

=head2 set_scroll_position

Sets the scroll position of a scroll container, for scroll bars,
"scroll to" buttons and the like.

    set_scroll_position(Clay_GetElementId('list'), { x => 0, y => -120 });

The first argument is an element id hash reference, the second a
C<Clay_Vector2>. Both axes are written: a missing key or undef means 0,
so to change one axis pass the current value of the other:

    my $id = Clay_GetElementId('list');
    set_scroll_position($id, {
        x => Clay_GetScrollContainerData($id)->{scrollPosition}{x},
        y => -120,
    });

In C this is a write through the pointer
C<Clay_GetScrollContainerData> returns. The new position shows in the
next frame. It is not clamped: a position beyond the content is used as
given until the next C<Clay_UpdateScrollContainers> clamps it. Every write counts as a change for L<Clay::UI::Revision>, so
a renderer that skips unchanged frames still draws the next one.

Croaks C<< set_scroll_position: element <id> is not a known scroll container (declare it with clip enabled and complete a frame first) >>,
and L</STRUCT ERRORS> objects for a bad id or position.

I<Context:> current. I<Frame:> any time. I<In a callback:> refused.
I<Held errors:> re-thrown.

=head2 Clay_SetQueryScrollOffsetFunction

Installs the current context's query-scroll function, used when the
host application scrolls content itself.

    Clay_SetQueryScrollOffsetFunction($callback);
    Clay_SetQueryScrollOffsetFunction($callback, $userdata);
    Clay_SetQueryScrollOffsetFunction(undef);

The callback is called as

    $callback->($element_id, $userdata)

with the container's numeric id (the C<id> of its id hash), and must
return C<< { x => $x, y => $y } >> or C<[$x, $y]>. While external
scroll handling is on (see L</Clay_SetExternalScrollHandlingEnabled>),
Clay calls it for every scroll container during that container's
C<Clay__ConfigureOpenElement>; the result becomes the container's
scroll position. An undef result is a held error, re-thrown by
C<Clay_EndLayout>.

Croaks C<Clay_SetQueryScrollOffsetFunction: callback: expected a CODE reference or undef, got ...>.

I<Context:> current. I<Frame:> any time. I<In a callback:> refused.
I<Held errors:> re-thrown.

=head2 Clay_SetExternalScrollHandlingEnabled

Switches external scroll handling on or off.

    Clay_SetExternalScrollHandlingEnabled(1);

While it is on, the host application scrolls the content itself:

=over 4

=item *

Clay asks the query-scroll function for the position of every scroll
container when the container is configured, instead of using its own.

=item *

Clay ignores the containers' C<childOffset> when placing their
children.

=item *

The pointer counts as over an element even outside the element that
clips it.

=back

F<clay.h> implements this function without declaring it.

Croaks C<Clay_SetExternalScrollHandlingEnabled: install a function with Clay_SetQueryScrollOffsetFunction first> when switched on without one.
Removing the function later while handling is on makes the next scroll
container a held error (C<Clay::XS: external scroll handling is enabled but no query_scroll_offset function is installed for this context>).

I<Context:> current. I<Frame:> any time. I<In a callback:> refused.
I<Held errors:> re-thrown.

=head1 FUNCTIONS: DEBUGGING AND CULLING

=head2 Clay_SetDebugModeEnabled

Switches Clay's built-in debug view on or off.

    Clay_SetDebugModeEnabled(1);

The debug view is a panel on the right side of the layout that shows
the element tree; the root element gets narrower by the panel's width.
The panel is part of the render commands, so your renderer draws it.
Its text uses C<fontId> 0 and needs the measure function. The setting
stays until changed.

I<Context:> current. I<Frame:> any time. I<In a callback:> refused.
I<Held errors:> re-thrown.

=head2 Clay_IsDebugModeEnabled

Returns true (a Perl boolean) while the debug view is on.

    my $on = Clay_IsDebugModeEnabled();

I<Context:> current. I<Frame:> any time. I<In a callback:> allowed.
I<Held errors:> re-thrown.

=head2 Clay_SetCullingEnabled

Switches visibility culling on or off.

    Clay_SetCullingEnabled(0);

With culling on (the default), Clay emits no render commands for
elements whose box lies entirely outside the layout dimensions, and
stops emitting the lines of a text once they pass the bottom edge.
Culling tests each element on its own: the children of a culled element
are still emitted when their own boxes reach into the layout. A culled
clip container still emits its C<SCISSOR_START> / C<SCISSOR_END> pair,
so children of it that reach into the layout stay clipped.

I<Context:> current. I<Frame:> any time. I<In a callback:> refused.
I<Held errors:> re-thrown.

=head1 FUNCTIONS: TRANSITIONS

A I<transition> animates an element's position, size or colours when
they change, when the element appears (enter) or when it disappears
(exit). An element gets one with the C<transition> key of its
declaration (see L<Clay::XS::Structs/transition>); the handlers below
compute the animation.

Clay runs an element's transitions only while the element has a C
transition hook. Clay::XS gives it one while the context has a Perl
C<$handler> (installed with C<Clay_SetTransitionHandlers> below), so
without handlers the C<transition> key does nothing and every change
shows at once, as in C with a NULL handler. The hook is set when the
element is declared: install the handlers before the frame whose
transitions they should run.

An element that exits stays on screen, with its subtree as last
declared, until its exit transition ends. For that Clay copies every
element that has an exit transition, with its subtree, at the end of
each frame and keeps the copies until the next frame ends; a frame in
which elements exit also lays out a second copy of them. The copies
count against the element count (see L</Clay_SetMaxElementCount>): a
frame has room for the element count less the copies Clay keeps, and,
while elements exit, less twice that. When a frame and the copies do
not fit, Clay reports C<CLAY_ERROR_TYPE_ELEMENTS_CAPACITY_EXCEEDED> to
the error handler, drops every exit transition (exiting elements
disappear at once), and treats the frame like one with more elements
than the element count allows (the next C<Clay_SetPointerState> is
ignored). A frame with more elements than the element count allows
drops every exit transition as well. An element declared without the
C<transition> key loses its transitions, its exit included, even if it
had one in the frame before.

L<Clay::UI> has no attribute for C<transition>, but widgets can use it:
add the key in a C<contribute_> method of the widget class (see
L<Clay::XS::Structs/Keys Clay::UI has no attribute for>) and call
C<Clay_SetTransitionHandlers> right after C<< Clay::UI->new >>, while
the UI's context is the current one. Give such widgets an C<id>, so the
element id stays the same in every frame.

=head2 Clay_SetTransitionHandlers

Installs the current context's transition handlers.

    Clay_SetTransitionHandlers($handler);
    Clay_SetTransitionHandlers($handler, $set_initial, $set_final, $userdata);
    Clay_SetTransitionHandlers();                  # remove all three

Each argument is undef or a code reference; C<$userdata> goes to all
three. One handler set per context serves every element with a
C<transition> config, because Clay's transition callbacks carry no
element id. The callbacks are described in L</CALLBACKS>.

Croaks C<< Clay_SetTransitionHandlers: <handler|setInitialState|setFinalState>: expected a CODE reference or undef, got ... >>.

I<Context:> current. I<Frame:> any time. I<In a callback:> refused.
I<Held errors:> re-thrown.

=head2 Clay_EaseOut

Computes one step of Clay's built-in ease-out curve.

    my $result = Clay_EaseOut(\%args);
    # { complete => 0, current => { boundingBox => {...}, backgroundColor => {...}, ... } }

C<%args> has the shape a transition handler receives, a
L<Clay::XS::Structs/Clay_TransitionCallbackArguments> hash (see also
L</CALLBACKS>): C<initial>, C<target> and C<current> transition data,
C<elapsedTime> and C<duration> in seconds, C<properties> (an OR of
L</Transition properties>) and C<transitionState>. Missing numbers mean
0, missing transition data means all zero, and a missing (or undef)
C<current> starts from C<initial>. Unknown keys are ignored.

Returns C<< { complete => 1|0, current => \%eased } >>:

=over 4

=item C<complete>

1 when C<elapsedTime> has reached C<duration> (or C<duration> is 0 or
less), 0 otherwise.

=item C<current> (Clay_EaseOut result)

C<%eased>: C<current> with every property selected in C<properties>
eased from C<initial> towards C<target>, colours and border widths
included.

=back

A transition handler can use it directly:

    Clay_SetTransitionHandlers(sub ($args, $userdata) {
        my $step = Clay_EaseOut($args);
        $args->{current} = $step->{current};
        return $step->{complete};
    });

Croaks a L</STRUCT ERRORS> object whose path starts at
C<Clay_EaseOut: args> when C<\%args> is not a hash reference or a value
in it is out of range, for example
C<Clay_EaseOut: args.duration: expected a finite number, got 'soon'>.

I<Context:> none. I<Frame:> any time. I<In a callback:> allowed.
I<Held errors:> never.

=head1 FUNCTIONS: HELPERS

These replace the value-building C macros. They return fresh hash
references, need no context and work anywhere, inside callbacks too.
They never re-throw a held error.

=head2 sizing_fit

Returns a C<FIT> sizing axis: the element is as large as its content,
within C<$min> and C<$max>. Replaces C<CLAY_SIZING_FIT>.

    sizing_fit();                 # { type => CLAY__SIZING_TYPE_FIT, min => 0, max => 0 }
    sizing_fit($min, $max);

C<$min> is a finite number (default 0). C<$max> (default 0) is the
maximum when it is a finite number above 0; 0, a negative number,
C<+Inf> or a number beyond the C<float> range means no maximum. Croaks
C<sizing_fit: min: expected a finite number, got ...> and
C<sizing_fit: max: expected a finite number or +Inf, got ...>.

=head2 sizing_grow

Returns a C<GROW> sizing axis: the element takes a share of the free
space in its parent, within C<$min> and C<$max>. Replaces
C<CLAY_SIZING_GROW>.

    sizing_grow();                # { type => CLAY__SIZING_TYPE_GROW, min => 0, max => 0 }
    sizing_grow($min, $max);

The arguments are those of L</sizing_fit>.

=head2 sizing_fixed

Returns a C<FIXED> sizing axis of exactly C<$size> units. Replaces
C<CLAY_SIZING_FIXED>.

    sizing_fixed(200);            # { type => CLAY__SIZING_TYPE_FIXED, min => 200, max => 200 }

C<$size> is required and must be a finite number; croaks
C<sizing_fixed: size: expected a finite number, got ...>.

C<sizing_fixed(0)> does not make an element take no space: Clay reads
a C<max> of 0 as "no maximum", so the axis behaves like
C<sizing_fit()> and the element is as big as its content. Use
C<sizing_fixed(1)> for an element that should take (almost) no space.

=head2 sizing_percent

Returns a C<PERCENT> sizing axis: a fraction of the parent's inner size
(minus padding and child gaps). Replaces C<CLAY_SIZING_PERCENT>.

    sizing_percent(0.5);          # { type => CLAY__SIZING_TYPE_PERCENT, percent => 0.5 }

C<$fraction> is required and must be a number in C<0 .. 1>; croaks
C<sizing_percent: percent: expected a number in 0..1, got ...>.

=head2 padding_all

Returns a C<Clay_Padding> with the same value on all four sides.
Replaces C<CLAY_PADDING_ALL>.

    padding_all(16);              # { left => 16, right => 16, top => 16, bottom => 16 }

C<$value> is an integer in C<0 .. 65535>; croaks
C<padding_all: value: expected an integer in 0..65535, got ...>.

=head2 border_all

Returns a C<Clay_BorderWidth> with the same width on all four sides
and between the children. Replaces C<CLAY_BORDER_ALL>.

    border_all(2);    # { left => 2, right => 2, top => 2, bottom => 2, betweenChildren => 2 }

C<$width> is an integer in C<0 .. 65535>; croaks
C<border_all: width: expected an integer in 0..65535, got ...>.

=head2 border_outside

Returns a C<Clay_BorderWidth> with the same width on all four sides and
no border between the children. Replaces C<CLAY_BORDER_OUTSIDE>.

    border_outside(2); # { left => 2, right => 2, top => 2, bottom => 2, betweenChildren => 0 }

C<$width> is an integer in C<0 .. 65535>.

=head2 corner_radius_all

Returns a C<Clay_CornerRadius> with the same radius on all four
corners. Replaces C<CLAY_CORNER_RADIUS>.

    corner_radius_all(8);   # { topLeft => 8, topRight => 8, bottomLeft => 8, bottomRight => 8 }

C<$radius> is a number of at least 0; croaks
C<< corner_radius_all: radius: expected a number >= 0, got ... >>. A
declaration's C<cornerRadius> also accepts the plain number.

=head1 FUNCTIONS: VALIDATION

=head2 check_struct

Validates a struct value without a context or a frame.

    check_struct($type, $value);
    check_struct($type, $value, $root);

    check_struct('Clay_LayoutConfig', $layout);
    check_struct('Clay_Padding', $padding, 'layout.padding');

=for highlighter language=text

C<$type> is the exact C type name of a struct, one of:

    Clay_ElementDeclaration        Clay_LayoutConfig
    Clay_TextElementConfig         Clay_Sizing
    Clay_SizingAxis                Clay_Padding
    Clay_ChildAlignment            Clay_Color
    Clay_Vector2                   Clay_Dimensions
    Clay_BoundingBox               Clay_CornerRadius
    Clay_BorderWidth               Clay_BorderElementConfig
    Clay_AspectRatioElementConfig  Clay_ImageElementConfig
    Clay_CustomElementConfig       Clay_ClipElementConfig
    Clay_FloatingElementConfig     Clay_FloatingAttachPoints
    Clay_TransitionElementConfig   Clay_TransitionData
    Clay_TransitionCallbackArguments
    Clay_SizingGroup

L<Clay::XS::Structs> describes each. Element ids (C<Clay_ElementId>)
are not on the list: they are not checked by C<check_struct>, only by
the functions that take them. The anonymous C<enter> and C<exit> parts
of a transition have no type name either; check them through
C<Clay_TransitionElementConfig>.

Returns nothing. Croaks a L</STRUCT ERRORS> object for the first
problem, or the plain string C<check_struct: unknown struct type '...'>.
See L</CHECKING STRUCTS> for the rules.

I<Context:> none. I<Frame:> any time. I<In a callback:> allowed.
I<Held errors:> never.

=head1 CONSTANTS

Every constant is an integer constant sub named as in F<clay.h> (plus
the ones the bundled patches add). Import them with C<:all> or by name.
Most are enum values for one declaration key; the transition properties
are bit flags you combine with C<|>. L<Clay::XS::Structs> says which key
takes which group.

=head2 Layout direction

For C<< layout => { layoutDirection => ... } >>.

=over 4

=item CLAY_LEFT_TO_RIGHT

Children in a row, left to right (the default).

=item CLAY_TOP_TO_BOTTOM

Children in a column, top to bottom.

=item CLAY_LEFT_TO_RIGHT_WRAP

Children left to right, wrapping into new lines (see L</FLOW LAYOUT>).

=item CLAY_BACK_TO_FRONT

Children stacked on top of each other (see L</STACK LAYOUT>).

=back

=head2 Line sizing

For C<< layout => { lineSizing => ... } >> of a
C<CLAY_LEFT_TO_RIGHT_WRAP> container (see L</FLOW LAYOUT>).

=over 4

=item CLAY_LINE_SIZING_GROW

Lines share the container's leftover height (the default).

=item CLAY_LINE_SIZING_FIT

Every line is as tall as its tallest child.

=back

=head2 Child alignment

For C<< layout => { childAlignment => { x => ..., y => ... } } >>.

=over 4

=item CLAY_ALIGN_X_LEFT

Children start at the left edge, after the left padding (the default).

=item CLAY_ALIGN_X_RIGHT

Children end at the right edge, before the right padding.

=item CLAY_ALIGN_X_CENTER

Children are centred horizontally.

=item CLAY_ALIGN_Y_TOP

Children start at the top edge, after the top padding (the default).

=item CLAY_ALIGN_Y_BOTTOM

Children end at the bottom edge, before the bottom padding.

=item CLAY_ALIGN_Y_CENTER

Children are centred vertically.

=back

=head2 Sizing types

The C<type> of a sizing axis (C<< layout => { sizing => { width => ...,
height => ... } } >>). The names keep Clay's double underscore. The
L</FUNCTIONS: HELPERS> build these axes for you.

=over 4

=item CLAY__SIZING_TYPE_FIT

As large as the content, within C<min> and C<max> (the default).

=item CLAY__SIZING_TYPE_GROW

Takes a share of the parent's free space, within C<min> and C<max>.

=item CLAY__SIZING_TYPE_PERCENT

A fraction (C<percent>, 0 to 1) of the parent's size minus padding and
child gaps.

=item CLAY__SIZING_TYPE_FIXED

Exactly C<min> (= C<max>) units.

=back

=head2 Text wrap modes

For C<< wrapMode => ... >> in a text config.

=over 4

=item CLAY_TEXT_WRAP_WORDS

Wraps at spaces and newlines when the text does not fit (the default).

=item CLAY_TEXT_WRAP_NEWLINES

Breaks lines only at newline characters.

=item CLAY_TEXT_WRAP_NONE

Never wraps at spaces. In this Clay version newline characters still
start a new line, as with C<CLAY_TEXT_WRAP_NEWLINES>.

=back

=head2 Text alignment

For C<< textAlignment => ... >> in a text config: how the lines of a
wrapped text are placed within the text element.

=over 4

=item CLAY_TEXT_ALIGN_LEFT

Lines start at the left edge (the default).

=item CLAY_TEXT_ALIGN_CENTER

Lines are centred.

=item CLAY_TEXT_ALIGN_RIGHT

Lines end at the right edge.

=back

=head2 Floating attach points

For C<< floating => { attachPoints => { element => ..., parent => ... } } >>:
which point of the floating element (C<element>) is placed on which
point of the element it is attached to (C<parent>), before C<offset> is
added. C<CLAY_ATTACH_POINT_LEFT_TOP> is the default for both.

=over 4

=item CLAY_ATTACH_POINT_LEFT_TOP

The top left corner.

=item CLAY_ATTACH_POINT_LEFT_CENTER

The middle of the left edge.

=item CLAY_ATTACH_POINT_LEFT_BOTTOM

The bottom left corner.

=item CLAY_ATTACH_POINT_CENTER_TOP

The middle of the top edge.

=item CLAY_ATTACH_POINT_CENTER_CENTER

The centre.

=item CLAY_ATTACH_POINT_CENTER_BOTTOM

The middle of the bottom edge.

=item CLAY_ATTACH_POINT_RIGHT_TOP

The top right corner.

=item CLAY_ATTACH_POINT_RIGHT_CENTER

The middle of the right edge.

=item CLAY_ATTACH_POINT_RIGHT_BOTTOM

The bottom right corner.

=back

=head2 Floating attach targets

For C<< floating => { attachTo => ... } >>: what a floating element is
positioned against. A floating element is drawn above the normal tree
and does not affect the size or position of its siblings or parent.

=over 4

=item CLAY_ATTACH_TO_NONE

Not floating (the default).

=item CLAY_ATTACH_TO_PARENT

Floats relative to its parent element.

=item CLAY_ATTACH_TO_ELEMENT_WITH_ID

Floats relative to the element whose id is in C<parentId> (a numeric id
or an element id hash). An unknown id makes Clay report
C<CLAY_ERROR_TYPE_FLOATING_CONTAINER_PARENT_NOT_FOUND>.

=item CLAY_ATTACH_TO_ROOT

Floats relative to the layout's root, which with C<offset> works like
absolute positioning.

=back

=head2 Floating clipping

For C<< floating => { clipTo => ... } >>.

=over 4

=item CLAY_CLIP_TO_NONE

The floating element is not clipped (the default).

=item CLAY_CLIP_TO_ATTACHED_PARENT

The floating element is clipped like the element it is attached to.

=back

=head2 Pointer capture modes

For C<< floating => { pointerCaptureMode => ... } >> (see
L</Clay_GetPointerOverIds>).

=over 4

=item CLAY_POINTER_CAPTURE_MODE_CAPTURE

A floating element under the pointer hides the elements below it from
hit testing (the default).

=item CLAY_POINTER_CAPTURE_MODE_PASSTHROUGH

Elements below the floating element are still hit tested.

=back

=head2 Render command types

The C<commandType> of a render command. L</RENDER COMMANDS> describes
each one in detail.

=over 4

=item CLAY_RENDER_COMMAND_TYPE_NONE (0)

Nothing to draw; skip it.

=item CLAY_RENDER_COMMAND_TYPE_RECTANGLE (1)

A filled rectangle with rounded corners.

=item CLAY_RENDER_COMMAND_TYPE_BORDER (2)

A border drawn inside the bounding box.

=item CLAY_RENDER_COMMAND_TYPE_TEXT (3)

One line of text.

=item CLAY_RENDER_COMMAND_TYPE_IMAGE (4)

An image.

=item CLAY_RENDER_COMMAND_TYPE_SCISSOR_START (5)

Start clipping to the bounding box.

=item CLAY_RENDER_COMMAND_TYPE_SCISSOR_END (6)

End the clipping the matching start began.

=item CLAY_RENDER_COMMAND_TYPE_OVERLAY_COLOR_START (7)

Start tinting everything drawn with a colour.

=item CLAY_RENDER_COMMAND_TYPE_OVERLAY_COLOR_END (8)

End the tint the matching start began.

=item CLAY_RENDER_COMMAND_TYPE_CUSTOM (9)

Something your renderer draws in its own way.

=back

=head2 Pointer data states

The C<state> of L</Clay_GetPointerState> and of a hover callback's
pointer argument (see L</Clay_SetPointerState> for how it changes).

=over 4

=item CLAY_POINTER_DATA_PRESSED_THIS_FRAME

The latest C<Clay_SetPointerState> call pressed the pointer.

=item CLAY_POINTER_DATA_PRESSED

The pointer was pressed earlier and is still down.

=item CLAY_POINTER_DATA_RELEASED_THIS_FRAME

The latest C<Clay_SetPointerState> call released the pointer.

=item CLAY_POINTER_DATA_RELEASED

The pointer was released earlier and is still up.

=back

=head2 Transition states

The C<transitionState> a transition handler receives.

=over 4

=item CLAY_TRANSITION_STATE_IDLE

No transition is running.

=item CLAY_TRANSITION_STATE_ENTERING

The element has just appeared and plays its enter transition.

=item CLAY_TRANSITION_STATE_TRANSITIONING

A property changed and the element moves towards the new value.

=item CLAY_TRANSITION_STATE_EXITING

The element is no longer declared and plays its exit transition.

=back

=head2 Transition properties

Bit flags for C<< transition => { properties => ... } >> and the
C<properties> argument of the transition callbacks: which values
animate. Combine them with C<|>.

=over 4

=item CLAY_TRANSITION_PROPERTY_NONE

Nothing (0).

=item CLAY_TRANSITION_PROPERTY_X

The horizontal position (1).

=item CLAY_TRANSITION_PROPERTY_Y

The vertical position (2).

=item CLAY_TRANSITION_PROPERTY_POSITION

C<X | Y> (3).

=item CLAY_TRANSITION_PROPERTY_WIDTH

The width (4).

=item CLAY_TRANSITION_PROPERTY_HEIGHT

The height (8).

=item CLAY_TRANSITION_PROPERTY_DIMENSIONS

C<WIDTH | HEIGHT> (12).

=item CLAY_TRANSITION_PROPERTY_BOUNDING_BOX

C<POSITION | DIMENSIONS> (15).

=item CLAY_TRANSITION_PROPERTY_BACKGROUND_COLOR

The background colour (16).

=item CLAY_TRANSITION_PROPERTY_OVERLAY_COLOR

The overlay colour (32).

=item CLAY_TRANSITION_PROPERTY_CORNER_RADIUS

The corner radius (64). Clay's transition data has no corner radius, so
in this Clay version the flag has no value to animate.

=item CLAY_TRANSITION_PROPERTY_BORDER_COLOR

The border colour (128).

=item CLAY_TRANSITION_PROPERTY_BORDER_WIDTH

The border widths (256).

=item CLAY_TRANSITION_PROPERTY_BORDER

C<BORDER_COLOR | BORDER_WIDTH> (384).

=back

=head2 Transition enter triggers

For C<< transition => { enter => { trigger => ... } } >>.

=over 4

=item CLAY_TRANSITION_ENTER_SKIP_ON_FIRST_PARENT_FRAME

No enter transition when the element appears in the same frame as its
parent (the default).

=item CLAY_TRANSITION_ENTER_TRIGGER_ON_FIRST_PARENT_FRAME

Play the enter transition even then.

=back

=head2 Transition exit triggers

For C<< transition => { exit => { trigger => ... } } >>.

=over 4

=item CLAY_TRANSITION_EXIT_SKIP_WHEN_PARENT_EXITS

No exit transition when the parent disappears too (the default).

=item CLAY_TRANSITION_EXIT_TRIGGER_WHEN_PARENT_EXITS

Play the exit transition even then.

=back

=head2 Transition interaction handling

For C<< transition => { interactionHandling => ... } >>: whether the
element (with its children) stays hit-testable while it transitions.

=over 4

=item CLAY_TRANSITION_DISABLE_INTERACTIONS_WHILE_TRANSITIONING_POSITION

Not hit-testable while entering, exiting or moving (the default).

=item CLAY_TRANSITION_ALLOW_INTERACTIONS_WHILE_TRANSITIONING_POSITION

Hit-testable except while exiting.

=back

=head2 Exit transition sibling ordering

For C<< transition => { exit => { siblingOrdering => ... } } >>: where
an exiting element is drawn relative to its siblings.

=over 4

=item CLAY_EXIT_TRANSITION_ORDERING_UNDERNEATH_SIBLINGS

Below its siblings (the C default).

=item CLAY_EXIT_TRANSITION_ORDERING_NATURAL_ORDER

At its usual place among its siblings.

=item CLAY_EXIT_TRANSITION_ORDERING_ABOVE_SIBLINGS

Above its siblings.

=back

=head2 Error types

The C<errorType> the error handler receives (see L</CALLBACKS>).

=over 4

=item CLAY_ERROR_TYPE_TEXT_MEASUREMENT_FUNCTION_NOT_PROVIDED

Clay found no measure function. Clay::XS always gives Clay one, so it
reports a missing Perl measure function as a held error instead (see
L</Clay_SetMeasureTextFunction>).

=item CLAY_ERROR_TYPE_ARENA_CAPACITY_EXCEEDED

The arena passed to C<Clay_Initialize> is too small.

=item CLAY_ERROR_TYPE_ELEMENTS_CAPACITY_EXCEEDED

The frame needs more elements, text lines or render commands than the
element count allows (see L</Clay_SetMaxElementCount>), or its elements
and the copies of elements with exit transitions do not fit together
(see L</FUNCTIONS: TRANSITIONS>).

=item CLAY_ERROR_TYPE_TEXT_MEASUREMENT_CAPACITY_EXCEEDED

The text measurement cache is full (see
L</Clay_SetMaxMeasureTextCacheWordCount>).

=item CLAY_ERROR_TYPE_DUPLICATE_ID

Two elements in one frame have the same id.

=item CLAY_ERROR_TYPE_FLOATING_CONTAINER_PARENT_NOT_FOUND

A floating element's C<parentId> names no element.

=item CLAY_ERROR_TYPE_PERCENTAGE_OVER_1

A C<PERCENT> sizing axis is above 1.

=item CLAY_ERROR_TYPE_INTERNAL_ERROR

Clay caught an out-of-bounds access in itself (a Clay bug).

=item CLAY_ERROR_TYPE_UNBALANCED_OPEN_CLOSE

Elements were still open at the end of the frame. Clay::XS closes them
before Clay checks and croaks itself (see L</ELEMENTS AND FRAMES>).

=item CLAY_ERROR_TYPE_HASH_MAP_CAPACITY_EXCEEDED

Clay's element id table is full (see L</Clay_SetMaxElementCount>).

=item CLAY_ERROR_TYPE_SIZING_GROUP_CYCLE

Sizing groups are nested in a cycle (see L</SIZING GROUPS>).

=back

=head1 MAPPING C MACROS TO PERL

The Clay C macros expand to calls of internal functions. This is how
to spell each one in Perl:

=over 4

=item CLAY_ID

    CLAY_ID("foo")               ->  Clay_GetElementId("foo")

=item CLAY_IDI

    CLAY_IDI("foo", 3)           ->  Clay_GetElementIdWithIndex("foo", 3)

=item CLAY_ID_LOCAL

    CLAY_ID_LOCAL("foo")         ->  Clay__HashString("foo", Clay_GetOpenElementId())

=item CLAY_IDI_LOCAL

    CLAY_IDI_LOCAL("foo", 3)     ->  Clay__HashStringWithOffset("foo", 3, Clay_GetOpenElementId())

=item CLAY_SIZING_FIT

    CLAY_SIZING_FIT($min, $max)  ->  sizing_fit($min, $max)

=item CLAY_SIZING_GROW

    CLAY_SIZING_GROW($min, $max) ->  sizing_grow($min, $max)

=item CLAY_SIZING_FIXED

    CLAY_SIZING_FIXED($size)     ->  sizing_fixed($size)

=item CLAY_SIZING_PERCENT

    CLAY_SIZING_PERCENT($pct)    ->  sizing_percent($pct)

=item CLAY_PADDING_ALL

    CLAY_PADDING_ALL($v)         ->  padding_all($v)

=item CLAY_BORDER_ALL

    CLAY_BORDER_ALL($v)          ->  border_all($v)

=item CLAY_BORDER_OUTSIDE

    CLAY_BORDER_OUTSIDE($v)      ->  border_outside($v)

=item CLAY_CORNER_RADIUS

    CLAY_CORNER_RADIUS($r)       ->  corner_radius_all($r)

=item CLAY

    CLAY(id, { ... }) { ... }    ->
        Clay__OpenElementWithId($id);
        Clay__ConfigureOpenElement({ ... });
        # ... children declared here ...
        Clay__CloseElement();

=item CLAY_AUTO_ID

    CLAY_AUTO_ID({ ... }) { ... } ->
        Clay__OpenElement();
        Clay__ConfigureOpenElement({ ... });
        # ... children ...
        Clay__CloseElement();

=item CLAY_TEXT

    CLAY_TEXT($text, { ... })    ->  Clay__OpenTextElement($text, { ... })

=item scrollPosition (programmatic scrolling)

    Clay_GetScrollContainerData(id).scrollPosition->y = -40
                                 ->  set_scroll_position($id, {
                                         x => Clay_GetScrollContainerData($id)->{scrollPosition}{x},
                                         y => -40,
                                     })

In C, programmatic scrolling writes through the C<scrollPosition>
pointer that C<Clay_GetScrollContainerData> returns.
L</set_scroll_position> does that write. It sets both axes (a missing
key means 0), so pass the current value of the axis you keep. It croaks
unless the id names a scroll container Clay knows: one declared with
C<clip> enabled in a completed frame.

=back

For the C<max> of the C<sizing_*> helpers, a finite number above 0 is
the maximum; 0, a negative number, C<+Inf> or a number beyond the
C<float> range means no maximum.

=head1 CONTEXTS

A I<context> is one independent Clay instance with its own memory,
layout state, callbacks and settings.

=over 4

=item *

C<Clay_Initialize($capacity, $dimensions, $error_handler, $userdata)>
returns a C<Clay::XS::Context> object and makes it current (see
L</Clay_Initialize>).

=item *

Every other function that touches Clay works on the I<current context>
and croaks C<< <function>: no current Clay context; call Clay_Initialize first >> if there is none.

=item *

C<Clay_SetCurrentContext($ctx)> switches contexts.
C<Clay_GetCurrentContext()> returns the current context (another
reference to the same object) or undef.

=back

=head2 Lifetime

The context is freed when the last reference to it goes away. Freeing
the current context leaves no context current.

Copies made with L<Storable> and hand-blessed objects are not contexts:
they croak C<Clay::XS: argument is not a live Clay::XS::Context> when
used.

Freeing a context that still holds a callback error (because a frame
was left unfinished) warns C<Clay::XS: context destroyed with a held callback error: ...>.

=head2 Threads

Clay keeps one process-wide current context, so a context belongs to
the interpreter that created it and is not copied into new threads.

While another thread's context is current, every call that touches Clay
(C<Clay_Initialize> included) croaks C<< <function>: the current Clay::XS context belongs to a different interpreter/thread (Clay has one process-wide current context) >>. Only C<Clay_SetCurrentContext> with
one of the thread's own contexts works.

=head2 Element and word counts

C<Clay_SetMaxElementCount> and C<Clay_SetMaxMeasureTextCacheWordCount>
take effect at the next C<Clay_Initialize>, which sizes the new context
for them.

=over 4

=item *

The word count must be at least 32, and at most 32 words per element.

=item *

Without a current context, C<Clay_SetMaxElementCount> also sets the
word count to twice the element count, as Clay does. Set the word count
after the element count. C<Clay_Initialize> croaks for fewer than 32
words.

=item *

Calling a setter on a live context is allowed, but every call that
touches that context then croaks C<< <function>: element/word counts changed since Clay_Initialize; call Clay_Initialize again >> until
C<Clay_Initialize> has been called again: Clay's arrays keep the sizes
they were created with. Only C<Clay_Initialize>,
C<Clay_SetCurrentContext>, C<Clay_GetCurrentContext>,
C<Clay_MinMemorySize> and the four count setters and getters keep
working; every other function that needs a context croaks, queries
such as C<Clay_GetLayoutDimensions> included.

=item *

Counts whose arena would exceed 4 GiB are rejected.

=back

=head1 ELEMENTS AND FRAMES

A I<frame> is C<Clay_BeginLayout()>, the element declarations, and
C<Clay_EndLayout($delta_time)>, which returns the render commands.

=head2 Rules for declarations

Element declarations are checked for balance and order:

=over 4

=item *

C<Clay__OpenElement>, C<Clay__OpenElementWithId> and
C<Clay__OpenTextElement> croak outside a frame.

=item *

C<Clay__CloseElement>, C<Clay__ConfigureOpenElement> and C<Clay_OnHover>
croak when no element is open.

=item *

C<Clay__ConfigureOpenElement> configures the element just opened, once,
before any child is declared (as the C C<CLAY()> macro does). A second
call, or one after a child, croaks.

=item *

C<Clay_SetPointerState> and C<Clay_UpdateScrollContainers> work on the
layout of the last completed frame. They croak between
C<Clay_BeginLayout> and C<Clay_EndLayout>, also while a frame is left
unfinished (see below).

=item *

C<Clay_EndLayout> croaks without a matching C<Clay_BeginLayout>. If
elements are still open (for example because an exception interrupted a
declaration), it closes them, lets Clay finish the frame, and croaks
C<N element(s) still open at Clay_EndLayout (unbalanced Clay__OpenElement/Clay__CloseElement)>. When a callback error is held
as well, the message continues with C<; callback error:> and that
error's message; a held exception object is re-thrown unchanged
instead. The next frame works normally.

=item *

A frame that is never ended is I<unfinished>. The next
C<Clay_BeginLayout> finishes it like C<Clay_EndLayout> with a delta time
of 0 would (it closes the elements still open, lets Clay compute the
layout and discards the render commands), so Clay never begins a frame
over an unfinished one. The finished frame counts as a completed frame:
elements it did not declare start their exit transitions in it, and
the pointer and scroll functions work on its layout. If the unfinished
frame held a callback error, that C<Clay_BeginLayout> then re-throws it
and starts no frame (see L</ERRORS FROM CALLBACKS>); otherwise it starts
the new frame at once.

=back

=head2 How values are parsed

Every struct field is parsed when it crosses into Clay. These croak a
L</STRUCT ERRORS> object naming the struct and field:

=over 4

=item *

wrong reference types, at any nesting level;

=item *

non-numeric numbers;

=item *

numbers that are not finite as a C C<float>: NaN, infinities, and
values beyond about 3.4e38 (the C<max> of a sizing axis may be C<+Inf>
or larger, meaning no maximum);

=item *

integers outside the C field's range, for example negative padding or
an enum value Clay does not define.

=back

An example message: C<Clay_ElementDeclaration.layout.padding.left: expected an integer in 0..65535, got '-8'>.

Further rules:

=over 4

=item *

C<userData>, C<imageData> and C<customData> take an unsigned integer
that fits a pointer (C<refaddr> values do), read exactly. Pass integers
above 2**53 as Perl integers or decimal strings, not as floats.

=item *

Unknown keys are ignored, and so are extra array elements.
L</check_struct> reports both.

=item *

C<< floating => { parentId => ... } >> accepts a numeric id or an
element id hash from C<Clay_GetElementId>.

=back

=head1 CHECKING STRUCTS

=for highlighter language=perl

    check_struct('Clay_LayoutConfig', $layout);
    check_struct('Clay_Padding', $padding, 'layout.padding');

C<check_struct($type, $value, $root)> validates C<$value> as the struct
named by its exact C type (C<Clay_ElementDeclaration>,
C<Clay_LayoutConfig>, C<Clay_TextElementConfig>, C<Clay_Color>,
C<Clay_SizingAxis>, ...; L</check_struct> lists every accepted name,
which excludes C<Clay_ElementId>) without a context or a frame.

=over 4

=item *

It returns nothing and croaks a L</STRUCT ERRORS> object for the first
problem. An unknown type name croaks a plain string.

=item *

The error path starts at C<$root>, or at the type name when C<$root> is
undef.

=item *

An undef C<$value> is accepted: it means the zero struct.

=back

It applies the same rules as the parse that runs when the value crosses
into Clay (see L</How values are parsed>), and is stricter in three
ways:

=over 4

=item *

unknown keys croak, and the error lists the known ones;

=item *

an arrayref must have exactly one element per field (four for a
colour);

=item *

a boolean field must not be a reference.

=back

Shape errors of a few structs carry a hint, for example
C<(padding_all(N) builds one)>.

=head1 STRUCT ERRORS

Struct values that cannot be used croak a C<Clay::XS::StructError>
object, both when they cross into Clay and from L</CHECKING STRUCTS>.
Bad element id arguments croak one too.

=head2 Clay::XS::StructError

A C<Clay::XS::StructError> object is true in boolean context and stringifies like a plain
croak message:

=for highlighter language=text

    <path>: expected <what>, got <value>[ (<hint>)] at <file> line <n>.

For example:

    Clay_ElementDeclaration.layout.padding.left: expected an integer in 0..65535, got '-8' at app.pl line 12.

Its readers:

=over 4

=item C<path>

Arrayref of names from the root (the struct or function argument) to
the field, e.g. C<['Clay_ElementDeclaration', 'layout', 'padding', 'left']>.

=item C<expected>

What the field takes, e.g. C<an integer in 0..65535>.

=item C<got>

How the value was seen, e.g. C<'-8'>, C<undef> or C<a HASH reference>.

=item C<hint>

A hint for building the value, or undef. Only L</CHECKING STRUCTS> sets
it.

=item C<unknown_keys>

For an unknown-key error: an arrayref of the offending keys, sorted.
Undef otherwise.

=item C<known_keys>

For an unknown-key error: an arrayref of the keys the struct takes.
Undef otherwise.

=item C<message>

The message without the location.

=item C<file>

The file where the croak happened.

=item C<line>

The line where the croak happened.

=back

=for highlighter language=perl

    use Scalar::Util qw(blessed);

    eval { check_struct('Clay_Padding', { lft => 4 }) };
    if (blessed $@ && $@->isa('Clay::XS::StructError')) {
        warn "unknown keys: @{ $@->unknown_keys }\n";
    }

Errors raised inside a callback (for example a bad transition handler
result) are re-thrown unchanged, as described in L</ERRORS FROM
CALLBACKS>. Plain function arguments that are not structs (counts,
floats, callbacks) croak plain strings.

=head1 STRINGS

Strings are characters in and out.

=over 4

=item *

Text and element ids may contain any Unicode characters. They reach
Clay as UTF-8.

=item *

Text in render commands, the measure function's text and the
C<stringId> of element ids come back as Perl character strings.

=item *

Clay splits words only at ASCII spaces and newlines, so the pieces it
measures never cut a character.

=back

Clay::XS copies text into per-context storage and interns element id
strings, so the caller never has to keep strings alive between calls.

Undef text and undef id strings croak. So does every function that
takes an element id (C<Clay__OpenElementWithId>, C<Clay_GetElementData>,
C<Clay_PointerOver>, C<Clay_GetScrollContainerData>,
C<set_scroll_position>) when it gets anything but an element id hash
reference, undef included.

=head1 CALLBACKS

All callbacks are code references, validated when installed. Undef
clears a per-context callback. The callback and userdata values are
copied, so reassigning the caller's variables afterwards has no effect.
Every callback gets its userdata (or undef) as its last argument.

=over 4

=item Error handler (C<Clay_Initialize>)

    $handler->({ errorType => CLAY_ERROR_TYPE_..., errorText => $text }, $userdata)

=over 4

=item C<errorType>

One of the L</Error types>.

=item C<errorText>

Clay's message, a human-readable string.

=back

The return value is ignored. Without a handler, Clay errors
are ignored (as in C).

=item Measure function (C<Clay_SetMeasureTextFunction($cb, $userdata)>)

    $cb->($text, \%text_config, $userdata) -> { width => $w, height => $h } or [ $w, $h ]

C<%text_config> has the C<Clay_TextElementConfig> fields. Every context
that lays out text needs its own measure function: measuring text in a
context without one is reported as an error. A result of undef (a
forgotten C<return>, say) is an error too. See
L</Clay_SetMeasureTextFunction>.

=item Query-scroll function (C<Clay_SetQueryScrollOffsetFunction($cb, $userdata)>)

    $cb->($element_id, $userdata) -> { x => $x, y => $y } or [ $x, $y ]

C<$element_id> is the numeric id. An undef result is an error. Clay
calls it for every scroll container while
C<Clay_SetExternalScrollHandlingEnabled(1)> is on; the returned offset
becomes the container's scroll position. Enabling external handling
without a query function croaks.

=item Hover callback (C<Clay_OnHover($cb, $userdata)>)

    $cb->(\%element_id, { position => { x, y }, state => CLAY_POINTER_DATA_... }, $userdata)

Registers a hover callback for the currently open element. Clay forgets
an element's hover callback whenever the element is declared again, so
call C<Clay_OnHover> every frame. C<Clay_SetPointerState> runs the
callbacks registered while declaring the last completed frame, with the
new position and the pointer state from before the call. The return
value is ignored.

=item Transition handlers (C<Clay_SetTransitionHandlers($handler, $set_initial, $set_final, $userdata)>)

    $handler->(\%args, $userdata) -> $complete
    $set_initial->(\%target_state, $properties, $userdata) -> \%initial_state
    $set_final->(\%initial_state, $properties, $userdata) -> \%final_state

One handler set per context serves every element with a C<transition>
config (Clay's transition callbacks carry no element id). Clay calls
them during C<Clay_EndLayout>.

=over 4

=item *

C<%args> is a L<Clay::XS::Structs/Clay_TransitionCallbackArguments>
hash with these keys:

=over 4

=item C<transitionState>

One of the L</Transition states>.

=item C<initial>

Transition data: the state when the transition started.

=item C<target>

Transition data: the state the transition moves to.

=item C<current> (transition handler)

Transition data: the state to draw now; the handler updates it.

=item C<elapsedTime>

Seconds since the transition started.

=item C<duration>

The element's transition duration in seconds.

=item C<properties>

The element's L</Transition properties>, the ones being animated.

=back

=item *

The handler updates C<< $args->{current} >> (keys it leaves out keep
their value) and returns true when the transition is complete. Undef
also counts as complete. Assigning anything but a hash reference to
C<$_[0]> is an error (C<Clay::XS: transition handler replaced its argument hash>);
a new hash reference assigned to C<$_[0]> replaces the argument hash,
and its C<current> is used.

=item *

I<Transition data> hashes have the keys C<boundingBox>
(C<< { x, y, width, height } >>), C<backgroundColor>, C<overlayColor>,
C<borderColor> (C<< { r, g, b, a } >>) and C<borderWidth> (a
C<Clay_BorderWidth>).

=item *

An element's C<< transition => { enter => { hasSetInitial => 1 } } >>
routes its enter transition through C<$set_initial>, which turns the
target state into the state the element starts from.
C<< exit => { hasSetFinal => 1 } >> gives it an exit transition through
C<$set_final>, which turns the last state into the state it ends in.
Undef from either means "unchanged"; a returned hash only changes the
keys it has.

=item *

Without a C<$handler>, elements declared with a C<transition> key have
no transitions at all: Clay::XS leaves Clay's handler NULL, as a C
program without one would, and changes show at once (see
L</FUNCTIONS: TRANSITIONS>). Handlers apply to the elements declared
after they were installed. Without C<$set_initial> or C<$set_final>, the
state stays unchanged.

=item *

The C default for C<< exit => { siblingOrdering } >> is
C<CLAY_EXIT_TRANSITION_ORDERING_UNDERNEATH_SIBLINGS>.

=back

=back

C<Clay_EaseOut(\%args)> takes the same argument hash (C<current>
defaults to C<initial> when absent) and returns
C<< { complete => $bool, current => \%eased_state } >>, easing every
property selected in C<properties>, colours and border widths included
(see L</Clay_EaseOut>).

=head2 What a callback may do

A callback runs while Clay is in the middle of one of its own
functions, so it must not change Clay's state.

Inside a callback, these croak with
C<< <function>: cannot be called from inside a Clay callback >>
(re-thrown like any other callback error, see L</ERRORS FROM
CALLBACKS>): C<Clay_Initialize>,
C<Clay_SetCurrentContext>, C<Clay_BeginLayout>, C<Clay_EndLayout>, the
element functions (C<Clay__OpenElement>, C<Clay__OpenElementWithId>,
C<Clay__ConfigureOpenElement>, C<Clay__OpenTextElement>,
C<Clay__CloseElement>, C<Clay_OnHover>), the queries about the open
element (C<Clay_GetOpenElementId>, C<Clay_Hovered>,
C<Clay_GetScrollOffset>), C<Clay_SetPointerState>,
C<Clay_UpdateScrollContainers>, C<set_scroll_position>, and every
setter (C<Clay_SetLayoutDimensions>, C<Clay_SetMeasureTextFunction>,
C<Clay_ResetMeasureTextCache>, C<Clay_SetQueryScrollOffsetFunction>,
C<Clay_SetExternalScrollHandlingEnabled>, C<Clay_SetTransitionHandlers>,
C<Clay_SetDebugModeEnabled>, C<Clay_SetCullingEnabled>,
C<Clay_SetMaxElementCount>, C<Clay_SetMaxMeasureTextCacheWordCount>).

These calls are refused whichever context is current: Clay has a
single current context. A refused call reads none of its arguments, so
no tie, get-magic or overload of an argument runs. The refusal also covers code that runs when
the callback's arguments are freed after it returns (a C<DESTROY> of
an object that only an argument held, say), because Clay has not
returned yet.

An explicit C<DESTROY> of the current context croaks the same way
(C<Clay::XS::Context::DESTROY: cannot be called ... for the context the callback runs in>).

Read-only queries work: C<Clay_GetCurrentContext>,
C<Clay_GetLayoutDimensions>, C<Clay_GetElementData>,
C<Clay_GetPointerState>, C<Clay_PointerOver>, C<Clay_GetPointerOverIds>,
C<Clay_GetScrollContainerData>, C<Clay_IsDebugModeEnabled>,
C<Clay_GetMaxElementCount>, C<Clay_GetMaxMeasureTextCacheWordCount> and
the helpers that need no context (ids, hashing, the ease function, the
sizing helpers, check_struct). A query called inside a callback never
re-throws a held error; see L</ERRORS FROM CALLBACKS>.

A callback runs on a Perl stack of its own, so loop control cannot
leave it: C<last>, C<next>, C<redo> or C<goto> aimed at a loop or label
outside the callback dies inside it (C<Label not found for "last FRAME">,
C<Can't "last" outside a loop block>), and that error is re-thrown like
any other. C<die> and C<return> behave as usual.

C<exit> in a callback takes effect once Clay has returned: no further
callback runs, and the Clay::XS function that called into Clay exits
with the status right after Clay's call, before it would re-throw
anything. C<END> blocks and destructors then run as for any exit and may
use Clay::XS again. Code that runs while the exit unwinds the scopes of
the program (a C<DESTROY> of a lexical going out of scope, say) runs
while Clay has not returned yet, so the calls listed above croak there.

Dropping the last reference to the running context inside a callback
is safe: every Clay::XS call keeps its context alive until the
statement that made the call has finished, and the context is freed
then.

=head1 ERRORS FROM CALLBACKS

Clay calls the callbacks from inside its C code, which must never be
unwound by a Perl exception. An exception thrown by a callback (or a
malformed callback result, such as a measure function returning a
plain number) is therefore I<held> until Clay returns, then re-thrown
by the Clay::XS function that invoked Clay.

=head2 Which function re-throws

=over 4

=item *

C<Clay_EndLayout> re-throws errors from the measure function, the error
handler, the query-scroll function and the transition handlers,
including those raised while elements were being declared.

=item *

C<Clay_SetPointerState> re-throws errors from hover callbacks.

=item *

An error held when a frame is left unfinished (including one raised
while C<Clay_BeginLayout> finishes it) is re-thrown by the next
C<Clay_BeginLayout> with the suffix C<(from the previous unfinished frame)>.

=item *

A C<Clay_Initialize> whose error handler failed croaks with that error
and leaves the previous context current.

=item *

Every other function that needs a context re-throws a held error once
its Clay call has returned, so its own effect (a setter's new value,
say) has already taken place. The exceptions are listed next.

=item *

Between C<Clay_BeginLayout> and C<Clay_EndLayout> nothing re-throws: a
query called in the middle of a declaration (C<Clay_PointerOver> to
pick a colour, say) returns normally, the elements stay open as
declared, and C<Clay_EndLayout> re-throws the error.

=back

These never re-throw a held error: the element-construction functions
(C<Clay__OpenElement>, C<Clay__OpenElementWithId>,
C<Clay__ConfigureOpenElement>, C<Clay__OpenTextElement>,
C<Clay__CloseElement>, C<Clay_OnHover>) and the in-element queries
(C<Clay_GetOpenElementId>, C<Clay_Hovered>, C<Clay_GetScrollOffset>),
so declarations stay balanced and their errors surface when the frame
ends; and the functions that manage contexts and configuration rather
than layout state (C<Clay_SetCurrentContext>, C<Clay_GetCurrentContext>,
C<Clay_MinMemorySize>, C<Clay_GetMaxElementCount>,
C<Clay_SetMaxElementCount>, C<Clay_GetMaxMeasureTextCacheWordCount>,
C<Clay_SetMaxMeasureTextCacheWordCount>). Neither do the helpers that
need no context.

Nothing is re-thrown while a callback runs: a query called from a
callback leaves a held error in place for the function that invoked
Clay.

=head2 What the error looks like

=over 4

=item *

Only the first error of a frame is kept. Later ones are counted, and
the message gains C< (and N more callback errors this frame)>, or
C< (and 1 more callback error this frame)> for one.

=item *

Exception objects (including a L</STRUCT ERRORS> object for a
malformed callback result) are re-thrown unchanged, without either
suffix.

=item *

The render commands of a frame whose C<Clay_EndLayout> croaked are
discarded.

=item *

Callbacks do not disturb the caller's C<$@>.

=back

=head2 Measuring after a failure

While the context holds a callback error of any kind (from the measure
function, the error handler, the query-scroll function or a transition
handler), text is measured as 0 x 0 without calling the measure
function, until the error has been re-thrown. A broken measure function
therefore causes one exception per frame. When the held error is
re-thrown, Clay's measurement cache is reset if any text was measured
as 0 x 0 (or failed to measure) in the meantime, so the next frame
measures afresh.

=head1 RENDER COMMANDS

C<Clay_EndLayout> returns an array reference of hashes, one per
C<Clay_RenderCommand>:

    {
        id          => $id,                # numeric id, see below
        commandType => CLAY_RENDER_COMMAND_TYPE_...,
        zIndex      => $z,
        boundingBox => { x => ..., y => ..., width => ..., height => ... },
        userData    => $integer,           # 0 when none was set
        renderData  => { ... },            # depends on commandType
    }

=over 4

=item C<boundingBox>

Where to draw, in layout coordinates (the layout's top left corner is
0, 0). Children of a scroll container are already moved by its
C<childOffset>, except with external scroll handling on (see
L</Clay_SetExternalScrollHandlingEnabled>).

=item C<commandType>

One of the L</Render command types>; selects the C<renderData> keys.

=item C<zIndex>

The C<zIndex> of the floating element the command belongs to, 0 for
the main tree. The array is already sorted for drawing: draw the
commands in array order and later commands correctly cover earlier
ones. C<zIndex> only helps renderers that batch commands; every command
of a floating element carries its C<zIndex>.

=item C<id>

The numeric id of the element the command belongs to. C<TEXT>,
C<BORDER> and C<SCISSOR_END> commands, the bars between children and
the C<SCISSOR_START> of a clipped floating element carry ids that Clay
derives from the element's id.

=item C<userData>

The element's C<userData> (for C<TEXT>: the text config's C<userData>),
an unsigned integer Clay passes through unchanged. L<Clay::UI> uses it
to find the widget behind a command.

=item C<renderData>

A hash whose keys depend on the type, described below. Colours are
C<< { r, g, b, a } >> hashes, conventionally 0 to 255 per channel (the
renderer decides). Corner radii are C<< { topLeft, topRight,
bottomLeft, bottomRight } >> hashes.

=back

For one element, Clay emits in this order: C<OVERLAY_COLOR_START>,
C<IMAGE>, C<CUSTOM>, C<SCISSOR_START>, C<RECTANGLE>, then the commands
of its children, then C<BORDER>, the bars between children,
C<OVERLAY_COLOR_END> and C<SCISSOR_END>. Each is present only when the
declaration asks for it. Colours with alpha 0 emit nothing: no
C<RECTANGLE> for a transparent C<backgroundColor>, no overlay commands
for a transparent C<overlayColor>. A C<BORDER> is emitted for any width
above 0, whatever the alpha of its colour, so a renderer that draws
borders without a colour of their own (a terminal's default colour) still
sees them. An C<IMAGE> or C<CUSTOM> element emits no C<RECTANGLE>: its
C<backgroundColor> travels in its own command.

With culling on (the default, see L</Clay_SetCullingEnabled>), elements
entirely outside the layout dimensions emit no commands, except that a
culled clip container still emits its C<SCISSOR_START> and
C<SCISSOR_END>. Culling does not look at clip containers: content that
a clip container hides but that lies within the layout is still
emitted, and the scissor commands clip it. A child that reaches into
the layout from a culled clip container is emitted between its scissor
commands, so it stays clipped.

=head2 CLAY_RENDER_COMMAND_TYPE_NONE

Draw nothing; skip the command. C<renderData> is empty.

=head2 CLAY_RENDER_COMMAND_TYPE_RECTANGLE

Fill C<boundingBox> with a colour.

    renderData => { backgroundColor => { r, g, b, a }, cornerRadius => { ... } }

Clay emits it for an element whose C<backgroundColor> has an alpha
above 0 (unless the element is an image or custom element, whose
command carries the colour), and for each bar between children (see
the C<BORDER> command below). Round each corner by drawing a
circle of the corner's radius inset into that corner.

=head2 CLAY_RENDER_COMMAND_TYPE_BORDER

Draw a border inside C<boundingBox>.

    renderData => {
        color        => { r, g, b, a },
        cornerRadius => { topLeft, topRight, bottomLeft, bottomRight },
        width        => { left, right, top, bottom, betweenChildren },
    }

Draw each side with its own width, inset into the box (the outer edge
of the border is the edge of C<boundingBox>), and round the corners
with C<cornerRadius> (the element's corner radius). Clay emits it after
the element's children, so the border covers them.

Ignore C<< width->{betweenChildren} >>: Clay emits the bars between
children as separate C<RECTANGLE> commands right after the C<BORDER>
command, in the border colour, and only when that colour's alpha is
above 0. For a C<CLAY_LEFT_TO_RIGHT_WRAP> container see
L</FLOW LAYOUT>; a C<CLAY_BACK_TO_FRONT> container gets no bars.

Clay emits a C<BORDER> command when at least one width (including
C<betweenChildren>) is above 0.

=head2 CLAY_RENDER_COMMAND_TYPE_TEXT

Draw one line of text.

    renderData => {
        stringContents => $line,           # Perl character string
        stringOffset   => $characters,     # where the line starts in the element's text
        textColor      => { r, g, b, a },
        fontId         => $font_id,
        fontSize       => $size,
        letterSpacing  => $spacing,
        lineHeight     => $line_height,    # 0 when not set
    }

Clay emits one command per non-empty line of a text element.
C<stringOffset> is the number of characters of the element's text
before the line, so C<substr($text, $offset, length $line)> is the line;
a renderer that styles ranges of the text finds the range of each line
with it. C<boundingBox> is the box of that line, already placed according to
C<textAlignment>. Draw C<stringContents> into it with the font
C<fontId> at size C<fontSize> and with C<letterSpacing> units between
characters, the same way the measure function measured it.
C<lineHeight> is the configured line height (the vertical distance
between lines), not a size to draw with. C<userData> is the text
config's C<userData>.

=head2 CLAY_RENDER_COMMAND_TYPE_IMAGE

Draw an image into C<boundingBox>.

    renderData => { backgroundColor => { r, g, b, a }, cornerRadius => { ... }, imageData => $integer }

C<imageData> is the integer from the declaration's
C<< image => { imageData => ... } >>; use it to look up the image (for
example as a key into your own table). C<backgroundColor> is the
declaration's C<backgroundColor>, meant as a tint; all zero means
"untinted". C<cornerRadius> rounds the image's corners.

The declaration's C<backgroundColor> reaches the renderer only here: an
image element emits no C<RECTANGLE> of its own.

=head2 CLAY_RENDER_COMMAND_TYPE_CUSTOM

Draw something your renderer defines.

    renderData => { backgroundColor => { r, g, b, a }, cornerRadius => { ... }, customData => $integer }

C<customData> is the integer from the declaration's
C<< custom => { customData => ... } >>; your renderer decides what it
means. C<backgroundColor> and C<cornerRadius> come from the declaration.
As with C<IMAGE>, the element emits no C<RECTANGLE> of its own:
C<backgroundColor> reaches the renderer only in this command.

=head2 CLAY_RENDER_COMMAND_TYPE_SCISSOR_START

Start clipping: until the matching C<SCISSOR_END>, draw only what lies
inside C<boundingBox>.

    renderData => { horizontal => 1|0, vertical => 1|0 }

C<boundingBox> is the box of the element whose declaration enables
C<clip>. C<horizontal> and C<vertical> say which axes it clips; a
renderer may clip only those axes or simply clip to the whole box.

A floating element with C<< clipTo => CLAY_CLIP_TO_ATTACHED_PARENT >>
gets its own C<SCISSOR_START> (with the box of the element that clips
its parent, and both flags 0) before its commands, and a C<SCISSOR_END>
after them.

Clip containers can be nested, so C<SCISSOR_START> / C<SCISSOR_END>
pairs nest. To restore the enclosing clip at a C<SCISSOR_END>, keep a
stack of clip rectangles.

=head2 CLAY_RENDER_COMMAND_TYPE_SCISSOR_END

End the clipping that the matching C<SCISSOR_START> began.

    renderData => { horizontal => 0, vertical => 0 }

C<boundingBox> and the flags are all zero. Clay emits it after the
element's border and the bars between its children, so they are
clipped too.

=head2 CLAY_RENDER_COMMAND_TYPE_OVERLAY_COLOR_START

Start tinting: until the matching C<OVERLAY_COLOR_END>, mix every
colour you draw with the overlay colour.

    renderData => { color => { r, g, b, a } }

Clay emits it for an element whose C<overlayColor> has an alpha above
0, before the element's own commands; it covers the element and all
its children. The intended effect is GLSL's
C<mix(drawn_colour, color.rgb, color.a)>, with C<a> scaled to 0 .. 1.
C<boundingBox> is all zero. Overlays nest like their elements.

=head2 CLAY_RENDER_COMMAND_TYPE_OVERLAY_COLOR_END

End the tint that the matching C<OVERLAY_COLOR_START> began.

    renderData => { color => { r => 0, g => 0, b => 0, a => 0 } }

C<boundingBox> and C<color> are all zero.

=head1 SIZING GROUPS

A patched Clay adds the declaration key
C<< sizingGroup => { width => $id, height => $id } >> (see
L<Clay::XS::Structs/sizingGroup>). L<Clay::UI::Grid> builds on it.

=for text Figure: images/sizing-groups.png in the distribution.

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-clay-xs/v0.06/images/sizing-groups.png" alt="Two forms with the rows Name, E-mail address and City, each a grey label followed by a blue input box. Without a sizing group every label is as wide as its text and the inputs start at different positions. With the labels in width_group 1 every label is as wide as E-mail address and the inputs line up."></p>

=end html

=over 4

=item *

Elements that share a non-zero group id on an axis are equalized to
the group's largest size on that axis, before Clay distributes free
space to C<GROW> elements.

=item *

C<FIT> and C<GROW> elements take part. C<FIXED> and C<PERCENT> sizes do
not depend on content, so they do not.

=item *

Each member stays within its own C<max>.

=item *

Members also share the group's largest minimum size (for text, its
longest word), so a parent that is too small compresses them like any
other children, down to that minimum, and text in them wraps. Members
whose parents compress alike, such as the rows of a grid, stay aligned.

=item *

Groups may nest: a member can contain members of other groups, as with
a grid inside a grid cell. Equalization repeats until the sizes settle,
widening containers (C<FIT> and C<GROW>) up the tree.

=item *

Nesting that forms a cycle on one axis (a member of group 1 contains a
member of group 2 whose other member contains a member of group 1)
cannot settle. Clay then reports C<CLAY_ERROR_TYPE_SIZING_GROUP_CYCLE>
through the error handler, stops equalizing after a fixed number of
rounds, and the members of the groups in the cycle keep unequal sizes.

=item *

Only elements declared in the frame take part. An element in its exit
transition (see L</FUNCTIONS: TRANSITIONS>) keeps the sizes of its last
frame, and so do the members inside it; they neither widen their groups
nor take space in their parents, so a group next to exiting members
keeps its size from frame to frame.

=back

Clay's own distribution of free and missing space stops once a step
changes nothing, so sizes too large for a float to take a small step
(beyond about 16 million layout units) end the frame instead of
stalling it.

=head1 FLOW LAYOUT

A second patch adds the layout direction C<CLAY_LEFT_TO_RIGHT_WRAP> and
the layout keys C<lineGap> and C<lineSizing> (see
L<Clay::XS::Structs/layout>).

A I<wrap container> lays its children out left to right and starts a
new line below whenever the next child would not fit into the remaining
inner width.

=for text Figure: images/flow-layout.png in the distribution.

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-clay-xs/v0.06/images/flow-layout.png" alt="Two wrap containers of the same size holding the same eight tags, which wrap onto three lines. With lineSizing GROW the lines share the container's extra height and the tags grow taller; with lineSizing FIT the lines stay as tall as their tags and the bottom of the container stays empty."></p>

=end html

=over 4

=item *

Lines are C<lineGap> units apart; children within a line C<childGap>.

=item *

Line breaks use the children's preferred widths. A child wider than the
container is compressed like any overflowing child (unless the
container clips horizontally) and gets a line of its own.

=item *

Within a line, C<GROW> children share the line's free width and stretch
to the line's height.

=back

Sizing the container:

=over 4

=item *

A C<FIT> wrap container prefers a single line and can be compressed
down to its widest child. Give it a C<GROW> or C<FIXED> width to make
it wrap inside its parent.

=item *

A C<FIT> height is the height of its lines.

=item *

When the container is taller than its lines, C<lineSizing> decides
what happens to the leftover height: C<CLAY_LINE_SIZING_GROW> (the
default) adds an equal share of it to every line;
C<CLAY_LINE_SIZING_FIT> keeps every line as tall as its tallest child.

=back

Alignment:

=over 4

=item *

C<childAlignment.x> aligns every line on its own.

=item *

C<childAlignment.y> aligns each child within its line and, with
C<CLAY_LINE_SIZING_FIT>, the block of lines within the container.

=item *

A child in its exit transition (see L</FUNCTIONS: TRANSITIONS>) takes
no space and starts no line: it is drawn where the next child goes,
aligned within that child's line. One placed before the first line
(exiting children come first unless their exit sibling ordering says
otherwise) aligns within the first line; with no line at all, it aligns
within the container.

=back

Borders between children (C<betweenChildren>) draw a vertical bar in
the C<childGap> between neighbours on a line, and a horizontal bar
across the container in every C<lineGap>. A vertical bar reaches
halfway into the C<lineGap>s around its line, or to the container's
edge above the first line and below the last one.

Wrapping is horizontal only: Clay sizes widths before heights, so
wrapping into columns cannot be expressed.

=head1 STACK LAYOUT

A third patch adds the layout direction C<CLAY_BACK_TO_FRONT>. A
I<stack container> places all its children on top of each other inside
its padding.

=for text Figure: images/stack-layout.png in the distribution.

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-clay-xs/v0.06/images/stack-layout.png" alt="A stack container: a blue picture fills it, a red badge sits in its top right corner and a dark caption bar runs along its bottom. The legend lists the three children: the picture, GROW on both axes; a layer aligned x RIGHT and y TOP holding the badge; a layer aligned y BOTTOM holding the caption bar."></p>

=end html

=over 4

=item *

Later children are drawn over earlier ones. C<childGap> is unused.

=item *

Both axes are sized the way the other directions size their off axis:
a C<FIT> stack is as wide as its widest child and as tall as its
tallest one (plus padding), C<GROW> children fill its inner size, and
children larger than a non-clipping stack are compressed to it.

=item *

C<childAlignment> places every child on its own, on both axes.

=item *

C<betweenChildren> borders draw nothing.

=back

The order also decides hit testing: Clay reports every element under
the pointer, and L<Clay::UI> sends a press to the child drawn on top
(see L<Clay::UI::Interaction>).

=head1 LIMITATIONS

=over 4

=item *

Per-element transition handlers are not supported. Clay's transition
callback signatures do not include the element id, so Clay::XS cannot
route a call to a different Perl code reference per element. Install
one set of handlers with C<Clay_SetTransitionHandlers>; it runs for
every transitioning element. Decide what to do from the values in the
callback arguments.

=item *

Contexts are per interpreter (see L</CONTEXTS>). One interpreter can
use several contexts with C<Clay_SetCurrentContext>; using Clay from
several threads at once is not supported.

=item *

Clay's layout arithmetic is single-precision and does not guard
against overflow. Sizes near the C<float> limit (text measured at about
1e38, say) can sum to infinity inside Clay, and C<Clay_EndLayout> may
then not return. Keep sizes in a realistic pixel range.

=item *

While the element count is exceeded, text that exiting elements still
show is kept until a frame fits again. Clay makes no copies of exiting
elements in such a frame, so Clay::XS cannot tell which text they use.

=back

=head1 SEE ALSO

L<Clay::UI>, L<Clay::Manual>, L<Clay::Cookbook>, L<Clay::XS::Structs>,
L<https://github.com/nicbarker/clay>.

=head1 LICENSE

This binding is released under the same zlib/libpng license as Clay
itself. See F<src/clay/LICENSE.md> for the upstream notice.

=cut
