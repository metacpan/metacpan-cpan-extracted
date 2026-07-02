#!/usr/bin/perl
# t/edge_cases.t
#
# Hostile, pathological, boundary-condition, and security tests.
# Strategy: actively try to break or subvert each module.
#
use strict;
use warnings;

use Test::Most;
use Test::Returns;
use Test::Mockingbird qw(mock_scoped restore_all);
use Readonly;
use File::Temp    qw(tempdir);
use File::Spec;
use File::Path    qw(make_path);
use File::Basename qw(dirname);
use Scalar::Util  qw(blessed);

our $INJECT_SENTINEL;

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

Readonly::Scalar my $EMPTY      => '';
Readonly::Scalar my $WHITESPACE => "   \t\n  ";
Readonly::Scalar my $HUGE       => 'A' x 1_000_000;
Readonly::Scalar my $VALID_MSG  => 'A valid finding message';

Readonly::Scalar my $Finding => 'App::Project::Doctor::Finding';
Readonly::Scalar my $Context => 'App::Project::Doctor::Context';
Readonly::Scalar my $Report  => 'App::Project::Doctor::Report';
Readonly::Scalar my $Fixer   => 'App::Project::Doctor::Fixer';
Readonly::Scalar my $Doctor  => 'App::Project::Doctor';

Readonly::Scalar my $SEV_ERROR   => 'error';
Readonly::Scalar my $SEV_WARNING => 'warning';
Readonly::Scalar my $SEV_PASS    => 'pass';
Readonly::Scalar my $SEV_INFO    => 'info';

# ---------------------------------------------------------------------------
# Module bootstrap
# ---------------------------------------------------------------------------

use_ok $Finding;
use_ok $Context;
use_ok $Report;
use_ok $Fixer;
use_ok $Doctor;
require App::Project::Doctor::Check::Security;
require App::Project::Doctor::Check::Dependencies;

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Build a minimal temp distro from a { relative/path => content } hash.
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

# Return a Context rooted at a fresh temp dir (or supplied dir).
sub _ctx {
	my $dir = shift // tempdir(CLEANUP => 1);
	return $Context->new(root => $dir);
}

# Minimal valid Finding with optional overrides.
sub _f {
	my (%args) = @_;
	return $Finding->new(
		message    => $VALID_MSG,
		check_name => 'EdgeTest',
		severity   => $SEV_ERROR,
		%args,
	);
}

# Empty Report with N added findings.
sub _report_with {
	my (@f) = @_;
	my $r = $Report->new;
	$r->add_findings(@f) if @f;
	return $r;
}

# Run the Fixer in interactive mode, feeding $input as STDIN.
# Captures STDOUT into $$out_ref and $SIG{__WARN__} into @$warn_ref.
sub _run_fixer_interactive {
	my ($report, $input, $out_ref, $warn_ref) = @_;
	my $ctx   = _ctx();
	my $fixer = $Fixer->new(report => $report, context => $ctx);
	my $count;
	{
		open(local *STDOUT, '>', $out_ref) or die;
		open(local *STDIN,  '<', \$input) or die;
		local $SIG{__WARN__} = sub { push @{$warn_ref}, $_[0] };
		$count = $fixer->run;
	}
	return $count;
}

# ===========================================================================
# Finding -- hostile constructor inputs
# ===========================================================================

subtest 'Finding::new -- undef message croaks immediately (pre-PVS guard)' => sub {
	# The early guard fires before Params::Validate::Strict sees the args;
	# the documented error message must be exact.
	throws_ok { $Finding->new(message => undef, check_name => 'T') }
		qr/message must be a non-empty string/,
		'undef message produces documented croak';
};

subtest 'Finding::new -- empty-string message croaks' => sub {
	throws_ok { $Finding->new(message => $EMPTY, check_name => 'T') }
		qr/message must be a non-empty string/,
		'empty string message rejected';
};

subtest 'Finding::new -- string "0" is a valid message (non-empty)' => sub {
	# length("0") == 1; the guard must not confuse falsy-in-boolean with empty.
	my $f;
	lives_ok { $f = $Finding->new(message => '0', check_name => 'T') }
		'"0" passes the non-empty guard';
	is( $f->message, '0', 'message stored verbatim' );
};

subtest 'Finding::new -- whitespace-only message is accepted' => sub {
	# The spec says non-empty (length > 0), not non-whitespace.
	lives_ok { $Finding->new(message => $WHITESPACE, check_name => 'T') }
		'whitespace-only message accepted';
};

subtest 'Finding::new -- million-character message does not crash' => sub {
	my $f;
	lives_ok { $f = $Finding->new(message => $HUGE, check_name => 'T') }
		'huge message accepted';
	is( length($f->message), 1_000_000, 'full length preserved' );
};

subtest 'Finding::new -- invalid severity croaks with documented message' => sub {
	throws_ok { $Finding->new(message => $VALID_MSG, severity => 'critical') }
		qr/Invalid severity 'critical'/,
		'unknown severity rejected with documented error';
	throws_ok { $Finding->new(message => $VALID_MSG, severity => $EMPTY) }
		qr/Invalid severity/,
		'empty severity rejected';
};

subtest 'Finding::new -- line => 0 croaks (minimum is 1)' => sub {
	throws_ok { $Finding->new(message => $VALID_MSG, line => 0) }
		qr//,
		'line => 0 rejected by schema (min 1)';
};

subtest 'Finding::new -- line => -1 croaks (minimum is 1)' => sub {
	throws_ok { $Finding->new(message => $VALID_MSG, line => -1) }
		qr//,
		'negative line number rejected';
};

subtest 'Finding::new -- unknown constructor key rejected by strict schema' => sub {
	throws_ok { $Finding->new(message => $VALID_MSG, frob => 1) }
		qr//,
		'undocumented key "frob" rejected by Params::Validate::Strict';
};

subtest 'Finding::new -- arrayref as message rejected by PVS type check' => sub {
	# A ref is defined, and may pass length(); PVS type=>'scalar' must reject it.
	throws_ok { $Finding->new(message => [], check_name => 'T') }
		qr//,
		'arrayref rejected as message';
};

subtest 'Finding::new -- hashref as fix (not a coderef) rejected' => sub {
	throws_ok { $Finding->new(message => $VALID_MSG, fix => {}) }
		qr//,
		'hashref for fix rejected (type must be coderef)';
};

subtest 'Finding::new -- string as fix (not a coderef) rejected' => sub {
	throws_ok { $Finding->new(message => $VALID_MSG, fix => 'not_a_sub') }
		qr//,
		'plain string for fix rejected';
};

subtest 'Finding::is_fixable -- returns exact integers 1 and 0, not truthy refs' => sub {
	my $unfixable = _f();
	my $fixable   = _f(fix => sub { 1 });

	is( $unfixable->is_fixable, 0, 'unfixable returns 0'   );
	is( $fixable->is_fixable,   1, 'fixable returns 1'     );
	ok( !ref($unfixable->is_fixable), 'is_fixable is a plain scalar, not ref' );
	ok(  defined $unfixable->is_fixable, 'is_fixable never returns undef' );
};

subtest 'Finding::to_hash -- fix coderef excluded from serialisation' => sub {
	my $called = 0;
	my $f = _f(fix => sub { $called++ });
	my $h = $f->to_hash;
	ok( !exists $h->{fix}, 'fix key absent from to_hash' );
	is( $called, 0, 'fix coderef not invoked during to_hash' );
};

subtest 'Finding::to_hash -- line key absent when not set' => sub {
	my $h = _f()->to_hash;
	ok( !exists $h->{line}, 'line key absent when not set in constructor' );
};

subtest 'Finding::to_hash -- line key present and correct when set' => sub {
	my $h = _f(line => 99)->to_hash;
	is( $h->{line}, 99, 'line key present with correct value' );
};

subtest 'Finding::icon -- returns bracketed string for all four valid severities' => sub {
	Readonly::Hash my %EXPECT => (
		$SEV_ERROR   => '[X]',
		$SEV_WARNING => '[!]',
		$SEV_PASS    => '[v]',
		$SEV_INFO    => '[i]',
	);
	for my $sev (keys %EXPECT) {
		my $f = _f(severity => $sev);
		is( $f->icon, $EXPECT{$sev}, "icon for $sev is $EXPECT{$sev}" );
	}
};

# ===========================================================================
# Context -- hostile inputs and path traversal
# ===========================================================================

subtest 'Context::new -- non-existent root croaks' => sub {
	throws_ok { $Context->new(root => '/no/such/path/xyz987abc') }
		qr/is not a directory/,
		'non-existent root rejected';
};

subtest 'Context::new -- plain file path as root croaks' => sub {
	# A file exists but is not a directory.
	my $tmp = File::Temp->new(UNLINK => 1);
	throws_ok { $Context->new(root => $tmp->filename) }
		qr/is not a directory/,
		'file path rejected as root';
};

subtest 'Context::has_file -- undef rel_path croaks' => sub {
	throws_ok { _ctx()->has_file(undef) }
		qr/requires a relative path/,
		'has_file(undef) croaks with documented error';
};

subtest 'Context::abs_path -- undef rel_path croaks' => sub {
	throws_ok { _ctx()->abs_path(undef) }
		qr/requires a relative path/,
		'abs_path(undef) croaks';
};

subtest 'Context::slurp -- undef rel_path croaks' => sub {
	throws_ok { _ctx()->slurp(undef) }
		qr/requires a relative path/,
		'slurp(undef) croaks';
};

subtest 'Context::slurp -- missing file croaks with documented error' => sub {
	throws_ok { _ctx()->slurp('no_such_file.pm') }
		qr/File not found/,
		'slurp of absent file croaks "File not found"';
};

# abs_path must reject paths with ".." components to prevent
# reading/checking files outside the distribution root.
subtest 'Context -- path traversal via abs_path is blocked' => sub {
	my $ctx = _ctx();
	throws_ok { $ctx->abs_path('../outside.txt') }
		qr/path traversal/i,
		'abs_path with leading ".." rejected';
	throws_ok { $ctx->abs_path('lib/../../outside.txt') }
		qr/path traversal/i,
		'abs_path with embedded ".." rejected';
};

subtest 'Context -- path traversal via has_file is blocked' => sub {
	my $ctx = _ctx();
	throws_ok { $ctx->has_file('../sibling') }
		qr/path traversal/i,
		'has_file with ".." component rejected';
};

subtest 'Context -- path traversal via slurp is blocked' => sub {
	my $ctx = _ctx();
	throws_ok { $ctx->slurp('../secret.txt') }
		qr/path traversal/i,
		'slurp with ".." component rejected';
};

subtest 'Context::perl_files -- non-existent dirs skipped silently' => sub {
	# An empty root with no lib/ or t/ must return an empty arrayref, not die.
	my $dir = tempdir(CLEANUP => 1);
	my $ctx = $Context->new(root => $dir);
	my $result;
	lives_ok { $result = $ctx->perl_files('lib', 't', 'nonexistent') }
		'missing dirs do not cause perl_files to die';
	returns_ok( $result, { type => 'arrayref' }, 'still returns arrayref' );
	is( scalar @{$result}, 0, 'empty arrayref for missing dirs' );
};

subtest 'Context::perl_files -- does not clobber outer $_' => sub {
	# File::Find localises $_ internally; we verify the outer value survives.
	my $ctx = _ctx(_distro('lib/A.pm' => '1;'));
	local $_ = 'sentinel_value';
	$ctx->perl_files;
	is( $_, 'sentinel_value', '$_ unchanged by perl_files' );
};

subtest 'Context::find_files -- undef dir argument croaks' => sub {
	throws_ok { _ctx()->find_files(undef) }
		qr/requires a directory/,
		'find_files(undef) croaks';
};

# ===========================================================================
# Report -- hostile add_findings inputs and empty-state rendering
# ===========================================================================

subtest 'Report::add_findings -- undef finding croaks' => sub {
	throws_ok { $Report->new->add_findings(undef) }
		qr/Expected an App::Project::Doctor::Finding/,
		'undef rejected by add_findings';
};

subtest 'Report::add_findings -- plain string croaks' => sub {
	throws_ok { $Report->new->add_findings('not a finding') }
		qr/Expected an App::Project::Doctor::Finding/,
		'string rejected by add_findings';
};

subtest 'Report::add_findings -- wrong blessed class croaks' => sub {
	# A blessed hashref that is not an ::Finding must be rejected.
	my $impostor = bless { severity => $SEV_ERROR, message => 'fake' }, 'FakeClass';
	throws_ok { $Report->new->add_findings($impostor) }
		qr/Expected an App::Project::Doctor::Finding/,
		'wrong-class object rejected';
};

subtest 'Report::add_findings -- no-arg call is a harmless no-op' => sub {
	my $r = $Report->new;
	lives_ok { $r->add_findings() } 'no-arg add_findings does not die';
	is( scalar($r->all_findings), 0, 'report stays empty' );
};

subtest 'Report::render_text -- empty report produces "No errors or warnings"' => sub {
	my $out;
	lives_ok { $out = $Report->new->render_text } 'render_text on empty report lives';
	like( $out, qr/No errors or warnings/i, 'empty report text is correct' );
};

subtest 'Report::render_tap -- empty report produces "1..0" plan' => sub {
	like( $Report->new->render_tap, qr/^1\.\.0/, '1..0 plan for empty report' );
};

subtest 'Report::has_errors / has_warnings -- return exact 0 and 1' => sub {
	my $r = $Report->new;
	is( $r->has_errors,   0, 'empty report: has_errors == 0' );
	is( $r->has_warnings, 0, 'empty report: has_warnings == 0' );

	$r->add_findings(_f(severity => $SEV_ERROR));
	is( $r->has_errors,   1, 'has_errors == 1 after adding an error'   );
	is( $r->has_warnings, 0, 'has_warnings == 0 with only an error'    );

	$r->add_findings(_f(severity => $SEV_WARNING));
	is( $r->has_warnings, 1, 'has_warnings == 1 after adding a warning' );
};

subtest 'Report -- error accumulation and exit_code' => sub {
	my $r = $Report->new;
	$r->add_findings(_f(severity => $SEV_ERROR))   for 1 .. 4;
	$r->add_findings(_f(severity => $SEV_WARNING)) for 1 .. 2;
	is( scalar($r->errors),   4, '4 errors accumulated'           );
	is( scalar($r->warnings), 2, '2 warnings accumulated'         );
	is( $r->exit_code, 1,        'exit_code is 1 when errors exist' );
};

subtest 'Report -- exit_code is 0 when only warnings present' => sub {
	my $r = $Report->new;
	$r->add_findings(_f(severity => $SEV_WARNING));
	is( $r->exit_code, 0, 'exit_code is 0 for warnings-only report' );
};

# ===========================================================================
# Fixer -- hostile constructor, STDIN attack surface, index boundary
# ===========================================================================

subtest 'Fixer::new -- missing report argument croaks' => sub {
	throws_ok { $Fixer->new(context => _ctx()) }
		qr//,
		'new without report croaks';
};

subtest 'Fixer::new -- missing context argument croaks' => sub {
	throws_ok { $Fixer->new(report => $Report->new) }
		qr//,
		'new without context croaks';
};

subtest 'Fixer::new -- wrong object types rejected' => sub {
	# report/context must be proper blessed objects of the right class.
	throws_ok { $Fixer->new(report => {}, context => {}) }
		qr//,
		'plain hashrefs rejected for report and context';
};

subtest 'Fixer::new -- wrong Report subclass rejected' => sub {
	my $not_report = bless {}, 'NotAReport';
	throws_ok { $Fixer->new(report => $not_report, context => _ctx()) }
		qr/report must be an App::Project::Doctor::Report/,
		'wrong report class rejected with documented message';
};

subtest 'Fixer::new -- wrong Context subclass rejected' => sub {
	my $r          = $Report->new;
	my $not_context = bless {}, 'NotAContext';
	throws_ok { $Fixer->new(report => $r, context => $not_context) }
		qr/context must be an App::Project::Doctor::Context/,
		'wrong context class rejected with documented message';
};

subtest 'Fixer::run -- zero fixable findings returns 0 without touching STDIN' => sub {
	# A report with only pass findings must short-circuit immediately.
	my $r = _report_with(_f(severity => $SEV_PASS));
	my $fixer = $Fixer->new(report => $r, context => _ctx(), non_interactive => 1);
	my $out;
	open(local *STDOUT, '>', \$out) or die;
	is( $fixer->run, 0, 'run returns 0 for unfixable report' );
};

subtest 'Fixer -- STDIN immediately closed (undef) returns 0' => sub {
	# <STDIN> returning undef simulates a closed pipe; must not crash.
	my $r   = _report_with(_f(fix => sub { 1 }));
	my $out = $EMPTY;
	my @w;
	my $count = _run_fixer_interactive($r, $EMPTY, \$out, \@w);
	is( $count, 0, 'returns 0 when STDIN is immediately closed' );
};

subtest 'Fixer -- STDIN input "n" applies no fixes' => sub {
	my $applied = 0;
	my $r       = _report_with(_f(fix => sub { $applied++ }));
	my $out     = $EMPTY;
	my @w;
	my $count = _run_fixer_interactive($r, "n\n", \$out, \@w);
	is( $count,   0, '"n" applies zero fixes'           );
	is( $applied, 0, 'fix coderef was not called'        );
	like( $out, qr/No fixes applied/i, 'STDOUT confirms no fixes' );
};

subtest 'Fixer -- STDIN injection attempt treated as unrecognised input' => sub {
	# Hostile STDIN: code-like string must not be executed.
	# The ^[\d,\s]+$ guard must reject anything with non-digit non-comma chars.
	my $applied = 0;
	my $r       = _report_with(_f(fix => sub { $applied++ }));
	my $out     = $EMPTY;
	my @w;
	my $count = _run_fixer_interactive($r, "1; system('true')\n", \$out, \@w);
	is( $count,   0, 'injection-like input applies 0 fixes' );
	is( $applied, 0, 'fix coderef not invoked'              );
	like( $out, qr/Unrecognised input/i, 'user informed of unrecognised input' );
};

subtest 'Fixer -- STDIN index 0 is filtered (indices are 1-based)' => sub {
	my $applied = 0;
	my $r       = _report_with(_f(fix => sub { $applied++ }));
	my $out     = $EMPTY;
	my @w;
	_run_fixer_interactive($r, "0\n", \$out, \@w);
	is( $applied, 0, 'index 0 not applied (must be >= 1)' );
};

subtest 'Fixer -- STDIN out-of-range index applies no fixes' => sub {
	my $applied = 0;
	my $r       = _report_with(_f(fix => sub { $applied++ }));
	my $out     = $EMPTY;
	my @w;
	my $count = _run_fixer_interactive($r, "99999\n", \$out, \@w);
	is( $count,   0, 'out-of-range index applies 0 fixes' );
	is( $applied, 0, 'fix coderef not called for index > max' );
};

subtest 'Fixer -- duplicate indices apply each fix exactly once' => sub {
	# Before the fix: "1,1,1" would call fix #1 three times.
	# After the fix: indices are deduplicated; fix #1 is called once.
	my $call_count = 0;
	my $r          = _report_with(_f(fix => sub { $call_count++ }));
	my $out        = $EMPTY;
	my @w;
	my $count = _run_fixer_interactive($r, "1,1,1\n", \$out, \@w);
	is( $call_count, 1, 'duplicate "1,1,1" applies fix exactly once (deduped)' );
	is( $count,      1, 'run returns 1 successful fix'                          );
};

subtest 'Fixer -- all-whitespace STDIN input applies no fixes' => sub {
	# "   " matches ^[\d,\s]+$ but splits to an empty list of indices.
	my $applied = 0;
	my $r       = _report_with(_f(fix => sub { $applied++ }));
	my $out     = $EMPTY;
	my @w;
	my $count = _run_fixer_interactive($r, "   \n", \$out, \@w);
	is( $applied, 0, 'whitespace-only index list applies no fixes' );
};

subtest 'Fixer -- non_interactive mode applies all fixes without STDIN' => sub {
	my @applied;
	my $r = $Report->new;
	for my $i (1 .. 3) {
		$r->add_findings(_f(fix => sub { push @applied, $i }));
	}
	my $fixer = $Fixer->new(report => $r, context => _ctx(), non_interactive => 1);
	my $out;
	open(local *STDOUT, '>', \$out) or die;
	my $count = $fixer->run;
	is( $count, 3, 'non_interactive mode applies all 3 fixes' );
	is( scalar @applied, 3, 'all 3 fix coderefs were called' );
};

# ===========================================================================
# Doctor -- code injection via check name and root detection
# ===========================================================================

subtest 'Doctor::run -- no root marker found croaks' => sub {
	# A directory without Makefile.PL / Build.PL / dist.ini / cpanfile.
	my $dir = tempdir(CLEANUP => 1);
	throws_ok { $Doctor->new(path => $dir)->run }
		qr/Cannot detect a distribution root/,
		'run croaks when no root marker is present';
};

subtest 'Doctor -- check name injection blocked before eval' => sub {
	# Before the fix: eval "require App::Project::Doctor::Check::Tests;
	# ++$main::INJECT_SENTINEL; 1" would execute the increment.
	# After the fix: names not matching /\A[A-Za-z][A-Za-z0-9]*\z/ are
	# rejected with a carp and skipped before the eval runs.
	local $INJECT_SENTINEL = 0;

	my $dir = _distro('Makefile.PL' => '');
	my $doctor = $Doctor->new(
		path   => $dir,
		checks => ['Tests; ++$main::INJECT_SENTINEL; 1'],
	);
	my ($out, @carped);
	{
		open(local *STDOUT, '>', \$out) or die;
		local $SIG{__WARN__} = sub { push @carped, $_[0] };
		eval { $doctor->run };
	}

	is( $INJECT_SENTINEL, 0, 'injected code was not executed' );
	ok( scalar @carped, 'invalid check name produces a carp warning' );
	like( join($EMPTY, @carped), qr/invalid|character/i,
		'warning message mentions invalid characters' );
	diag "carp: @carped" if $ENV{TEST_VERBOSE};
};

subtest 'Doctor -- check name with path separators is sanitised' => sub {
	# "../../etc/passwd" must be rejected before reaching eval.
	local $INJECT_SENTINEL = 0;

	my $dir = _distro('Makefile.PL' => '');
	my $doctor = $Doctor->new(
		path   => $dir,
		checks => ['../../etc/passwd'],
	);
	my ($out, @carped);
	{
		open(local *STDOUT, '>', \$out) or die;
		local $SIG{__WARN__} = sub { push @carped, $_[0] };
		eval { $doctor->run };
	}
	ok( 1, 'path-separator check name did not crash Doctor' );
	ok( scalar @carped, 'path-separator check name produces a carp' );
};

subtest 'Doctor::run -- preserves caller $@ across a failing check' => sub {
	# Doctor::run wraps check invocations in eval{}; caller $@ must survive.
	my $dir = _distro('Makefile.PL' => '');
	$@ = 'caller_sentinel';

	my $doctor = $Doctor->new(path => $dir, checks => ['Tests']);
	my ($out, @carped);
	{
		open(local *STDOUT, '>', \$out) or die;
		local $SIG{__WARN__} = sub { push @carped, $_[0] };
		my $g = mock_scoped 'App::Project::Doctor::Check::Tests::check'
			=> sub { die "deliberate failure\n" };
		$doctor->run;    # run catches the die internally; does not itself die
	}
	restore_all();

	is( $@, 'caller_sentinel', 'Doctor::run does not clobber caller $@' );
};

subtest 'Doctor -- two concurrent instances have independent state' => sub {
	my $d1 = $Doctor->new(path => '.', checks => ['Tests']);
	my $d2 = $Doctor->new(path => '.', checks => ['CI', 'Meta']);

	is( $d1->path, $d2->path, 'same path (sanity check)' );
	isnt( $d1->checks, $d2->checks, 'checks arrayrefs are separate objects' );
	is( scalar @{ $d1->checks }, 1, 'd1 has 1 check' );
	is( scalar @{ $d2->checks }, 2, 'd2 has 2 checks' );
};

subtest 'Doctor -- skip list excludes named checks' => sub {
	# When a check name is in skip, its class must not be instantiated.
	my $dir    = _distro('Makefile.PL' => '');
	my $doctor = $Doctor->new(
		path   => $dir,
		checks => [qw(Tests CI)],
		skip   => ['Tests'],
	);
	my ($out, @carped);
	my $report;
	{
		open(local *STDOUT, '>', \$out) or die;
		local $SIG{__WARN__} = sub { push @carped, $_[0] };
		$report = eval { $doctor->run };
	}
	my @test_findings = grep { $_->check_name eq 'Tests' } $report->all_findings;
	is( scalar @test_findings, 0, 'Tests check was excluded by skip list' );
};

# ===========================================================================
# Check::Security -- credential pattern boundary conditions
# ===========================================================================

subtest 'Check::Security -- 3-char credential value does not trigger (min 4)' => sub {
	# Pattern [^'"]{4,} requires at least 4 chars between the quotes.
	my $dir = _distro(
		'Makefile.PL' => '',
		'lib/Short.pm' =>
			"package Short;\nuse strict;\nuse warnings;\nmy \$password = 'abc';\n1;\n",
	);
	my @f     = App::Project::Doctor::Check::Security->new->check($Context->new(root => $dir));
	my @creds = grep { $_->severity eq 'error' && $_->message =~ /credential/i } @f;
	is( scalar @creds, 0, '3-char password not flagged (below 4-char threshold)' );
};

subtest 'Check::Security -- 4-char credential value triggers finding' => sub {
	my $dir = _distro(
		'Makefile.PL' => '',
		'lib/Long.pm' =>
			"package Long;\nuse strict;\nuse warnings;\nmy \$password = 'abcd';\n1;\n",
	);
	my @f     = App::Project::Doctor::Check::Security->new->check($Context->new(root => $dir));
	my @creds = grep { $_->severity eq 'error' && $_->message =~ /credential/i } @f;
	is( scalar @creds, 1, '4-char password value triggers credential finding' );
};

subtest 'Check::Security -- env-var reference is not a hardcoded credential' => sub {
	# my $token = $ENV{TOKEN}: no literal string value, must not be flagged.
	my $dir = _distro(
		'Makefile.PL' => '',
		'lib/Safe.pm' =>
			"package Safe;\nuse strict;\nuse warnings;\nmy \$token = \$ENV{TOKEN};\n1;\n",
	);
	my @f     = App::Project::Doctor::Check::Security->new->check($Context->new(root => $dir));
	my @creds = grep { $_->severity eq 'error' && $_->message =~ /credential/i } @f;
	is( scalar @creds, 0, 'env-var token reference is not flagged' );
};

subtest 'Check::Security -- AWS AKIA key prefix triggers credential finding' => sub {
	my $dir = _distro(
		'Makefile.PL' => '',
		'lib/Aws.pm'  =>
			"package Aws;\nuse strict;\nuse warnings;\nmy \$k = 'AKIAIOSFODNN7EXAMPLE';\n1;\n",
	);
	my @f     = App::Project::Doctor::Check::Security->new->check($Context->new(root => $dir));
	my @creds = grep { $_->severity eq 'error' && $_->message =~ /credential/i } @f;
	is( scalar @creds, 1, 'AWS AKIA key triggers credential finding' );
};

subtest 'Check::Security -- PEM private key header triggers credential finding' => sub {
	my $dir = _distro(
		'Makefile.PL' => '',
		'lib/Key.pm'  =>
			"package Key;\nuse strict;\nuse warnings;\n# -----BEGIN RSA PRIVATE KEY-----\n1;\n",
	);
	my @f     = App::Project::Doctor::Check::Security->new->check($Context->new(root => $dir));
	my @creds = grep { $_->severity eq 'error' && $_->message =~ /credential/i } @f;
	is( scalar @creds, 1, 'PEM private key header triggers credential finding' );
};

subtest 'Check::Security -- EC private key header triggers credential finding' => sub {
	my $dir = _distro(
		'Makefile.PL' => '',
		'lib/EC.pm'   =>
			"package EC;\nuse strict;\nuse warnings;\n# -----BEGIN EC PRIVATE KEY-----\n1;\n",
	);
	my @f     = App::Project::Doctor::Check::Security->new->check($Context->new(root => $dir));
	my @creds = grep { $_->severity eq 'error' && $_->message =~ /credential/i } @f;
	is( scalar @creds, 1, 'EC private key header triggers credential finding' );
};

subtest 'Check::Security -- api_key variant triggers credential finding' => sub {
	my $dir = _distro(
		'Makefile.PL' => '',
		'lib/Api.pm'  =>
			"package Api;\nuse strict;\nuse warnings;\nmy \$api_key = 'secretkey1234';\n1;\n",
	);
	my @f     = App::Project::Doctor::Check::Security->new->check($Context->new(root => $dir));
	my @creds = grep { $_->severity eq 'error' && $_->message =~ /credential/i } @f;
	is( scalar @creds, 1, 'api_key pattern triggers credential finding' );
};

subtest 'Check::Security -- does not clobber outer $_' => sub {
	# The check iterates over files and splits content; $_ must not leak out.
	my $dir = _distro(
		'Makefile.PL' => '',
		'lib/A.pm'    => "package A;\nuse strict;\nuse warnings;\n1;\n",
	);
	my $ctx = $Context->new(root => $dir);
	local $_ = 'outer_sentinel';
	App::Project::Doctor::Check::Security->new->check($ctx);
	is( $_, 'outer_sentinel', '$_ unchanged after Check::Security::check' );
};

# ===========================================================================
# Global state -- $_ and $@ must not leak out of any public method
# ===========================================================================

subtest 'Global state -- $@ not clobbered by Report::render_text' => sub {
	$@ = 'preserved_by_render_text';
	_report_with(_f())->render_text;
	is( $@, 'preserved_by_render_text', 'render_text does not touch $@' );
};

subtest 'Global state -- $@ not clobbered by Finding::new (success path)' => sub {
	$@ = 'preserved_by_finding_new';
	_f();
	is( $@, 'preserved_by_finding_new', 'Finding::new does not clear $@' );
};

subtest 'Global state -- $@ not clobbered by Context::perl_files' => sub {
	my $ctx = $Context->new(root => _distro('lib/A.pm' => '1;'));
	$@ = 'preserved_by_perl_files';
	$ctx->perl_files;
	is( $@, 'preserved_by_perl_files', 'perl_files does not touch $@' );
};

subtest 'Global state -- $@ not clobbered by Context::slurp (success path)' => sub {
	my $dir = _distro('lib/A.pm' => "1;\n");
	my $ctx = $Context->new(root => $dir);
	$@ = 'preserved_by_slurp';
	$ctx->slurp('lib/A.pm');
	is( $@, 'preserved_by_slurp', 'slurp does not touch $@' );
};

done_testing;
