package Code::Quality;

use 5.020000;
use strict;
use warnings;
use utf8;
use re '/s';
use parent qw/Exporter/;

=encoding utf-8

=head1 NAME

Code::Quality - use static analysis to compute a "code quality" metric for a program

=head1 SYNOPSIS

  use v5.20;
  use Code::Quality;
  # code to test (required)
  my $code = ...;
  # reference code to compare against (optional)
  my $reference = ...;

  my $warnings =
    analyse_code
      code => $code,
      reference => $reference,
      language => 'C';
  if (defined $warnings) {
    my $stars = star_rating_of_warnings $warnings;
    say "Program is rated $stars stars"; # 3 is best, 1 is worst
    my @errors = grep { $_->[0] eq 'error' } @$warnings;
    if (@errors > 0) {
      say 'Found ', scalar @errors, ' errors';
      say "First error:  $errors[0][1]";
    }
  } else {
    say 'Failed to analyse code';
  }

=head1 DESCRIPTION

Code::Quality runs a series of tests on a piece of source code to
compute a code quality metric. Each test returns a possibly empty list
of warnings, that is potential issues present in the source code. This
list of warnings can then be turned into a star rating: 3 stars for
good code, 2 stars for acceptable code, and 1 stars for dubious code.

=head2 Warnings

A warning is an arrayref C<< [type, message, row, column] >>, where
the first two entries are mandatory and the last two can be either
both present or both absent.
The type is one of C<< qw/error warning info/ >>.

Four-element warnings correspond to ACE code editor annotations.
Two-element warnings apply to the entire document, not a specific
place in the code.

=head2 Tests

A test is a function that takes key-value arguments:

B<test_something>(code => I<$code>, language => I<$language>, [reference => I<$reference>])

Here I<$code> is the code to be tested, I<$language> is the
programming language, and I<$reference> is an optional reference
source code to compare I<$code> against.

Each test returns undef if the test failed (for example, if the test
cannot be applied to this programming language), and an arrayref of
warnings otherwise.

Most tests have several configurable parameters, which come from
global variables. The documentation of each test mentions the global
variables that affect its operations. C<local> can be used to run a
test with special configuration once, without affecting other code:

  {
    local $Code::Quality::bla_threshold = 5;
    test_bla code => $code, language => 'C';
  }

=cut

our $VERSION = '0.001001';
our @EXPORT = qw/analyse_code star_rating_of_warnings/;
our @EXPORT_OK = (@EXPORT, qw/test_lines test_clang_tidy/);
our %EXPORT_TAGS = (default => \@EXPORT, all => \@EXPORT_OK);

# set this to a "Test::More::diag"-like function to get debug output
our $DEBUG;

use Carp qw/carp croak/;
use Cpanel::JSON::XS qw/encode_json/;
use File::Temp qw//;
use List::Util qw/reduce any/;

sub diag { $DEBUG->(@_) if defined $DEBUG }

sub remove_empty_lines {
	my ($code) = @_;
	$code =~ s/\n\s*/\n/g;  # remove empty lines
	$code =~ s/^\s*//g;     # remove leading whitespace
	return $code;
}

our $warn_code_is_long = [warning => 'A shorter solution is possible'];
our $warn_code_is_very_long = [error => 'A significantly shorter solution is possible'];

# a criterion is a pair [abs, rel]. a program matches a criterion if
# the absolute loc difference is at most abs AND the relative loc
# difference is at most rel. These criteria are used to categorise
# code as "short", "long", or "very long".

# code is considered short if one of these criteria match
our @short_code_criteria = (
	[1e9, 0.3],
	[20,  0.5],
	[10,  1],
);

# code is considered long if one of these criteria match, and none of
# the above do
our @long_code_criteria = (
	[1e9, 0.5],
	[20, 1],
	[10, 2],
);

# code is considered very long if none of the criteria above match

=head3 test_lines

This test counts non-empty lines in both the code and the reference.
If the code is significantly longer than the reference, it returns a warning.
If the code is much longer, it returns an error.
Otherwise it returns an empty arrayref.

The thresholds for raising a warning/error are available in the source
code, see global variables C<@short_code_criteria> and
C<@long_code_criteria>.

This test fails if no reference is provided, but is language-agnostic

=cut

sub test_lines {
	my %args = @_;
	my $user_solution = $args{code};
	my $official_solution = $args{reference};
	return unless defined $official_solution;

	$user_solution = remove_empty_lines($user_solution . "\n");
	$official_solution = remove_empty_lines($official_solution . "\n");

	# Count number of lines of code from both solutions.
	my $loc_user_solution = () = $user_solution =~ /\n/g;
	my $loc_official_solution = () = $official_solution =~ /\n/g;
	return if $loc_official_solution == 0;

	my $loc_absolute_diff = $loc_user_solution - $loc_official_solution;
	my $loc_relative_diff = $loc_absolute_diff / $loc_official_solution;
	diag "abs diff: $loc_absolute_diff, rel diff: $loc_relative_diff";
	my $predicate = sub {
		$loc_absolute_diff <= $_->[0] && $loc_relative_diff <= $_->[1]
	};

	return [] if any \&$predicate, @short_code_criteria;
	return [$warn_code_is_long] if any \&$predicate, @long_code_criteria;
	return [$warn_code_is_very_long]
}

=head3 test_clang_tidy

This test runs the
L<clang-tidy|https://clang.llvm.org/extra/clang-tidy/> static analyser
on the code and returns all warnings found.

The clang-tidy checks in use are determined by two global variables,
each of which is a list of globs such as C<modernize-*>. The checks in
C<@clang_tidy_warnings> produce warnings, while the checks in
C<@clang_tidy_errors> produce errors. There is also a hash
C<%clang_tidy_check_options> which contains configuration for the
checks.

This test does not require a reference, but is limited to languages
that clang-tidy understands. This is controlled by the global variable
C<%extension_of_language>, which contains file extensions for the
supported languages.

=cut

our %extension_of_language = (
	'C' => '.c',
	'C++' => '.cpp',
);

our @clang_tidy_warnings =
	qw/clang-analyzer-deadcode.DeadStores
	   clang-analyzer-unix.*
	   clang-analyzer-valist.*
	   misc-*
	   modernize-*
	   performance-*
	   readability-*
	   -readability-braces-around-statements/;

our @clang_tidy_errors =
	qw/bugprone-*
	   clang-analyzer-core.*
	   clang-analyzer-cplusplus.*
	   clang-diagnostic-*/;

our %clang_tidy_check_options = (
	'readability-implicit-bool-conversion.AllowIntegerConditions' => 1,
);

sub _clang_tidy_exists {
	# does clang-tidy exist?
	# run it with no arguments, see if exit code is 127
	system 'clang-tidy 2>/dev/null 1>/dev/null';
	$? >> 8 != 127
}

sub test_clang_tidy {
	my %args = @_;
	my $extension = $extension_of_language{uc $args{language}};
	return unless defined $extension;

	my $fh = File::Temp->new(
		TEMPLATE => 'code-qualityXXXXX',
		TMPDIR => 1,
		SUFFIX => $extension,
	);
	print $fh $args{code} or croak 'Failed to write code to temporary file';
	close $fh or croak 'Failed to close temporary file';

	my $checks = join ',', '-*', @clang_tidy_warnings, @clang_tidy_errors;
	my $errors = join ',', '-*', @clang_tidy_errors;
	my @check_options;
	while (my ($key, $value) = each %clang_tidy_check_options) {
		push @check_options, { key => $key, value => $value }
	}
	my $config = encode_json +{
		CheckOptions => \@check_options,
		Checks => $checks,
		WarningsAsErrors => $errors,
	};

	my @output = qx,clang-tidy -config='$config' -quiet $fh 2>/dev/null,;
	my $exit_code = $? >> 8; # this is usually the number of clang-tidy errors
	my $signal = $? & 127;
	if ($signal || ($exit_code == 127 && !_clang_tidy_exists)) {
		# special case: exit code 127 could mean "127 errors found" or
		# "clang-tidy not found"
		carp "Failed to run clang-tidy, \$? is $?";
		return
	}

	my @warnings;
	for my $line (@output) {
		my ($row, $col, $type, $msg) =
		  $line =~ /$fh:(\d+):(\d+): (\w+): (.*)$/
		  or next;
		chomp $msg;
		$msg =~ s/,-warnings-as-errors//;
		$type = 'info' if $type eq 'note';
		push @warnings, [$type, $msg, $row, $col]
	}
	\@warnings
}

=head3 analyse_code

B<analyse_code> runs every test above on the code, producing a
combined list of warnings. It fails (returns undef) if all tests fail.
The tests run by B<analyse_code> are those in the global variable
C<@all_tests>, which is a list of coderefs.

=cut

our @all_tests = (
	\&test_lines,
	\&test_clang_tidy,
);

sub analyse_code {
	# arguments/return value are identical to those of individual tests
	my @test_args = @_;
	my @test_results = map { $_->(@test_args) } @all_tests;
	reduce {
		# $a accumulates warnings so far, $b are warnings from current test
		return $b unless defined $a;
		push @$a, @$b if defined $b;
		$a
	} @test_results;
}

=head2 Star rating

B<star_rating_of_warnings>(I<$warnings>) is a subroutine that takes
the output of a test and computes the star rating as an integer. The
rating is undef if the test failed, 1 if the test returned at least
one error, 2 if the test returned at least one warning but no errors,
and 3 otherwise. So a program gets 3 stars if it only raises
informational messages, or no messages at all.

=cut

sub star_rating_of_warnings {
	my ($warnings) = @_;
	return unless defined $warnings;
	return 1 if any { $_->[0] eq 'error' } @$warnings;
	return 2 if any { $_->[0] eq 'warning' } @$warnings;
	return 3;
}

1;
__END__

=head1 EXPORT

By default only B<analyse_code> and B<star_rating_of_warnings> are exported.

The other tests can be exported on request.

=head1 AUTHOR

Marius Gavrilescu, E<lt>marius@ieval.roE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2019 by Wellcode PB SRL

Code::Quality is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

Code::Quality is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public
License along with Code::Quality. If not, see
L<https://www.gnu.org/licenses/>.

=cut
