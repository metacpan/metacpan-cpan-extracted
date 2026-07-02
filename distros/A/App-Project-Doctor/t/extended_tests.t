package main;

use strict;
use warnings;

use lib 'lib';
use lib '/Users/njh/src/njh/Test-Returns/lib';

use Test::Most;
use Test::Mockingbird qw(mock_scoped restore_all);
use File::Temp qw(tempdir);
use File::Path qw(make_path);
use File::Spec;
use File::Basename qw(dirname);
use Scalar::Util qw(blessed);
use Readonly;

# ===========================================================================
# Constants
# ===========================================================================

Readonly::Scalar my $CONTEXT      => 'App::Project::Doctor::Context';
Readonly::Scalar my $FINDING      => 'App::Project::Doctor::Finding';
Readonly::Scalar my $REPORT       => 'App::Project::Doctor::Report';
Readonly::Scalar my $FIXER        => 'App::Project::Doctor::Fixer';
Readonly::Scalar my $DOCTOR       => 'App::Project::Doctor';
Readonly::Scalar my $GHACTIONS    => 'App::Project::Doctor::Check::GitHubActions';
Readonly::Scalar my $CHECK_POD    => 'App::Project::Doctor::Check::Pod';
Readonly::Scalar my $CHECK_SEC    => 'App::Project::Doctor::Check::Security';
Readonly::Scalar my $CHECK_CI     => 'App::Project::Doctor::Check::CI';
Readonly::Scalar my $CHECK_TESTS  => 'App::Project::Doctor::Check::Tests';

Readonly::Scalar my $SEV_ERROR    => 'error';
Readonly::Scalar my $SEV_WARN     => 'warning';
Readonly::Scalar my $SEV_PASS     => 'pass';
Readonly::Scalar my $SEV_INFO     => 'info';

Readonly::Scalar my $WORKFLOW_DIR => '.github/workflows';
Readonly::Scalar my $VALID_MSG    => 'Valid message for extended testing.';

# ===========================================================================
# Load modules under test
# ===========================================================================

use_ok $CONTEXT;
use_ok $FINDING;
use_ok $REPORT;
use_ok $FIXER;
use_ok $DOCTOR;
use_ok $GHACTIONS;
use_ok $CHECK_POD;
use_ok $CHECK_SEC;
use_ok $CHECK_CI;
use_ok $CHECK_TESTS;

# Check plugins inherit new() from Check::Base via 'use parent -norequire'.
# Base must be loaded explicitly because -norequire suppresses the automatic
# require that parent would normally issue.
require App::Project::Doctor::Check::Base;

# ===========================================================================
# Test helpers
# ===========================================================================

# Build a temporary distro directory from a hash of relative_path => content.
sub _distro {
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

sub _ctx {
	my $dir = shift // tempdir(CLEANUP => 1);
	return $CONTEXT->new(root => $dir);
}

sub _f {
	my (%args) = @_;
	return $FINDING->new(
		message    => $VALID_MSG,
		check_name => 'ExtTest',
		severity   => $SEV_INFO,
		%args,
	);
}

sub _report_with {
	my @findings = @_;
	my $r = $REPORT->new;
	$r->add_findings(@findings) if @findings;
	return $r;
}

# ===========================================================================
# Check::GitHubActions -- previously 56% stmt / 33% branch / 0% cond
#
# Strategy: drive every branch by mocking App::Workflow::Lint and App::GHGen
# so tests run without network or real workflow files.
# ===========================================================================

subtest 'GitHubActions::check -- no .github/workflows/ dir returns info' => sub {
	# When the workflow directory is entirely absent the check returns an info
	# finding; it does NOT emit an error because Check::CI owns that signal.
	my $dir = _distro('Makefile.PL' => '');
	my @f = $GHACTIONS->new->check($CONTEXT->new(root => $dir));
	is(  scalar @f,   1,          'single finding' );
	is(  $f[0]->severity, $SEV_INFO, 'severity is info' );
	like($f[0]->message, qr/No .github.workflows/i, 'mentions absent dir' );
	ok(  !$f[0]->is_fixable, 'no fix when dir is absent' );
};

subtest 'GitHubActions::check -- empty workflows dir returns warning+fix' => sub {
	# .github/workflows/ present but no YAML files: warning with a fix that
	# generates a default workflow via App::GHGen.
	my $dir = _distro(
		'Makefile.PL'               => '',
		"$WORKFLOW_DIR/.gitkeep"    => '',    # forces the dir without any YAML
	);
	my @f = $GHACTIONS->new->check($CONTEXT->new(root => $dir));
	is(  scalar @f, 1,           'single finding' );
	is(  $f[0]->severity, $SEV_WARN, 'severity is warning' );
	ok(  $f[0]->is_fixable, 'fix is offered' );
};

subtest 'GitHubActions::_fix_generate -- delegates to App::GHGen::Generator::generate_workflow' => sub {
	# Covers the _fix_generate sub and its inner anonymous coderef.
	# Bug found by tests: the original code called App::GHGen->new->generate which
	# does not exist; the source was fixed to call App::GHGen::Generator::generate_workflow.
	my $dir = _distro(
		'Makefile.PL'            => '',
		"$WORKFLOW_DIR/.gitkeep" => '',
	);
	my @f  = $GHACTIONS->new->check($CONTEXT->new(root => $dir));
	my $fix = $f[0]->fix;

	require App::GHGen::Generator;
	my $generated = 0;
	{
		my $g = mock_scoped 'App::GHGen::Generator::generate_workflow'
			=> sub { $generated++; return '' };    # return '' to skip file write
		$fix->(_ctx($dir));
	}
	restore_all();
	is( $generated, 1, '_fix_generate called generate_workflow exactly once' );
};

subtest 'GitHubActions::_lint_workflow -- hash error WITH line number' => sub {
	# Covers the 'ref $_ eq HASH' branch AND the 'defined $_->{line}' ternary
	# true-branch inside _lint_workflow.
	require App::Project::Doctor::Check::GitHubActions;
	my @errors;
	{
		my $g = mock_scoped 'App::Workflow::Lint::lint'
			=> sub { return ({message => 'unexpected key', line => 7}) };
		@errors = App::Project::Doctor::Check::GitHubActions::_lint_workflow('/fake/ci.yml');
	}
	restore_all();
	is(  scalar @errors, 1,                'one error returned' );
	is(  $errors[0]{message}, 'unexpected key', 'message from hash' );
	is(  $errors[0]{line},    7,               'line extracted from hash' );
	diag "error: $errors[0]{message} at line $errors[0]{line}" if $ENV{TEST_VERBOSE};
};

subtest 'GitHubActions::_lint_workflow -- hash error WITHOUT line key' => sub {
	# Covers the 'defined $_->{line}' ternary FALSE branch inside _lint_workflow.
	# Refactored: result hash does NOT include the 'line' key when line is absent.
	require App::Project::Doctor::Check::GitHubActions;
	my @errors;
	{
		my $g = mock_scoped 'App::Workflow::Lint::lint'
			=> sub { return ({message => 'schema mismatch'}) };    # no 'line' key
		@errors = App::Project::Doctor::Check::GitHubActions::_lint_workflow('/fake.yml');
	}
	restore_all();
	is(  $errors[0]{message}, 'schema mismatch', 'message from hash' );
	ok( !exists $errors[0]{line}, 'line key absent from result when not defined' );
};

subtest 'GitHubActions::_lint_workflow -- hash with undef message uses fallback string' => sub {
	# After refactor: '// "$_"' (hashref stringification) replaced with
	# '// "(unknown lint error)"' so the fallback is a human-readable string.
	require App::Project::Doctor::Check::GitHubActions;
	my @errors;
	{
		my $g = mock_scoped 'App::Workflow::Lint::lint'
			=> sub { return ({line => 5}) };    # message key is absent (undef)
		@errors = App::Project::Doctor::Check::GitHubActions::_lint_workflow('/fake.yml');
	}
	restore_all();
	is( $errors[0]{message}, '(unknown lint error)', 'undef message uses readable fallback' );
	is( $errors[0]{line},    5,                      'line still extracted from hash' );
};

subtest 'GitHubActions::_lint_workflow -- non-hash (string) error stringified' => sub {
	# Covers the 'ref $_ ne HASH' branch inside the map in _lint_workflow.
	require App::Project::Doctor::Check::GitHubActions;
	my @errors;
	{
		my $g = mock_scoped 'App::Workflow::Lint::lint'
			=> sub { return 'plain string error' };
		@errors = App::Project::Doctor::Check::GitHubActions::_lint_workflow('/fake.yml');
	}
	restore_all();
	is(  $errors[0]{message}, 'plain string error', 'string error becomes message' );
	ok( !defined $errors[0]{line}, 'no line for string error' );
};

subtest 'GitHubActions::check -- lint passes: single YAML -> pass finding' => sub {
	# Covers the "no errors collected -> pass" branch (lines 58-63).
	my $dir = _distro(
		'Makefile.PL'            => '',
		"$WORKFLOW_DIR/ci.yml"   => "on: push\njobs: {}\n",
	);
	my @f;
	{
		my $g = mock_scoped 'App::Project::Doctor::Check::GitHubActions::_lint_workflow'
			=> sub { return () };
		@f = $GHACTIONS->new->check($CONTEXT->new(root => $dir));
	}
	restore_all();
	is(  scalar @f, 1,           'single pass finding' );
	is(  $f[0]->severity, $SEV_PASS, 'severity is pass' );
	like($f[0]->message, qr/1 workflow file/i, 'message includes file count' );
};

subtest 'GitHubActions::check -- lint error WITH line: Finding carries line attr' => sub {
	# Covers the 'defined $err->{line}' ternary inside check() at line 53-54.
	my $dir = _distro(
		'Makefile.PL'            => '',
		"$WORKFLOW_DIR/bad.yml"  => "garbage:\n",
	);
	my @f;
	{
		my $g = mock_scoped 'App::Project::Doctor::Check::GitHubActions::_lint_workflow'
			=> sub { return ({message => 'bad syntax', line => 3}) };
		@f = $GHACTIONS->new->check($CONTEXT->new(root => $dir));
	}
	restore_all();
	is(  scalar @f, 1,              'one error finding' );
	is(  $f[0]->severity, $SEV_ERROR, 'severity is error' );
	is(  $f[0]->line, 3,            'Finding line attribute set from lint result' );
	like($f[0]->message, qr/bad syntax/, 'lint message propagated' );
	like($f[0]->file,    qr/bad\.yml/,   'file attribute set to workflow path' );
};

subtest 'GitHubActions::check -- lint error WITHOUT line: Finding has no line' => sub {
	# Covers the 'defined $err->{line}' FALSE branch inside check().
	my $dir = _distro(
		'Makefile.PL'            => '',
		"$WORKFLOW_DIR/bad.yml"  => "garbage:\n",
	);
	my @f;
	{
		my $g = mock_scoped 'App::Project::Doctor::Check::GitHubActions::_lint_workflow'
			=> sub { return ({message => 'schema error'}) };
		@f = $GHACTIONS->new->check($CONTEXT->new(root => $dir));
	}
	restore_all();
	ok( !defined $f[0]->line, 'Finding::line absent when lint error has no line' );
};

subtest 'GitHubActions::check -- two YAML files both pass: count reflected' => sub {
	my $dir = _distro(
		'Makefile.PL'                   => '',
		"$WORKFLOW_DIR/ci.yml"          => "on: push\n",
		"$WORKFLOW_DIR/release.yml"     => "on: release\n",
	);
	my @f;
	{
		my $g = mock_scoped 'App::Project::Doctor::Check::GitHubActions::_lint_workflow'
			=> sub { return () };
		@f = $GHACTIONS->new->check($CONTEXT->new(root => $dir));
	}
	restore_all();
	is(  scalar @f, 1,     'single pass finding' );
	like($f[0]->message, qr/2 workflow file/i, 'count is 2 in message' );
};

subtest 'GitHubActions::check -- lint errors suppress pass finding' => sub {
	# Errors present: the "unless (@findings)" guard is false; no pass emitted.
	my $dir = _distro(
		'Makefile.PL'          => '',
		"$WORKFLOW_DIR/a.yml"  => "x:\n",
		"$WORKFLOW_DIR/b.yml"  => "y:\n",
	);
	my @f;
	{
		my $g = mock_scoped 'App::Project::Doctor::Check::GitHubActions::_lint_workflow'
			=> sub { return ({message => 'error', line => 1}) };
		@f = $GHACTIONS->new->check($CONTEXT->new(root => $dir));
	}
	restore_all();
	is(  scalar @f, 2, 'one error per YAML file (two total)' );
	ok( !(grep { $_->severity eq $SEV_PASS } @f), 'no pass finding when errors present' );
};

# ===========================================================================
# Check::Pod -- previously 87% stmt / 50% branch / 40% cond
#
# Strategy: exercise _check_pod with genuinely malformed POD to cover the
# error-extraction loop, and mock slurp to cover the skip-on-read-failure path.
# ===========================================================================

subtest 'Pod::check -- no lib/ modules returns info' => sub {
	my @f = $CHECK_POD->new->check($CONTEXT->new(root => _distro('Makefile.PL' => '')));
	is( scalar @f, 1,          'single finding' );
	is( $f[0]->severity, $SEV_INFO, 'severity is info' );
	like($f[0]->message, qr/No \.pm files/i, 'message says no .pm files' );
};

subtest 'Pod::check -- valid POD returns pass' => sub {
	my $dir = _distro(
		'Makefile.PL' => '',
		'lib/Good.pm' => "package Good;\n1;\n__END__\n=head1 NAME\nGood - good\n=cut\n",
	);
	my @f = $CHECK_POD->new->check($CONTEXT->new(root => $dir));
	is( scalar @f, 1,           'single pass finding' );
	is( $f[0]->severity, $SEV_PASS, 'severity is pass' );
};

subtest 'Pod::check -- no POD produces fixable error; fix rewrites with skeleton' => sub {
	my $dir = _distro(
		'Makefile.PL' => '',
		'lib/Bare.pm' => "package Bare;\n1;\n",
	);
	my $ctx = $CONTEXT->new(root => $dir);
	my @f   = $CHECK_POD->new->check($ctx);

	my @errs = grep { $_->severity eq $SEV_ERROR } @f;
	is(  scalar @errs, 1, 'one error for missing POD' );
	like($errs[0]->message, qr/No POD found/i, 'message says No POD found' );
	ok(  $errs[0]->is_fixable, 'finding carries fix coderef' );

	# Apply the fix and verify POD skeleton was written (not just appended).
	my $out;
	open(local *STDOUT, '>', \$out) or die;
	$errs[0]->fix->($ctx);
	my $content = $ctx->slurp('lib/Bare.pm');
	like($content, qr/=head1 NAME/, 'fix wrote =head1 NAME' );
	like($content, qr/Bare/,        'fix included the package name' );

	# Regression: _fix_scaffold_pod previously used '>>' (append) which produced
	# a duplicate `1;` line.  Verify the file has exactly one `1;` at the top level.
	my @one_lines = $content =~ /^1;$/mg;
	is( scalar @one_lines, 1, 'exactly one "1;" line in fixed file (no duplication)' );
	diag "fixed content tail:\n" . substr($content, -200) if $ENV{TEST_VERBOSE};
};

subtest 'Pod::check -- nested package name resolved in fix skeleton' => sub {
	# Verifies _fix_scaffold_pod correctly converts lib/My/Module.pm -> My::Module
	my $dir = _distro(
		'Makefile.PL'      => '',
		'lib/My/Module.pm' => "package My::Module;\n1;\n",
	);
	my $ctx = $CONTEXT->new(root => $dir);
	my @f   = $CHECK_POD->new->check($ctx);
	my ($fixable) = grep { $_->is_fixable } @f;
	ok( $fixable, 'fixable finding for nested module' );
	my $out;
	open(local *STDOUT, '>', \$out) or die;
	$fixable->fix->($ctx);
	my $content = $ctx->slurp('lib/My/Module.pm');
	like($content, qr/My::Module/, 'fix skeleton uses :: package name' );
};

subtest 'Pod::check -- malformed POD triggers error findings with line numbers' => sub {
	# =over without =back before the next =head1 forces Pod::Checker to emit
	# an error.  This exercises _check_pod when num_errors > 0 (line 85),
	# the error-extraction loop (lines 88-96), and the 'defined $lineno ?'
	# ternary true-branch (line 51 in check()).
	my $broken_pod = join "\n",
		'package Broken;',
		'1;',
		'__END__',
		'',
		'=head1 NAME',
		'',
		'Broken - a module with broken POD',
		'',
		'=over 4',
		'',
		'=item * item one',
		'',
		'=head1 DESCRIPTION',    # =back missing before new =head1
		'',
		'Some text.',
		'',
		'=cut',
		'';
	my $dir = _distro('Makefile.PL' => '', 'lib/Broken.pm' => $broken_pod);
	my @f = $CHECK_POD->new->check($CONTEXT->new(root => $dir));
	my @errs = grep { $_->severity eq $SEV_ERROR } @f;
	ok( scalar @errs >= 1, 'at least one POD error finding' );
	like($errs[0]->message, qr/POD error in lib.Broken\.pm/i, 'message names the file' );
	diag "POD errors: " . join(', ', map { $_->message } @errs) if $ENV{TEST_VERBOSE};
};

subtest 'Pod::check -- slurp failure is skipped; other modules still checked' => sub {
	# Covers the '// do { carp "Cannot slurp ..."; next }' path in check()
	# (line 34).  The unreadable module is silently skipped; the readable
	# module still produces a finding.
	my $dir = _distro(
		'Makefile.PL'        => '',
		'lib/Good.pm'        => "package Good;\n1;\n__END__\n=head1 NAME\nGood\n=cut\n",
		'lib/Unreadable.pm'  => "package Unreadable;\n1;\n",
	);
	my $ctx = $CONTEXT->new(root => $dir);
	my @carped;
	my @f;
	{
		# Intercept slurp and fail only for Unreadable.pm.
		my $g = mock_scoped 'App::Project::Doctor::Context::slurp' => sub {
			my ($self, $rel) = @_;
			die "mocked read failure\n" if $rel =~ /Unreadable/;
			open my $fh, '<:encoding(UTF-8)', $self->abs_path($rel) or die $!;
			local $/;
			my $c = <$fh>;
			close $fh;
			return $c;
		};
		local $SIG{__WARN__} = sub { push @carped, shift };
		@f = $CHECK_POD->new->check($ctx);
	}
	restore_all();
	ok(  scalar @carped > 0, 'slurp failure produced a carp' );
	like($carped[0], qr/Cannot slurp/i, 'carp mentions Cannot slurp' );
	ok(  scalar @f > 0, 'check produced findings for remaining readable module' );
};

# ===========================================================================
# Check::Security -- uncovered execution paths
#
# Two gaps remain: the '.t file' branch that skips pragma checks, and the
# _fix_pragma shebang-preservation branch.
# ===========================================================================

subtest 'Security::check -- .t file in script/ skips use-strict/warnings check' => sub {
	# perl_files('lib','script','bin') picks up .t extensions.  Files whose
	# path matches /\.t$/ must NOT be checked for missing strict/warnings
	# (line 36 false branch -- when $rel =~ /\.t$/).
	my $dir = _distro(
		'Makefile.PL'       => '',
		'script/runner.t'   => "use Test::More;\nok(1);\ndone_testing;\n",
	);
	my @f          = $CHECK_SEC->new->check($CONTEXT->new(root => $dir));
	my @strict_errs = grep { $_->severity eq $SEV_ERROR && $_->message =~ /use strict/i } @f;
	is( scalar @strict_errs, 0,
		'.t file lacks use strict but is not flagged -- pragma check skipped' );
	diag 'findings: ' . join(', ', map { $_->message } @f) if $ENV{TEST_VERBOSE};
};

subtest 'Security::check -- slurp failure in credential scan is skipped' => sub {
	# The '// do { carp "Cannot slurp $rel"; next }' path at line 33.
	my $dir = _distro(
		'Makefile.PL'   => '',
		'lib/Good.pm'   => "package Good;\nuse strict;\nuse warnings;\n1;\n",
		'lib/Bad.pm'    => "package Bad;\nuse strict;\nuse warnings;\n1;\n",
	);
	my $ctx = $CONTEXT->new(root => $dir);
	my @carped;
	{
		my $g = mock_scoped 'App::Project::Doctor::Context::slurp' => sub {
			my ($self, $rel) = @_;
			die "io error\n" if $rel =~ /Bad/;
			open my $fh, '<:encoding(UTF-8)', $self->abs_path($rel) or die $!;
			local $/; my $c = <$fh>; close $fh; return $c;
		};
		local $SIG{__WARN__} = sub { push @carped, shift };
		$CHECK_SEC->new->check($ctx);
	}
	restore_all();
	ok(  scalar @carped > 0, 'slurp failure produced a carp' );
	like($carped[0], qr/Cannot slurp/i, 'carp message identifies the failed slurp' );
};

subtest 'Security::_fix_pragma -- shebang line preserved as line 1 after fix' => sub {
	# Covers the '@lines && $lines[0] =~ /^#!/' true branch in _fix_pragma
	# (line 102 condition), which sets $insert_at = 1 to skip the shebang.
	my $dir = _distro(
		'Makefile.PL'   => '',
		'script/run.pl' => "#!/usr/bin/perl\nmy \$x = 1;\n",
	);
	my $ctx = $CONTEXT->new(root => $dir);
	my @f   = $CHECK_SEC->new->check($ctx);
	my @strict_errs = grep { $_->severity eq $SEV_ERROR && $_->message =~ /use strict/i } @f;
	is( scalar @strict_errs, 1, 'script missing use strict triggers finding' );
	ok( $strict_errs[0]->is_fixable, 'finding carries fix' );

	my $out;
	open(local *STDOUT, '>', \$out) or die;
	$strict_errs[0]->fix->($ctx);

	my $fixed = $ctx->slurp('script/run.pl');
	my ($first_line) = $fixed =~ /\A([^\n]+)/;
	like($first_line, qr/^#!/,         'shebang is still the first line after fix' );
	like($fixed,      qr/use strict/,  'use strict was inserted by fix' );
	ok(
		index($fixed, '#!/') < index($fixed, 'use strict'),
		'shebang appears before use strict in the fixed file',
	);
	diag "fixed content:\n$fixed" if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# Report::render_text -- previously 92.8% branch / 90% cond
#
# Two branch gaps remain: (1) verbose mode encountering a 'pass' finding
# inside a mixed group (triggering 'next'), and (2) verbose mode with a
# non-pass finding whose detail is '' (falsey -- skipping the detail line).
# ===========================================================================

subtest 'Report::render_text -- verbose mode skips pass findings within a group' => sub {
	# Line 117: 'next if $f->severity eq "pass"' -- true branch.
	# A check_name group containing BOTH an error and a pass finding exercises
	# this; the pass finding must be silently skipped in verbose output.
	my $r = $REPORT->new;
	$r->add_findings(
		$FINDING->new(severity => $SEV_ERROR, message => 'Something broke.',
		              check_name => 'Mixed', detail => 'Run with --verbose'),
		$FINDING->new(severity => $SEV_PASS,  message => 'Partial pass.',
		              check_name => 'Mixed'),
	);
	my $text = $r->render_text(verbose => 1);
	like(  $text, qr/Something broke\./, 'error message appears in verbose output' );
	unlike($text, qr/Partial pass\./,    'pass finding body is NOT printed verbosely' );
};

subtest 'Report::render_text -- verbose mode skips empty detail (falsey)' => sub {
	# Line 119: 'if $f->detail' -- false branch.
	# Finding::new defaults detail to '' (empty string); empty string is falsey
	# so the detail line must not be printed.
	my $r = $REPORT->new;
	$r->add_findings(
		$FINDING->new(severity => $SEV_ERROR, message => 'No detail here.',
		              check_name => 'NoDetail'),
		# detail is not set -- defaults to ''
	);
	my $text = $r->render_text(verbose => 1);
	like($text, qr/No detail here\./, 'message present' );
	# The detail indent pattern is 11 leading spaces (the '           ' format)
	unlike($text, qr/^ {11}/m, 'no detail-indent line when detail is empty' );
};

subtest 'Report::render_text -- verbose mode prints non-empty detail' => sub {
	# Line 119: 'if $f->detail' -- true branch (confirm positive case).
	my $r = $REPORT->new;
	$r->add_findings(
		$FINDING->new(severity => $SEV_ERROR, message => 'Check logs.',
		              check_name => 'WithDetail', detail => 'See /var/log/app.log'),
	);
	my $text = $r->render_text(verbose => 1);
	like($text, qr|/var/log/app\.log|, 'detail line printed in verbose mode' );
};

subtest 'Report::render_text -- summary with errors only (no warnings)' => sub {
	# The 'join( " - ", ($ec ? ... : ()), ($wc ? ... : ()))' expression when
	# only errors exist: the warnings list is (), so join produces "N error(s)".
	my $r = $REPORT->new;
	$r->add_findings(_f(severity => $SEV_ERROR, check_name => 'E', message => 'Error.'));
	my $text = $r->render_text;
	like(  $text, qr/1 error\(s\)/,   'error count in summary' );
	unlike($text, qr/warning/,        'no warnings mention' );
};

subtest 'Report::render_text -- summary with warnings only (no errors)' => sub {
	# When only warnings exist: the errors list is (), join produces "N warning(s)".
	my $r = $REPORT->new;
	$r->add_findings(_f(severity => $SEV_WARN, check_name => 'W', message => 'Warn.'));
	my $text = $r->render_text;
	like(  $text, qr/1 warning\(s\)/, 'warning count in summary' );
	unlike($text, qr/\d+ error/,      'no error mention' );
};

subtest 'Report::render_text -- summary with both errors and warnings' => sub {
	my $r = $REPORT->new;
	$r->add_findings(_f(severity => $SEV_ERROR, check_name => 'E', message => 'Err.'));
	$r->add_findings(_f(severity => $SEV_WARN,  check_name => 'W', message => 'Warn.'));
	my $text = $r->render_text;
	like($text, qr/1 error\(s\)/,   'error count present' );
	like($text, qr/1 warning\(s\)/, 'warning count present' );
	like($text, qr/ - /,            'joined with hyphen' );
};

# ===========================================================================
# Check::CI -- alternate detection targets and fix coderef (previously 6% uncovered)
#
# The CI check tests already cover GitHub Actions detection; here we exercise
# the other CI systems and confirm the fix coderef delegates to App::GHGen.
# ===========================================================================

subtest 'CI::check -- Travis CI (.travis.yml) detected as pass' => sub {
	my $dir = _distro('Makefile.PL' => '', '.travis.yml' => "language: perl\n");
	my @f = $CHECK_CI->new->check($CONTEXT->new(root => $dir));
	is(  $f[0]->severity, $SEV_PASS, 'Travis CI config detected' );
	like($f[0]->message, qr/Travis CI/, 'message names Travis' );
};

subtest 'CI::check -- CircleCI config detected as pass' => sub {
	my $dir = _distro('Makefile.PL' => '', '.circleci/config.yml' => "version: 2\n");
	my @f = $CHECK_CI->new->check($CONTEXT->new(root => $dir));
	is(  $f[0]->severity, $SEV_PASS, 'CircleCI config detected' );
	like($f[0]->message, qr/CircleCI/, 'message names CircleCI' );
};

subtest 'CI::check -- AppVeyor config detected as pass' => sub {
	my $dir = _distro('Makefile.PL' => '', 'appveyor.yml' => "environment:\n");
	my @f = $CHECK_CI->new->check($CONTEXT->new(root => $dir));
	is(  $f[0]->severity, $SEV_PASS, 'AppVeyor config detected' );
	like($f[0]->message, qr/AppVeyor/, 'message names AppVeyor' );
};

subtest 'CI::check -- fix coderef delegates to App::GHGen::Generator::generate_workflow' => sub {
	# Covers the anonymous sub in Check/CI.pm.
	# Bug found by tests: original code called App::GHGen->new->generate (non-existent OO API).
	# Source was fixed to call App::GHGen::Generator::generate_workflow('perl').
	my $dir = _distro('Makefile.PL' => '');
	my $ctx = $CONTEXT->new(root => $dir);
	my @f   = $CHECK_CI->new->check($ctx);
	is( $f[0]->severity, $SEV_ERROR, 'no CI config: error' );
	ok( $f[0]->is_fixable, 'fix is offered' );

	require App::GHGen::Generator;
	my $generated = 0;
	{
		my $g = mock_scoped 'App::GHGen::Generator::generate_workflow'
			=> sub { $generated++; return '' };    # return '' to skip file write
		$f[0]->fix->($ctx);
	}
	restore_all();
	is( $generated, 1, 'CI fix called App::GHGen::Generator::generate_workflow once' );
};

# ===========================================================================
# Check::Tests -- fix coderef previously uncovered
# ===========================================================================

subtest 'Tests::check -- fix for missing t/ creates smoke test scaffold' => sub {
	# Covers _fix_scaffold and its inner anonymous coderef.
	# Bug found by tests: original code called App::Test::Generator->new->generate
	# which does not exist.  Source fixed to write a minimal t/00-smoke.t directly.
	my $dir = _distro('Makefile.PL' => '');
	my $ctx = $CONTEXT->new(root => $dir);
	my @f   = $CHECK_TESTS->new->check($ctx);

	my ($fixable) = grep { $_->is_fixable } @f;
	ok( $fixable, 'missing t/ produces a fixable finding' );

	$fixable->fix->($ctx);

	my $t_dir  = File::Spec->catdir($dir, 't');
	my $smoke  = File::Spec->catfile($t_dir, '00-smoke.t');
	ok( -d $t_dir,   'fix created t/ directory' );
	ok( -f $smoke,   'fix created t/00-smoke.t' );
	my $content = do { open my $fh, '<', $smoke; local $/; <$fh> };
	like($content, qr/use strict/,    'smoke test has use strict' );
	like($content, qr/done_testing/,  'smoke test has done_testing' );
};

# ===========================================================================
# Doctor -- uncovered branches
#
# Two genuine gaps: (1) require failing for a valid-looking but uninstalled
# check name, and (2) verbose mode printing "Running: <name> ..." to STDOUT.
# A third gap -- check() method throwing -- was previously untested but is
# now covered by the updated test 61 in edge_cases.t; it is retested here for
# completeness and cross-file coverage consistency.
# ===========================================================================

subtest 'Doctor::new -- invalid arg type dies via validate_strict' => sub {
	# Doctor::new passes args through Params::Get::get_params then validate_strict.
	# Passing an arrayref for the scalar 'path' parameter must throw.
	throws_ok { $DOCTOR->new(path => []) }
		qr/path/i,
		'Doctor::new throws when path is not a scalar';
};

subtest 'Doctor::run -- unloadable check name is skipped with carp' => sub {
	# Covers 'if ($@)' at line 242 (true branch): a check name that passes
	# the /\A[A-Za-z][A-Za-z0-9]*\z/ regex but whose module does not exist.
	my $dir = _distro('Makefile.PL' => '');
	my $doctor = $DOCTOR->new(path => $dir, checks => ['ZZZNotInstalled']);
	my @carped;
	my $out;
	{
		open(local *STDOUT, '>', \$out) or die;
		local $SIG{__WARN__} = sub { push @carped, shift };
		$doctor->run;
	}
	ok(  scalar @carped > 0, 'unloadable check produced a carp' );
	like($carped[0], qr/Could not load/i, 'carp says "Could not load"' );
};

subtest 'Doctor::run -- verbose=1 prints "Running: <name>" to STDOUT' => sub {
	# Covers 'printf ... if $self->verbose' (line 178 true branch).
	my $dir = _distro('Makefile.PL' => '');
	my $doctor = $DOCTOR->new(path => $dir, checks => ['Security'], verbose => 1);
	my $out = '';
	{
		my $g = mock_scoped 'App::Project::Doctor::Check::Security::check'
			=> sub { return () };
		open(local *STDOUT, '>', \$out) or die;
		$doctor->run;
	}
	restore_all();
	like($out, qr/Running.*Security/i, 'verbose output contains "Running: Security"' );
};

subtest 'Doctor::run -- check() that throws is carped and does not abort run' => sub {
	# Covers 'if ($@)' at line 184 (true branch): eval { check->check($ctx) }
	# throws; run() carps the error, adds no findings, and returns the report.
	my $dir = _distro('Makefile.PL' => '');
	my $doctor = $DOCTOR->new(path => $dir, checks => ['Security']);
	my (@carped, $report);
	{
		my $g = mock_scoped 'App::Project::Doctor::Check::Security::check'
			=> sub { die "deliberate check failure\n" };
		my $out;
		open(local *STDOUT, '>', \$out) or die;
		local $SIG{__WARN__} = sub { push @carped, shift };
		$report = $doctor->run;
	}
	restore_all();
	ok(  defined $report,            'run returns a Report even after a throwing check' );
	is(  scalar $report->all_findings, 0, 'no findings added for the throwing check' );
	ok(  scalar @carped > 0,         'a carp was emitted' );
	like($carped[0], qr/threw/i,     'carp mentions that the check threw' );
};

# ===========================================================================
# Dead code resolution log
# ===========================================================================
#
# The following previously unreachable paths have been RESOLVED in the critique
# refactor.  They are listed here for audit purposes.
#
# 1. Finding::icon -- '// "[?]"' fallback  [RESOLVED -- removed]
#    Finding::new validates severity against %VALID_SEVERITY.  All four valid
#    severities are keys in %SEVERITY_ICON.  The '[?]' fallback was removed.
#
# 2. Finding::new -- second 'croak message must be a non-empty string' [RESOLVED -- removed]
#    The first guard (before validate_strict) already catches empty messages.
#    The second croak after validate_strict was removed as redundant.
#
# 3. Report::render_text -- '$ICON{$sev} // "[?]"' [RESOLVED -- removed]
#    _worst_severity only returns validated severities; all are keys in %ICON.
#    The '// "[?]"' fallback was removed.
#
# 4. Fixer::new -- '!blessed($args->{report/context})' guards [RESOLVED -- simplified]
#    Params::Validate::Strict type => 'object' ensures blessed before the isa
#    guards run.  The redundant blessed() checks were removed; isa() checks kept.
#
# 5. Doctor::new / Context::new / Fixer::new -- 'or croak $@' [RESOLVED -- removed]
#    Params::Validate::Strict throws (dies) on failure rather than returning
#    undef.  The 'or croak $@' branches were removed from all three constructors.

done_testing;
