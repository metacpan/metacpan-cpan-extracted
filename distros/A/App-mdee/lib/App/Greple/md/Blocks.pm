package App::Greple::md::Blocks;

use 5.026;
use warnings;
use utf8;

our $VERSION = "1.17";

use Exporter 'import';
our @EXPORT_OK = qw(blocks available);

# The paragraphs of a Markdown text, for the refill of App::Greple::md:
# blocks($text) returns the blocks as {type, depth, first, last}, where
# type is Para or Plain for a paragraph, depth the number of block
# quotes the block is in, and first and last its line numbers (from 1).
# The positions come from the CommonMark module (libcmark, in this
# process), from Markdown::Perl (pure Perl, a required dependency) or
# from pandoc with its sourcepos extension, whichever the parser option
# names; without it, from the first one that is available, in that order.
sub blocks {
    my($text, %opt) = @_;
    my $parser = $opt{parser} || (available())[0]
        // die "refill: no Markdown parser is available (CommonMark, Markdown::Perl or pandoc with sourcepos)\n";
    if ($parser eq 'cmark') {
        return cmark_blocks($text);
    } elsif ($parser eq 'mdperl') {
        return mdperl_blocks($text);
    } elsif ($parser eq 'pandoc') {
        return pandoc_blocks($text);
    } else {
        die "refill_parser: $parser: use cmark, mdperl or pandoc\n";
    }
}

# The parsers that work here, the fastest first.
sub available {
    state $parsers = [
        (eval { require CommonMark; 1 } ? 'cmark' : ()),
        (mdperl_works() ? 'mdperl' : ()),
        (pandoc_works() ? 'pandoc' : ()),
    ];
    @$parsers;
}

# pandoc with the sourcepos extension (2.11.3 or later): run the reader
# that pandoc_blocks uses, so that the check and the use agree.
sub pandoc_works {
    system(q(printf "x\n" | pandoc -f gfm+sourcepos+definition_lists -t json >/dev/null 2>&1)) == 0;
}

# CommonMark gives every node its first and last line.  Only the
# paragraphs are needed; libcmark has no tables and no definition
# lists, so a table and a term with its definitions are paragraphs to
# it, which refill_block keeps apart by their lines.
sub cmark_blocks {
    my $text = shift;
    require CommonMark;
    my $doc = CommonMark->parse(string => $text, sourcepos => 1);
    my $iter = $doc->iterator;
    my($depth, @blocks) = (0);
    while (my($ev, $node) = $iter->next) {
        my $type = $node->get_type;
        if ($type == CommonMark::NODE_BLOCK_QUOTE()) {
            $depth += $ev == CommonMark::EVENT_ENTER() ? 1 : -1;
            next;
        }
        next unless $ev == CommonMark::EVENT_ENTER()
            and $type == CommonMark::NODE_PARAGRAPH();
        push @blocks, {
            type  => 'Para',
            depth => $depth,
            first => $node->get_start_line,
            last  => $node->get_end_line,
        };
    }
    @blocks;
}

# Markdown::Perl has no public parse tree and no positions, but its block
# parser builds a paragraph line by line in _do_paragraph and closes it
# in _finalize_paragraph, and it keeps the offset of the current line in
# last_pos.  mdperl_blocks wraps those two subs while it parses and takes
# the line numbers from there.  This leans on private names, so
# mdperl_works checks that they still exist, and the parser is not
# offered when they do not; t/10_blocks.t compares the result with the
# other parsers.
my @mdperl_private = qw(_do_paragraph _finalize_paragraph _parse);
sub mdperl_works {
    eval { require Markdown::Perl; require Markdown::Perl::BlockParser; 1 } or return 0;
    for my $name (@mdperl_private) {
        my $pkg = $name eq '_parse' ? 'Markdown::Perl' : 'Markdown::Perl::BlockParser';
        return 0 unless defined &{"${pkg}::$name"};
    }
    1;
}

sub mdperl_blocks {
    my $text = shift;
    mdperl_works() or die "refill: Markdown::Perl is not usable\n";
    my @blocks;
    my %state;      # per parser object: first, last, and the line count so far
    my $do  = \&Markdown::Perl::BlockParser::_do_paragraph;
    my $fin = \&Markdown::Perl::BlockParser::_finalize_paragraph;
    no warnings 'redefine';
    local *Markdown::Perl::BlockParser::_do_paragraph = sub {
        my($this) = @_;
        my $before = @{$this->{paragraph}};
        my $r = $do->(@_);
        if (@{$this->{paragraph}} > $before) {
            # the line number of the current line, counting from where we
            # last counted (the parser may step back a line)
            my $s = $state{$this} //= { pos => 0, line => 1 };
            my $pos = $this->{last_pos};
            if ($pos < $s->{pos}) { @$s{qw(pos line)} = (0, 1) }
            $s->{line} += substr($this->{md}, $s->{pos}, $pos - $s->{pos}) =~ tr/\n//;
            $s->{pos} = $pos;
            # a new paragraph starts when the first line goes in (a setext
            # heading takes the lines away without closing the paragraph)
            $s->{first} = $s->{line} if $before == 0 or !defined $s->{first};
            $s->{last} = $s->{line};
        }
        $r;
    };
    local *Markdown::Perl::BlockParser::_finalize_paragraph = sub {
        my($this) = @_;
        my $s = $state{$this};
        if (@{$this->{paragraph}} and $s and defined $s->{first}) {
            push @blocks, {
                type  => 'Para',
                depth => scalar(grep { $_->{block}{type} eq 'quotes' } @{$this->{blocks_stack}}),
                first => $s->{first},
                last  => $s->{last},
            };
            delete @$s{qw(first last)};
        }
        $fin->(@_);
    };
    # tables are left as paragraphs, as libcmark reports them, so that the
    # table-row rules of refill_block apply the same way for every parser
    Markdown::Perl->new(mode => 'github', use_table_blocks => 0, parse_file_metadata => 'yaml')->_parse(\$text);
    sort { $a->{first} <=> $b->{first} } @blocks;
}

# Run pandoc on the text and return the blocks it reports with a source
# position.  With the sourcepos extension pandoc wraps a block in a Div whose
# data-pos is "L:C-L:C", or several such segments separated by ";" when
# the block is interrupted by markers it consumed (a list item's
# continuation lines).  An end column of 1 means the block ended with
# the line before.  A paragraph followed by a horizontal rule without a
# blank line is reported up to the rule, so the end is also cut at the
# line before the next block that starts below the first line.  depth
# is the number of block quotes the block is in.
#
# A block that has attributes of its own (a heading, a code block, a
# table) is not wrapped: its position is in its attributes, at the
# index below in its content.  A table's segments are not in order.
my %attr_index = (Div => 0, Header => 1, CodeBlock => 0, Table => 0, Figure => 0);
sub pandoc_blocks {
    my $text = shift;
    require Command::Run;
    require JSON::PP;
    my $result = Command::Run->new
        ->command(qw(pandoc -f gfm+sourcepos+definition_lists -t json))
        ->with(stdin => $text)
        ->run;
    die "refill: pandoc failed\n" if $result->{result} != 0;
    my $doc = JSON::PP->new->decode($result->{data});
    my @blocks;
    my $walk; $walk = sub {
        my($node, $depth) = @_;
        if (ref $node eq 'HASH') {
            my $t = $node->{t} // '';
            if (defined(my $i = $attr_index{$t})) {
                my $attr = $node->{c}[$i];
                my %kv = map { @$_ } @{$attr->[2]};
                if (defined(my $pos = $kv{'data-pos'})) {
                    my($first, $last);
                    while ($pos =~ /(\d+):\d+-(\d+):(\d+)/g) {
                        my($from, $to) = ($1, $3 == 1 ? $2 - 1 : $2);
                        $first = $from if !defined $first or $from < $first;
                        $last  = $to   if !defined $last  or $to > $last;
                    }
                    my $inner = $node->{c}[1];
                    push @blocks, {
                        type  => $t ne 'Div' ? $t
                               : @$inner == 1 ? $inner->[0]{t} : 'Blocks',
                        depth => $depth,
                        first => $first,
                        last  => $last,
                    } if defined $first;
                }
            }
            $depth++ if $t eq 'BlockQuote';
            $walk->($node->{c}, $depth) if ref $node->{c};
        } elsif (ref $node eq 'ARRAY') {
            $walk->($_, $depth) for @$node;
        }
    };
    $walk->($doc->{blocks}, 0);
    my @starts = sort { $a <=> $b } keys %{{ map { $_->{first} => 1 } @blocks }};
    for my $b (@blocks) {
        my($next) = grep { $_ > $b->{first} } @starts;
        $b->{last} = $next - 1 if defined $next and $next - 1 < $b->{last};
    }
    @blocks;
}

1;

__END__

=encoding utf-8

=head1 NAME

App::Greple::md::Blocks - find the paragraphs of a Markdown text

=head1 SYNOPSIS

    use App::Greple::md::Blocks qw(blocks available);

    my @blocks = blocks($text);                    # first available parser
    my @blocks = blocks($text, parser => 'cmark'); # or 'mdperl', 'pandoc'
    my @parsers = available();                     # ('cmark', 'mdperl', 'pandoc')

=head1 DESCRIPTION

This module gives L<App::Greple::md> the line numbers of the
paragraphs in a Markdown text, for its C<refill> option, which joins
the lines of each paragraph.  The text itself is not changed or
rendered: the module is only asked where the paragraphs are.

Each block is a hash with C<type> (C<Para> or C<Plain> for a
paragraph), C<depth> (the number of block quotes the block is in) and
C<first> and C<last> (its first and last line, counted from 1).

Three parsers are supported:

=over 4

=item C<cmark>

The L<CommonMark> module, an interface to libcmark, run in this
process.  It is fast, but it does not know GFM tables and definition
lists, which it reports as paragraphs; L<App::Greple::md> keeps their
lines apart by their shape.

=item C<mdperl>

L<Markdown::Perl>, a CommonMark implementation in pure Perl and a
dependency of this distribution, so it is always there.  It publishes
no parse tree or positions; the module wraps two private subroutines
of its block parser while it parses and reads the line numbers from
there, checks first that those subroutines exist, and parses tables as
paragraphs, like libcmark, so that the three parsers agree.

=item C<pandoc>

L<pandoc|https://pandoc.org> 2.11.3 or later, run as a child process
with C<-f gfm+sourcepos+definition_lists -t json>.

=back

C<available()> returns the names of the parsers that work on this
system, the fastest first (C<cmark>, C<mdperl>, C<pandoc>), and
C<blocks()> uses the first of them unless C<parser> is given.

=head1 SEE ALSO

L<App::Greple::md>, L<CommonMark>, L<Markdown::Perl>, L<https://pandoc.org>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2026 Kazumasa Utashiro.

This software is released under the MIT License.
L<https://opensource.org/licenses/MIT>

=cut
