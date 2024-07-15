# Generate a distribution tarball for a package.
#
# This is the implementation of the docknot dist command, which determines and
# runs the commands necessary to build a distribution tarball for a given
# package.
#
# SPDX-License-Identifier: MIT

##############################################################################
# Modules and declarations
##############################################################################

package App::DocKnot::Dist v8.0.1;

use 5.024;
use autodie;
use warnings;

use App::DocKnot::Config;
use App::DocKnot::Util qw(latest_tarball print_checked);
use Archive::Tar ();
use Carp qw(croak);
use File::Find qw(find);
use Git::Repository ();
use IO::Compress::Xz ();
use IO::Uncompress::Gunzip ();
use IPC::Run qw(run);
use IPC::System::Simple qw(systemx);
use List::SomeUtils qw(lastval);
use List::Util qw(any first);
use Path::Tiny qw(path);

# Base commands to run for various types of distributions.  Additional
# variations may be added depending on additional configuration parameters.
#<<<
our %COMMANDS = (
    'Autoconf' => [
        ['./bootstrap'],
        ['./configure', 'CC=clang'],
        ['make', 'warnings'],
        ['make', 'check'],
        ['make', 'clean'],
        ['./configure', 'CC=gcc'],
        ['make', 'warnings'],
        ['make', 'check'],
        ['make', 'clean'],
        ['make', 'check-cppcheck'],
        ['make', 'distcheck'],
    ],
    'ExtUtils::MakeMaker' => [
        ['perl', 'Makefile.PL'],
        ['make', 'disttest'],
        ['make', 'dist'],
    ],
    'Module::Build' => [
        ['perl', 'Build.PL'],
        ['./Build', 'disttest'],
        ['./Build', 'dist'],
    ],
    'make' => [
        ['make', 'dist'],
    ],
);
#>>>

# Regexes matching files or directories in the source tree to ignore when
# comparing it against the generated distribution (in other words, we don't
# care whether these files or any files in these directories are included in
# the distribution).  These should match the full file path relative to the
# top directory.
#
# Include all of the build-generated files for docknot itself so that we can
# use the new version to release the new version.
## no critic (RegularExpressions::ProhibitFixedStringMatches)
our @DIST_IGNORE = (
    qr{ \A [.]git \z }xms,
    qr{ \A autom4te[.]cache \z }xms,
    qr{ \A Build \z }xms,
    qr{ \A MANIFEST[.]bak \z }xms,
    qr{ \A MYMETA [.] (?:json (?:[.]lock)? | yml) \z }xms,
    qr{ \A _build \z }xms,
    qr{ \A blib \z }xms,
    qr{ \A config[.]h[.]in~ \z }xms,
    qr{ \A configure~ \z }xms,
    qr{ \A cover_db \z }xms,
    qr{ \A tests/config \z }xms,
    qr{ [.]tar[.][gx]z \z }xms,
);
## use critic

##############################################################################
# Helper methods
##############################################################################

# Given the path to the source tree, generate a list of files that we expect
# to find in the distribution tarball.
#
# $path - The directory path
#
# Returns: A list of files (no directories) that the distribution tarball
#          should contain.
sub _expected_dist_files {
    my ($self, $path) = @_;
    my @files;

    # Supplemental ignore rules from the package configuration.
    my @ignore;
    if ($self->{config}{distribution}{ignore}) {
        @ignore = map { qr{$_}xms } $self->{config}{distribution}{ignore}->@*;
    }

    # Find all files in the source directory, stripping its path from the file
    # name and excluding (and pruning) anything matching @DIST_IGNORE or in
    # the distribution/ignore key of the package configuration.
    #
    # This uses File::Find rather than Path::Iterator::Rule like other parts
    # of DocKnot because the ignore patterns are based on the whole path
    # relative to the top of the distribution, and that's more annoying to do
    # with Path::Iterator::Rule.
    my $wanted = sub {
        my $name = $File::Find::name;
        $name =~ s{ \A \Q$path\E / }{}xms;
        return if !$name;
        if (any { $name =~ $_ } @DIST_IGNORE, @ignore) {
            $File::Find::prune = 1;
            return;
        }
        return if -d;
        push(@files, $name);
    };

    # Generate and return the list of files.
    find($wanted, "$path");
    return @files;
}

# Find the tarball compressed with gzip given a directory and a prefix.
#
# $path   - The directory path
# $prefix - The tarball file prefix
#
# Returns: The path to the gzip tarball
#  Throws: Text exception if no gzip tarball was found
sub _find_gzip_tarball {
    my ($self, $path, $prefix) = @_;
    my $files_ref = latest_tarball($path, $prefix)->{files};
    my $gzip_file = lastval { m{ [.]tar [.]gz \z }xms } $files_ref->@*;
    if (!defined($gzip_file)) {
        die "cannot find gzip tarball for $prefix in $path\n";
    }
    return $path->child($gzip_file);
}

# Given a directory and a prefix for tarballs in that directory, ensure that
# all the desired compression formats exist.  Currently this only handles
# generating the xz version of a gzip tarball.
#
# $path   - The directory path
# $prefix - The tarball file prefix
#
# Throws: Text exception on failure to read or write compressed files.
sub _generate_compression_formats {
    my ($self, $path, $prefix) = @_;
    my $files_ref = latest_tarball($path, $prefix)->{files};
    if (!any { m{ [.]tar [.]xz \z }xms } $files_ref->@*) {
        my $gzip_file = lastval { m{ [.]tar [.]gz \z }xms } $files_ref->@*;
        my $gzip_path = $path->child($gzip_file);
        my $xz_path = $path->child($gzip_path->basename('.gz') . '.xz');

        # Open the input and output files.
        my $gzip_fh = IO::Uncompress::Gunzip->new("$gzip_path");
        my $xz_fh = IO::Compress::Xz->new("$xz_path");

        # Read from the gzip file and write to the xz-compressed file.
        my $buffer;
        while (my $bytes = read($gzip_fh, $buffer, 1024 * 1024)) {
            syswrite($xz_fh, $buffer);
        }
        close($xz_fh);
        close($gzip_fh);
    }
    return;
}

# Given a source directory, a prefix for tarballs and related files (such as
# signatures), and a destination directory, move all matching files from the
# source directory to the destination directory.
#
# $source_path - The source directory path
# $prefix      - The tarball file prefix
# $dest_path   - The destination directory path
#
# Throws: Text exception if no files are found
#         Text exception on failure to move a file
sub _move_tarballs {
    my ($self, $source_path, $prefix, $dest_path) = @_;
    my $files_ref = latest_tarball($source_path, $prefix)->{files};
    for my $file ($files_ref->@*) {
        $source_path->child($file)->move($dest_path->child($file));
    }
    return;
}

# Given a command with arguments, replace a command of "perl" with the
# configured path to Perl, if any.  Assumes that the perl configuration
# parameter is set in the object and should not be called if this is not true.
#
# $command_ref - Reference to an array representing a command with arguments
#
# Returns: Reference to an array representing a command with arguments, with
#          the command replaced with the configured path to Perl if it was
#          "perl"
sub _replace_perl_path {
    my ($self, $command_ref) = @_;
    if ($command_ref->[0] ne 'perl') {
        return $command_ref;
    }
    my @command = $command_ref->@*;
    $command[0] = $self->{perl};
    return [@command];
}

