# Implementation of the DocKnot application.
#
# This is the primary class for the DocKnot application, which supports
# generation of various documentation files based on package metadata and
# general templates.
#
# SPDX-License-Identifier: MIT

##############################################################################
# Modules and declarations
##############################################################################

package App::DocKnot 1.04;

use 5.018;
use autodie;
use warnings;

use Carp qw(croak);
use File::BaseDir qw(config_files);
use File::ShareDir qw(module_file);
use File::Spec;
use JSON;
use Perl6::Slurp;
use Template;
use Text::Wrap qw(wrap);

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
# $self - The App::DocKnot object
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
# $self           - The App::DocKnot object
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
        for my $copyright (@{$copyrights_ref}) {
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
# $self - The App::DocKnot object
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
# $self - The App::DocKnot object
#
# Returns: Code reference to a closure that takes a block of text and returns
#          the coverted text
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

        # Remove URLs from all links, replacing them with numeric references,
        # and accumulate the mapping of numbers to URLs in %urls.
        my %urls;
        my $ref = 1;
        while ($text =~ s{ \[ ([^\]]+) \] [(] (\S+) [)] }{$1 [$ref]}xms) {
            $urls{$ref} = $2;
            $ref++;
        }

        # If there are any URLs, add an additional paragraph with all the
        # references and URLs.
        if (%urls) {
            my @refs = map { "[$_] $urls{$_}" } sort { $a <=> $b } keys(%urls);
            $text .= join("\n", q{}, @refs, q{});
        }
        return $text;
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
# $self - The App::DocKnot object
#
# Returns: Code reference to a closure that takes a block of text and returns
#          the coverted thread
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

# Internal helper routine to return the path of a file from the application
# data.  These data files are installed with App::DocKnot, but each file can
# be overridden by the user via files in $HOME/.config/docknot or
# /etc/xdg/docknot (or whatever $XDG_CONFIG_DIRS is set to).
#
# We therefore try File::BaseDir first (which handles the XDG paths) and fall
# back on using File::ShareDir to locate the data.
#
# $self - The App::DocKnot object
# @path - The relative path of the file as a list of components
#
# Returns: The absolute path to the application data
#  Throws: Text exception on failure to locate the desired file
sub _appdata_path {
    my ($self, @path) = @_;

    # Try XDG paths first.
    my $path = config_files('docknot', @path);

    # If that doesn't work, use the data that came with the module.
    if (!defined($path)) {
        $path = module_file('App::DocKnot', File::Spec->catfile(@path));
    }
    return $path;
}

# Internal helper routine that locates an application data file, interprets it
# as JSON, and returns the resulting decoded contents.  This uses the relaxed
# parsing mode, so comments and commas after data elements are supported.
#
# $self - The App::DocKnot object
# @path - The path of the file to load, as a list of components
#
# Returns: Anonymous hash or array resulting from decoding the JSON object
#  Throws: slurp or JSON exception on failure to load or decode the object
sub _load_appdata_json {
    my ($self, @path) = @_;
    my $path = $self->_appdata_path(@path);
    my $json = JSON->new;
    $json->relaxed;
    return $json->decode(scalar(slurp($path)));
}

# Internal helper routine to return the path of a file or directory from the
# package metadata directory.  The resulting file or directory path is not
# checked for existence.
#
# $self - The App::DocKnot object
# @path - The relative path of the file as a list of components
#
# Returns: The absolute path in the metadata directory
sub _metadata_path {
    my ($self, @path) = @_;
    return File::Spec->catdir($self->{metadata}, @path);
}

# Internal helper routine to read a file from the package metadata directory
# and return the contents.  The file is specified as a list of path
# components.
#
# $self - The App::DocKnot object
# @path - The path of the file to load, as a list of components
#
# Returns: The contents of the file as a string
#  Throws: slurp exception on failure to read the file
sub _load_metadata {
    my ($self, @path) = @_;
    return slurp($self->_metadata_path(@path));
}

# Like _load_metadata, but interprets the contents of the metadata file as
# JSON and decodes it, returning the resulting object.  This uses the relaxed
# parsing mode, so comments and commas after data elements are supported.
#
# $self - The App::DocKnot object
# @path - The path of the file to load, as a list of components
#
# Returns: Anonymous hash or array resulting from decoding the JSON object
#  Throws: slurp or JSON exception on failure to load or decode the object
sub _load_metadata_json {
    my ($self, @path) = @_;
    my $data = $self->_load_metadata(@path);
    my $json = JSON->new;
    $json->relaxed;
    return $json->decode($data);
}

# Word-wrap a paragraph of text.  This is a helper function for _wrap, mostly
# so that it can be invoked recursively to wrap bulleted paragraphs.
#
# If the paragraph looks like regular text, which means indented by two or
# four spaces and consistently on each line, remove the indentation and then
# add it back in while wrapping the text.
#
# $self      - The App::DocKnot object
# $paragraph - A paragraph of text to wrap
#
# Returns: The wrapped paragraph
sub _wrap_paragraph {
    my ($self, $paragraph) = @_;
    my ($indent) = ($paragraph =~ m{ \A ([ ]*) \S }xms);

    # If the indent is longer than four characters, leave it alone.
    if (length($indent) > 4) {
        return $paragraph;
    }

    # If this looks like thread commands or URLs, leave it alone.
    if ($paragraph =~ m{ \A \s* (?: \\ | \[\d+\] ) }xms) {
        return $paragraph;
    }

    # If this starts with a bullet, strip the bullet off, wrap the paragaraph,
    # and then add it back in.
    if ($paragraph =~ s{ \A (\s*) [*] (\s+) }{$1 $2}xms) {
        my $offset = length($1);
        $paragraph = $self->_wrap_paragraph($paragraph);
        substr($paragraph, $offset, 1, q{*});
        return $paragraph;
    }

    # If this looks like a Markdown block quote leave it alone, but strip
    # trailing whitespace.
    if ($paragraph =~ m{ \A \s* > \s }xms) {
        $paragraph =~ s{ [ ]+ \n }{\n}xmsg;
        return $paragraph;
    }

    # If this paragraph is not consistently indented, leave it alone.
    if ($paragraph !~ m{ \A (?: \Q$indent\E \S[^\n]+ \n )+ \z }xms) {
        return $paragraph;
    }

    # Strip the indent from each line.
    $paragraph =~ s{ (?: \A | (?<=\n) ) \Q$indent\E }{}xmsg;

    # Remove any existing newlines, preserving two spaces after periods.
    $paragraph =~ s{ [.] ([)\"]?) \n (\S) }{.$1  $2}xmsg;
    $paragraph =~ s{ \n(\S) }{ $1}xmsg;

    # Force locally correct configuration of Text::Wrap.
    local $Text::Wrap::break    = qr{\s+}xms;
    local $Text::Wrap::columns  = $self->{width} + 1;
    local $Text::Wrap::huge     = 'overflow';
    local $Text::Wrap::unexpand = 0;

    # Do the wrapping.  This modifies @paragraphs in place.
    $paragraph = wrap($indent, $indent, $paragraph);

    # Strip any trailing whitespace, since some gets left behind after periods
    # by Text::Wrap.
    $paragraph =~ s{ [ ]+ \n }{\n}xmsg;

    # All done.
    return $paragraph;
}

# Word-wrap a block of text.  This requires some annoying heuristics, but the
# alternative is to try to get the template to always produce correctly
# wrapped results, which is far harder.
#
# $self - The App::DocKnot object
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

# Create a new App::DocKnot object, which will be used for subsequent calls.
#
# $class - Class of object to create
# $args  - Anonymous hash of arguments with the following keys:
#   width    - Line length at which to wrap output files
#   metadata - Path to the directory containing package metadata
#
# Returns: Newly created object
#  Throws: Text exceptions on invalid metadata directory path
sub new {
    my ($class, $args_ref) = @_;

    # Ensure we were given a valid metadata argument.
    my $metadata = $args_ref->{metadata};
    if (!defined($metadata)) {
        croak('Missing metadata argument to new');
    }
    if (!-d $metadata) {
        croak("Metadata path $metadata does not exist or is not a directory");
    }

    # Create and return the object.
    my $self = {
        metadata => $metadata,
        width    => $args_ref->{width} // 74,
    };
    bless($self, $class);
    return $self;
}

# Generate a documentation file from the package metadata.  Takes the template
# to use and returns the generated documentation.
#
# $self     - The App::DocKnot object
# $template - Name of the documentation template (using Template Toolkit)
#
# Returns: The generated documentation as a string
#  Throws: autodie exception on failure to read metadata or write the output
#          Text exception on Template Toolkit failures
#          Text exception on inconsistencies in the package data
sub generate {
    my ($self, $template) = @_;

    # Load the package metadata from JSON.
    my $data_ref = $self->_load_metadata_json('metadata.json');

    # Load supplemental README sections.  readme.sections will contain a list
    # of sections to add to the README file.
    for my $section (@{ $data_ref->{readme}{sections} }) {
        my $title = $section->{title};

        # The file containing the section data will match the title, converted
        # to lowercase and with spaces changed to dashes.
        my $file = lc($title);
        $file =~ tr{ }{-};

        # Load the section content.
        $section->{body} = $self->_load_metadata('sections', $file);

        # If this contains a testing section, that overrides our default.  Set
        # a flag so that the templates know this has happened.
        if ($file eq 'testing') {
            $data_ref->{readme}{testing} = 1;
        }
    }

    # If the package is marked orphaned, load the explanation.
    if ($data_ref->{orphaned}) {
        $data_ref->{orphaned} = $self->_load_metadata('orphaned');
    }

    # If the package has a quote, load the text of the quote.
    if ($data_ref->{quote}) {
        $data_ref->{quote}{text} = $self->_load_metadata('quote');
    }

    # Expand the package license into license text.
    my $license      = $data_ref->{license};
    my $licenses_ref = $self->_load_appdata_json('licenses.json');
    if (!exists($licenses_ref->{$license})) {
        die "Unknown license $license\n";
    }
    my $license_text = slurp($self->_appdata_path('licenses', $license));
    $data_ref->{license} = { %{ $licenses_ref->{$license} } };
    $data_ref->{license}{full} = $license_text;

    # Load additional license notices if they exist.
    eval { $data_ref->{license}{notices} = $self->_load_metadata('notices') };

    # Create the variable information for the template.  Start with all
    # metadata as loaded above.
    my %vars = %{$data_ref};

    # Load the standard sections.
    $vars{blurb}        = $self->_load_metadata('blurb');
    $vars{description}  = $self->_load_metadata('description');
    $vars{requirements} = $self->_load_metadata('requirements');

    # Load bootstrap and Debian summary information if it exists.
    eval { $vars{bootstrap} = $self->_load_metadata('bootstrap') };
    eval {
        $vars{debian}{summary} = $self->_load_metadata('debian', 'summary');
    };

    # Load build sections if they exist.
    eval { $vars{build}{middle} = $self->_load_metadata('build', 'middle') };
    eval { $vars{build}{suffix} = $self->_load_metadata('build', 'suffix') };

    # build.install defaults to true.
    if (!exists($vars{build}{install})) {
        $vars{build}{install} = 1;
    }

    # Load testing sections if they exist.
    eval { $vars{test}{prefix} = $self->_load_metadata('test', 'prefix') };
    eval { $vars{test}{suffix} = $self->_load_metadata('test', 'suffix') };

    # Load support sections if they exist.
    eval { $vars{support}{extra} = $self->_load_metadata('support', 'extra') };

    # Add code references for our defined helper functions.
    $vars{center}    = $self->_code_for_center;
    $vars{copyright} = $self->_code_for_copyright($data_ref->{copyrights});
    $vars{indent}    = $self->_code_for_indent;
    $vars{to_text}   = $self->_code_for_to_text;
    $vars{to_thread} = $self->_code_for_to_thread;

    # Find the path to the relevant template.
    $template = $self->_appdata_path('templates', "${template}.tmpl");

    # Run Template Toolkit processing.
    my $tt = Template->new({ ABSOLUTE => 1 }) or die Template->error . "\n";
    my $result;
    $tt->process($template, \%vars, \$result) or die $tt->error . "\n";

    # Word-wrap the results to our width and return them.
    return $self->_wrap($result);
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

App::DocKnot - Generate human-readable documentation from package metadata

=head1 SYNOPSIS

    my $docknot = App::DocKnot->new({ metadata => 'docs/metadata' });
    my $readme = $docknot->generate('readme');
    my $index = $docknot->generate('thread');

=head1 REQUIREMENTS

Perl 5.18 or later and the modules File::BaseDir, File::ShareDir, JSON,
Perl6::Slurp, and Template (part of Template Toolkit), all of which are
available from CPAN.

=head1 DESCRIPTION

DocKnot is a system for generating consistent human-readable software package
documentation from metadata files, primarily JSON and files containing
documentation snippets.  It takes as input a directory of metadata and a set
of templates and generates a documentation file from the metadata given the
template name.

The path to the metadata directory for a package is given as an explicit
argument to the App::DocKnot constructor.  All other data (currently templates
and license information) is loaded via File::BaseDir and therefore uses XDG
paths by default.  This means that templates and other global configuration
are found by searching the following paths in order:

=over 4

=item 1.

F<$HOME/.config/docknot>

=item 2.

F<$XDG_CONFIG_DIRS/docknot> (F</etc/xdg/docknot> by default)

=item 3.

Files included in the package.

=back

As noted above, default templates and license files are included with the
App::DocKnot module and are used unless more specific configuration files
exist.

=head1 CLASS METHODS

=over 4

=item new(ARGS)

Create a new App::DocKnot object.  This should be used for all subsequent
actions.  ARGS should be a hash reference with one or more of the following
keys:

=over 4

=item metadata

The path to the directory containing metadata for a package.  This argument is
required.

=item width

The wrap width to use when generating documentation.  Default is 74.

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

=back

=head1 AUTHOR

Russ Allbery <rra@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2013-2018 Russ Allbery <rra@cpan.org>

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

This module is part of the DocKnot distribution.  The current version of
App::DocKnot is available from CPAN, or directly from its web site at
L<https://www.eyrie.org/~eagle/software/docknot/>.

=cut

# Local Variables:
# copyright-at-end-flag: t
# End:
