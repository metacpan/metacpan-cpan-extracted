# Update package configuration for a DocKnot version upgrade.
#
# Adjusts the DocKnot configuration data for changes in format for newer
# versions of DocKnot.
#
# SPDX-License-Identifier: MIT

##############################################################################
# Modules and declarations
##############################################################################

package App::DocKnot::Update 7.00;

use 5.024;
use autodie;
use parent qw(App::DocKnot);
use warnings;

use Carp qw(croak);
use JSON::MaybeXS qw(JSON);
use Kwalify qw(validate);
use Path::Iterator::Rule;
use Path::Tiny qw(path);
use YAML::XS ();

# The older JSON metadata format stored text snippets in separate files in the
# file system.  This is the list of additional files to load from the metadata
# directory if they exist.  The contents of these files will be added to the
# configuration in a key of the same name.  If the key contains a slash, like
# foo/bar, it will be stored as a nested hash, as $data{foo}{bar}.
our @JSON_METADATA_FILES = qw(
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
# JSON helper methods
##############################################################################

# Internal helper routine to return the path of a file or directory from the
# package metadata directory.  The resulting file or directory path is not
# checked for existence.
#
# @path - The relative path of the file as a list of components
#
# Returns: Path::Tiny for the metadata file
sub _metadata_path {
    my ($self, @path) = @_;
    return path($self->{metadata}, @path);
}

# Internal helper routine to read a file from the package metadata directory
# and return the contents.  The file is specified as a list of path
# components.
#
# @path - The path of the file to load, as a list of components
#
# Returns: The contents of the file as a string
#  Throws: slurp exception on failure to read the file
sub _load_metadata {
    my ($self, @path) = @_;
    my $path = $self->_metadata_path(@path);
    return $path->slurp_utf8();
}

# Like _load_metadata, but interprets the contents of the metadata file as
# JSON and decodes it, returning the resulting object.  This uses the relaxed
# parsing mode, so comments and commas after data elements are supported.
#
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

# Load the legacy JSON DocKnot package configuration.
#
# Returns: The package configuration as a dict
#  Throws: autodie exception on failure to read metadata
#          Text exception on inconsistencies in the package data
sub _config_from_json {
    my ($self) = @_;

    # Localize $@ since we catch and ignore a lot of exceptions and don't want
    # to leak changes to $@ to the caller.
    local $@ = q{};

    # Load the package metadata from JSON.
    my $data_ref = $self->_load_metadata_json('metadata.json');

    # Load supplemental README sections.  readme.sections will contain a list
    # of sections to add to the README file.
    for my $section_ref ($data_ref->{readme}{sections}->@*) {
        my $title = $section_ref->{title};

        # The file containing the section data will match the title, converted
        # to lowercase and with spaces changed to dashes.
        my $file = lc($title);
        $file =~ tr{ }{-};

        # Load the section content.
        $section_ref->{body} = $self->_load_metadata('sections', $file);
    }

    # If there are no supplemental README sections, remove that data element.
    if (!$data_ref->{readme}{sections}->@*) {
        delete($data_ref->{readme});
    }

    # If the package is marked orphaned, load the explanation.
    if ($data_ref->{orphaned}) {
        $data_ref->{orphaned} = $self->_load_metadata('orphaned');
    }

    # If the package has a quote, load the text of the quote.
    if ($data_ref->{quote}) {
        $data_ref->{quote}{text} = $self->_load_metadata('quote');
    }

    # Move the name of the license to its new metadata key.
    my $license = $data_ref->{license};
    $data_ref->{license} = { name => $license };

    # Load additional license notices if they exist.
    eval { $data_ref->{license}{notices} = $self->_load_metadata('notices') };

    # Load the standard sections.
    $data_ref->{blurb} = $self->_load_metadata('blurb');
    $data_ref->{description} = $self->_load_metadata('description');
    $data_ref->{requirements} = $self->_load_metadata('requirements');

    # Load optional information if it exists.
    for my $file (@JSON_METADATA_FILES) {
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
# Spin helper methods
##############################################################################

# Given an old-format *.rpod pointer file, read the master file name and any
# options.  Return them in the structure used for *.spin pointer files.
#
# $path - Path::Tiny for the file to read
#
# Returns: Hash in the format of a *.spin pointer file
#  Throws: Text exception if no master file is present in the pointer
#          autodie exception if the pointer file could not be read
sub _read_rpod_pointer {
    my ($self, $path) = @_;

    # Read the pointer file.
    my ($master, $options, $style) = $path->lines_utf8();
    if (!$master) {
        die "no master file specified in $path\n";
    }
    chomp($master);

    # Put the results into the correct format.
    my %results = (format => 'pod', path => $master);
    if (defined($style)) {
        chomp($style);
        $results{style} = $style;
    }
    if (defined($options)) {
        if ($options =~ m{ -c ( \s | \z ) }xms) {
            $results{options} = {
                contents => JSON::MaybeXS::true,
                navbar => JSON::MaybeXS::false,
            };
        }
        if ($options =~ m{ -t \s+ (?: '(.*)' | ( [^\'] \S+ ) ) }xms) {
            $results{title} = $1 || $2;
        }
    }

    # Return the parsed file.
    return \%results;
}

# Given its representation as a hash, write out a new-style *.spin file.
#
# $data_ref - Hash of data for the file
# $path     - Path to output file
sub _write_spin_pointer {
    my ($self, $data_ref, $path) = @_;

    # Generate the YAML output and strip off the leading document separator.
    local $YAML::XS::Boolean = 'JSON::PP';
    my $yaml = YAML::XS::Dump($data_ref);
    $yaml =~ s{ \A --- \n }{}xms;

    # Write the output.
    $path->spew_utf8($yaml);
    return;
}

# Convert an *.rpod file to a *.spin file.  Intended to be run via
# Path::Iterator::Rule.
#
# $rpod_path - Path to *.rpod file
# $repo      - Optional Git::Repository object for input tree
sub _convert_rpod_pointer {
    my ($self, $rpod_path, $repo) = @_;

    # Convert the file.
    my $data_ref = $self->_read_rpod_pointer($rpod_path);
    my $basename = $rpod_path->basename('.rpod');
    my $spin_path = $rpod_path->sibling($basename . '.spin');
    $self->_write_spin_pointer($data_ref, $spin_path);

    # If we have a Git repository, update Git.
    if (defined($repo)) {
        my $root = path($repo->work_tree());
        $repo->run('add', $spin_path->relative($root)->stringify());
        $repo->run('rm', $rpod_path->relative($root)->stringify());
    }
    return;
}

##############################################################################
# Public Interface
##############################################################################

# Create a new App::DocKnot::Update object, which will be used for subsequent
# calls.
#
# $args  - Anonymous hash of arguments with the following keys:
#   metadata - Path to the directory containing package metadata
#   output   - Path to the output file with the converted metadata
#
# Returns: Newly created object
#  Throws: Text exceptions on invalid metadata directory path
sub new {
    my ($class, $args_ref) = @_;
    my $self = {
        metadata => path($args_ref->{metadata} // 'docs/metadata'),
        output => path($args_ref->{output} // 'docs/docknot.yaml'),
    };
    bless($self, $class);
    return $self;
}

# Update an older version of DocKnot configuration.  Currently, this only
# handles the old JSON format.
#
# Raises: autodie exception on failure to read metadata
#         Text exception on inconsistencies in the package data
#         Text exception if schema checking failed on the converted config
sub update {
    my ($self) = @_;

    # Ensure we were given a valid metadata argument.
    if (!$self->{metadata}->is_dir()) {
        my $metadata = $self->{metadata};
        croak("metadata path $metadata does not exist or is not a directory");
    }

    # Tell YAML::XS that we'll be feeding it JSON::PP booleans.
    local $YAML::XS::Boolean = 'JSON::PP';

    # Load the config.
    my $data_ref = $self->_config_from_json();

    # Add the current format version.
    $data_ref->{format} = 'v1';

    # Move bootstrap to build.bootstrap.
    if (defined($data_ref->{bootstrap})) {
        $data_ref->{build}{bootstrap} = $data_ref->{bootstrap};
        delete $data_ref->{bootstrap};
    }

    # Move build.lancaster to test.lancaster.
    if (defined($data_ref->{build}{lancaster})) {
        $data_ref->{test}{lancaster} = $data_ref->{build}{lancaster};
        delete $data_ref->{build}{lancaster};
    }

    # Move packaging.debian to packaging.debian.package, move debian to
    # packaging.debian, and move packaging to distribution.packaging.
    if (defined($data_ref->{packaging})) {
        if (defined($data_ref->{packaging}{debian})) {
            my $package = $data_ref->{packaging}{debian};
            $data_ref->{packaging}{debian} = { package => $package };
        }
    }
    if (defined($data_ref->{debian})) {
        $data_ref->{packaging}{debian} //= {};
        $data_ref->{packaging}{debian}
          = { $data_ref->{debian}->%*, $data_ref->{packaging}{debian}->%* };
        delete $data_ref->{debian};
    }
    if ($data_ref->{packaging}) {
        $data_ref->{distribution}{packaging} = $data_ref->{packaging};
        delete $data_ref->{packaging};
    }

    # Move readme.sections to sections.  If there was a testing override, move
    # it to test.override and delete it from sections.
    if (defined($data_ref->{readme})) {
        $data_ref->{sections} = $data_ref->{readme}{sections};
        delete $data_ref->{readme};
        for my $section_ref ($data_ref->{sections}->@*) {
            if (lc($section_ref->{title}) eq 'testing') {
                $data_ref->{test}{override} = $section_ref->{body};
                last;
            }
        }
        $data_ref->{sections}
          = [grep { lc($_->{title}) ne 'testing' } $data_ref->{sections}->@*];
    }

    # support.cpan is obsolete.  If vcs.github is set and support.github is
    # not, use it as support.github.
    if (defined($data_ref->{support}{cpan})) {
        if (!defined($data_ref->{support}{github})) {
            if (defined($data_ref->{vcs}{github})) {
                $data_ref->{support}{github} = $data_ref->{vcs}{github};
            }
        }
        delete $data_ref->{support}{cpan};
    }

    # Check the schema of the resulting file.
    my $schema_path = $self->appdata_path('schema/docknot.yaml');
    my $schema_ref = YAML::XS::LoadFile($schema_path);
    eval { validate($schema_ref, $data_ref) };
    if ($@) {
        my $errors = $@;
        chomp($errors);
        die "schema validation failed:\n$errors\n";
    }

    # Write the new YAML package configuration.
    YAML::XS::DumpFile($self->{output}->stringify(), $data_ref);
    return;
}

# Update an input tree for spin to the current format.
#
# $path - Optional path to the spin input tree, defaults to current directory
#
# Raises: Text exception on failure
sub update_spin {
    my ($self, $path) = @_;
    $path = defined($path) ? path($path) : path(q{.});
    my $repo;
    if ($path->child('.git')->is_dir()) {
        $repo = Git::Repository->new(work_tree => "$path");
    }

    # Convert all *.rpod files to *.spin files.
    my $rule = Path::Iterator::Rule->new()->name(qr{ [.] rpod \z }xms);
    my $iter = $rule->iter($path, { follow_symlinks => 0 });
    while (defined(my $file = $iter->())) {
        $self->_convert_rpod_pointer(path($file), $repo);
    }
    return;
}

##############################################################################
# Module return value and documentation
##############################################################################

1;
__END__

=for stopwords
Allbery DocKnot MERCHANTABILITY NONINFRINGEMENT sublicense CPAN XDG

=head1 NAME

App::DocKnot::Update - Update DocKnot input or package configuration

=head1 SYNOPSIS

    use App::DocKnot::Update;

    my $update = App::DocKnot::Update->new(
        {
            metadata => 'docs/metadata',
            output   => 'docs/docknot.yaml',
        }
    );
    $update->update();

    $update->update_spin('/path/to/spin/input');

=head1 REQUIREMENTS

Perl 5.24 or later and the modules Git::Repository, File::BaseDir,
File::ShareDir, JSON::MaybeXS, Path::Iterator::Rule, Path::Tiny, Perl6::Slurp,
and YAML::XS, all of which are available from CPAN.

=head1 DESCRIPTION

This component of DocKnot updates package configuration from older versions.
Currently, its main purpose is to convert from the JSON format used prior to
DocKnot 4.0 to the current YAML syntax.

=head1 CLASS METHODS

=over 4

=item new(ARGS)

Create a new App::DocKnot::Update object.  This should be used for all
subsequent actions.  ARGS should be a hash reference with one or more of the
following keys:

=over 4

=item metadata

The path to the directory containing the legacy JSON metadata for a package.
Default: F<docs/metadata> relative to the current directory.

=item output

The path to which to write the new YAML configuration.  Default:
F<docs/docknot.yaml> relative to the current directory.

=back

=back

=head1 INSTANCE METHODS

=over 4

=item update()

Load the legacy JSON metadata and write out the YAML equivalent.

=item update_spin([PATH])

Update the input tree for App::DocKnot::Spin to follow current expectations.
PATH is the path to the input tree, which defaults to the current directory
if not given.  If the input tree is the working tree for a Git repository,
any changes are also registered with Git (but not committed).

=back

=head1 AUTHOR

Russ Allbery <rra@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2013-2022 Russ Allbery <rra@cpan.org>

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

L<docknot(1)>, L<App::DocKnot::Config>

This module is part of the App-DocKnot distribution.  The current version of
DocKnot is available from CPAN, or directly from its web site at
L<https://www.eyrie.org/~eagle/software/docknot/>.

=cut

# Local Variables:
# copyright-at-end-flag: t
# End:
