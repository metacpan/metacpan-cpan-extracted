#!/usr/bin/env perl
use strict;
use warnings;

# Self-test: run every ATG .pm file through SchemaExtractor (strict_pod=fatal),
# generate a fuzz harness for each extracted schema, and prove it.
# Temp dirs are kept on failure for diagnosis.

use Test::DescribeMe qw(extended);
use Test::Most;
use Capture::Tiny qw(capture);
use File::Find;
use File::Path qw(rmtree);
use File::Spec;
use File::Temp ();
use FindBin qw($Bin);
use YAML::XS qw(LoadFile DumpFile);

use constant PROVE_TIMEOUT => 0;	# seconds per module before killing prove

my $VERBOSE = $ENV{TEST_VERBOSE} // 0;

BEGIN {
	use_ok('App::Test::Generator::SchemaExtractor');
	use_ok('App::Test::Generator');
}

# Collect all .pm files under lib/.
# no_chdir avoids File::Find calling chdir() with tainted directory names,
# which would die under prove -t (taint mode).
my $lib_dir = File::Spec->catdir($Bin, '..', 'lib');
my @pm_files;
find(
	{ wanted => sub { push @pm_files, $File::Find::name if /\.pm$/ },
	  no_chdir => 1 },
	$lib_dir
);

diag(scalar(@pm_files) . ' .pm files to self-test') if $VERBOSE;

for my $pm_file (sort @pm_files) {
	subtest "self-test: $pm_file" => sub {

		# Never auto-clean: we keep the dir if anything fails so the user
		# can inspect the intermediate schema YAML and generated .t files.
		my $tmpdir = File::Temp::tempdir(CLEANUP => 0);
		my $failed = 0;

		# ── Step 1: extract schemas ──────────────────────────────────────
		diag("step 1: extracting schemas from $pm_file") if $VERBOSE;
		my $t0 = time;

		my $extractor = App::Test::Generator::SchemaExtractor->new(
			input_file => $pm_file,
			output_dir => $tmpdir,
			strict_pod => 'fatal',
			verbose    => 0,
		);

		my $schemas;
		eval { $schemas = $extractor->extract_all() };
		if ($@) {
			fail("SchemaExtractor died for $pm_file");
			diag($@);
			diag("Diagnostics kept in: $tmpdir");
			done_testing();
			return;
		}

		if (!$schemas || !keys %$schemas) {
			pass("no methods extracted from $pm_file");
			rmtree($tmpdir);
			done_testing();
			return;
		}

		my $n_schemas = scalar keys %$schemas;
		diag(sprintf('step 1 done in %ds: %d schemas extracted (%s)',
			time - $t0, $n_schemas, join(', ', sort keys %$schemas))) if $VERBOSE;

		pass('SchemaExtractor completed without error');

		# ── Step 2: generate a fuzz harness for each schema ──────────────
		diag("step 2: generating fuzz harnesses") if $VERBOSE;
		$t0 = time;

		# Functions that require real file-system inputs can't be meaningfully
		# fuzz-tested: the harness would supply random strings as file paths and
		# every call would die with "file not found". Syntax-check these files
		# (step 3a) but skip them in the prove run (step 3b).
		# DB::DB is a Perl debugger hook in the DB package; ATG extracts it
		# from Devel::... files but it is not callable as a module method.
		# get_data_section returns a reference whose type PVS cannot validate.
		# new constructors often require mandatory parameters the fuzzer can't supply.
		# export conflicts with Perl's import mechanism; generated test uses 'use export'.
		# merge/if/applies_to require real files or PPI objects or are Perl keywords.
		# mutate/applies_to require a PPI::Document object the fuzzer can't construct.
		# render_args_hash/render_arrayref_map/render_hash return '' for
		# wrong-type inputs rather than dying, so fuzz "dies" tests fail.
		my %no_prove = map { $_ => 1 } qw(generate DB::DB get_data_section new export merge mutate applies_to if render_args_hash render_arrayref_map render_hash);

		my @test_files;
		my @prove_files;
		for my $func (sort keys %$schemas) {
			my $schema_file = File::Spec->catfile($tmpdir, "${func}.yml");
			next unless -f $schema_file;

			# Patch schema: short per-case timeout (3s vs default 10s), no
			# test_empty, low iterations, and cap string max lengths.
			# The 64K-string cases come from a separate path and are only
			# suppressed by setting max; test_empty only removes '' cases.
			my $skip_prove = 0;
			eval {
				my ($schema) = LoadFile($schema_file);
				if (ref($schema) eq 'HASH') {
					$schema->{iterations}             = 3;
					$schema->{config}{timeout}        = 3;
					$schema->{config}{test_empty}     = 0;
					$schema->{config}{close_stdin}    = 1;
					# Cap unconstrained file-path string fields to prevent 64K-char test cases.
					# Only applied to fields whose name suggests a file path — not general
					# string arguments like 's', 'v', etc., which don't enforce length.
					if (ref($schema->{input}) eq 'HASH') {
						for my $field (keys %{$schema->{input}}) {
							my $spec = $schema->{input}{$field};
							next unless ref($spec) eq 'HASH';
							if (($spec->{type}//'') eq 'string'
								&& !defined($spec->{max})
								&& $field =~ /(?:file|path|dir|filename|dirname)/i) {
								$spec->{max} = 1025;
							}
							# A mandatory 'object'-type param without 'can' cannot be
							# mocked by the fuzz harness — skip prove for such functions.
							if (($spec->{type}//'') eq 'object'
								&& !$spec->{optional}
								&& !defined($spec->{can})) {
								$skip_prove = 1;
							}
						}
					}
					# OOP instance methods have 'new:' in their schema — the fuzz
					# harness would need to instantiate the class, which fails for
					# classes whose constructors require mandatory parameters.
					$skip_prove = 1 if exists $schema->{new};
					DumpFile($schema_file, $schema);
				}
			};

			# Private functions (leading underscore) are internal helpers that
			# typically lack input validation; fuzz tests expect die-on-bad-input.
			$skip_prove = 1 if $func =~ /^_/;

			my $test_file = File::Spec->catfile($tmpdir, "${func}.t");

			diag("  generating $func.t") if $VERBOSE;
			my (undef, undef) = capture {
				eval {
					App::Test::Generator->generate(
						schema_file => $schema_file,
						output_file => $test_file,
					);
				};
			};

			if ($@) {
				fail("Generator died for $func in $pm_file");
				diag($@);
				diag("Diagnostics kept in: $tmpdir");
				$failed++;
				next;
			}

			if (-f $test_file) {
				push @test_files, $test_file;
				push @prove_files, $test_file
					unless $no_prove{$func} || $skip_prove;
			}
		}

		diag(sprintf('step 2 done in %ds: %d test files generated (%d for prove)',
			time - $t0, scalar @test_files, scalar @prove_files)) if $VERBOSE;

		pass('fuzz harnesses generated without error') unless $failed;

		# ── Step 3: syntax-check every generated harness, then optionally run ──
		if (@test_files) {
			# Always: perl -c each file — fast, catches bad generated code.
			diag(sprintf('step 3a: syntax-checking %d file(s)', scalar @test_files))
				if $VERBOSE;
			$t0 = time;

			for my $test_file (@test_files) {
				diag("  perl -c $test_file") if $VERBOSE;
				my (undef, $syntax_err) = capture {
					system('perl', '-Ilib', '-c', $test_file);
				};
				if ($?) {
					fail("syntax error in generated $test_file");
					diag($syntax_err);
					diag("Diagnostics kept in: $tmpdir");
					$failed++;
				}
			}
			pass('all generated harnesses have valid syntax') unless $failed;
			diag(sprintf('step 3a done in %ds', time - $t0)) if $VERBOSE;

			# Optionally: run the fuzz harnesses through prove.
			# Set TEST_JOBS=1 (or any value) to enable; parallelism via TEST_JOBS > 1.
			if (defined $ENV{TEST_JOBS} && @prove_files) {
				my $jobs     = int($ENV{TEST_JOBS}) || 1;
				my $limit_str = PROVE_TIMEOUT ? PROVE_TIMEOUT . 's limit' : 'no limit';
				my $skipped  = @test_files - @prove_files;
				diag(sprintf('step 3b: running prove on %d file(s) (jobs=%d, %s%s)',
					scalar @prove_files, $jobs, $limit_str,
					$skipped ? ", $skipped skipped (require real files)" : '')) if $VERBOSE;
				$t0 = time;

				my $out_file = File::Spec->catfile($tmpdir, '_prove_stdout.txt');
				my $err_file = File::Spec->catfile($tmpdir, '_prove_stderr.txt');

				my @prove_cmd = ('prove', '-Ilib', '--nocolor');
				push @prove_cmd, "-j$jobs" if $jobs > 1;
				push @prove_cmd, @prove_files;

				# Fork prove with stdin=/dev/null and stdout/stderr to temp files
				# to avoid pipe-buffer deadlocks from fuzz-induced TAP floods.
				my $pid = fork() // die "fork failed: $!";
				if ($pid == 0) {
					# Don't let verbose flags flood the harness stderr files.
					delete $ENV{TEST_VERBOSE};
					open(STDIN,  '<', File::Spec->devnull()) or exit 1;
					open(STDOUT, '>', $out_file)             or exit 1;
					open(STDERR, '>', $err_file)             or exit 1;
					exec @prove_cmd;
					exit 1;
				}

				# Parent: wait (with optional timeout) then reap.
				my $timed_out = 0;
				my $child_status;
				eval {
					local $SIG{ALRM} = sub {
						$timed_out = 1;
						kill 'KILL', $pid;
						die "prove timed out\n";
					};
					alarm(PROVE_TIMEOUT) if PROVE_TIMEOUT;
					waitpid($pid, 0);
					$child_status = $?;
					alarm(0) if PROVE_TIMEOUT;
				};
				alarm(0);
				waitpid($pid, 0) if $timed_out;	# reap zombie after kill

				my $elapsed = time - $t0;
				diag(sprintf('step 3b done in %ds%s', $elapsed,
					$timed_out ? ' (killed — hit ' . PROVE_TIMEOUT . 's limit)' : ''))
					if $VERBOSE;

				my $prove_status = $timed_out ? 1 : ($child_status >> 8);
				my $prove_out = do { local $/; open(my $f, '<', $out_file) or die $!; <$f> }
					if -f $out_file;
				my $prove_err = do { local $/; open(my $f, '<', $err_file) or die $!; <$f> }
					if -f $err_file;

				if ($prove_status != 0) {
					my $reason = $timed_out ? ' (killed after ' . PROVE_TIMEOUT . 's)' : '';
					fail("prove failed$reason for $pm_file");
					diag("stdout:\n$prove_out") if $prove_out;
					diag("stderr:\n$prove_err") if $prove_err;
					diag("Schema YAML and generated tests kept in: $tmpdir");
					$failed++;
				} else {
					pass("prove passed for all schemas from $pm_file");
				}
			}
		} else {
			pass('no test files to run (all schemas lacked output_file)');
		}

		# ── Cleanup: only remove the temp dir when everything passed ─────
		rmtree($tmpdir) unless $failed;

		done_testing();
	};
}

done_testing();
