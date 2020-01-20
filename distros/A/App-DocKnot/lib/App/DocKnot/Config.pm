# Read and return DocKnot package configuration.
#
# Parses the DocKnot package configuration and provides it to other DocKnot
# commands.
#
# SPDX-License-Identifier: MIT

##############################################################################
# Modules and declarations
##############################################################################

package App::DocKnot::Config 3.03;

use 5.024;
use autodie;
use parent qw(App::DocKnot);
use warnings;

use Carp qw(croak);
use File::Spec;
use JSON;
use Perl6::Slurp;

# Additional files to load from the metadata directory if they exist.  The
# contents of these files will be added to the configuration in a key of the
# same name.  If the key contains a slash, like foo/bar, it will be stored as
# a nested hash, as $data{foo}{bar}.
our @METADATA_FILES = qw(
  bootstrap
  build/middle
  build/suffix
  debian/summary
  packaging/extra
  support/extra
  test/prefix
  test/suffix
);

##############################################################################
# Helper methods
##############################################################################

# Internal helper routine to return the path of a file or directory from the
# package metadata directory.  The resulting file or directory path is not
# checked for existence.
#
# $self - The App::DocKnot::Generate object
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
# $self - The App::DocKnot::Generate object
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
# $self - The App::DocKnot::Generate object
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

##############################################################################
# Public Interface
##############################################################################

# Create a new App::DocKnot::Config object, which will be used for subsequent
# calls.
#
# $class - Class of object to create
# $args  - Anonymous hash of arguments with the following keys:
#   metadata - Path to the directory containing package metadata
#
# Returns: Newly created object
#  Throws: Text exceptions on invalid metadata directory path
sub new {
    my ($class, $args_ref) = @_;

    # Ensure we were given a valid metadata argument.
    my $metadata = $args_ref->{metadata};
    if (!defined($metadata)) {
        $metadata = 'docs/metadata';
    }
    if (!-d $metadata) {
        croak("metadata path $metadata does not exist or is not a directory");
    }

    # Create and return the object.
    my $self = { metadata => $metadata };
    bless($self, $class);
    return $self;
}

# Load the DocKnot package configuration.
#
# $self - The App::DocKnot::Config object
#
# Returns: The package configuration as a dict
#  Throws: autodie exception on failure to read metadata
#          Text exception on inconsistencies in the package data
sub config {
    my ($self) = @_;

    # Localize $@ since we catch and ignore a lot of exceptions and don't want
    # to leak changes to $@ to the caller.
    local $@ = q{};

    # Load the package metadata from JSON.
    my $data_ref = $self->_load_metadata_json('metadata.json');

    # build.install defaults to true.
    if (!exists($data_ref->{build}{install})) {
        $data_ref->{build}{install} = 1;
    }

    # Load supplemental README sections.  readme.sections will contain a list
    # of sections to add to the README file.
    for my $section ($data_ref->{readme}{sections}->@*) {
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
    my $licenses_ref = $self->load_appdata_json('licenses.json');
    if (!exists($licenses_ref->{$license})) {
        die "Unknown license $license\n";
    }
    my $license_text = slurp($self->appdata_path('licenses', $license));
    $data_ref->{license} = { $licenses_ref->{$license}->%* };
    $data_ref->{license}{full} = $license_text;

    # Load additional license notices if they exist.
    eval { $data_ref->{license}{notices} = $self->_load_metadata('notices') };

    # Load the standard sections.
    $data_ref->{blurb}        = $self->_load_metadata('blurb');
    $data_ref->{description}  = $self->_load_metadata('description');
    $data_ref->{requirements} = $self->_load_metadata('requirements');

    # Load optional information if it exists.
    for my $file (@METADATA_FILES) {
        my @file = split(m{/}xms, $file);
        if (scalar(@file) == 1) {
            eval { $data_ref->{$file} = $self->_load_metadata(@file) };
        } else {
            eval {
                $data_ref->{ $file[0] }{ $file[1] }
                  = $self->_load_metadata(@file);
            };
        }
    }

    # Return the resulting configuration.
    return $data_ref;
}

##############################################################################
# Module return value and documentation
##############################################################################

1;
__END__

=for stopwords
Allbery DocKnot MERCHANTABILITY NONINFRINGEMENT sublicense CPAN XDG

=head1 NAME

App::DocKnot::Config - Read and return DocKnot package configuration

=head1 SYNOPSIS

    use App::DocKnot::Config;
    my $reader = App::DocKnot::Config->new({ metadata => 'docs/metadata' });
    my $config = $reader->config();

=head1 REQUIREMENTS

Perl 5.24 or later and the modules File::BaseDir, File::ShareDir, JSON, and
Perl6::Slurp, all of which are available from CPAN.

=head1 DESCRIPTION

This component of DocKnot reads and returns the configuration for a package.
It takes as input a directory of metadata and returns the configuration
information as a hash.

Additional metadata about specific licenses is loaded via File::BaseDir and
therefore uses XDG paths by default.  This means that license metadata is
found by searching the following paths in order:

=over 4

=item 1.

F<$HOME/.config/docknot>

=item 2.

F<$XDG_CONFIG_DIRS/docknot> (F</etc/xdg/docknot> by default)

=item 3.

Files included in the package.

=back

Default license metadata files are included with the App::DocKnot module and
are used unless more specific configuration files exist.

=head1 CLASS METHODS

=over 4

=item new(ARGS)

Create a new App::DocKnot::Config object.  This should be used for all
subsequent actions.  ARGS should be a hash reference with one or more of the
following keys:

=over 4

=item metadata

The path to the directory containing metadata for a package.  Default:
F<docs/metadata> relative to the current directory.

=back

=back

=head1 INSTANCE METHODS

=over 4

=item config()

Load the metadata for the package and return it as a hash.  The possible keys
of this hash and the possible values are not yet documented.

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
