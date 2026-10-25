# Table Cell Wrapping Design

Date: 2026-10-21

## Motivation

mdee formats Markdown pipe tables with ansicolumn but never wraps cell
content. A table wider than the display width overflows and becomes
unreadable. This was a deliberate stance (see
`docs/option-programming.md`): the viewer offers up to a single column
of 180 characters, and writing within that is the author's
responsibility.

That contract assumes a human author. LLM-generated Markdown routinely
contains tables with long prose cells, and the reader has no control
over how it was written. Wrapping is therefore added as a **fallback
that only engages when a table does not fit**. Tables that fit are
rendered exactly as before, so the contract still holds for
well-formed input.

The target look is what a browser does with an over-wide table: short
columns keep their natural width, long columns are wrapped.

## Where It Lives

The feature is implemented in **ansicolumn** (`App::ansicolumn`,
`~/Git/tecolicom/ANSI-Tools/App-ansicolumn`), not in the md module.
Reasons:

- ansicolumn already owns table layout (`table_out`), ANSI-aware width
  measurement, and a `Text::ANSI::Fold` object factory (`foldobj` in
  `App::ansicolumn::Util`).
- It becomes usable on its own: `ansicolumn -t -w80`.
- Same pattern as `--table-right`, `--table-center`, `--table-remove`,
  which were added to ansicolumn for mdee.

mdee / `App::Greple::md` only gain a config parameter that passes the
width through.

Two repositories are touched. Release order: ansicolumn first, then
mdee bumps its `cpanfile` requirement.

## Goals

- `ansicolumn -t -w N` fits the table into N display columns by
  wrapping cells of over-wide columns.
- `ansicolumn -t --cell SPEC` sets fixed or capped widths per column,
  overriding the automatic allocation for those columns. This reuses
  the existing `--cell` (`-X`) option, which already carries per-item
  widths for parallel view mode.
- Columns whose content already fits are never wrapped.
- Output of a table that fits in N is byte-identical to output
  without `-w`.
- ANSI SGR colors and OSC 8 hyperlinks inside cells survive wrapping
  (verified: `Text::ANSI::Fold` 2.33 closes and reopens them across
  line breaks, and `ansi_width` ignores them).
- Word-boundary wrapping for Latin text, kinsoku (line-break
  prohibition) for Japanese, and forced character splits for tokens
  longer than the column (URLs, identifiers). All of this is provided
  by `Text::ANSI::Fold`; no custom tokenizing.
- Existing alignment (`--table-right`, `--table-center`), `--padding`,
  `--item-format`, `--table-remove`, `--table-squeeze` keep working on
  wrapped tables.
- mdee enables it by default whenever fold is enabled (styles `nup`,
  `pager`, `cat`), using the fold width.

## Non-Goals

- Row separator lines between wrapped rows. Not in this round. The
  idea for later: double rule under the header, single rule between
  rows.
- Pandoc simple/grid/multiline tables. Only pipe tables, as today.
- Changing how non-table ansicolumn modes use `-w`.
- A dedicated mdee command-line option. `--config table_width=N` is
  enough for now.

## Anti-Goals

- Any change to the rendering of a table that already fits (unless
  `--cell` explicitly fixes a width).
- A column that fits being wrapped because another column is huge.
- Output lines wider than the requested width (except the documented
  overflow case when even the floor width does not fit).

## Behavior Specification (ansicolumn)

### Activation

- Applies only in table mode (`-t`) and only when `--width` / `-w` /
  `-c` or `--cell` / `-X` is explicitly given. Both are currently
  ignored in table mode (confirmed: `table_out` never reads them), so
  this is backward compatible.
- `-w` accepts the existing RPN form, so `-w=` means terminal width and
  `-w=10-` means terminal width minus 10. This is resolved by the
  existing `+width` handler before `table_out` runs.
- When `--table-align` (`-A`) or `--table-tabs` (`-T`) is in effect,
  the width is ignored (no wrapping). Those modes round to column
  units and are out of scope.

### Width Budget

Let `n` be the number of columns after `--table-remove` and
`--table-squeeze`, `S` the display width of the output separator
(`-o`), and `F` the width of the `--item-format` overhead, measured as
`ansi_width(sprintf($fmt, ''))` (0 when no format is set).

```
budget  = N - S * (n - 1)
cost_i  = content_i + F        # content_i = max raw cell width in column i
```

If `sum(cost_i) <= budget` the table fits and nothing changes.

Note for the mdee case (trim mode): `--item-format=' %s '` gives
`F = 2`, `-o '│'` gives `S = 1`, so a 3-column table costs
`sum(content_i) + 6 + 2`.

