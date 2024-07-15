# Generate HTML from a pointer to an external file.
#
# The input tree for spin may contain pointers to external files in various
# formats.  This module parses those pointer files and performs the conversion
# of those external files into HTML.
#
# SPDX-License-Identifier: MIT

##############################################################################
# Modules and declarations
##############################################################################

package App::DocKnot::Spin::Pointer v8.0.1;

use 5.024;
use autodie;
use parent qw(App::DocKnot);
use warnings FATAL => 'utf8';

use App::DocKnot::Config;
use App::DocKnot::Spin::Text;
use App::DocKnot::Util qw(is_newer);
use Carp qw(croak);
use Encode qw(decode);
use File::BaseDir qw(config_files);
use IPC::System::Simple qw(capturex);
use Path::Tiny qw(path);
use Pod::Thread 3.01 ();
use POSIX qw(strftime);
use Template ();
use YAML::XS ();

# The URL to the software page for this package, used to embed a link to the
# software that generated the page.
my $URL = 'https://www.eyrie.org/~eagle/software/docknot/';

##############################################################################
# Format conversions
##############################################################################

# Convert a Markdown file to HTML.
#
# $data_ref - Data from the pointer file
#   path  - Path to the Markdown file to convert
#   style - Style sheet to use
#   title - Title of the page
# $base     - Base path of pointer file (for relative paths)
# $output   - Path to the output file
#
# Throws: Text exception on conversion failure
sub _spin_markdown {
    my ($self, $data_ref, $base, $output) = @_;
    my $source = path($data_ref->{path})->absolute($base);

    # Do the Markdown conversion using pandoc.
    my $html = capturex(
        $self->{pandoc_path}, '--wrap=preserve', '-f', 'markdown',
        '-t', 'html', $source,
    );

    # Pull the title out of the contents of the <h1> header if not set.
    my $title = $data_ref->{title};
    if (!defined($title)) {
        ($title) = $html =~ m{ <h1 [^>]+ > (.*?) </h1> }xms;
    }

    # Construct the template variables.
    my ($links, $navbar, $style);
    if ($self->{sitemap}) {
        my $page = $output->relative($self->{output});
        my @links = $self->{sitemap}->links($page);
        if (@links) {
            $links = join(q{}, @links);
        }
        my @navbar = $self->{sitemap}->navbar($page);
        if (@navbar) {
            $navbar = join(q{}, @navbar);
        }
    }
    if ($data_ref->{style}) {
        $style = $self->{style_url} . $data_ref->{style} . '.css';
    }
    my %vars = (
        docknot_url => $URL,
        html        => decode('utf-8', $html),
        links       => $links,
        modified    => strftime('%Y-%m-%d', gmtime($source->stat()->[9])),
        navbar      => $navbar,
        now         => strftime('%Y-%m-%d', gmtime()),
        style       => $style,
        title       => $title,
    );

    # Construct the output page from those template variables.
    my $result;
    $self->{template}->process($self->{template_path}, \%vars, \$result)
      or croak($self->{template}->error());

    # Write the result to the output file.
    $output->spew_utf8($result);
    return;
}

# Convert a POD file to HTML.
#
# $data_ref - Data from the pointer file
#   options - Hash of conversion options
#     contents - Whether to add a table of contents
#     navbar   - Whether to add a navigation bar
#   path    - Path to the POD file to convert
#   style   - Style sheet to use
#   title   - Title of the page
# $base     - Base path of pointer file (for relative paths)
# $output   - Path to the output file
#
# Throws: Text exception on conversion failure
sub _spin_pod {
    my ($self, $data_ref, $base, $output) = @_;
    my $source = path($data_ref->{path})->absolute($base);

    # Construct the Pod::Thread formatter object.
    my %options = (
        contents => $data_ref->{options}{contents},
        style    => $data_ref->{style} // 'pod',
        title    => $data_ref->{title},
    );
    if (exists($data_ref->{options}{navbar})) {
        $options{navbar} = $data_ref->{options}{navbar};
    } else {
        $options{navbar} = 1;
    }
    my $podthread = Pod::Thread->new(%options);

    # Convert the POD to thread.
    my $data;
    $podthread->output_string(\$data);
    $podthread->parse_file("$source");
    $data = decode('utf-8', $data);

    # Spin that page into HTML.
    $self->{thread}->spin_thread_output($data, $source, 'POD', $output);
    return;
}

# Convert a text file to HTML.
#
# $data_ref - Data form the pointer file
#   options - Hash of conversion options
#     modified - Whether to add a last modified subheader
#   path    - Path to the text file to convert
#   style   - Style sheet to use
#   title   - Title of the page
# $base     - Base path of pointer file (for relative paths)
# $output   - Path to the output file
#
# Throws: Text exception on conversion failure
sub _spin_text {
    my ($self, $data_ref, $base, $output) = @_;
    my $source = path($data_ref->{path})->absolute($base);

    # Determine the style URL.
    my $style = ($data_ref->{style} // 'faq') . '.css';
    if ($self->{style_url}) {
        $style = $self->{style_url} . $style;
    }

    # Create the formatter object.
    my %options = (
        modified => $data_ref->{options}{modified},
        output   => $self->{output},
        sitemap  => $self->{sitemap},
        style    => $style,
        title    => $data_ref->{title},
    );
    my $text = App::DocKnot::Spin::Text->new(\%options);

    # Generate the output page.
    $text->spin_text_file($source, $output);
    return;
}

##############################################################################
# Public interface
##############################################################################

# Create a new HTML converter for pointers.  This object can (and should) be
# reused for all pointer conversions done while spinning a tree of files.
#
# $args - Anonymous hash of arguments with the following keys:
#   output    - Root of the output tree
#   sitemap   - App::DocKnot::Spin::Sitemap object
#   style-url - Partial URL to style sheets
#   thread    - App::DocKnot::Spin::Thread object
#
# Returns: Newly created object
#  Throws: Text exception on failure to initialize Template Toolkit
sub new {
    my ($class, $args_ref) = @_;

    # Get the configured path to pandoc, if any.
    my $config_reader = App::DocKnot::Config->new();
    my $global_config_ref = $config_reader->global_config();
    my $pandoc = $global_config_ref->{pandoc} // 'pandoc';

    # Add a trailing slash to the partial URL for style sheets.
    my $style_url = $args_ref->{'style-url'} // q{};
    if ($style_url) {
        $style_url =~ s{ /* \z }{/}xms;
    }

    # Create and return the object.
    my $tt = Template->new({ ABSOLUTE => 1, ENCODING => 'utf8' })
      or croak(Template->error());
    my $self = {
        output      => $args_ref->{output},
        pandoc_path => $pandoc,
        sitemap     => $args_ref->{sitemap},
        style_url   => $style_url,
        template    => $tt,
        thread      => $args_ref->{thread},
    };
    bless($self, $class);
    $self->{template_path} = $self->appdata_path('templates', 'html.tmpl');
    return $self;
}

# Check if the result of a pointer file needs to be regenerated.
#
# $pointer - Path to pointer file
# $output  - Path to corresponding output file
#
# Returns: True if the output file does not exist or has a modification date
#          older than either the pointer file or the underlying source file,
#          false otherwise
#  Throws: YAML::XS exception on invalid pointer
sub is_out_of_date {
    my ($self, $pointer, $output) = @_;
    my $data_ref = $self->load_yaml_file($pointer, 'pointer');
    my $path = path($data_ref->{path})->absolute($pointer->parent());
    if (!$path->exists()) {
        die "$pointer: path $data_ref->{path} ($path) does not exist\n";
    }
    return !is_newer($output, $pointer, $path);
}

# Process a given pointer file.
#
# $pointer - Path to pointer file to process
# $output  - Path to corresponding output file
#
# Throws: YAML::XS exception on invalid pointer
#         Text exception for missing input file
#         Text exception on failure to convert the file
sub spin_pointer {
    my ($self, $pointer, $output, $options_ref) = @_;
    my $data_ref = $self->load_yaml_file($pointer, 'pointer');
    $data_ref->{options} //= {};

    # Dispatch to the appropriate conversion function.
    if ($data_ref->{format} eq 'markdown') {
        $self->_spin_markdown($data_ref, $pointer->parent(), $output);
    } elsif ($data_ref->{format} eq 'pod') {
        $self->_spin_pod($data_ref, $pointer->parent(), $output);
    } elsif ($data_ref->{format} eq 'text') {
        $self->_spin_text($data_ref, $pointer->parent(), $output);
    } else {
        die "$pointer: unknown output format $data_ref->{format}\n";
    }
    return;
}

##############################################################################
# Module return value and documentation
##############################################################################

1;

__END__

=for stopwords
Allbery DocKnot MERCHANTABILITY NONINFRINGEMENT Kwalify sublicense unstyled
navbar

=head1 NAME

App::DocKnot::Spin::Pointer - Generate HTML from a pointer to an external file

=head1 SYNOPSIS

    use App::DocKnot::Spin::Pointer;
    use App::DocKnot::Spin::Sitemap;
    use Path::Tiny qw(path);

    my $sitemap_path = path('/input/.sitemap');
    my $sitemap = App::DocKnot::Spin::Sitemap->new($sitemap_path);
    my $pointer = App::DocKnot::Spin::Pointer->new({
        output  => path('/output'),
        sitemap => $sitemap,
    });
    my $input = path('/input/file.spin');
    my $output = path('/output/file.html');
    $pointer->spin_pointer($input, $output);

=head1 REQUIREMENTS

Perl 5.24 or later and the modules File::ShareDir, Kwalify, List::SomeUtils,
Path::Tiny, Pod::Thread, and YAML::XS, all of which are available from CPAN.

=head1 DESCRIPTION

The tree of input files for App::DocKnot::Spin may contain pointers to
external files in various formats.  These files are in YAML format and end in
C<.spin>.  This module processes those files and converts them to HTML and, if
so configured, adds the links to integrate the page with the rest of the site.

For the details of the pointer file format, see L<POINTER FILES> below.

=head1 CLASS METHODS

=over 4

=item new(ARGS)

Create a new App::DocKnot::Spin::Pointer object.  A single converter object
can be used repeatedly to convert pointers in a tree of files.  ARGS should
be a hash reference with one or more of the following keys, all of which are
optional:

=over 4

=item output

The path to the root of the output tree when converting a tree of files.  This
will be used to calculate relative path names for generating inter-page links
using the provided C<sitemap> argument.  If C<sitemap> is given, this option
should also always be given.

=item sitemap

An App::DocKnot::Spin::Sitemap object.  This will be used to create inter-page
links.  For inter-page links, the C<output> argument must also be provided.

=item style-url

The base URL for style sheets.  A style sheet specified in a pointer file will
be considered to be relative to this URL and this URL will be prepended to it.
If this option is not given, the name of the style sheet will be used verbatim
as its URL, except with C<.css> appended.

=item thread

An App::DocKnot::Spin::Thread object, used for converting POD into HTML.  It
should be configured with the same App::DocKnot::Spin::Sitemap object as the
C<sitemap> argument.

=back

=back

=head1 INSTANCE METHODS

=over 4

=item is_out_of_date(POINTER, OUTPUT)

Returns true if OUTPUT is missing or if it was modified less recently than the
modification time of either POINTER or the underlying file that it points to.
Both paths must be Path::Tiny objects.

=item spin_pointer(POINTER, OUTPUT)

Convert a single pointer file to HTML.  POINTER is the path to the pointer
file, and OUTPUT is the path to where to write the output.  Both paths must
be Path::Tiny objects.

=back

=head1 POINTER FILES

A pointer file is a YAML file ending in C<.spin> that points to the source
file for a generated HTML page and provides additional configuration for its
conversion.  The valid keys for a pointer file are:

=over 4

=item format

The format of the source file.  Supported values are C<markdown>, C<pod>, and
C<text>.  Required.

=item path

The path to the source file.  It may be relative, in which case it's relative
to the pointer file.  Required.

=item options

Additional options that control the conversion to HTML.  These will be
different for each supported format.

C<markdown> has no supported options.

The supported options for a format of C<pod> are:

=over 4

=item contents

Boolean saying whether to generate a table of contents.  The default is false.

=item navbar

Boolean saying whether to generate a navigation bar at the top of the page.
The default is true.

=back

The supported options for a format of C<text> are:

=over 4

=item modified

Boolean saying whether to add a last modified header.  This will always be
done if the file contains a CVS-style C<$Id$> string, but otherwise will only
be done if this option is set to true.  The default is false.

=back

=item style

The style sheet to use for the converted output.  Optional.  If not set,
converted C<markdown> output will be unstyled, converted C<pod> output will
use a style sheet named C<pod>, and converted C<text> output will use a style
sheet named C<faq>.

=item title

The title of the converted page.  Optional.  If not set, the title will be
taken from the converted file in a format-specific way.  For Markdown, the
title will be the contents of the first top-level heading.  For POD, the title
will be taken from a NAME section formatted according to the conventions for
manual pages.

=back

=head1 AUTHOR

Russ Allbery <rra@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2021, 2024 Russ Allbery <rra@cpan.org>

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

L<docknot(1)>, L<App::DocKnot::Spin>, L<App::DocKnot::Spin::Sitemap>

This module is part of the App-DocKnot distribution.  The current version of
DocKnot is available from CPAN, or directly from its web site at
L<https://www.eyrie.org/~eagle/software/docknot/>.

=cut

# Local Variables:
# copyright-at-end-flag: t
# End:
