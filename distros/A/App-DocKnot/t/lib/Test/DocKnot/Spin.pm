# Helper functions for testing spin.
#
# SPDX-License-Identifier: MIT

##############################################################################
# Modules and declarations
##############################################################################

package Test::DocKnot::Spin 1.00;

use 5.024;
use autodie;
use warnings;

use Cwd qw(getcwd);
use Exporter qw(import);
use File::Compare qw(compare);
use File::Find qw(find);
use Perl6::Slurp qw(slurp);
use Test::RRA qw(is_file_contents);

use Test::More;

our @EXPORT_OK = qw(is_spin_output is_spin_output_tree);

##############################################################################
# Test functions
##############################################################################

# Compare an output file with expected file contents, with modifications for
# things that are expected to vary on each run, such as timestamps and version
# numbers.
#
# $output_file - The file of spin output
# $expected    - The expected output
# $message     - The descriptive message of the test
sub is_spin_output {
    my ($output_file, $expected, $message) = @_;
    my $results = slurp($output_file);

    # Map dates to %DATE% and ignore the different output when the
    # modification date is the same as the generation date.
    $results =~ s{
        [ ] \d{4}-\d\d-\d\d (?: [ ] \d\d:\d\d:\d\d [ ] -0000 )?
    }{ %DATE%}gxms;
    $results =~ s{
        \w{3}, [ ] \d\d [ ] \w{3} [ ] \d{4} [ ] \d\d:\d\d:\d\d [ ] [-+]\d{4}
    }{%DATE%}gxms;
    $results =~ s{
        Last [ ] modified [ ] and \s+ (<a[^>]+>spun</a>) [ ] [%]DATE[%]
    }{Last $1\n    %DATE% from thread modified %DATE%}gxms;
    $results =~ s{
        %DATE% [ ] from [ ] (Markdown|POD) [ ] modified [ ] %DATE%
    }{%DATE% from thread modified %DATE%}gxms;
    $results =~ s{
        (<guid [ ] isPermaLink="false">) \d+ (</guid>)
    }{$1%DATE%$2}gxms;

    # Map the DocKnot version number to %VERSION%.
    $results =~ s{ DocKnot [ ] \d+ [.] \d+ }{DocKnot %VERSION%}xms;

    # Check the results against the expected file.
    is_file_contents($results, $expected, $message);
    return;
}

# Compare a spin output tree with an expected output tree, with the same
# modification logic as is_spin_output.
#
# $output   - The output tree
# $expected - The expected output tree
# $message  - The descriptive message for the test
#
# Returns: The number of tests run.
sub is_spin_output_tree {
    my ($output, $expected, $message) = @_;
    my $cwd = getcwd();
    my %seen;
    my @missing;

    # Function that compares each of the output files in the tree, called from
    # File::Find on the output directory.
    my $check_output = sub {
        my $file = $_;
        return if -d $file;

        # Determine the relative path and mark it as seen.
        my $path = File::Spec->abs2rel($File::Find::name, $output);
        $seen{$path} = 1;

        # Find the corresponding expected file.
        my $expected_file
          = File::Spec->rel2abs(File::Spec->catfile($expected, $path), $cwd);

        # Compare HTML output using is_spin_output and all other files as
        # copies.
        if ($file =~ m{ [.] (?: html | rss ) \z }xms) {
            is_spin_output($file, $expected_file, "$message ($path)");
        } else {
            is(compare($file, $expected_file), 0, "$message ($path)");
        }
        return;
    };

    # Function that checks that every file in the expected output tree was
    # seen in the generated output tree, called from File::Find on the
    # expected directory.
    my $check_files = sub {
        my $file = $_;
        return if -d $file;

        # Determine the relative path and make sure it was in the %seen hash.
        my $path = File::Spec->abs2rel($File::Find::name, $expected);
        if ($seen{$path}) {
            delete $seen{$path};
        } else {
            push(@missing, $path);
        }
        return;
    };

    # Compare the output.
    find($check_output, $output);
    my $count = keys(%seen);

    # Check that there aren't any missing files.
    find($check_files, $expected);
    is_deeply(\@missing, [], 'All expected files generated');

    # Return the count of tests.
    return $count + 1;
}

##############################################################################
# Module return value and documentation
##############################################################################

1;
__END__

=for stopwords
Allbery Allbery sublicense MERCHANTABILITY NONINFRINGEMENT DocKnot

=head1 NAME

Test::DocKnot::Spin - Helper functions for testing spin

=head1 SYNOPSIS

    use Test::DocKnot::Spin qw(is_spin_output);

    $spin->spin_file($input, $output);
    is_spin_output($output, $expected, 'Check a single file');

    $spin->spin_tree($input_path, $output_path);
    is_spin_output_tree($output_path, $expected_path, 'Check a tree');

=head1 DESCRIPTION

This module collects utility functions that are useful for testing the
App::DocKnot::Spin module.

This module B<must> be loaded before Test::More or it will abort during
import.

=head1 FUNCTIONS

None of these functions are imported by default.  The ones used by a script
should be explicitly imported.

=over 4

=item is_spin_output(OUTPUT, EXPECTED, MESSAGE)

Given OUTPUT, which should be the path to a file generated by
App::DocKnot::Spin, compare it to the expected output in the file named
EXPECTED.  MESSAGE is the message to print with the test results for easy
identification.

=item is_spin_output_tree(OUTPUT, EXPECTED, MESSAGE)

Compare the output tree at OUTPUT with the expected output tree at EXPECTED,
using the same comparison algorithm as is_spin_output().  MESSAGE with the
message to print with the test results for easy identification.

=back

=head1 AUTHOR

Russ Allbery <rra@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2021 Russ Allbery <rra@cpan.org>

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

L<App::DocKnot::Spin>

This module is part of the App-DocKnot distribution.  The current version of
DocKnot is available from CPAN, or directly from its web site at
L<https://www.eyrie.org/~eagle/software/docknot/>.

=cut

# Local Variables:
# copyright-at-end-flag: t
# End:
