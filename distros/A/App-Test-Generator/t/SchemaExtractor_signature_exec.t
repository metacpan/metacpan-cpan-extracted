#!/usr/bin/env perl
use strict;
use warnings;

use Test::Most;
use File::Spec;
use File::Temp qw(tempdir tempfile);

# Regression tests for the allow_signature_exec opt-in gate on
# _compile_signature_isolated(). Extracting parameter types from a
# Type::Params signature_for() declaration requires executing code
# sliced from the target module's own source, unlike every other
# extraction path in this module, which is static PPI-only analysis.
# That execution must never happen unless the caller explicitly opts
# in, regardless of whether the denylist pre-filter would also have
# rejected the expression.

BEGIN {
	use_ok('App::Test::Generator::SchemaExtractor');
}

sub create_test_module {
	my ($content) = @_;
	my $dir = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, 'TestModule.pm');
	open my $fh, '>', $file or die "Cannot create $file: $!";
	print $fh $content;
	close $fh;
	return $file;
}

subtest 'signature_for extraction is skipped by default (no allow_signature_exec)' => sub {
	my $module = <<'END_MODULE';
use Types::Standard qw(Num);
use Type::Params qw(-sigs);

signature_for add_numbers => (
  method      => 1,
  positional  => [ Num, Num ],
  returns     => Num
);

sub add_numbers ( $self, $first, $second ) {
	return $first + $second;
}
END_MODULE

	my $module_file = create_test_module($module);
	my $extractor = App::Test::Generator::SchemaExtractor->new(
		input_file => $module_file,
		output_dir => tempdir(CLEANUP => 1),
	);

	ok(!$extractor->{allow_signature_exec}, 'allow_signature_exec defaults to off');

	my $schemas = $extractor->extract_all();
	ok(defined($schemas), 'extract_all still succeeds');

	my $schema = $schemas->{add_numbers};
	ok($schema, 'add_numbers schema entry exists');

	# Without the opt-in, nothing was executed to populate parameter
	# types from the signature_for() declaration.
	ok(!exists($schema->{input}{arg0}), 'no parameter info extracted from signature_for without opt-in');
};

subtest '_compile_signature_isolated() never executes when allow_signature_exec is off' => sub {
	my (undef, $marker) = tempfile(UNLINK => 0);
	unlink $marker;

	my $module_file = create_test_module("package TestModule;\n1;\n");
	my $extractor = App::Test::Generator::SchemaExtractor->new(
		input_file => $module_file,
		output_dir => tempdir(CLEANUP => 1),
	);

	# Even a signature expression that the denylist would also reject
	# must never be evaluated: the opt-in gate is checked first.
	my $result = $extractor->_compile_signature_isolated(
		'evil',
		qq{( positional => [ Num ], system("touch", "$marker") )},
	);

	ok(!defined($result), '_compile_signature_isolated() returns undef without opt-in');
	ok(!-e $marker, 'no subprocess executed: marker file was never created');

	unlink $marker if -e $marker;
};

done_testing();
