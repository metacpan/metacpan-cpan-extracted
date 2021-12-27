# Shared utility functions for other DocKnot modules.
#
# A collection of random utility functions that are used by more than one
# DocKnot module but don't make sense as App::DocKnot methods.
#
# SPDX-License-Identifier: MIT

##############################################################################
# Modules and declarations
##############################################################################

package App::DocKnot::Util 6.00;

use 5.024;
use autodie;
use warnings;

use Carp qw(croak);
use Exporter qw(import);
use List::SomeUtils qw(all);

our @EXPORT_OK = qw(is_newer print_checked print_fh);

##############################################################################
# Public interface
##############################################################################

# Check if a file, which may not exist, is newer than another list of files.
#
# $file   - File whose timestamp to compare
# @others - Other files to compare against
#
# Returns: True if $file exists and is newer than @others, false otherwise
sub is_newer {
    my ($file, @others) = @_;
    return if !-e $file;
    my $file_mtime = (stat($file))[9];
    my @others_mtimes = map { (stat)[9] } @others;
    return all { $file_mtime >= $_ } @others_mtimes;
}

# print with error checking.  autodie unfortunately can't help us because
# print can't be prototyped and hence can't be overridden.
#
# @args - Arguments to print to stdout
#
# Returns: undef
#  Throws: Text exception on output failure
sub print_checked {
    my (@args) = @_;
    print @args or croak('print failed');
    return;
}

# print with error checking and an explicit file handle.  autodie
# unfortunately can't help us because print can't be prototyped and
# hence can't be overridden.
#
# $fh   - Output file handle
# $file - File name for error reporting
# @args - Remaining arguments to print
#
# Returns: undef
#  Throws: Text exception on output failure
sub print_fh {
    my ($fh, $file, @args) = @_;
    print {$fh} @args or croak("cannot write to $file: $!");
    return;
}

##############################################################################
# Module return value and documentation
##############################################################################

1;
__END__

=for stopwords
Allbery DocKnot MERCHANTABILITY NONINFRINGEMENT sublicense FH autodie

=head1 NAME

App::DocKnot::Util - Shared utility functions for other DocKnot modules

=head1 SYNOPSIS

    use App::DocKnot::Util qw(is_newer print_checked print_fh);

    print_checked('some stdout output');
    if (!is_newer('/output', '/input-1', '/input-2')) {
        open(my $fh, '>', '/output');
        print_fh($fh, '/output', 'some stuff');
        close($fh);
    }

=head1 REQUIREMENTS

Perl 5.24 or later and the List::SomeUtils module, available from CPAN.

=head1 DESCRIPTION

This module collects utility functions used by other App::DocKnot modules.  It
is not really intended for use outside of DocKnot, but these functions can be
used if desired.

=head1 FUNCTIONS

=over 4

=item is_newer(FILE, SOURCE[, SOURCE ...])

Returns a true value if FILE exists and has a last modified time that is newer
or equal to the last modified times of all SOURCE files, and otherwise returns
a false value.  Used primarily to determine if a given output file is
up-to-date with respect to its source files.

=item print_checked(ARG[, ARG ...])

The same as print (without a file handle argument), except that it throws a
text exception on failure as if autodie affected print (which it unfortunately
doesn't because print cannot be prototyped).

=item print_fh(FH, NAME, DATA[, DATA ...])

Writes the concatenation of the DATA elements (interpreted as scalar strings)
to the file handle FH.  NAME should be the name of the file open as FH, and is
used for error reporting.

This is mostly equivalent to C<print {fh}> but throws a text exception in the
event of a failure.

=back

=head1 AUTHOR

Russ Allbery <rra@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 1999-2011, 2013, 2021 Russ Allbery <rra@cpan.org>

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

L<App::DocKnot>

This module is part of the App-DocKnot distribution.  The current version of
DocKnot is available from CPAN, or directly from its web site at
L<https://www.eyrie.org/~eagle/software/docknot/>.

=cut

# Local Variables:
# copyright-at-end-flag: t
# End:
