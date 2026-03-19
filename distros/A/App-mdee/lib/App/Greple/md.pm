# -*- mode: perl; coding: utf-8 -*-
# vim: set fileencoding=utf-8 filetype=perl :
package App::Greple::md;

use 5.024;
use warnings;

our $VERSION = "1.07";

=encoding utf-8

=head1 NAME

App::Greple::md - Greple module for Markdown syntax highlighting

=head1 SYNOPSIS

    greple -Mmd file.md

    greple -Mmd --mode=dark -- file.md

    greple -Mmd --base-color=Crimson -- file.md

    greple -Mmd --cm h1=RD -- file.md

    greple -Mmd --no-table -- file.md

    greple -Mmd --foldlist -- file.md

    greple -Mmd -- --fold file.md

=head1 DESCRIPTION

B<App::Greple::md> is a L<greple|App::Greple> module for viewing
Markdown files in the terminal with syntax highlighting.

It colorizes headings, bold, italic, strikethrough, inline code,
fenced code blocks, HTML comments, blockquotes, horizontal rules,
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

=head1 COMMAND OPTIONS

The following options are defined as greple command options
(specified after C<-->).

=head2 B<--fold>

Enable text folding for list items and definition lists.  Long lines
are wrapped with proper indentation using L<ansifold(1)|App::ansifold>
via L<Greple::tee>.  Code blocks, HTML comments, and tables are
excluded from folding.  The fold width is controlled by the
C<foldwidth> config parameter (default: 80).

    greple -Mmd -- --fold file.md
    greple -Mmd::config(foldwidth=60) -- --fold file.md

Supported list markers: C<*>, C<->, C<1.>, C<1)>, C<#.>, C<#)>.

The module option C<--foldlist> is a convenient alternative that
enables folding via config.

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

=head2 B<--[no-]foldlist>

Enable or disable text folding.  Disabled by default.  When
enabled, long lines in list items and definition lists are wrapped
with proper indentation.  The fold width is controlled by the
C<foldwidth> config parameter (default: 80).

    greple -Mmd --foldlist -- file.md
    greple -Mmd::config(foldlist=1,foldwidth=60) file.md

See also the C<--fold> command option.

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
    foldlist        text folding (default: 0)
    foldwidth       fold width in columns (default: 80)
    table           table formatting (default: 1)
    rule            box-drawing characters (default: 1)
    osc8            OSC 8 hyperlinks (default: 1)
    heading_markup  inline markup in headings (default: 0)
                    0=off, 1/all=all, or colon-separated steps
    tick_open       inline code open marker (default: `)
    tick_close      inline code close marker (default: ´)
    nofork          nofork+raw mode for code ref calls (default: 1)
    hashed.h1-h6    closing hashes per level (default: 0)

=head2 OSC 8 Hyperlinks

Links are converted to clickable OSC 8 terminal hyperlinks in
supported terminals (iTerm2, Kitty, WezTerm, Ghostty, etc.).
Disable with:

    greple -Mmd::config(osc8=0) file.md

=head1 COLOR LABELS

The following labels identify colorizable elements.  Use them
with C<--colormap> (C<--cm>) to customize colors or C<--show> to control
visibility.  Default values are shown as C<light / dark>.
Colors follow L<Term::ANSIColor::Concise> format.

=head2 Headings

    LABEL   LIGHT                    DARK
    h1      L25D/${base};E           L00D/${base};E
    h2      L25D/${base}+y20;E       L00D/${base}-y15;E
    h3      L25DN/${base}+y30        L00DN/${base}-y25
    h4      ${base}UD                ${base}UD
    h5      ${base}U                 ${base}U
    h6      ${base}                  ${base}

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

=head2 Code

    LABEL        LIGHT              DARK
    code_mark    L20                L10
    code_tick    L15/L23            L15/L05
    code_info    ${base_name}=y70   L10
    code_block   /L23;E             /L05;E
    code_inline  L00/L23            L25/L05

Inline code backticks are displayed as C<`contentE<0xb4>> using
C<code_tick> color.  Multi-backtick delimiters are collapsed to a
single pair with optional surrounding spaces stripped (per CommonMark).
The open/close markers can be customized via C<tick_open>/C<tick_close>
config parameters.

=head2 Block Elements

    LABEL            LIGHT / DARK
    blockquote       ${base}D
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

=back

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2025-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

use URI::Escape;
use Getopt::EX::Config;
use Getopt::EX::Colormap;

my @color_labels = qw(
    code_mark code_tick code_info code_block code_inline
    comment link image image_link
    h1 h2 h3 h4 h5 h6
    bold italic strike emphasis_mark
    bold_mark italic_mark strike_mark link_mark
    blockquote horizontal_rule
);

my $config = Getopt::EX::Config->new(
    mode       => '',  # light / dark
    osc8       => 1,   # OSC 8 hyperlinks
    base_color => '',  # override base color
    colorize   => 1,   # syntax highlighting
    foldlist   => 0,   # text folding
    foldwidth  => 80,  # fold width
    table      => 1,   # table formatting
    table_trim => 1,   # trim cell content whitespace
    rule       => 1,   # box-drawing characters for tables
    nofork     => 1,   # use nofork+raw for code ref calls
    heading_markup => 0,  # inline formatting in headings
    tick_open  => '`',       # inline code open marker
    tick_close => "\x{b4}",  # inline code close marker (´)
    hashed     => { h1 => 0, h2 => 0, h3 => 0, h4 => 0, h5 => 0, h6 => 0 },
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
    comment         => '${base}+r60',
    link            => 'I',
    image           => 'I',
    image_link      => 'I',
    h1              => 'L25D/${base};E',
    h2              => 'L25D/${base}+y20;E',
    h3              => 'L25DN/${base}+y30',
    h4              => '${base}UD',
    h5              => '${base}U',
    h6              => '${base}',
    bold            => 'D',
    italic          => 'I',
    strike          => 'X',
    emphasis_mark   => 'L18',
    blockquote      => '${base}D',
    horizontal_rule => 'L15',
);

my %dark_overrides = (
    code_mark       => 'L10',
    code_tick       => 'L15/L05',
    code_info       => 'L10',
    code_block      => '/L05;E',
    code_inline     => 'L25/L05',
    h1              => 'L00D/${base};E',
    h2              => 'L00D/${base}-y15;E',
    h3              => 'L00DN/${base}-y25',
    h4              => '${base}UD',
    h5              => '${base}U',
    h6              => '${base}',
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
my %show;

sub finalize {
    my($mod, $argv) = @_;
    $config->deal_with($argv,
                       "mode|m=s", "base_color|B=s",
                       "colorize!", "nofork!", "foldlist!", "foldwidth=i", "table!", "table_trim!", "rule!",
                       "heading_markup|hm:s", "tick_open=s", "tick_close=s",
                       "hashed=s%",
                       "colormap|cm=s" => \@opt_cm,
                       "show=s%" => \%show);
    # --hm with no argument gives "": treat as "all"
    my $hm = $config->{heading_markup};
    if (defined $hm && $hm eq '') {
        $config->{heading_markup} = 'all';
    }
    if (my $w = $config->{foldwidth}) {
        $mod->setopt('--fold', "--fold-by $w");
        if ($config->{foldlist}) {
            my @default = $mod->default;
            $mod->setopt('default', @default, "--fold-by $w");
        }
    }
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

    code_blocks => Step(sub {
        s{^( {0,3})(`{3,}|~{3,})(.*)\n((?s:.*?))^( {0,3})\2(\h*)$}{
            my($oi, $fence, $lang, $body, $ci, $trail) = ($1, $2, $3, $4, $5, $6);
            my $result = md_color('code_mark', "$oi$fence");
            $result .= md_color('code_info', $lang) if length($lang);
            $result .= "\n";
            if (length($body)) {
                $result .= join '', map { md_color('code_block', $_) }
                    split /(?<=\n)/, $body;
            }
            $result .= md_color('code_mark', "$ci$fence") . $trail;
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
            s{^($hdr\h+.*)$}{
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
        s{$SKIP_CODE|(?<!\\)(?<m>\*\*)(?<t>.*?)(?<!\\)\g{m}}{
            mark_color('bold', $+{m}) . md_color('bold', $+{t}) . mark_color('bold', $+{m})
        }gep;
        s{$SKIP_CODE|(?<![\\\w])(?<m>__)(?<t>.*?)(?<!\\)\g{m}(?!\w)}{
            mark_color('bold', $+{m}) . md_color('bold', $+{t}) . mark_color('bold', $+{m})
        }gep;
    }),

    italic => Step(italic => sub {
        s{$SKIP_CODE|(?<![\\\w])(?<m>_)(?<t>(?:(?!_).)+)(?<!\\)\g{m}(?!\w)}{
            mark_color('italic', $+{m}) . md_color('italic', $+{t}) . mark_color('italic', $+{m})
        }gep;
        s{$SKIP_CODE|(?<![\\*])(?<m>\*)(?<t>(?:(?!\*).)+)(?<!\\)\g{m}(?!\*)}{
            mark_color('italic', $+{m}) . md_color('italic', $+{t}) . mark_color('italic', $+{m})
        }gep;
    }),

    strike => Step(strike => sub {
        s{$SKIP_CODE|(?<!\\)(?<m>~~)(?<t>.+?)(?<!\\)\g{m}}{
            mark_color('strike', $+{m}) . md_color('strike', $+{t}) . mark_color('strike', $+{m})
        }gep;
    }),

    blockquotes => Step(blockquote => sub {
        s/^(>+\h?)(.*)$/md_color('blockquote', $1) . $2/mge;
    }),
);

#
# Pipeline configuration
#

# Always before headings (protection + links)
my @protect_steps = qw(code_blocks comments image_links images links);

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

sub begin {
    colorize()     if $config->{colorize};
    format_table() if $config->{table};
}

sub format_table {
    my $sep = $config->{rule} ? "\x{2502}" : '|';  # │ or |

    s{(^ {0,3}\|.+\|\n){3,}}{
        my $block = $&;
        my($right, $center) = parse_separator(\$block);
        my @sep_opt;
        if ($config->{table_trim}) {
            @sep_opt = ('-rs', '\s*\|\s*', '--item-format= %s ', '--table-remove=1,-0', '--padding');
        } else {
            $_++ for @$right, @$center;
            @sep_opt = ('-s', '|');
        }
        my @align = (
            @$right  ? ('--table-right='  . join(',', @$right))  : (),
            @$center ? ('--table-center=' . join(',', @$center)) : (),
        );
        my $formatted = call_ansicolumn($block, @sep_opt, '-o', $sep, '-t', '--cu=1', @align);
        fix_separator($formatted, $sep);
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

define {CODE_BLOCK}  ^ {0,3}(?<bt>`{3,}+|~{3,}+)(.*)\n((?s:.*?))^ {0,3}(\g{bt})
define {COMMENT}     ^<!--(?![->])(?s:.+?)-->
define {TABLE}       ^ {0,3}([│|├].+[│|┤]\n){3,}
define {LIST_ITEM}   ^\h*(?:[*-]|(?:\d+|#)[.)])\h+.*\n
define {DEFINITION}  (?:\A|\G\n|\n\n).+\n\n?(:\h+.*\n)

option --fold-by \
    -Mtee "&ansifold" --crmode \
        --autoindent='^\h*(?:[*-]|(?:\d+|#)[.)]|:)\h+|^\h+' \
        --smart --width=$<shift> \
    -- \
    --exclude {CODE_BLOCK} \
    --exclude {COMMENT} \
    --exclude {TABLE} \
    --cm N -E {LIST_ITEM} \
    --cm N -E {DEFINITION} \
    --crmode