# Given a directory and a prefix for tarballs in that directory, sign the
# tarballs in that directory.
#
# $path   - The directory path
# $prefix - The tarball file prefix
#
# Throws: Text exception on failure to sign the file
sub _sign_tarballs {
    my ($self, $path, $prefix) = @_;
    my $files_ref = latest_tarball($path, $prefix)->{files};
    for my $file (grep { m{ [.]tar [.][xg]z }xms } $files_ref->@*) {
        my $tarball_path = $path->child($file);
        my $sig_path = $path->child($tarball_path->basename() . '.asc');
        if ($sig_path->exists()) {
            $sig_path->remove();
        }
        systemx(
            $self->{gpg}, '--detach-sign', '--armor', '-u',
            $self->{pgp_key}, $tarball_path,
        );
    }
    return;
}

##############################################################################
# Public interface
##############################################################################

# Create a new App::DocKnot::Dist object, which will be used for subsequent
# calls.
#
# $args_ref - Anonymous hash of arguments with the following keys:
#   distdir  - Path to the directory for distribution tarball
#   metadata - Path to the package metadata
#   perl     - Path to Perl to use (default: search the user's PATH)
#
# Returns: Newly created object
#  Throws: Text exceptions on invalid metadata directory path
#          Text exception on missing or invalid distdir argument
sub new {
    my ($class, $args_ref) = @_;

    # Create the config reader.
    my %config_args;
    if ($args_ref->{metadata}) {
        $config_args{metadata} = $args_ref->{metadata};
    }
    my $config_reader = App::DocKnot::Config->new(\%config_args);

    # Load the global configuration.
    my $global_config_ref = $config_reader->global_config();

    # Ensure we were given a valid distdir argument if it was not set in the
    # global configuration.
    my $distdir = $args_ref->{distdir} // $global_config_ref->{distdir};
    if (!defined($distdir)) {
        croak('distdir path not given');
    } elsif (!-d $distdir) {
        croak("distdir path $distdir does not exist or is not a directory");
    }

    # Create and return the object.
    my $self = {
        config  => $config_reader->config(),
        distdir => path($distdir),
        gpg     => $args_ref->{gpg} // 'gpg',
        perl    => $args_ref->{perl},
        pgp_key => $args_ref->{pgp_key} // $global_config_ref->{pgp_key},
    };
    bless($self, $class);
    return $self;
}

# Given a distribution tarball compressed with gzip, ensure that every file
# from the source directory that is expected to be there is in the
# distribution tarball.  Assumes that it is run from the root of the source
# directory.
#
# $source  - Path to the source directory
# $tarball - Path to a gzip-compressed distribution tarball
#
# Returns: A list of files missing from the distribution (so an empty list
#          means all expected files were found)
sub check_dist {
    my ($self, $source, $tarball) = @_;
    my @expected = $self->_expected_dist_files(path(q{.}));
    my %expected = map { ("$_", 1) } @expected;
    my $archive = Archive::Tar->new($tarball);
    for my $file ($archive->list_files()) {
        $file =~ s{ \A [^/]* / }{}xms;
        delete $expected{$file};
    }
    my @missing = sort(keys(%expected));
    return @missing;
}

# Analyze a source directory and return the list of commands to run to
# generate a distribution tarball.
#
# Returns: List of commands, each of which is a list of strings representing
#          a command and its arguments
sub commands {
    my ($self) = @_;
    my $type = $self->{config}{build}{type};
    my @commands = map { [@$_] } $COMMANDS{$type}->@*;

    # Special-case: If a specific path to Perl was configured, use that path
    # rather than searching for perl in the user's PATH.  This is used
    # primarily by the test suite, which wants to run a Module::Build Build.PL
    # and thus has to use the same perl binary as the one running the tests.
    if (defined($self->{perl})) {
        @commands = map { $self->_replace_perl_path($_) } @commands;
    }

    # Special-case: Autoconf packages with C++ support should also attempt a
    # build with a C++ compiler.
    if ($type eq 'Autoconf' && $self->{config}{build}{cplusplus}) {
        #<<<
        my @extra = (
            ['./configure', 'CC=g++'],
            ['make', 'check'],
            ['make', 'clean'],
        );
        #>>>
        splice(@commands, 1, 0, @extra);
    }

    # Special-case: Autoconf packages with Valgrind support should also run
    # make check-valgrind.
    if ($type eq 'Autoconf' && $self->{config}{build}{valgrind}) {
        splice(@commands, -3, 0, ['make', 'check-valgrind']);
    }

    return @commands;
}

# Generate a distribution tarball.  This assumes it is run from the root
# directory of the package to release and that it is a Git repository.  It
# exports the Git repository, runs the commands to generate the tarball, and
# then removes the working tree.
#
# Throws: Text exception if any of the commands fail
#         Text exception if the distribution is missing files
sub make_distribution {
    my ($self) = @_;

    # Determine the source directory and the distribution directory name.
    my $source = path(q{.})->realpath();
    my $prefix = $self->{config}{distribution}{tarname};

    # If the distribution directory name already exists, remove it.  Automake
    # may have made parts of it read-only, so be forceful in the removal.
    # Note that this disables safe mode and therefore should not be called on
    # attacker-controlled directories.
    chdir($self->{distdir});
    my $workdir = path($prefix);
    if ($workdir->is_dir()) {
        $workdir->remove_tree({ safe => 0 });
    }

    # Export the Git repository into a new directory.
    my $repo = Git::Repository->new(work_tree => "$source");
    my @branches = $repo->run(
        'for-each-ref' => '--format=%(refname:short)', 'refs/heads/',
    );
    my $head = first { $_ eq 'main' || $_ eq 'master' } @branches;
    my $archive = $repo->command(archive => "--prefix=${prefix}/", $head);
    run([qw(tar xf -)], '<', $archive->stdout)
      or die "git archive | tar xf - failed with status $?\n";
    $archive->close();

    if ($archive->exit != 0) {
        die 'git archive failed with status ' . $archive->exit . "\n";
    }

    # Change to that directory and run the configured commands.
    chdir($workdir);
    for my $command_ref ($self->commands()) {
        systemx($command_ref->@*);
    }

    # Generate additional compression formats if needed.
    $self->_generate_compression_formats(path(q{.}), $prefix);

    # Move the generated tarballs to the parent directory.
    $self->_move_tarballs(path(q{.}), $prefix, $self->{distdir});

    # Remove the working tree.
    chdir($self->{distdir});
    $workdir->remove_tree();

    # Check the distribution for any missing files.  If there are any, report
    # them and then fail with an error.
    my $tarball = $self->_find_gzip_tarball($self->{distdir}, $prefix);
    chdir($source);
    my @missing = $self->check_dist($source, $tarball);
    if (@missing) {
        print_checked("Files found in local tree but not in distribution:\n");
        print_checked(q{    }, join(qq{\n    }, @missing), "\n");
        my $count = scalar(@missing);
        my $files = ($count == 1) ? '1 file' : "$count files";
        die "$files missing from distribution\n";
    }

    # Sign the tarballs if configured to do so.
    if (defined($self->{pgp_key})) {
        $self->_sign_tarballs($self->{distdir}, $prefix);
    }

    return;
}

##############################################################################
# Module return value and documentation
##############################################################################

1;
__END__

=for stopwords
Allbery DocKnot MERCHANTABILITY NONINFRINGEMENT sublicense JSON CPAN ARGS
distdir Automake xz gpg Kwalify IO-Compress-Lzma

=head1 NAME

App::DocKnot::Dist - Prepare a distribution tarball

=head1 SYNOPSIS

    use App::DocKnot::Dist;
    my $docknot = App::DocKnot::Dist->new({ distdir => '/path/to/dist' });
    $docknot->make_distribution();

=head1 REQUIREMENTS

Git, Perl 5.24 or later, and the modules File::BaseDir, File::ShareDir,
Git::Repository, IO::Compress::Xz (part of IO-Compress-Lzma),
IO::Uncompress::Gunzip (part of IO-Compress), IPC::Run, IPC::System::Simple,
Kwalify, List::SomeUtils, Path::Tiny, and YAML::XS, all of which are available
from CPAN.

The tools to build whatever type of software distribution is being prepared
are also required, since the distribution is built and tested as part of
preparing the tarball.

To sign distribution tarballs, the GnuPG command-line program B<gpg> is
required.  (Any version, either GnuPG v1 or GnuPG v2, should work.)

=head1 DESCRIPTION

This component of DocKnot generates distribution tarballs for a package.  This
is a bit of an odd inclusion in the DocKnot suite, since it's not about
generating documentation, but it uses the same configuration and metadata as
the rest of DocKnot.

Specifically, App::DocKnot::Dist exports the current branch from Git into a
separate working directory, runs the commands appropriate to create a
distribution (based on the build system configured in the package metadata),
and cleans up the working directory.

=head1 CLASS METHODS

=over 4

=item new(ARGS)

Create a new App::DocKnot::Dist object.  This should be used for all
subsequent actions.  ARGS should be a hash reference with one or more of the
following keys:

=over 4

=item distdir

The path to the directory into which to put the distribution tarball.  This
should point to a trusted directory, not one where an attacker could have
written files (see make_distribution() below).  Required if not set in the
global configuration file.

=item gpg

The path to the B<gpg> binary, used to sign generated tarballs if C<pgp_key>
is present in the global configuration or provided as a constructor argument.
Default: The binary named C<gpg> on the user's PATH.

=item metadata

The path to the metadata for the package on which to operate.  Default:
F<docs/docknot.yaml> relative to the current directory.

=item perl

The path to the Perl executable to use for build steps that require it.  Used
primarily in the test suite.  Default: The binary named C<perl> on the user's
PATH.

=item pgp_key

Sign generated tarballs with the provided PGP key.  The key can be named in
any way that the B<-u> option of GnuPG understands.  This can also be set in
the global configuration file.  There is no default; if this option is not
set, either as a constructor parameter or in the global configuration file,
the generated tarballs will not be signed.

=back

=back

=head1 INSTANCE METHODS

=over 4

=item check_dist(SOURCE, TARBALL)

Given the path to a source directory and the path to a gzip-compressed
distribution tarball made from that directory, return the list of files that
should be in the tarball but aren't.  An empty list means that all files in
the source tree expected to be in the distribution are present.

This method is provided primarily for testing convenience and is normally just
an implementation detail of make_distribution().

=item commands()

Return the commands that should be run to generate a distribution tarball as a
reference to an array of arrays.  Each included array is a single command.

This method is provided primarily for testing convenience and is normally just
an implementation detail of make_distribution().

=item make_distribution()

Generate distribution tarballs in the C<destdir> directory provided to new().
The distribution will be generated from the first branch found named either
C<main> or C<master>.

If C<destdir> already contains a subdirectory whose name matches the
C<tarname> of the distribution, it will be forcibly removed.  In order to
successfully remove trees that result from Automake's C<make distcheck>
failing partway through, App::DocKnot::Dist will change permissions as needed
to remove an existing directory.  For security reasons, the C<distdir>
parameter of this module should therefore only be pointed to a trusted
directory, not one where an attacker could have written files.

If the native distribution tarball generation commands for the package
generate a gzip-compressed tarball but not an xz-compressed tarball, an
xz-compressed tarball will be created.

After the distribution is created, check_dist() will be run on it.  If any
files are missing from the distribution, they will be reported to standard
output and then an exception will be thrown.

If the C<pgp_key> constructor parameter or global configuration option is set,
the generated tarballs will then be signed with that key, using B<gpg>.  The
generated signature will be armored and stored in a file named by appending
C<.asc> to the name of the tarball.

=back

=head1 AUTHOR

Russ Allbery <rra@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2019-2022 Russ Allbery <rra@cpan.org>

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
