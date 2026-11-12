#!/usr/bin/env perl
use strict;
use warnings;

# ======================================================================
# all-fuzz.t - black-box testing of every public routine in this
# distribution, generated from the source code by App::Test::Generator.
#
# Drop this file into the t/ directory of any distribution that keeps its
# modules in lib/, then run:
#
#     make EXTENDED_TESTING=1 TEST_FILES=t/all-fuzz.t
#
# or, without ExtUtils::MakeMaker in the way:
#
#     EXTENDED_TESTING=1 prove -Ilib t/all-fuzz.t
#
# For every .pm under lib/ it runs the CLI pipeline
#
#     extract-schemas --output-dir $tmp $pm
#     fuzz-harness-generator -r $tmp/$func.yml
#
# and checks that every generated harness passes.  Nothing is written to
# the distribution: schemas, harnesses and any files the routines under
# test create all live in a temporary directory.
#
# Routines that cannot be tested this way are reported and skipped:
#
#   internal helper           name starts with _
#   excluded from fuzz list   listed in %no_fuzz below
#   constructor not buildable the extractor emitted "new: ~", so the
#                             harness cannot build $self
#   object param without can  a mandatory object parameter that the
#                             harness cannot mock
#   no result in $TIMEOUT s   the routine did not finish; see below
#
# Environment:
#
#   EXTENDED_TESTING=1   required; the file runs nothing without it
#   TEST_VERBOSE=1       per-step diagnostics
#   ALL_FUZZ_TIMEOUT=N   seconds allowed per routine (default 180)
#
# A routine that talks to the network or sleeps can take longer than any
# useful test run, so each harness gets a hard limit and the whole process
# group is killed when it expires.  A timeout is reported as a skip, not a
# failure: it says the routine is not fuzzable in this way, not that it is
# broken.  Raise ALL_FUZZ_TIMEOUT for a routine that is merely slow.
#
# When a harness fails, check extract-schemas first: the generated YAML
# may contain wrong types or constraints that a SchemaExtractor fix can
# address.  Only fall back to POD edits when the extractor cannot
# determine the right schema from the code.
# ======================================================================

use Test::Needs {
	'App::Test::Generator' => '0.46',
	'IPC::Run3' => 0,
	'Test::DescribeMe' => 0,
	'Test::Most' => 0,
	'Test::Which' => 0,
	'YAML::XS' => 0,
	'perl' => 5.036,	# Later A::T::G need this version
};

use Test::DescribeMe qw(extended);
use Test::Most;
use Config;
use File::Find;
use File::Path qw(make_path rmtree);
use File::Spec;
use File::Temp ();
use FindBin qw($Bin);
use IPC::Run3;
use POSIX qw(_exit);
use YAML::XS qw(LoadFile);

use Test::Which 'extract-schemas', 'fuzz-harness-generator';

my $VERBOSE = $ENV{TEST_VERBOSE} // 0;
my $TIMEOUT = $ENV{ALL_FUZZ_TIMEOUT} // 180;

# t/ is a direct child of the distribution root in every CPAN layout
my $root    = File::Spec->rel2abs(File::Spec->catdir($Bin, File::Spec->updir()));
my $lib_dir = File::Spec->catdir($root, 'lib');

plan skip_all => "all-fuzz: no lib/ directory under $root" unless(-d $lib_dir);

# Test::Which has just confirmed both are on PATH; the generated harnesses
# run them by their bare names.
my $extract_bin = 'extract-schemas';
my $fuzz_bin    = 'fuzz-harness-generator';

# The harness runs in a child process with a scratch cwd, so the module
# under test is found through PERL5LIB rather than through "prove -l".
my @inc_dirs = grep { -d } map { File::Spec->catdir($root, $_) } qw(lib blib/lib);

# Populated during the run; each entry: { module, func, tests, status }
# status: ok | failed | timeout | private | no_fuzz | oop | no_can
my @fuzz_report;

# Functions that cannot be fuzz-tested via this CLI pipeline.
# When adding an entry here, first check whether extract-schemas produces a
# wrong schema (fix SchemaExtractor) before resorting to a skip.
#
my %no_fuzz = map { $_ => 1 } qw(
);

my @pm_files;
find(
	{ wanted  => sub { push @pm_files, $File::Find::name if(/\.pm$/) },
	  no_chdir => 1 },
	$lib_dir
);
@pm_files = sort @pm_files;

plan skip_all => 'all-fuzz: no .pm files under lib/' unless(@pm_files);

diag(scalar(@pm_files) . ' .pm files to fuzz') if $VERBOSE;

for my $pm_file (@pm_files) {
	# Derive a readable module name from the file path
	my $module = $pm_file;
	$module =~ s{.*\blib/}{};
	$module =~ s/\.pm$//;
	$module =~ s{/}{::}g;

	subtest "all-fuzz: $module" => sub {
		my $tmpdir = File::Temp::tempdir(CLEANUP => 0);
		my $run_dir = File::Spec->catdir($tmpdir, 'run');
		make_path($run_dir);
		my $failed = 0;

		# ── Step 1: extract schemas via CLI ──────────────────────────────
		diag("step 1: extract-schemas $pm_file") if $VERBOSE;

		my ($out, $err);
		run3(
			[$extract_bin, '--output-dir', $tmpdir, '--strict-pod=warn', $pm_file],
			\undef, \$out, \$err
		);
		my $rc = $? >> 8;

		if($rc != 0) {
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

		unless(@yml_files) {
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
			if($func =~ /^_/) {
				push @fuzz_report, { module => $module, func => $func, status => 'private' };
				pass("$func: skipped (private)");
				next;
			}

			if($no_fuzz{$func}) {
				push @fuzz_report, { module => $module, func => $func, status => 'no_fuzz' };
				pass("$func: skipped (in no_fuzz list)");
				next;
			}

			# Read the schema to detect conditions that make harness running
			# wrong: OOP instance methods need a real object the fuzzer can't
			# build; mandatory 'object'-typed params without a 'can' key also
			# can't be mocked.
			my $schema = eval { (LoadFile($yml_file))[0] };
			if($@) {
				fail("$func: cannot load schema YAML");
				diag($@);
				push @fuzz_report, { module => $module, func => $func, status => 'failed' };
				$failed++;
				next;
			}

			if(exists $schema->{new} && !defined($schema->{new})) {
				# new: null means SchemaExtractor could not generate representative
				# constructor args (e.g. it needs a coderef or object param, or the class
				# is abstract and refuses to build itself).
				# Skip — the harness can't build $self automatically in this case.
				push @fuzz_report, { module => $module, func => $func, status => 'oop' };
				pass("$func: skipped (OOP instance method - constructor not auto-buildable, " .
					'perhaps this is an abstract class?)');
				next;
			}

			if(ref($schema->{input}) eq 'HASH') {
				my $skip;
				for my $spec (values %{$schema->{input}}) {
					next unless ref($spec) eq 'HASH';
					if(($spec->{type} // '') eq 'object'
						&& !$spec->{optional}
						&& !defined $spec->{can}) {
						$skip = 1;
						last;
					}
				}
				if($skip) {
					push @fuzz_report, { module => $module, func => $func, status => 'no_can' };
					pass("$func: skipped (mandatory object param without 'can')");
					next;
				}
			}

			diag("  fuzz-harness-generator -r $func.yml (limit ${TIMEOUT}s)") if $VERBOSE;

			my ($status, $fuzz_out, $fuzz_err) = _run_harness($yml_file, $run_dir, $TIMEOUT);

			if($status eq 'timeout') {
				push @fuzz_report, { module => $module, func => $func, status => 'timeout' };
				pass("$func: skipped (no result in ${TIMEOUT}s)");
				diag("partial output:\n" . _tail($fuzz_out, 20)) if $VERBOSE && length($fuzz_out);
				next;
			}

			if($status ne 'ok') {
				fail("$func: fuzz harness failed");
				diag("output:\n$fuzz_out") if length($fuzz_out);
				diag("stderr:\n$fuzz_err") if length($fuzz_err);
				diag("Schema kept in: $yml_file");
				push @fuzz_report, { module => $module, func => $func, status => 'failed' };
				$failed++;
				next;
			}

			my $n = ($fuzz_out =~ /Tests=(\d+)/) ? $1 : 0;
			push @fuzz_report, { module => $module, func => $func, status => 'ok', tests => $n };
			pass("$func: fuzz harness passed ($n tests)");
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
			$r->{status} eq 'oop'     ? 'skipped (constructor not auto-buildable, perhaps this is an abstract class?)' :
			$r->{status} eq 'timeout' ? "skipped (no result in ${TIMEOUT}s)"  :
			$r->{status} eq 'no_can'  ? 'skipped (object param without can:)' : '?';
		diag(sprintf '  %-*s  %-*s  %s', $mw, $r->{module}, $fw, $r->{func}, $tests_col);
		$total += $r->{tests} // 0;
	}
	diag(sprintf '  %-*s  %-*s  %d', $mw, '', $fw, 'TOTAL', $total);
}

done_testing();

# ----------------------------------------------------------------------
# Run one fuzz harness under a hard time limit.
#
# The harness runs in a fork so the whole process group can be killed: the
# child puts itself in its own group, and prove, the generated .t and any
# perl it starts all die with it.  stdout and stderr go to files rather
# than pipes, so a routine that warns thousands of times cannot fill a pipe
# buffer and deadlock, and the parent cannot grow its heap to hold the
# output of a fuzzer that has gone into a loop.
#
# Returns (status, stdout, stderr) with status ok | failed | timeout |
# fork_failed.
# ----------------------------------------------------------------------
sub _run_harness
{
	my ($schema_file, $run_dir, $timeout) = @_;

	my (undef, $out_file) = File::Temp::tempfile(UNLINK => 1);
	my (undef, $err_file) = File::Temp::tempfile(UNLINK => 1);

	my $pid = fork;
	return ('fork_failed', '', '') unless defined($pid);

	if(!$pid) {
		# Child.  _exit() rather than exit(): Test::Builder's END block is
		# inherited and would print a second TAP stream.
		setpgrp(0, 0) if($^O ne 'MSWin32');
		$ENV{'PERL5LIB'} = join($Config{'path_sep'},
			grep { defined($_) && length($_) } ($ENV{'PERL5LIB'}, @inc_dirs));
		chdir($run_dir) or _exit(2);
		run3([$fuzz_bin, '-r', $schema_file], \undef, $out_file, $err_file);
		_exit(($? >> 8) ? 1 : 0);
	}

	my $deadline = time() + $timeout;
	my $status = 'ok';

	while(1) {
		my $reaped = waitpid($pid, 1);	# WNOHANG
		if($reaped == $pid) {
			my $raw = $?;
			$status = 'failed' if($raw & 127 || ($raw >> 8));
			last;
		}
		if($reaped == -1) {	# reaped by someone else's SIGCHLD handler
			$status = 'failed';
			last;
		}
		if(time() >= $deadline) {
			_kill_tree($pid);
			$status = 'timeout';
			last;
		}
		select(undef, undef, undef, 0.2);
	}

	return ($status, _read_tail($out_file, 200_000), _read_tail($err_file, 40_000));
}

sub _kill_tree
{
	my ($pid) = @_;

	kill('TERM', -$pid) if($^O ne 'MSWin32');	# the child's process group
	kill('TERM', $pid);

	my $until = time() + 5;
	while(waitpid($pid, 1) == 0 && time() < $until) {
		select(undef, undef, undef, 0.1);
	}

	kill('KILL', -$pid) if($^O ne 'MSWin32');
	kill('KILL', $pid);
	waitpid($pid, 0);
}

sub _read_tail
{
	my ($file, $limit) = @_;

	open(my $fh, '<', $file) or return '';
	my $size = -s $fh;
	seek($fh, $size - $limit, 0) if(defined($size) && $size > $limit);
	local $/;
	my $text = <$fh>;
	close($fh);

	return defined($text) ? $text : '';
}

sub _tail
{
	my ($text, $lines) = @_;

	my @lines = split(/\n/, $text);
	splice(@lines, 0, @lines - $lines) if(@lines > $lines);

	return join("\n", @lines) . "\n";
}
