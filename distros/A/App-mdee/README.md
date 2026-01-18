[![Actions Status](https://github.com/tecolicom/App-mdee/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/tecolicom/App-mdee/actions?workflow=test) [![MetaCPAN Release](https://badge.fury.io/pl/App-mdee.svg)](https://metacpan.org/release/App-mdee)
# NAME

mdee - Markdown, Easy on the Eyes

# SYNOPSIS

    mdee [ options ] file ...

     -h  --help             show help
         --version          show version
     -d  --debug            debug level (repeatable)
     -n  --dryrun           dry-run mode
     -f  --filter           filter mode (highlight only)
         --[no-]fold        line folding (default: on)
         --[no-]table       table formatting (default: on)
         --[no-]nup         nup paged output (default: on)
     -w  --width=#          fold width (default: 80)
     -t  --theme=#          color theme
     -m  --mode=#           light or dark (default: light)
     -B  --base-color=#     override theme's base color
                            (e.g., <Red>, #FF5733, hsl(0,100,50))
         --list-themes      list built-in themes
         --show=#           set field visibility (e.g., italic=1)
     -C  --pane=#           number of columns
     -R  --row=#            number of rows
     -G  --grid=#           grid layout (e.g., 2x3)
     -P  --page=#           page height in lines
     -S  --pane-width=#     pane width (default: 85)
    --bs --border-style=#   border style
         --[no-]pager[=#]   pager command

# VERSION

Version 0.03

# DESCRIPTION

**mdee** is a multi-column Markdown viewer with syntax highlighting,
combining [greple(1)](http://man.he.net/man1/greple) for colorization and [nup(1)](http://man.he.net/man1/nup) for paged output.

Supported elements: headers (h1-h6), bold, italic, strikethrough,
inline code, code blocks, HTML comments, tables, and list items.

This tool is designed for viewing Markdown not constrained by display
formatting, such as output from LLMs (Large Language Models).  It applies
syntax highlighting with line folding and table alignment, but does not
reflow paragraphs with hard line breaks.  For full Markdown rendering,
many other viewers are available.  Combine them with [nup(1)](http://man.he.net/man1/nup) for
similar paged output (e.g., `nup glow README.md`).

# OPTIONS

## General Options

- **-h**, **--help**

    Show help message.

- **--version**

    Show version.

- **-d**, **--debug**

    Set debug level.  Can be repeated (`-d`, `-dd`, `-ddd`) for
    increasing verbosity.

- **-n**, **--dryrun**

    Dry-run mode. Show the command without executing.

- **-f**, **--filter**

    Filter mode.  Reads from stdin (or files) and outputs highlighted
    Markdown to stdout.  Disables line folding, table formatting, and
    nup paged output.  Useful for piping Markdown content through mdee
    for syntax highlighting only.

## Processing Options

- **--\[no-\]fold**

    Enable or disable line folding for list items.  When enabled, long
    lines in list items are wrapped with proper indentation using
    [ansifold(1)](http://man.he.net/man1/ansifold).  Default is enabled.

- **--\[no-\]table**

    Enable or disable table formatting.  When enabled, Markdown tables
    are formatted using [ansicolumn(1)](http://man.he.net/man1/ansicolumn) for aligned column display.
    Default is enabled.

- **--\[no-\]nup**

    Enable or disable [nup(1)](http://man.he.net/man1/nup) for multi-column paged output.  When
    disabled, output goes directly to stdout without formatting.
    Default is enabled.

- **-w** _N_, **--width**=_N_

    Set the fold width for text wrapping. Default is 80.
    Only effective when `--fold` is enabled.

## Theme Options

**mdee** supports color themes for customizing syntax highlighting.
Themes define colors for various Markdown elements (headers, code blocks,
bold text, etc.).

- **-t** _NAME_, **--theme**=_NAME_

    Select a color theme.  Default is `default`.

- **-m** _MODE_, **--mode**=_MODE_

    Select light or dark mode.  Default is `light`.

    If the terminal supports background color detection (via
    [Getopt::EX::termcolor](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3Atermcolor)), the mode is automatically selected based on
    terminal luminance.

    Each theme has light and dark variants optimized for different terminal
    backgrounds.  The built-in `default` theme provides:

    - `light` - Navy blue base color for light backgrounds
    - `dark` - Light blue (#CCCDFF) base color for dark backgrounds

    User configuration is loaded from:

        ${XDG_CONFIG_HOME:-~/.config}/mdee/config.sh

    This is a shell script that can set defaults and override colors:

        # ~/.config/mdee/config.sh
        default_mode='dark'              # set default mode
        colors[base]='<DarkCyan>'        # override base color
        colors[h1]='L25DE/${base}'       # header with base background

    Color specifications use [Term::ANSIColor::Concise](https://metacpan.org/pod/Term%3A%3AANSIColor%3A%3AConcise) format.
    The `FG/BG` notation specifies foreground and background colors
    (e.g., `L25DE/${base}` means gray foreground on base-colored background).
    The `${base}` string is expanded to the base color value after loading.

- **-B** _COLOR_, **--base-color**=_COLOR_

    Override the theme's base color.  This is useful for quickly adjusting
    the color scheme without creating a custom theme.
    Accepts [Term::ANSIColor::Concise](https://metacpan.org/pod/Term%3A%3AANSIColor%3A%3AConcise) color specifications:

    - Color names: `<Red>`, `<NavyBlue>`
    - RGB hex: `#FF5733`
    - RGB decimal: `rgb(255,87,51)`
    - HSL: `hsl(0,100,50)`

    **Note:** Basic ANSI color codes (`R`, `G`, `B`, etc.) are not supported
    because the highlighting variations are created by adjusting lightness
    of the base color, which requires full color specifications.

- **--list-themes**

    List built-in themes with color samples and exit.

## Highlight Options

- **--show**=_FIELD_\[=_VALUE_\],...

    Control field visibility for highlighting.  Empty value or `0` disables
    the field; any other value (including `1`) enables it.

        --show italic           # enable italic
        --show bold=0           # disable bold
        --show all              # enable all fields
        --show all= --show bold # disable all, then enable only bold

    Multiple fields can be specified with commas or by repeating the option.
    The special field `all` affects all fields and is processed first.

    Available fields: `comment`, `bold`, `italic`, `strike`, `h1`,
    `h2`, `h3`, `h4`, `h5`, `h6`, `inline_code`, `code_block`.

    All fields are enabled by default.

## Layout Options (passed to nup)

- **-C** _N_, **--pane**=_N_

    Set the number of columns (panes).

- **-R** _N_, **--row**=_N_

    Set the number of rows.

- **-G** _CxR_, **--grid**=_CxR_

    Set grid layout. For example, `-G2x3` creates 2 columns and 3 rows.

- **-P** _N_, **--page**=_N_

    Set the page height in lines.

- **-S** _N_, **--pane-width**=_N_

    Set the pane width in characters. Default is 85.

- **--bs**=_STYLE_, **--border-style**=_STYLE_

    Set the border style.

## Pager Options

- **--\[no-\]pager**\[=_COMMAND_\]

    Set the pager command.  Use `--pager=less` to specify a pager,
    or `--no-pager` to disable paging.

# EXAMPLES

    mdee README.md              # view markdown file
    mdee -C2 document.md        # 2-column view
    mdee -G2x2 manual.md        # 2x2 grid (4-up)
    mdee -w60 narrow.md         # narrower text width
    mdee --no-pager file.md     # without pager
    mdee --no-nup file.md       # output to stdout without nup
    mdee --no-fold file.md      # disable line folding
    mdee --no-table file.md     # disable table formatting

    # Filter mode
    cat file.md | mdee -f       # highlight stdin
    mdee -f file.md             # highlight only (no paging)

    # Theme examples
    mdee --mode=dark file.md             # use dark mode
    mdee --mode=light file.md            # use light mode
    mdee -B '<Red>' file.md              # override base color
    mdee --mode=dark -B '<Cyan>' file.md # dark mode with cyan base
    mdee --list-themes                   # list available themes

# DEPENDENCIES

This command requires the following:

- [App::Greple](https://metacpan.org/pod/App%3A%3AGreple) - pattern matching and highlighting
- [App::Greple::tee](https://metacpan.org/pod/App%3A%3AGreple%3A%3Atee) - filter integration
- [App::ansifold](https://metacpan.org/pod/App%3A%3Aansifold) - ANSI-aware text folding
- [App::ansicolumn](https://metacpan.org/pod/App%3A%3Aansicolumn) - ANSI-aware column formatting
- [App::nup](https://metacpan.org/pod/App%3A%3Anup) - N-up multi-column paged output
- [App::ansiecho](https://metacpan.org/pod/App%3A%3Aansiecho) - ANSI color output
- [Getopt::Long::Bash](https://metacpan.org/pod/Getopt%3A%3ALong%3A%3ABash) - bash option parsing
- [Getopt::EX::termcolor](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3Atermcolor) - terminal background detection

# IMPLEMENTATION

**mdee** is implemented as a Bash script that orchestrates multiple
specialized tools into a unified pipeline.  The architecture follows
Unix philosophy: each tool does one thing well, and they communicate
through standard streams.

The overall data flow is:

    Input File
        |
        v
    [greple] --- Syntax Highlighting
        |
        v
    [ansifold] --- Text Folding (optional)
        |
        v
    [ansicolumn] --- Table Formatting (optional)
        |
        v
    [nup] --- Paged Output (optional)
        |
        v
    Terminal/Pager

## Pipeline Architecture

**mdee** dynamically constructs a pipeline based on enabled options.
Each stage is represented as a Bash array containing the command and
its arguments.  The `--dryrun` option displays the constructed pipeline
without execution.

### Processing Stages

The pipeline consists of four configurable stages.  Each stage can be
enabled or disabled independently using `--[no-]fold`, `--[no-]table`,
and `--[no-]nup` options.

#### Syntax Highlighting

The first stage uses [greple(1)](http://man.he.net/man1/greple) with the `-G` (grep mode) and
`--ci=G` (capture index) options to apply different colors to each
captured group in regular expressions.

Supported Markdown elements:

- Headers (`# h1` through `###### h6`)
- Bold text (`**bold**` or `__bold__`)
- Italic text (`*italic*` or `_italic_`)
- Inline code (`` `code` ``)
- Code blocks (fenced with ```` ``` ```` or `~~~`)
- HTML comments (`<!-- comment -->`)

Code block detection follows the CommonMark specification:

- Opening fence: 0-3 spaces indentation, then 3+ backticks or tildes
- Closing fence: 0-3 spaces indentation, same character, same or more count
- Backticks and tildes cannot be mixed (```` ``` ```` must close with ```` ``` ````)

**Color Specifications**

Colors are specified using [Term::ANSIColor::Concise](https://metacpan.org/pod/Term%3A%3AANSIColor%3A%3AConcise) format.
The `--cm` option maps colors to captured groups.  For example,
`L00DE/${base}` specifies gray foreground on base-colored background.

The color specification supports modifiers:

- `+l10` / `-l10`: Adjust lightness by percentage
- `=l50`: Set absolute lightness
- `D`: Bold, `U`: Underline, `E`: Erase line

Example greple invocation:

    greple -G --ci=G --all --need=0 \
        --cm 'L00DE/${base}' -E '^#\h+.*' \
        --cm '${base}D' -E '\*\*.*?\*\*' \
        file.md

#### Text Folding

The second stage wraps long lines in list items using [ansifold(1)](http://man.he.net/man1/ansifold)
via [Greple::tee](https://metacpan.org/pod/Greple%3A%3Atee).  It preserves ANSI escape sequences and maintains
proper indentation for nested lists.

The folding width is controlled by `--width` option (default: 80).

#### Table Formatting

The third stage formats Markdown tables using [ansicolumn(1)](http://man.he.net/man1/ansicolumn).
Tables are detected by the pattern `^(\|.+\|\n){3,}` and formatted
with aligned columns while preserving ANSI colors.

### Output Stage

The final stage uses [nup(1)](http://man.he.net/man1/nup) to provide multi-column paged output.
Layout options (`--pane`, `--row`, `--grid`, `--page`) are passed
directly to nup.

## Theme System

**mdee** implements a theme system with light and dark mode variants.

### Theme Structure

Each theme is defined as a Bash associative array with color
definitions for each Markdown element:

    declare -A theme_default_dark=(
        [base]='#CCCDFF'
        [h1]='L00DE/${base}'
        [h2]='L00DE/${base}-l10'
        ...
    )

#### Base Color Expansion

The `${base}` placeholder in color values is expanded after theme
loading.  This allows derived colors to be calculated from a single
base color, making theme customization easier.

#### Terminal Mode Detection

**mdee** uses [Getopt::EX::termcolor](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3Atermcolor) to detect terminal background
luminance.  If luminance is below 50%, dark mode is automatically
selected.

# LIMITATIONS

## HTML Comments

Only HTML comments starting at the beginning of a line are highlighted.
Inline comments are not matched to avoid conflicts with inline code
containing comment-like text (e.g., `` `<!-->` ``).

## Emphasis

Emphasis patterns (bold and italic) do not span multiple lines.
Multi-line emphasis text is not supported.

## Links

Link patterns do not span multiple lines.  The link text and URL must
be on the same line.

Reference-style links (`[text][ref]` with `[ref]: url` elsewhere)
are not supported.

## OSC 8 Hyperlinks

Links are converted to OSC 8 terminal hyperlinks for clickable URLs.
This requires terminal support.  Compatible terminals include iTerm2,
Kitty, WezTerm, Ghostty, and recent versions of GNOME Terminal.
Apple's default Terminal.app does not support OSC 8.

When using `less` as pager, version 566 or later is required with
`-R` option.

# SEE ALSO

[nup(1)](http://man.he.net/man1/nup), [greple(1)](http://man.he.net/man1/greple), [ansifold(1)](http://man.he.net/man1/ansifold), [ansicolumn(1)](http://man.he.net/man1/ansicolumn)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2026 Kazumasa Utashiro.

This software is released under the MIT License.
[https://opensource.org/licenses/MIT](https://opensource.org/licenses/MIT)
