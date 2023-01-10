[![Actions Status](https://github.com/tecolicom/App-ansiexpand/workflows/test/badge.svg)](https://github.com/tecolicom/App-ansiexpand/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-ansiexpand.svg)](https://metacpan.org/release/App-ansiexpand)
# NAME

ansiexpand, ansiunexpand - ANSI sequences aware tab expand/unexpand command

# SYNOPSIS

ansiexpand \[ option \] file ...

ansiunexpand \[ option \] file ...

    -u  --unexpand               convert spaces to tabs
    -t# --tabstop=#              tab stop width
        --tabhead=char           tab head character
        --tabspace=char          tab space character
        --tabstyle=style         tab style
        --ambiguous=wide|narrow  width of Unicode ambiguous character

# VERSION

Version 1.04

# DESCRIPTION

**ansiexpand** is an [expand(1)](http://man.he.net/man1/expand) compatible command utilizing
[Text::ANSI::Tabs](https://metacpan.org/pod/Text%3A%3AANSI%3A%3ATabs) module, which enables to handle ANSI terminal
sequences and Unicode wide characters.  Not only expanding tabs to
spaces, it can visualize them in various styles.

This is a command line interface for [Text::ANSI::Tabs](https://metacpan.org/pod/Text%3A%3AANSI%3A%3ATabs) module, which
uses [Text::ANSI::Fold](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AFold) module as a backend.  Consult them for
implementation detail.

# OPTIONS

- **--unexpand**, **-u**

    Behave as unexpand command.

- **--tabstop**=#, **-t**#

    Set tab stop width.  Unlike [expand(1)](http://man.he.net/man1/expand), takes only single value.

- **--tabhead**=_char_
- **--tabspace**=_char_

    Set tab head and following space character.  If longer than single
    character, it is considered as a Unicode name.

- **--tabstyle**, **--ts**
- **--tabstyle**=_style_, **--ts**=...
- **--tabstyle**=_head-style_,_space-style_ **--ts**=...

    Set the style how tab is expanded.  Select `symbol` or `shade` for
    example.  If two style names are combined, like
    `squat-arrow,middle-dot`, use `squat-arrow` for tabhead and
    `middle-dot` for tabspace.

    Show available style list if called without parameter.  Styles are
    defined in [Text::ANSI::Fold](https://metacpan.org/pod/Text%3A%3AANSI%3A%3AFold) library.

- **--ambiguous**=`wide`|`narrow`

    Set the width of Unicode ambiguous characters.  Default is `narrow`.

# INCOMPATIBILITY

There is no `-a` option for `ansiunexpand` and it always convert all
spaces not only leading ones.  Use normal [unexpand(1)](http://man.he.net/man1/unexpand) to convert
just leading spaces.

`ansiexpand -u` or `ansiunexpand` convert all spaces whenever possible
including single space even if it does not reduce total data length.

# FILES

- `~/.ansiunexpandrc`
- `~/.ansiexpandrc`

    Start-up file.
    See [Getopt::EX::Module](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3AModule) for format.

# INSTALL

## CPANMINUS

    $ cpanm App::ansiexpand

# SEE ALSO

[App::ansiexpand](https://metacpan.org/pod/App%3A%3Aansiexpand), [https://github.com/tecolicom/App-ansiexpand](https://github.com/tecolicom/App-ansiexpand)

[Text::ANSI::Tabs](https://github.com/tecolicom/Text-ANSI-Tabs)

[Text::ANSI::Fold](https://github.com/tecolicom/Text-ANSI-Fold)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2021-2023 Kazumasa Utashiro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
