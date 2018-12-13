# NAME

ansifold - fold command handling ANSI terminal sequences

# SYNOPSIS

ansifold \[ options \]

    --width=80, -w80         Folding width
    --boundary=word, -s      Fold on word boundary
    --padding                Padding to margin space
    --padchar=_              Padding character
    --ambiguous=narrow|wide  Unicode ambiguous character handling
    --paragraph, -p          Print extra newline
    --truncate               Truncate folded text

# DESCRIPTION

**ansifold** is almost **fold** compatible command utilizing
[Text::ANSI::Fold](https://metacpan.org/pod/Text::ANSI::Fold) module, which enables to handle ANSI terminal
sequences and Unicode multibyte characters properly.

# LICENSE

Copyright (C) Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kazumasa Utashiro
