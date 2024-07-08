# Helper functions for testing spin.
#
# SPDX-License-Identifier: MIT

##############################################################################
# Modules and declarations
##############################################################################

package Test::DocKnot::Spin v3.0.0;

use 5.024;
use autodie;
use warnings;

use Cwd qw(getcwd);
use Encode qw(encode);
use Exporter qw(import);
use File::Compare qw(compare);
use File::Find qw(find);
use Path::Iterator::Rule ();
use Path::Tiny qw(path);
use Test::RRA qw(is_file_contents);
use YAML::XS ();

use Test::More;

our @EXPORT_OK = qw(fix_pointers is_spin_output is_spin_output_tree);

##############################################################################
# Test functions
##############################################################################

# Replace pointers in a spin input tree containing relative paths with
# absolute paths.  This is used after copying an input tree to a temporary
# directory when it contains references to other files in the same source
# tree.  Fix permissions as we go to allow writes since when building a
# distribution the original file may be read-only.
#
# $tree - Path::Tiny pointing to a tree of files containing pointers
# $base - Base path of the original input tree as a Path::Tiny object
sub fix_pointers {
    my ($tree, $base) = @_;
    my $rule = Path::Iterator::Rule->new()->name('*.spin')->file();
    my $iter = $rule->iter("$tree", { follow_symlinks => 0 });
    while (defined(my $file = $iter->())) {
        chmod(0644, $file);
        my $data_ref = YAML::XS::LoadFile($file);
        my $path = path($data_ref->{path});
        my $top = path($file)->parent()->relative($tree)->absolute($base);
        $data_ref->{path} = $path->absolute($top)->realpath()->stringify();
        YAML::XS::DumpFile($file, $data_ref);
    }
    return;
}

# Compare an output file with expected file contents, with modifications for
# things that are expected to vary on each run, such as timestamps and version
# numbers.
#
# $output_file - The file of spin output
# $expected    - The expected output
# $message     - The descriptive message of the test
sub is_spin_output {
    my ($output_file, $expected, $message) = @_;
    my $results = path($output_file)->slurp_utf8();

    # Map dates to %DATE% and ignore the different output when the
    # modification date is the same as the generation date.
    $results =~ s{
        [ ] \d{4}-\d\d-\d\d (?: [ ] \d\d:\d\d:\d\d [ ] -0000 )?
    }{ %DATE%}gxms;
    $results =~ s{
        \w{3}, [ ] \d\d [ ] \w{3} [ ] \d{4} [ ] \d\d:\d\d:\d\d [ ] [-+]\d{4}
    }{%DATE%}gxms;
    $results =~ s{
        Last [ ] modified [ ] \w+ [ ] \d{1,2}, [ ] \d{4}
    }{Last modified %DATE%}gxms;
    $results =~ s{
        Last [ ] modified [ ] and \s+ (<a[^>]+>spun</a>) [ ] [%]DATE[%]
    }{Last $1\n  %DATE% from thread modified %DATE%}gxms;
    $results =~ s{
        %DATE% [ ] from [ ] (Markdown|POD) [ ] modified [ ] %DATE%
    }{%DATE% from thread modified %DATE%}gxms;
    $results =~ s{
        (<guid [ ] isPermaLink="false">) \d+ (</guid>)
    }{$1%DATE%$2}gxms;

    # Map the DocKnot version number to %VERSION%.
    $results =~ s{ DocKnot [ ] v? [\d.]+ }{DocKnot %VERSION%}xmsg;

    # Check the results against the expected file.
    is_file_contents(encode('utf-8', $results), $expected, $message);
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
    my (%seen, @missing);

    # Compare each of the output files in the tree.
    my $rule = Path::Iterator::Rule->new()->skip_dirs('.git')->file();
    my $iter = $rule->iter("$output", { follow_symlinks => 0 });
    while (defined(my $file = $iter->())) {
        my $path = path($file)->relative($output);
        $seen{"$path"} = 1;
        my $expected_file = $path->absolute($expected);

        # Compare HTML output using is_spin_output and all other files as
        # copies.
        if ($path->basename() =~ m{ [.] (?: html | rss ) \z }xms) {
            is_spin_output($file, $expected_file, "$message ($path)");
        } else {
            is(compare($file, $expected_file), 0, "$message ($path)");
        }
    }
    my $count = keys(%seen);

    # Check every file in the expected output tree was seen in the generated
    # output tree.
    $rule = Path::Iterator::Rule->new()->skip_dirs('.git')->file();
    $iter = $rule->iter("$expected", { follow_symlinks => 0 });
    while (defined(my $file = $iter->())) {
        my $path = path($file)->relative($expected);
        if ($seen{"$path"}) {
            delete $seen{"$path"};
        } else {
            push(@missing, $path);
        }
    }
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
Allbery Allbery sublicense MERCHANTABILITY NONINFRINGEMENT DocKnot RSS

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

=item fix_pointers(TREE, BASE)

Find all F<*.spin> pointer files in TREE, treat any relative paths found in
those pointer files as if they were relative to BASE, convert them to absolute
paths, and write out the modified pointer file.  This is intended to be used
after copying an input tree for App::DocKnot::Spin to a temporary directory,
which would otherwise break any relative paths in pointer files.

=item is_spin_output(OUTPUT, EXPECTED, MESSAGE)

Given OUTPUT, which should be a Path::Tiny object pointing to the output from
App::DocKnot::Spin, compare it to the expected output in the file named
EXPECTED (also a Path::Tiny object).  MESSAGE is the message to print with the
test results for easy identification.

=item is_spin_output_tree(OUTPUT, EXPECTED, MESSAGE)

Compare the output tree at OUTPUT with the expected output tree at EXPECTED
(both Path::Tiny objects), using the same comparison algorithm as
is_spin_output() for HTML and RSS files and a straight content comparison for
all other files.  MESSAGE with the message to print with the test results for
easy identification.

=back

=head1 AUTHOR

Russ Allbery <rra@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2021-2024 Russ Allbery <rra@cpan.org>

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
