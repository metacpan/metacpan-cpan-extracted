# Parent module for DocKnot.
#
# DocKnot provides various commands for generating documentation, web pages,
# and software releases.  This parent module provides some internal helper
# functions used to load configuration and metadata.  The normal entry point
# are the various submodules, or App::DocKnot::Command via docknot.
#
# SPDX-License-Identifier: MIT

##############################################################################
# Modules and declarations
##############################################################################

package App::DocKnot 6.01;

use 5.024;
use autodie;
use warnings;

use File::BaseDir qw(config_files);
use File::ShareDir qw(module_file);
use File::Spec;
use Kwalify qw(validate);
use YAML::XS ();

##############################################################################
# Helper methods
##############################################################################

# Helper routine to return the path of a file from the application data.
# These data files are installed with App::DocKnot, but each file can be
# overridden by the user via files in $HOME/.config/docknot or
# /etc/xdg/docknot (or whatever $XDG_CONFIG_DIRS is set to).
#
# We therefore try File::BaseDir first (which handles the XDG paths) and fall
# back on using File::ShareDir to locate the data.
#
# This function must be in the App::DocKnot module so that File::ShareDir
# works properly and searches the correct module path.
#
# @path - The relative path of the file as a list of components
#
# Returns: The absolute path to the application data
#  Throws: Text exception on failure to locate the desired file
sub appdata_path {
    my ($self, @path) = @_;

    # Try XDG paths first.
    my $path = config_files('docknot', @path);

    # If that doesn't work, use the data that came with the module.
    if (!defined($path)) {
        $path = module_file('App::DocKnot', File::Spec->catfile(@path));
    }
    return $path;
}

# Load a YAML file with schema checking.
#
# $path   - Path to the YAML file to load
# $schema - Name of the schema file against which to check it
#
# Returns: Contents of the file as a hash
#  Throws: YAML::XS exception on invalid file
#          Text exception on schema mismatch
sub load_yaml_file {
    my ($self, $path, $schema) = @_;

    # Tell YAML::XS to use real booleans.  Otherwise, Kwalify is unhappy with
    # data elements set to false.
    local $YAML::XS::Boolean = 'JSON::PP';

    # Load the metadata and check it against the schema.  YAML::XS for some
    # reason puts a newline before the system error part of an error message
    # when loading a file, so clean up the error a bit.
    my $schema_path = $self->appdata_path('schema', $schema . '.yaml');
    my ($data_ref, $schema_ref);
    eval {
        $data_ref = YAML::XS::LoadFile($path);
        $schema_ref = YAML::XS::LoadFile($schema_path);
    };
    if ($@) {
        my $error = lcfirst($@);
        chomp($error);
        $error =~ s{ \n }{ }xms;
        die "$error\n";
    }
    eval { validate($schema_ref, $data_ref) };
    if ($@) {
        my $errors = $@;
        chomp($errors);
        die "schema validation for $path failed:\n$errors\n";
    }

    # Return the verified contents.
    return $data_ref;
}

##############################################################################
# Module return value and documentation
##############################################################################

1;
__END__

=for stopwords
Allbery DocKnot docknot MERCHANTABILITY NONINFRINGEMENT sublicense
submodules Kwalify

=head1 NAME

App::DocKnot - Documentation and software release management

=head1 REQUIREMENTS

Perl 5.24 or later and the modules File::BaseDir, File::ShareDir, Kwalify, and
YAML::XS, all of which are available from CPAN.

=head1 DESCRIPTION

DocKnot is a system for documentation and software release management.  Its
functionality is provided by various submodules, often invoked via the
B<docknot> command-line program.  For more information, see L<docknot(1)>.

This module only provides helper functions to load configuration and metadata
that are used by its various submodules.

=head1 INSTANCE METHODS

=over 4

=item appdata_path(PATH[, ...])

Return the path of a file from the application data.  The file is specified as
one or more path components.

These data files are installed with App::DocKnot, but each file can be
overridden by the user via files in F<$HOME/.config/docknot> or
F</etc/xdg/docknot> (or whatever $XDG_CONFIG_HOME and $XDG_CONFIG_DIRS are set
to).  Raises a text exception if the desired file could not be located.

=item load_yaml_file(PATH, SCHEMA)

Load a YAML file with schema checking.  PATH is the path to the file.
SCHEMA is the name of the schema, which will be loaded from the F<schema>
directory using appdata_path().  See the description of that method for the
paths that are searched.

=back

=head1 AUTHOR

Russ Allbery <rra@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2013-2021 Russ Allbery <rra@cpan.org>

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
DocKnot is available from CPAN, or directly from its web site at
L<https://www.eyrie.org/~eagle/software/docknot/>.

=cut

# Local Variables:
# copyright-at-end-flag: t
# End:
