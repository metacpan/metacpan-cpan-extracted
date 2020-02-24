package App::unbelievable;

# Documentation {{{1

=encoding utf-8

=head1 NAME

App::unbelievable - Dancer2 static site generator

=head1 SYNOPSIS

In your Dancer2 app:

    use App::unbelievable;  # Pulls in Dancer2
    # your routes here
    unbelievable;           # At EOF, fills in the rest of the routes.

Then:

    $ unbelievable build    # Make the HTML
    $ unbelievable serve    # Run a local development server

App::unbelievable makes a Dancer2 application into a static site generator.
App::unbelievable adds routes for C</> and C</**> that will render Markdown
files in C<content/>.  The L<unbelievable> script generates static HTML
and other assets into C<_built/>.

=cut

# }}}1

use version 0.77; our $VERSION = version->declare('v0.0.5');

use App::unbelievable::Util;

use File::Slurp;
use File::Spec;
use JSON;
use Plack::Builder;
use Syntax::Highlight::Engine::Kate;
use Syntax::Highlight::Engine::Kate::All;
use Text::FrontMatter::YAML;
use Text::MultiMarkdown 'markdown';     # TODO someday? - Text::Markup
    # But see https://github.com/theory/text-markup/issues/20

# Routes to generate the HTML from Markdown (main logic) {{{1
use parent 'Exporter';
use vars::i '@EXPORT' => [qw(unbelievable)];

sub import {
    my $target = caller;
    _diag('Loading ' . __PACKAGE__ . ' into ' . $target);
    __PACKAGE__->export_to_level(1, @_);

    require Import::Into;
    require feature;
    require Dancer2;
    $_->import::into($target) foreach qw(Dancer2 strict warnings);
    feature->import::into($target, ':5.10');
} #import()

# The list of syntaxes we know about, keyed lower-case
# (Kamelon is case-sensitive).
my %SYNTAXES;

# Produce a file, e.g., by processing a markdown file into HTML.
# Returns:
#   - falsy: pass
#   - hashref:
#       - {send_file => $filename}: a filename to send_file
#       - {template => [...]}: args for template().
sub _produce_output {
    my ($public_dir, $content_dir, $request, $templater, $lrTags) = @_;

    die "Assertion failure - empty megasplat??!!" unless @$lrTags;

    # Munge the last path component to provide the CLI with flexibility
    $lrTags->[$#$lrTags] =~ s{/$}{};
        # We handle /foo and /foo/ the same --- the CLI can request either.
    $lrTags->[$#$lrTags] =~ s{\.(?:html?|md|markdown)$}{};
        # We ignore the requested extension.  Static files are served elsewhere
        # so never get here.

    my $path = join('/', @$lrTags);
    _diag("Processing file ", $path);

    my $fn;             # File we are going to read from
    my @candidates;     # Where we might find it

    push @candidates, File::Spec->catfile($content_dir, _suffix('.md', @$lrTags));
    push @candidates, File::Spec->catfile($content_dir, _suffix('.markdown', @$lrTags));
    push @candidates, File::Spec->catfile($public_dir, _suffix('.html', @$lrTags));
    push @candidates, File::Spec->catfile($public_dir, _suffix('.htm', @$lrTags));

    foreach my $candidate (@candidates) {
        next unless -f -r $candidate;
        $fn = $candidate;
        last;
    }

    die "Could not find file for $path (tried @{[join(' ', @candidates)]})"
        unless $fn;

    return {send_file => $fn} if $fn =~ /\.html?$/;

    # Load Markdown file
    my @retval = ('index');     # Name of the template
    my ($frontmatter, $markdown) = _load($fn);
    _diag("Got frontmatter\n", Dumper $frontmatter);
    _diag(\2, "Got contents:\n$markdown");

    # shortcodes.  TODO other than single-arg.
    $markdown =~ s[\{\{<\s*(?<code>\w+)\s+(?<arg0>\S+)\s*>\}\}]
                    [ _shortcode($+{code}, [$+{arg0}], $templater) ]exg;

    # Fenced, tagged code blocks.
    # TODO in S::K, don't repeat IDs for the line divs (currently each
    # block has lines id="1", id="2", ...).
    my (%styles, %scripts);     # Map from text to 1.  This way we only
                                # include each style or script block once.

    pos($markdown) = 0;
    while($markdown =~ m{\G.*?(^```(\S+)$(.*?)^```)}gcms) {

        my ($lang, $text) = (_normalize_syntax($2), $3);
        my $fence_start = $-[1];        # Where the fenced block ($1) is
        my $fence_len = $+[1] - $-[1];

        if(!$SYNTAXES{$lang}) {
            warn "Unknown language $2 in $path";
            substr($markdown, $fence_start, $fence_len) =
                "```\n$text```";    # Just remove the language tag
            next;
        }

        # Trim newline at the start (because the $ above matched _before_
        # the newline after the '```')
        $text =~ s{\A\R}{};

        substr($markdown, $fence_start, $fence_len) = _highlight($lang, $text);
    }

    # Process what's left
    my $html = markdown($markdown, {base_url => '/'});

    # TODO permit the user to specify a template
    _diag(\2, "Generated HTML:\n$html");
    return { template => [
                'raw',
                {
                    %$frontmatter,
                    htmlsource => $html,
                    styles => join("\n", keys %styles),
                    scripts => join("\n", keys %scripts),
                }
            ] };
} #_produce_output

sub unbelievable {
    my $appname = caller or die "No caller!";
    _diag('unbelievable ' . __PACKAGE__ . ' in ' . $appname);

    require Dancer2;

    my $dsl = do { no strict 'refs'; &{ $appname . '::dsl' } };
    die "Could not find Dancer2 DSL" unless $dsl;

    # Find the public dir and the content dir
    my $public_dir = $dsl->setting('public_dir') or die "No public_dir set";
    $public_dir = File::Spec->rel2abs($public_dir)
        unless File::Spec->file_name_is_absolute($public_dir);
    my ($vol, $dirs, $file) = File::Spec->splitpath($public_dir);
    my $content_dir = File::Spec->catpath($vol, $dirs, 'content');

    _diag("public_dir $public_dir");
    _diag("content_dir $content_dir");

    # Create default routes.  The caller must invoke this function
    # after defining any other routes, so these will only be used
    # as fallbacks.
    my $text = _line_mark_string(<<EOT);
    package App::unbelievable::Routes;
    use 5.010001;
    use strict;
    use warnings;
    use vars::i {
        '\$APPNAME' => @{[_sqescape($appname)]},
        '\$PUBLIC' =>@{[_sqescape($public_dir)]},
        '\$CONTENT' => @{[_sqescape($content_dir)]},
    };
EOT

    $text .= _line_mark_string(<<'EOTSQ');
    use Data::Dumper;
    use Dancer2 appname => $APPNAME;
    use App::unbelievable::Util;

    _diag("Loading routes into $APPNAME");
    App::unbelievable::_initialize();

    # Call our _produce_output, above, and take the appropriate action.
    # This way we don't have to try to directly invoke Dancer2 DSL in
    # _produce_output.
    sub _do_file {
        my $content =
            App::unbelievable::_produce_output($PUBLIC, $CONTENT, request,
                sub { template @_ }, shift);
        pass unless $content;
        send_file $content->{send_file} if $content->{send_file};
        return template @{$content->{template}} if $content->{template};
        die "Assertion failure: I don't know how to handle that file.\n" .
            Dumper $content;
    }

    get '/' => sub { _do_file(['index']) };
    # Note: we never get here on requests for static files --- those are
    # handled by middleware before Dancer2 checks routes.  See
    # Dancer2::Core::App::to_app().
    get '/**' => sub { _do_file(splat) };

EOTSQ

    eval $text;
    die $@ if $@;

    return 1;   # So the unbelievable() call can be the last thing in the file
} #unbelievable()

# }}}1
# Helper routines {{{1

# Escape in single quotes
sub _sqescape {
    my $str = shift;
    $str =~ s/'/\\'/g;
    return "'$str'";
}

# Render a shortcode.  Usage: _shortcode($code, \@args, $templater)
sub _shortcode {
    my ($code, $lrArgs, $templater) = @_;
    _diag(\2, "Shortcode $code @$lrArgs");

    $_ =~ s{\A(['"])(.+)\1\z}{$2} foreach @$lrArgs;     # de-quote

    my $result = $templater->(                          # render
        File::Spec->catfile('shortcodes', $code),
        { map {; "_$_" => $lrArgs->[$_]} 0..$#$lrArgs },
        { layout => undef } );

    $result =~ s{^\s+|\s+$}{}g;                         # trim
    return $result;
} #_shortcode()

# Add a suffix to the last component of a list.  No-op if the
# list is empty.
sub _suffix {
    my $suffix = shift;
    return () unless @_;
    my $last = $_[$#_] . $suffix;
    return @_[0..$#_-1], $last;
}

# Load a Markdown file, which may have front matter.
# Input must be in UTF-8.
# Returns an arrayref of YAML documents.
sub _load {
    my $fn = shift;
    my $text = read_file($fn, {binmode => ':utf8'});
    my ($frontmatter, $markdown);
    my @errors;
    my $reader;

    # Look for JSON frontmatter without separators (Hugo-style).
    my $charcount;
    eval {
        $reader = JSON->new;
        ($frontmatter, $charcount) = $reader->decode_prefix($text);
        $markdown = substr $text, $charcount//0;
    };
    push @errors, "Could not read JSON: $@" if $@;
    push @errors, "No JSON found" unless $charcount;

    return ($frontmatter, $markdown) unless(@errors);

    # Mainline case: YAML frontmatter with `---` separators
    eval {
        $reader = Text::FrontMatter::YAML->new(
            document_string => $text
        );
        $frontmatter = $reader->frontmatter_hashref;
        $markdown = $reader->data_text // '';
    };
    push @errors, "Could not read YAML-frontmatter document: $@" if $@;

    return ($frontmatter, $markdown) unless @errors;

    # Default: assume the full contents are markdown, and there is
    # no frontmatter.
    _diag(join "\n  ", "Assuming plain Markdown $fn --- errors were:", @errors);

    return ({}, $text);
} #_load()

# Normalize a syntax name into a key for %SYNTAXES
sub _normalize_syntax {
    my $retval = lc(shift);
    $retval =~ s/[^A-Za-z0-9]/_/g;
    $retval =~ tr/_/_/s;
    return $retval;
}

# Populates %SYNTAXES.  Must be called before
# _produce_output().  Called by unbelievable().
sub _initialize {
    foreach(keys %INC) {
        next unless m{Syntax/Highlight/Engine/Kate/([^\.]+).pm$};
        $SYNTAXES{_normalize_syntax($1)} = $1;
    }
    say "Syntaxes:\n", Dumper(\%SYNTAXES) if $VERBOSE >= 2;
} #_initialize()

# Syntax-highlight text
sub _highlight {
    my ($lang, $text) = @_;

    # Make the highlighter
    my $hl = Syntax::Highlight::Engine::Kate->new(
        language => $SYNTAXES{$lang},

        substitutions => {
            "<"  => "&lt;",
            ">"  => "&gt;",
            "&"  => "&amp;",
            " "  => "&nbsp;",
            "\t" => "&nbsp;&nbsp;&nbsp;",
            "\n" => "<BR>\n",
        },

        format_table => {
            Alert        => [ "<font color=\"#0000ff\">",       "</font>" ],
            BaseN        => [ "<font color=\"#007f00\">",       "</font>" ],
            BString      => [ "<font color=\"#c9a7ff\">",       "</font>" ],
            Char         => [ "<font color=\"#ff00ff\">",       "</font>" ],
            Comment      => [ "<font color=\"#7f7f7f\"><i>",    "</i></font>" ],
            DataType     => [ "<font color=\"#0000ff\">",       "</font>" ],
            DecVal       => [ "<font color=\"#00007f\">",       "</font>" ],
            Error        => [ "<font color=\"#ff0000\"><b><i>", "</i></b></font>" ],
            Float        => [ "<font color=\"#00007f\">",       "</font>" ],
            Function     => [ "<font color=\"#007f00\">",       "</font>" ],
            IString      => [ "<font color=\"#ff0000\">",       "" ],
            Keyword      => [ "<b>",                            "</b>" ],
            Normal       => [ "",                               "" ],
            Operator     => [ "<font color=\"#ffa500\">",       "</font>" ],
            Others       => [ "<font color=\"#b03060\">",       "</font>" ],
            RegionMarker => [ "<font color=\"#96b9ff\"><i>",    "</i></font>" ],
            Reserved     => [ "<font color=\"#9b30ff\"><b>",    "</b></font>" ],
            String       => [ "<font color=\"#ff0000\">",       "</font>" ],
            Variable     => [ "<font color=\"#0000ff\"><b>",    "</b></font>" ],
            Warning      => [ "<font color=\"#0000ff\"><b><i>", "</b></i></font>" ],
        },
    );

    return '<div>' . $hl->highlightText($text) . '</div>';
} #_make_highlighter()

# }}}1
1;
__END__

# Rest of the docs {{{1

=head1 FEATURES

=head2 Markdown rendering

All non-hidden files in C<content/> are rendered as Markdown files.
Hidden files are those that start with a C<.> (the Unix convention).

=head2 Fenced code blocks

Fenced code blocks are syntax-highlighted using
L<Syntax::Highlight::Engine::Kate>.  Language names are the lowercased
versions of the module suffixes in
L<Syntax::Highlight::Engine::Kate::All|https://metacpan.org/source/MANWAR/Syntax-Highlight-Engine-Kate-0.14/lib/Syntax/Highlight/Engine/Kate/All.pm>.

=head2 Shortcodes

In Markdown inputs, shortcode tags of the form:

    {{< KEY [args] >}}

are replaced with the Dancer2 template C<shortcodes/KEY>
(e.g., C<views/shortcodes/foo.tt>).  Currently, only one argument is supported;
it is passed to the template as variable C<_0>.

=head2 Templates

Use whatever you want in your routes!  Use regular Dancer2 templating.

=head2 Static files

Everything in C<public/> is available under C</>, just as in Dancer2.

=head1 WHY?

Yet another site generator --- can you believe it?  And now you know where
the package name comes from ;) .

This package's roadmap is feature parity with L<Hugo|https://gohugo.io/>.

My motivation for writing unbelievable was two-fold:

=over

=item 1.

Perl.com is currently using Hugo, which is not written in Perl!

=item 2.

"every self-respecting programmer has written at least one static site
generator ... since writing a basic one is easy and often tends to be easier
than learning an existing one." --- SHLOMIF
(L<here|http://web-cpan.shlomifish.org/latemp/>).  :D

=back

=head1 FUNCTIONS

=head2 import

Imports L<Dancer2>, among others, into the caller's namespace.

=head2 unbelievable

Make default routes to render Markdown files in C<content/> into HTML.
Usage: C<unbelievable;>.  Returns a truthy value, so can be used as the
last line in a module.

=head1 THANKS

=over

=item *

Thanks to L<Getopt::Long::Subcommand> --- I used some code from its Synopsis.

=item *

Thanks to L<App::Wallflower>, L<Dancer2>, and
L<Syntax::Highlight::Engine::Kate> for doing the heavy lifting!

=back

=head1 LICENSE

Copyright (C) 2020 Chris White.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Chris White E<lt>cxwembedded@gmail.comE<gt>

=cut

# }}}1
# vi: set fdm=marker: #
