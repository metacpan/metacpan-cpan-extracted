# In-band Metadata by OSC, and Tables Kept Intact, Design

Date: 2026-11-20

Status: Tables Kept Intact is implemented (ansicolumn `--intact`, md
module `intact=table`, mdee), except keeping a table in one pane and
repeating its header row.  The OSC part is a draft, not implemented.

## Motivation

mdee sends its output to nup, and nup lays it out with ansicolumn.
Between them there is only text: ansicolumn reads the standard input
and knows nothing of what the lines are.  Several things would be
better if it did:

- **Tables are folded by the panes.**  A pane folds every line at the
  pane width minus the run-in width, so that run-in characters
  (kinsoku) have room.  Tables are formatted to the fold width, which
  is the same, and the last run-in width of every pane (4 columns by
  default) is never used by a table.  Fitting tables to the full pane
  width makes nup fold their lines (tried on 2026-11-20).  Not folding
  every line that fits the pane is not the answer either: prose lines
  that fit only in the run-in room would end further right than the
  folded lines around them.  The pane has to know which lines are
  table lines.  This is done without OSC (see Tables Kept Intact).
- **The file name takes a line.**  ansicolumn can put labels on the
  border (`--label`, with `%f` and `%F` for the file name), but the
  file name comes from the command line.  mdee feeds nup through the
  standard input, so nup shows the name in a header line and mdee
  embeds it in the text (greple's `--format FILE=`, theme key
  `FILE_FORMAT`).
- Other information that the producer has and the layout could use:
  the section a pane is in, the source line, where a block starts and
  ends.

## Approach

The producer (the md module, greple, mdee) puts the information in
the text as OSC (Operating System Command) sequences, and ansicolumn
reads them and takes them out of its output.

Considered:

| Approach | Trade-off |
|---|---|
| **OSC sequences in the text (chosen)** | Goes through pipes, greple and nup unchanged.  Text::ANSI::Fold already counts any OSC as width 0 and keeps it with the text it precedes when it folds (checked with `ESC ] 7777 ; nofold ESC \` and with BEL as the terminator).  Needs a number of our own and must be removed before a terminal sees it. |
| A side file or environment variable mapping lines to files | Breaks as soon as a stage adds or removes lines; nup and ansicolumn would need a new input. |
| Guessing from the text (rule characters of a table) | No change to the producers, but the `3line` and `simple` table styles have no column separators, and prose can contain the same characters. |
| Invisible characters (as U+2028 is used for `<br>`) | No standard character fits, and every tool on the way counts or shows them. |

## Standards and Prior Art

- **ECMA-48** defines OSC as "the opening delimiter of a command
  string for an operating system", whose interpretation "depends on
  the relevant operating system".  It has no numeric parameter: the
  `OSC Ps ; Pt ST` form is the convention of xterm, not of the
  standard.  The command string is bytes 0x20-0x7E, closed by ST.
  There is no registry of OSC numbers; a registry was proposed in the
  freedesktop terminal-wg (specifications issue #10), and none seems
  to have been adopted.
- ECMA-48 also has **APC**, "a command string for an application
  program", which fits this use better by its definition, and xterm
  ignores its content.  But Text::ANSI::Fold does not know APC (nor
  PM and DCS): it counts the string as visible text and folds it in
  the middle (checked on 2026-11-20).  Using APC would need changes in
  Text::ANSI::Fold and in everything that measures width.
- **Private uses of OSC** with numbers picked by the user, none
  registered:
  - OSC 133 (FinalTerm, semantic prompts) and OSC 633 (VS Code, its
    extension, with `P;key=value` properties): mark the prompt, the
    command and the output, for the terminal to use.
  - OSC 1337 (iTerm2, also WezTerm): many proprietary commands, such
    as `SetUserVar`.
  - OSC 3008 (systemd, UAPI.15 "Hierarchical Context Signalling"):
    the closest to this design.  `3008;start=ID;type=...` and
    `3008;end=ID;exit=...`; fields are `;key=value`, `;` and `\` in
    values are escaped as `\x3b` and `\x5c`, text is UTF-8, and
    "unknown fields should be ignored".  Its page notes that no
    terminal is known to consume it, and users who saw it over SSH as
    garbage have written guides to turn it off: what happens when a
    sequence reaches a program that does not know it.
- xterm documents no range for private use and does not say what it
  does with an OSC number it does not know.  Terminals are reported to
  ignore unknown OSC, but that is not promised anywhere; this design
  does not rely on it and removes the sequences before the terminal.

### Numbers in Use

Collected on 2026-11-20 from terminfo-dev, xterm ctlseqs and the kitty
documentation.  It is not a registry: terminfo-dev warns that
terminals "occasionally pick the same number for different purposes",
and a number missing here is not known to be free.

| Number | Used by | Purpose |
|---|---|---|
| 0, 1, 2 | xterm | icon name and window title |
| 4, 5, 10-19, 104, 110-119 | xterm | colors, and their reset |
| 7 | xterm and many | current directory |
| 8 | many | hyperlinks |
| 9 | ConEmu, Windows Terminal | notification, progress (9;4), directory (9;9) |
| 21 | kitty | color protocol |
| 22 | xterm | pointer shape |
| 46 | xterm | log file |
| 50 | xterm | font |
| 51 | xterm | reserved for Emacs shell |
| 52 | xterm and many | clipboard |
| 66 | kitty | text sizing |
| 99 | kitty | desktop notifications |
| 133 | FinalTerm, iTerm2, VS Code, Windows Terminal, Ghostty | semantic prompts |
| 176 | (unnamed) | Wayland app-id |
| 440, 555 | (unnamed) | sound, screen flash |
| 633 | VS Code | shell integration |
| 666 | VTE | terminal properties |
| 701, 702, 710, 720, 776 | (unnamed, rxvt family) | locale, version, font, scroll, cell size |
| 777 | rxvt family and others | notifications |
| 1337 | iTerm2, WezTerm | proprietary commands |
| 3008 | systemd | context signalling |
| 5113 | kitty | file transfer |
| 5522 | kitty | clipboard (extends 52) |
| 7770, 7777 | (unnamed) | font size, window size |
| 30001, 30101 | kitty | color stack push and pop |

### Candidates

- **2674** (chosen): "ANSI" on a phone keypad (A=2, N=6, S=7,
  I=4), for the ANSI-Tools family whose ansicolumn reads it.  Not in the list above.
- **6429**: the number of ISO 6429, the ISO edition of ECMA-48.  Not
  in the list, but it may be taken as something the standard defines.

### Sources

- ECMA-48, Markdown edition of the 2nd edition by Wez Furlong:
  https://wezfurlong.org/ecma48/07-control.html
- ECMA-48, 5th edition: https://ecma-international.org/wp-content/uploads/ECMA-48_5th_edition_june_1991.pdf
- XTerm Control Sequences: https://invisible-island.net/xterm/ctlseqs/ctlseqs.html
- UAPI.15 OSC 3008: https://uapi-group.org/specifications/specs/osc_context/
  (moved from https://systemd.io/OSC_CONTEXT)
- terminal-wg registry proposal (not readable from here):
  https://gitlab.freedesktop.org/terminal-wg/specifications/-/issues/10
- GNOME bug on unknown OSC: https://bugzilla.gnome.org/show_bug.cgi?id=403130
- OSC list of terminfo-dev: https://terminfo-dev.pages.dev/osc
- kitty protocol extensions: https://sw.kovidgoyal.net/kitty/protocol-extensions/
- iTerm2 escape codes: https://iterm2.com/3.1/documentation-escape-codes.html
- Windows Terminal shell integration:
  https://learn.microsoft.com/en-us/windows/terminal/tutorials/shell-integration

## Format

    ESC ] 2674 ; key=value ; key ; ... ST

- `2674` is the one OSC number for all of this (chosen on
  2026-11-20, see Candidates).
- `ST` is `ESC \`.  BEL is accepted when reading.
- Fields are separated by `;`.  A field is `key=value` or a bare
  `key` (a flag).
- Values are percent-encoded: `%`, `;`, `=`, control characters and
  ESC are written as `%XX`.  A file name may contain any of them.
- A reader ignores keys it does not know, so that keys can be added
  later without breaking older readers.

Two kinds of key:

- **State** (`file`, `heading`, ...): holds from the point where it
  appears until it is given again.  Put at the start of a line.
- **Line**: is about the line it is on.  Put at the start of the
  line.  None in phase 1 (see Later).

## Keys

### Phase 1

| Key | Kind | Producer | Use |
|---|---|---|---|
| `file=PATH` | state | mdee (greple's `--format FILE=`) | The file the following lines come from.  ansicolumn uses it for `%f` (base name) and `%F` (path) in labels, in place of the name from the command line. |

### Phase 2

| Key | Kind | Producer | Use |
|---|---|---|---|
| `heading=TEXT` | state | md module | The current section, for a label like a running head (a new placeholder, e.g. `%h`). |
| `level=N` | with `heading` | md module | Level of the heading: for a heading path in the label, and for PDF bookmarks in ansi2pdf. |
| `title=TEXT` | state | md module (first heading or front matter title) | A label, and the PDF document title. |
| `line=N` | state | md module | Source line of what follows; a label can show where a pane starts in the file.  The md module already records how table formatting shifts lines (`@table_shift`). |
| `matches=N` | state | greple | Number of matches in the file, for a label. |

### Later

These need new layout work in ansicolumn or nup, not only a label:

| Key | Kind | Use |
|---|---|---|
| `block=begin` / `block=end` | line | Keep a code block in one pane where possible (tables are kept intact already, see Tables Kept Intact). |
| `keep` | line | Keep a heading with the next line; no heading alone at the bottom of a pane. |
| `indent=N` | line | Indent of the continuation lines when the pane folds the line (list items). |
| `prefix=TEXT` | line | Put the text (`> ` of a block quote) at the start of continuation lines. |
| `truncate` | line | Cut the line at the pane width instead of folding it (code blocks). |

## Tables Kept Intact

The option is named by what it means, lines to be kept as they are,
not by how they are given: US is how they are given for now, and it
may change (to OSC, say) with the md module and ansicolumn together.
It is not only for tables: a code block or other preformatted text
can be kept intact the same way; the md module says which parts
(`intact=table`, later `intact=table:code`).  Other names considered:
`--block` (what it is not clear), `--usmode` (after `--crmode`, but
named by the mechanism), `--pre` and `--verbatim` (no image of data),
`--bundle` (no meaning of keeping).

Tables are sent as blocks, by the idea of the `--crmode` of
App::Greple::tee: the newlines in the middle of a formatted table are
replaced with US (UNIT SEPARATOR, 0x1F), and the last newline is kept.

    row 1 US row 2 US row 3 \n

The whole table is then one line to everything on the way, and
ansicolumn, which lays out the panes, divides it at US into its rows
again.  Unlike `--crmode`, where tee changes the newlines and changes
them back, the md module changes them and ansicolumn changes them
back, so the character is agreed between the two.

- **Why not a mark on every line.**  A mark (OSC `nofold`, or a
  control character at the start of the line) tells only that a line
  is not to be folded.  A block also tells where a table starts and
  ends, so that it can later be kept in one pane and its header row
  repeated on the next pane, with no other mark.
- **Why US.**  It is not in Perl's `\R`, so no tool on the way takes
  it as a line end, and it does not appear in ordinary text.  LINE
  SEPARATOR (U+2028) is in `\R`.  CR, used by `--crmode`, appears in
  ordinary text (CRLF files, progress lines).  RS (0x1E) fits the
  meaning of a row as well, but US was chosen.
- **The last newline is kept**, so that the table is exactly one line
  and the lines around it are not changed.  US goes only between
  rows: a table has at least three rows (header, separator, body), so
  every block has US in it.
- **Offsets do not move.**  `\n` and US are one byte each, and the
  regions of formatted tables recorded by the md module stay valid.
- **When.**  The md module replaces the newlines last, after the
  coloring and the folding, which use `^` and `$` on lines.  Only when
  asked (the config parameter `intact=table`); mdee asks only
  when nup is used.  Without nup (`--style=cat`, `pager`, `filter`,
  `raw`) tables are plain lines as now.
- **US used as data.**  US is a field separator by its definition,
  and `ansicolumn -t -s $'\x1f'` is a possible use.  ansicolumn takes
  US as a separator only with an option (`--intact`), and
  not in the table mode; mdee gives the option to the ansicolumn
  behind nup.

In ansicolumn, with the option, a line with US holds lines kept intact:

- Its rows are measured one by one when the width of the panes is
  decided, and counted one by one when the panes are filled.
- A row that fits the pane width, run-in room included, is padded and
  not folded; a row that does not fit is cut at the pane width, as a
  terminal does, with no word boundary and no line-break (kinsoku)
  rule: they are for text folded into lines, and a row is not text.
- Later: a block that does not fit the rest of a pane starts the next
  pane; a block taller than a pane is divided between rows, and the
  header row can be repeated.

With tables kept intact, the table width can be the fold width plus the run-in
width (`_total / _cols - 3` with nup), which was reverted on
2026-11-20 because the panes folded it.  mdee requires the ansicolumn
that has `--intact` when it is released.  One column is kept free at
the right (`fold_width + runin - 1`), so that the table rule does not
touch the pane border.

## Consumer: ansicolumn

- When a document is read, the sequences are taken out of the lines
  and kept by line: the state in force at every line, and the flags
  of every line.  All sequences of OSC 2674 are removed, known keys or
  not, so that none reaches the terminal.
- Labels: `%f` and `%F` take `file` at the first line of the pane
  when there is one, else the name from the command line as now.
- Nothing changes for input without the sequences.

## Producers

- **mdee**: when nup is used, sets greple's file format to the `file`
  sequence (in place of the visible file name), turns off nup's header
  line, and gives nup a label with `%f`.  Without nup (`--style=cat`,
  `pager`, `filter`, `raw`) it does not ask for the sequences.  How
  `--filename` and `FILE_FORMAT` map onto this is to be decided.
- **md module**: a config parameter (e.g. `osc=1`, off by default)
  turns the sequences on.  Later, headings put `heading`.  Tables are
  kept intact, not marked by OSC.
- **greple**: could emit `file` itself (an option), which would help
  nup used without mdee.  Not needed for phase 1: the file format is
  enough.

## Open Questions

1. How values are escaped: percent-encoding (above), or `\xNN` as
   OSC 3008 does.
2. Which state a pane label shows: that at the first line of the pane
   (simplest) or, for headings, the last one started in the pane (as
   the running head of a right-hand page).
3. Whether greple should emit `file` natively, and with what option.
4. How the sequences reach ansi2pdf and the PDF path of mdee (`-o
   file.pdf`, `--device`): removed there too, or used for bookmarks.
5. Whether nup needs to know the keys, or only passes them on to
   ansicolumn.

## Testing

- ansicolumn: the sequences are removed from the output; `%f`/`%F`
  from `file`; unknown keys are removed and ignored; percent-encoded
  values.  `--intact`: divided at US only with the option and not in the
  table mode; a row that fits the pane is not folded and one that
  does not fit is; widths and pane filling count rows.
- md module: US only between the rows of formatted tables, the last
  newline kept, and only with the config parameter.
- mdee: with nup, no table line is folded by the panes at the full
  table width (the disk image table of the 2026-11-20 report is a good
  case: a SHA-256 column that fills the width); without nup, no
  sequence and no US in the output.
