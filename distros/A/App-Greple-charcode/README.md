[![Actions Status](https://github.com/kaz-utashiro/greple-charcode/actions/workflows/test.yml/badge.svg)](https://github.com/kaz-utashiro/greple-charcode/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-Greple-charcode.svg)](https://metacpan.org/release/App-Greple-charcode)
# NAME

App::Greple::charcode - greple module to annotate unicode character data

# SYNOPSIS

**greple** **-Mcharcode** ...

**greple** **-Mcharcode** \[ _module option_ \] -- \[ _greple option_ \] ...

    MODULE OPTIONS
      --[no-]column display column number
      --[no-]char   display character itself
      --[no-]width  display width
      --[no-]code   display character code
      --[no-]name   display character name
      --align=#     align annotation

      --config KEY[=VALUE],... (KEY: column, char, width, code, name, align)

# VERSION

Version 0.9901

# DESCRIPTION

`App::Greple::charcode` displays Unicode information about the
matched characters.  It can also visualize zero-width combining or
hidden characters, which can be useful for examining text containing
such characters.

The following output, retrieved from this document for non-ASCII
characters (`\P{ASCII}`), shows that the character `\N{VARIATION
SELECTOR-15}` is included after the copyright character.  The same
character, presumably left over from editing, is also included after a
normal ASCII `t` character.

    $ greple -Mcharcode '\P{ASCII}' charcode.pm

            ┌───  12 \x{fe0e} \N{VARIATION SELECTOR-15}
            │ ┌─  14 \x{a9} \N{COPYRIGHT SIGN}
            │ ├─  14 \x{fe0e} \N{VARIATION SELECTOR-15}
    Copyright︎ ©︎ 2025 Kazumasa Utashiro.

The nasal sound of the K line (カ行) in Japanese is sometimes
represented by adding a semivoiced dot to the K line character, and
since Unicode does not define a corresponding character, it is
represented by combining the original character with a combining
character.  This module allows you to see how it is done.

    ┌─────────   0 \x{30ab} \N{KATAKANA LETTER KA}
    ├─────────   0 \x{309a} \N{COMBINING KATAKANA-HIRAGANA SEMI-VOICED SOUND MARK}
    │ ┌───────   2 \x{30ad} \N{KATAKANA LETTER KI}
    │ ├───────   2 \x{309a} \N{COMBINING KATAKANA-HIRAGANA SEMI-VOICED SOUND MARK}
    │ │ ┌─────   4 \x{30af} \N{KATAKANA LETTER KU}
    │ │ ├─────   4 \x{309a} \N{COMBINING KATAKANA-HIRAGANA SEMI-VOICED SOUND MARK}
    │ │ │ ┌───   6 \x{30b1} \N{KATAKANA LETTER KE}
    │ │ │ ├───   6 \x{309a} \N{COMBINING KATAKANA-HIRAGANA SEMI-VOICED SOUND MARK}
    │ │ │ │ ┌─   8 \x{30b3} \N{KATAKANA LETTER KO}
    │ │ │ │ ├─   8 \x{309a} \N{COMBINING KATAKANA-HIRAGANA SEMI-VOICED SOUND MARK}
    カ゚キ゚ク゚ケ゚コ゚

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-charcode/refs/heads/main/images/ka-ko.png">
    </p>
</div>

# MODULE OPTIONS

- **--**\[**no-**\]**column**

    Show column number.
    Default **true**.

- **--**\[**no-**\]**char**

    Show the character itself.
    Default **false**.

- **--**\[**no-**\]**width**

    Show the width.
    Default **false**.

- **--**\[**no-**\]**code**

    Show the character code in hex.
    Default **true**.

- **--**\[**no-**\]**name**

    Show the Unicode name of the character.
    Default **true**.

- **--align**=_column_

    Align annotation messages.  Defaults to `1`, which aligns to the
    rightmost column; `0` means no align; if a value of `2` or greater
    is given, it aligns to that numbered column.

# CONFIGURATION

Configuration parameters can be set in several ways.

## MODULE START FUNCTION

The start function of a module can be specified at the same time as
the module declaration.

    greple -Mcharcode::config(width,name=0)

    greple -Mcharcode::config=width,name=0

## PRIVATE MODULE OPTION

Module-specific options are specified between `-Mcharcode` and `--`.

    greple -Mcharcode --config width,name=0 -- ...

# CONFIGURATION PARAMETERS

- **column**

    (default 1)
    Show column number.

- **char**

    (default 0)
    Show the character itself.

- **width**

    (default 0)
    Show the width.

- **code**

    (default 1)
    Show the character code in hex.

- **name**

    (default 1)
    Show the Unicode name of the character.

- **align**=_column_

    (default 1)
    Align the description on the same column.

# INSTALL

    cpanm -n App::Greple::charcode

# SEE ALSO

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

[App::Greple::charcode](https://metacpan.org/pod/App%3A%3AGreple%3A%3Acharcode)

[App::Greple::annotate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aannotate)

# LICENSE

Copyright︎ ©︎ 2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kazumasa Utashiro
