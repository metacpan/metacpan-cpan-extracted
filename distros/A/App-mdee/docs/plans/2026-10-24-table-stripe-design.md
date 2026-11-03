# Table Row Striping and Header Rule Design

Date: 2026-10-24

Builds on `docs/plans/2026-10-21-table-wrap-design.md` (cell wrapping,
implemented in App::ansicolumn master and App-mdee main, not yet
released).

## Motivation

Cell wrapping turns one Markdown table row into several physical
lines. Without any visual grouping, the reader cannot tell where one
row ends and the next begins, and a table with several wrapped rows
reads as an undifferentiated block of text. The same lack of grouping
also makes the table area hard to distinguish from surrounding prose.

The chosen remedy is what browsers (GitHub included) do: alternate the
background of body rows ("zebra striping"), with the header row set
apart typographically. Both stripe shades differ from the page
background, so the striped body also outlines the table area.

Ruled out during design:

- Separator lines between rows: cost vertical space and clutter.
- Blank lines between wrapped rows: cheap, but expands the table and
  does not outline the area. Kept as a possible fallback for terminals
  without background colour support (not in scope).
- Full frame (top, bottom and side borders) drawn by ansicolumn: this
  is the territory of a dedicated table formatter, which the
  maintainer explicitly does not want ansicolumn to become. Deferred to
  Future Work.

## The Look (maintainer's choice, "variant F" in the mockup)

```
 key  │ description                           │ count     <- header: bold, no background
──────┼───────────────────────────────────────┼───────    <- rule line: unchanged
 k1   │ the quick brown fox jumps over the    │    12     <- body row 1: shade A
      │ lazy dog and keeps on running through │
      │ the field                             │
 日本 │ これは長い説明文で、幅に収まらないの  │     3     <- body row 2: shade B
      │ で折り返されるはずの文章です。        │
 k2   │ short                                 │  1024     <- body row 3: shade A
```

- Body rows alternate between two background shades. Every physical
  line of a wrapped row carries the colour of its logical row.
- The header row is bold with no background. If the header wraps,
  every physical line of it is bold.
- The rule line under the header is drawn as today, uncoloured.
- The background extends to the table's width only, not to the
  terminal edge. The right edge is straight because the last column is
  padded.
- Striping is **on by default** in mdee.

## Where It Lives

Two small additions to **ansicolumn** table mode, and plumbing in
**App::Greple::md**. The split follows one fact: only ansicolumn knows
which physical lines belong to which logical row after wrapping, so
row colouring must happen there. Everything Markdown-specific stays in
the md module.

The second addition, drawing the header rule inside ansicolumn,
replaces an existing hack. Today the md module feeds the Markdown
separator row (`|---|---:|`) through ansicolumn as an ordinary data
row and afterwards rewrites the resulting `-  │ -` line into
`───┼───` (`fix_separator`). With row colouring, that extra row would
either break stripe parity or require lying to ansicolumn about the
header height. Letting ansicolumn underline its header removes the
rewrite step, the parity problem and `fix_separator` itself.

## Goals

- Body rows of a formatted table alternate between two configurable
  colours; the header row gets a third configurable colour (bold by
  default). Colours apply per logical row, so wrapped rows stay one
  colour.
- The table's rule line is produced by ansicolumn from its own column
  widths, with characters chosen by the caller.
- Default mdee output for a table that fits, with SGR sequences
  stripped, is byte-identical to today's output in all four
  combinations of `table_trim` × `rule` (see the documented
  exceptions under Constraints).
- All colours are theme-able through the existing md colour-label
  mechanism and can be turned off.

## Non-Goals

- Top, bottom or side borders. (Future Work.)
- Any change to how cell content is coloured, wrapped or aligned.
- Row separators or blank lines between rows.
- Striping in ansicolumn's non-table (column/parallel) modes.
- A new ansicolumn or mdee command-line switch beyond those listed
  below.

## Anti-Goals

- ansicolumn growing a table-border or table-style subsystem.
- The md module parsing ansicolumn's output to find the header (it
  must not depend on SGR sequences or line shapes to locate rows).
- Stripes that bleed to the terminal edge (`\e[K`-style fill), or
  that depend on the pager/nup handling erase-line sequences.

## Behavior Specification (ansicolumn)

All of this applies to table mode (`-t`) only. Nothing changes when
none of the new options or labels is used.

### New colormap labels

Added to `%DEFAULT_COLORMAP`, all default `''` (no colour):

| Label        | Applied to                                        |
|--------------|---------------------------------------------------|
| `TABLE_HEAD` | every physical line of the first N logical rows   |
| `TABLE_ODD`  | 1st, 3rd, 5th… logical body row (after the head)  |
| `TABLE_EVEN` | 2nd, 4th, 6th… logical body row                   |

Set with the existing `--cm LABEL=SPEC` option (one `--cm` per label is
the recommended form, because a `sub{...}` spec consumes the rest of a
comma-separated list).

The colour wraps the **whole formatted physical line**: cell text,
item-format padding, alignment padding and output separators, but not
the trailing newline. Lines are coloured after they are fully formatted
(after `ansi_printf` formatting, before printing), so width
computation is unaffected. An empty label leaves the line untouched.

### `--table-head=N`

Integer, default 0. The first N logical rows are the head. Rows
N+1, N+2, … are body rows and take `TABLE_ODD`, `TABLE_EVEN`,
`TABLE_ODD`, … in order. With N=0 all rows are body rows.

A "logical row" is one input line. Input lines that produce no output
(blank lines, which `split` turns into an empty list) do not count.
Physical lines created by wrapping (`-w` / `--cell`) belong to the
logical row they came from.

### `--table-rule=CHARS`

String of 1 to 4 characters, default empty (no rule). When set and
`--table-head` is at least 1, a rule line is emitted immediately after
the last physical line of the head, before the first body row. It is
emitted even when there are no body rows. It is not coloured by any
`TABLE_*` label.

The rule is built from the same column widths and output separator as
the data rows:

- `CHARS[0]`, the **horizontal** character, fills each column to its
  width. Multi-column-width characters are not supported; the builder
  may die or fall back to ASCII `-` on a wide character.
- `CHARS[1]`, the **cross** character (defaults to `CHARS[0]`),
  replaces each non-space character of the output separator; spaces in
  the separator become the horizontal character. So `-o '│'` gives
  `┼`, `-o ' | '` gives `─┼─`, and the default two-space separator
  gives `──`.
- `CHARS[2]` / `CHARS[3]`, the **left** and **right edge** characters
  (default to the cross character), are used instead of the cross for
  the separator that follows a **blank first column** and the one that
  precedes a **blank last column** respectively. A column is blank when
  every cell in it is empty or whitespace-only (before item format).
  This is how the phantom border columns of mdee's non-trim mode become
  `├` and `┤`, including when the Markdown table is indented by one to
  three spaces and the phantom column is therefore 1–3 wide rather
  than 0.

Examples, with columns of width 5 and 3:

```
--table-rule='─┼'           -o '│'    ─────┼───
--table-rule='-|'           -o '|'    -----|---
--table-rule='─┼├┤'         -o '│'    ├─────┼───┤   (phantom first and last columns)
--table-rule='-|||'         -o '|'    |-----|---|   (phantom first and last columns)
--table-rule='─┼├┤'         -o '│'    ──├─────┼───┤ (first column blank, 2 wide)
```

### Padding

When any `TABLE_*` label is non-empty, the last column is padded to its
full width as if `--padding` were given, so coloured rows have a
straight right edge. The rule line is always full width. Without
colours, padding behaviour is unchanged.

### Interaction with other options

- `-T` (`--table-tabs`): colours and rule are ignored; output is
  unchanged.
- `-A` (`--table-align`): colours and rule apply to the space-separated
  output as usual.
- `--table-right` / `--table-center`: unaffected; the rule does not
  care about alignment.
- `-w` / `--cell` wrapping: the head may wrap; the rule follows its
  last physical line. Stripe parity counts logical rows.
- `--table-remove` / `--table-squeeze`: applied before anything here,
  as today.

### Documentation (ansicolumn)

`script/ansicolumn` POD: the three labels under `--colormap`;
`--table-head` and `--table-rule` under the table options, with the
examples above. Help text (`--help`) lines for the two options.

### Tests (ansicolumn)

Add to `t/03_table_wrap.t` or a new `t/04_table_head.t` in the same
style (`ac.pm` CLI runs, assertions on decoded output):

- `--table-head=1 --cm TABLE_HEAD=D`: first line bold, others plain.
- `--table-head=1 --cm TABLE_ODD=/L24 --cm TABLE_EVEN=/L22` on four
  rows: rows 2–4 start with the odd, even, odd SGR; the colour closes
  at end of line (`\e[m` followed by the newline, allowing Concise's
  trailing `\e[K`).
- Wrapped row (`-w` small enough): all its physical lines carry the
  same colour; the next logical row switches.
- Wrapped head: all head lines carry `TABLE_HEAD`; rule follows the
  last of them.
- `--table-rule` with 2 and 4 characters, with and without phantom
  edge columns, matching the examples above character for character,
  including a blank-but-not-empty first column (indented input).
- A body cell containing its own SGR (`\e[1mx\e[m`) and one containing
  an OSC 8 hyperlink: the physical line stays on its stripe colour
  after the inner reset (Concise re-opens the outer colour after each
  reset, the mechanism mdee's cumulative colouring already relies on).
- Blank input line does not shift parity.
- No labels, no options: output identical to the pre-change baseline
  (reuse `t/data/parallel-baseline.txt` style or compare to a run
  without the new options).
- `-T` with labels: output identical to `-T` without them.
- Colours force last-column padding: widths of all body lines equal.

## Behavior Specification (mdee / App::Greple::md)

### Colour labels

Three labels added to `@color_labels`, `%default_colors` and
`%dark_overrides`:

| Label        | light   | dark    |
|--------------|---------|---------|
| `table_head` | `D`     | `D`     |
| `table_odd`  | `/L24`  | `/L04`  |
| `table_even` | `/L22`  | `/L02`  |

The shades are provisional (taken from the mockup) and will be tuned
on real terminals after implementation. They follow the `${base}`
expansion and `--cm` / `--config` override rules of every other label,
so themes can change them with `md_config+=(table_odd=...)` or
`pass_md+=(--cm table_odd=...)`.

### `table_color` config parameter

New config parameter `table_color` (default 1). When 0, no `TABLE_*`
colours are passed to ansicolumn. Table colours are also suppressed
when `colorize` is 0, so an uncoloured run stays uncoloured. This is
the documented one-switch way to turn striping off:
`mdee --config table_color=0`. Individual labels can also be blanked
the usual way (`--config table_odd=` or `--cm table_odd=`; an empty
value clears a label, verified with `horizontal_rule=` on the current
code).

Only plain string specs are forwarded to ansicolumn. A function spec
(`sub{...}` or `&func`) set on one of the three table labels is not
supported and is treated as empty; `setup_colors` must therefore keep
the spec text for these labels (it is lost once `load_params` compiles
a function).

### `format_table` changes

For each table block:

1. `parse_separator` finds the **first** separator row in the block,
   exactly as today (GFM puts it on line 2, but the current code
   accepts it anywhere and this keeps that). It returns the alignment
   lists as today and **removes the separator line from the block**
   instead of minimising its dashes, and additionally reports its
   position K (1-based line number within the block). When not found,
   the block has no header: no `--table-head`, no rule, every row is a
   body row.
2. ansicolumn is called with the existing options plus, when a
   separator was found at K ≥ 2, `--table-head=K-1` and
   `--table-rule=CHARS` (so a separator on line 2 gives a one-row head,
   and the rule stays where it is today for the malformed case of a
   separator further down; a separator on line 1, K=1, yields no head
   and no rule, a documented difference from today's top rule):

   | `rule` | CHARS   |
   |--------|---------|
   | 1      | `─┼├┤`  |
   | 0      | dash, then three ASCII vertical bars (no escape form fits in a Markdown cell) |

   and, when colours are enabled (`colorize` and `table_color`), one
   `--cm` per label: `TABLE_HEAD=<spec>`, `TABLE_ODD=<spec>`,
   `TABLE_EVEN=<spec>`, where `<spec>` is the fully expanded colour
   string of the md label (the same string `setup_colors` stores in the
   colormap hash, after `${base}` substitution and overrides). A label
   whose spec is empty is not passed.
3. `fix_separator` is deleted. The output of ansicolumn is the output
   of `format_table`.

Trim mode keeps `--table-remove=1,-0`, `--item-format= %s ` and
`--padding`; non-trim mode keeps `-s '|'` and its phantom first and
last columns (which the edge characters of `--table-rule` turn into
`├` / `┤` or `|`). The `$_++` offset for alignment columns in non-trim
mode is unchanged.

### Fold exclusion

Formatted table lines now begin with an SGR sequence when coloured. The
`{TABLE}` pattern in `__DATA__` must allow an optional run of SGR
sequences (`(?:\e\[[\d;]*m)*`) at the start of each line before the
existing first-character class, in both the lookahead and the body.
Lines end with `\e[m` (and Concise's `\e[K`) before the newline, which
the existing `[^\n]*\n` already accepts. The three-line minimum, the
separator-row requirement and everything else stay as they are.

### mdee script

No new option. `script/mdee` POD: document `table_color` in the config
parameter list and the three labels in the colour-label table, with a
sentence that striping is on by default and `--config table_color=0`
turns it off.

### Documentation

- `CLAUDE.md`: replace the `fix_separator` description with the
  `--table-head` / `--table-rule` call, describe the three labels and
  `table_color`, and note the SGR-prefix allowance in `{TABLE}`.
- Memory note under Table Formatting.

### Tests (mdee)

- `t/04_table_align.t`: the `parse_separator` unit tests change from
  "colons stripped" to "separator line removed, alignment lists
  returned"; add a case where the dash row is not line 2 and is left
  alone.
- Regression guard, the key test of this change: for `t/test.md` (and
  `t/table_wrap.md` at a fitting width), run with
  `colorize=0` and compare each of the four `table_trim` × `rule`
  combinations to the output of the committed pre-change md module
  captured once into `t/data/` fixtures. They must be byte-identical
  (allowing the documented empty-column exception, which `t/test.md`
  must not contain).
- Colour tests with `colorize=1,table_color=1`: header line starts with
  `\e[1m`; body lines alternate between the two shade SGRs; wrapped
  rows (`table_width=40`) keep one colour across their physical lines;
  the rule line carries no SGR.
- `table_color=0` and `colorize=0` each produce output free of
  `TABLE_*` SGRs.
- Fold test (existing in `t/05_table_wrap.t`): still passes with
  colours on, proving the `{TABLE}` pattern accepts the SGR prefix.
  Add a run with `colorize=1` beside the existing `colorize=0` one.
- `t/01_mdee.t`: a `mdee -s cat` run shows the shade SGRs; a run with
  `--config table_color=0` does not.

## Constraints

- Perl ≥ 5.14 (both distributions), `use utf8` sources.
- App::ansicolumn: no new dependencies. The colour comes from the
  existing Getopt::EX::Colormap instance (`$obj->color(LABEL, $text)`).
- App::mdee `cpanfile` already requires `App::ansicolumn 1.58`; this
  feature ships in the same 1.58 release as cell wrapping.
- **Documented output difference**: today the minimised dash row still
  takes part in width computation. In trim mode it contributes `-`
  (width 1, 3 with item format), so a column whose every cell is empty
  shrinks from 3 to 2. In non-trim mode the minimised cell keeps the
  source spacing (`| --- |` becomes ` - `, width 3; `|---|` becomes `-`,
  width 1), so any column whose widest data cell is narrower than that
  changes width (e.g. data `|1|` under `| --- |`). Both are accepted;
  the old widths were artefacts of feeding the separator through
  ansicolumn. The regression fixtures must include such a table so the
  real delta is seen, not assumed, and the byte-identical comparison
  excludes it.
- A separator row on line 1 of a block (no header row at all) produces
  no rule where today it produces a rule at the top. Accepted.
- Term::ANSIColor::Concise appends `\e[K` after the closing reset of
  every coloured segment unless `$NO_RESET_EL` is set. Since the reset
  precedes it, the erase uses the default background and does not
  extend the stripe; nup's inner ansicolumn discards EL sequences. No
  action needed, but tests must tolerate the trailing `\e[K`.
- No pushes, no releases, no formula updates without the maintainer's
  explicit go-ahead; commits follow the project's attribution rule (no
  `Claude-Session:` line).

## Decisions Made Here (the maintainer's)

- Zebra striping of body rows, background up to the table width.
- Header bold, no background; rule line unchanged, uncoloured
  ("variant F"; variants with coloured header, coloured rule line, or
  rule line inside the header block were shown and rejected).
- Striping on by default in mdee.
- ansicolumn additions limited to row colouring and the header rule;
  no frame. A dedicated table module is the path if a frame is ever
  wanted.
- Header rule drawn by ansicolumn so `fix_separator` can go.

## Decisions Made by the Designer (flag if you disagree)

- Label names `TABLE_HEAD` / `TABLE_ODD` / `TABLE_EVEN` (ansicolumn) and
  `table_head` / `table_odd` / `table_even` (md), option names
  `--table-head` and `--table-rule`.
- `--table-rule` grammar: 1–4 characters, horizontal / cross / left
  edge / right edge, edges triggered by zero-width first/last columns.
- Non-empty `TABLE_*` labels imply last-column padding.
- Rule emitted even with no body rows; not emitted when
  `--table-head` is 0.
- `-T` ignores the feature entirely.
- The first separator row anywhere in the block counts (today's rule);
  rows above it form the head (`--table-head=K-1`).
- Edge characters trigger on a *blank* first/last column (all cells
  empty or whitespace), not only a zero-width one, so indented non-trim
  tables keep `├`/`┤`.
- Function colour specs on the three table labels are not forwarded
  (treated as empty).
- Table colours gated by both `colorize` and the new `table_color`
  config; no new mdee command-line flag.
- One `--cm` per label when calling ansicolumn.
- Provisional shades: light `/L24` `/L22`, dark `/L04` `/L02`.
- The empty-column width change is accepted rather than emulated.

## Left to the Builder

- How `expand_table_rows` reports the logical-row index of each
  physical line (second return value, parallel array, or a field on
  each row) and where the colour is applied in `table_out`.
- Whether the pre-change regression fixtures are generated by a helper
  script or checked in by hand.
- Exact placement of the SGR-prefix group in the `{TABLE}` pattern.
- Test file organisation in both distributions.

## Future Work

- Full table frame (top/bottom/sides): belongs in a dedicated table
  module (`Text::ANSI::Table` or similar) that both ansicolumn `-t` and
  the md module would use. Not started.
- Blank-line fallback between wrapped rows for terminals without
  background colour.
- Tuning the default shades after seeing them on real light and dark
  terminals.