### Water-Level Allocation

When the table does not fit, choose a level `L` and give every column
`min(content_i, L)` content columns:

- `L` is the largest integer with `sum(min(content_i, L) + F) <= budget`.
- Floor: `L >= 4`. If no `L >= 4` satisfies the budget, use `L = 4`
  and let the table overflow. (This is the only case where output may
  exceed N.)
- Columns with `content_i <= L` are untouched. Columns with
  `content_i > L` are wrapped at `L`.
- Any leftover (`budget - sum`) is small (less than the number of
  wrapped columns) and may be left unused. Builder may optionally hand
  one extra column each to wrapped columns from the left until it is
  gone; either is acceptable.

Rationale: proportional distribution lets one enormous cell squeeze
every other column down to its minimum. Water-level treats all
over-wide columns equally and never touches columns that fit. There is
no minimum-width computation per column: `Text::ANSI::Fold` already
force-splits tokens longer than the width, so unbreakable content
cannot inflate a column.

Worked example, N = 80, `-o '  '` (S = 2), no format (F = 0),
content widths 6, 12, 60, 300: budget = 74, L = 28, widths become
6, 12, 28, 28.

### Per-Column Widths with `--cell`

`--cell` in table mode takes a comma-separated list, one entry per
column, with the same grammar as parallel view mode:

- `N`: fixed content width N. Cells longer than N wrap; the column is
  padded to N even when all cells are shorter.
- `<N` (or `<=N`): upper bound. Width is `min(content_i, N)`; wraps
  only when content exceeds N.
- `+N` / `-N`: relative to the column's natural content width
  `content_i`.
- `0`: automatic (no constraint). This value does not exist in
  parallel view mode; it is added so a single column can be
  constrained, as in `--cell 0,0,20`.
- Fewer entries than columns: the last entry is repeated, as in
  parallel view. So `--cell '<20'` caps every column at 20.
- Empty entries (`10,,30`) are not supported, matching the existing
  `split /,+/` behavior; use `0`.

Widths are content widths: item format overhead `F` and separators
are added on top, exactly as in the `-w` budget. The floor of 4 does
not apply to `--cell`; a user asking for width 2 gets width 2.

Combination with `-w`:

1. Resolve `--cell` entries to fixed widths `w_i` for the constrained
   columns (`<N`, `+N`, `-N` resolve against `content_i`).
2. Subtract `w_i + F` for each constrained column and `S` per
   separator from `N` to get the remaining budget.
3. Run the water-level allocation over the unconstrained columns only.

Without `-w`, unconstrained columns keep their natural width and only
constrained columns may wrap.

Parallel view mode is unaffected: the option is simply read in
`table_out` as well, and the `0` value is rejected there as today.

### Wrapping and Item Format

Order of operations in `table_out` changes slightly:

1. Split, remove, squeeze columns (as now).
2. Measure raw cell widths (**before** item format), compute `content_i`.
3. Decide a target width per column: `w_i` from `--cell`, or `L` from
   the water level, or the natural width (no wrapping).
4. Wrap raw cells of columns whose content exceeds the target with
   `Text::ANSI::Fold`.
5. Apply `--item-format` to **each physical line** of each cell.
6. Expand each logical row into `max(lines per cell)` physical rows,
   filling missing cell lines with `''` (which then goes through item
   format like any cell, so a blank continuation cell becomes `'  '`
   under `' %s '`).
7. Measure widths, build formats, print (existing code, unchanged).

Applying item format after wrapping keeps continuation lines aligned
with the first line. When nothing wraps, steps 4 and 6 are no-ops and
step 5 is identical to today, so output is unchanged.

Fold configuration for cells (builder constructs a
`Text::ANSI::Fold` per column; `foldobj` in Util.pm is the reference,
but its `padding => 1` must **not** be used here because padded lines
would defeat centering and width measurement):

- `width => target`
- `margin => $obj->runin_margin` (same as `foldobj`; see below)
- `boundary => ($obj->boundary || 'word')`
- `linebreak => ($obj->linebreak ? $obj->lb_flag : LINEBREAK_ALL)`
- `runin`, `runout`, `ambiguous`, `padchar` from the object as
  `foldobj` does
- `padding => 0`

