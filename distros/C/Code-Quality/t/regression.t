#!/usr/bin/perl
use strict;
use warnings;
use lib '.';

use t::lib;
use File::Slurper qw/read_lines/;
use List::Util qw/uniq/;
use Test::More;
use String::Escape qw/unbackslash/;

BEGIN {
	if ($ENV{RELEASE_TESTING}) {
		plan tests => 27;
	} else {
		plan skip_all => '$ENV{RELEASE_TESTING} is false'
	}
}

BEGIN { use_ok('Code::Quality', qw/:all/) };

my $expected_reference = [];
my $expected_long_code = [];
my $expected_long_code_with_bug = [
	[error => 'format specifies type \'int\' but the argument has type \'long\' [clang-diagnostic-format]', 14, 36],
];

sub run_test {
	my ($code, $expected, $message) = @_;
	my $actual = analyse_code code => $_[0], language => 'C';
	is_deeply $actual, $expected, $message or diag explain $actual
}

run_test $t::lib::reference, $expected_reference, 'reference';
run_test $t::lib::long_code, $expected_long_code, 'long_code';
run_test $t::lib::long_code_with_bug, $expected_long_code_with_bug, 'long_code_with_bug';

sub extract_error {
	my $message = $_->[1];
	my ($error) = $message =~ /\[(.*)\]$/;
	defined $error ? $error : ()
}

sub run_simplified_test {
	my ($code, @expected_warnings) = @_;
	my $actual = test_clang_tidy code => $_[0], language => 'C++';
	my @actual_warnings = uniq sort map { extract_error } @$actual;
	is_deeply \@actual_warnings, \@expected_warnings or diag join ' ', @actual_warnings;
	@actual_warnings
}

my @sources = read_lines 't/examples.txt';
my @expect = (
	['clang-diagnostic-unused-value', 'readability-misleading-indentation'],
	['readability-container-size-empty'],
	['bugprone-narrowing-conversions', 'readability-non-const-parameter'],
	['clang-analyzer-core.UndefinedBinaryOperatorResult', 'modernize-use-bool-literals', 'readability-else-after-return'],
	['readability-implicit-bool-conversion'],
	['readability-implicit-bool-conversion'],
	['clang-analyzer-core.CallAndMessage'],
	['readability-container-size-empty'],
	['clang-analyzer-core.UndefinedBinaryOperatorResult'],
	['readability-container-size-empty'],
	['clang-analyzer-core.uninitialized.Assign'],
	['readability-implicit-bool-conversion'],
	['readability-implicit-bool-conversion'],
	['modernize-use-bool-literals', 'readability-implicit-bool-conversion'],
	['readability-implicit-bool-conversion', 'readability-non-const-parameter'],
	['readability-implicit-bool-conversion'],
	['clang-analyzer-deadcode.DeadStores'],
	['readability-implicit-bool-conversion'],
	['modernize-loop-convert'],
	['clang-analyzer-core.CallAndMessage', 'readability-simplify-boolean-expr'],
	['performance-inefficient-string-concatenation', 'performance-unnecessary-value-param', 'readability-container-size-empty'],
	['readability-container-size-empty'],
	['performance-for-range-copy']
);

# correct versions of @sources and @expect
# these are printed out if the environment contains PRINT_FIXES=1
my @out_sources;
my @out_expect;

for my $idx (0 .. $#sources) {
	my $src = unbackslash $sources[$idx];
	my @warns = run_simplified_test $src, @{$expect[$idx]};
	if (@warns) {
		push @out_sources, $sources[$idx];
		push @out_expect, \@warns;
	}
}

if ($ENV{PRINT_FIXES}) {
	say STDERR join "\n", @out_sources;
	say STDERR explain \@out_expect;
}
