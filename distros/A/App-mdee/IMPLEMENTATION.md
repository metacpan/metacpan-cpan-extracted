# Implementation of em·dee

This describes how `mdee` works inside.  For the usage, see the
[manual](README.md).

**em·dee** is implemented as a Bash script that orchestrates multiple
specialized tools into a unified pipeline.  The architecture follows
Unix philosophy: each tool does one thing well, and they communicate
through standard streams.

The overall data flow is:

    Input File
        |
        v
    [greple -Mmd] --- Syntax Highlighting + Table Formatting + Text Folding
        |
        v
    [nup] --- Paged Output (nup style)
        |         or
    [pager] --- Pager Output (pager style)
        |
        v
    Terminal

With `-T` and a paper, or `-o` and a file ending with `.pdf`, nup
gives its output to ansi2pdf in place of the pager:

    [greple -Mmd] --> [nup] --> [ansi2pdf] --> PDF

## Pipeline Architecture

**em·dee** dynamically constructs a pipeline based on enabled options.
Each stage is defined as a Bash function (e.g., `run_greple`,
`run_nup`).  The `--dryrun` option prints the command line of
each stage without running them, and `-d` prints the stage names.

### Processing Stages

The pipeline consists of configurable stages.  Processing options
can be enabled or disabled independently using `--[no-]refill`,
`--[no-]fold`, `--[no-]table`, and `--[no-]nup` options.

#### Syntax Highlighting

The first stage uses [greple(1)](https://metacpan.org/pod/App%3A%3AGreple) with the `--filter`
option, which sets `--all --need=0 --exit=0` to run as a filter
without requiring pattern arguments.  Syntax highlighting is handled
entirely by the `-Mmd` module.

Supported Markdown elements:

- Headers (`# h1` through `###### h6`)
- Bold text (`**bold**` or `__bold__`)
- Italic text (`*italic*` or `_italic_`)
- Inline code (`` `code` ``)
- Code blocks (fenced with ```` ``` ```` or `~~~`)
- Front matter (TOML between `+++` lines, YAML between `---`
lines), shown as a code block
- HTML comments (`<!-- comment -->`)

Code block detection follows the CommonMark specification:

- Opening fence: 0-3 spaces indentation, then 3+ backticks or tildes
- Closing fence: 0-3 spaces indentation, same character, same or more count
- Backticks and tildes cannot be mixed (```` ``` ```` must close with ```` ``` ````)

#### Paragraph Refill

With `--refill`, the [App::Greple::md](https://metacpan.org/pod/App%3A%3AGreple%3A%3Amd) module joins the lines of
each paragraph before anything else.  It asks a Markdown parser
([App::Greple::md::Blocks](https://metacpan.org/pod/App%3A%3AGreple%3A%3Amd%3A%3ABlocks): the [CommonMark](https://metacpan.org/pod/CommonMark) module,
[Markdown::Perl](https://metacpan.org/pod/Markdown%3A%3APerl), or [pandoc](https://pandoc.org) with the
`sourcepos` extension) which
lines of the text form a paragraph, a block quote, a list item or a
definition, and joins those lines in the original text.  A line that
starts a footnote definition (`[^name]:`) stays on its own line.  The
joined lines are folded like list items.

#### Text Folding

Text folding is handled within the [App::Greple::md](https://metacpan.org/pod/App%3A%3AGreple%3A%3Amd) module
using [Greple::tee](https://metacpan.org/pod/Greple%3A%3Atee) to pipe matched regions through
[ansifold(1)](https://metacpan.org/pod/App%3A%3Aansifold).  It preserves ANSI escape sequences
and maintains proper indentation for nested lists.  List items,
definition lists and the paragraphs joined by `--refill` are
folded; code blocks, front matter, HTML comments, and tables are
excluded.

Recognized list markers include `*`, `+`, `-`, `1.`, `1)`, `#.`,
and `#)`.  The `#` marker is the auto-numbered list of Pandoc's Markdown.

The folding width is controlled by `--fold-width` option (default: the
pane width minus 3 and the run-in width, 78 for a pane of 85).

#### Table Formatting

Table formatting is handled within the [App::Greple::md](https://metacpan.org/pod/App%3A%3AGreple%3A%3Amd) module
(after syntax highlighting, before output).  Markdown tables are
detected by the pattern `^ {0,3}(\|.+\|\n){3,}` and formatted with
aligned columns using [ansicolumn(1)](https://metacpan.org/pod/App%3A%3Aansicolumn) while
preserving ANSI colors.

Column alignment is parsed from the separator line: `:---` (left,
default), `:---:` (center), `---:` (right).  The `parse_separator()`
function extracts alignment markers and passes `--table-right` and
`--table-center` options to [ansicolumn(1)](https://metacpan.org/pod/App%3A%3Aansicolumn) (requires
version 1.61 or later).  Colons are stripped from the separator line
before further processing.

When `--rule` is enabled (default), ASCII pipe characters are replaced
with Unicode box-drawing characters (`│`, `├`, `┤`, `┼`, `─`).

### Output Stage

The final stage uses [nup(1)](https://metacpan.org/pod/App%3A%3Anup) to provide multi-column paged output.
Layout options (`--pane`, `--row`, `--grid`, `--page`) are passed
directly to nup.

The device (`-T`) and the output file (`-o`) are passed to nup as
well.  When either is given, mdee first runs nup with `--geometry`,
which prints the columns and the lines of the device and its kind,
`tty` or `pdf`.  For `pdf`, the columns of the paper take the place
of the terminal width in the calculation of the panes and the fold
width, and the mode is light.  nup then runs
[ansi2pdf](https://github.com/tecolicom/App-ansi2pdf) in place of
the pager, which makes the PDF.

## Theme System

**em·dee** implements a theme system where themes are transformations
applied to the built-in default theme.  Multiple themes can be
chained via `--theme=NAME1,NAME2,...`.

### Theme Structure

Color definitions are managed by the [App::Greple::md](https://metacpan.org/pod/App%3A%3AGreple%3A%3Amd) module.
The `theme_light` and `theme_dark` arrays contain only the base
color.  Theme files can modify the base color and pass configuration
to the md module via `md_config[]`:

    # theme/warm.sh — change base color
    theme_light[base]='<Coral>=y25'
    theme_dark[base]='<Coral>=y80'

    # theme/hashed.sh — enable closing hashes
    md_config+=(hashed.h3=1 hashed.h4=1 hashed.h5=1 hashed.h6=1)

The `md_config[]` entries are passed as config parameters to the
[App::Greple::md](https://metacpan.org/pod/App%3A%3AGreple%3A%3Amd) module.  Color labels (`h1`, `bold`, etc.)
can also be set as config parameters:

    # theme file or config.sh — override color label
    md_config+=(h1='L25D/R;E' bold=RD)

#### Base Color Expansion

The `${base}` placeholder in color values is expanded by the md
module.  The base color is determined by `--base-color` option
(default: RoyalBlue) with automatic luminance adjustment based on
mode (`=y25` for light, `=y80` for dark).

### Color Specifications

Colors are specified using [Term::ANSIColor::Concise](https://metacpan.org/pod/Term%3A%3AANSIColor%3A%3AConcise) format.
The `--colormap` (`--cm`) option maps colors to captured groups.  For example,
`L00D/${base};E` specifies gray foreground on base-colored background.

The color specification supports modifiers:

- `+y10` / `-y10`: Adjust luminance by percentage
- `=y50`: Set absolute luminance
- `D`: Bold, `U`: Underline, `E`: Erase line

### Terminal Mode Detection

**em·dee** uses [Getopt::EX::termcolor](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3Atermcolor) to detect terminal background
luminance.  If luminance is below 50%, dark mode is automatically
selected.  The environment variable `TERM_LUMINANCE` gives the
luminance without the detection (see "Terminal Luminance" in the [manual](README.md#terminal-luminance)).
