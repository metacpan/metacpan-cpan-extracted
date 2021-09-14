# Parse data from a spin .versions file.
#
# The top of a web site source tree for use with spin may contain a .versions
# file, which is a database of software release versions and dates that
# support various rendering features for software pages.  This module parses
# that file into an internal data structure and answers questions about its
# contents.
#
# SPDX-License-Identifier: MIT

##############################################################################
# Modules and declarations
##############################################################################

package App::DocKnot::Spin::Versions 5.00;

use 5.024;
use autodie;
use warnings;

use POSIX qw(mktime strftime);

##############################################################################
# File parsing
##############################################################################

# Parse a date/time in YYYY-mm-dd HH:MM:SS format in local time into seconds
# since epoch.  This duplicates Date::Parse, which is already a dependency,
# but this gives us more control over the format and better error reporting.
#
# $date - The date component
# $time - The time component
# $path - Path of file being parsed, for error reporting
#
# Returns: The time in seconds since epoch
#  Raises: Text exception if the date is invalid
sub _datetime_to_seconds {
    my ($date, $time, $path) = @_;

    # Check the data for validity.
    if ($date !~ m{ \A \d{4}-\d\d-\d\d \z }xms) {
        die qq(invalid date "$date" in $path\n);
    }
    if ($time !~ m{ \A \d\d:\d\d:\d\d \z }xms) {
        die qq(invalid time "$time" in $path\n);
    }

    # Parse and convert the date/time.
    my @datetime = reverse(split(m{ : }xms, $time));
    push(@datetime, reverse(split(m{ - }xms, $date)));
    $datetime[4]--;
    $datetime[5] -= 1900;
    $datetime[6] = 0;
    $datetime[7] = 0;
    $datetime[8] = -1;
    return mktime(@datetime);
}

# Parse a .versions file and populate the App::DocKnot::Spin::Versions object.
#
# $path - Path to the .versions file
#
# Raises: autodie exception on file read errors
#         Text exception on file parsing errors
sub _read_data {
    my ($self, $path) = @_;
    my $timestamp;

    open(my $fh, '<', $path);
    while (defined(my $line = <$fh>)) {
        next if $line =~ m{ \A \s* \z }xms;
        next if $line =~ m{ \A \s* \# }xms;

        # The list of files may be continued from a previous line.
        my @depends;
        if ($line =~ m{ \A \s }xms) {
            if (!defined($timestamp)) {
                die "continuation without previous entry in $path\n";
            }
            @depends = split(qr{ \s+ }xms, $line);
        } else {
            my @line = split(qr{ \s+ }xms, $line);
            my ($package, $version, $date, $time, @files) = @line;
            if (!defined($time)) {
                die "invalid line $. in $path\n";
            }
            @depends   = @files;
            $timestamp = _datetime_to_seconds($date, $time, $path);
            $date      = strftime('%Y-%m-%d', gmtime($timestamp));
            $self->{versions}{$package} = [$version, $date];
        }

        # We now have the previous release time as a timestamp in $timestamp
        # and some set of files affected by that release in @depends.  Record
        # that as dependency information.
        for my $file (@depends) {
            $self->{depends}{$file} //= $timestamp;
            if ($self->{depends}{$file} < $timestamp) {
                $self->{depends}{$file} = $timestamp;
            }
        }
    }
    close($fh);
    return;
}

##############################################################################
# Public interface
##############################################################################

# Parse a .versions file into a new App::DocKnot::Spin::Versions object.
#
# $path - Path to the .versions file
#
# Returns: Newly created object
#  Throws: Text exception on failure to parse the file
#          autodie exception on failure to read the file
sub new {
    my ($class, $path) = @_;

    # Create an empty object.
    my $self = {
        depends  => {},
        versions => {},
    };
    bless($self, $class);

    # Parse the file into the newly-created object.
    $self->_read_data($path);

    # Return the populated object.
    return $self;
}

# Return the timestamp of the latest release affecting a different page.
#
# $file - File name that may be listed as an affected file for a release
#
# Returns: The timestamp in seconds since epoch of the latest release
#          affecting that file, or 0 if there are none
sub latest_release {
    my ($self, $file) = @_;
    return $self->{depends}{$file} // 0;
}

# Return the release date for a given package.
#
# $package - Name of the package
#
# Returns: Release date as a string in UTC, or undef if not known
sub release_date {
    my ($self, $package) = @_;
    my $version = $self->{versions}{$package};
    return defined($version) ? $version->[1] : undef;
}

# Return the latest version for a given package.
#
# $package - Name of the package
#
# Returns: Latest version for package as a string, or undef if not known
sub version {
    my ($self, $package) = @_;
    my $version = $self->{versions}{$package};
    return defined($version) ? $version->[0] : undef;
}

##############################################################################
# Module return value and documentation
##############################################################################

1;
__END__

=for stopwords
Allbery DocKnot MERCHANTABILITY NONINFRINGEMENT sublicense YYYY-MM-DD

=head1 NAME

App::DocKnot::Spin::Versions - Parse package release information for spin

=head1 SYNOPSIS

    use App::DocKnot::Spin::Versions;
    my $versions = App::DocKnot::Spin::Versions('/path/to/.versions');
    my $version = $versions->version('some-package');
    my $release_date = $versions->release_date('some-package');
    my $timestamp = $versions->latest_release('some/file/index.th');

=head1 REQUIREMENTS

Perl 5.24 or later.

=head1 DESCRIPTION

App::DocKnot::Spin supports a database of release information for packages
that may be referenced in the generated web site.  This is stored as the file
named F<.versions> at the top of the source tree.  This module parses that
file and provides an API to the information it contains.

The file should consist of lines (except for continuation lines, see below) in
the form:

    <package>  <version>  <date>  <time>  <files>

starting in the first column.  Each field is separated by one or more spaces
except the last, <files>, which is all remaining space-separated words of the
line.  Blank lines and lines starting with C<#> in the first column are
ignored.

The fields are:

=over 4

=item <package>

The name of a package.

=item <version>

The version number of the latest release of that package.

=item <date>

The date of the latest release of that package in YYYY-MM-DD format in the
local time zone.

=item <time>

The time of the latest release of that package in HH:MM:SS format in the local
time zone.

=item <files>

Any number of thread input files affected by this release, separated by
spaces.  The file names should be relative to the top of the source tree for
the web site.

=back

The <files> field can be continued on the following line by starting the line
with whitespace.  Each whitespace-separated word in a continuation line is
taken as an additional affected file for the previous line.

This information is used for the C<\version> and C<\release> thread commands
and to force regeneration of files affected by a release with a timestamp
newer than the timestamp of the corresponding output file.

=head1 CLASS METHODS

=over 4

=item new(PATH)

Create a new App::DocKnot::Spin::Versions object for the F<.versions> file
specified by PATH.

=back

=head1 INSTANCE METHODS

=over 4

=item latest_release(PATH)

Return the timestamp (in seconds since epoch) for the latest release affecting
PATH, or 0 if no releases affect that file.

=item release_date(PACKAGE)

Return the release date of the latest release of PACKAGE (in UTC), or C<undef>
if there is no release information for PACKAGE.

=item version(PACKAGE)

Return the version of the latest release of PACKAGE, or C<undef> if there is
no release information for PACKAGE.

=back

=head1 AUTHOR

Russ Allbery <rra@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2004, 2021 Russ Allbery <rra@cpan.org>

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

L<docknot(1)>, L<App::DocKnot::Spin>

This module is part of the App-DocKnot distribution.  The current version of
DocKnot is available from CPAN, or directly from its web site at
L<https://www.eyrie.org/~eagle/software/docknot/>.

=cut

# Local Variables:
# copyright-at-end-flag: t
# End:
