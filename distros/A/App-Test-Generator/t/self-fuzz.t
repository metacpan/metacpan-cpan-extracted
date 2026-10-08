#!/usr/bin/env perl
use strict;
use warnings;

# Automatically generate and run tests for each function in the package.

# End-to-end self-test: for every .pm under lib/, run the CLI pipeline
#   extract-schemas --output-dir $tmp $pm
#   fuzz-harness-generator -r $tmp/$func.yml
# and verify that every generated fuzz harness passes.
#
# Requires EXTENDED_TESTING=1.  Set TEST_VERBOSE=1 for per-step output.
#
# When a harness fails, check extract-schemas first: the generated YAML may
# contain wrong types or constraints that a SchemaExtractor fix can address.
# Only fall back to POD edits when the extractor cannot determine the right
# schema from the code.

use Test::DescribeMe qw(extended);
use Test::Most;
use File::Find;
use File::Path qw(rmtree);
use File::Spec;
use File::Temp ();
use FindBin qw($Bin);
use IPC::Run3;
use YAML::XS qw(LoadFile);

my $VERBOSE = $ENV{TEST_VERBOSE} // 0;

my $extract_bin = File::Spec->catfile($Bin, '..', 'bin', 'extract-schemas');
my $fuzz_bin    = File::Spec->catfile($Bin, '..', 'bin', 'fuzz-harness-generator');

# Populated during the run; each entry: { module, func, tests, status }
# status: 'ok' | 'failed' | 'private' | 'no_fuzz' | 'oop' | 'no_can'
my @fuzz_report;

# Functions that cannot be fuzz-tested via this CLI pipeline.
# When adding an entry here, first check whether extract-schemas produces a
# wrong schema (fix SchemaExtractor) before resorting to a skip.
#
#   generate       - requires schemas/generate.yml on disk (memberof path) and
#                    takes 40+ s; tested separately via fuzz-harness-generator
#   DB::DB         - Perl debugger hook; auto-filtered by SchemaExtractor since
#                    0.45 (cross-package subs skipped); kept here as a belt-and-
#                    suspenders guard in case the schema somehow surfaces it
#   get_data_section - returns a ref type that Test::Returns cannot validate
#   new            - constructors need properly typed args (hashref/object);
#                    SchemaExtractor infers 'string' and the harness sends
#                    random strings, crashing every call
#   merge          - requires valid file paths that exist on disk
#   mutate         - requires a live PPI::Document object; schema has new: ~
#                    so auto-detected as OOP, but kept here for clarity
#   applies_to     - requires a live PPI::Document object; same as mutate
#   absorb_legacy_output - silently returns for non-hashref input rather than
#                    croaking; harness generates DIES tests that always fail
#   calculate_age  - integer min constraint causes rand() to generate sub-minimum
#                    values (e.g. 0..1899) that die with "Birth year out of range";
#                    harness expects survival but the function dies
#   add_evidence   - category and signal accept only specific enum values; schema
#                    says 'string' so harness sends random strings which croak with
#                    "Invalid evidence category '...'" — enum constraints not yet
#                    supported in the schema format
#   classification - getter that returns undef until resolve_classification() is
#                    called; output spec says 'string' but freshly-constructed
#                    objects have classification=undef; Return::Set validation fails
#   evidence       - returns a list (not a reference), so scalar context gives 0;
#                    output spec says 'arrayref' but harness captures in scalar context
#   validate_email - requires valid email format (regex with @); harness generates random
#                    strings that don't satisfy the format check; enum-like semantic
#   return_type    - getter returning undef until resolve_return_type() called; output
#                    spec says string but freshly-constructed objects have return_type=undef
#
# The following methods belong to classes whose new() requires mandatory arguments
# (schema+target_sub, file+lib_dir, or file) that cannot be synthesised
# automatically.  SchemaExtractor now emits new:{} (no-arg fallback) instead of
# new:~ for these, but the harness discovers at runtime that new() dies without
# its required args.
#   load_corpus / minimize_corpus / run / save_corpus
#                  - CoverageGuidedFuzzer::new requires schema (hashref) and
#                    target_sub (coderef); new() with no args croaks immediately
#   apply_mutant / generate_mutants / prepare_workspace / run_tests
#                  - Mutator::new requires file and lib_dir; new() with no args croaks
#   extract        - PodExampleExtractor::new requires file; new() with no args croaks
#   extract_all / generate_pod_validation_report
#                  - SchemaExtractor::new requires input_file; new() with no args croaks
my %no_fuzz = map { $_ => 1 } qw(
	generate
	DB::DB
	get_data_section
	new
	merge
	mutate
	applies_to
	absorb_legacy_output
	calculate_age
	add_evidence
	classification
	evidence
	validate_email
	return_type
	load_corpus
	minimize_corpus
	run
	save_corpus
	apply_mutant
	generate_mutants
	prepare_workspace
	run_tests
	extract
	extract_all
	generate_pod_validation_report
);

# Collect every .pm under lib/
my $lib_dir = File::Spec->catdir($Bin, '..', 'lib');
my @pm_files;
find(
	{ wanted  => sub { push @pm_files, $File::Find::name if /\.pm$/ },
	  no_chdir => 1 },
	$lib_dir
);
@pm_files = sort @pm_files;

diag(scalar(@pm_files) . ' .pm files to self-test') if $VERBOSE;

for my $pm_file (@pm_files) {
	# Derive a readable module name from the file path
	my $module = $pm_file;
	$module =~ s{.*\blib/}{};
	$module =~ s/\.pm$//;
	$module =~ s{/}{::}g;

	subtest "self-fuzz: $module" => sub {
		my $tmpdir = File::Temp::tempdir(CLEANUP => 0);
		my $failed = 0;

		# ── Step 1: extract schemas via CLI ──────────────────────────────
		diag("step 1: extract-schemas $pm_file") if $VERBOSE;

		my ($out, $err);
		run3(
			[$extract_bin, '--output-dir', $tmpdir, '--strict-pod=warn', $pm_file],
			\undef, \$out, \$err
		);
		my $rc = $? >> 8;

		if ($rc != 0) {
			fail("extract-schemas failed (exit $rc)");
			diag("stdout:\n$out") if $out;
			diag("stderr:\n$err") if $err;
			diag("Diagnostics kept in: $tmpdir");
			done_testing();
			return;
		}

		diag("stdout:\n$out") if $VERBOSE && $out;
		pass('extract-schemas succeeded');

		# ── Step 2: find generated schema files ──────────────────────────
		my @yml_files = sort glob("$tmpdir/*.yml");

		unless (@yml_files) {
			pass('no schemas extracted (nothing to fuzz)');
			rmtree($tmpdir);
			done_testing();
			return;
		}

		diag(scalar(@yml_files) . ' schema(s) to fuzz') if $VERBOSE;

		# ── Step 3: fuzz-harness-generator -r on each schema ─────────────
		for my $yml_file (@yml_files) {
			my ($func) = $yml_file =~ m{/([^/]+)\.yml$};

			# Private functions lack input validation; the harness generates
			# "dies on bad type" tests that always fail for them.
			if ($func =~ /^_/) {
				push @fuzz_report, { module => $module, func => $func, status => 'private' };
				pass("$func: skipped (private)");
				next;
			}

			if ($no_fuzz{$func}) {
				push @fuzz_report, { module => $module, func => $func, status => 'no_fuzz' };
				pass("$func: skipped (in no_fuzz list)");
				next;
			}

			# Read the schema to detect conditions that make harness running
			# wrong: OOP instance methods need a real object the fuzzer can't
			# build; mandatory 'object'-typed params without a 'can' key also
			# can't be mocked.
			my $schema = eval { (LoadFile($yml_file))[0] };
			if ($@) {
				fail("$func: cannot load schema YAML");
				diag($@);
				push @fuzz_report, { module => $module, func => $func, status => 'failed' };
				$failed++;
				next;
			}

			if (exists $schema->{new} && !defined($schema->{new})) {
				# new: null means SchemaExtractor could not generate representative
				# constructor args (e.g. constructor needs a coderef or object param).
				# Skip — the harness can't build $self automatically in this case.
				push @fuzz_report, { module => $module, func => $func, status => 'oop' };
				pass("$func: skipped (OOP instance method - constructor not auto-buildable)");
				next;
			}

			if (ref($schema->{input}) eq 'HASH') {
				my $skip;
				for my $spec (values %{$schema->{input}}) {
					next unless ref($spec) eq 'HASH';
					if (($spec->{type} // '') eq 'object'
						&& !$spec->{optional}
						&& !defined $spec->{can}) {
						$skip = 1;
						last;
					}
				}
				if ($skip) {
					push @fuzz_report, { module => $module, func => $func, status => 'no_can' };
					pass("$func: skipped (mandatory object param without 'can')");
					next;
				}
			}

			diag("  fuzz-harness-generator -r $func.yml") if $VERBOSE;

			my ($fuzz_out, $fuzz_err);
			run3(
				[$fuzz_bin, '-r', $yml_file],
				\undef, \$fuzz_out, \$fuzz_err
			);
			my $fuzz_rc = $? >> 8;

			if ($fuzz_rc != 0) {
				fail("$func: fuzz harness failed");
				diag("output:\n$fuzz_out") if $fuzz_out;
				diag("stderr:\n$fuzz_err") if $fuzz_err;
				diag("Schema kept in: $yml_file");
				push @fuzz_report, { module => $module, func => $func, status => 'failed' };
				$failed++;
				last;
			} else {
				my $n = ($fuzz_out =~ /Tests=(\d+)/) ? $1 : 0;
				push @fuzz_report, { module => $module, func => $func, status => 'ok', tests => $n };
				pass("$func: fuzz harness passed ($n tests)");
			}
		}

		rmtree($tmpdir) unless $failed;

		done_testing();
	};
}

if (@fuzz_report) {
	my $mw = (sort { $b <=> $a } map { length($_->{module}) } @fuzz_report)[0];
	my $fw = (sort { $b <=> $a } map { length($_->{func})   } @fuzz_report)[0];
	$mw = 30 if $mw < 30;
	$fw = 24 if $fw < 24;

	my $total = 0;
	diag('');
	diag('Fuzz test summary:');
	diag(sprintf '  %-*s  %-*s  %s', $mw, 'Module', $fw, 'Routine', 'Tests');
	diag(sprintf '  %-*s  %-*s  %s', $mw, '-' x $mw, $fw, '-' x $fw, '-----');
	for my $r (sort { $a->{module} cmp $b->{module} || $a->{func} cmp $b->{func} } @fuzz_report) {
		my $tests_col =
			$r->{status} eq 'ok'      ? $r->{tests}                          :
			$r->{status} eq 'failed'  ? 'FAILED'                              :
			$r->{status} eq 'private' ? 'skipped (internal helper)'           :
			$r->{status} eq 'no_fuzz' ? 'skipped (excluded from fuzz list)'   :
			$r->{status} eq 'oop'     ? 'skipped (constructor not auto-buildable)' :
			$r->{status} eq 'no_can'  ? 'skipped (object param without can:)' : '?';
		diag(sprintf '  %-*s  %-*s  %s', $mw, $r->{module}, $fw, $r->{func}, $tests_col);
		$total += $r->{tests} // 0;
	}
	diag(sprintf '  %-*s  %-*s  %d', $mw, '', $fw, 'TOTAL', $total);
}

done_testing();
