# -*- mode: perl; coding: utf-8 -*-
# vim: set fileencoding=utf-8 filetype=perl :
package App::Greple::md;

use 5.026;
use warnings;
use utf8;

our $VERSION = "1.18";

=encoding utf-8

=head1 NAME

App::Greple::md - Greple module for Markdown syntax highlighting

=head1 SYNOPSIS

    greple -Mmd file.md

    greple -Mmd --mode=dark -- file.md

    greple -Mmd --base-color=Crimson -- file.md

    greple -Mmd --cm h1=RD -- file.md

    greple -Mmd --no-table -- file.md

    greple -Mmd --fold -- file.md

    greple -Mmd -- --fold file.md

    greple -Mmd --refill -- file.md

=head1 DESCRIPTION

B<App::Greple::md> is a L<greple|App::Greple> module for viewing
Markdown files in the terminal with syntax highlighting.

It colorizes headings, bold, italic, strikethrough, inline code,
fenced code blocks, front matter, HTML comments, blockquotes, horizontal rules,
links, and images.  Tables are formatted with aligned columns and
optional Unicode box-drawing borders.  Long lines in list items can
be folded with proper indentation.  Links become clickable via OSC 8
terminal hyperlinks in supported terminals.

Nested elements are handled with cumulative coloring: for example,
a link inside a heading retains both its link color and the heading
background color.

For a complete Markdown viewing experience with line folding,
multi-column output, and themes, see L<App::mdee>, which uses this
module as its highlighting engine.

Control characters and escape sequences in the file, which could change
the title or the clipboard or clear the screen, are removed before
anything else, and so are not shown.  Colors stay.

=head1 COMMAND OPTIONS

The following options are defined as greple command options
(specified after C<-->).

=head2 B<--fold>

Enable text folding for list items, definition lists, block quotes
and the paragraphs joined by C<--refill>.  Long lines are wrapped
with proper indentation using L<ansifold(1)|App::ansifold> via
L<Greple::tee>; the continuation lines of a block quote start with
the quote marker again.
Code blocks, front matter, HTML comments, and tables are
excluded from folding.  The fold width is controlled by the
C<fold_width> config parameter (default: 80), and the run-in and
run-out widths for line breaking (kinsoku) by C<fold_runin> and
C<fold_runout> (default: 4, as in ansifold).

    greple -Mmd -- --fold file.md
    greple -Mmd::config(fold_width=60) -- --fold file.md

Supported list markers: C<*>, C<+>, C<->, C<1.>, C<1)>, C<#.>, C<#)>.

The module option C<--fold> (before C<-->) enables the same folding
through the config.

=head1 MODULE OPTIONS

Module options are specified before C<--> to separate them from
greple's own options:

    greple -Mmd --mode=dark --cm h1=RD -- file.md

=head2 B<-m> I<MODE>, B<--mode>=I<MODE>

Set color mode.  Available modes are C<light> (default) and C<dark>.

    greple -Mmd -m dark -- file.md

=head2 B<-B> I<COLOR>, B<--base-color>=I<COLOR>

Override the base color used for headings, bold, links, and other
elements.  Accepts a named color (e.g., C<Crimson>, C<DarkCyan>) or a
L<Term::ANSIColor::Concise> color spec.

    greple -Mmd -B Crimson -- file.md

=head2 B<--[no-]colorize>

Enable or disable syntax highlighting.  Enabled by default.
When disabled, no color is applied to Markdown elements.

    greple -Mmd --no-colorize -- file.md

=head2 B<--[no-]fold>

Enable or disable text folding (config C<fold>).  Disabled by default.
When enabled, long lines in list items, definition lists, block
quotes and the paragraphs joined by C<--refill> are wrapped with
proper indentation.
The fold width is controlled by the C<fold_width> config parameter
(default: 80).

    greple -Mmd --fold -- file.md
    greple -Mmd::config(fold=1,fold_width=60) file.md

The greple command option of the same name, C<--fold> after C<-->,
folds the same lines once without setting the config.

=head2 B<--[no-]refill>

Join the lines of paragraphs into one line each (see L</Paragraph
Refill>).  Disabled by default.

=head2 B<--[no-]table>

Enable or disable table formatting.  When enabled (default),
Markdown tables (3 or more consecutive pipe-delimited rows) are
formatted with aligned columns using L<App::ansicolumn>.

    greple -Mmd --no-table -- file.md

=head2 B<--[no-]rule>

Enable or disable Unicode box-drawing characters for table borders.
When enabled (default), ASCII pipe characters (C<|>) are replaced
with vertical lines (C<E<0x2502>>), and separator row dashes become
horizontal rules (C<E<0x2500>>) with corner pieces (C<E<0x251C>>,
C<E<0x2524>>, C<E<0x253C>>).

    greple -Mmd --no-rule -- file.md

=head2 B<--colormap> I<LABEL>=I<SPEC>, B<--cm> I<LABEL>=I<SPEC>

Override the color for a specific element.  I<LABEL> is one of
the color labels listed in L</COLOR LABELS>.  I<SPEC> follows
L<Term::ANSIColor::Concise> format and supports C<sub{...}>
function specs via L<Getopt::EX::Colormap>.

    greple -Mmd --cm h1=RD -- file.md
    greple -Mmd --cm bold='${base}D' -- file.md

B<greple> has an option of the same name.  Before C<-->, C<--cm> belongs
to this module and takes the labels above.  After C<-->, or when there
is no C<-->, it is the option of B<greple>, which colors the matched
text and its own labels such as C<FILE>, and complains about the labels
of this module:

    greple -Mmd --cm h1=RD -- --cm B -E foo file.md  # h1 is red, foo blue
    greple -Mmd --cm h1=RD file.md                   # h1: Unknown label

=head2 B<--begin> I<FUNCTION>

Call I<FUNCTION> on the whole text of each file, in C<$_>, before this
module does anything to it, so that the tables and the folded lines
follow the change.  I<FUNCTION> is a C<sub{...}> or the name of a
function, as C<&func(key=value)> or C<&Package::func(key=value)>.  A
name without a package is looked for in C<main>, and then in the module
C<App::Greple::md::func>, named after the function.  The package is
loaded if the function is not defined yet.  A function that is not found
is reported with a warning and skipped.  The option can be repeated.

    greple -Mmd --begin 'sub{ s/\(C\)/\x{A9}/g }' -- file.md

Unlike the C<--begin> of B<greple> after C<-->, which runs after this
module, this one runs before it.  In a configuration file or a theme of
L<mdee>, it is given as C<pass_md+=(--begin '...')>.

L<App::Greple::md::widen> has such a function, C<&widen>.

=head2 B<--heading-markup>[=I<STEPS>], B<--hm>[=I<STEPS>]

Control inline markup processing inside headings.  By default,
headings are rendered with uniform heading color without processing
bold, italic, strikethrough, or inline code inside them.  Links
are always processed as OSC 8 hyperlinks regardless of this option.

Without an argument, all inline formatting becomes visible within
headings using cumulative coloring.  With an argument, only the
specified steps are processed inside headings.  Steps are separated
by colons.

Available steps: C<inline_code>, C<horizontal_rules>, C<bold>,
C<italic>, C<strike>.

    greple -Mmd --hm -- file.md                  # all markup
    greple -Mmd --hm=bold -- file.md              # bold only
    greple -Mmd --hm=bold:italic -- file.md       # bold and italic

=head2 B<--hashed> I<LEVEL>=I<VALUE>

Append closing hashes to headings.  For example, C<### Title>
becomes C<### Title ###>.  Set per heading level:

    greple -Mmd --hashed h3=1 --hashed h4=1 -- file.md

=head2 B<--show> I<LABEL>[=I<VALUE>]

Control which elements are highlighted.  This is useful for
focusing on specific elements or disabling unwanted highlighting.

    greple -Mmd --show bold=0 -- file.md          # disable bold
    greple -Mmd --show all= --show h1 -- file.md  # only h1

C<--show LABEL=0> or C<--show LABEL=> disables the label.
C<--show LABEL> or C<--show LABEL=1> enables it.
C<all> is a special key that sets all labels at once.

Controllable labels: C<bold>, C<italic>, C<strike>, C<code_inline>,
C<header> (h1-h6), C<horizontal_rule>, C<blockquote>.

The following elements are always processed and cannot be disabled:
C<comment>, C<code_block> (C<code_mark>, C<code_info>),
C<link>, C<image>, C<image_link>.
Use C<--cm LABEL=> to remove their color without disabling processing.

=head1 CONFIGURATION

Module parameters can also be set using the C<config()> function
in the C<-M> declaration:

    greple -Mmd::config(mode=dark,base_color=Crimson) file.md

Nested hash parameters use dot notation:

    greple -Mmd::config(hashed.h3=1,hashed.h4=1) file.md

