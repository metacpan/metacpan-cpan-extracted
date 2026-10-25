# Table Cell Wrapping Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `ansicolumn -t -w N` (and `--cell`) wrap over-wide table cells, then let mdee pass its fold width through so wide Markdown tables fit the display.

**Architecture:** Part A adds width allocation (water level), per-column `--cell` resolution, and cell folding to ansicolumn's `table_out`, as pure functions in a new `App::ansicolumn::Table` file plus a small change to the `table_out` pipeline. Part B teaches `App::Greple::md` two config parameters (`table_width`, `table_cell`) that become `-w` / `--cell` arguments to ansicolumn, fixes the `{TABLE}` fold-exclude pattern, and has `script/mdee` pass the fold width. Part B depends on the Part A ansicolumn being installed locally.

**Tech Stack:** Perl (v5.16 floor), Text::ANSI::Fold, Getopt::EX::Hashed (ansicolumn options), Getopt::EX::Config (md module), Test::More with Data::Section::Simple (ansicolumn) and `t/Util.pm` greple runner (mdee).

**Spec:** `docs/plans/2026-10-21-table-wrap-design.md`

## Global Constraints

- Two repositories: `~/Git/tecolicom/ANSI-Tools/App-ansicolumn` (Part A) and `~/Git/tecolicom/App-mdee` (Part B). Release ansicolumn before releasing mdee.
- Perl `v5.16`; no new CPAN dependencies. `Text::ANSI::Fold >= 2.3303` is already required by ansicolumn.
- Output of a table that fits in `-w N` must be byte-identical to output without `-w`.
- Every physical line of a wrapped cell: `ansi_width(line) <= target width`.
- Water-level floor is `4`. `--cell` widths have no floor.
- Table-mode wrapping is ignored when `--table-align` (`-A`) or `--table-tabs` (`-T`) is set.
- No process-global `Text::ANSI::Fold->configure` for table folding; build an object (ansicolumn runs in-process from the md module via `Command::Run`).
- Commits and pushes require the maintainer's explicit go-ahead (project policy); the executor asks at the commit step. In App-mdee run `minil build` before committing. Do not edit `Changes`; that happens at release.
- Commit messages end with `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>`, no `Claude-Session:` line.

## Review Focus

1. Ragged rows (a row with fewer cells than the header): expansion and wrapping must keep the row ragged and not warn; pinned in Task 3 (A3) test `ragged`.
2. `-w` smaller than the separators alone (budget <= 0): every free column gets the floor, output is produced, no infinite loop; pinned in Task 1 (A1) unit test `budget-negative` and Task 3 (A3) `floor`.
3. `--table-columns-limit` (`-l`) with wrapping: the overflow cell that still contains separators is one cell and wraps like any other; pinned in Task 3 (A3) test `limit`.
4. `--cell` with more entries than columns or an invalid token: extra entries ignored, invalid token dies with `Invalid number: SPEC`; pinned in Task 2 (A2) unit tests.
5. `--padding` with wrapping: continuation lines of the last column are padded to the column width like first lines; pinned in Task 3 (A3) test `padding-wrap`.

---

## Part A: ansicolumn

Working directory for all Part A tasks: `~/Git/tecolicom/ANSI-Tools/App-ansicolumn`. Run tests with `prove -l t/`.

### Task 1 (A1): Water-level allocation (`table_widths`)

**Files:**
- Create: `lib/App/ansicolumn/Table.pm` (`package App::ansicolumn;`, same style as `lib/App/ansicolumn/Util.pm`)
- Modify: `lib/App/ansicolumn.pm:20` add `use App::ansicolumn::Table;` after `use App::ansicolumn::Util;`
- Test: `t/03_table_wrap.t` (new; unit tests at the top, CLI tests added in A3)

**Interfaces:**
- Produces: `App::ansicolumn::table_widths(\@content, $budget, $overhead, \@fixed_or_undef, $floor) -> \@target`
  - `@content`: natural (raw, pre-item-format) max width per column.
  - `$budget`: `N - S*(n-1)` or `undef` when `-w` not given.
  - `$overhead`: item-format width `F`.
  - `@fixed`: per column, integer for a `--cell`-constrained column, `undef` for free; whole arg may be `undef`.
  - Returns per-column target content widths. Free columns that fit return their natural width.

- [ ] **Step 1: Write the failing unit tests**

```perl
use Test::More 0.98;
use App::ansicolumn;
sub tw { App::ansicolumn::table_widths(@_) }

is_deeply(tw([6,12,60,300], 74, 0, undef, 4), [6,12,28,28], 'worked example');
is_deeply(tw([6,12,60,300], 74, 2, undef, 4), [6,12,24,24], 'with item-format overhead');
is_deeply(tw([5,5], 20, 0, undef, 4),         [5,5],        'fits: unchanged');
is_deeply(tw([5,5], undef, 0, undef, 4),      [5,5],        'no budget: unchanged');
is_deeply(tw([50,50,50], 10, 0, undef, 4),    [4,4,4],      'floor');
is_deeply(tw([50,50], -3, 0, undef, 4),       [4,4],        'budget-negative');
is_deeply(tw([10,30,30], 40, 0, [undef,8,undef], 4), [10,8,22], 'fixed column removed from budget');
is_deeply(tw([3,3], undef, 0, [20,undef], 4), [20,3],       'fixed without budget');
```

- [ ] **Step 2: Run to verify failure**

Run: `prove -l t/03_table_wrap.t`
Expected: FAIL, `Undefined subroutine &App::ansicolumn::table_widths`

- [ ] **Step 3: Implement `table_widths` in `lib/App/ansicolumn/Table.pm`**

Algorithm (the spec's water level): fixed columns take `fixed+overhead` out of the budget first. If the free columns' `sum(content+overhead)` fits the remainder, return natural widths. Otherwise find the largest integer `L >= floor` with `sum(min(content_i, L) + overhead) <= remainder` over free columns (descending scan from `max content` or binary search, builder's choice); if none, `L = floor`. Free targets are `min(content_i, L)`. Leftover columns may stay unused.

- [ ] **Step 4: Run to verify pass**

Run: `prove -l t/03_table_wrap.t`
Expected: PASS (8 tests)

- [ ] **Step 5: Commit** (ask the maintainer first)

```bash
git add lib/App/ansicolumn/Table.pm lib/App/ansicolumn.pm t/03_table_wrap.t
git commit -m "Add table_widths water-level allocation for table mode"
```

### Task 2 (A2): `--cell` spec resolution (`parse_cell_spec`)

**Files:**
- Modify: `lib/App/ansicolumn/Table.pm`
- Test: `t/03_table_wrap.t`

**Interfaces:**
- Produces: `App::ansicolumn::parse_cell_spec($spec, \@content) -> \@fixed` (same length as `@content`; `undef` = auto). Dies with `"Invalid number: $spec\n"` on a bad token (same message as the parallel-view code at `lib/App/ansicolumn.pm:338`).
- Grammar per entry (split on `/,+/`, last entry repeated): `0` → `undef`; `\d+` → that width; `[-+]\d+` → `content_i + n` (minimum 1); `(<=|[<=])(\d*)` → `$2 ? min(content_i, $2) : content_i`; anything else dies.

- [ ] **Step 1: Write the failing unit tests**

```perl
sub pc { App::ansicolumn::parse_cell_spec(@_) }
is_deeply(pc('0,0,20', [5,5,50]),  [undef,undef,20], 'single constrained column');
is_deeply(pc('<20',    [8,50]),    [8,20],           'upper bound, last repeated');
is_deeply(pc('20',     [8,50]),    [20,20],          'fixed, last repeated');
is_deeply(pc('-10,+2', [30,5]),    [20,7],           'relative to content');
is_deeply(pc('=',      [30]),      [30],             'bare = is content width');
is_deeply(pc('10,20,30', [5,5]),   [10,20],          'extra entries ignored');
eval { pc('abc', [5]) }; like($@, qr/^Invalid number: abc$/m, 'invalid token dies');
```

- [ ] **Step 2: Run to verify failure**

Run: `prove -l t/03_table_wrap.t`
Expected: FAIL, undefined `parse_cell_spec`

- [ ] **Step 3: Implement `parse_cell_spec` in `lib/App/ansicolumn/Table.pm`**

- [ ] **Step 4: Run to verify pass**

Run: `prove -l t/03_table_wrap.t`
Expected: PASS

- [ ] **Step 5: Commit** (ask the maintainer first)

```bash
git add lib/App/ansicolumn/Table.pm t/03_table_wrap.t
git commit -m "Add parse_cell_spec for per-column table widths"
```

### Task 3 (A3): Wrap cells in `table_out`

**Files:**
- Modify: `lib/App/ansicolumn/Table.pm` (add `table_fold`, `expand_table_rows`)
- Modify: `lib/App/ansicolumn.pm:688-760` (`table_out`)
- Test: `t/03_table_wrap.t` (CLI tests through `t/ac.pm`, expected output in `__DATA__` sections via `Data::Section::Simple`, as in `t/01_run.t`; note `ac->exec` strips trailing spaces)

**Interfaces:**
- Consumes: `table_widths`, `parse_cell_spec` from A1/A2.
- Produces (methods on the ansicolumn object):
  - `$obj->table_fold($width) -> Text::ANSI::Fold`: `width => $width`, `boundary => ($obj->boundary || 'word')`, `linebreak => ($obj->linebreak ? $obj->lb_flag : LINEBREAK_ALL)`, `margin => (that linebreak & LINEBREAK_RUNIN) ? min($obj->runin, $width - 1) : 0` (clamped: Text::ANSI::Fold dies with `margin too big` when `width <= margin`; verified, so `--cell 1`/`--cell 2` must still work), `runin`/`runout`/`ambiguous`/`padchar` from the object, `padding => 0`; `configure(discard => ['EL'])` when `$obj->discard_el`, as `foldobj` does.
  - `$obj->expand_table_rows(\@rows, \@target) -> @rows`: for each logical row, cells whose `ansi_width` exceeds `$target[$i]` (when defined) are split with `table_fold($target[$i])->text($cell)->chops`; each chop has trailing horizontal whitespace stripped (`s/\h+((?:\e\[[\d;]*m)*)$/$1/`); an empty cell yields one `''` line; the row becomes `max(lines)` physical rows, missing cells filled with `''`, ragged rows stay ragged (never extend a row beyond its own cell count).

- [ ] **Step 1: Write the failing CLI tests**

Common input `$tbl = "|key|description|\n|k1|the quick brown fox jumps over the lazy dog|\n|k2|short|\n"` and base options `my @T = ('-t', '-s', '|', '--table-remove=1,-0');`.

```perl
# fits: identical with and without -w
is(ac->new(@T, '-w', 80)->exec($tbl), ac->new(@T)->exec($tbl), 'fits-identical');

for (
    [ 'wrap'        => [@T, '-w', 30] ],
    [ 'item-format' => [@T, '-w', 34, '-o', '|', '--item-format= %s '] ],
    [ 'right'       => [@T, '-w', 30, '--table-right=2'] ],
    [ 'cell-fixed'  => ['-t', '-s', '|', '--table-remove=1,-0', '--cell', '20,0', '-o', '|'] ],
) { my($name, $opt) = @$_; is(ac->new(@$opt)->exec($tbl), get_data_section($name), $name) }
```

Expected `__DATA__` sections (fold width is target minus run-in margin 2; `wrap` has budget 28, L = 25; `item-format` has budget 33, F = 2, L = 26):

```
@@ wrap
key  description
k1   the quick brown fox
     jumps over the lazy dog
k2   short
@@ item-format
 key | description
 k1  | the quick brown fox
     | jumps over the lazy dog
 k2  | short
@@ right
key              description
k1       the quick brown fox
     jumps over the lazy dog
k2                     short
@@ cell-fixed
key                 |description
k1                  |the quick brown fox jumps over the lazy dog
k2                  |short
```

Assertion-style tests (compute from output, no data section); helper `sub widths { map { ansi_width($_) } split /\n/, shift }` with `use Text::ANSI::Fold::Util qw(ansi_width)`:

- `equal-level`: input `"|aaaa bbbb cccc dddd eeee|1111 2222 3333 4444 5555|\n"` ×2 rows, `@T, '-w', 30`: both columns produce 3 physical lines per row, and the two columns' max widths are equal.
- `japanese`: input row `"|j|ああああああああああ。いいいいいいいいいい、ううう|\n"` ×3 rows, `@T, '-w', 24`: no output line starts (after the first column) with `。` or `、`, and every line width `<= 24`.
- `sgr`: cell `"\e[1mthe quick brown fox jumps over the lazy dog\e[m"`, `@T, '-w', 30`: every line width `<= 28` and each physical line of the bold cell both contains `\e[1m` and ends its colored run with `\e[m` (Text::ANSI::Fold reopens SGR).
- `empty-cells`: `"|a|bbbbbbbbbbbbbbbbbbbbbbbbbbbb|\n|c||\n|d|e|\n"`, `@T, '-w', 20` (column 2 wraps, so the empty cell in row 2 goes through the fold path): a line starting with `c` exists, row 2 is exactly one line, and `"|||\n|||\n|||\n"` with the same options yields exactly 3 lines.
- `align-ignored`: `ac->new('-t', '-A', '-w', 20)->exec("a bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb\n")` equals the same without `-w`.
- `floor`: `@T, '-w', 3` on `$tbl`: output non-empty, finishes (set `alarm 10`).
- `cell-tiny`: `--cell 1` and `--cell 2` on `$tbl` (with `@T`): both finish under `alarm 10`, output non-empty, column 1 is 1 and 2 wide respectively.
- `cell-auto`: `'-t','-s','|','--table-remove=1,-0','--cell','0,0,20'` on a 3-column table whose columns are 5, 5 and 50 wide: columns 1–2 single-line, column 3 width `<= 20`.
- `cell-cap`: `--cell '<20'` on `$tbl`: column 1 stays 3 wide, column 2 `<= 20`, 5 output lines.
- `cell-with-width`: `--cell 0,10 -w 60` on a 3-column table (5, 40, 60 wide): column 2 is exactly 10 wide, columns 1 and 3 fit in `60 - 10 - 4`.
- `ragged`: `"|a|b|c|\n|dddddddddddddddddddddddddd|\n"` with `@T, '-w', 20`: second row wraps into lines that contain no `|` and no cells beyond the first; row 1 is one line. Do not assert on warnings: plain `-t` already emits `Use of uninitialized value in sprintf` for ragged input (verified before this change); the expansion must not add new kinds of warnings.
- `limit`: `-t -s '|' -l 3 -w 30` on `"|a|b|c|d|e|\n"` ×3 rows: the split yields `''`, `a`, `b|c|d|e|`, so the third cell keeps its separators; output non-empty, widths `<= 30`.
- `padding-wrap`: `@T, '-w', 30, '--padding'` on `$tbl`: all raw output lines (use `->update->data`, not `exec`) have equal `ansi_width`.
- `parallel-unchanged`: `ac->new('-V', '--cell', '20,10')->exec` on two files from `t/` equals the pre-change output captured once (store the expected text in a data section the implementer generates with the unmodified code before Step 3).

- [ ] **Step 2: Run to verify failure**

Run: `prove -l t/03_table_wrap.t`
Expected: the data-section tests fail (no wrapping yet); `fits-identical`, `align-ignored`, `parallel-unchanged` pass already.

- [ ] **Step 3: Implement `table_fold`, `expand_table_rows`, and wire `table_out`**

New `table_out` order (existing code otherwise unchanged):

1. split, `--table-remove`, `--table-squeeze` (as now)
2. **new:** raw `@content` = per-column max `ansi_width` over rows; `$F = $obj->item_format ? ansi_width(ansi_sprintf($obj->item_format, '')) : 0`; `$S = ansi_width($obj->output_separator)`; `$fixed = parse_cell_spec($obj->cell, \@content)` when `$obj->cell`; `$budget = defined $obj->width ? $obj->get_width - $S * (@content - 1) : undef` (`-w=` stores `''`, so test `defined`, read via `get_width`; verified that nothing else assigns `width`, so `defined` means the user typed `-w`/`-c`, and `-W`/`-D`/`-P` do not activate wrapping); when `!$obj->table_align && !$obj->table_tabs && ($fixed || defined $budget)`: `$target = table_widths(\@content, $budget, $F, $fixed, 4)` and `@lines = $obj->expand_table_rows(\@lines, $target)`
3. item format (as now, now applied to physical lines)
4. measure, `@max` (as now); **new:** for each fixed column `$max[$i] = max($max[$i], $fixed->[$i] + $F)` so `--cell 20` pads a short column
5. alignment, formats, print (as now)

- [ ] **Step 4: Run the whole suite**

Run: `prove -l t/`
Expected: PASS, including unchanged `t/01_run.t` and `t/02_yamanashi.t`. If a data-section expectation differs only in where Text::ANSI::Fold breaks, confirm every line is `<= target` and the first line is the longest word-boundary prefix, then correct the expected text.

- [ ] **Step 5: Commit** (ask the maintainer first)

```bash
git add lib/App/ansicolumn/Table.pm lib/App/ansicolumn.pm t/03_table_wrap.t
git commit -m "Wrap over-wide table cells with -t -w and --cell"
```

### Task 4 (A4): Documentation

**Files:**
- Modify: `script/ansicolumn` POD: `-w` item (line 150), `-t` item (163), `--cell` item (326); SYNOPSIS lines 21 and 35
- Modify: `lib/App/ansicolumn.pm` only if the SYNOPSIS is duplicated there (it is not; `-sections` reads the script)

- [ ] **Step 1: Write the POD**

Under `-t`: with `-w`, the table is fit into that width; columns that fit keep their width, over-wide columns share the remaining width equally (water level) and their cells wrap at word boundaries with Japanese line-break rules; floor 4; ignored with `-A`/`-T`; a fitting table is unchanged. Under `--cell`: drop "only valid in parallel view mode"; add the table-mode grammar (`N`, `<N`, `+N`/`-N`, `0` = auto, last repeated, combination with `-w`). SYNOPSIS: `-w#, -c#  output width (fit table in -t mode)` and `-X#, --cell=#  cell widths (parallel view / table columns)`.

- [ ] **Step 2: Verify**

Run: `podchecker script/ansicolumn && perl -Ilib script/ansicolumn --help | grep -n 'cell\|width'`
Expected: `script/ansicolumn pod syntax OK`; both lines show the new text.

- [ ] **Step 3: Commit** (ask the maintainer first)

```bash
git add script/ansicolumn
git commit -m "Document table fitting with -w and --cell in table mode"
```

### Task 5 (A5): Release ansicolumn and install locally

- [ ] **Step 1:** Maintainer releases with the `minilla-release` skill (planned version `1.58`; `Changes` entry: "Fit tables into -w width by wrapping over-wide cells; --cell sets per-column widths in table mode").
- [ ] **Step 2:** Install the released or working-tree version where mdee's greple will find it: `cpanm .` in the ansicolumn directory (or the released tarball). Verify: `perl -MApp::ansicolumn -e 'print $App::ansicolumn::VERSION'` prints `1.58` or later.

---

## Part B: mdee / App::Greple::md

Working directory: `~/Git/tecolicom/App-mdee`. Run tests with `prove -l t/`. `t/Util.pm`'s `run()` invokes the installed greple with the local `lib/App/Greple/md.pm`.

### Task 6 (B1): `table_width` and `table_cell` config in the md module

**Files:**
- Modify: `lib/App/Greple/md.pm:349-365` (`Config->new`), `:441` (`deal_with` specs), `:792-812` (`format_table`), POD config list near line 204
- Create: `t/table_wrap.md` (fixture)
- Test: `t/05_table_wrap.t`

**Interfaces:**
- Config: `table_width => 0` (int; 0 = off), `table_cell => ''` (string; entries separated by `:` because `,` separates config parameters in `-Mmd::config(...)`; converted with `tr/:/,/` before use). Verified: values containing `:` and `<` pass through `-Mmd::config(...)` intact.
- `format_table()` adds to the `call_ansicolumn` argument list: `('-w', $config->{table_width})` when `table_width > 0`; `('--cell', $cell)` when `table_cell` is non-empty, where `$cell` is the comma form, prefixed with `0,` in non-trim mode (the phantom first column, same reason as the `$_++` offset on alignment columns).
- `deal_with` gains `"table_width=i", "table_cell=s"`.
- Non-trim note: the `-s '|'` split also yields a trailing phantom column, so "last entry repeated" lands on it. Harmless: the last column is never padded without `--padding`, which the md module passes only in trim mode.

- [ ] **Step 1: Create the fixture `t/table_wrap.md`**

```markdown
# Wrap

| key | description |
|-----|-------------|
| k1 | the quick brown fox jumps over the lazy dog and keeps on running through the field |
| - alpha | this is a fairly long description cell that goes well beyond forty columns wide |
| 日本 | これは長い説明文で、幅に収まらないので折り返されるはずの文章です。句読点、括弧（あり）。 |
| k2 | short |
```

- [ ] **Step 2: Write the failing tests `t/05_table_wrap.t`** (same preamble as `t/03_nofork.t`; `use Text::ANSI::Fold::Util qw(ansi_width)`; `$strip` removes `\e\[[0-9;]*[mK]` and OSC 8 `\e\]8;;[^\e]*\e\\`)

```perl
my $md = 't/table_wrap.md';
my $V = "\x{2502}";
sub table_lines { grep { /[\x{2502}\x{253C}]/ } map { $strip->($_) } split /\n/, shift }

my $wrapped = run("'-Mmd::config(colorize=0,table=1,rule=1,table_width=40)' $md")->stdout;
my @w = table_lines($wrapped);
ok(@w > 6, 'rows were wrapped into extra lines');
ok(!(grep { ansi_width($_) > 40 } @w), 'every table line fits in 40 columns');
ok((grep { /^\s+$V/ } @w), 'continuation lines keep the column rule');
is(scalar(grep { /\x{253C}/ } @w), 1, 'exactly one separator row (continuation lines are not mistaken for one)');
unlike($wrapped, qr/^\s*[。、]/m, 'no line starts with Japanese closing punctuation');

my $plain = run("'-Mmd::config(colorize=0,table=1,rule=1)' $md")->stdout;
ok((grep { ansi_width($_) > 40 } table_lines($plain)), 'without table_width the table is wider than 40');
is(run("'-Mmd::config(colorize=0,table=1,rule=1,table_width=200)' $md")->stdout, $plain,
   'a fitting width leaves output unchanged');

my $cell = run("'-Mmd::config(colorize=0,table=1,rule=1,table_cell=0:10)' $md")->stdout;
ok(!(grep { /$V(.*)$/ && ansi_width($1) > 12 } table_lines($cell)), 'table_cell caps column 2 at 10 (+padding)');

my $notrim = run("'-Mmd::config(colorize=0,table=1,rule=1,table_trim=0,table_cell=0:10)' $md")->stdout;
ok(!(grep { /^\S*$V[^$V]*$V(.*?)$V/ && ansi_width($1) > 12 } table_lines($notrim)), 'non-trim mode shifts the cell list');
```

- [ ] **Step 3: Run to verify failure**

Run: `prove -l t/05_table_wrap.t`
Expected: FAIL (`table_width` unknown to `Getopt::EX::Config`, or output not wrapped).

- [ ] **Step 4: Implement** the config keys, `deal_with` specs, `format_table` arguments, and POD entries (`table_width  table width in columns, wrap over-wide cells (default: 0 = off)`, `table_cell   per-column widths, colon-separated, passed to ansicolumn --cell`).

- [ ] **Step 5: Run to verify pass**

Run: `prove -l t/05_table_wrap.t t/03_nofork.t t/04_table_align.t`
Expected: PASS

- [ ] **Step 6: Commit** (ask the maintainer first; run `minil build` before)

```bash
git add lib/App/Greple/md.pm t/table_wrap.md t/05_table_wrap.t
git commit -m "Add table_width and table_cell config to md module"
```

### Task 7 (B2): Fix the `{TABLE}` fold-exclude pattern

**Files:**
- Modify: `lib/App/Greple/md.pm:873` (`define {TABLE}`)
- Test: `t/05_table_wrap.t`

**Interfaces:**
- New pattern: `^(?:[│|├─\h-][^\n]*[│|┼][^\n]*\n){3,}` — three or more consecutive lines that start with a border character, a rule character, a dash, or whitespace, and contain a column separator. Matches trim/non-trim × rule/non-rule output, wrapped continuation lines, and separator rows. Known limitation: a one-column table in trim mode has no separator and is not excluded.

- [ ] **Step 1: Write the failing test** (append to `t/05_table_wrap.t`)

```perl
my $folded = run("'-Mmd::config(colorize=0,table=1,rule=1,foldlist=1,foldwidth=40,table_width=200)' $md")->stdout;
my @f = map { $strip->($_) } split /\n/, $folded;
my ($start) = grep { $f[$_] =~ /key.*description/ } 0..$#f;
my ($end)   = grep { $f[$_] =~ /^\s*k2\s/ } 0..$#f;
is($end - $start, 5, 'table rows are not re-folded by ansifold (header, rule, 4 rows)');
ok(!(grep { !/[\x{2502}\x{253C}]/ } @f[$start..$end]), 'every table line keeps its rule character');
```

- [ ] **Step 2: Run to verify failure**

Run: `prove -l t/05_table_wrap.t`
Expected: FAIL — the `- alpha` row is folded into extra lines without `│`.

- [ ] **Step 3: Replace the `{TABLE}` definition**

- [ ] **Step 4: Run to verify pass**

Run: `prove -l t/`
Expected: PASS. Also eyeball `./script/mdee -s cat -w 40 t/table_wrap.md`: the `- alpha` row shows continuation lines with `│`, none indented by three spaces.

- [ ] **Step 5: Commit** (ask the maintainer first; `minil build` before)

```bash
git add lib/App/Greple/md.pm t/05_table_wrap.t
git commit -m "Fix TABLE fold-exclude pattern to match trim-mode output"
```

### Task 8 (B3): mdee passes the fold width; docs and dependency

**Files:**
- Modify: `script/mdee:466` (config params), POD `--[no-]table` (line 736), `--width` (774), config parameter list (near 962)
- Modify: `cpanfile:9` → `requires 'App::ansicolumn', '1.58';`
- Modify: `CLAUDE.md` section "Table Formatting in md Module" (line 418): `call_ansicolumn` option list, `table_width`/`table_cell`, new `{TABLE}` pattern, the width budget formula
- Test: `t/01_mdee.t`

**Interfaces:**
- `script/mdee`: `[[ $fold ]] && config_params+=("foldlist=1,foldwidth=$width" "table_width=$width")` (same line as today, extended). `--config table_width=N` / `table_width=0` / `table_cell=0:10` already route to `md_config` and win over the mdee-supplied value (later key wins; verified).

- [ ] **Step 1: Write the failing subtests** (append to `t/01_mdee.t`; add `use Encode qw(decode_utf8); use Text::ANSI::Fold::Util qw(ansi_width);` at the top, since backtick output is bytes; define `$strip` as in B1)

```perl
subtest 'table wrap' => sub {
    my $md = File::Spec->rel2abs('t/table_wrap.md');
    my $out = `$mdee -s cat -w 40 $md`;
    my @t = grep { /[\x{2502}\x{253C}]/ } map { $strip->($_) } split /\n/, decode_utf8($out);
    ok(@t > 6, 'wide table is wrapped');
    ok(!(grep { ansi_width($_) > 40 } @t), 'table fits in --width');
    my $off = `$mdee -s cat -w 40 --config table_width=0 $md`;
    ok((grep { ansi_width($_) > 40 } grep { /\x{2502}/ } map { $strip->($_) } split /\n/, decode_utf8($off)),
       '--config table_width=0 disables wrapping');
    my $cell = `$mdee -s cat -w 40 --config table_cell=0:10 $md`;
    isnt($cell, $out, '--config table_cell changes the layout');
    my $dry = `$mdee -ddn -s cat -w 40 $md 2>&1`;
    like($dry, qr/table_width=40/, 'table_width is passed to the md module');
};
```

- [ ] **Step 2: Run to verify failure**

Run: `prove -l t/01_mdee.t`
Expected: FAIL on `wide table is wrapped` and `table_width is passed`.

- [ ] **Step 3: Implement** the `config_params` change, POD (under `--table`: tables wider than `--width` wrap over-wide columns; under `--width`: also the table width; config list: `table_width`, `table_cell`), `cpanfile`, `CLAUDE.md`.

- [ ] **Step 4: Run everything**

Run: `minil build && prove -l t/`
Expected: PASS; `README.md` regenerated by `minil build`.

- [ ] **Step 5: Commit** (ask the maintainer first)

```bash
git add script/mdee cpanfile CLAUDE.md README.md lib/App/mdee.pm t/01_mdee.t
git commit -m "Wrap over-wide table cells to the fold width; require App::ansicolumn 1.58"
```

### Task 9 (B4): Release mdee

- [ ] Maintainer releases with the `minilla-release` skill after ansicolumn 1.58 is on CPAN (`Changes`: "Wrap over-wide table cells to the fold width (requires App::ansicolumn 1.58); fix table fold-exclude pattern in trim mode").
