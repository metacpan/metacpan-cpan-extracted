# NAME

ansifold - fold command handling ANSI terminal sequences

# SYNOPSIS

ansifold \[ options \]

    -w#, --width=#                Folding width
    -s,  --boundary=word          Fold on word boundary
         --padding                Padding to margin space
         --padchar=_              Padding character
         --ambiguous=narrow|wide  Unicode ambiguous character handling
    -p,  --paragraph              Print extra newline
         --separate=string        Set separator string (default newline)
    -n                            Short cut for --separate ''

# DESCRIPTION

**ansifold** is almost **fold** compatible command utilizing
[Text::ANSI::Fold](https://metacpan.org/pod/Text::ANSI::Fold) module, which enables to handle ANSI terminal
sequences and Unicode multibyte characters properly.

Opiton **-w** takes width number to fold.  Unlike original fold(1)
command, multiple numbers can be specified like:

    ansifold -w 3,1,3,1,2

Negative number fields are discarded.

    $ LANG=C date | ansifold -w 3,-1,3,-1,2
    Wed
    Dec
    19

Single field is used repeatedly for the same line, but multiple fields
are not.  Put comma at the end to discard the rest:

    ansifold -w 80,

Number description is handled by [Getopt::EX::Numbers](https://metacpan.org/pod/Getopt::EX::Numbers) module, and
consists of `start`, `end`, `step` and `length` elements.  For
example,

    ansifold -w 2:10:2

produces output like this:

    AA
    BBBB
    CCCCCC
    DDDDDDDD
    EEEEEEEEEE

Each folded strings are separated by newline.  Use `--separate`
option to set the separator string, and use `-n` to set it empty.

# SEE ALSO

[github](https://github.com/kaz-utashiro/ansifold)

[github](https://github.com/kaz-utashiro/Text-ANSI-Fold)

[Getopt::EX::Numbers](https://metacpan.org/pod/Getopt::EX::Numbers)

# LICENSE

Copyright (C) 2018- Kazumasa Utashiro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kazumasa Utashiro