Run-in margin (designer's decision after measuring Text::ANSI::Fold
2.33): with run-in enabled and no margin, a closing punctuation mark
run in at the end of a line pushes that line past the fold width. The
`margin` option reserves that room on every line, so Latin text in a
wrapped column occupies at most `target - runin` columns while
Japanese lines may use the full `target` when punctuation is run in.
This is exactly what ansicolumn's own pane folding does (`foldobj`),
and it is preferred over disabling run-in, which would put `。` or `、`
at the start of a line. Consequence for the worked example: the two
wrapped columns are 28 wide but Latin prose in them wraps at 26. The
water-level arithmetic is unchanged; the margin is inside the target
width, not added to it.

Requirement regardless of configuration: every physical line of a
wrapped cell must satisfy `ansi_width(line) <= target width`. Include
a test with Japanese punctuation at the break point.

Builder notes gathered during review:

- `-w=` (RPN, terminal width) stores `''` in `$obj->width`; test
  activation with `defined $obj->width` and read the value through
  `get_width`.
- Word-boundary folding keeps the trailing space on a line
  (`"aaaa bbbb "`); strip trailing whitespace from wrapped lines so
  `--table-right` and `--table-center` continuation lines align.
- A continuation line whose cells are all empty must not be mistaken
  for a separator row by the md module's `fix_separator` (it requires
  at least one `-`, so it should be safe; add a test).
- `-Mmd::config(...)` lets a later duplicate key win (verified:
  `-w 40 --config foldwidth=20` folds at 20), so
  `--config table_width=N` overrides the mdee-supplied value without
  bash changes.

Edge cases:

- An empty cell folds to zero lines; treat as one empty line so a row
  of empty cells still produces one output line.
- A row whose cells all fit produces exactly one physical row.
- A cell containing only a wide character wider than `L` cannot happen
  with floor 4, but the builder should confirm `Text::ANSI::Fold` does
  not loop on `width => 1` with wide characters (checked: it emits one
  character per line; no loop).
- SGR state (e.g. bold) spanning a break is closed at line end and
  reopened on the next line by `Text::ANSI::Fold`; include a test.

### Documentation (ansicolumn)

- POD: under `-t`, describe that `-w` sets the table width and wraps
  over-wide columns; describe the water-level rule in one paragraph
  and the floor of 4; note `-A`/`-T` ignore it. Under `--cell`,
  remove "only valid in parallel view mode" and describe the table
  mode grammar including `0` and the combination with `-w`.
- `--help` summary: add a line such as
  `-t -w#  fit table into width, wrapping long cells` and extend the
  `--cell` line.
- Changes entry; version bump (next release, 1.58 or whatever the
  maintainer chooses).

### Tests (ansicolumn, `t/01_run.t` style with data sections)

1. `-t -w80` on a table that fits: identical to `-t`.
2. One long column wrapped; others untouched; every line `<= 80`.
3. Two over-wide columns get equal width.
4. `--item-format=' %s '` with wrapping: continuation lines aligned.
5. `--table-right` on a wrapped column: each physical line
   right-aligned.
6. Japanese text with punctuation at the break.
7. Colored cell (SGR) spanning the break: color closed and reopened,
   `ansi_width` of each line `<= L`.
8. Empty cells and a row with all-empty cells.
9. `-w` with `-A`: ignored.
10. Floor case: width too small for all columns; output is produced,
    no crash.
11. `--cell 0,0,20` without `-w`: only column 3 wraps at 20.
12. `--cell '<20'` caps all columns; a column with content 8 stays 8.
13. `--cell 20` fixed: a column with content 8 is padded to 20.
14. `--cell 0,10 -w 60`: column 2 fixed at 10, the rest allocated by
    water level within the remaining budget.
15. Parallel view (`-V --cell 80,40`) output unchanged.

## Behavior Specification (mdee / App::Greple::md)

### md module

- New config parameters `table_width` (default `0` = no wrapping) and
  `table_cell` (default empty), declared in `Config->new()` alongside
  `table`, `table_trim`, `rule`.
- `format_table()` passes `-w $config->{table_width}` to
  `call_ansicolumn` when `table_width > 0`, and
  `--cell $config->{table_cell}` when `table_cell` is non-empty.
  Because `,` separates parameters inside `-Mmd::config(...)`,
  `table_cell` entries are separated by `:` (`table_cell=0:10:<20`)
  and converted to commas before being handed to ansicolumn.
  Column numbers in `table_cell` refer to Markdown columns; in trim
  mode the leading/trailing border columns are removed by
  `--table-remove=1,-0` before `--cell` applies, and in non-trim mode
  the builder must shift the list by one (prepend `0`) so the user
  never sees the phantom first column, mirroring the `$_++` offset
  applied to alignment columns. Nothing else changes;
  `fix_separator` keeps working because separator rows are
  single-line (their cells were minimized to `-` by `parse_separator`
  and never exceed `L`).
