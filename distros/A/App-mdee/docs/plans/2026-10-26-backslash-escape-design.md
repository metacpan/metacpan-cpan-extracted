# Backslash Escape Handling (future plan)

Date: 2026-10-26

Status: not started.  Memo written after the escaped-pipe fix
(commit 76ee939) so that the general case is not forgotten.

## Problem

The md module does not process Markdown backslash escapes at all.
Any ASCII punctuation may be escaped in CommonMark (`\*`, `\_`,
`` \` ``, `\#`, `\[`, `\|`, ...), and the escaped character is
literal text.  Today:

    input:  a \* b \* c, x \_y\_ z, 1\. two, \`tick\`
    output: a \* b \* c, x \_y\_ z, 1\. two, \tick\

- `\*`, `\_`, `\.` are shown with the backslash.
- `` \`tick\` `` is mistaken for a code span and mangled.
- `\|` in a table cell is no longer split as a column separator
  (76ee939), but it is still displayed as `\|`.

The emphasis patterns already carry `(?<!\\)` lookbehinds, so an
escaped marker does not start emphasis; the backslash itself is just
never removed.

## Why it was not done inside format_table

An escaped pipe must be excluded from the column split but measured
as one column by ansicolumn, and shown as `|` afterwards.  Doing that
only for `|` (a fixed placeholder such as U+E000, or Text::Conceal)
works, but it is a table-local patch for a Markdown-level feature.
Text::Conceal was tried and dropped: the object has to be created per
block, decode must only follow encode, and the characters ansicolumn
inserts (separator, cell and wrap marks) must be passed as `except`
or decoding fails silently.  The right place is the colorize
pipeline, where code spans and links are already protected.

## Design sketch

1. Add an `escapes` step at the front of `@protect_steps` in
   `colorize()`: `s/\\([!-\/:-@\[-`{-~])/protect(...)/ge`.  Protection
   uses the existing `\e[256mN\e[m` placeholders, so emphasis, code
   span and link patterns never see the escaped character.
2. `restore()` returns the character wrapped in a width-neutral
   marker instead of the bare character: `\e[257m|\e[m` (SGR 257 is
   not a real attribute; terminals ignore it, Text::ANSI::Fold and
   ansicolumn count it as one column).  The marker ends in `\e[m`
   like the other placeholders, so cumulative coloring in headings
   keeps working.
3. `format_table` splits columns with `-rs '\s*(?<!\e\[257m)\|\s*'`
   (and the same regex instead of `-s '|'` in non-trim mode), so a
   marked pipe is cell content.  The current `(?<!\\)` lookbehind is
   then unnecessary, and the `\\|` case (escaped backslash followed by
   a real separator) comes out right.
4. After `format_table`, at the end of `begin()`, strip the markers:
   `s/\e\[257m(.)\e\[m/$1/g`.
5. Fold exclusion patterns (`{CODE_BLOCK}`, `{LIST_ITEM}`, ...) and
   `table_regions()` need a check that a marker at a line start does
   not change what they match.

## Tests to write first

- `\*`, `\_`, `\#` at line start, `\.` after a digit: shown without
  the backslash, no emphasis/heading/list formatting.
- `` \`tick\` ``: literal backticks, no code span.
- `\|` in a table cell: shown as `|`, still one column, widths right;
  with cell wrapping; in non-trim mode; `\\|` splits.
- Inside a heading with `heading_markup` off and on.
- `--no-theme` / raw style: should the source be shown as written?
  Decide: raw style keeps the backslashes (it is the source view).

## Concept check

mdee shows the source as written (see the Concept section of the
manual).  Removing an escaping backslash is a small step away from
that, comparable to hiding markup characters, which the default
themes already do.  It should therefore follow the same rule: on by
default, and `--no-theme` (or a `showmark`-like theme) shows the
backslashes again.
