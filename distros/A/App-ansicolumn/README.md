[![Actions Status](https://github.com/tecolicom/App-ansicolumn/workflows/test/badge.svg)](https://github.com/tecolicom/App-ansicolumn/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-ansicolumn.svg)](https://metacpan.org/release/App-ansicolumn)
# NAME

ansicolumn - ANSI terminal sequence aware column command

# SYNOPSIS

ansicolumn \[options\] \[file ...\]

    -w#, -c#             output width
    -s#                  separator string
    -t                   table style output
    -l#                  maximum number of table columns
    -x                   exchange rows and columns
    -o#                  output separator
    -R#                  right adjust table columns

    -P[#], --page=#      page mode, with optional page length
    -U[#], --up=#        show in N-up format (-WC# --linestyle=wrap)
    --2up .. --9up       same as -U2 .. -U9
    -D, --document       document mode
    -V, --parallel       parallel view mode
    -C#, --pane=#        number of panes
    -S#, --pane-width=#  pane width
    -W, --widen          widen to terminal width
    -p, --paragraph      paragraph mode

    -B, --border[=#]     print border with optional style
    -F, --fillup[=#]     fill-up unit (pane|page|none)

    --height=#           page height
    --column-unit=#      column unit (default 8)
    --margin=#           column margin width (default 1)
    --linestyle=#        folding style (none|truncate|wrap|wordwrap)
    --boundary=#         line-end boundary
    --linebreak=#        line-break mode (none|all|runin|runout)
    --runin=#            run-in width
    --runout=#           run-out width
    --run=#              set both run-in and run-out width
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

# VERSION

Version 1.2801

# DESCRIPTION

**ansicolumn** is a [column(1)](http://man.he.net/man1/column) command clone which can handle ANSI
terminal sequences.  It supports traditional options and some of Linux
extended, and many other original options.  Empty lines are **not**
ignored, though.

In contrast to the original [column(1)](http://man.he.net/man1/column) command which handles mainly
short item list, and Linux variant which has been expanded to have
ritch table style output, **ansicolumn(1)** has been expanded to show
text file in multi-column view.  Combined with pagenation and
document-friendly folding mechanism, it can be used as a document
viewing preprocessor for pager program.

When multiple files are given as arguments, it gets in the parallel
view mode, and show all files in parallel.  It's convenient to see
multiple files side-by-side.

## COMPATIBLE OPTIONS

The column utility formats its input into multiple columns.  Rows are
filled before columns.  Input is taken from _file_ operands, or, by
default, from the standard input.

- **-w**#, **-c**#, **--width**=#, **--output-width**=#

    Output is formatted for a display columns wide.  See ["CALCULATION"](#calculation)
    section.

    Accept **-c** for compatibility, but **-w** is more popular.

- **-s**#, **--separator**=#

    Specify a set of characters to be used to delimit columns for the
    \-t option.

- **-t**, **--table**

    Determine the number of columns the input contains and create a
    table.  Columns are delimited with whitespace, by default, or
    with the characters supplied using the -s option.  Useful for
    pretty-printing displays.

- **-l**#, **--table-columns-limit**=#

    Specify maximal number of the input columns.  The last column will
    contain all remaining line data if the limit is smaller than the
    number of the columns in the input data.

- **-x**, **--fillrows**

    Fill columns before filling rows.

- **-o**#, **--output-separator**=#

    When used **--table** or **-t** option, each column are joined by two
    space characters (' ') by default.  This option will change it.

- **-R**#, **--table-right**=#

    Right align text in these columns.
    Support only numbers.

## EXTENDED OPTIONS

- **-P**\[#\], **--page**\[=#\]

    Page mode.  Set these options.

        --height=# or 1-
        --linestyle=wrap
        --border
        --fillup

    If optional number is given, it is used as a page height unless option
    **--height** exists.  Otherwise page height is set to terminal height
    minus one.

- **-U**#, **--up**=#, **--2up** .. **--9up**

    Show in N-up format.  Almost same as **-P** but does not set page
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
    specified.  Use **--no-parallel** to disable.

    Set these options, and cancel all pagenation behavior.

        --widen
        --linestyle=wrap
        --border

    By default, all files are displayed in parallel.  In other words,
    number of pane is set as a number of files.  You can use **-C** option
    to specify number of files displayed simultaneously.

    You can use this option mixed with **-D** option to see document files.

    If you want to show multiple parts in single data stream in parallel,
    use **--pages** option.  It split the data by formfeed character and
    treat each part as a individual file.

- **-C**#, **--pane**=#

    Output is formatted in the specified number of panes.  Setting number
    of panes implies **--widen** option enabled.  See ["CALCULATION"](#calculation)
    section.

- **-S**#, **--pane-width**=#, **--pw**=#

    Specify the span of each pane.  This includes border spaces.  See
    ["CALCULATION"](#calculation) section.

- **-W**, **--widen**

    Use full width of the terminal.  Each pane is expanded to fill
    terminal width, unless **--pane-width** is specified.

- **-p**, **--paragraph**

    Insert empty line between every successive non-empty lines.

- **-B**, **--border**\[=_style_\]

    Print border.  Enabled by **--page** option automatically.  If the
    optional _style_ is given, it is used as a border style and precedes
    to **--border-style** option.  Use **--border=none** to disable it.

    Border style is specified by **--border-style** option.

- **-F**, **--fillup**\[=`pane`|`page`|`none`\]

    Fill up final pane or page by empty lines.  Parameter is optional and
    considered as 'pane' by default.  Set by **--page** option
    automatically.  Use **--fillup=none** if you want to explicitly disable
    it.

    Option **-F** is a shortcut for **--fillup=pane**.

- **--height**=#

    Set page height and page mode on.  See ["CALCULATION"](#calculation) section.

- **--column-unit**=#, **--cu**=#

    Each column is placed at the unit of 8 by default.  This option
    changes the number of the unit.

- **--margin**=#

    Each column has at least single character margin on the right side so
    that they are not placed back-to-back.  This option specifies the
    margin width.

- **--linestyle**=`none`|`truncate`|`wrap`|`wordwrap`, **--ls**=`...`

    Set the style of treatment for longer lines.
    Default is `none`.

    Option **--linestyle=wordrap** sets **--linestyle=wrap** and
    **--boundary=word** at once.

- **--boundary**=`none`|`word`|`space`

    Set text wrap boundary.  If set as `word` or `space`, text is not
    wrapped in the middle of alphanumeric word or non-space sequence.
    Option **--document** set this as `word`.  See [Text::ANSI::Fold](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AFold) for
    detail.

- **--linebreak**=`none`|`all`|`runin`|`runout`, **--lb**=...

    Set the linebreak mode.

- **--runin**=#, **--runout**=#, **--run**=#

    Set the number of runin/runout column.  **--run** set both.
    Default is both 2.

    As for Japanese text, only one character can be moved with default
    value.  Longer value allows more flexible arrangement, but makes text
    area shorter.  Author is using the command with own `~/.ansicolumnrc`
    like this:

        option default --runin=4 --runout=4

- **--**\[**no-**\]**pagebreak**

    Move to next pane when form feed character found.
    Default true.

- **--border-style**=_style_, **--bs**=...

    Set the border style.  Current default style is `box`, which enclose
    each pane with box drawing graphic characters.  Special style
    `random` choose random style.

    Sample styles:
    none,
    space,
    vbar, heavy-vbar, fat-vbar,
    line, heavy-line,
    stick, heavy-stick,
    ascii-frame,
    ascii-box,
    c-box,
    box, heavy-box, fat-box, very-fat-box,
    dash-box, heavy-dash-box,
    round-box,
    frame, heavy-frame, fat-frame, very-fat-frame,
    dash-frame, heavy-dash-frame,
    page-frame, heavy-page-frame,
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

    When used **-t** option, leading spaces are ignored by default.  Use
    **--no-ignore-space** option to disable it.

- **--**\[**no-**\]**white-space**

    Allow white spaces at the top of each pane, or clean them up.  Default
    true.  Negated by **--document** option.

- **--**\[**no-**\]**isolation**

    Allow the first line of a paragraph (continuous non-space lines) is
    placed at the bottom of a pane.  Default true.  If false, move it to
    the top of next pane.  Negated by **--document** option.

- **--tabstop**=#

    Set tab width.

- **--tabhead**=#
- **--tabspace**=#

    Set head and following space characters.  Both are space by default.
    If the option value is longer than single characger, it is evaluated
    as unicode name.

- **--tabstyle**=#

    Set the style how tab is expanded.  Select from `dot`, `symbol` or
    `shade`.  Styles are defined in [Text::ANSI::Fold](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AFold) library.

- **--ambiguous**=`wide`|`narrow`

    Specifies how to treat Unicode ambiguous width characters.  Take a
    value of 'narrow' or 'wide.  Default is 'narrow'.

- **--pages**

    Split file content by formfeed character, and treat each part as a
    individual file.  Use with **--parallel** option.

# CALCULATION

As for **--height**, **--width**, **--pane** and **--pane-width** options,
besides giving numeric digits, you can calculate the number using
terminal size.  If the expression contains non-digit character, it is
evaluated as an RPN (Reverse Polish Notation) with the terminal size
pushed on the stack.  Initial value for **--height** options is
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

file is read at start up time.  If you want use **--no-white-space**
always, put this line in your `~/.ansicolumnrc`.

    option default --no-white-space

Also command can be extended by original modules with **-M**
option. See \`perldoc Getopt::EX\` for detail.

# INSTALL

## CPANMINUS

    $ cpanm App::ansicolumn

To get the latest code, use this:

    $ cpanm https://github.com/tecolicom/App-ansicolumn.git

# EXAMPLES

[https://github.com/tecolicom/App-ansicolumn/tree/master/images](https://github.com/tecolicom/App-ansicolumn/tree/master/images)

# SEE ALSO

[column(1)](http://man.he.net/man1/column),
[https://man7.org/linux/man-pages/man1/column.1.html](https://man7.org/linux/man-pages/man1/column.1.html)

[App::ansicolumn](https://metacpan.org/pod/App%3A%3Aansicolumn),
[https://github.com/tecolicom/App-ansicolumn](https://github.com/tecolicom/App-ansicolumn)

[Text::ANSI::Printf](https://metacpan.org/pod/Text%3A%3AANSI%3A%3APrintf),
[https://github.com/kaz-utashiro/Text-ANSI-Printf](https://github.com/kaz-utashiro/Text-ANSI-Printf)

## Articles

- https://qiita.com/kaz-utashiro/items/345cd9abcd8e1f0d81a2
- https://qiita.com/kaz-utashiro/items/1cdd71d44eb11f3fb36e
- https://qiita.com/kaz-utashiro/items/32e1c2d4c42a80c42422

# AUTHOR

Kazumasa Utashiro

# LICENSE

©︎ 2020-2022 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
