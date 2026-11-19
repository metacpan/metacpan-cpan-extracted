# App::AnteREPL

`anterepl` combines immediate Perl execution with an in-memory, numbered
program and an editable scrolling screen inspired by the C64 BASIC prompt.
The startup banner is `*** PERL ANTE REPL V0.1 ***`.

Screen editing inserts characters by default; Insert toggles overwrite mode.
Move up, edit an earlier entry, and press Enter to replace its result directly
below it. Later entries stay intact while they fit, without an added blank spacer. The cursor
follows the result onto the next row; Esc moves to fresh input at the bottom.

```text
AUTO
say "hi"
say "there!"
AUTO OFF
LIST
5  say "hi";
10 say "there!";
RUN
hi
there!
```

`AUTO` supplies numbers in increments of 5. `AUTO OFF`, Ctrl-C, or Ctrl-D ends entry.
Entries stay quiet by default; `LIST` shows numbers, or use `AUTO ECHO ON`.
Outside AUTO, ordinary Perl executes immediately. `EDIT` opens the stored
program in `$EDITOR`; `EDIT ENV` edits `%ENV` using `VAR=value` lines.
`CLS` clears the screen and resize bank while keeping the stored program, live Perl
variables, and `%ENV`. Use `LIST` to display the program again.
All REPL commands and subcommands are uppercase, including `LIST`, `AUTO OFF`,
`ENV SET`, `DUMP`, and `PEEK`. Lowercase Perl keywords and defined functions
retain their meaning; immediate lists follow the shorthand rules below.
Filenames, environment
names, values, and Perl code retain their case. `EVAL` executes immediately;
lowercase `eval` is ordinary Perl.
A command-like bareword such as `cls` gets a short `try, "CLS".` spelling hint.
`CD directory` and `CHDIR directory` change this session's directory; ordinary
Perl such as `chdir $ENV{HOME}` still works. Ctrl-C cancels or interrupts and
reminds you how to leave with `QUIT`, `QUIT!`, or Ctrl-D.
Shift+Enter (when the terminal distinguishes it) or Ctrl-N inserts a newline
without submitting, including inside an editable multiline EVAL block.
`EVAL sub triple { return 3 * shift; }` defines a session-only function in the
current workspace. Immediate code and `RUN` can call it; it does not enter
the numbered program or appear in `SAVE`. `FUNCTIONS` lists defined functions
in the current workspace, including imports. Redefining a named subroutine
through ordinary Perl replaces it with the usual warning, without confirmation.
Shorthand redefinitions ask first, as described below.
Call it as `say triple 14`. Bare calls use Perl's normal precedence and
prototype rules; parentheses remain available when needed for grouping.

Command shortcuts need one shifted letter: `E` evaluates, `L` lists, `R` runs,
`C` clears the screen, `H` shows HELP, and `Q` quits. Digits resolve collisions:
`E1` edits, `L1` loads, `R1` renumbers. Every command and option has a shortcut;
`H` lists the complete table. Existing long commands still work.
Destructive shortcuts ask `Continue? [y/N]`; append `!` to skip the question,
for example `D1! 10-30`, `R2!`, `S! demo.pl`, or `Q!`. New files and values do
not prompt. Piped input requires `!` for a destructive shortcut.

Immediate definitions include:

```text
E s triple return 3 * shift
E a colors red, blue
E ar names Ada, Bob
E h options color => blue
E hr record name => Ada
```

With AUTO off, `a one, two, threee` defines persistent `@a` with those exact
strings. Perl keywords and existing functions take priority over bare destination
names. E reserves the five spaced definition tags; EVAL always accepts literal
Perl. Normal quotes and q/qq/qw/regex operators work inside shorthand lists.
Other Perl expressions
go in parentheses. Replacing existing destinations asks first; `E! a colors
green` and `colors! green, blue` force replacement. Literal EVAL and arbitrary
Perl retain their usual side effects. See [the complete grammar and review checklist](docs/SHORTCUTS-AND-SHORTHAND.md).
For a hands-on test session, follow [the human QA/QC walkthrough](docs/HUMAN-QAQC.md).

## A screen-sized work area

The white border encloses the working "VRAM", like a sheet of graph paper.
A single-line command legend stays below it. An 80x24 terminal gives 78x21 editable
cells; resizing adjusts the interior. Output scrolls old rows away; long lines wrap.
The legend shows commands to type and submit with Enter, such as H for HELP.
The input loop blinks the cursor every half second; insert requests a bar
and overwrite a block, subject to terminal shape support. CLS clears the interior and retains the frame.
`--plain` uses normal terminal input without the frame, legend, or cursor styling.
Interactive exits print: `Thank, we hope something good happens to you today!`
PageUp cannot reach an invisible history.

Making the window smaller cuts off rows and columns. AnteREPL warns and keeps
one separate copy from before the shrink. Making it bigger adds empty cells:
lost text does not return on its own. To get the copy back, enlarge to the size
in the warning and type `RECOVER`. That replaces the current screen without
running code. `CLS` forgets the copy; ordinary scrolling does not make one.

Your numbered program and live Perl values are separate from this sheet.
`LIST` brings source back into view; `SAVE` writes source to disk. Use `EDIT`
for code too large to fit on the screen. An entry clipped by the boundary
cannot run as partial Perl. `HELP` pauses by screenful in screen mode.

## Install and run

Requires Perl 5.16 or newer. Install a release archive:

```sh
cpanm ./App-AnteREPL-0.01.tar.gz
anterepl
```

Or install from this checkout:

```sh
perl Makefile.PL
make test
make install
```

Run without installing with `perl -Ilib script/anterepl`. Native Windows
screen mode also needs `Term::ReadKey` and an ANSI-capable terminal. Unix can
use the core POSIX backend. `anterepl --plain` disables screen editing.

## Learn to use it

- [User guide and tutorials](https://github.com/oodler577/p5-App-AnteREPL/wiki)
- [First session](https://github.com/oodler577/p5-App-AnteREPL/wiki/First-session)
- [Commands](https://github.com/oodler577/p5-App-AnteREPL/wiki/Command-reference)
- [Troubleshooting](https://github.com/oodler577/p5-App-AnteREPL/wiki/Troubleshooting)
- Offline: `HELP`, `anterepl --help`, or `perldoc App::AnteREPL`.

`LOAD program.pl` reads ordinary Perl; `SAVE` remembers that file and format.
`.bperl` files preserve editing numbers. `LIST` supports ranges, slow output,
and pause/step controls. Move up into a listed row, edit it, and press Enter to
replace that program line. `DUMP` and `PEEK` inspect live values.

Source files do not save runtime variables. `my` variables last for one
evaluation; use package variables for values shared across commands. Native
Windows screen behavior has not yet been verified on Windows.

## Development

`prove -lr t` runs the tests. `dzil test` and `dzil build` use `dist.ini`.
Dist::Zilla is a maintainer dependency, not needed to install or run a release.
See [CONTRIBUTING.md](https://github.com/oodler577/p5-App-AnteREPL/blob/main/CONTRIBUTING.md)
for release contents and optional terminal checks.

Copyright (c) 2026 Brett Estrade. Licensed under the same terms as Perl itself.

## Talk material

The [Winter 2026 PCC talk draft](https://github.com/oodler577/p5-App-AnteREPL/tree/main/talks/winter-2026-pcc) includes an
editable Beamer tutorial and overview, speaker notes, a rendered PDF, and
rehearsal examples. Presentation files are excluded from the CPAN distribution.