Available parameters:

    mode            light or dark (default: light)
    base_color      base color override
    colorize        syntax highlighting (default: 1)
    fold            text folding (default: 0)
    fold_width      fold width in columns (default: 80)
    fold_runin      run-in width in folded lines (default: 4)
    fold_runout     run-out width in folded lines (default: 4)
    refill          join the lines of paragraphs (default: 0)
    refill_parser   cmark (the CommonMark module), mdperl (Markdown::Perl)
                    or pandoc (default: the first that is there, in
                    that order)
    front_matter    show TOML and YAML front matter as a code block
                    and leave it alone with refill (default: 1)
    table           table formatting (default: 1)
    table_trim      trim cell whitespace (default: 1)
    table_width     table width in columns; cells of over-wide
                    columns are wrapped (default: 0 = off)
    table_cell      per-column widths passed to ansicolumn --cell,
                    colon separated (e.g. 0:10:<20)
    table_wrap_mark string put at the start of continuation lines
                    of wrapped cells (default: none)
    table_cell_mark string put at the start of the first line of
                    every body cell in a column that has a wrapped
                    cell (default: none)
    table_runin     run-in width in wrapped cells (default: 2)
    table_runout    run-out width in wrapped cells (default: 2)
    table_boundary  fold boundary in wrapped cells (default: word)
    table_linebreak line break mode in wrapped cells: none, runin,
                    runout or all (default: all)
    table_style     lattice: column separators (default; pipe is
                    another name); 3line: columns separated by spaces,
                    a rule above and below the table and per column
                    below the header; simple: columns separated by
                    spaces, a rule per column below the header and
                    below the table
    rule            box-drawing characters (default: 1)
    osc8            OSC 8 hyperlinks (default: 1)
    heading_markup  inline markup in headings (default: 0)
                    0=off, 1/all=all, or colon-separated steps
    cjk_friendly    markdown-cjk-friendly rules for * and **
                    emphasis (default: 0)
    tick_open       inline code open marker (default: `)
    tick_close      inline code close marker (default: ´)
    nofork          nofork+raw mode for code ref calls (default: 1)
    hashed.h1-h6    closing hashes per level (default: 0)

=head2 Paragraph Refill

With C<refill=1>, the lines of every paragraph, block quote, list
item and definition are joined into one line before the text is
colorized.  Which lines belong together is decided by a Markdown
parser (L<App::Greple::md::Blocks>): the L<CommonMark> module, an
interface to libcmark, when it is installed, otherwise
L<Markdown::Perl>, which is pure Perl and always installed with this
module, or L<pandoc|https://pandoc.org> (2.11.3 or later) run with the
C<sourcepos> extension; C<refill_parser> chooses one.  The module
joins the lines of the original text and changes nothing else.  Hard
line breaks are kept, and so is the break before a list marker, a
horizontal rule, a table row or a definition (C<: >).  When folding
is enabled, the joined lines are folded too.

Front matter (see L</Front Matter>) is left as it is.

    greple -Mmd::config(refill=1) file.md
    greple -Mmd::config(refill=1,refill_parser=pandoc) file.md

=head2 Front Matter

Front matter at the top of the file is shown as a code block: the
body in C<meta_block> and the delimiter lines in C<meta_mark>, with
no other markup, and it is not folded or joined.
TOML front matter is between C<+++> lines, and YAML front matter goes
from a C<---> line to a C<---> or C<...> line, as pandoc takes it (the
opening line is not followed by a blank line).

Front matter is not part of CommonMark.  pandoc and L<Markdown::Perl>
take YAML front matter as metadata, while libcmark reads it as a rule,
paragraphs and list items.  C<front_matter=0> takes the lines as
Markdown, as libcmark does.

=head2 OSC 8 Hyperlinks

Links are converted to clickable OSC 8 terminal hyperlinks in
supported terminals (iTerm2, Kitty, WezTerm, Ghostty, etc.).
Disable with:

    greple -Mmd::config(osc8=0) file.md

=head2 Settings of the User

The module runs B<ansifold> and B<ansicolumn> for folding and tables.
They are run as functions in the greple process, or as separate
processes with C<nofork=0>, and either way they do not read the rc
files of the user, F<~/.ansifoldrc> and F<~/.ansicolumnrc>: the
module puts their names in the environment variable
C<GETOPTEX_NO_USER_SETTINGS> (see L<Getopt::EX::Long>), so that the
output does not change by the settings made for them on the command
line.

=head1 COLOR LABELS

The following labels identify colorizable elements.  Use them
with C<--colormap> (C<--cm>) to customize colors or C<--show> to control
visibility.  Default values are shown as C<light / dark>.
Colors follow L<Term::ANSIColor::Concise> format.

=head2 Headings

    LABEL   LIGHT                    DARK
    h1      L25D/${base};E           L00D/${base};E
    h2      L25D/${base}+y20;E       L00D/${base}-y15;E
    h3      L25DN/${base}+y20        L00DN/${base}-y15
    h4      ${base}UD                ${base}UD
    h5      ${base}UD                ${base}UD
    h6      ${base}D                 ${base}D

=head2 Inline Formatting

    LABEL           LIGHT   DARK
    bold            D
    italic          I
    strike          X
    emphasis_mark   L18     L10
    bold_mark       -       -
    italic_mark     -       -
    strike_mark     -       -

Emphasis markers (C<**>, C<*>, C<__>, C<_>, C<~~>) are colored with
C<emphasis_mark>, separately from the content text.  C<bold_mark>,
C<italic_mark>, C<strike_mark> are undefined by default and fall back
to C<emphasis_mark>.  Define them via C<--cm> to override per type:

    greple -Mmd --cm emphasis_mark=R -- file.md    # all markers red
    greple -Mmd --cm bold_mark=G -- file.md        # bold markers green

C<*> and C<**> start and end emphasis as in CommonMark: a delimiter
next to a letter on one side and punctuation on the other does not
count, so C<L*=50, a*=68> is not italic.  In Japanese text this also
rejects C<日本語の*「強調」*です> and C<日本語の**強調。**です>, as the
commonmark and gfm readers of pandoc do.  With C<cjk_friendly=1>,
the rules of
L<markdown-cjk-friendly|https://github.com/tats-u/markdown-cjk-friendly>
are used instead, and these are emphasis.

=head2 Code

    LABEL        LIGHT              DARK
    code_mark    L20                L10
    code_tick    L15/L23            L15/L05
    code_info    ${base_name}=y70   L10
    code_block   /L23;E             /L05;E
    code_inline  L00/L23            L25/L05
    meta_mark    L15/L10E           L10/L15E
    meta_block   L25/L12E           L00/L13E

Inline code backticks are displayed as C<`contentE<0xb4>> using
C<code_tick> color.  Multi-backtick delimiters are collapsed to a
single pair with optional surrounding spaces stripped (per CommonMark).
The open/close markers can be customized via C<tick_open>/C<tick_close>
config parameters.

C<meta_mark> and C<meta_block> color the delimiter lines and the
body of front matter (see L</Front Matter>), the delimiter lines in
the background of the file name and the body a little apart from it.
When they are set to empty, C<meta_block> falls back to C<code_block>,
and the delimiter lines are in C<code_mark> inside the color of the
body.

=head2 Block Elements

    LABEL            LIGHT / DARK
    blockquote       ${base}
    horizontal_rule  L15
    comment          ${base}+r60

=head2 Links

    LABEL        LIGHT / DARK
    link         I
    image        I
    image_link   I
    link_mark    -       -

C<link_mark> colors the brackets (C<[>, C<]>) around link and image
text.  Undefined by default, falls back to C<emphasis_mark>.
The C<!> prefix for images uses the C<image> or C<image_link>
color.  Hide brackets with C<--cm 'link_mark=sub{""}'> (used by
the C<nomark> theme).

=head1 SEE ALSO

=over 4

=item L<App::mdee>

Markdown viewer command with line folding, table formatting,
multi-column layout, and themes.  Uses this module for syntax
highlighting.

=item L<App::Greple>

General-purpose extensible grep tool that hosts this module.

=item L<Term::ANSIColor::Concise>

Concise ANSI color specification format used for color labels.

=item L<App::ansicolumn>

ANSI-aware column formatting used for table alignment.

=item L<App::ansifold>

ANSI-aware text folding used for line wrapping in list items.

=item L<App::Greple::md::widen>

A function for B<--begin>, for characters that terminals draw over two
columns.

=item L<App::Greple::md::Blocks>

Finds the paragraphs for C<refill=1> with L<CommonMark>,
L<Markdown::Perl> or L<pandoc|https://pandoc.org>.

=item L<CommonMark Spec 0.31.2, Emphasis and strong emphasis|https://spec.commonmark.org/0.31.2/#emphasis-and-strong-emphasis>

The rules that C<*> and C<**> follow by default.

=item L<CommonMark CJK-friendly Amendments|https://github.com/tats-u/markdown-cjk-friendly/blob/main/specification.md>

The rules that C<cjk_friendly=1> follows.  The proposal comes from
L<commonmark-spec issue #650, Emphasis with CJK punctuation|https://github.com/commonmark/commonmark-spec/issues/650>,
open since 2020.

=back

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2025-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use URI::Escape;
use Text::ANSI::Fold qw($csi_re $osc_re);
use Text::ANSI::Fold::Util qw(ansi_width);
use Getopt::EX::Config;
use Getopt::EX::Colormap;
use Getopt::EX::Func qw(parse_func);
use App::Greple::Common qw(FILELABEL);
use App::Greple::Regions qw(match_regions);
use App::Greple::md::Blocks qw(blocks);

my @color_labels = qw(
    code_mark code_tick code_info code_block code_inline
    meta_mark meta_block
    comment link image image_link
    h1 h2 h3 h4 h5 h6
    bold italic strike emphasis_mark
    bold_mark italic_mark strike_mark link_mark
    blockquote horizontal_rule
);

my $config = Getopt::EX::Config->new(
    mode            => '',       # light / dark
    osc8            => 1,        # OSC 8 hyperlinks
    base_color      => '',       # override base color
    colorize        => 1,        # syntax highlighting
    fold            => 0,        # text folding
    refill          => 0,        # join the lines of paragraphs
    refill_parser   => '',       # cmark (CommonMark module), mdperl (Markdown::Perl) or pandoc; '' = whichever is there
    front_matter    => 1,        # front matter (+++ TOML, --- YAML) at the top is a code block
    fold_width      => 80,       # fold width
    fold_runin      => 4,        # run-in width in folded lines (ansifold default)
    fold_runout     => 4,        # run-out width in folded lines (ansifold default)
    table           => 1,        # table formatting
    table_trim      => 1,        # trim cell content whitespace
    table_width     => 0,        # table width; wrap over-wide cells (0 = off)
    table_cell      => '',       # per-column widths for ansicolumn --cell (colon separated)
    table_wrap_mark => '',       # mark for continuation lines of wrapped cells
    table_cell_mark => '',       # mark for the first line of cells in wrapped columns
    table_runin     => 2,        # run-in width in wrapped cells
    table_runout    => 2,        # run-out width in wrapped cells
    table_boundary  => 'word',   # fold boundary in wrapped cells
    table_linebreak => 'all',    # line break (kinsoku) mode in wrapped cells
    rule            => 1,        # box-drawing characters for tables
    table_style     => 'lattice', # lattice (or pipe): column separators; 3line, simple: spaces and rules only
    nofork          => 1,        # use nofork+raw for code ref calls
    heading_markup  => 0,        # inline formatting in headings
    cjk_friendly    => 0,        # markdown-cjk-friendly rules for * and ** emphasis
    tick_open       => '`',      # inline code open marker
    tick_close      => "\x{b4}", # inline code close marker (´)
    hashed          => { h1 => 0, h2 => 0, h3 => 0, h4 => 0, h5 => 0, h6 => 0 },
    (map { $_ => undef } @color_labels),  # color labels (undef = not set)
);

#
# Color definitions
#

my %base_color = (
    light => '<RoyalBlue>=y25',
    dark  => '<RoyalBlue>=y80',
);

my %default_colors = (
    code_mark       => 'L20',
    code_tick       => 'L15/L23',
    code_info       => '${base_name}=y70',
    code_block      => '/L23;E',
    code_inline     => 'L00/L23',
    meta_mark       => 'L15/L10E',
    meta_block      => 'L25/L12E',
    comment         => '${base}+r60',
    link            => 'I',
    image           => 'I',
    image_link      => 'I',
    h1              => 'L25D/${base};E',
    h2              => 'L25D/${base}+y20;E',
    h3              => 'L25DN/${base}+y20',
    h4              => '${base}UD',
    h5              => '${base}UD',
    h6              => '${base}D',
    bold            => 'D',
    italic          => 'I',
    strike          => 'X',
    emphasis_mark   => 'L18',
    blockquote      => '${base}',
    horizontal_rule => 'L15',
);

my %dark_overrides = (
    code_mark       => 'L10',
    code_tick       => 'L15/L05',
    code_info       => 'L10',
    code_block      => '/L05;E',
    code_inline     => 'L25/L05',
    meta_mark       => 'L10/L15E',
    meta_block      => 'L00/L13E',
    h1              => 'L00D/${base};E',
    h2              => 'L00D/${base}-y15;E',
    h3              => 'L00DN/${base}-y15',
    h4              => '${base}UD',
    h5              => '${base}UD',
    h6              => '${base}D',
    emphasis_mark   => 'L10',
);

sub default_theme {
    my $mode = shift // 'light';
    my %colors = %default_colors;
    if ($mode eq 'dark') {
        @colors{keys %dark_overrides} = values %dark_overrides;
    }
    $colors{base} = $base_color{$mode};
    if (defined wantarray) {
        %colors;
    } else {
        # Print as bash array assignments: theme_MODE[key]='value'
        for my $key (sort keys %colors) {
            (my $val = $colors{$key}) =~ s/'/'\\''/g;
            printf "theme_%s[%s]='%s'\n", $mode, $key, $val;
        }
    }
}

my $cm;
my @opt_cm;
my @opt_begin;
my %show;

sub finalize {
    my($mod, $argv) = @_;
    no_user_settings(qw(ansicolumn ansifold));
    $config->deal_with($argv,
                       "mode|m=s", "base_color|B=s",
                       "colorize!", "nofork!", "fold!", "refill!", "refill_parser=s", "front_matter!", "fold_width=i", "fold_runin=i", "fold_runout=i",
                       "table!", "table_trim!",
                       "table_width=i", "table_cell=s", "table_wrap_mark=s", "table_cell_mark=s", "rule!", "table_style=s",
                       "table_runin=i", "table_runout=i", "table_boundary=s", "table_linebreak=s",
                       "heading_markup|hm:s", "cjk_friendly!", "tick_open=s", "tick_close=s",
                       "hashed=s%",
                       "colormap|cm=s" => \@opt_cm,
                       "begin=s" => \@opt_begin,
                       "show=s%" => \%show);
    # --hm with no argument gives "": treat as "all"
    my $hm = $config->{heading_markup};
    if (defined $hm && $hm eq '') {
        $config->{heading_markup} = 'all';
    }
    if (my $w = $config->{fold_width}) {
        my $fold = join ' ', '--fold-by', $w, @{$config}{qw(fold_runin fold_runout)};
        $mod->setopt('--fold', $fold);
        if ($config->{fold}) {
            my @default = $mod->default;
            $mod->setopt('default', @default, $fold);
        }
    }
}

# ansicolumn and ansifold are called as functions in this process
# (Command::Run), or as separate processes by the tee module in fork
# mode.  Either way they must not read the rc files of the user, so
# their names go into GETOPTEX_NO_USER_SETTINGS (Getopt::EX >= 3.05),
# which Getopt::EX::Long reads when the program first runs.  Names
# already there are kept, and 1 or * (all programs) is left as it is.
sub no_user_settings {
    my @names = @_;
    my $env = $ENV{GETOPTEX_NO_USER_SETTINGS} // '';
    return if $env eq '1' or $env eq '*';
    my %have = map { $_ => 1 } split /[\s,]+/, $env;
    $ENV{GETOPTEX_NO_USER_SETTINGS} =
	join ' ', grep { length } $env, grep { !$have{$_}++ } @names;
}

sub setup_colors {
    my $mode = $config->{mode} || 'light';
    my %colors = %default_colors;
    if ($mode eq 'dark') {
        @colors{keys %dark_overrides} = values %dark_overrides;
    }
    # Determine base color
    my $base = $config->{base_color};
    if ($base) {
        # Color names get automatic luminance adjustment
        $base = "<$base>" . ($mode eq 'dark' ? '=y80' : '=y25')
            if $base =~ /^[A-Za-z]\w*$/;
    } else {
        $base = $base_color{$mode} || $base_color{light};
    }
    # Override with config params (e.g., config(h1=RD))
    for my $key (@color_labels) {
        my $val = $config->{$key};
        if (defined $val) {
            $colors{$key} = $val;
        }
    }
    # ${base_name}: color without luminance (e.g., '<RoyalBlue>')
    (my $base_name = $base) =~ s/=y\d+$//;
    # Expand placeholders
    for my $key (keys %colors) {
        $colors{$key} =~ s/\$\{base_name\}/$base_name/g;
        $colors{$key} =~ s/\$\{base\}/$base/g;
    }
    # Handle + prefix: prepend current color value before load_params
    # (load_params' built-in + doesn't work correctly with sub{...})
    my @final_cm;
    for my $entry (@opt_cm) {
        my $expanded = $entry =~ s/\$\{base_name\}/$base_name/gr
                              =~ s/\$\{base\}/$base/gr;
        if ($expanded =~ /^(\w+)=\+(.*)/) {
            my ($label, $append) = ($1, $2);
            my $current = $colors{$label} // '';
            push @final_cm, "$label=$current$append";
        } else {
            push @final_cm, $expanded;
        }
    }

    $cm = Getopt::EX::Colormap->new(
        HASH => \%colors,
        NEWLABEL => 1,
    );
    $cm->load_params(@final_cm);
}

sub active {
    my $label = shift;
    return 0 if exists $show{$label} && !$show{$label};
    return 1 unless exists $cm->{HASH}{$label};
    $cm->{HASH}{$label} ne '';
}

#
# Apply color by label
#

sub md_color {
    my($label, $text) = @_;
    $cm->color($label, $text);
}

sub defined_color {
    my $label = shift;
    exists $cm->{HASH}{$label} && $cm->{HASH}{$label} ne '';
}

# The color of $label, or of $fallback when $label is not defined
sub fallback_color {
    my($label, $fallback, $text) = @_;
    $label = $fallback unless defined_color($label);
    md_color($label, $text);
}

sub mark_color {
    my($type, $text) = @_;
    my $label = "${type}_mark";
    $label = 'emphasis_mark' unless exists $cm->{HASH}{$label}
                                 && $cm->{HASH}{$label} ne '';
    md_color($label, $text);
}

#
# Protection mechanism
#
# SGR 256 placeholders protect processed regions (inline code,
# comments, links) from being matched by later patterns.
#

my @protected;
my($PS, $PE) = ("\e[256m", "\e[m");     # protect start/end markers
my $PR = qr/\e\[256m(\d+)\e\[m/;       # protect restore pattern
my($OS, $OE) = ("\e]8;;", "\e\\");      # OSC 8 start/end markers

sub protect {
    my $text = shift;
    push @protected, $text;
    $PS . $#protected . $PE;
}

sub restore {
    my $s = shift;
    1 while $s =~ s{$PR}{$protected[$1] // die "restore failed: index $1"}ge;
    $s;
}

#
# OSC 8 hyperlink generation
#

sub osc8 {
    return $_[1] unless $config->{osc8};
    my($url, $text) = @_;
    my $escaped = uri_escape_utf8($url, "^\\x20-\\x7e");
    "${OS}${escaped}${OE}${text}${OS}${OE}";
}

#
# Link text inner pattern: backtick spans, backslash escapes, normal chars
#

my $LT = qr/(?:`[^`\n]*+`|\\.|[^`\\\n\]]++)+/;

# Code span pattern (both single and multi-backtick).
# Captures: _bt (backtick delimiter), _content (code body).
# Used directly in inline_code step and as basis for $SKIP_CODE.
my $CODE = qr{(?x)
    (?<_bt> `++ )               # opening backtick(s)
    (?<_content>
        (?: (?! \g{_bt} ) . )+? # content (not containing same-length backticks)
    )
    \g{_bt}                     # closing backtick(s) matching opener
};

# Skip code spans in link/image patterns.
# Used as the first alternative in s{$SKIP_CODE|<link pattern>}{...}ge
# so that code spans are matched and skipped, preventing link/image
# patterns from matching inside them.
my $SKIP_CODE = qr{$CODE (*SKIP)(*FAIL)}x;

# Delimiters of * and ** emphasis (CommonMark 0.31.2, 6.2): an opener
# must be left-flanking and a closer right-flanking, so that
# "L*=50, a*=68" is not italic.  Punctuation is Unicode punctuation and
# symbols.  An opener after $tight (neither a space nor punctuation)
# cannot have punctuation after it, and a closer before $tight cannot
# have punctuation before it.
#
# With cjk_friendly=1 the amendments of markdown-cjk-friendly apply:
# CJK punctuation does not count, and a CJK character is as good as a
# space on the other side, so that "日本語の*「強調」*です" is italic.
# See CLAUDE.md.
my $EMOJI = eval q{ qr/\p{Emoji_Presentation}/ } // qr/(?!)/;  # not in old perl
my $CJK   = qr/(?:(?!$EMOJI)[\p{EA=W}\p{EA=F}\p{EA=H}]|\p{Hangul})/;

sub flanking {
    my $d = quotemeta shift;
    my($punct, $tight) = $config->{cjk_friendly}
        ? (qr/(?!$CJK)[\p{P}\p{S}]/, qr/(?!$CJK)[^\s\p{P}\p{S}]/)
        : (qr/[\p{P}\p{S}]/,         qr/[^\s\p{P}\p{S}]/);
    # A link or a code span is a protect() placeholder by now; its
    # ends stand for the punctuation that delimits it in the text.
    my($ps, $pe) = (qr/\e\[256m/, qr/\e\[m/);
    (qr/(?:(?<!$tight)|(?<=$pe)|(?!$d(?:$punct|$ps)))$d(?=\S)/,
     qr/(?<=\S)(?:(?<!$punct)(?<!$pe)|(?!$d(?!$ps)$tight))$d/);
}

#
# colorize() - the main function
#
# Receives entire file content in $_ (--begin with -G --filter).
# Processes all patterns with multiline regexes.
#

#
# Pipeline step class
#

package App::Greple::md::Step {
    sub new {
        my($class, %args) = @_;
        bless \%args, $class;
    }
    sub label  { $_[0]->{label} }
    sub active { !$_[0]->{label} || App::Greple::md::active($_[0]->{label}) }
    sub run    { $_[0]->{code}->() }
}

sub Step {
    my $code = pop;
    my $label = shift;
    App::Greple::md::Step->new(label => $label, code => $code);
}

#
# Pipeline steps: Step(sub{}) = always active, Step(label => sub{}) = controllable
#

my %colorize = (

    front_matter => Step(sub {
        my $front = front_matter($_) // return;
        my($open, @body) = split /(?<=\n)/, $front;
        my $close = pop @body;
        chomp $open;
        my $block = sub { fallback_color('meta_block', 'code_block', $_[0]) };
        # A delimiter line is in meta_mark alone when it is defined, and
        # otherwise in code_mark inside the block color, so that the
        # background of the block runs over it
        my $mark = defined_color('meta_mark')
            ? sub { md_color('meta_mark', $_[0]) }
            : sub { $block->(md_color('code_mark', $_[0])) };
        substr($_, 0, length $front) = protect(join '',
            $mark->($open), "\n",
            (map { $block->($_) } @body),
            $mark->($close));
    }),

    code_blocks => Step(sub {
        # closing fence: the same character, at least as long (CommonMark)
        s{^( {0,3})((`|~)\3{2,})(.*)\n((?s:.*?))^( {0,3})(\2\3*)(\h*)$}{
            my($oi, $fence, $lang, $body, $ci, $close, $trail) = ($1, $2, $4, $5, $6, $7, $8);
            my $result = md_color('code_mark', "$oi$fence");
            $result .= md_color('code_info', $lang) if length($lang);
            $result .= "\n";
            if (length($body)) {
                $result .= join '', map { md_color('code_block', $_) }
                    split /(?<=\n)/, $body;
            }
            $result .= md_color('code_mark', "$ci$close") . $trail;
            protect($result)
        }mge;
    }),

    comments => Step(sub {
        s/(^<!--(?![->])(?s:.*?)-->)/protect(md_color('comment', $1))/mge;
    }),

    image_links => Step(sub {
        s{$SKIP_CODE|\[!\[(?<text>$LT)\]\((?<img>[^)\n]+)\)\]\(<?(?<url>[^>)\s\n]+)>?\)}{
            protect(
                osc8($+{img}, md_color('image_link', "!"))
                . osc8($+{url}, mark_color('link', "[") . md_color('image_link', $+{text}) . mark_color('link', "]"))
            )
        }ge;
    }),

    images => Step(sub {
        s{$SKIP_CODE|!\[(?<text>$LT)\]\(<?(?<url>[^>)\s\n]+)>?\)}{
            protect(osc8($+{url}, md_color('image', "!") . mark_color('link', "[") . md_color('image', $+{text}) . mark_color('link', "]")))
        }ge;
    }),

    links => Step(sub {
        s{$SKIP_CODE|(?<![!\e])\[(?<text>$LT)\]\(<?(?<url>[^>)\s\n]+)>?\)}{
            protect(osc8($+{url}, mark_color('link', "[") . md_color('link', $+{text}) . mark_color('link', "]")))
        }ge;
    }),

    inline_code => Step(code_inline => sub {
        state $to = $config->{tick_open};
        state $tc = $config->{tick_close};
        s{$CODE}{
            my $content = $+{_content};
            # Strip optional leading/trailing space for multi-backtick (CommonMark)
            $content =~ s/^ (.+) $/$1/ if length($+{_bt}) >= 2;
            protect(md_color('code_tick', $to) . md_color('code_inline', $content) . md_color('code_tick', $tc))
        }ge;
    }),

    headings => Step(header => sub {
        my $hashed = $config->{hashed};
        for my $n (reverse 1..6) {
            next unless active("h$n");
            my $hdr = '#' x $n;
            # up to 3 spaces of indentation; empty headings ("#") too (CommonMark)
            s{^( {0,3}$hdr(?:\h+.*)?)$}{
                my $line = $1;
                $line .= " $hdr"
                    if $hashed->{"h$n"} && $line !~ /\#$/;
                protect(md_color("h$n", restore($line)));
            }mge;
        }
    }),

    horizontal_rules => Step(horizontal_rule => sub {
        s/^([ ]{0,3}(?:[-*_][ ]*){3,})$/protect(md_color('horizontal_rule', $1))/mge;
    }),

    bold_italic => Step(bold => sub {
        s{$SKIP_CODE|(?<!\\)(?<m>\*\*\*)(?<t>.*?)(?<!\\)\g{m}}{
            protect(mark_color('bold', $+{m}) . md_color('bold', md_color('italic', $+{t})) . mark_color('bold', $+{m}))
        }gep;
        s{$SKIP_CODE|(?<![\\\w])(?<m>___)(?<t>.*?)(?<!\\)\g{m}(?!\w)}{
            protect(mark_color('bold', $+{m}) . md_color('bold', md_color('italic', $+{t})) . mark_color('bold', $+{m}))
        }gep;
    }),

    bold => Step(bold => sub {
        my($open, $close) = flanking('**');
        # no opener inside, so that a closer pairs with the nearest opener
        s{$SKIP_CODE|(?<!\\)(?<m>$open)(?<t>(?:(?!$open).)*?)(?<!\\)$close}{
            mark_color('bold', $+{m}) . md_color('bold', $+{t}) . mark_color('bold', $+{m})
        }gep;
        s{$SKIP_CODE|(?<![\\\w])(?<m>__)(?<t>.*?)(?<!\\)\g{m}(?!\w)}{
            mark_color('bold', $+{m}) . md_color('bold', $+{t}) . mark_color('bold', $+{m})
        }gep;
    }),

    italic => Step(italic => sub {
        my($open, $close) = flanking('*');
        s{$SKIP_CODE|(?<![\\\w])(?<m>_)(?<t>(?:(?!_).)+)(?<!\\)\g{m}(?!\w)}{
            mark_color('italic', $+{m}) . md_color('italic', $+{t}) . mark_color('italic', $+{m})
        }gep;
        s{$SKIP_CODE|(?<![\\*])(?<m>$open)(?<t>(?:(?!\*).)+)(?<!\\)$close(?!\*)}{
            mark_color('italic', $+{m}) . md_color('italic', $+{t}) . mark_color('italic', $+{m})
        }gep;
    }),

    strike => Step(strike => sub {
        s{$SKIP_CODE|(?<!\\)(?<m>~~)(?<t>.+?)(?<!\\)\g{m}}{
            mark_color('strike', $+{m}) . md_color('strike', $+{t}) . mark_color('strike', $+{m})
        }gep;
    }),

    blockquotes => Step(blockquote => sub {
        s/^( {0,3})((?:>\h?)+)(.*)$/$1 . md_color('blockquote', $2) . $3/mge;
    }),
);

