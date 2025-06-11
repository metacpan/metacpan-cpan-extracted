[![Actions Status](https://github.com/kaz-utashiro/greple-xp/workflows/test/badge.svg)](https://github.com/kaz-utashiro/greple-xp/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-Greple-xp.svg)](https://metacpan.org/release/App-Greple-xp)
# NAME

App::Greple::xp - extended pattern module

# VERSION

Version 1.01

# SYNOPSIS

greple -Mxp

# DESCRIPTION

This module provides functions those can be used by **greple** pattern
and region options.

# OPTIONS

- **--le-pattern** _file_
- **--inside-pattern** _file_
- **--outside-pattern** _file_
- **--include-pattern** _file_
- **--exclude-pattern** _file_

    Read file contents and use each lines as a pattern for options.

- **--le-string** _file_
- **--inside-string** _file_
- **--outside-string** _file_
- **--include-string** _file_
- **--exclude-string** _file_

    Almost same as **\*-pattern** option but each line is concidered as a
    fixed string rather than regular expression.

## COMMENT

You can insert comment lines in pattern file.  As for fixed string
file, there is no way to write comment.

Lines start with hash mark (`#`) is ignored as a comment line.

String after double slash (`//`) is also ignored with preceding
spaces.

## MULTILINE REGEX

Complex pattern can be written on multiple lines as follows.

    (?xxn) \
    ( (?<b>\[) | \@ )   # start with "[" or @             \
    (?<n> [ \d : , ]+)  # sequence of digit, ":", or ","  \
    (?(<b>) \] | )      # closing "]" if start with "["   \
    $                   # EOL

## WILD CARD

Because _file_ parameter is globbed, you can use wild card to give
multiple files.  If nothing matched to the wild card, this option is
simply ignored with no message.

    $ greple -Mxp --exclude-pattern '*.exclude' ...

# SEE ALSO

[https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[https://github.com/kaz-utashiro/greple-xp](https://github.com/kaz-utashiro/greple-xp)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2019-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
