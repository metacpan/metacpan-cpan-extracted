[![Actions Status](https://github.com/tecolicom/App-ansicolumn/workflows/test/badge.svg)](https://github.com/tecolicom/App-ansicolumn/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-ansicolumn.svg)](https://metacpan.org/release/App-ansicolumn)
# NAME

ansicolumn - ANSI terminal sequence aware column command

# SYNOPSIS

ansicolumn \[options\] \[file ...\]

    -w#, -c#             output width
    -s#                  separator string
    -l#                  maximum number of table columns
    -x                   exchange rows and columns
    -o#                  output separator

    -P[#], --page=#      page mode, with optional page length
    -U[#], --up=#        show in N-up format (-WC# --linestyle=wrap)
    --2up .. --9up       same as -U2 .. -U9
    -D,  --document      document mode
    -V,  --parallel      parallel view mode
    -H,  --filename      print filename header in parallel view mode
    -X#, --cell=#        set text width for files in parallel view mode
    -C#, --pane=#        number of panes
    -S#, --pane-width=#  pane width
    -W,  --widen         widen to terminal width
    -p,  --paragraph     paragraph mode
    -r,  --regex-sep     treat separator string as regex

    -B,  --border[=#]    print border with optional style
    -F, --fillup[=#]     fill-up unit (pane|page|none)

    --height=#           page height
    --column-unit=#      column unit (default 8)
    --margin=#           column margin width (default 1)
    --linestyle=#        folding style (none|truncate|wrap|wordwrap)
    --boundary=#         line-end boundary
    --linebreak=#        line-break mode (none|all|runin|runout)
    --runin=#            run-in width
    --runout=#           run-out width
    --runlen=#           set both run-in and run-out width
    --[no-]pagebreak     allow page break
    --border-style=#     border style
    --[no-]ignore-space  ignore space in table output
    --[no-]white-space   allow white spaces at the top of each pane
    --[no-]isolation     page-end line isolation
    --tabstop=#          tab-stop character
    --tabhead=#          tab-head character
    --tabspace=#         tab-space width
    --tabstyle=#         tab style
    --ambiguous=#        ambiguous character width (narrow|wide)
    --pages              split file by formfeed

Table style options:

    -t, --table          table style output
    -A, --table-align    align table output to column unit
    -T, --table-tabs     align items by tabs
    -R#, --table-right=# right adjust table columns

Default alias options:

    --board-color FG BG  board style pages with FG and BG colors
    --white-board        black on white board
    --black-board        white on black board
    --green-board        white on green board
    --slate-board        white on dark slategray board

# VERSION

Version 1.4101

# DESCRIPTION

**ansicolumn** is a [column(1)](http://man.he.net/man1/column) command clone which can handle ANSI
terminal sequences, backspaces, and Asian wide characters.  It
supports traditional options and some of Linux extended, and many
other original options.

<div>
    <p><img width="750" src="https://raw.githubusercontent.com/tecolicom/App-ansicolumn/master/images/ac-grep.png">
</div>

In addition to normal operation, table style output (`-t`) is
supported as well.

<div>
    <p><img width="750" src="https://raw.githubusercontent.com/tecolicom/App-ansicolumn/master/images/ac-table.png">
</div>

In contrast to the original [column(1)](http://man.he.net/man1/column) command which handles mainly
short item list, and Linux variant which has been expanded to have
ritch table style output, **ansicolumn(1)** has been expanded to show
text file in multi-column view.  Combined with pagenation and
document-friendly folding mechanism, it can be used as a document
viewing preprocessor for pager program.

<div>
    <p><img width="750" src="https://raw.githubusercontent.com/tecolicom/App-ansicolumn/master/images/ac-man.png">
</div>

In order to accurately display the contents of the file, blank lines
that were ignored by the original [column(1)](http://man.he.net/man1/column) command are not
ignored.

When multiple files are given as arguments, it gets in the parallel
view mode, and show all files in parallel.  It's convenient to see
multiple files side-by-side.

<div>
    <p><img width="750" src="https://raw.githubusercontent.com/tecolicom/App-ansicolumn/master/images/ac-cell.png">
</div>

## COMPATIBLE OPTIONS

The column utility formats its input into multiple columns.  Rows are
filled before columns.  Input is taken from _file_ operands, or, by
default, from the standard input.

- **-w**#, **-c**#, **--width**=#, **--output-width**=#

    Output is formatted for a display columns wide.  See ["CALCULATION"](#calculation)
    section.

    Accept `-c` for compatibility, but `-w` is more popular.

- **-s**#, **--separator**=#

    Specify a set of characters to be used to delimit columns for the -t
    option.  When used with `--regex-sep` or `-r` option, it is used as
    regex rather than character set.

- **-t**, **--table**

    Determine the number of columns the input contains and create a
    table.  Columns are delimited with whitespace, by default, or
    with the characters supplied using the -s option.  Useful for
    pretty-printing displays.

    Unlike original [column(1)](http://man.he.net/man1/column) command, empty field is not ignored.

- **-l**#, **--table-columns-limit**=#

    Specify maximal number of the input columns.  The last column will
    contain all remaining line data if the limit is smaller than the
    number of the columns in the input data.

- **-x**, **--fillrows**

    Fill columns before filling rows.

- **-o**#, **--output-separator**=#

    When used `--table` or `-t` option, each column are joined by two
    space characters (' ') by default.  This option will change it.

- **-R**#, **--table-right**=#

    Right align text in these columns.  Multiple columns are separated by
    commas.  Support only numbers.

    Parameters are parsed by the [Getopt::EX::Numbers](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3ANumbers) module, so you can
    specify a range of numbers, as in `-R2:5` which is equivalent to
    `-R2,3,4,5`. Option `-R:` makes all fields right-aligned.

## EXTENDED OPTIONS

- **-P**\[#\], **--page**\[=#\]

    Page mode.  Set these options.

        --height=# or 1-
        --linestyle=wrap
        --border
        --fillup

    If optional number is given, it is used as a page height unless option
    `--height` exists.  Otherwise page height is set to terminal height
    minus one.

- **-U**#, **--up**=#, **--2up** .. **--9up**

    Show in N-up format.  Almost same as `-P` but does not set page
    height.  This is convenient when you want multi-column output without
    page control.

- **-D**, **--document**

    Document mode.  Set these options.

        --widen
        --linebreak=all
        --linestyle=wrap
        --boundary=word
        --no-white-space
        --no-isolation

    Next command display DOCX text in 3-up format using
    [App::optex::textconv](https://metacpan.org/pod/App%3A%3Aoptex%3A%3Atextconv).

        optex -Mtextconv ansicolumn -DPC3 foo.docx | less

- **-V**, **--**\[**no-**\]**parallel**

    Parallel view mode.  Implicitly enabled when multiple files are
    specified.  Use `--no-parallel` to disable.

    Set these options, and cancel all pagenation behavior.

        --widen
        --linestyle=wrap
        --border

    By default, all files are displayed in parallel.  In other words,
    number of pane is set as a number of files.  You can use `-C` option
    to specify number of files displayed simultaneously.

    You can use this option mixed with `-D` option to see document files.

    If you want to display multiple parts in a single stream in parallel,
    use the `--pages` option. It will split the data by form feed
    characters and treat each part as a separate file.

- **-H**, **--filename**
- **--filename-format**=_format_ (DEFAULT: `: %s`)

    Print filename header before contents.  Currently, this option is
    effective only in `--parallel` mode.  Filename is truncated in each
    pane width.

    This option is convenient to look over many small files at once.

        ansicolumn -VHC1 *.txt | less

    Filename is printed in a format given by `--filename-format` option.
    Default is `: %s` so that making easy to move to next file by `^:`
    pattern search.

- **-X**#, **--cell**=#

    Sets the display width of each file.  This option is only valid with
    parallel view mode.  For example, if you are displaying three files
    and want the first file to be displayed in 80 columns and the
    remaining files in 40 columns, specify like this:

        --cell 80,40,40

    This is the same as

        --cell 80,40

    since the last value specified is repeated.

    You can also specify values relative to the default width.  For
    example, to display the first column 20 columns more and the remaining
    columns 10 columns less, use

        --cell +20,-10

    To return to the default display width for the fourth and subsequent
    files, use

        --cell +20,-10,-10,+0

    If `=` is specified as the value, it is set to the width of the
    longest line in the file.

        -X=

    Then all specified files will be displayed with the width of the
    longest line they contain. `=` may be followed by a maximum value.

        -X=80

    will set the cell width to length of the longest line if it is less
    than 80, or 80 if it is greater than 80.  `<` may be used instead
    of `=`.

        -X'<80'

    The correspondence between file and display width remains the same 
    even when the number of columns to be displayed simultaneously is 
    specified with the `-C` option.

- **-C**#, **--pane**=#

    Output is formatted in the specified number of panes.  Setting number
    of panes implies `--widen` option enabled.  See ["CALCULATION"](#calculation)
    section.

- **-S**#, **--pane-width**=#, **--pw**=#

    Specify the span of each pane.  This includes border spaces.  See
    ["CALCULATION"](#calculation) section.

- **-W**, **--widen**

    Use full width of the terminal.  Each pane is expanded to fill
    terminal width, unless `--pane-width` is specified.

- **-p**, **--paragraph**

    Insert empty line between every successive non-empty lines.

- **-B**, **--border**\[=_style_\] (DEFAULT: `box`)

    Print border.  Enabled by `--page` option automatically.  If the
    optional _style_ is given, it is used as a border style and precedes
    to `--border-style` option.  Use `--border=none` to disable it.

    Border style is specified by `--border-style` option.

- **-F**, **--fillup**\[=`pane`|`page`|`none`\]

    Fill up final pane or page by empty lines.  Parameter is optional and
    considered as 'pane' by default.  Set by `--page` option
    automatically.  Use `--fillup=none` if you want to explicitly disable
    it.

    Option `-F` is a shortcut for `--fillup=pane`.

- **--fillup-str**=_string_

    Set string used for filling up space.  Default is empty.

    Use `--fillup-str='~'` to fill up the area after EOF by `~`
    character like [vi(1)](http://man.he.net/man1/vi) or [more(1)](http://man.he.net/man1/more).

- **--height**=#

    Set page height and page mode on.  See ["CALCULATION"](#calculation) section.

- **--column-unit**=#, **--cu**=# (DEFAULT: 8)

    Each column is placed at the unit of 8 by default.  This option
    changes the number of the unit.

- **--margin**=#

    Each column has at least single character margin on the right side so
    that they are not placed back-to-back.  This option specifies the
    margin width.

- **-A**, **--table-align**

    Align each field in the table output to column-unit.  If this option
    is specified, **--output-separator** option is ignored.
    Implicitly enable the **--table** option.

- **-T**, **--table-tabs**

    If this option is specified with **--table-align**, tabs are used for
    spaces between items.  The width of tabs uses the value of
    **--column-unit**.  Implicitly enable the **--table** and
    **--table-align** option.  Option **--table-right** does not take
    effect.

- **--linestyle**=`none`|`truncate`|`wrap`|`wordwrap`, **--ls**=`...`

    Set the style of treatment for longer lines.
    Default is `none`.

    Option `--linestyle=wordrap` sets `--linestyle=wrap` and
    `--boundary=word` at once.

- **--boundary**=`none`|`word`|`space`

    Set text wrap boundary.  If set as `word` or `space`, text is not
    wrapped in the middle of alphanumeric word or non-space sequence.
    Option `--document` set this as `word`.  See [Text::ANSI::Fold](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AFold) for
    detail.

- **--linebreak**=`none`|`all`|`runin`|`runout`, **--lb**=...

    Set the linebreak mode.

- **--runin**=#, **--runout**=#, **--runlen**=#

    Set the number of runin/runout column.  `--runlen` set both.
    Default is both 2.

    As for Japanese text, only one character can be moved with default
    value.  Longer value allows more flexible arrangement, but makes text
    area shorter.  Author is using the command with own `~/.ansicolumnrc`
    like this:

        option default --runin=4 --runout=4

- **--**\[**no-**\]**pagebreak**

    Move to next pane when form feed character found.
    Default true.

- **-r**, **--regex-sep**

    Treat separator option as a regex pattern.  Next example specifies a
    space character just before `(` as a separator.

        gem list | ansicolumn -trs ' (?=\()'

- **--border-style**=_style_, **--bs**=...

    Set the border style.  Current default style is `box`, which enclose
    each pane with box drawing graphic characters.  Special style
    `random` choose random style.

    Sample styles:
    none,
    space,
    vbar, heavy-vbar, fat-vbar,
    line, heavy-line,
    hline, heavy-hline,
    bottom-line, heavy-bottom-line,
    stick, heavy-stick,
    ascii-frame,
    ascii-box,
    c-box,
    box, heavy-box, fat-box, very-fat-box,
    dash-box, heavy-dash-box, fat-dash-box,
    round-box,
    inner-box, outer-box,
    frame, heavy-frame, fat-frame, very-fat-frame,
    dash-frame, heavy-dash-frame, fat-dash-frame,
    page-frame, heavy-page-frame,
    zebra-frame,
    checker-box, checker-frame,
    shadow, shin-shadow,
    shadow-box, shin-shadow-box, heavy-shadow-box,
    comb, heavy-comb,
    rake, heavy-rake,
    mesh, heavy-mesh,
    dumbbell, heavy-dumbbell,
    ribbon, heavy-ribbon,
    round-ribbon,
    double-ribbon,
    etc.

    These are experimental and subject to change, and this document is not
    always up-to-date.  See \`perldoc -m App::ansicolumn::Border\` for
    actual data.

    You can define your own style in module or startup file.  Put next
    lines in your `$HOME/.ansicolumnrc` file, for example.

        option default --border-style myheart
        __PERL__
        App::ansicolumn::Border->add_style(
            myheart  => {
            left   => [ "\N{WHITE HEART SUIT} ", "\N{BLACK HEART SUIT} " ],
            center => [ "\N{WHITE HEART SUIT} ", "\N{BLACK HEART SUIT} " ],
            right  => [ "\N{WHITE HEART SUIT}" , "\N{BLACK HEART SUIT}"  ],
        },
        );

- **--**\[**no-**\]**ignore-space**, **--**\[**no-**\]**is**

    When used `-t` option, leading spaces are ignored by default.  Use
    `--no-ignore-space` option to disable it.

- **--**\[**no-**\]**white-space**

    Allow white spaces at the top of each pane, or clean them up.  Default
    true.  Negated by `--document` option.

- **--**\[**no-**\]**isolation**

    Allow the first line of a paragraph (continuous non-space lines) is
    placed at the bottom of a pane.  Default true.  If false, move it to
    the top of next pane.  Negated by `--document` option.

- **--tabstop**=# (DEFAULT: 8)

    Set tab width.

- **--tabhead**=#
- **--tabspace**=#

    Set head and following space characters.  Both are space by default.
    If the option value is longer than single characger, it is evaluated
    as unicode name.

- **--tabstyle**, **--ts**
- **--tabstyle**=_style_, **--ts**=...
- **--tabstyle**=_head-style_,_space-style_ **--ts**=...

    Set the style how tab is expanded.  Select `symbol` or `shade` for
    example.  If two style names are combined, like
    `squat-arrow,middle-dot`, use `squat-arrow` for tabhead and
    `middle-dot` for tabspace.

    Show available style list if called without parameter.  Styles are
    defined in [Text::ANSI::Fold](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AFold) library.

- **--ambiguous**=`wide`|`narrow` (DEFAULT: `narrow`)

    Specifies how to treat Unicode ambiguous width characters.  Take a
    value of 'narrow' or 'wide.  Default is 'narrow'.

- **--pages**

    Split file content by formfeed character, and treat each part as a
    individual file.  Use with `--parallel` option.

# DEFAULT ALISES

The following options are defined in `App::ansicolumn::default.pm`.

- **--board-color** _fg-color_ _bg-color_

    This option is defined as follows:

        option --board-color \
               --bs=inner-box \
               --cm=BORDER=$<2>,TEXT=$<shift>/$<shift>

    The resulting text is displayed in an _fg-color_ font on an
    _bg-color_ panel.

- **--white-board**
- **--black-board**
- **--green-board**
- **--slate-board**

    Use the `--board-color` option to display text on the white, black,
    green or darkslate panels.

# CALCULATION

As for `--height`, `--width`, `--pane`, `--up` and `--pane-width`
options, besides giving numeric digits, you can calculate the number
using terminal size.  If the expression contains non-digit character,
it is evaluated as an RPN (Reverse Polish Notation) with the terminal
size pushed on the stack.  Initial value for `--height` options is
terminal height, and terminal width for others.

    OPTION              VALUE
    =================   =========================
    --height 1-         height - 1
    --height 2/         height / 2
    --height 1-2/       (height - 1) / 2
    --height dup2%-2/   (height - height % 2) / 2

Space and comma characters are ignored in the expression.  So `1-2/`
and `1 - 2 /` and `1,-,2,/` are all same.  See \`perldoc
Math::RPN\` for the expression detail.

Next example select number of panes by dividing terminal width by 85:

    ansicolumn --pane 85/

If you consider the case the terminal width is less than 85:

    ansicolumn --pane 85/,DUP,1,GE,EXCH,1,IF

This RPN means `$height/85 >= 1 ? $height/85 : 1`.

# STARTUP

This command is implemented with [Getopt::EX](https://metacpan.org/pod/Getopt%3A%3AEX) module.  So

    ~/.ansicolumnrc

file is read at start up time.  If you want use `--no-white-space`
always, put this line in your `~/.ansicolumnrc`.

    option default --no-white-space

Also command can be extended by original modules with `-M`
option. See \`perldoc Getopt::EX\` for detail.

# INSTALL

## CPANMINUS

    $ cpanm App::ansicolumn

To get the latest code, use this:

    $ cpanm https://github.com/tecolicom/App-ansicolumn.git

# EXAMPLES

[https://github.com/tecolicom/App-ansicolumn/tree/master/images](https://github.com/tecolicom/App-ansicolumn/tree/master/images)

# SEE ALSO

[https://github.com/tecolicom/ANSI-Tools](https://github.com/tecolicom/ANSI-Tools)

[column(1)](http://man.he.net/man1/column),
[https://man7.org/linux/man-pages/man1/column.1.html](https://man7.org/linux/man-pages/man1/column.1.html)

[App::ansicolumn](https://metacpan.org/pod/App%3A%3Aansicolumn),
[https://github.com/tecolicom/App-ansicolumn](https://github.com/tecolicom/App-ansicolumn)

[Text::ANSI::Printf](https://metacpan.org/pod/Text%3A%3AANSI%3A%3APrintf),
[https://github.com/tecolicom/Text-ANSI-Printf](https://github.com/tecolicom/Text-ANSI-Printf)

## Articles (in Japanese)

- [https://qiita.com/kaz-utashiro/items/345cd9abcd8e1f0d81a2](https://qiita.com/kaz-utashiro/items/345cd9abcd8e1f0d81a2)
- [https://qiita.com/kaz-utashiro/items/1cdd71d44eb11f3fb36e](https://qiita.com/kaz-utashiro/items/1cdd71d44eb11f3fb36e)
- [https://qiita.com/kaz-utashiro/items/32e1c2d4c42a80c42422](https://qiita.com/kaz-utashiro/items/32e1c2d4c42a80c42422)
- [https://qiita.com/kaz-utashiro/items/a347628da09638e633ed](https://qiita.com/kaz-utashiro/items/a347628da09638e633ed)

# RELATED WORKS

[https://github.com/LukeSavefrogs/column\_ansi](https://github.com/LukeSavefrogs/column_ansi)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright © 2020-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
