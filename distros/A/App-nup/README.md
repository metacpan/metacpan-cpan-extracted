[![Actions Status](https://github.com/tecolicom/App-nup/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/tecolicom/App-nup/actions?workflow=test) [![MetaCPAN Release](https://badge.fury.io/pl/App-nup.svg)](https://metacpan.org/release/App-nup)
# NAME

nup - n-up, multi-column paged output for commands and files

# SYNOPSIS

    nup [ options ] file ...
    nup -e [ options ] command ...

     -h  --help             show help
         --version          show version
     -d  --debug            debug mode
     -n  --dryrun           dry-run mode
     -e  --exec             execute command mode
         --alias=CMD=OPTS   set command alias
     -V  --parallel         parallel view mode
     -D  --document         document mode (default: on)
     -F  --no-paginate      disable page mode
     -A  --auto-paginate    auto disable page mode for single column
     -H  --filename         show filename headers (default: on)
     -C  --pane=#[,#]       number of columns, and rows (e.g., 2,2)
     -P  --page=#           page height in lines
     -S  --pane-width=#     pane width (default: 85)
    --bs --border-style=#   border style (default: heavy-box)
    --ls --line-style=#     line style (none/truncate/wrap/wordwrap)
         --runin=#          run-in width for line breaking
         --runout=#         run-out width for line breaking
         --runlen=#         set both run-in and run-out
         --boundary=#       fold boundary: word, space or none
    --cm --colormap=#       color mapping (LABEL=COLOR)
         --[no-]page-number page number on border (default: on)
         --textconv[=EXT]   textconv for non-text files
         --pager=#          pager command (empty to disable)
         --no-pager         disable pager
     -T  --device=#         output device: tty, pdf, or a paper for PDF
                            (e.g., a4, a4p, a3l)
     -o  --output=FILE      output file (PDF when it ends with .pdf)
         --pdf-opts=#       options for ansi2pdf (e.g., "-l 80")
         --geometry         print the size and the kind of the device
         --white-board      black on white board
         --black-board      white on black board
         --green-board      white on green board
         --slate-board      white on dark slate board

# VERSION

Version 1.12

# DESCRIPTION

**N-up** (command: `nup`) is a multi-column paged output tool.
It provides a convenient way to view files or run commands in
n-up layout using the [App::optex::up](https://metacpan.org/pod/App%3A%3Aoptex%3A%3Aup) module through `optex`.

<div>
    <p><img width="750" src="https://raw.githubusercontent.com/tecolicom/App-nup/main/images/nup.png"></p>
</div>

`nup` automatically detects the mode based on the first argument:
if it is an existing file, n-up file view mode is used; if it is an
executable command, n-up command mode is used.  Use `-e` option to
force command mode when needed.

In file view mode, `nup` stops parsing its own options at the first
file name and hands the file names and everything after them to
[ansicolumn](https://metacpan.org/pod/ansicolumn) unchanged.  Options of `ansicolumn` that `nup` does
not provide can therefore be given after the file names:

    nup -C2 file1.txt file2.txt -w 170

Here `-w 170` sets the output width for `ansicolumn`.  To set the
width when no terminal is available, the `COLUMNS` environment
variable works in both modes; see ["Terminal Size"](#terminal-size).

# OPTIONS

## General Options

- **-h**, **--help**

    Show help message.

- **--version**

    Show version.

- **-d**, **--debug**

    Enable debug mode.

- **-n**, **--dryrun**

    Dry-run mode. Show the command without executing.

- **-e**, **--exec**

    Force command execution mode. Normally the mode is auto-detected,
    but use this option when you want to execute a file as a command.

- **--alias**=_NAME_=_CMD_ _OPTS_...

    Define command alias. When a command matches _NAME_, it is replaced
    by _CMD_ with specified _OPTS_.  This can be used to add default
    options or to substitute a different command.
    Multiple `--alias` options can be specified.

    Default aliases:

        bat     bat --style=plain --color=always
        batcat  batcat --style=plain --color=always
        mdcat   mdcat --ansi
        rg      rg --color=always
        tree    tree -C

    Example:

        nup --alias='grep=ggrep --color=always' grep pattern file

- **-V**, **--parallel**

    Enable parallel view mode for ansicolumn.  In this mode, each file
    is displayed in its own column without pagination, similar to
    `--no-paginate`.  Automatically enabled when multiple files are
    specified.  Single file or stdin input results in single column
    output.

- **-D**, **--document**

    Enable document mode for ansicolumn.  This mode is optimized for
    viewing documents with n-up page-based layout.  Enabled by default.
    Use `--no-document` to disable.

- **-F**, **--no-paginate**

    Disable page mode.  Without pagination, the entire content is
    split evenly across columns.  Page mode is the default; use
    **--paginate** to re-enable if needed.

- **-A**, **--auto-paginate**

    Automatically disable page mode when only one column fits the
    terminal.  This is useful when using `nup` as `MANPAGER`,
    where single-column page splitting wastes space.

- **-H**, **--filename**

    Show filename headers in file view mode. Enabled by default.
    Use `--no-filename` to disable.

## Layout Options

- **-C** _C_\[,_R_\], **--pane**=_C_\[,_R_\]

    Set the number of columns (panes), and the number of rows when it is
    given after a comma.  For example, `-C2` creates 2 columns, and
    `-C2,3` creates 2 columns and 3 rows.

- **-R** _N_, **--row**=_N_

    Set the number of rows.
    This option is kept for compatibility and may be removed in the
    future.

- **-G** _CxR_, **--grid**=_CxR_

    Set grid layout.  `-G2x3` is equivalent to `-C2,3`.
    This option is kept for compatibility and may be removed in the
    future.

- **-P** _N_, **--page**=_N_

    Set the page height in lines.

- **-S** _N_, **--pane-width**=_N_

    Set the pane width in characters. Default is 85.

## Style Options

- **--bs**=_STYLE_, **--border-style**=_STYLE_

    Set the border style. Default is `heavy-box`.

- **--ls**=_STYLE_, **--line-style**=_STYLE_

    Set the line style. Available: `none`, `truncate`, `wrap`, `wordwrap`.

- **--runin**=_N_, **--runout**=_N_, **--runlen**=_N_

    Set the run-in and run-out widths that [ansicolumn](https://metacpan.org/pod/ansicolumn) uses for line
    breaking (kinsoku) when it folds long lines.  `--runlen` sets both.
    They are given to ansicolumn after the values in `~/.ansicolumnrc`,
    so they take precedence.  Without them, ansicolumn uses the values in
    `~/.ansicolumnrc`, or 2.

- **--boundary**=`word`|`space`|`none`

    Set where [ansicolumn](https://metacpan.org/pod/ansicolumn) may break a line when it folds long lines, as
    its `--boundary` option: `word` does not break inside an
    alphanumeric word, `space` not inside a sequence of non-space
    characters, and `none` breaks anywhere.  Like `--runin`, it is
    given to ansicolumn after `~/.ansicolumnrc`.  Without it, ansicolumn
    uses the value in the rc file, or `word` in document mode.

- **--cm**=_SPEC_, **--colormap**=_SPEC_

    Set color mapping. Specify as `LABEL=COLOR` (e.g., `--cm=BORDER=R`).
    Available labels: `TEXT`, `BORDER`.

- **--**\[**no-**\]**page-number**

    Show page number on the bottom border of each column.  Enabled by
    default.  Use `--no-page-number` to disable.

- **--white-board**, **--black-board**, **--green-board**, **--slate-board**

    Predefined color schemes for board-style display.

## Text Conversion

- **--textconv**\[=_EXT,..._\]

    Enable text conversion for non-text files using
    [App::optex::textconv](https://metacpan.org/pod/App%3A%3Aoptex%3A%3Atextconv).  When any of the specified file extensions
    are found in the arguments, the `textconv` module is loaded to
    convert them to text before display.

    Default extensions:
    `pdf,docx,docm,pptx,pptm,xlsx,xlsm,jpg,jpeg`.

    Use `--textconv=none` to disable.

## Pager Options

- **--pager**=_COMMAND_

    Set the pager command. Default is `NUP_PAGER` or `less -F +Gg`.
    When page mode is active, `NUP_PAGE_PAGER` takes precedence over
    `NUP_PAGER`.
    Viewing multiple files (or `-V` parallel view) produces parallel
    layout which has no page structure, so `nup` disables page mode
    and `NUP_PAGE_PAGER` is not used there.
    The `PAGER` variable is not used to avoid an infinite loop when
    `PAGER` is set to `nup`.
    `+Gg` makes `less` read all input before displaying, so that `-F`
    and the percentage work; `--file-size` of `less` 590 and later does
    the same, but the `less` 581 of macOS does not have it, so `+Gg`
    is the default.  Set `NUP_PAGER` to use it:

        export NUP_PAGER="less --file-size"

    Use `--pager=` (empty) or `--no-pager` to disable pager.

- **--no-pager**

    Disable pager.

## PDF Output

- **-T** _DEVICE_, **--device**=_DEVICE_

    Set the device to show the output on.  The default is `tty`, the
    terminal.  Any other device is a paper, and the output is printed to
    PDF by `ansi2pdf`, instead of being shown on the terminal.

    The name of a paper is the one for the `-p` option of `ansi2pdf`,
    such as `a4`, `a3`, `b5` or `letter`.  A paper is used in
    landscape orientation.  The letter `p` or `l` after the name gives
    the orientation: `a4p` is A4 in portrait, and `a4l` is A4 in
    landscape.  The device `pdf` is the default paper of `ansi2pdf`, A4.

        nup -T a4 man nup > nup.pdf     # A4, landscape
        nup -T a4p -C1 man nup | lpr    # A4, portrait

    A sheet of paper takes the place of the terminal, and `ansi2pdf`
    takes the place of the pager.  The size of a sheet in columns and
    lines is asked to `ansi2pdf`, the output is formatted for that size
    in the same way as for a terminal, and each screen is printed on a
    sheet as it is.  The default is a landscape A4 sheet of 60 lines,
    which has room for two panes of the default width.

- **-o** _FILE_, **--output**=_FILE_

    Write the output to _FILE_.  When the name ends with `.pdf`, the
    output is PDF without `-T` as well.

        nup -o nup.pdf man nup          # A4, landscape
        nup -T a3 -o nup.pdf man nup    # A3, landscape

    Otherwise, what is shown on the terminal is written to the file as it
    is, with the ANSI sequences and in the size of the terminal, and the
    pager is not used.  `-T tty` does so for a name ending with `.pdf`
    as well.

        nup -o nup.txt man nup          # the same as --no-pager > nup.txt

- **--geometry**

    Print the size of the device in columns and lines and its kind,
    `tty` or `pdf`, and exit.  No file is read and no command is run.

        $ nup -T a4p --geometry
        100 60 pdf
        $ nup -o nup.pdf -P 80 --geometry
        275 80 pdf

    For a paper, the size is that of a sheet, which follows `-T`, `-o`,
    `-P`, the number of rows, `--pdf-opts` and `-w` of `ansicolumn`
    given after the file names.  For the terminal, it is the size of the
    terminal.  This is for a program that formats text before giving it
    to `nup`, as [mdee(1)](https://metacpan.org/pod/App%3A%3Amdee) does.

- **--pdf-opts**=_OPTIONS_

    Give other options to `ansi2pdf`, such as the number of lines on a
    sheet, the margin and the fonts.  They are given after the paper, so
    they take precedence.

        nup -o nup.pdf --pdf-opts='-l 80 -m 15' man nup

The `-P` option sets the number of lines of a page for PDF as well:
a sheet has that many lines for each row.  The `-w` option of
`ansicolumn`, given after the files or the command, sets the number
of columns of a sheet.  The font size follows them, and the one that
is not given is decided to fill the sheet.  With neither of them, a
sheet has 60 lines.

    nup -o nup.pdf -P 80 man nup         # 80 lines on a sheet
    nup -o nup.pdf -C2,2 -P 40 man nup   # 2x2 pages of 40 lines
    nup -o nup.pdf -C3 file -w 300       # 300 columns on a sheet

## Terminal Size

The terminal size is taken from the controlling terminal
(`/dev/tty`).  When it is not available, as when `nup` is run
without a terminal, the `COLUMNS` environment variable gives the
width (default 80), and `LINES` gives the height (default 24) used
to split the screen when the number of rows is set, as in `-C2,2`:

    COLUMNS=170 nup -C2 file1.txt file2.txt

## Less Environment Variables

`nup` sets the following environment variables when they are not
already defined, to ensure proper display with `less`:

- `LESS`

    Default: `-R`.  Required for ANSI color sequences.

- `LESSANSIENDCHARS`

    Default: `mK`.  Recognizes SGR (`m`) and erase line (`K`)
    sequences.

# EXAMPLES

Typical n-up usage:

    nup man nup                # view manual in n-up layout
    nup -C2 man perl           # 2 columns
    nup -C2,2 man perl         # 2x2 grid (4-up layout)
    nup -F man perl            # no pagination
    nup file1.txt file2.txt    # view files side by side
    nup -C2 a.txt b.txt -w 170 # 2 columns, width 170 (ansicolumn -w)
    nup -e ./script.sh         # force command mode for a file
    nup -o nup.pdf man nup     # print to PDF (requires ansi2pdf)
    nup -T a4p -C1 file | lpr  # print on A4 in portrait

Using `nup` as a `MANPAGER`:

    export MANPAGER="nup -A"

# INSTALLATION

## Homebrew

Use [tecolicom/tap](https://github.com/tecolicom/homebrew-tap):

    brew tap tecolicom/tap
    brew install app-nup

## CPAN

Using [cpanminus](https://metacpan.org/pod/App::cpanminus):

    cpanm -n App::nup

# DIAGNOSTICS

Both stdout and stderr of the command are merged and passed through
the n-up output filter.  Error messages will appear in the paged output.

# EXIT STATUS

The exit status of the executed command is not preserved because
the output is passed through a filter pipeline.

# SEE ALSO

[App::optex::up](https://metacpan.org/pod/App%3A%3Aoptex%3A%3Aup) (bundled), [optex](https://metacpan.org/pod/optex)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2025-2026 Kazumasa Utashiro.

This software is released under the MIT License.
[https://opensource.org/licenses/MIT](https://opensource.org/licenses/MIT)
