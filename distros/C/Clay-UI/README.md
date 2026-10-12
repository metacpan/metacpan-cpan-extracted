# Clay::XS and Clay::UI

Perl bindings for [Clay](https://github.com/nicbarker/clay) v0.14, a
fast layout engine written in C. You describe a tree of boxes and text
with rules such as "grow to fill the space" or "children from top to
bottom"; Clay computes the position and size of everything and returns
a list of **render commands** ("draw a rectangle here", "draw this text
there"). Your code draws them - into a PNG, a PDF page, an SVG file, a
window or a terminal.

The distribution has two layers:

- **`Clay::XS`** - the low-level binding. Every Clay function under its
  C name (`Clay_BeginLayout`, `Clay_GetElementData`, ...); structs are
  Perl hashes with Clay's camelCase keys.
- **`Clay::UI`** - a widget layer built with Object::Pad. You build a
  tree of widget objects once, change it when your data changes, and
  call `$ui->render`. It adds pointer events (hover, press, release,
  scroll), keyboard focus, tables with auto-sized columns, and a
  revision counter that tells you when a frame must be redrawn.

Clay is vendored; there is no system library to install.

## Install

```sh
perl Makefile.PL
make
make test
make install
```

Requirements: Perl 5.26+, a C99 compiler (GCC or Clang), the `patch`
program, ExtUtils::MakeMaker 7.12+, Object::Pad 0.800+ and
Object::PadX::Enum. Tests need Test2::V0 and JSON::PP. The examples
that write images or PDFs need Imager or PDF::Builder (see the table
below).

To run scripts against the built but not installed module:

```sh
perl -Ilib -Iblib/lib -Iblib/arch examples/01-minimal.pl
```

## A first layout with Clay::UI

```perl
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.800;
use Clay::XS qw(:all);
use Clay::UI;
use Clay::UI::Box;
use Clay::UI::Text;

# Clay::UI ships roles; a widget class is one line that composes them.
class My::Box  :strict(params) :does(Clay::UI::Box)  {}
class My::Text :strict(params) :does(Clay::UI::Text) {}

my $root = My::Box->new(
	layout => {
		sizing          => { width => sizing_grow(), height => sizing_grow() },
		padding         => padding_all(16),
		child_alignment => { x => CLAY_ALIGN_X_CENTER, y => CLAY_ALIGN_Y_CENTER },
	},
	background_color => [240, 240, 240, 255],
);
$root->add_child(My::Text->new(text => 'Hello, Clay', font_size => 24, text_color => [0, 0, 0, 255]));

my $ui       = Clay::UI->new(width => 800, height => 600, root => $root);
my $commands = $ui->render;

for my $command (@$commands) {
	my $box = $command->{boundingBox};
	printf "%-8s at %g,%g size %gx%g\n", ref $ui->widget_for($command->{userData}), @$box{qw(x y width height)};
}
```

## The same with Clay::XS

```perl
use v5.22;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Clay::XS qw(:all);

my $ctx = Clay_Initialize(
	Clay_MinMemorySize(),
	{ width => 800, height => 600 },
	sub ($error, $userdata) { die "Clay error: $error->{errorText}\n" },
);
Clay_SetMeasureTextFunction(sub ($text, $config, $userdata) {
	return { width => length($text) * $config->{fontSize}, height => $config->{fontSize} };
});

Clay_BeginLayout();
Clay__OpenElementWithId(Clay_GetElementId('root'));
Clay__ConfigureOpenElement({
	layout => {
		sizing         => { width => sizing_grow(), height => sizing_grow() },
		padding        => padding_all(16),
		childAlignment => { x => CLAY_ALIGN_X_CENTER, y => CLAY_ALIGN_Y_CENTER },
	},
	backgroundColor => [240, 240, 240, 255],
});
Clay__OpenTextElement('Hello, Clay', { fontSize => 24, textColor => [0, 0, 0, 255] });
Clay__CloseElement();
my $commands = Clay_EndLayout();
printf "%d render commands\n", scalar @$commands;    # 2: the rectangle and the text
```

## Documentation

After installation, read the documents with `perldoc`; in the source
tree, with `perldoc lib/Clay/Manual.pod`. On GitHub, every document
is also a Markdown page in
[`docs/`](https://github.com/davenonymous/perl-clay-xs/tree/master/docs),
starting with
[Clay::Manual](https://github.com/davenonymous/perl-clay-xs/blob/master/docs/Clay/Manual.md).

| Document | What it contains |
|---|---|
| `Clay::Manual` | The user guide: concepts, the layout model, text, renderers, events, focus, a feature index and a glossary. **Start here.** |
| `Clay::Cookbook` | Recipes for common tasks: center an element, make a table, show a tooltip, render to PDF, paginate. |
| `Clay::XS` | Reference for every low-level function and constant, render commands, callbacks and errors. |
| `Clay::XS::Structs` | Reference for every key of an element declaration and every other struct. |
| `Clay::UI` | Reference for the widget layer. Each widget role (`Clay::UI::Box`, `Clay::UI::Text`, `Clay::UI::Grid`, `Clay::UI::Role::...`) and event class has its own page. |

Every function, method, attribute and struct key has a heading or an
`=item` of its own, spelled as in code, so
`grep -rnE '^=(head.|item) (C<)?scroll_to' lib/` finds it.

The Manual and the Cookbook illustrate the layout model with figures
from [`images/`](images/), each laid out by Clay itself and drawn with
Imager by `tools/make-images` (`make images` regenerates them, `make
images-check` reports stale ones). `perldoc` names the figure files
where the HTML shows them.

## Examples

All examples run headless. Those that write a PNG or PDF (06, 15, 16)
take the output path as their first argument; their outputs are kept in
`images/`
([06](images/example-06-png-render.png),
[15](images/example-15-og-card.png),
[16](images/example-16-invoice-pdf.pdf)).
The SVG examples write to
the path given or to standard output. The `Features:`
line in each file's header lists the identifiers it uses, so
`grep -l 'Features:.*floating' examples/*.pl` finds the examples for a
feature.

| Script | Shows | Needs |
|---|---|---|
| `01-minimal.pl` | the smallest Clay::XS program; render commands as JSON | - |
| `02-sidebar-demo.pl` | Clay's README layout with Clay::XS; pointer queries | - |
| `03-svg-render.pl` | an SVG renderer | - |
| `04-ui-sidebar.pl` | `02` rebuilt with Clay::UI widgets | - |
| `05-ui-grid.pl` | `Clay::UI::Grid` tables, rendered to SVG | - |
| `06-png-render.pl` | a PNG renderer with real fonts | Imager, DejaVu Sans Mono |
| `07-ui-flow.pl` | flow layout (`CLAY_LEFT_TO_RIGHT_WRAP`) | - |
| `08-ui-stack.pl` | stack layout (`CLAY_BACK_TO_FRONT`) | - |
| `09-xs-floating-scroll.pl` | Clay::XS floating elements, scrolling, pointer queries | - |
| `10-xs-transitions.pl` | Clay::XS transitions and easing | - |
| `11-xs-images-custom.pl` | images, custom elements, aspect ratio, overlay colour, struct checks | - |
| `12-ui-interaction.pl` | events, bubbling, focus, disabled widgets, states, redraw on change | - |
| `13-ui-scroll-floating.pl` | Clay::UI scroll containers and tooltips | - |
| `14-ui-custom-widgets.pl` | writing widget classes, internal children, sizing groups, errors | - |
| `15-og-card.pl` | a 1200x630 social media preview card as PNG | Imager, DejaVu Sans |
| `16-invoice-pdf.pl` | a multi-page invoice PDF from a data template | PDF::Builder |
| `17-xs-contexts-debug.pl` | several contexts, capacity, culling, debug view, external scrolling, ids | - |
| `18-ui-tree-editing.pl` | click-to-focus, states, editing children and grids, resizing | - |

## Limitations

- Clay calls one set of transition handlers per context for every
  element; Clay::UI users install them with `Clay_SetTransitionHandlers`
  right after `Clay::UI->new` (see `Clay::Manual`, TRANSITIONS).
- A context belongs to the Perl interpreter (thread) that created it.
- Neither layer reads the keyboard or draws; both are left to your
  program.

## License

zlib/libpng, the same license as Clay. See `src/clay/LICENSE.md` for the
upstream notice.
