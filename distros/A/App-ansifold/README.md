# NAME

ansifold - fold command handling ANSI terminal sequences

# VERSION

Version 1.05

# SYNOPSIS

ansifold \[ options \]

    -w#, --width=#                Folding width (default 72)
         --boundary=word          Fold on word boundary
         --padding                Padding to margin space
         --padchar=_              Padding character
         --ambiguous=narrow|wide  Unicode ambiguous character handling
    -p,  --paragraph              Print extra newline
         --separate=string        Set separator string (default newline)
    -n                            Short cut for --separate ''
         --linebreak=mode         Line-break adjustment rule (default all)
         --runin                  Run-in width (default 4)
         --runout                 Run-out width (default 4)
    -s,  --smart                  Short cut for --boundary=word --linebreak=all
         --expand[=mode]          Expand tabs
         --tabstop=n              Tab-stop position (default 8)
         --tabhead=char           Tab-head character (default space)
         --tabspace=char          Tab-space character (default space)

# DESCRIPTION

**ansifold** is almost **fold** compatible command utilizing
[Text::ANSI::Fold](https://metacpan.org/pod/Text::ANSI::Fold) module, which enables to handle ANSI terminal
sequences and Unicode multibyte characters properly.

It folds lines in 72 column by default.  Use option **-w** to change
the folding width.

    $ ansifold -w132

Unlike original fold(1) command, multiple numbers can be specified
like:

    $ LANG=C date | ansifold -w 3,1,3,1,2 | cat -n
         1  Wed
         2   
         3  Dec
         4   
         5  19

Negative number fields are discarded.

    $ LANG=C date | ansifold -w 3,-1,3,-1,2
    Wed
    Dec
    19

Option **-n** (or **--separate** '') eliminates newlines between
columns.

    $ LANG=C date | ansifold -w 3,-1,3,-1,2 -n
    WedDec19

Single field is used repeatedly for the same line, but multiple fields
are not.  Put comma at the end of single field to discard the rest:

    ansifold -w 80,

Option `-w 80,` is equivalent to `-w 80,0`.  Zero width is ignored
when seen as a final number, but not ignored otherwise.

If the final width is negative, it is not discarded but takes all the
rest instead.  So next commands do the same thing.

    $ colrm 7 10

    $ ansifold -nw 6,-4,-1

Next command implements ANSI/Unicode aware [expand(1)](http://man.he.net/man1/expand) command.

    $ ansifold -w -1 --expand

Number description is handled by [Getopt::EX::Numbers](https://metacpan.org/pod/Getopt::EX::Numbers) module, and
consists of `start`, `end`, `step` and `length` elements.  For
example,

    $ echo AABBBBCCCCCCDDDDDDDDEEEEEEEEEE | ansifold -w 2:10:2

is equivalent to:

    $ echo AABBBBCCCCCCDDDDDDDDEEEEEEEEEE | ansifold -w 2,4,6,8,10

and produces output like this:

    AA
    BBBB
    CCCCCC
    DDDDDDDD
    EEEEEEEEEE

# LINE BREAKING

Option **--boundary=word** prohibit to break line in the middle of
alphanumeric word.  This version also supports line break adjustment,
mainly to perform Japanese \`\`KINSOKU'' processing.  Use
**--linebreak=all** to enable it.

When **--linebreak** option is enabled, if the cut-off text start with
space or prohibited characters (e.g. closing parenthesis), they are
ran-in at the end of current line as much as possible.

If the trimmed text end with prohibited characters (e.g. opening
parenthesis), they are ran-out to the head of next line, provided it
fits to maximum width.

Option **--linebreak** takes a value of _all_, _runin_, _runout_ or
_none_.  Default value is _none_.

Maximum width of run-in/run-out characters are defined by **--runin**
and **--runout** option.  Default values are 4.

Option **--smart** (or simply **-s**) is shortcut for
"**--boundary=word** **--linebreak=all**" and enables all smart text
formatting capability.

# TAB EXPANSION

Option **--expand** enables tab character expansion.  Each tab
character is converted to **tabhead** and following **tabspace**
characters (both are space by default).  They can be specified by
**--tabhead** and **--tabspace** option.  If the option value is longer
than single characger, it is evaluated as unicode name.  Next example
makes tab character visible keeping text layout.

    $ ansifold --expand --tabhead="MEDIUM SHADE" --tabspace="LIGHT SHADE"

Option **--expand** also takes option of pre-defined names.  Currently
these names are available.

    dot    => [ '.', '.' ],
    symbol => [ "\N{SYMBOL FOR HORIZONTAL TABULATION}", ' ' ],
    shade  => [ "\N{MEDIUM SHADE}", "\N{LIGHT SHADE}" ],

You can use like this:

    $ ansifold --expand=symbol

# SEE ALSO

[ansifold](https://github.com/kaz-utashiro/ansifold)

[Text::ANSI::Fold](https://github.com/kaz-utashiro/Text-ANSI-Fold)

[Text::ANSI::Fold::Util](https://github.com/kaz-utashiro/Text-ANSI-Fold-Util)

[Getopt::EX::Numbers](https://metacpan.org/pod/Getopt::EX::Numbers)

[https://www.w3.org/TR/2012/NOTE-jlreq-20120403/](https://www.w3.org/TR/2012/NOTE-jlreq-20120403/),
Requirements for Japanese Text Layout,
W3C Working Group Note 3 April 2012

# LICENSE

Copyright 2018- Kazumasa Utashiro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kazumasa Utashiro
