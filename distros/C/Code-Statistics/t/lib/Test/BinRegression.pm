package Test::BinRegression;

use warnings;
use strict;
use FileHandle;

=head1 NAME

Test::Regression - Test library that can be run in two modes; one to generate outputs and a second to compare against them

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

  use Test::Regression;

  # read and write the regression file while generating os-specific newlines
  ok_regression(sub {return "hello world"}, "t/out/hello_world.txt");

  # read and write the file without generating os-specific newlines
  ok_regression(sub {return "hello world"}, "t/out/hello_world.txt", 'binmode');

=head1 DESCRIPTION

Using the various Test:: modules you can compare the output of a function against what you expect.
However if the output is complex and changes from version to version, maintenance of the expected
output could be costly. This module allows one to use the test code to generate the expected output,
so that if the differences with model output are expected, one can easily refresh the model output.

=head1 EXPORT

ok_regression

=cut

use Test::Builder::Module;
use Test::Differences;
use base qw(Test::Builder::Module);
our @EXPORT = qw(ok_regression);
my $CLASS = __PACKAGE__;

=head1 FUNCTIONS

=head2 ok_regression

This function requires two arguments: a CODE ref and a file path.
The CODE ref is expected to return a SCALAR string which
can be compared against previous runs.
If the TEST_REGRESSION_GEN is set to a true value, then the CODE ref is run and the
output written to the file. Otherwise the output of the
file is compared against the contents of the file.
There is a third optional argument which is the test name.
There is a fourth optional argument which is a boolean which enables read/write
with bin mode if set to true.

=cut

sub ok_regression {
	my $code_ref = shift;
	my $file = shift;
	my $test_name = shift;
	my $bin_mode = shift;
	my $output = eval {&$code_ref();};
	my $tb = $CLASS->builder;
	if ($@) {
		$tb->diag($@);
		return $tb->ok(0, $test_name);
	}

	# generate the output files if required
	if ($ENV{TEST_REGRESSION_GEN}) {
		my $fh = FileHandle->new;
		$fh->open(">$file") ||  return $tb->ok(0, "$test_name: cannot open $file");
		$fh->binmode if $bin_mode;
		if (length $output) {
			$fh->print($output) || return $tb->ok(0, "actual write failed: $file");
		}
		return $tb->ok(1, $test_name);
	}

	# compare the files
	return $tb->ok(0, "$test_name: cannot read $file") unless -r $file;
	my $fh = FileHandle->new;
	$fh->open("<$file") ||  return $tb->ok(0, "$test_name: cannot open $file");
	$fh->binmode if $bin_mode;
	my $content = join '', (<$fh>);
	eq_or_diff($output, $content, $test_name);
	return $output eq $file;
}

=head1 ENVIRONMENT VARIABLES

=head2 TEST_REGRESSION_GEN

If the TEST_REGRESSION_GEN environment file is unset or false in a perl sense, then the named output files must exist and be readable and the
test will run normally comparing the outputs of the CODE refs against the contents of those files. If the environment variable is true in
a perl sense, then model output files will be overwritten with the output of the CODE ref.

=head1 AUTHOR

Nicholas Bamber, C<< <nicholas at periapt.co.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-regression at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Regression>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head2 testing of STDERR

The testing of stderr from this module is not as thorough as I would like. L<Test::Builder::Tester> allows turning
off of stderr checking but not matching by regular expression. Handcrafted efforts currently fall foul of L<Test::Harness>.
Still it is I believe adequately tested in terms of coverage.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Regression


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Regression>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Regression>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Regression>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Regression/>

=back


=head1 ACKNOWLEDGEMENTS

=over

=item Some documentation improvements have been suggested by toolic (http://perlmonks.org/?node_id=622051).

=item Thanks to Filip GraliE<0x144>ski for pointing out I need to test against output of zero length and providing a patch.

=back

=head1 COPYRIGHT & LICENSE

Copyright 2009 Nicholas Bamber.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Test::Regression
