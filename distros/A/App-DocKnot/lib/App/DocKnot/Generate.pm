# Generate human-readable documentation from package metadata.
#
# This is the implementation of the docknot generate command, which uses
# templates to support generation of various documentation files based on
# package metadata.
#
# SPDX-License-Identifier: MIT

##############################################################################
# Modules and declarations
##############################################################################

package App::DocKnot::Generate 4.00;

use 5.024;
use autodie;
use parent qw(App::DocKnot);
use warnings;

use App::DocKnot::Config;
use Carp qw(croak);
use Encode qw(encode);
use Template;
use Text::Wrap qw(wrap);

# Default output files for specific templates.
my %DEFAULT_OUTPUT = (
    'readme'    => 'README',
    'readme-md' => 'README.md',
);

##############################################################################
# Generator functions
##############################################################################

# The internal helper object methods in this section are generators.  They
# return code references intended to be passed into Template Toolkit as code
# references so that they can be called inside templates, incorporating data
# from the App::DocKnot configuration or the package metadata.

# Returns code to center a line in $self->{width} characters given the text of
# the line.  The returned code will take a line of text and return that line
# with leading whitespace added as required.
#
# Returns: Code reference to a closure that uses $self->{width} for width
sub _code_for_center {
    my ($self) = @_;
    my $center = sub {
        my ($text) = @_;
        my $space = $self->{width} - length($text);
        if ($space <= 0) {
            return $text;
        } else {
            return q{ } x int($space / 2) . $text;
        }
    };
    return $center;
}

# Returns code that formats the copyright notices for the package.  The
# resulting code reference takes two parameter, the indentation level and an
# optional prefix for each line, and wraps the copyright notices accordingly.
# They will be wrapped with a four-space outdent and kept within
# $self->{width} columns.
#
# $copyrights_ref - A reference to a list of anonymous hashes, each with keys:
#   holder - The copyright holder for that copyright
#   years  - The years of that copyright
#
# Returns: Code reference to a closure taking an indent level and an optional
#          prefix and returning the formatted copyright notice
sub _code_for_copyright {
    my ($self, $copyrights_ref) = @_;
    my $copyright = sub {
        my ($indent, $lead) = @_;
        my $prefix = ($lead // q{}) . q{ } x $indent;
        my $notice;
        for my $copyright ($copyrights_ref->@*) {
            my $holder = $copyright->{holder};
            my $years  = $copyright->{years};

            # Build the initial notice with the word copyright and the years.
            my $text = 'Copyright ' . $copyright->{years};
            local $Text::Wrap::columns  = $self->{width} + 1;
            local $Text::Wrap::unexpand = 0;
            $text = wrap($prefix, $prefix . q{ } x 4, $text);

            # See if the holder fits on the last line.  If so, add it there;
            # otherwise, add another line.
            my $last_length;
            if (rindex($text, "\n") == -1) {
                $last_length = length($text);
            } else {
                $last_length = length($text) - rindex($text, "\n");
            }
            if ($last_length + length($holder) < $self->{width}) {
                $text .= " $holder";
            } else {
                $text .= "\n" . $prefix . q{ } x 4 . $holder;
            }
            $notice .= $text . "\n";
        }
        chomp($notice);
        return $notice;
    };
    return $copyright;
}

# Returns code to indent each line of a paragraph by a given number of spaces.
# This is constructed as a method returning a closure so that its behavior can
# be influenced by App::DocKnot configuration in the future, but it currently
# doesn't use any configuration.  It takes the indentation and an optional
# prefix to put at the start of each line.
#
# Returns: Code reference to a closure
sub _code_for_indent {
    my ($self) = @_;
    my $indent = sub {
        my ($text, $space, $lead) = @_;
        $lead //= q{};
        my @text = split(m{\n}xms, $text);
        return join("\n", map { $lead . q{ } x $space . $_ } @text);
    };
    return $indent;
}

# Returns code that converts metadata text (which is assumed to be in
# Markdown) to text.  This is not a complete Markdown formatter.  It only
# supports the bits of markup that I've had some reason to use.
#
# This is constructed as a method returning a closure so that its behavior can
# be influenced by App::DocKnot configuration in the future, but it currently
# doesn't use any configuration.
#
# Returns: Code reference to a closure that takes a block of text and returns
#          the converted text
sub _code_for_to_text {
    my ($self) = @_;
    my $to_text = sub {
        my ($text) = @_;

        # Remove triple backticks but escape all backticks inside them.
        $text =~ s{ ``` \w* (\s .*?) ``` }{
            my $text = $1;
            $text =~ s{ [\`] }{``}xmsg;
            $text;
        }xmsge;

        # Remove backticks, but don't look at things starting with doubled
        # backticks.
        $text =~ s{ (?<! \` ) ` ([^\`]+) ` }{$1}xmsg;

        # Undo backtick escaping.
        $text =~ s{ `` }{\`}xmsg;

        # Rewrite quoted paragraphs to have four spaces of additional
        # indentation.
        $text =~ s{
            \n \n               # start of paragraph
            (                   # start of the text
              (> \s+)           #   quote mark on first line
              \S [^\n]* \n      #   first line
              (?:               #   all subsequent lines
                \2 \S [^\n]* \n #     start with the same prefix
              )*                #   any number of subsequent lines
            )                   # end of the text
        }{
            my ($text, $prefix) = ($1, $2);
            $text =~ s{ ^ \Q$prefix\E }{  }xmsg;
            "\n\n" . $text;
        }xmsge;

        # For each paragraph, remove URLs from all links, replacing them with
        # numeric references, and accumulate the mapping of numbers to URLs in
        # %urls.  Then, add to the end of the paragraph the references and
        # URLs.
        my $ref        = 1;
        my @paragraphs = split(m{ \n\n }xms, $text);
        for my $para (@paragraphs) {
            my %urls;
            while ($para =~ s{ \[ ([^\]]+) \] [(] (\S+) [)] }{$1 [$ref]}xms) {
                $urls{$ref} = $2;
                $ref++;
            }
            if (%urls) {
                my @refs = map { "[$_] $urls{$_}" } sort { $a <=> $b }
                  keys(%urls);
                $para .= "\n\n" . join("\n", q{}, @refs, q{});
            }
        }

        # Rejoin the paragraphs and return the result.
        return join("\n\n", @paragraphs);
    };
    return $to_text;
}

# Returns code that converts metadata text (which is assumed to be in
# Markdown) to thread.  This is not a complete Markdown formatter.  It only
# supports the bits of markup that I've had some reason to use.
#
# This is constructed as a method returning a closure so that its behavior can
# be influenced by App::DocKnot configuration in the future, but it currently
# doesn't use any configuration.
#
# Returns: Code reference to a closure that takes a block of text and returns
#          the converted thread
sub _code_for_to_thread {
    my ($self) = @_;
    my $to_thread = sub {
        my ($text) = @_;

        # Escape all backslashes.
        $text =~ s{ \\ }{\\\\}xmsg;

        # Rewrite triple backticks to \pre blocks and escape backticks inside
        # them so that they're not turned into \code blocks.
        $text =~ s{ ``` \w* (\s .*?) ``` }{
            my $text = $1;
            $text =~ s{ [\`] }{``}xmsg;
            '\pre[' . $1 . ']';
        }xmsge;

        # Rewrite backticks to \code blocks.
        $text =~ s{ ` ([^\`]+) ` }{\\code[$1]}xmsg;

        # Undo backtick escaping.
        $text =~ s{ `` }{\`}xmsg;

        # Rewrite all Markdown links into thread syntax.
        $text =~ s{ \[ ([^\]]+) \] [(] (\S+) [)] }{\\link[$2][$1]}xmsg;

        # Rewrite long bullets.  This is quite tricky since we have to grab
        # every line from the first bulleted one to the point where the
        # indentation stops.
        $text =~ s{
            (                   # capture whole contents
                ^ (\s*)         #   indent before bullet
                [*] (\s+)       #   bullet and following indent
                [^\n]+ \n       #   rest of line
                (?: \s* \n )*   #   optional blank lines
                (\2 [ ] \3)     #   matching indent
                [^\n]+ \n       #   rest of line
                (?:             #   one or more of
                    \4          #       matching indent
                    [^\n]+ \n   #       rest of line
                |               #   or
                    \s* \n      #       blank lines
                )+              #   end of indented block
            )                   # full bullet with leading bullet
        }{
            my $text = $1;
            $text =~ s{ [*] }{ }xms;
            "\\bullet[\n\n" . $text . "\n]\n";
        }xmsge;

        # Do the same thing, but with numbered lists.  This doesn't handle
        # numbers larger than 9 currently, since that requires massaging the
        # spacing.
        $text =~ s{
            (                   # capture whole contents
                ^ (\s*)         #   indent before number
                \d [.] (\s+)    #   number and following indent
                [^\n]+ \n       #   rest of line
                (?: \s* \n )*   #   optional blank lines
                (\2 [ ][ ] \3)  #   matching indent
                [^\n]+ \n       #   rest of line
                (?:             #   one or more of
                    \4          #       matching indent
                    [^\n]+ \n   #       rest of line
                |               #   or
                    \s* \n      #       blank lines
                )+              #   end of indented block
            )                   # full bullet with leading bullet
        }{
            my $text = $1;
            $text =~ s{ \A (\s*) \d [.] }{$1  }xms;
            "\\number[\n\n" . $text . "\n]\n\n";
        }xmsge;

        # Rewrite compact bulleted lists.
        $text =~ s{ \n ( (?: \s* [*] \s+ [^\n]+ \s* \n ){2,} ) }{
            my $list = $1;
            $list =~ s{ \n [*] \s+ ([^\n]+) }{\n\\bullet(packed)[$1]}xmsg;
            "\n" . $list;
        }xmsge;

        # Done.  Return the results.
        return $text;
    };
    return $to_thread;
}

##############################################################################
# Helper methods
##############################################################################

# Word-wrap a paragraph of text.  This is a helper function for _wrap, mostly
# so that it can be invoked recursively to wrap bulleted paragraphs.
#
# If the paragraph looks like regular text, which means indented by two or
# four spaces and consistently on each line, remove the indentation and then
# add it back in while wrapping the text.
#
# $para        - A paragraph of text to wrap
# $options_ref - Options to controll the wrapping
#   ignore_indent - Ignore indentation when choosing whether to wrap
#
# Returns: The wrapped paragraph
sub _wrap_paragraph {
    my ($self, $para, $options_ref) = @_;
    $options_ref //= {};
    my ($indent) = ($para =~ m{ \A ([ ]*) \S }xms);

    # If the indent is longer than five characters and the ignore indent
    # option is not set, leave it alone.  Allow an indent of five characters
    # since it may be a continuation of a numbered list entry.
    if (length($indent) > 5 && !$options_ref->{ignore_indent}) {
        return $para;
    }

    # If this looks like thread commands or URLs, leave it alone.
    if ($para =~ m{ \A \s* (?: \\ | \[\d+\] ) }xms) {
        return $para;
    }

    # If this starts with a bullet, strip the bullet off, wrap the paragraph,
    # and then add it back in.
    if ($para =~ s{ \A (\s*) [*] (\s+) }{$1 $2}xms) {
        my $offset = length($1);
        $para = $self->_wrap_paragraph($para, { ignore_indent => 1 });
        substr($para, $offset, 1, q{*});
        return $para;
    }

    # If this starts with a number, strip the number off, wrap the paragraph,
    # and then add it back in.
    if ($para =~ s{\A (\s*) (\d+[.]) (\s+)}{$1 . q{ } x length($2) . $3}xmse) {
        my $offset = length($1);
        my $number = $2;
        $para = $self->_wrap_paragraph($para, { ignore_indent => 1 });
        substr($para, $offset, length($number), $number);
        return $para;
    }

    # If this looks like a Markdown block quote, strip trailing whitespace,
    # remove the leading indentation marks, wrap the paragraph, and then put
    # them back.
    ## no critic (RegularExpressions::ProhibitCaptureWithoutTest)
    if ($para =~ m{ \A (\s*) > \s }xms) {
        $para =~ s{ [ ]+ \n }{\n}xmsg;
        $para =~ s{ ^ (\s*) > (\s) }{$1 $2}xmsg;
        my $offset = length($1);
        $para = $self->_wrap_paragraph($para, { ignore_indent => 1 });
        $para =~ s{ ^ (\s{$offset}) \s }{$1>}xmsg;
        return $para;
    }
    ## use critic

    # If this looks like a bunch of short lines, leave it alone.
    if ($para =~ m{ \A (?: \Q$indent\E [^\n]{1,45} \n ){3,} }xms) {
        return $para;
    }

    # If this paragraph is not consistently indented, leave it alone.
    if ($para !~ m{ \A (?: \Q$indent\E \S[^\n]+ \n )+ \z }xms) {
        return $para;
    }

    # Strip the indent from each line.
    $para =~ s{ (?: \A | (?<=\n) ) \Q$indent\E }{}xmsg;

    # Remove any existing newlines, preserving two spaces after periods.
    $para =~ s{ [.] ([)\"]?) \n (\S) }{.$1  $2}xmsg;
    $para =~ s{ \n(\S) }{ $1}xmsg;

    # Force locally correct configuration of Text::Wrap.
    local $Text::Wrap::break    = qr{\s+}xms;
    local $Text::Wrap::columns  = $self->{width} + 1;
    local $Text::Wrap::huge     = 'overflow';
    local $Text::Wrap::unexpand = 0;

    # Do the wrapping.  This modifies @paragraphs in place.
    $para = wrap($indent, $indent, $para);

    # Strip any trailing whitespace, since some gets left behind after periods
    # by Text::Wrap.
    $para =~ s{ [ ]+ \n }{\n}xmsg;

    # All done.
    return $para;
}

# Word-wrap a block of text.  This requires some annoying heuristics, but the
# alternative is to try to get the template to always produce correctly
# wrapped results, which is far harder.
#
# $text - The text to wrap
#
# Returns: The wrapped text
sub _wrap {
    my ($self, $text) = @_;

    # First, break the text up into paragraphs.  (This will also turn more
    # than two consecutive newlines into just two newlines.)
    my @paragraphs = split(m{ \n(?:[ ]*\n)+ }xms, $text);

    # Add back the trailing newlines at the end of each paragraph.
    @paragraphs = map { $_ . "\n" } @paragraphs;

    # Wrap all of the paragraphs.  This modifies @paragraphs in place.
    for my $paragraph (@paragraphs) {
        $paragraph = $self->_wrap_paragraph($paragraph);
    }

    # Glue the paragraphs back together and return the result.  Because the
    # last newline won't get stripped by the split above, we have to strip an
    # extra newline from the end of the file.
    my $result = join("\n", @paragraphs);
    $result =~ s{ \n+ \z }{\n}xms;
    return $result;
}

##############################################################################
# Public interface
##############################################################################

# Create a new App::DocKnot::Generate object, which will be used for
# subsequent calls.
#
# $args  - Anonymous hash of arguments with the following keys:
#   metadata - Path to the directory containing package metadata
#   width    - Line length at which to wrap output files
#
# Returns: Newly created object
#  Throws: Text exceptions on invalid metadata directory path
sub new {
    my ($class, $args_ref) = @_;

    # Create the config reader.
    my %config_args;
    if ($args_ref->{metadata}) {
        $config_args{metadata} = $args_ref->{metadata};
    }
    my $config = App::DocKnot::Config->new(\%config_args);

    # Create and return the object.
    my $self = {
        config => $config,
        width  => $args_ref->{width} // 74,
    };
    bless($self, $class);
    return $self;
}

# Generate a documentation file from the package metadata.
#
# $template - Name of the documentation template (using Template Toolkit)
#
# Returns: The generated documentation as a string
#  Throws: autodie exception on failure to read metadata or write the output
#          Text exception on Template Toolkit failures
#          Text exception on inconsistencies in the package data
sub generate {
    my ($self, $template) = @_;

    # Load the package metadata.
    my $data_ref = $self->{config}->config();

    # Create the variable information for the template.  Start with all
    # metadata as loaded above.
    my %vars = %{$data_ref};

    # Add code references for our defined helper functions.
    $vars{center}    = $self->_code_for_center;
    $vars{copyright} = $self->_code_for_copyright($data_ref->{copyrights});
    $vars{indent}    = $self->_code_for_indent;
    $vars{to_text}   = $self->_code_for_to_text;
    $vars{to_thread} = $self->_code_for_to_thread;

    # Ensure we were given a valid template.
    $template = $self->appdata_path('templates', "${template}.tmpl");

    # Run Template Toolkit processing.
    my $tt = Template->new({ ABSOLUTE => 1 }) or croak(Template->error());
    my $result;
    $tt->process($template, \%vars, \$result) or croak($tt->error);

    # Word-wrap the results to our width and return them.
    return $self->_wrap($result);
}

# Generate all package documentation from the package metadata.  Only
# generates the output for templates with a default output file.
#
# Returns: undef
#  Throws: autodie exception on failure to read metadata or write the output
#          Text exception on Template Toolkit failures
#          Text exception on inconsistencies in the package data
sub generate_all {
    my ($self) = @_;
    for my $template (keys(%DEFAULT_OUTPUT)) {
        $self->generate_output($template);
    }
    return;
}

# Generate a documentation file from the package metadata.
#
# $template - Name of the documentation template
# $output   - Output file name (undef to use the default)
#
# Returns: undef
#  Throws: autodie exception on failure to read metadata or write the output
#          Text exception on Template Toolkit failures
#          Text exception on inconsistencies in the package data
sub generate_output {
    my ($self, $template, $output) = @_;
    $output //= $DEFAULT_OUTPUT{$template};

    # If the template doesn't have a default output file, $output is required.
    if (!defined($output)) {
        croak('missing required output argument');
    }

    # Generate the output.
    open(my $outfh, '>', $output);
    print {$outfh} encode('utf-8', $self->generate($template))
      or croak("cannot write to $output: $!");
    close($outfh);
    return;
}

##############################################################################
# Module return value and documentation
##############################################################################

1;
__END__

=for stopwords
Allbery DocKnot MERCHANTABILITY NONINFRINGEMENT XDG sublicense JSON CPAN
ARGS

=head1 NAME

App::DocKnot::Generate - Generate documentation from package metadata

=head1 SYNOPSIS

    use App::DocKnot::Generate;
    my $docknot = App::DocKnot::Generate->new({ metadata => 'docs/metadata' });
    my $readme = $docknot->generate('readme');
    my $index = $docknot->generate('thread');
    $docknot->generate_output('readme');
    $docknot->generate_output('thread', 'www/index.th')

=head1 REQUIREMENTS

Perl 5.24 or later and the modules File::BaseDir, File::ShareDir, JSON,
Perl6::Slurp, and Template (part of Template Toolkit), all of which are
available from CPAN.

=head1 DESCRIPTION

This component of DocKnot provides a system for generating consistent
human-readable software package documentation from metadata files, primarily
JSON and files containing documentation snippets.  It takes as input a
directory of metadata and a set of templates and generates a documentation
file from the metadata given the template name.

The path to the metadata directory for a package is given as an explicit
argument to the App::DocKnot::Generate constructor.  All other data (currently
templates and license information) is loaded via File::BaseDir and therefore
uses XDG paths by default.  This means that templates and other global
configuration are found by searching the following paths in order:

=over 4

=item 1.

F<$HOME/.config/docknot>

=item 2.

F<$XDG_CONFIG_DIRS/docknot> (F</etc/xdg/docknot> by default)

=item 3.

Files included in the package.

=back

Default templates and license files are included with the App::DocKnot module
and are used unless more specific configuration files exist.

=head1 CLASS METHODS

=over 4

=item new(ARGS)

Create a new App::DocKnot::Generate object.  This should be used for all
subsequent actions.  ARGS should be a hash reference with one or more of the
following keys:

=over 4

=item metadata

The path to the directory containing metadata for a package.  Default:
F<docs/metadata> relative to the current directory.

=item width

The wrap width to use when generating documentation.  Default: 74.

=back

=back

=head1 INSTANCE METHODS

=over 4

=item generate(TEMPLATE)

Load the metadata from the path given in the constructor and generate the
documentation file defined by TEMPLATE, which is the name of a template.  The
template itself will be loaded from the App::DocKnot configuration path as
described in L<DESCRIPTION>.  Returns the generated documentation file as a
string.

=item generate_all()

Generate all of the documentation files for a package.  This is currently
defined as the C<readme> and C<readme-md> templates.  The output will be
written to the default output locations, as described under generate_output().

=item generate_output(TEMPLATE [, OUTPUT])

The same as generate() except that rather than returning the generated
documentation file as a string, it will be written to the file named by
OUTPUT.  If that argument isn't given, a default based on the TEMPLATE
argument is chosen as follows:

    readme     ->  README
    readme-md  ->  README.md

If TEMPLATE isn't one of the templates listed above, the OUTPUT argument is
required.

=back

=head1 AUTHOR

Russ Allbery <rra@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2013-2020 Russ Allbery <rra@cpan.org>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

=head1 SEE ALSO

L<docknot(1)>

This module is part of the App-DocKnot distribution.  The current version of
App::DocKnot is available from CPAN, or directly from its web site at
L<https://www.eyrie.org/~eagle/software/docknot/>.

=cut

# Local Variables:
# copyright-at-end-flag: t
# End:
