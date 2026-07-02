#!/usr/bin/perl

use strict;
use warnings;

use Test::Most;
use Test::Returns;
use Test::Mockingbird qw(spy mock_scoped restore_all);
use Readonly;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(make_path);
use File::Basename qw(dirname);
use Scalar::Util qw(blessed);

# ── Constants ─────────────────────────────────────────────────────────────────

Readonly::Scalar my $VALID_VERSION   => '1.00';
Readonly::Scalar my $INVALID_VERSION => 'alpha';
Readonly::Scalar my $SOME_MOD        => 'Some::Undeclared';
Readonly::Scalar my $ANOTHER_MOD     => 'Some::Other';

Readonly::Hash my %MINIMAL_DISTRO => (
	'Makefile.PL'      => "use ExtUtils::MakeMaker;\n",
	'lib/My/Module.pm' => "package My::Module;\nuse strict;\nuse warnings;\nour \$VERSION = '1.00';\n1;\n",
	'Changes'          => "1.00 2026-06-30\n    - Initial release.\n",
	'MANIFEST'         => "MANIFEST\nMakefile.PL\nlib/My/Module.pm\n",
	'README'           => "My::Module -- a test module.\n",
);

# ── Module loading ─────────────────────────────────────────────────────────────

use_ok 'App::Project::Doctor';
use_ok 'App::Project::Doctor::Context';
use_ok 'App::Project::Doctor::Finding';
use_ok 'App::Project::Doctor::Report';
use_ok 'App::Project::Doctor::Fixer';

my $Doctor  = 'App::Project::Doctor';
my $Context = 'App::Project::Doctor::Context';
my $Finding = 'App::Project::Doctor::Finding';
my $Report  = 'App::Project::Doctor::Report';
my $Fixer   = 'App::Project::Doctor::Fixer';

# ── Shared helpers ────────────────────────────────────────────────────────────

# Build a temp directory tree from a %{ rel_path => content } hash.
sub _make_distro {
	my (%files) = @_;
	my $dir = tempdir(CLEANUP => 1);
	for my $rel (sort keys %files) {
		my @parts = split m{/}, $rel;
		my $abs   = File::Spec->catfile($dir, @parts);
		make_path(dirname($abs)) unless -d dirname($abs);
		open my $fh, '>', $abs or die "Cannot write $abs: $!";
		print $fh $files{$rel};
		close $fh;
	}
	return $dir;
}

# Create a Finding with the given named args.
sub _f {
	return $Finding->new(@_);
}

# Build a Report containing $n fixable error findings.
# Each fix coderef appends "fixN" to @{$applied_ref}.
sub _report_with_fixable {
	my ($applied_ref, $n) = @_;
	my $report = $Report->new;
	for my $i (1 .. $n) {
		my $idx = $i;
		$report->add_findings(_f(
			severity   => 'error',
			message    => "Fix me $idx",
			check_name => 'Test',
			fix        => sub { push @{$applied_ref}, "fix$idx" },
		));
	}
	return $report;
}

# Run Fixer interactively, supplying $input via a string-ref STDIN.
# Suppresses Fixer output unless $ENV{TEST_VERBOSE}.
sub _interactive_fixer {
	my ($input, $applied_ref) = @_;
	my $dir    = tempdir(CLEANUP => 1);
	my $ctx    = $Context->new(root => $dir);
	my $report = _report_with_fixable($applied_ref, 3);
	my $fixer  = $Fixer->new(report => $report, context => $ctx);

	my ($count, $out);
	{
		open(local *STDOUT, '>', \$out)  or die "Cannot redirect STDOUT: $!";
		open(local *STDIN,  '<', \$input) or die "Cannot redirect STDIN: $!";
		$count = $fixer->run;
	}
	diag "Fixer output:\n$out" if $ENV{TEST_VERBOSE} && $out;
	return $count;
}

# ─────────────────────────────────────────────────────────────────────────────
# 1. FINDING -> REPORT ACCUMULATION
# Strategy: Exercise the full Finding+Report pipeline by creating all four
# severity types and verifying that each filter method is independently correct.
# A passing report and a failing report are tested to ensure exit_code and the
# has_* predicates agree.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'finding-report accumulation across all severity types' => sub {
	my $fix_called = 0;
	my $report     = $Report->new;

	$report->add_findings(
		_f(severity => 'error',   message => 'E1',    check_name => 'A'),
		_f(severity => 'error',   message => 'E2',    check_name => 'A'),
		_f(severity => 'warning', message => 'W1',    check_name => 'B'),
		_f(severity => 'pass',    message => 'P1',    check_name => 'C'),
		_f(severity => 'info',    message => 'I1',    check_name => 'D'),
		_f(severity => 'error',   message => 'E_fix', check_name => 'E',
		   fix => sub { $fix_called++ }),
	);

	is( scalar($report->all_findings), 6, 'six findings accumulated' );
	is( scalar($report->errors),       3, 'three errors' );
	is( scalar($report->warnings),     1, 'one warning' );
	is( scalar($report->passes),       1, 'one pass' );
	is( scalar($report->fixable),      1, 'one fixable finding' );
	ok(  $report->has_errors,             'has_errors is true' );
	ok(  $report->has_warnings,           'has_warnings is true' );
	is(  $report->exit_code, 1,           'exit_code 1 when errors present' );

	diag 'findings: ' . join(', ', map { $_->message } $report->all_findings)
		if $ENV{TEST_VERBOSE};
};

subtest 'report exit_code is 0 and has_errors is false with only warnings' => sub {
	my $report = $Report->new;
	$report->add_findings(
		_f(severity => 'warning', message => 'W1', check_name => 'X'),
		_f(severity => 'pass',    message => 'P1', check_name => 'X'),
	);
	is(  $report->exit_code,  0, 'exit_code 0 when no errors present' );
	ok( !$report->has_errors,    'has_errors false when no errors' );
	ok(  $report->has_warnings,  'has_warnings true when warning present' );
};

subtest 'add_findings returns $self for method chaining' => sub {
	my $r1 = $Report->new;
	my $r2 = $r1->add_findings(_f(severity => 'info', message => 'X', check_name => 'T'));
	is( $r2, $r1, 'add_findings returns the same report object' );
};

subtest 'add_findings croaks on non-Finding arguments' => sub {
	my $report = $Report->new;
	throws_ok { $report->add_findings('plain string') }
		qr/Expected an App::Project::Doctor::Finding/,
		'croaks when passed a plain string';
	throws_ok { $report->add_findings(bless {}, 'SomeOtherClass') }
		qr/Expected an App::Project::Doctor::Finding/,
		'croaks when passed a wrong blessed object';
	is( scalar($report->all_findings), 0, 'no findings accumulated after failed adds' );
};

# ─────────────────────────────────────────────────────────────────────────────
# 2. REPORT RENDERING
# Strategy: Verify that each render method transforms accumulated state into
# the correct output format. render_text is tested both plain and verbose to
# confirm the detail field is hidden/shown correctly.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'render_text includes check_name, severity icon, and summary' => sub {
	my $report = $Report->new;
	$report->add_findings(
		_f(severity => 'pass',    message => 'Tests pass',    check_name => 'Tests'),
		_f(severity => 'error',   message => 'Missing strict', check_name => 'Security'),
		_f(severity => 'info',    message => 'MANIFEST info',  check_name => 'CPAN Readiness'),
	);

	my $text = $report->render_text;
	like( $text, qr/\[v\]/,    'pass icon [v] present' );
	like( $text, qr/\[X\]/,    'error icon [X] present' );
	like( $text, qr/\[i\]/,    'info icon [i] present' );
	like( $text, qr/Tests/,    'check_name Tests appears in output' );
	like( $text, qr/Security/, 'check_name Security appears in output' );
	like( $text, qr/1 error/,  'error count in summary line' );
	unlike( $text, qr/No errors or warnings/, 'no-error message absent when errors present' );

	diag $text if $ENV{TEST_VERBOSE};
};

subtest 'render_text verbose mode shows detail; non-verbose hides it' => sub {
	my $detail_text = 'Extended diagnostic detail here';
	my $report = $Report->new;
	$report->add_findings(_f(
		severity   => 'error',
		message    => 'Primary message',
		detail     => $detail_text,
		check_name => 'TestCheck',
	));

	my $plain   = $report->render_text(verbose => 0);
	my $verbose = $report->render_text(verbose => 1);

	unlike( $plain,   qr/\Q$detail_text\E/, 'detail hidden when verbose => 0' );
	like(   $verbose, qr/\Q$detail_text\E/, 'detail shown when verbose => 1' );
};

subtest 'render_tap produces a valid TAP stream' => sub {
	my $report = $Report->new;
	$report->add_findings(
		_f(severity => 'pass',  message => 'Tests ok',  check_name => 'Tests'),
		_f(severity => 'error', message => 'POD error', check_name => 'POD'),
	);

	my $tap = $report->render_tap;
	like( $tap, qr/^1\.\.2$/m,    'TAP plan line 1..2' );
	like( $tap, qr/^ok 1\b/m,     'first finding is ok' );
	like( $tap, qr/^not ok 2\b/m, 'second (error) finding is not ok' );
	like( $tap, qr/\[Tests\]/,    'check_name included in TAP line' );

	diag $tap if $ENV{TEST_VERBOSE};
};

subtest 'render_json returns parseable array with expected keys; fix excluded' => sub {
	my $report = $Report->new;
	$report->add_findings(_f(
		severity   => 'error',
		message    => 'A JSON finding',
		detail     => 'some detail',
		check_name => 'TestCheck',
		file       => 'lib/T.pm',
		line       => 42,
		fix        => sub { 1 },
	));

	require JSON::MaybeXS;
	my $json_str = $report->render_json;
	my $decoded  = JSON::MaybeXS->new->decode($json_str);

	ok( ref $decoded eq 'ARRAY',            'decoded JSON is an array' );
	is( scalar @{$decoded}, 1,              'one element in array' );
	is( $decoded->[0]{severity},   'error', 'severity key correct' );
	is( $decoded->[0]{message}, 'A JSON finding', 'message key correct' );
	is( $decoded->[0]{check_name}, 'TestCheck',   'check_name key correct' );
	is( $decoded->[0]{file},       'lib/T.pm',    'file key correct' );
	is( $decoded->[0]{line},       42,             'line key correct' );
	ok( !exists $decoded->[0]{fix},                'fix coderef excluded from JSON output' );

	diag $json_str if $ENV{TEST_VERBOSE};
};

# ─────────────────────────────────────────────────────────────────────────────
# 3. OPTIONAL DEPENDENCY: JSON::MaybeXS
# Strategy: mock_scoped replaces JSON::MaybeXS::new with a sub that throws,
# simulating the module being unavailable. This is more portable than
# Test::Without::Module + INC manipulation, which behaves differently across
# Perl versions (runtime eval of 'use' does not reliably install the @INC hook).
# ─────────────────────────────────────────────────────────────────────────────

subtest 'render_json throws when JSON::MaybeXS backend fails' => sub {
	require JSON::MaybeXS;

	my $report = $Report->new;
	$report->add_findings(_f(severity => 'info', message => 'x', check_name => 'T'));

	# Replace new() for the duration of this block; the guard restores it on exit.
	my $g = mock_scoped 'JSON::MaybeXS::new'
		=> sub { die "Simulated: JSON::MaybeXS unavailable\n" };

	throws_ok { $report->render_json }
		qr/JSON::MaybeXS unavailable/,
		'render_json propagates exception when JSON::MaybeXS backend fails';
};

# ─────────────────────────────────────────────────────────────────────────────
# 4. FIXER NON-INTERACTIVE
# Strategy: Verify that the Report->Fixer->apply_all workflow fires each fix
# coderef exactly once (in insertion order) and returns the correct count.
# A non-fixable finding is included to confirm it is not counted.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'fixer non_interactive applies all fixable findings and returns correct count' => sub {
	my $dir    = tempdir(CLEANUP => 1);
	my $ctx    = $Context->new(root => $dir);
	my @applied;
	my $report = _report_with_fixable(\@applied, 3);

	# Add a non-fixable finding to confirm it does not inflate the count.
	$report->add_findings(_f(severity => 'info', message => 'No fix', check_name => 'T'));

	my $fixer = $Fixer->new(report => $report, context => $ctx, non_interactive => 1);
	my ($count, $out);
	{
		open(local *STDOUT, '>', \$out) or die;
		$count = $fixer->run;
	}

	is( $count, 3,                          'three fixable findings applied' );
	is_deeply( \@applied, [qw(fix1 fix2 fix3)], 'fix coderefs called in insertion order' );

	diag "Fixer output:\n$out" if $ENV{TEST_VERBOSE};
};

subtest 'fixer returns 0 immediately when report has no fixable findings' => sub {
	my $dir    = tempdir(CLEANUP => 1);
	my $ctx    = $Context->new(root => $dir);
	my $report = $Report->new;
	$report->add_findings(_f(severity => 'pass', message => 'All clean', check_name => 'T'));

	my $fixer = $Fixer->new(report => $report, context => $ctx, non_interactive => 1);
	my ($count, $out);
	{
		open(local *STDOUT, '>', \$out) or die;
		$count = $fixer->run;
	}
	is( $count, 0, 'returns 0 when no fixable findings exist' );
};

# ─────────────────────────────────────────────────────────────────────────────
# 5. FIXER INTERACTIVE INPUT BRANCHES
# Strategy: Each subtest supplies a different STDIN string to exercise every
# conditional branch of _interactive_loop: "n", "y", blank, index, "1,3",
# and unrecognised input. The applied-fix counter proves which coderefs ran.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'fixer interactive "n" applies no fixes' => sub {
	my @applied;
	my $count = _interactive_fixer("n\n", \@applied);
	is( $count, 0,          '"n" -> 0 fixes applied' );
	is( scalar @applied, 0, '"n" -> no coderefs called' );
};

subtest 'fixer interactive "y" applies all fixes' => sub {
	my @applied;
	my $count = _interactive_fixer("y\n", \@applied);
	is( $count, 3,          '"y" -> all 3 fixes applied' );
	is( scalar @applied, 3, '"y" -> all coderefs called' );
};

subtest 'fixer interactive blank (Enter) applies all fixes' => sub {
	my @applied;
	my $count = _interactive_fixer("\n", \@applied);
	is( $count, 3, 'blank input -> all 3 fixes applied' );
};

subtest 'fixer interactive single index "1" applies only the first fix' => sub {
	my @applied;
	my $count = _interactive_fixer("1\n", \@applied);
	is( $count, 1,                  '"1" -> 1 fix applied' );
	is_deeply( \@applied, ['fix1'], '"1" -> only first coderef called' );
};

subtest 'fixer interactive "1,3" applies fix 1 and fix 3' => sub {
	my @applied;
	my $count = _interactive_fixer("1,3\n", \@applied);
	is( $count, 2,                          '"1,3" -> 2 fixes applied' );
	is_deeply( \@applied, [qw(fix1 fix3)],  '"1,3" -> first and third coderefs called' );
};

subtest 'fixer interactive unrecognised input applies no fixes' => sub {
	my @applied;
	my $count = _interactive_fixer("maybe\n", \@applied);
	is( $count, 0,          'unrecognised input -> 0 fixes' );
	is( scalar @applied, 0, 'unrecognised input -> no coderefs called' );
};

# ─────────────────────────────────────────────────────────────────────────────
# 6. FIXER WITH A FAILING FIX CODEREF
# Strategy: A fix coderef that throws must be skipped and carped, while
# subsequent fixes continue. Only successful fixes are reflected in the count.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'fixer skips a failing fix coderef and counts only successes' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $ctx = $Context->new(root => $dir);
	my @applied;

	my $report = $Report->new;
	$report->add_findings(
		_f(severity => 'error', message => 'Fix ok1', check_name => 'T',
		   fix => sub { push @applied, 'ok1' }),
		_f(severity => 'error', message => 'Fix boom', check_name => 'T',
		   fix => sub { die "Fix exploded\n" }),
		_f(severity => 'error', message => 'Fix ok2', check_name => 'T',
		   fix => sub { push @applied, 'ok2' }),
	);

	my $fixer = $Fixer->new(report => $report, context => $ctx, non_interactive => 1);

	# Test::Builder installs a $SIG{__WARN__} hook that intercepts warn (and
	# therefore carp) before it reaches STDERR, emitting it as a TAP diagnostic.
	# We localize the handler to capture the carp message for assertion without
	# letting it leak into the test output.
	my ($count, $out, @carped);
	{
		open(local *STDOUT, '>', \$out) or die;
		local $SIG{__WARN__} = sub { push @carped, $_[0] };
		$count = $fixer->run;
	}

	is( $count, 2,                       'only two successful fixes counted' );
	is_deeply( \@applied, [qw(ok1 ok2)], 'first and third fix coderefs called; failed one skipped' );
	like( join('', @carped), qr/Fix exploded/, 'failed fix error is reported via carp' );

	diag "Fixer output:\n$out\nCarped: @carped" if $ENV{TEST_VERBOSE};
};

# ─────────────────────────────────────────────────────────────────────────────
# 7. DOCTOR ROOT DETECTION
# Strategy: Point Doctor at a subdirectory that does NOT contain a root marker.
# Doctor must walk up and find the Makefile.PL in the parent. This tests the
# _detect_root traversal loop. Also test that the DR01 croak fires cleanly when
# there is genuinely no distribution root anywhere above the given path.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'doctor detects distro root by walking up from a nested subdirectory' => sub {
	my $dir = _make_distro(
		'Makefile.PL'      => "use ExtUtils::MakeMaker;\n",
		'lib/My/Module.pm' => "package My::Module;\nour \$VERSION = '$VALID_VERSION';\n1;\n",
		'Changes'          => "1.00 2026-06-30\n    - Initial.\n",
		'MANIFEST'         => "MANIFEST\n",
		'README'           => "My Module\n",
	);

	my $subdir = File::Spec->catdir($dir, 'lib', 'My');
	my $doctor = $Doctor->new(path => $subdir, checks => ['CpanReadiness']);
	my $report = $doctor->run;

	isa_ok( $report, $Report, 'run() returns a Report when root found via walk-up' );
	ok( defined $report, 'report is defined' );

	diag 'findings from subdir run: ' . join(', ', map { $_->message } $report->all_findings)
		if $ENV{TEST_VERBOSE};
};

subtest 'doctor->run croaks with DR01 message when no distribution root exists' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $doctor = $Doctor->new(path => $dir);
	throws_ok { $doctor->run }
		qr/Cannot detect a distribution root/,
		'croaks DR01 when no Makefile.PL / Build.PL / cpanfile found';
};

# ─────────────────────────────────────────────────────────────────────────────
# 8. DOCTOR FULL PIPELINE - CPANREADINESS CHECK
# Strategy: Run the full Doctor->run pipeline on a crafted temp distro with a
# single targeted check. Verify that the Report reflects the actual state of
# the distro files: valid version -> no errors; invalid version -> error.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'doctor full pipeline - minimal valid distro produces no CpanReadiness errors' => sub {
	my $dir = _make_distro(%MINIMAL_DISTRO);

	my $doctor = $Doctor->new(path => $dir, checks => ['CpanReadiness']);
	my $report = $doctor->run;

	is( $report->exit_code, 0, 'exit_code 0 for valid distro' );
	ok( !$report->has_errors,  'no errors for distro meeting all CpanReadiness requirements' );

	diag 'findings: ' . join('; ', map { $_->message } $report->all_findings)
		if $ENV{TEST_VERBOSE};
};

subtest 'doctor full pipeline - invalid version triggers a CpanReadiness error' => sub {
	my $dir = _make_distro(
		'Makefile.PL'      => "use ExtUtils::MakeMaker;\n",
		'lib/My/Module.pm' => "package My::Module;\nour \$VERSION = '$INVALID_VERSION';\n1;\n",
		'Changes'          => "1.00 2026-06-30\n    - Initial.\n",
		'MANIFEST'         => "MANIFEST\n",
		'README'           => "My Module\n",
	);

	my $doctor = $Doctor->new(path => $dir, checks => ['CpanReadiness']);
	my $report = $doctor->run;

	ok( $report->has_errors, 'error raised when version does not match CPAN format' );
	my ($ver_err) = grep { $_->message =~ /\Q$INVALID_VERSION\E/ } $report->errors;
	ok( $ver_err, "error finding mentions the invalid version string '$INVALID_VERSION'" );

	diag 'error: ' . ($ver_err ? $ver_err->message : 'none') if $ENV{TEST_VERBOSE};
};

# ─────────────────────────────────────────────────────────────────────────────
# 9. DOCTOR SKIP AND CHECKS PARAMETERS
# Strategy: The 'skip' list and the 'checks' list control which plugins run.
# Skipping CpanReadiness must produce zero CpanReadiness findings, even when
# the distro is missing required files. Restricting to 'checks => [Security]'
# must produce no findings from other check classes.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'doctor skip parameter prevents skipped check from adding findings' => sub {
	# Distro is deliberately missing Changes/MANIFEST/README so CpanReadiness
	# WOULD emit errors -- but we skip it.
	my $dir = _make_distro(
		'Makefile.PL'      => "use ExtUtils::MakeMaker;\n",
		'lib/My/Module.pm' => "package My::Module;\nuse strict;\nuse warnings;\nour \$VERSION = '$VALID_VERSION';\n1;\n",
	);

	my $doctor = $Doctor->new(
		path   => $dir,
		checks => [qw(Security CpanReadiness)],
		skip   => ['CpanReadiness'],
	);
	my $report = $doctor->run;

	my @cpan = grep { $_->check_name eq 'CPAN Readiness' } $report->all_findings;
	is( scalar @cpan, 0, 'zero CPAN Readiness findings when check is skipped' );
};

subtest 'doctor checks parameter restricts pipeline to named check only' => sub {
	my $dir = _make_distro(
		'Makefile.PL'      => "use ExtUtils::MakeMaker;\n",
		'lib/My/Module.pm' => "package My::Module;\nuse strict;\nuse warnings;\nour \$VERSION = '$VALID_VERSION';\n1;\n",
		'Changes'          => "1.00 2026-06-30\n    - Initial.\n",
		'MANIFEST'         => "MANIFEST\n",
		'README'           => "My Module\n",
	);

	my $doctor = $Doctor->new(path => $dir, checks => ['Security']);
	my $report = $doctor->run;

	my @non_security = grep { $_->check_name ne 'Security' } $report->all_findings;
	is( scalar @non_security, 0, 'no findings from other check classes when checks => [Security]' );
	ok( scalar($report->all_findings) > 0, 'at least one Security finding present' );
};

# ─────────────────────────────────────────────────────────────────────────────
# 10. SECURITY CHECK INTEGRATION
# Strategy: Run Check::Security directly on crafted distros to verify the
# strict/warnings detection produces a fixable error finding that correctly
# identifies the source file. A clean file must yield only a pass finding.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'security check detects missing "use strict" and produces fixable error' => sub {
	require App::Project::Doctor::Check::Security;

	my $dir = _make_distro(
		'lib/Broken.pm' => "package Broken;\nuse warnings;\n1;\n",
	);
	my $ctx   = $Context->new(root => $dir);
	my $check = App::Project::Doctor::Check::Security->new;

	my @findings = $check->check($ctx);
	my ($strict_err) = grep { $_->message =~ /use strict/i } @findings;

	ok(  $strict_err,                        'error finding produced for missing use strict' );
	is(  $strict_err->severity,   'error',   'severity is error' );
	ok(  $strict_err->is_fixable,            'finding carries an automated fix coderef' );
	like($strict_err->file,       qr/Broken\.pm/, 'file attribute identifies the broken file' );

	diag 'finding: ' . $strict_err->message if $ENV{TEST_VERBOSE} && $strict_err;
};

subtest 'security check emits a pass finding for a clean module' => sub {
	require App::Project::Doctor::Check::Security;

	my $dir = _make_distro(
		'lib/Clean.pm' => "package Clean;\nuse strict;\nuse warnings;\n1;\n",
	);
	my $ctx   = $Context->new(root => $dir);
	my $check = App::Project::Doctor::Check::Security->new;

	my @findings = $check->check($ctx);
	my ($pass) = grep { $_->severity eq 'pass' } @findings;

	ok( $pass, 'a pass finding emitted for a clean module' );
	is( scalar(grep { $_->severity eq 'error' } @findings), 0, 'no error findings' );
};

# ─────────────────────────────────────────────────────────────────────────────
# 11. DEPENDENCIES CHECK + FIX INTEGRATION
# Strategy: Exercise the multi-step Check::Dependencies workflow:
#   (a) detect an undeclared module -> error + fixable finding
#   (b) apply the fix               -> cpanfile updated on disk
#   (c) re-run check                -> pass finding
#   (d) App::makefilepl2cpanfile absent -> graceful warning, not a crash
# ─────────────────────────────────────────────────────────────────────────────

subtest 'dependencies check detects used module not in cpanfile' => sub {
	require App::Project::Doctor::Check::Dependencies;

	my $dir = _make_distro(
		'cpanfile'    => "# intentionally empty\n",
		'lib/My/M.pm' => "package My::M;\nuse strict;\nuse warnings;\nuse $SOME_MOD;\n1;\n",
	);
	my $ctx   = $Context->new(root => $dir);
	my $check = App::Project::Doctor::Check::Dependencies->new;

	my @findings = $check->check($ctx);
	my ($err) = grep { $_->message =~ /\Q$SOME_MOD\E/ } @findings;

	ok(  $err,                        'error finding for undeclared module' );
	is(  $err->severity, 'error',     'severity is error' );
	ok(  $err->is_fixable,            'finding carries a fix coderef' );
	like($err->detail, qr{lib/My/M\.pm}, 'detail names the source file containing the use' );

	diag 'finding: ' . $err->message if $ENV{TEST_VERBOSE} && $err;
};

subtest 'dependencies fix appends a "requires" line to cpanfile' => sub {
	require App::Project::Doctor::Check::Dependencies;

	my $dir = _make_distro(
		'cpanfile'    => "requires 'Carp';\n",
		'lib/My/M.pm' => "package My::M;\nuse strict;\nuse warnings;\nuse $ANOTHER_MOD;\n1;\n",
	);
	my $ctx   = $Context->new(root => $dir);
	my $check = App::Project::Doctor::Check::Dependencies->new;

	my @before = $check->check($ctx);
	my ($fix_finding) = grep { $_->message =~ /\Q$ANOTHER_MOD\E/ } @before;
	ok( $fix_finding, 'error finding for undeclared module before fix' );

	$fix_finding->fix->($ctx) if $fix_finding;

	my $content = $ctx->slurp('cpanfile');
	like( $content, qr/requires '$ANOTHER_MOD'/,
	      "cpanfile contains requires '$ANOTHER_MOD' after fix applied" );

	diag "cpanfile after fix:\n$content" if $ENV{TEST_VERBOSE};
};

subtest 'dependencies check passes when all used modules are declared' => sub {
	require App::Project::Doctor::Check::Dependencies;

	my $dir = _make_distro(
		'cpanfile'    => "requires '$SOME_MOD';\n",
		'lib/My/M.pm' => "package My::M;\nuse strict;\nuse warnings;\nuse $SOME_MOD;\n1;\n",
	);
	my $ctx   = $Context->new(root => $dir);
	my $check = App::Project::Doctor::Check::Dependencies->new;

	my @findings = $check->check($ctx);
	my ($pass) = grep { $_->severity eq 'pass' } @findings;

	ok( $pass, 'pass finding when all deps are declared' );
	is( scalar(grep { $_->severity eq 'error' } @findings), 0, 'no error findings' );
};

subtest 'dependencies check degrades gracefully when App::makefilepl2cpanfile fails' => sub {
	require App::Project::Doctor::Check::Dependencies;
	require App::makefilepl2cpanfile;

	# Only Makefile.PL present -- the module path requires App::makefilepl2cpanfile.
	my $dir = _make_distro(
		'Makefile.PL' => "use ExtUtils::MakeMaker;\n",
		'lib/My/M.pm' => "package My::M;\nuse strict;\nuse warnings;\n1;\n",
	);
	my $ctx   = $Context->new(root => $dir);
	my $check = App::Project::Doctor::Check::Dependencies->new;

	# Simulate generate() failing (equivalent to the module being uninstalled).
	# mock_scoped is portable across all Perl versions; Test::Without::Module +
	# local %INC manipulation is not reliable when 'use' is evaluated at runtime.
	my $g = mock_scoped 'App::makefilepl2cpanfile::generate'
		=> sub { die "Simulated: App::makefilepl2cpanfile unavailable\n" };

	my (@findings, @carped);
	{
		local $SIG{__WARN__} = sub { push @carped, $_[0] };
		@findings = eval { $check->check($ctx) };
	}
	ok( !$@,                               'check does not throw when generate() fails' );
	is( scalar @findings, 1,               'exactly one finding returned' );
	is( $findings[0]->severity, 'warning', 'finding is a warning, not an exception' );
	ok( scalar @carped,                    'carp was called to report the failure' );

	diag 'warning: ' . $findings[0]->message if $ENV{TEST_VERBOSE};
	diag 'carped: '  . $carped[0]            if $ENV{TEST_VERBOSE} && @carped;
};

# ─────────────────────────────────────────────────────────────────────────────
# 12. CONCURRENT OBJECT NON-INTERFERENCE
# Strategy: Create two independent instances of the same class within the same
# test block and verify they accumulate state in isolation -- no shared %INC
# side effects, no shared internal _findings arrays between Report instances,
# and no cross-contamination between Doctor runs on different distros.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'two concurrent Report instances accumulate state independently' => sub {
	my $report_a = $Report->new;
	my $report_b = $Report->new;

	$report_a->add_findings(_f(severity => 'error',   message => 'Err A',  check_name => 'A'));
	$report_b->add_findings(_f(severity => 'warning', message => 'Warn B', check_name => 'B'));

	is( scalar($report_a->all_findings), 1, 'report_a has exactly one finding' );
	is( scalar($report_b->all_findings), 1, 'report_b has exactly one finding' );
	is( scalar($report_a->errors),   1, 'report_a: one error' );
	is( scalar($report_b->errors),   0, 'report_b: no errors (its finding is a warning)' );
	is( scalar($report_b->warnings), 1, 'report_b: one warning' );
	is( $report_a->exit_code, 1, 'report_a exit_code is 1' );
	is( $report_b->exit_code, 0, 'report_b exit_code is 0' );

	diag sprintf('report_a exit=%d  report_b exit=%d', $report_a->exit_code, $report_b->exit_code)
		if $ENV{TEST_VERBOSE};
};

subtest 'two concurrent Doctor instances operate on separate distros without interference' => sub {
	# doc_bad points at a distro with an invalid version string -> errors.
	# doc_good points at a distro with a valid version string   -> no errors.
	my $dir_bad = _make_distro(
		'Makefile.PL'      => "use ExtUtils::MakeMaker;\n",
		'lib/M.pm'         => "package M;\nour \$VERSION = '$INVALID_VERSION';\n1;\n",
		'Changes'          => "1.00 2026-06-30\n    - Initial.\n",
		'MANIFEST'         => "MANIFEST\n",
		'README'           => "M\n",
	);
	my $dir_good = _make_distro(
		'Makefile.PL'      => "use ExtUtils::MakeMaker;\n",
		'lib/M.pm'         => "package M;\nour \$VERSION = '$VALID_VERSION';\n1;\n",
		'Changes'          => "1.00 2026-06-30\n    - Initial.\n",
		'MANIFEST'         => "MANIFEST\n",
		'README'           => "M\n",
	);

	my $doc_bad  = $Doctor->new(path => $dir_bad,  checks => ['CpanReadiness']);
	my $doc_good = $Doctor->new(path => $dir_good, checks => ['CpanReadiness']);

	my $report_bad  = $doc_bad->run;
	my $report_good = $doc_good->run;

	ok(  $report_bad->has_errors,  'invalid distro report has errors' );
	ok( !$report_good->has_errors, 'valid distro report has no errors' );
	is(  $report_bad->exit_code,  1, 'bad distro exit_code is 1' );
	is(  $report_good->exit_code, 0, 'good distro exit_code is 0' );

	diag sprintf("bad=%d good=%d", $report_bad->exit_code, $report_good->exit_code)
		if $ENV{TEST_VERBOSE};
};

# ─────────────────────────────────────────────────────────────────────────────
# 13. SPY: VERIFY EXTERNAL CALL ARGUMENTS
# Strategy: Use Test::Mockingbird::Spy on App::makefilepl2cpanfile::generate to
# confirm that Check::Dependencies passes the correct absolute Makefile.PL path
# to the external function. This verifies the integration contract between the
# check plugin and its external dependency.
# ─────────────────────────────────────────────────────────────────────────────

subtest 'dependencies check calls App::makefilepl2cpanfile::generate with abs Makefile.PL path' => sub {
	require App::makefilepl2cpanfile;
	require App::Project::Doctor::Check::Dependencies;

	my $dir = _make_distro(
		'Makefile.PL' => "use ExtUtils::MakeMaker; WriteMakefile(NAME => 'T');\n",
	);
	my $ctx = $Context->new(root => $dir);

	my $get_calls = spy 'App::makefilepl2cpanfile::generate';
	App::Project::Doctor::Check::Dependencies->new->check($ctx);
	my @calls = $get_calls->();

	ok( scalar @calls >= 1, 'App::makefilepl2cpanfile::generate was called at least once' );

	my $expected = $ctx->abs_path('Makefile.PL');
	# Spy format: [ method_name, @_ ] -- @_ for a plain function call includes all args.
	# generate(makefile => $path) means @_ = ('makefile', $path).
	my @call_args = @{ $calls[0] }[1 .. $#{ $calls[0] }];
	ok( (grep { defined && $_ eq $expected } @call_args),
	    "absolute path to Makefile.PL appears in generate call arguments" );

	diag 'generate call: ' . join(', ', @{ $calls[0] }) if $ENV{TEST_VERBOSE};

	restore_all();
};

done_testing;