#
# Pipeline configuration
#

# Always before headings (protection + links)
my @protect_steps = qw(front_matter code_blocks comments image_links images links);

# Inline steps controlled by heading_markup
my @inline_steps  = qw(inline_code horizontal_rules bold_italic bold italic strike);

# Always last
my @final_steps   = qw(blockquotes);

sub build_pipeline {
    my $hm = $config->{heading_markup};

    # heading_markup disabled: headings before all inline steps
    if (!$hm) {
        return (@protect_steps, 'headings', @inline_steps, @final_steps);
    }

    # "all" or "1": all inline steps before headings
    my %before;
    if ($hm eq '1' || $hm =~ /^all$/i) {
        %before = map { $_ => 1 } @inline_steps;
    } else {
        # "bold:italic" → collect word tokens, filter to valid inline steps
        my %valid = map { $_ => 1 } @inline_steps;
        %before = map { $_ => 1 } grep { $valid{$_} } ($hm =~ /(\w+)/g);
    }

    my @before_h = grep {  $before{$_} } @inline_steps;
    my @after_h  = grep { !$before{$_} } @inline_steps;

    return (@protect_steps, @before_h, 'headings', @after_h, @final_steps);
}

sub colorize {
    setup_colors();
    @protected = ();

    for my $name (build_pipeline()) {
        my $step = $colorize{$name};
        $step->run if $step->active;
    }

    $_ = restore($_);
    $_;
}

#
# Table formatting
#

# Regions of formatted tables, used by --fold-by as --exclude so that
# ansifold does not fold them again: three or more lines that contain a
# column separator, in a block that has a separator row.  A line may
# start with a border or rule character, a dash, whitespace, or one of
# the configured marks (a wrapped first column's continuation line starts
# with the wrap mark, and its body rows with the cell mark), so the
# pattern is built from the config at run time rather than in __DATA__.
sub table_regions {
    my %arg = @_;
    delete $arg{&FILELABEL};
    my $marks = join '', map { quotemeta substr $_, 0, 1 }
        grep { length } @{$config}{qw(table_wrap_mark table_cell_mark)};
    my $bar   = "\x{2502}|";                  # column separator  │ |
    my $cross = "\x{253C}";                   # rule crossing     ┼
    my $rule  = "\x{2500}\x{251C}\x{2524}";   # rule line         ─ ├ ┤
    my $row = qr{
        ^ [ $bar \x{251C} \x{2500} $marks \h - ]   # border, rule, mark, pad, or dash
          [^\n]* [ $bar $cross ] [^\n]* \n         # ... with a separator somewhere
    }xxm;
    my $sep = qr{ (?= [^\n]* [ $cross | ] ) [ $rule $cross | - ]+ \n }xx;
    match_regions(pattern => qr/ (?= (?:$row)*? $sep ) (?:$row){3,} /x);
}

#
# Paragraph refill
#

# Join the lines of one paragraph (or list item, quote, definition)
# into a single line.  The rules are those of ansifold's fill_up: the
# line break after a fullwidth punctuation character and between two
# characters of a script written without spaces (CJK) is simply
# removed, any other becomes one space.  A line is left as it is, as
# the start of a new line, when the line before it ends in a hard
# break (two or more spaces, or a backslash), or when it starts with
# a list marker, is a horizontal rule, which pandoc may report as
# part of the paragraph (a "#." list, "Text\n***"), or when either
# line looks like a table row: GFM does not let a table interrupt a
# paragraph, but format_table takes three such lines as a table.
# From the second line on, up to $depth quote markers and the
# indentation are removed before joining.  A CR before the line
# break (CRLF file) goes with the line break.
#
# The character properties are defined as subroutines in App::ansifold
# and looked up when the pattern is compiled, so the patterns are
# built here, after the module is loaded, not at compile time.
sub refill_block {
    my($lines, $depth) = @_;
    state $punct  = do {
        require App::ansifold;
        my $p = "App::ansifold::InFullwidthPunctuation";
        qr/\p{$p}/;
    };
    state $concat = do {
        my $p = "App::ansifold::InConcatScript";
        qr/\p{$p}/;
    };
    my $prefix = qr/^\h*(?:>\h?){0,$depth}\h*/;
    my $marker = qr/^\h*(?:[*+-]|(?:\d+|#)[.)])\h+/;
    my $hr     = qr/^ {0,3}(?:[-*_][ ]*){3,}\r?$/;
    my $row    = qr/^ {0,3}\|.+\|\h*\r?$/;
    my $def    = qr/^\h*:\h/;
    my $note   = qr/$prefix\[\^[^\]\s]+\]:/;
    my $hard   = qr/(?:(?<!\\)(?:\\\\)*\\|(?<! ) {2,})\r?$/;  # odd number of backslashes, or two spaces (the lookbehinds keep it linear)
    my @out;
    for my $line (@$lines) {
        if (!@out or $out[-1] =~ $hard or $out[-1] =~ $row
            or $line =~ $marker or $line =~ $hr or $line =~ $row
            or $line =~ $def or $line =~ $note) {
            push @out, $line;
            next;
        }
        my $text = $line =~ s/$prefix//r;
        $out[-1] =~ s/\r\z//;
        if ($out[-1] =~ /$punct$/) {
            $out[-1] .= $text;
        } elsif ($out[-1] =~ /$concat$/ and $text =~ /^$concat/) {
            $out[-1] .= $text;
        } else {
            $out[-1] =~ s/ +$//;
            $text =~ s/^ +//;
            $out[-1] .= " $text";
        }
    }
    @out;
}

# The line ranges that refill() joined, as [first, last] in the text
# after joining, and the formatted tables, as [first line, lines added],
# both for the current file.  refill_regions() turns them into the
# regions that --fold-by folds.
our @refill_lines;
our @table_shift;

# Front matter at the top of the text: TOML (+++ ... +++) or YAML
# (--- ... --- or ...).  It is not part of CommonMark: pandoc takes TOML
# as a paragraph and YAML as metadata, Markdown::Perl takes YAML as
# metadata, and libcmark takes YAML as paragraphs and list items.  As
# in pandoc, a blank line right after the opening --- makes it a rule.
# Returns the front matter without the line break after its last line,
# or an empty list.  $front_lines is its number of lines, set by
# begin() before the text is changed, for refill and the fold regions.
our $front_lines = 0;
sub front_matter {
    $config->{front_matter} or return;
    $_[0] =~ m{
        \A (?: \+\+\+ \r?\n (?:[^\n]*\n)*? \+\+\+
             | ---    \r?\n (?!\r?\n) (?:[^\n]*\n)*? (?:---|\.\.\.) )
        \h* \r? (?=\n|\z)
    }px ? ${^MATCH} : ();
}

# The region of the front matter, used by --fold-by as --exclude.  The
# text is colored by then, so the region is found by its line count.
sub front_matter_region {
    my %arg = @_;
    delete $arg{&FILELABEL};
    $front_lines or return ();
    my $pos = 0;
    for (1 .. $front_lines) {
        $pos = index($_, "\n", $pos);
        $pos < 0 and return [ 0, length ];
        $pos++;
    }
    [ 0, $pos ];
}

# Join the lines of every paragraph (Para) and tight list item or
# definition (Plain) in $_, from the bottom up so that the line numbers
# of the blocks above stay valid, and remember where the joined lines
# are in the result.
sub refill {
    @refill_lines = ();
    my @lines = split /\n/, $_, -1;
    my @done;
    my $limit = @lines + 1;
    my $front = $front_lines;
    for my $b (sort { $b->{first} <=> $a->{first} }
               grep { $_->{type} eq 'Para' or $_->{type} eq 'Plain' }
               blocks($_, parser => $config->{refill_parser})) {
        my($first, $last) = @{$b}{qw(first last)};
        # libcmark runs a paragraph on past a closing "..."
        $first = $front + 1 if $first <= $front;
        next if $last < $first or $last >= $limit;
        $limit = $first;
        my @joined = refill_block([ @lines[$first-1 .. $last-1] ], $b->{depth});
        splice @lines, $first-1, $last-$first+1, @joined;
        unshift @done, [ $first, scalar @joined, $last - $first + 1 - @joined ];
    }
    my $shift = 0;
    for my $d (@done) {
        my($first, $count, $removed) = @$d;
        push @refill_lines, [ $first - $shift, $first - $shift + $count - 1 ];
        $shift += $removed;
    }
    $_ = join "\n", @lines;
}

# The lines that refill() joined, one region per line including its
# newline, for --fold-by.  The text has been through colorize(), which
# keeps the number of lines, and format_table(), which does not: the
# tables above a range have added the lines in @table_shift.
sub refill_regions {
    my %arg = @_;
    delete $arg{&FILELABEL};
    return () unless @refill_lines;
    my @start = (0);
    my $pos = 0;
    while (($pos = index($_, "\n", $pos)) >= 0) {
        push @start, ++$pos;
    }
    my $end = length $_;
    my @regions;
    for my $range (@refill_lines) {
        for my $line ($range->[0] .. $range->[1]) {
            my $shift = 0;
            for my $t (@table_shift) {
                $shift += $t->[1] if $t->[0] < $line;
            }
            my $n = $line + $shift;
            last if $n > @start;
            push @regions, [ $start[$n-1], $start[$n] // $end ];
        }
    }
    @regions;
}


# What a file must not send to the terminal: everything but colors, and the
# mark of protect(), which would bring back or look for protected text.
my $STRING = qr{
    (?: \e [PX^_] | [\x90\x98\x9e\x9f] )            # DCS, SOS, PM, APC
    (?: [^\x00-\x07\x0e-\x1f\x7f-\x9f]*+ (?: \e\\ | \x9c | \a ) )?
}x;
my $CONTROLS = qr{
    \e \[ (?! 256m ) [0-9:;]* m (*SKIP)(*FAIL)
  |
    $osc_re
  |
    $STRING
  |
    $csi_re
  |
    \e [\x20-\x2f]* [\x30-\x7e]
  |
    [\x00-\x08\x0b\x0e-\x1f\x7f-\x9f]
}x;

sub remove_controls {
    s/$CONTROLS//g;
}

# Find the function of a --begin option and load its package, so that a
# module does not have to be given with -M ahead of this one.  A name without
# a package is looked for in main, and then as the function name of the
# module App::Greple::md::name.  Returns the option with the full name.  A
# function that does not exist is only reported, and the text is shown
# without it; a module that exists and does not compile is an error.
sub resolve_function {
    my $spec = shift;
    $spec =~ m{ ^ &? (?<name> \w+ (?: :: \w+ )* ) (?<arg> (?= [(=] | $ ) .* ) }xs or return $spec;
    my($name, $arg) = @+{qw(name arg)};
    my @candidate = $name =~ /::/ ? $name : ("main::$name", "App::Greple::md::${name}::$name");
    no strict q(refs);
    for my $func (@candidate) {
        load_package($func =~ s/::\w+$//r) unless defined &$func;
        return "&$func$arg" if defined &$func;
    }
    warn "--begin: $name: function not found\n";
    return;
}

sub load_package {
    my $package = shift;
    return if $package eq q(main);
    my $file = $package =~ s{::}{/}gr . q(.pm);
    return if eval { require $file; 1 };
    die $@ unless $@ =~ /^Can't locate \Q$file\E /;
}

# The functions of --begin, parsed once.  The names belong to main, as
# with the --begin of greple.
sub begin_functions {
    state $func = [ map {
        parse_func({ PACKAGE => 'main' }, $_) or die "$_: function format error\n";
        my $spec = resolve_function($_);
        defined $spec ? parse_func({ PACKAGE => 'main' }, $spec) : ();
    } @opt_begin ];
    @$func;
}

sub begin {
    remove_controls();
    @refill_lines = @table_shift = ();
    for my $func (begin_functions()) {
        $func->call(@_);
    }
    $front_lines = do { my $f = front_matter($_); defined $f ? ($f =~ tr/\n//) + 1 : 0 };
    refill()       if $config->{refill};
    colorize()     if $config->{colorize};
    format_table() if $config->{table};
}

sub format_table {
    # lattice (or pipe) has column separators.  3line and simple have
    # none and a header rule per column: 3line adds a full-width rule
    # above and below, simple the header rule below.  They are formatted
    # as in rule mode and the separators are blanked.
    my $style = $config->{table_style};
    my $open = $style eq '3line' || $style eq 'simple';
    my $sep = ($config->{rule} || $open) ? "\x{2502}" : '|';  # │ or |

    # A row may have spaces after the last pipe (GFM ignores them); they
    # are allowed in the block and removed, so that every row ends in
    # the same column for ansicolumn.
    s{(^ {0,3}\|.+\|\h*\n){3,}}{
        my $block = $& =~ s/\h+$//mgr;
        my $line  = 1 + (substr($_, 0, $-[0]) =~ tr/\n//);
        my $lines = $& =~ tr/\n//;
        my($right, $center) = parse_separator(\$block);
        my @sep_opt;
        # An escaped pipe (\|) is not a column separator (GFM).  It is
        # left as written: backslash escapes are not processed yet.
        if ($config->{table_trim}) {
            @sep_opt = ('-rs', '\s*(?<!\\\\)\|\s*', '--item-format= %s ', '--table-remove=1,-0', '--padding');
        } else {
            $_++ for @$right, @$center;
            @sep_opt = ('-rs', '(?<!\\\\)\|');
        }
        my @align = (
            @$right  ? ('--table-right='  . join(',', @$right))  : (),
            @$center ? ('--table-center=' . join(',', @$center)) : (),
        );
        # Fit table into table_width and/or per-column widths (table_cell).
        # table_cell entries are colon separated because comma separates
        # config parameters; non-trim mode has a phantom first column.
        my @fit;
        if ($config->{table_width} > 0) {
            push @fit, '-w', $config->{table_width};
        }
        if ((my $cell = $config->{table_cell}) ne '') {
            $cell =~ tr/:/,/;
            $cell = "0,$cell" unless $config->{table_trim};
            push @fit, '--cell', $cell;
        }
        if ((my $mark = $config->{table_wrap_mark}) ne '') {
            push @fit, '--table-wrap-mark', $mark;
        }
        if ((my $mark = $config->{table_cell_mark}) ne '') {
            # the header row and the separator row (to ansicolumn a row of
            # "-" cells) are the two header rows and get no mark
            push @fit, '--table-cell-mark', $mark, '--table-head', 2;
        }
        # How cells are wrapped is given explicitly, so that it does not
        # change with the user's ~/.ansicolumnrc
        my @wrap = map { "--$_=" . $config->{"table_$_"} } qw(runin runout boundary linebreak);
        my $formatted = call_ansicolumn($block, @sep_opt, '-o', $sep, '-t', '--cu=1', @align, @fit, @wrap);
        my $table = fix_separator($formatted, $sep);
        if ($open) {
            # blank the column separators and add the rules
            $table =~ tr/\x{2502}\x{253C}\x{251C}\x{2524}/    /;
            if ($style eq '3line') {
                my($first) = $table =~ /^(.*)$/m;
                my $rule = "\x{2500}" x ansi_width($first);
                $table = "$rule\n$table$rule\n";
            } else {
                my($rule) = $table =~ /^([\x{2500} ]+)$/m;
                $table .= "$rule\n" if defined $rule;
            }
            $table =~ s{^[\x{2500} ]+$}{ $& =~ tr/\x{2500}/-/r }mge unless $config->{rule};
        }
        push @table_shift, [ $line, ($table =~ tr/\n//) - $lines ];
        $table;
    }mge;
}

sub parse_separator {
    my $blockref = shift;
    my $SEP = qr/^\h*+\|(\h*+:?+-++:?+\h*+\|)++\h*+$/mn;
    my ($sep_line) = $$blockref =~ /($SEP)/;
    return ([], []) unless defined $sep_line;
    my @cells = split /\|/, $sep_line, -1;
    shift @cells; pop @cells;
    s/^\h+|\h+$//g for @cells;
    my @right  = grep { $cells[$_-1] =~ /^-+:$/  } 1..@cells;
    my @center = grep { $cells[$_-1] =~ /^:-+:$/ } 1..@cells;
    # Minimize dashes so separator width doesn't inflate column widths
    $$blockref =~ s{$SEP}{ ${^MATCH} =~ s/:?-+:?/-/gr }mpe;
    (\@right, \@center);
}

sub call_ansicolumn {
    my ($text, @args) = @_;
    require Command::Run;
    require App::ansicolumn;
    Command::Run->new
        ->command(\&App::ansicolumn::ansicolumn, @args)
        ->with(stdin => $text,
               $config->{nofork} ? (nofork => 1, raw => 1) : ())
        ->update
        ->data // '';
}

sub fix_separator {
    my ($text, $sep) = @_;
    my $sep_re = $sep eq "\x{2502}" ? "\x{2502}" : '\\|';
    $text =~ s{^(\h*?)($sep_re)?((?:\h*-+\h*$sep_re)*\h*-+\h*)($sep_re)?(\h*?)$}{
        my($pre, $left, $mid, $right, $post) = ($1, $2, $3, $4, $5);
        if ($sep eq "\x{2502}") {
            ($pre  =~ tr[ ][\x{2500}]r)
            . (defined $left  ? "\x{251C}" : '')
            . ($mid =~ tr[\x{2502} -][\x{253C}\x{2500}\x{2500}]r)
            . (defined $right ? "\x{2524}" : '')
            . ($post =~ tr[ ][\x{2500}]r)
        } else {
            ($pre  =~ tr[ ][-]r)
            . (defined $left  ? '|' : '')
            . ($mid =~ tr[ ][-]r)
            . (defined $right ? '|' : '')
            . ($post =~ tr[ ][-]r)
        }
    }xmeg;
    $text;
}

1;

__DATA__

option default \
    -G --filter --filestyle=once --color=always \
    --begin &__PACKAGE__::begin

define {CODE_BLOCK}  ^ {0,3}(?<bt>(?<fc>[`~])\g{fc}{2,}+)(.*)\n((?s:.*?))^ {0,3}\g{bt}\g{fc}*+\h*$
define {COMMENT}     ^<!--(?![->])(?s:.+?)-->
define {SGR}         (?:\e\[[\d:;]*[mK])*
define {SGR_END}     (?:\e\[[0;]*[mK])*
define {LIST_MARKER} (?:[*+-]|(?:\d+|#)[.)])
define {LIST_ITEM}   ^\h*{LIST_MARKER}\h+.*\n
define {QUOTE_LINE}  ^ {0,3}(?:{SGR}>\h?)+.*\n
# The prefix of a folded line's continuation lines: the quote markers
# (named group, repeated by ansifold --keepindent=named), then the indent,
# a list marker or a definition colon, which become spaces of the same
# width.  Every line matches (all parts may be empty), so that every line
# sets its own prefix.
# After the markers only reset and erase sequences (SGR_END) belong to
# the group: any sequence (SGR) would take the opening of a span that
# follows, and every continuation line would start inside that span.
define {AUTOINDENT}  ^\h*(?<q>(?:{SGR}>\h?)*{SGR_END})(?:\h*(?:{LIST_MARKER}|:)\h+|\h+)?
define {DEFINITION}  (?:\A|\G\n|\n\n).+\n\n?(:\h+.*\n)

option --fold-by \
    -Mtee "&ansifold" --crmode \
        --autoindent='{AUTOINDENT}' \
        --keepindent=named \
        --smart --width=$<shift> --runin=$<shift> --runout=$<shift> \
    -- \
    --exclude {CODE_BLOCK} \
    --exclude {COMMENT} \
    --exclude &__PACKAGE__::front_matter_region \
    --exclude &__PACKAGE__::table_regions \
    --cm N -E {LIST_ITEM} \
    --cm N -E {DEFINITION} \
    --cm N -E {QUOTE_LINE} \
    --cm N --le &__PACKAGE__::refill_regions \
    --crmode