- Alignment columns from `parse_separator` are unaffected.
- **Fix the `{TABLE}` fold-exclude pattern** (maintainer's decision,
  bug fix). The current `^ {0,3}([│|├].+[│|┤]\n){3,}` only matches
  non-trim output; in trim mode (mdee default) `--table-remove=1,-0`
  strips the border columns, rows start with a space and have no `├`,
  so formatted tables are not excluded from ansifold and a row whose
  first cell looks like a list item (`- alpha`) gets re-folded. The
  new pattern must match a formatted table block in all four
  combinations of trim/non-trim and rule/non-rule, including wrapped
  continuation lines (which still contain the column separator) and
  the separator row (`─┼─` or `-|-`). Add a regression test with a
  list-like first cell in trim mode. Rendering of fitting tables with
  such cells changes as a result; this is intended.
- POD: document `table_width` and `table_cell` with the other config
  parameters.

### mdee script

- When fold is enabled, add `table_width=$width` to `config_params`,
  next to the existing `foldlist=1,foldwidth=$width` line. The fold
  width (`--width`, default pane width minus 5) is the table width, so
  wrapped tables are at most as wide as folded prose.
- `--config table_width=N` overrides (or `table_width=0` disables).
  `--config table_cell='0:<30'` passes per-column widths (colon
  separated); no dedicated mdee option in this round.
  Builder confirms that a later duplicate key in the md config list
  wins; if it does not, append the mdee-provided value before
  `md_config` (it already is) and verify.
- Styles `filter` and `raw` do not enable fold, so they do not wrap
  tables; no width is known there. Unchanged behavior.
- POD: mention table wrapping under `--table` and `--width`; document
  `table_width` in the config parameter list.
- `cpanfile`: `requires 'App::ansicolumn', '<released version>'`.
- CLAUDE.md: update the table formatting section (call_ansicolumn
  options, `table_width`).

### Tests (mdee)

- New `t/05_table_wrap.t` (or extend `t/04_table_align.t`) via
  `t/Util.pm`: run the md module with `table_width=40` on a table with
  one long column; assert wrapped output, rule characters intact,
  every line `<= 40` after stripping ANSI, and that the same table
  with a generous `table_width` equals the current output.
- `t/01_mdee.t`: one integration case with `-s cat -w 40` on a wide
  table, and one with `--config table_cell=0:10`.

## Constraints

- Perl v5.16 (ansicolumn) / existing mdee requirements.
- No new CPAN dependencies. `Text::ANSI::Fold` >= 2.3303 is already
  required by ansicolumn.
- ansicolumn is called in-process from the md module via
  `Command::Run` (`nofork => 1, raw => 1`); the implementation must not
  rely on process-global state that leaks between calls (e.g. do not
  `Text::ANSI::Fold->configure` globally for the table; construct an
  object).
- Commits and pushes in either repository require the maintainer's
  explicit go-ahead (project policy). Run `minil build` before
  committing in App-mdee.

## Decisions Made Here (the maintainer's)

- Implement in ansicolumn, exposed as `-t` + `-w`.
- Also allow overriding the automatic allocation with fixed per-column
  widths, via the existing `--cell` option.
- Browser-like result: only over-wide columns wrap.
- No row separators in this round.
- Wrapping engages only when the table does not fit; fitting tables
  are untouched.
- Fix the md module's `{TABLE}` fold-exclude pattern in this round.

## Decisions Made by the Designer (flag if you disagree)

- Water-level allocation instead of CSS proportional distribution.
- Floor width 4; overflow rather than crash below it.
- Word boundary and full kinsoku on by default for table cells, even
  though plain ansicolumn defaults to neither; `--boundary` and
  `--linebreak` still override.
- Item format applied per physical line after wrapping.
- `-A` / `-T` modes ignore the width.
- mdee enables wrapping by default in fold-enabled styles, using the
  fold width; no new mdee option.
- Design document lives in `docs/plans/` of App-mdee (repository
  precedent), even though most code lands in App-ansicolumn.

## Left to the Builder

- Exact search for `L` (binary search or descending scan; both fine).
- Whether to distribute the leftover columns.
- Whether the fold object is built once per table or once per column
  (per column is natural once widths differ).
- Test data wording and section names.
- The ansicolumn version number and Changes wording.

## Future Work

- Row separators for wrapped tables (double under header, single
  between rows), probably as an ansicolumn option.
- A dedicated mdee option for per-column widths if
  `--config table_cell=...` proves clumsy.
- An mdee `--table-width` option if `--config table_width=N` proves
  clumsy.
