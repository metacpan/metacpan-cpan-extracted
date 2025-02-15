[![Actions Status](https://github.com/kaz-utashiro/greple-charcode/actions/workflows/test.yml/badge.svg)](https://github.com/kaz-utashiro/greple-charcode/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-Greple-charcode.svg)](https://metacpan.org/release/App-Greple-charcode)
# NAME

App::Greple::charcode - greple module to annotate unicode character data

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-charcode/refs/heads/main/images/homoglyph.png">
    </p>
</div>

# SYNOPSIS

**greple** **-Mcharcode** ...

**greple** **-Mcharcode** \[ _module option_ \] -- \[ _command option_ \] ...

    COMMAND OPTION
      --no-annotate  do not print annotation
      --[no-]align   align annotations
      --align-all    align to the same column for all lines
      --align-side   align to the longest line

    UNICODE
      --composite    find composite character (combining character sequence)
      --precomposed  find precomposed character
      --combined     find both composite and precomposed characters
      --dt=type      specify decomposition type
      --surrogate    find character in UTF-16 surrogate pair range
      --outstand     find non-ASCII combining characters
      -p/-P prop     find \p{prop} or \P{prop} characters

    ANSI
      --ansicode     find ANSI terminal control sequences

    MODULE OPTION
      --[no-]column  display column number
      --[no-]char    display character itself
      --[no-]width   display width
      --[no-]code    display character code
      --[no-]name    display character name
      --[no-]visible display character name
      --[no-]split   put annotattion for each character
      --alignto=#    align annotation to #

      --config KEY[=VALUE],...
               (KEY: column char width code name visible align)

**greple** **-Mcc** ...

**greple** **-Mcc** \[ _module option_ \] -- \[ _command option_ \] ...

    -Mcc           alias module for -Mcharcode

# VERSION

Version 0.9906

# DESCRIPTION

Greple module `-Mcharcode` (or `-Mcc` for short) displays
information about the matched characters.  It can also visualize
Unicode zero-width combining or hidden characters, which can be useful
for examining text containing visually indistinguishable or
imperceptible elements.

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

# COMMAND OPTIONS

- **--annotate**, **--no-annotate**

    Print annotation or not.  Enabled by default, so use `--no-annotate`
    to disable it.

- **--**\[**no-**\]**align**

    Align annotation or not.
    Default true.

- **--align-all**

    Align to the same column for all lines

- **--align-side**

    Align to the longest line length, regardless of match position.

# PATTERN OPTIONS

If multiple patterns are given to **greple**, it normally prints only
the lines that match all of the patterns.  However, for the purposes
of this module, it is desirable to display lines that match any of
them, so the `--need=1` option is specified by default.

If multiple patterns are specified, the strings matching each pattern
will be displayed in a different color.

- **--composite**

    Search for composite characters (combining character sequence)
    composed of base and combining characters.

- **--precomposed**

    Search for precomposed characters (`\p{Dt=Canonical}`).

- **--combined**

    Find both **composite** and **precomposed** characters.

- **--dt**=_type_, **--decomposition-type**=_type_

    Specifies the `Decomposition_Type`.  It can take three values:
    `Canonical`, `Non_Canonical` (`NonCanon`), or `None`.

- **--outstand**

    Matches outstanding characters, those are non-ASCII combining
    characters.

- **--surrogate**

    Matches to characters in UTF-16 surragate pair range (U+10000 to
    U+10FFFF).

- **-p** _prop_, **-P** _prop_

    Short cut for `-E '\p{prop}'` and  `-E '\P{prop}'`.

    You will not be able to use greple's `-p` option, but it probably
    won't be a problem.  If you must use it, use `--pargraph`.

- **--ansicode**

    Search ANSI terminal control sequence.  Automatically disables `name`
    and `code` parameter and activates `visible`.  Colorized output is
    disabled too.

    To be precise, it searches for CSI Control sequences defined in
    ECMA-48.  Pattern is defined as this.

        (?x)
        # see ECMA-48 5.4 Control sequences
        (?: \e\[ | \x9b ) # csi
        [\x30-\x3f]*      # parameter bytes
        [\x20-\x2f]*      # intermediate bytes
        [\x40-\x7e]       # final byte

    <div>
            <p>
            <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-charcode/refs/heads/main/images/ansicode.png">
            </p>
    </div>

# MODULE OPTIONS and PARAMS

Module-specific options are specified between `-Mcharcode` and `--`.

    greple -Mcharcode --config width,name=0 -- ...

Parameters can be set in two ways, one using the `--config` option
and the other using dedicated options.  See the ["CONFIGURATION"](#configuration)
section for more information.

- **--config**=_params_

    Set configuration parameters.

- **column**
- **--**\[**no-**\]**column**

    Show column number.
    Default `1`.

- **char**
- **--**\[**no-**\]**char**

    Show the character itself.
    Default `0`.

- **width**
- **--**\[**no-**\]**width**

    Show the width.
    Default `0`.

- **code**
- **--**\[**no-**\]**code**

    Show the character code in hex.
    Default `1`.

- **name**
- **--**\[**no-**\]**name**

    Show the Unicode name of the character.
    Default `1`.

- **visible**
- **--**\[**no-**\]**visible**

    Display invisible characters in a visible string representation.
    Default `0`.

- **alignto**=_column_
- **--alignto**=_column_

    Align annotation messages.  Defaults to `1`, which aligns to the
    rightmost column; `0` means no align; if a value of `2` or greater
    is given, it aligns to that numbered column.

    _column_ can be negative; if `-1` is specified, align to the same
    column for all lines.  If `-2` is specified, align to the longest
    line length, regardless of match position.

- **split**
- **--**\[**no-**\]**split**

    If a pattern matching multiple characters is given, annotate each
    character independently.

# CONFIGURATION

Configuration parameters can be set in several ways.

## MODULE START FUNCTION

The start function of a module can be specified at the same time as
the module declaration.

    greple -Mannotate::config(alignto=0)

    greple -Mannotate::config=alignto=80

## PRIVATE MODULE OPTION

Module-specific options are specified between `-Mannotate` and `--`.

    greple -Mannotate --config alignto=80 -- ...

    greple -Mannotate --alignto=80 -- ...

## GENERIC MODULE OPTION

Module-specific `---config` option can be called by normal command
line option `--annotate::config`.

    greple -Mannotate --annotate::config alignto=80 ...

# EXAMPLES

## HOMOGLYPH

    greple -Mcc -P ASCII --align-side --cm=S t/homoglyph

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-charcode/refs/heads/main/images/homoglyph.png">
    </p>
</div>

## BOX DRAWINGS

    perldoc -m App::ansicolumn::Border | greple -Mline -Mcc --code -- --outstand --mc=10,

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-charcode/refs/heads/main/images/box-drawing.png">
    </p>
</div>

## AYNU ITAK

    greple -Mcc --outstand --split t/ainu.txt

<div>
    <p>
    <img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-charcode/refs/heads/main/images/aynu.png">
    </p>
</div>

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
