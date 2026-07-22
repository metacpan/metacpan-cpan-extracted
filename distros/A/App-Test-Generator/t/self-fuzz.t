#!/usr/bin/env perl
use strict;
use warnings;

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
my %no_fuzz = map { $_ => 1 } qw(
	generate
	DB::DB
	get_data_section
	new
	merge
	mutate
	applies_to
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
	subtest "self-fuzz: $pm_file" => sub {
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
				pass("$func: skipped (private)");
				next;
			}

			if ($no_fuzz{$func}) {
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
				$failed++;
				next;
			}

			if (exists $schema->{new}) {
				pass("$func: skipped (OOP instance method)");
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
				$failed++;
			} else {
				pass("$func: fuzz harness passed");
			}
		}

		rmtree($tmpdir) unless $failed;

		done_testing();
	};
}

done_testing();
