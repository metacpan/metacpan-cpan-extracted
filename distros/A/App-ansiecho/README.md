[![Actions Status](https://github.com/kaz-utashiro/App-ansiecho/workflows/test/badge.svg)](https://github.com/kaz-utashiro/App-ansiecho/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-ansiecho.svg)](https://metacpan.org/release/App-ansiecho)
# NAME

ansiecho - Colored echo command using ANSI terminal sequence

# SYNOPSIS

ansiecho \[ options \] args ...

Command Options:

    -n                 Do not print the trailing newline
    -j --join          Do not print space between arguments
    -e --escape        Enable backslash escape notation
       --rgb24         Produce 24bit color sequence
       --separate=s    Set argument separator
    -h --help          Print this message
    -v --version       Print version

Prefix Options:

    -s/-S SPEC         Produce ANSI sequence
    -c/-C SPEC ARG     Colorize next argument
    -f/-F FORMAT ARGS  Format arguments
       -E              Terminate -C -S -F effect
    -i/-a SPEC         Insert/Append ANSI sequence

Example:

    ansiecho -c R Red -c M/551 Magenta/Yellow -c FSDB BlinkReverseBoldBlue

    ansiecho -f '[ %12s ]' -c SR -f '%+06d' 123

    ansiecho -C '555/(132,0,41)' d i g i t a l

    read -a color < <( ansiecho -S ZE K/544 K/454 K/445 )

# VERSION

Version 0.07

# DESCRIPTION

## ECHO

**ansiecho** print arguments with ANSI terminal escape sequence
according to a given color specification.

In a simple case, **ansiecho** behave exactly same as [echo](https://metacpan.org/pod/echo) command.

    ansiecho a b c

Like [echo](https://metacpan.org/pod/echo) command, option **-n** disables to print newline at the
end.  Option **-j** (or **--join**) removes white space between
arguments.

Arguments can include backslash escaped characters, such as `\n` for
a new line.  There is an bash-echo-compatible **-e** option, but it is
enabled by default.  You can include control and named Unicode
characters using this.

    ansiecho '\t\N{ALARM CLOCK}\a'

See ["STRING LITERAL"](#string-literal) section for detail.

## COLOR and EFFECT

You can specify color of each argument by preceding with **-c** option:

    ansiecho -c R a -c GI b -c BD c

This command print strings `a`, `b` and `c` according to the color
spec of `R` (Red), `GI` (_Green Italic_) and `BD` (**Blue Bold**)
respectively.

Foreground and background color is specified in the form of
`fore/back`.

    ansiecho -c B/M 'Blue on Magenta' -c '<pink>/<salmon>' fish

Color can be described by 8+8 standard colors, 24 gray scales, 6x6x6
216 colors, RGB values or color names, with special effects such as I
(Italic), D (Double-struck; Bold), S (Stand-out; Reverse Video) and
such.  More information is described in ["COLOR SPEC"](#color-spec) section.

## FORMAT

Format string can be specified by **-f** option, and it behaves like a
[printf(1)](http://man.he.net/man1/printf) command.

    ansiecho -f '[ %5s : %5s : %5s ]' -c R RED -c G GREEN -c B BLUE

As in above example, colored text can be given as an argument for
**-f** option, and the string width is calculated as you expect,
including multibyte Unicode characters.

Formatted result ends up to a single argument, and can be a subject of
other operation.  In the next example, numbers are formatted, colored,
and given to other format.

    ansiecho -f '\N{ALARM CLOCK} %s' -c KF/544 -f ' %02d:%02d:%02d ' 1 2 3

Formatting is done by Perl `sprintf` function.  See
["sprintf" in perlfunc](https://metacpan.org/pod/perlfunc#sprintf) for detail.

## ANSI SEQUENCE

To get desired ANSI sequence, use **-s** option.  Next example produce
ANSI terminal sequence to indicate `deeppink` color on `lightyellow`
background.

    ansiecho -n -s '<deeppink>/<lightyellow>'

You will get the next result for the 256-color terminal:

    ^[[38;5;198;48;5;230m

and the next for the full-color terminal:

    ^[[38;2;255;20;147;48;2;255;255;224m

Using **-S** option, you can set multiple ANSI sequences at once in a
shell script.  Next **bash** code will initialize multiple variables
with the sequence for given color specs.

    read ZE C M Y < <( ansiecho -S ZE K/355 K/535 K/553 )

Or you can set array variable.

    read -a color < <( ansiecho -S ZE K/533 K/353 K/335 )

Then use this variable like:

    echo "${C} Cyan     ${ZE}"
    echo "${M} Mafenata ${ZE}"
    echo "${Y} Yellow   ${ZE}"

    reset=${color[0]}
    echo "${color[1]} Red   ${reset}"
    echo "${color[2]} Green ${reset}"
    echo "${color[3]} Blue  ${reset}"

# COMMAND OPTIONS

- **-n**

    Do not print newline at the end.

- **-e**, **--**\[**no-**\]**escape**

    Enable interpretation of backslash escapes in the normal string
    argument.  This option is enabled by default, unlike bash built-in
    [echo(1)](http://man.he.net/man1/echo) command.  Use **--no-escape** to disable it.

- **-j**, **--join**

    Do not print space between arguments.  This is a short-cut for
    `--separate ''`.

- **--separate** _string_

    Set separator string between each arguments.  Option **-j** is a
    short-cut for **--separate ''**.

- **--**\[**no-**\]**rgb24**

    Produce 24bit full-color sequence for 12bit/24bit specified colors.
    They are converted to 216 colors by default.

- **-h**, **--help**

    Print help.

- **-v**, **--version**

    Print version.

# PREFIX OPTIONS

- **-s** _spec_

    Print raw ANSI sequence for given _spec_.

- **-c** _spec_ _string_

    Print _string_ in a color given by _spec_.

- **-f** _format_ _args_ ...

    Print _args_ in a given _format_.  Backslash escape is always
    interpreted in the format string.

    The result of **-f** sequence ends up to a single argument, and can be
    a subject of other **-c** or **-f** option.

    Number of arguments are calculated from the number of `%` characters
    in the format string except `%%`.  Variable width and precision
    parameter `*` can be used like `%*s` or `%*.*s`.

    Format string also can be made by **-f** option.  Next commands produce
    same output, but second one looks better.

        ansiecho -f -f '%%%ds' 16 hello

        ansiecho -f '%*s' 16 hello

- **-S** _spec_

    If option `-S` found, all following arguments are considered as a
    color spec given to **-s** option, until option **-E** is found.

    Next two commands are equivalent.

        ansiecho -s ZE -s K/544 -s K/454 -s K/445

        ansiecho -S ZE K/544 K/454 K/445

- **-C** _spec_

    Option **-C** set permanent color which is applied to all following
    arguments until option **-E** found.

    Next command prints only a word `Yellow` in yellow, but second one
    print `Yellow`, `Brick`, and `Road` in yellow.

        ansiecho Follow the -cYS Yellow Brick Road

        ansiecho Follow the -CYS Yellow Brick Road

    You may want to color the phrase instead.

        ansiecho Follow the -cYS "Yellow Brick Road"

    Option `-C` can be used multiple times mixed with `-F` option.  See
    below.

- **-F** _format_

    As with the `-C` option, `-F` defines a format which is applied to
    all arguments until option **-E** found.  Format string have to include
    single `%s` placeholder.

        ansiecho Follow the -CYS -F ' %s ' Yellow Brick Road

    Option **-C** and **-F** can be used repeatedly, and they will take
    effect in the reverse order of their appearance.

    Next command show argument `A` in underline/bold with blinking red
    arrow.

        ansiecho -cRF -f'->%s' -cUD A B C

    Next one does the same thing for all arguments.

        ansiecho -CRF -F'->%s' -CUD A B C

- **-E**

    Terminate **-C**, **-F** and **-S** effects.

- **-i** _spec_
- **-a** _spec_

    Add raw ANSI sequence given by _spec_.  Option **-i** insert the
    sequence before the next argument, while **-a** append to the final
    argument.

    Next two commands are equivalent.

        ansiecho -c R Red

        ansiecho -i R Red -a ZE

    Color spec `ZE` produces RESET and ERASE LINE sequence.

    Because **-i** and **-a** does not produce RESET sequence, you can use
    them to accumulate the effects.

        ansiecho -i R R -i U RU -i I RUI -i S RUIS -i F RUISF -a Z

# STRING LITERAL

This is a backslash escape samples described in ["Quote and
Quote-like Operators" in perlop](https://metacpan.org/pod/perlop#Quote-and-Quote-like-Operators).  Non-alphabetical character after backslash is
always correspond to the character itself.

    Sequence     Description
    \t           tab               (HT, TAB)
    \n           newline           (NL)
    \r           return            (CR)
    \f           form feed         (FF)
    \b           backspace         (BS)
    \a           alarm (bell)      (BEL)
    \e           escape            (ESC)
    \x{263A}     hex char          (example: SMILEY)
    \x1b         restricted range hex char (example: ESC)
    \N{name}     named Unicode character or character sequence
    \N{U+263D}   Unicode character (example: FIRST QUARTER MOON)
    \c[          control char      (example: chr(27))
    \o{23072}    octal char        (example: SMILEY)
    \033         restricted range octal char  (example: ESC)

# COLOR SPEC

This is a brief summary.  Read ["COLOR SPEC" in Getopt::EX::Colormap](https://metacpan.org/pod/Getopt::EX::Colormap#COLOR-SPEC) for
complete description.  Try next command to see 256 color table.

    perl -MGetopt::EX::Colormap=:all -E colortable

Color specification is a combination of single uppercase character
representing 8 colors, and alternative (usually brighter) colors in
lowercase :

    R  r  Red
    G  g  Green
    B  b  Blue
    C  c  Cyan
    M  m  Magenta
    Y  y  Yellow
    K  k  Black
    W  w  White

or RGB values and 24 grey levels if using ANSI 256 or full color
terminal :

    (255,255,255)      : 24bit decimal RGB colors
    #000000 .. #FFFFFF : 24bit hex RGB colors
    #000    .. #FFF    : 12bit hex RGB 4096 colors
    000 .. 555         : 6x6x6 RGB 216 colors
    L00 .. L25         : Black (L00), 24 grey levels, White (L25)

or color names enclosed by angle bracket :

    <red> <blue> <green> <cyan> <magenta> <yellow>
    <aliceblue> <honeydue> <hotpink> <mooccasin>
    <medium_aqua_marine>

with other special effects :

    N    None
    Z  0 Zero (reset)
    D  1 Double strike (boldface)
    P  2 Pale (dark)
    I  3 Italic
    U  4 Underline
    F  5 Flash (blink: slow)
    Q  6 Quick (blink: rapid)
    S  7 Stand out (reverse video)
    H  8 Hide (concealed)
    X  9 Cross out

    E    Erase Line

    ;    No effect
    /    Toggle foreground/background
    ^    Reset to foreground
    ~    Cancel following effect

Samples:

    RGB  6x6x6    12bit      24bit           color name
    ===  =======  =========  =============  ==================
    B    005      #00F       (0,0,255)      <blue>
     /M     /505      /#F0F   /(255,0,255)  /<magenta>
    K/W  000/555  #000/#FFF  000000/FFFFFF  <black>/<white>
    R/G  500/050  #F00/#0F0  FF0000/00FF00  <red>/<green>
    W/w  L03/L20  #333/#ccc  303030/c6c6c6  <dimgrey>/<lightgrey>

# 256/24BIT COLORS

12bit/24bit colors are converted to 216 colors because most terminal
can not display them.  On some terminals which set the environment
variable `COLORTERM` as `truecolor` (e.g. iTerm), 24bit color mode
is automatically enabled.  Otherwise, use **--rgb24** option or set
`GETOPTEX_RGB24` environment variable to produce full-color sequence.

# INSTALL

## CPANMINUS

From CPAN archive:

    $ cpanm App::ansiecho
    or
    $ curl -sL http://cpanmin.us | perl - App::ansiecho

From GIT repository:

    cpanm https://github.com/kaz-utashiro/App-ansiecho.git

# SEE ALSO

["Quote and Quote-like Operators" in perlop](https://metacpan.org/pod/perlop#Quote-and-Quote-like-Operators)

[Getopt::EX::Colormap](https://metacpan.org/pod/Getopt::EX::Colormap)

[https://en.wikipedia.org/wiki/ANSI\_escape\_code](https://en.wikipedia.org/wiki/ANSI_escape_code)

[Graphics::ColorNames::X](https://metacpan.org/pod/Graphics::ColorNames::X)

[https://en.wikipedia.org/wiki/X11\_color\_names](https://en.wikipedia.org/wiki/X11_color_names)

[App::ansifold](https://metacpan.org/pod/App::ansifold), [App::ansicolumn](https://metacpan.org/pod/App::ansicolumn)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2021 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
