[![Actions Status](https://github.com/kaz-utashiro/ansifold/workflows/test/badge.svg)](https://github.com/kaz-utashiro/ansifold/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-ansifold.svg)](https://metacpan.org/release/App-ansifold)
# NAME

ansifold - fold command handling ANSI terminal sequences

# SYNOPSIS

ansifold \[ options \]

    -w#   --width=#                Folding width (default 72)
          --boundary=word|space    Fold on word boundary
          --padding[=#]            Padding to margin space
          --padchar=_              Default padding character
          --prefix=string          Set prefix string (default empty)
          --ambiguous=narrow|wide  Unicode ambiguous character handling
    -p    --paragraph              Print extra newline
          --separate=string        Set separator string (default newline)
    -n    --nonewline              Same as --separate ''
          --linebreak=mode         Line-break mode (all, runin, runout, none)
          --runin                  Run-in width (default 4)
          --runout                 Run-out width (default 4)
    -s    --smart                  Same as --boundary=word --linebreak=all
    -x[#] --expand[=#]             Expand tabs
          --tabstop=n              Tab-stop position (default 8)
          --tabhead=char           Tab-head character (default space)
          --tabspace=char          Tab-space character (default space)
          --tabstyle=style         Tab expansion style (shade, dot, symbol)
          --colrm start [ end ]    colrm(1) command compatible
    -h    --help                   Show help message
    -v    --version                Show version

ansiexpand \[ options \]

ansicolrm \[ options \]

# VERSION

Version 1.1501

# DESCRIPTION

**ansifold** is a [fold(1)](http://man.he.net/man1/fold) compatible command utilizing
[Text::ANSI::Fold](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AFold) module, which enables to handle ANSI terminal
sequences.

When executed under the name of **ansiexpand**, it works like
[expand(1)](http://man.he.net/man1/expand) command.  If the name is **ansicolrm**, works like
[colrm(1)](http://man.he.net/man1/colrm) command.  Because they are not installed automatically,
make a symbolic link manually if you want.

## FOLD BY WIDTH

**ansifold** folds lines in 72 column by default.  Use option **-w** to
change the folding width.

    $ ansifold -w132

Single field is used repeatedly for the same line.

With option **--padding**, remained columns are filled by padding
character, space by default, or specified by optional value like
`--padding=_`.  Default padding character can be set by **--padchar**
option.

**ansifold** handles Unicode multi-byte characters properly.  Option
**--ambiguous** takes _wide_ or _narrow_ and it specifies the visual
width of Unicode ambiguous characters.

If the width value is `term`, it is replaced by the terminal width.

## MULTIPLE WIDTH

Unlike the original fold(1) command, multiple numbers can be
specified.

    $ LANG=C date | ansifold -w 3,1,3,1,2 | cat -n
         1  Wed
         2   
         3  Dec
         4   
         5  19

With multiple fields, unmatched part is discarded as in the above
example.  So you can truncate lines by putting comma at the end of
single field.

    ansifold -w80,

Option `-w80,` is equivalent to `-w80,0`.  Zero width is ignored
when seen as a final number, but not ignored otherwise.

## NEGATIVE WIDTH

Negative number fields are discarded.

    $ LANG=C date | ansifold -w 3,-1,3,-1,2
    Wed
    Dec
    19

If the final width is negative, it is not discarded but takes all the
rest instead.  So next commands do the same thing.

    $ colrm 7 10

    $ ansifold -nw 6,-4,-1

Option `--width -1` does nothing effectively.  Using it with
**--expand** option implements ANSI/Unicode aware [expand(1)](http://man.he.net/man1/expand) command.

    $ ansifold --expand --width -1

This can be written as this.

    $ ansifold -xw-1

## NUMBERS

Number description is handled by [Getopt::EX::Numbers](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3ANumbers) module, and
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

## SEPARATOR/TERMINATOR

Option **-n** eliminates newlines between columns.

    $ LANG=C date | ansifold -w 3,-1,3,-1,2 -n
    WedDec19

Option **--separate** set separator string.

    $ echo ABCDEF | ansifold --separate=: -w 1,0,1,0,1,-1
    A::B::C:DEF

Option **-n** is a short-cut for `--separate ''`.

Option **--paragraph** or **-p** print extra newline after each line.
This is convenient when a paragraph is made up of single line, like
microsoft word document.

## PREFIX

If a string is given by **--prefix** option, that string is inserted at
the beginning of each folded text.  This is convenient to produce
indented text block.  Because the first line is not affected, insert
appropiate prefix if necessary.  Originally made for
[App::Greple::frame](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aframe) module.

# LINE BREAKING

Line break adjustment is supported for ASCII word boundaries.  As for
Japanese, more complicated prohibition processing is performed.  Use
option **-s** to enable everything.

## **--boundary**=_word_|_space_

This option prohibit breaking line in the middle of ASCII/Latin word.
Context of word is defined by option value; _word_ means
alpha-numeric sequence, while _space_ means simply non-space
printables.

## **--linebreak**=_all_|_runin_|_runout_|_none_

Option **--linebreak** takes a value of _all_, _runin_, _runout_ or
_none_.  Default value is _none_.

When **--linebreak** option is enabled, if the cut-off text start with
space or prohibited characters (e.g. closing parenthesis), they are
ran-in at the end of current line as much as possible.

If the trimmed text end with prohibited characters (e.g. opening
parenthesis), they are ran-out to the head of next line, provided it
fits to maximum width.

## **--runin**=_width_, **--runout**=_width_

Maximum width of run-in/run-out characters are defined by **--runin**
and **--runout** option.  Default values are 4.

## **--smart**, **-s**

Option **--smart** (or simply **-s**) set both **--boundary=word** and
**--linebreak=all**, and enables all smart text formatting capability.

Use option **--boundary=space** if you want the command to behave more
like **-s** option of [fold(1)](http://man.he.net/man1/fold) command.

# TAB EXPANSION

## **--expand**

Option **--expand** (or **-x**) enables tab character expansion.

    $ ansifold --expand

Takes optional number for tabstop and it precedes to **--tabstop**
option.

    $ ansifold -x4w-1

## **--tabhead**, **--tabspace**

Each tab character is converted to **tabhead** and following
**tabspace** characters (both are space by default).  They can be
specified by **--tabhead** and **--tabspace** option.  If the option
value is longer than single characger, it is evaluated as unicode
name.  Next example makes tab character visible keeping text layout.

    $ ansifold --expand --tabhead="MEDIUM SHADE" --tabspace="LIGHT SHADE"

## **--tabstyle**

Option **--tabstyle** allow to set **--tabhead** and **--tabspace**
characters at once according to the given style name.  Select from
`dot`, `symbol` or `shade`.  Styles are defined in
[Text::ANSI::Fold](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AFold) library.

    $ ansifold --expand --tabstyle=shade

# COLRM

## **--colrm** \[ start \[ end \] \]

Option **--colrm** takes [colrm(1)](http://man.he.net/man1/colrm) command compatible arguments and
implicitly set **--separate** empty.  Next command behave exactly like
`colrm start end` and takes care of ANSI terminal sequences.

    $ ansifold --colrm start end

# FILES

- `~/.ansifoldrc`

    Start-up file.
    See [Getopt::EX::Module](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3AModule) for format.

# INSTALL

## CPANMINUS

    $ cpanm App::ansifold

# SEE ALSO

[ansifold](https://github.com/kaz-utashiro/ansifold)

[Text::ANSI::Fold](https://github.com/kaz-utashiro/Text-ANSI-Fold)

[Text::ANSI::Fold::Util](https://github.com/kaz-utashiro/Text-ANSI-Fold-Util)

[Getopt::EX::Numbers](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3ANumbers)

[https://www.w3.org/TR/jlreq/](https://www.w3.org/TR/jlreq/)
Requirements for Japanese Text Layout,
W3C Working Group Note 11 August 2020

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2018-2022 Kazumasa Utashiro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
