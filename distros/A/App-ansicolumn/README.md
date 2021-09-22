[![Actions Status](https://github.com/kaz-utashiro/App-ansicolumn/workflows/test/badge.svg)](https://github.com/kaz-utashiro/App-ansicolumn/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-ansicolumn.svg)](https://metacpan.org/release/App-ansicolumn)
# NAME

ansicolumn - ANSI terminal sequence aware column command

# SYNOPSIS

ansicolumn \[options\] \[file ...\]

    -c#                  output width
    -s#                  separator string
    -t                   table style output
    -l#                  maximum number of table columns
    -x                   exchange rows and columns
    -o#                  output separator
    -R#                  right adjust table columns

    -P[#]                page mode, with optional page length
    -D                   document mode
    -C#                  number of panes
    -S#                  pane width
    -F                   full-width
    -p                   paragraph mode

    --height=#           page height
    --column-unit=#      column unit (default 8)
    --linestyle=#        folding style (none|truncate|wrap|wordwrap)
    --boundary=#         line-end boundary
    --linebreak=#        line-break mode (none|all|runin|runout)
    --runin=#            run-in width
    --runout=#           run-out width
    --[no-]pagebreak     allow page break
    --border[=#]         print border
    --border-style=#     border style
    --[no-]ignore-space  ignore space in table output
    --[no-]isolation     page-end line isolation
    --fillup=#           fill-up unit (pane|page|none)
    --tabstop=#          tab-stop character
    --tabhead=#          tab-head character
    --tabspace=#         tab-space width
    --tabstyle=#         tab style
    --ambiguous=#        ambiguous character width (narrow|wide)

# VERSION

Version 1.13

# DESCRIPTION

**ansicolumn** is a [column(1)](http://man.he.net/man1/column) command clone which can handle ANSI
terminal sequences.  It supports traditional options and some of Linux
extended, and other original options.  Empty lines are **not** ignored,
though.

## COMPATIBLE OPTIONS

The column utility formats its input into multiple columns.  Rows are
filled before columns.  Input is taken from _file_ operands, or, by
default, from the standard input.

- **-c**#, **--width**=#, **--output-width**=#

    Output is formatted for a display columns wide.  See ["CALCULATION"](#calculation)
    section.

- **-s**#, **--separator**=#

    Specify a set of characters to be used to delimit columns for the
    \-t option.

- **-t**, **--table**

    Determine the number of columns the input contains and create a
    table.  Columns are delimited with whitespace, by default, or
    with the characters supplied using the -s option.  Useful for
    pretty-printing displays.

- **-l**_#_, **--table-columns-limit** _number_

    Specify maximal number of the input columns.  The last column will
    contain all remaining line data if the limit is smaller than the
    number of the columns in the input data.

- **-x**, **--fillrows**

    Fill columns before filling rows.

- **-o**#, **--output-separator**=#

    When used **--table** or **-t** option, each columns are joined by two
    space characters (' ') by default.  This option will change it.

- **-R**_columns_, **--table-right**=_columns_

    Right align text in these columns.
    Support only numbers.

## EXTENDED OPTION

- **-P**\[_#_\], **--page**\[=_#_\]

    Page mode.  Set these options.

        --height=# or 1-
        --linestyle=wrap
        --border
        --fillup

    If optional number is given, it is used as a page height unless option
    **--height** exists.  Otherwise page height is set to terminal height
    minus one.

- **-D**, **--document**

    Document mode.  Set these options.

        --fullwidth
        --linebreak=all
        --linestyle=wrap
        --boundary=word
        --no-white-space
        --no-isolation

    Next command display DOCX text in 3-up format using
    [App::optex::textconv](https://metacpan.org/pod/App::optex::textconv).

        optex -Mtextconv ansicolumn -DPC3 foo.docx | less

- **-C**#, **--pane**=#

    Output is formatted in the specified number of panes.  Setting number
    of panes implies **--fullwidth** option enabled.

- **-S**#, **--pane-width**=#, **--pw**=#

    Specify pane width.  This includes border spaces.  See ["CALCULATION"](#calculation)
    section.

- **-F**, **--fullwidth**

    Use full width of the terminal.  Each panes are expanded to fill
    terminal width, unless **--pane-width** is specified.

- **-p**, **--paragraph**

    Insert empty line between every successive non-empty lines.

- **--height**=#

    Set page height and page mode on.  See ["CALCULATION"](#calculation) section.

- **--column-unit**=#, **--cu**=#

    Each columns are placed at the unit of 8 by default.  This option
    changes the number of the unit.

- **--linestyle**=`none`|`truncate`|`wrap`|`wordwrap`, **--ls**=`...`

    Set the style of treatment for longer lines.
    Default is `none`.

    **--linestyle=wordrap** is equivalent to **--linestyle=wrap**
    **--boundary=word**.

- **--boundary**=`none`|`word`|`space`

    Set text wrap boundary.  If set as `word` or `space`, text is not
    wrapped in the middle of alphanumeric word or non-space sequence.
    Option **--document** set this as `word`.  See [Text::ANSI::Fold](https://metacpan.org/pod/Text::ANSI::Fold) for
    detail.

- **--linebreak**=`none`|`all`|`runin`|`runout`, **--lb**=...

    Set the linebreak mode.

- **--runin**=#, **--runout**=#

    Set the number of runin/runout column.
    Default is both 2.

- **--**\[**no-**\]**pagebreak**

    Move to next pane when form feed character found.
    Default true.

- **--border**\[=_style_\], **-B**\[_style_\]

    Print border.  Enabled by **--page** option automatically.  If the
    optional _style_ is given, it is used as a border style and precedes
    to **--border-style** option.  Use **--border=none** to disable it.

    Border style is specified by **--border-style** option.

- **--border-style**=_style_, **--bs**=...

    Set the border style.  Current default style is `vbar`, which is
    light vertical line filling the page height.

    Sample styles:
    none,
    vbar, fence,
    line, heavy-line,
    ascii-frame, ascii-box,
    c-box,
    box, frame, page-frame,
    shadow, shadow-box,
    comb, rake, mesh,
    dumbbell, heavy-dumbbell,
    ribbon, round-ribbon, double-ribbon, double-double-ribbon, heavy-ribbon

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

    Allow white spaces at the top of each panes, or clean them up.
    Default true.  Negated by **--document** option.

- **--**\[**no-**\]**isolation**

    Allow the first line of a paragraph (continuous non-space lines) is
    placed at the bottom of a pane.  Default true.  If false, move it to
    the top of next pane.  Negated by **--document** option.

- **--fillup**\[=`pane`|`page`|`none`\]

    Fill up final pane or page by empty lines.  Parameter is optional and
    considered as 'pane' by default.  Set by **--page** option
    automatically.  Use **--fillup=none** if you want to explicitly disable
    it.

- **--tabstop**=#

    Set tab width.

- **--tabhead**=#
- **--tabspace**=#

    Set head and following space characters.  Both are space by default.
    If the option value is longer than single characger, it is evaluated
    as unicode name.

- **--tabstyle**=#

    Set the style how tab is expanded.  Select from `dot`, `symbol` or
    `shade`.  Styles are defined in [Text::ANSI::Fold](https://metacpan.org/pod/Text::ANSI::Fold) library.

- **--ambiguous**=`wide`|`narrow`

    Specifies how to treat Unicode ambiguous width characters.  Take a
    value of 'narrow' or 'wide.  Default is 'narrow'.

# CALCULATION

As for **--height**, **--width** and **--pane-width** options, besides
giving numeric digits, you can calculate the number using terminal
size.  If the expression contains non-digit character, it is evaluated
as a Reverse Polish Notation with the terminal size pushed on the
stack.

    OPTION              VALUE
    =================   =========================
    --height 1-         height - 1
    --height 2/         height / 2
    --height 1-2/       (height - 1) / 2
    --height dup2%-2/   (height - height % 2) / 2

Space and comma characters are ignored in the expression.  So `1-2/`
and `1 - 2 /` and `1,-,2,/` are all same.  See \`perldoc Math::RPN\`
for the expression detail.

# STARTUP

This command is implemented with [Getopt::EX](https://metacpan.org/pod/Getopt::EX) module.  So

    ~/.ansicolumnrc

file is read at start up.  If you want use **--no-white-space** always,
put this line in your `~/.ansicolumnrc`.

    option default --no-white-space

Also command can be extended by original modules with **-M**
option. See \`perldoc Getopt::EX\` for detail.

# INSTALL

## CPANMINUS

    $ cpanm App::ansicolumn
    or
    $ curl -sL http://cpanmin.us | perl - App::ansicolumn

To get the latest code, use this:

    $ cpanm https://github.com/kaz-utashiro/App-ansicolumn.git

# EXAMPLES

[https://github.com/kaz-utashiro/App-ansicolumn/tree/master/images](https://github.com/kaz-utashiro/App-ansicolumn/tree/master/images)

# SEE ALSO

[column(1)](http://man.he.net/man1/column),
[https://man7.org/linux/man-pages/man1/column.1.html](https://man7.org/linux/man-pages/man1/column.1.html)

[App::ansicolumn](https://metacpan.org/pod/App::ansicolumn),
[https://github.com/kaz-utashiro/App-ansicolumn](https://github.com/kaz-utashiro/App-ansicolumn)

[Text::ANSI::Printf](https://metacpan.org/pod/Text::ANSI::Printf),
[https://github.com/kaz-utashiro/Text-ANSI-Printf](https://github.com/kaz-utashiro/Text-ANSI-Printf)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2020-2021 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
