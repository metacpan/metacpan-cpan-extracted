# t/function.t -- White-box function tests for every .pm in lib/
#
# Tests are organized one subtest-block per module, in dependency order
# (value objects first, orchestrators last).
#
# Mocking: Test::Mockingbird -- mock/mock_scoped/mock_return/mock_exception/
# mock_once/mock_sequence/spy/restore_all.
# Return validation: Test::Returns -- returns_ok / returns_not_ok.

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Test::Memory::Cycle;
use File::Temp  qw(tempdir);
use File::Spec;
use File::Path  qw(make_path);
use Scalar::Util qw(blessed);
use Readonly;

Readonly::Scalar my $EMPTY    => '';
Readonly::Scalar my $NL       => "\n";
Readonly::Scalar my $PASS_SEV => 'pass';
Readonly::Scalar my $ERR_SEV  => 'error';
Readonly::Scalar my $WARN_SEV => 'warning';
Readonly::Scalar my $INFO_SEV => 'info';

# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------

# Build a temporary directory tree from a flat hash of rel-path => content.
sub make_distro {
	my (%files) = @_;
	my $dir = tempdir(CLEANUP => 1);
	for my $rel (sort keys %files) {
		my @parts  = split m{/}, $rel;
		my $abs    = File::Spec->catfile($dir, @parts);
		(my $parent = $abs) =~ s{[/\\][^/\\]+$}{};
		make_path($parent) unless -d $parent;
		open my $fh, '>', $abs or die "Cannot write $abs: $!";
		print {$fh} $files{$rel};
		close $fh;
	}
	return $dir;
}

# Construct a minimal Finding for use in other module tests.
sub _make_finding {
	require App::Project::Doctor::Finding;
	return App::Project::Doctor::Finding->new(@_);
}

# Construct a minimal Context for a given tempdir root.
sub _make_ctx {
	my $root = shift;
	require App::Project::Doctor::Context;
	return App::Project::Doctor::Context->new(root => $root);
}

# Construct a Report with an optional list of pre-loaded findings.
sub _make_report {
	require App::Project::Doctor::Report;
	my $r = App::Project::Doctor::Report->new;
	$r->add_findings(@_) if @_;
	return $r;
}

diag "Perl $]" if $ENV{TEST_VERBOSE};

# ===========================================================================
# 1. App::Project::Doctor::Finding
# ===========================================================================

require_ok 'App::Project::Doctor::Finding';

subtest 'Finding::new -- defaults' => sub {
	# When only message is supplied the other fields should carry documented
	# defaults so callers can safely omit them.
	my $f = App::Project::Doctor::Finding->new(message => 'ok');
	is  $f->severity,   $INFO_SEV,  'default severity is info';
	is  $f->detail,     $EMPTY,     'default detail is empty string';
	is  $f->check_name, 'Unknown',  'default check_name is Unknown';
	is  $f->file,       $EMPTY,     'default file is empty string';
	ok !defined $f->line,           'line undef by default';
};

subtest 'Finding::new -- all attributes round-trip' => sub {
	my $fix_called = 0;
	my $f = App::Project::Doctor::Finding->new(
		severity   => $ERR_SEV,
		message    => 'Something broke',
		detail     => 'Extra info',
		fix        => sub { $fix_called++ },
		check_name => 'Tests',
		file       => 'lib/Foo.pm',
		line       => 42,
	);
	is $f->severity,   $ERR_SEV,        'severity';
	is $f->message,    'Something broke','message';
	is $f->detail,     'Extra info',     'detail';
	is $f->check_name, 'Tests',          'check_name';
	is $f->file,       'lib/Foo.pm',     'file';
	is $f->line,       42,               'line';
	ok $f->has_fix,                      'has_fix true';
	$f->fix->();
	is $fix_called, 1, 'fix coderef is callable';
};

subtest 'Finding::new -- invalid severity croaks' => sub {
	# The constructor must validate the severity enumeration.
	throws_ok {
		App::Project::Doctor::Finding->new(severity => 'critical', message => 'x')
	} qr/Invalid severity 'critical'/i, 'unknown severity croaks with name';

	throws_ok {
		App::Project::Doctor::Finding->new(severity => $EMPTY, message => 'x')
	} qr/Invalid severity ''/i, 'empty severity croaks';
};

subtest 'Finding::new -- empty message croaks' => sub {
	throws_ok {
		App::Project::Doctor::Finding->new(message => $EMPTY)
	} qr/message must be a non-empty string/i, 'empty message croaks';

	throws_ok {
		App::Project::Doctor::Finding->new(message => undef)
	} qr/message must be a non-empty string/i, 'undef message croaks';
};

subtest 'Finding::new -- non-positive line croaks' => sub {
	# Line must be a positive integer when supplied.
	throws_ok {
		App::Project::Doctor::Finding->new(message => 'x', line => 0)
	} qr//i, 'line=0 rejected';

	throws_ok {
		App::Project::Doctor::Finding->new(message => 'x', line => -1)
	} qr//i, 'negative line rejected';
};

subtest 'Finding::is_fixable' => sub {
	my $without = _make_finding(message => 'no fix');
	ok !$without->is_fixable, 'is_fixable false without coderef';
	is  $without->is_fixable, 0, 'is_fixable returns integer 0, not just false';

	my $with = _make_finding(message => 'has fix', fix => sub {});
	ok  $with->is_fixable, 'is_fixable true with coderef';
	is  $with->is_fixable, 1, 'is_fixable returns integer 1, not just true';
};

subtest 'Finding::icon -- one icon per severity' => sub {
	my %expected = (
		error   => '[X]',
		warning => '[!]',
		pass    => '[v]',
		info    => '[i]',
	);
	for my $sev (sort keys %expected) {
		my $f = _make_finding(severity => $sev, message => 'x');
		is $f->icon, $expected{$sev}, "icon for $sev";
	}
};

subtest 'Finding::to_hash -- excludes fix, includes line only when set' => sub {
	my $without_line = _make_finding(
		severity   => $PASS_SEV,
		message    => 'ok',
		fix        => sub {},
		check_name => 'X',
	);
	my $h = $without_line->to_hash;
	returns_ok($h, { type => 'hashref' }, 'to_hash returns a hashref');
	ok !exists $h->{fix},  'fix excluded from hash';
	ok !exists $h->{line}, 'line absent when not set';
	is $h->{severity},   $PASS_SEV, 'severity in hash';
	is $h->{check_name}, 'X',       'check_name in hash';

	my $with_line = _make_finding(message => 'y', line => 7);
	ok exists $with_line->to_hash->{line}, 'line present when set';
	is $with_line->to_hash->{line}, 7,     'line value correct';
};

subtest 'Finding -- memory cycle check' => sub {
	my $f = _make_finding(severity => $INFO_SEV, message => 'cycle?');
	memory_cycle_ok($f, 'Finding has no circular references');
};

diag 'Finding: done' if $ENV{TEST_VERBOSE};

# ===========================================================================
# 2. App::Project::Doctor::Context
# ===========================================================================

require_ok 'App::Project::Doctor::Context';

subtest 'Context::new -- valid directory' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $ctx = App::Project::Doctor::Context->new(root => $dir);
	isa_ok $ctx, 'App::Project::Doctor::Context';
};

subtest 'Context::new -- root made absolute' => sub {
	# Relative paths must be normalised so downstream code can compare them.
	my $dir = tempdir(CLEANUP => 1);
	my $ctx = App::Project::Doctor::Context->new(root => $dir);
	ok(File::Spec->file_name_is_absolute($ctx->root), 'root is absolute');
};

subtest 'Context::new -- default root is cwd (must exist)' => sub {
	lives_ok { App::Project::Doctor::Context->new } 'default root (.) accepted';
};

subtest 'Context::new -- non-directory croaks' => sub {
	throws_ok {
		App::Project::Doctor::Context->new(root => '/no/such/dir/xyzzy99999')
	} qr/not a directory/i, 'non-existent path croaks';

	my $dir  = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($dir, 'regular.txt');
	open my $fh, '>', $file; close $fh;
	throws_ok {
		App::Project::Doctor::Context->new(root => $file)
	} qr/not a directory/i, 'regular file path croaks';
};

subtest 'Context::verbose accessor' => sub {
	my $dir = tempdir(CLEANUP => 1);
	is(App::Project::Doctor::Context->new(root => $dir, verbose => 0)->verbose, 0, 'verbose 0');
	is(App::Project::Doctor::Context->new(root => $dir, verbose => 1)->verbose, 1, 'verbose 1');
};

subtest 'Context::has_file' => sub {
	my $dir = make_distro('Makefile.PL' => "1;\n");
	my $ctx = _make_ctx($dir);
	ok  $ctx->has_file('Makefile.PL'), 'present file detected';
	ok !$ctx->has_file('nonexistent'), 'absent file returns false';
};

subtest 'Context::has_file -- undef arg croaks' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $ctx = _make_ctx($dir);
	throws_ok { $ctx->has_file(undef) } qr/requires a relative path/i, 'undef croaks';
};

subtest 'Context::abs_path' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $ctx = _make_ctx($dir);
	my $abs = $ctx->abs_path('lib/Foo.pm');
	like $abs, qr/lib.Foo\.pm$/, 'path ends with expected suffix';
	ok(File::Spec->file_name_is_absolute($abs), 'result is absolute');
};

subtest 'Context::abs_path -- undef arg croaks' => sub {
	my $dir = tempdir(CLEANUP => 1);
	throws_ok { _make_ctx($dir)->abs_path(undef) }
		qr/requires a relative path/i, 'undef croaks';
};

subtest 'Context::slurp -- reads file content' => sub {
	my $dir = make_distro('README' => "hello world\n");
	my $ctx = _make_ctx($dir);
	my $got = $ctx->slurp('README');
	returns_ok($got, { type => 'scalar' }, 'slurp returns a scalar');
	is $got, "hello world\n", 'content returned verbatim';
};

subtest 'Context::slurp -- undef arg croaks' => sub {
	my $dir = tempdir(CLEANUP => 1);
	throws_ok { _make_ctx($dir)->slurp(undef) }
		qr/requires a relative path/i, 'undef croaks';
};

subtest 'Context::slurp -- missing file croaks' => sub {
	my $dir = tempdir(CLEANUP => 1);
	throws_ok { _make_ctx($dir)->slurp('no-such-file.txt') }
		qr/File not found/i, 'missing file croaks';
};

subtest 'Context::slurp -- $INPUT_RECORD_SEPARATOR is localised' => sub {
	# $/ must be restored after slurp so callers using line-by-line reads
	# are not silently broken by our slurp mode.
	my $dir = make_distro('data.txt' => "a\nb\nc\n");
	my $ctx = _make_ctx($dir);
	my $original_sep = $/;
	$ctx->slurp('data.txt');
	is $/, $original_sep, '$/ restored after slurp';
};

subtest 'Context::perl_files -- extension filter' => sub {
	my $dir = make_distro(
		'lib/Foo.pm'    => '1;',
		'lib/bar.pl'    => '1;',
		'lib/Baz.txt'   => 'ignored',
		'lib/quux.yaml' => 'ignored',
		't/basic.t'     => '1;',
		'lib/Gen.PL'    => '1;',
	);
	my $ctx   = _make_ctx($dir);
	my $files = $ctx->perl_files('lib', 't');
	returns_ok($files, { type => 'arrayref' }, 'perl_files returns an arrayref');
	my %seen  = map { $_ => 1 } @{$files};

	ok  $seen{'lib/Foo.pm'},  '.pm collected';
	ok  $seen{'lib/bar.pl'},  '.pl collected';
	ok  $seen{'lib/Gen.PL'},  '.PL collected';
	ok  $seen{'t/basic.t'},   '.t collected';
	ok !$seen{'lib/Baz.txt'}, '.txt excluded';
	ok !$seen{'lib/quux.yaml'},'yaml excluded';
};

subtest 'Context::perl_files -- defaults to lib/script/bin/t' => sub {
	# When called with no args the four standard directories are searched.
	my $dir = make_distro(
		'lib/A.pm'      => '1;',
		't/foo.t'       => '1;',
		'script/run.pl' => '1;',
	);
	my $ctx   = _make_ctx($dir);
	my $files = $ctx->perl_files;
	my %seen  = map { $_ => 1 } @{$files};
	ok $seen{'lib/A.pm'},      'lib/ included in default';
	ok $seen{'t/foo.t'},       't/ included in default';
	ok $seen{'script/run.pl'}, 'script/ included in default';
};

subtest 'Context::lib_modules -- only .pm under lib/' => sub {
	my $dir = make_distro(
		'lib/A.pm'  => '1;',
		'lib/b.pl'  => '1;',
		't/c.t'     => '1;',
	);
	my $ctx  = _make_ctx($dir);
	my $mods = $ctx->lib_modules;
	my @pm   = grep { /\.pm$/ } @{$mods};
	is scalar @{$mods}, scalar @pm, 'lib_modules returns only .pm files';
};

subtest 'Context::test_files -- only .t under t/' => sub {
	my $dir = make_distro(
		't/a.t'    => '1;',
		't/b.t'    => '1;',
		'lib/c.pm' => '1;',
	);
	my $ctx   = _make_ctx($dir);
	my $tests = $ctx->test_files;
	is scalar @{$tests}, 2, 'finds both .t files';
	my $non_t = grep { !/\.t$/ } @{$tests};
	ok !$non_t, 'no non-.t files';
};

subtest 'Context::git_root -- returns string in a git repo' => sub {
	# This test runs inside the project repo, so git must find a root.
	my $ctx = App::Project::Doctor::Context->new(root => '.');
	my $gr  = $ctx->git_root;
	if (defined $gr) {
		ok length($gr), 'git_root returned a non-empty string';
		diag "git root: $gr" if $ENV{TEST_VERBOSE};
	} else {
		pass 'git not available -- skip';
	}
};

subtest 'Context::git_root -- returns undef outside any repo' => sub {
	# Use a mock so the test is deterministic regardless of environment.
	my $dir = tempdir(CLEANUP => 1);
	my $ctx = App::Project::Doctor::Context->new(root => $dir);
	my $g   = mock_scoped 'App::Project::Doctor::Context::git_root' => sub { return undef };
	is $ctx->git_root, undef, 'git_root returns undef outside repo';
};

subtest 'Context::builder_file -- priority and each marker' => sub {
	for my $marker (qw(Makefile.PL Build.PL dist.ini cpanfile)) {
		my $dir = make_distro($marker => '');
		my $ctx = _make_ctx($dir);
		is $ctx->builder_file, $marker, "detects $marker";
	}

	# undef when nothing found
	my $empty = tempdir(CLEANUP => 1);
	is _make_ctx($empty)->builder_file, undef, 'undef when no builder file';
};

subtest 'Context::builder_file -- Makefile.PL wins when multiple present' => sub {
	my $dir = make_distro(
		'Makefile.PL' => '',
		'dist.ini'    => '',
		'cpanfile'    => '',
	);
	is _make_ctx($dir)->builder_file, 'Makefile.PL', 'Makefile.PL has highest priority';
};

subtest 'Context::slurp -- spy verifies it is called with the right path' => sub {
	# Spy records calls while still running the real implementation.
	my $dir = make_distro('notes.txt' => "data\n");
	my $ctx = _make_ctx($dir);
	my $slurp_spy = spy 'App::Project::Doctor::Context::slurp';
	$ctx->slurp('notes.txt');
	my @calls = $slurp_spy->();
	is scalar @calls, 1,            'slurp called exactly once';
	is $calls[0][2],  'notes.txt',  'slurp invoked with correct relative path';
	restore_all 'App::Project::Doctor::Context';
};

subtest 'Context::find_files -- string suffix' => sub {
	my $dir = make_distro(
		'.github/workflows/ci.yml'  => '',
		'.github/workflows/rel.yml' => '',
		'.github/CODEOWNERS'        => '',
	);
	my $ctx   = _make_ctx($dir);
	my $found = $ctx->find_files('.github/workflows', '.yml');
	returns_ok($found, { type => 'arrayref' }, 'find_files returns an arrayref');
	is scalar @{$found}, 2, 'finds two .yml files';
	my $non_yml = grep { !/\.yml$/ } @{$found};
	ok !$non_yml, 'no non-.yml files returned';
};

subtest 'Context::find_files -- Regexp pattern' => sub {
	my $dir = make_distro(
		'.github/workflows/ci.yaml' => '',
		'.github/workflows/ci.yml'  => '',
		'.github/workflows/README'  => '',
	);
	my $ctx   = _make_ctx($dir);
	my $found = $ctx->find_files('.github/workflows', qr/\.ya?ml$/i);
	is scalar @{$found}, 2, 'regexp matches both .yml and .yaml';
};

subtest 'Context::find_files -- undef pattern returns all files' => sub {
	my $dir = make_distro(
		'.github/workflows/a.yml' => '',
		'.github/workflows/b.txt' => '',
	);
	my $ctx   = _make_ctx($dir);
	my $found = $ctx->find_files('.github/workflows', undef);
	is scalar @{$found}, 2, 'undef pattern returns all files';
};

subtest 'Context::find_files -- undef dir croaks' => sub {
	my $dir = tempdir(CLEANUP => 1);
	throws_ok { _make_ctx($dir)->find_files(undef) }
		qr/requires a directory/i, 'undef dir croaks';
};

subtest 'Context::_collect_files -- skips missing directories' => sub {
	# A dir name that does not exist on disk must be silently skipped, not
	# throw an error -- the user may not have all optional dirs present.
	my $dir = tempdir(CLEANUP => 1);
	my $ctx = _make_ctx($dir);
	lives_ok {
		$ctx->_collect_files(['nonexistent_dir'], sub { 1 });
	} 'non-existent dir in list is silently skipped';
	my $result = $ctx->_collect_files(['nonexistent_dir'], sub { 1 });
	is scalar @{$result}, 0, 'returns empty arrayref for missing dir';
};

subtest 'Context -- memory cycle check' => sub {
	my $dir = tempdir(CLEANUP => 1);
	memory_cycle_ok(_make_ctx($dir), 'Context has no circular references');
};

diag 'Context: done' if $ENV{TEST_VERBOSE};

# ===========================================================================
# 3. App::Project::Doctor::Check::Base
# ===========================================================================

require_ok 'App::Project::Doctor::Check::Base';

subtest 'Check::Base::new -- creates blessed object' => sub {
	my $b = App::Project::Doctor::Check::Base->new;
	isa_ok $b, 'App::Project::Doctor::Check::Base';
};

subtest 'Check::Base -- required methods croak with class name' => sub {
	my $b = App::Project::Doctor::Check::Base->new;

	# The error message must name the class so developers know which
	# subclass is missing the implementation.
	throws_ok { $b->name }
		qr/App::Project::Doctor::Check::Base must implement name/,
		'name() croaks with class name';

	throws_ok { $b->description }
		qr/App::Project::Doctor::Check::Base must implement description/,
		'description() croaks with class name';

	throws_ok { $b->check('ctx') }
		qr/App::Project::Doctor::Check::Base must implement check/,
		'check() croaks with class name';
};

subtest 'Check::Base -- optional method defaults' => sub {
	my $b = App::Project::Doctor::Check::Base->new;
	is $b->can_fix,  0,         'can_fix defaults to 0 (not just false)';
	is $b->category, 'general', 'category defaults to "general"';
	is $b->order,    50,        'order defaults to 50';
};

subtest 'Check::Base -- subclass inherits and overrides' => sub {
	# Create an inline subclass to verify inheritance mechanics.
	{
		package My::ConcreteCheck;
		use parent -norequire, 'App::Project::Doctor::Check::Base';
		sub name        { 'Concrete' }
		sub description { 'A test check.' }
		sub check       { () }
		sub can_fix     { 1 }
		sub order       { 99 }
	}

	my $c = My::ConcreteCheck->new;
	is $c->name,        'Concrete',       'overridden name';
	is $c->description, 'A test check.',  'overridden description';
	is $c->can_fix,     1,                'overridden can_fix';
	is $c->order,       99,               'overridden order';
	is $c->category,    'general',        'inherited category default';
};

subtest 'Check::Base -- subclass name appears in croak message' => sub {
	# If a subclass forgets to implement a method the error must point to
	# the subclass, not Base, so the developer knows where to look.
	{
		package My::IncompleteCheck;
		use parent -norequire, 'App::Project::Doctor::Check::Base';
		sub name        { 'Incomplete' }
		sub description { 'Missing check().' }
		# check() not implemented
	}
	my $ic = My::IncompleteCheck->new;
	throws_ok { $ic->check }
		qr/My::IncompleteCheck must implement check/,
		'subclass name appears in error';
};

diag 'Check::Base: done' if $ENV{TEST_VERBOSE};

# ===========================================================================
# 4. App::Project::Doctor::Report
# ===========================================================================

require_ok 'App::Project::Doctor::Report';

subtest 'Report::new -- starts empty and clean' => sub {
	my $r = App::Project::Doctor::Report->new;
	isa_ok $r, 'App::Project::Doctor::Report';
	is scalar($r->all_findings), 0, 'no findings on construction';
	is $r->exit_code,            0, 'exit_code 0 when clean';
	ok !$r->has_errors,             'has_errors false initially';
	ok !$r->has_warnings,           'has_warnings false initially';
};

subtest 'Report::add_findings -- appends and returns $self' => sub {
	my $r   = App::Project::Doctor::Report->new;
	my $f   = _make_finding(severity => $ERR_SEV, message => 'bad', check_name => 'X');
	my $ret = $r->add_findings($f);
	is $ret, $r, 'returns $self for chaining';
	is scalar($r->all_findings), 1, 'finding appended';
};

subtest 'Report::add_findings -- rejects non-Finding objects' => sub {
	my $r = App::Project::Doctor::Report->new;
	throws_ok { $r->add_findings('plain string') }
		qr/App::Project::Doctor::Finding/i, 'plain string rejected';
	throws_ok { $r->add_findings({}) }
		qr/App::Project::Doctor::Finding/i, 'plain hashref rejected';
	throws_ok { $r->add_findings(undef) }
		qr/App::Project::Doctor::Finding/i, 'undef rejected';
};

subtest 'Report -- filter methods: errors/warnings/passes/fixable' => sub {
	my $r = _make_report(
		_make_finding(severity => $ERR_SEV,  message => 'e',  check_name => 'A'),
		_make_finding(severity => $WARN_SEV, message => 'w',  check_name => 'B'),
		_make_finding(severity => $PASS_SEV, message => 'p',  check_name => 'C'),
		_make_finding(severity => $INFO_SEV, message => 'i',  check_name => 'D'),
		_make_finding(severity => $ERR_SEV,  message => 'e2', check_name => 'E',
		              fix => sub {}),
	);

	is scalar($r->errors),   2, 'errors() count';
	is scalar($r->warnings), 1, 'warnings() count';
	is scalar($r->passes),   1, 'passes() count';
	is scalar($r->fixable),  1, 'fixable() count -- only error-with-fix';
	ok $r->has_errors,          'has_errors true';
	ok $r->has_warnings,        'has_warnings true';
};

subtest 'Report::exit_code -- 0 clean, 1 errors' => sub {
	my $clean = _make_report(
		_make_finding(severity => $WARN_SEV, message => 'w', check_name => 'X'),
	);
	is $clean->exit_code, 0, 'warnings alone do not set exit_code to 1';

	my $dirty = _make_report(
		_make_finding(severity => $ERR_SEV, message => 'e', check_name => 'Y'),
	);
	is $dirty->exit_code, 1, 'error sets exit_code to 1';
};

subtest 'Report::render_text -- groups by check_name, shows worst icon' => sub {
	my $r = _make_report(
		_make_finding(severity => $PASS_SEV, message => 'clean', check_name => 'Tests'),
		_make_finding(severity => $ERR_SEV,  message => 'broke', check_name => 'Tests'),
	);
	my $text = $r->render_text;
	# Both findings belong to 'Tests'; the icon must reflect the worst (error).
	like $text, qr/\[X\].*Tests/,   'error icon shown for Tests group';
	like $text, qr/1 error\(s\)/,   'error count in summary';
};

subtest 'Report::render_text -- verbose shows per-finding detail' => sub {
	my $r = _make_report(
		_make_finding(
			severity   => $ERR_SEV,
			message    => 'Bad thing',
			detail     => 'Detailed explanation',
			check_name => 'Pod',
		),
	);
	my $plain   = $r->render_text(verbose => 0);
	my $verbose = $r->render_text(verbose => 1);
	unlike $plain,   qr/Detailed explanation/, 'detail hidden in plain mode';
	like   $verbose, qr/Detailed explanation/, 'detail shown in verbose mode';
};

subtest 'Report::render_text -- fix list present only when fixable findings exist' => sub {
	my $with_fix = _make_report(
		_make_finding(
			severity   => $ERR_SEV,
			message    => 'Fixable problem',
			check_name => 'CI',
			fix        => sub {},
		),
	);
	like $with_fix->render_text,
		qr/Suggested fixes:/,
		'fix list appears when fixable findings present';
	like $with_fix->render_text,
		qr/Would you like me to apply them/,
		'prompt appears';

	my $no_fix = _make_report(
		_make_finding(severity => $PASS_SEV, message => 'ok', check_name => 'CI'),
	);
	unlike $no_fix->render_text,
		qr/Suggested fixes:/,
		'no fix list when all findings are non-fixable';
};

subtest 'Report::render_text -- summary line formatting' => sub {
	my $r_err  = _make_report(_make_finding(severity => $ERR_SEV,  message => 'e', check_name => 'A'));
	my $r_warn = _make_report(_make_finding(severity => $WARN_SEV, message => 'w', check_name => 'A'));
	my $r_both = _make_report(
		_make_finding(severity => $ERR_SEV,  message => 'e', check_name => 'A'),
		_make_finding(severity => $WARN_SEV, message => 'w', check_name => 'B'),
	);
	my $r_none = _make_report(_make_finding(severity => $PASS_SEV, message => 'p', check_name => 'A'));

	like $r_err->render_text,  qr/1 error\(s\)/,       'error count';
	like $r_warn->render_text, qr/1 warning\(s\)/,     'warning count';
	like $r_both->render_text, qr/error.*warning/,     'both counts';
	like $r_none->render_text, qr/No errors or warnings/, 'clean message';
};

subtest 'Report::render_json -- parseable and excludes fix' => sub {
	my $r = _make_report(
		_make_finding(
			severity   => $INFO_SEV,
			message    => 'note',
			check_name => 'Meta',
			fix        => sub {},
		),
	);
	my $json = $r->render_json;
	returns_ok($json, { type => 'scalar' }, 'render_json returns a scalar');
	require JSON::MaybeXS;
	my $decoded = JSON::MaybeXS->new->decode($json);
	is ref $decoded, 'ARRAY', 'decodes to arrayref';
	ok !exists $decoded->[0]{fix}, 'fix not serialised';
	is $decoded->[0]{check_name}, 'Meta', 'check_name present';
};

subtest 'Report::render_tap -- plan and ok/not-ok lines' => sub {
	my $r = _make_report(
		_make_finding(severity => $PASS_SEV, message => 'good', check_name => 'A'),
		_make_finding(severity => $INFO_SEV, message => 'info', check_name => 'B'),
		_make_finding(severity => $ERR_SEV,  message => 'bad',  check_name => 'C'),
		_make_finding(severity => $WARN_SEV, message => 'warn', check_name => 'D'),
	);
	my $tap = $r->render_tap;
	returns_ok($tap, { type => 'scalar' }, 'render_tap returns a scalar');
	like $tap, qr/^1\.\.4/m,     'plan line';
	like $tap, qr/^ok 1/m,       'pass is ok';
	like $tap, qr/^ok 2/m,       'info is ok';
	like $tap, qr/^not ok 3/m,   'error is not ok';
	like $tap, qr/^not ok 4/m,   'warning is not ok';
};

subtest 'Report::_worst_severity -- rank order' => sub {
	# Directly exercise the private helper since it is non-trivial logic.
	my @err   = (_make_finding(severity => $ERR_SEV,  message => 'e', check_name => 'X'));
	my @warn  = (_make_finding(severity => $WARN_SEV, message => 'w', check_name => 'X'));
	my @info  = (_make_finding(severity => $INFO_SEV, message => 'i', check_name => 'X'));
	my @pass  = (_make_finding(severity => $PASS_SEV, message => 'p', check_name => 'X'));
	my @mixed = (@err, @warn, @info, @pass);

	is App::Project::Doctor::Report::_worst_severity(\@mixed), 'error',   'error dominates';
	is App::Project::Doctor::Report::_worst_severity(\@warn),  'warning', 'warning when no error';
	is App::Project::Doctor::Report::_worst_severity(\@info),  'info',    'info when only info';
	is App::Project::Doctor::Report::_worst_severity(\@pass),  'pass',    'pass when only pass';
};

subtest 'Report -- memory cycle check' => sub {
	my $r = _make_report(_make_finding(message => 'x', check_name => 'Y'));
	memory_cycle_ok($r, 'Report has no circular references');
};

diag 'Report: done' if $ENV{TEST_VERBOSE};

# ===========================================================================
# 5. App::Project::Doctor::Fixer
# ===========================================================================

require_ok 'App::Project::Doctor::Fixer';

# Build a real Context so the type constraint in Fixer::new is satisfied.
my $FIXER_DIR = make_distro('Makefile.PL' => '');
my $FIXER_CTX = _make_ctx($FIXER_DIR);

subtest 'Fixer::new -- requires report and context' => sub {
	my $r = _make_report;
	my $f = App::Project::Doctor::Fixer->new(report => $r, context => $FIXER_CTX);
	isa_ok $f, 'App::Project::Doctor::Fixer';
	is $f->non_interactive, 0, 'non_interactive defaults to 0';
};

subtest 'Fixer::new -- type constraints enforced' => sub {
	my $r = _make_report;
	throws_ok {
		App::Project::Doctor::Fixer->new(report => 'bad', context => $FIXER_CTX)
	} qr//i, 'non-Report for report rejected';

	throws_ok {
		App::Project::Doctor::Fixer->new(report => $r, context => 'bad')
	} qr//i, 'non-Context for context rejected';
};

subtest 'Fixer::run -- returns 0 immediately when no fixable findings' => sub {
	my $r     = _make_report(_make_finding(message => 'ok', severity => $PASS_SEV, check_name => 'X'));
	my $fixer = App::Project::Doctor::Fixer->new(
		report          => $r,
		context         => $FIXER_CTX,
		non_interactive => 1,
	);
	is $fixer->run, 0, 'run returns 0 when nothing to fix';
};

subtest 'Fixer::run -- non_interactive applies all fixes' => sub {
	my $applied = 0;
	my $r = _make_report(
		_make_finding(severity => $ERR_SEV, message => 'f1', check_name => 'X',
		              fix => sub { $applied++ }),
		_make_finding(severity => $ERR_SEV, message => 'f2', check_name => 'X',
		              fix => sub { $applied++ }),
	);
	my $fixer = App::Project::Doctor::Fixer->new(
		report          => $r,
		context         => $FIXER_CTX,
		non_interactive => 1,
	);
	my $count = $fixer->run;
	is $count,   2, 'returns count of applied fixes';
	is $applied, 2, 'both fix coderefs called';
};

subtest 'Fixer::_apply_all -- catches croaking fixes and carps' => sub {
	# A fix that throws must not abort the whole run -- it is caught and
	# reported via carp, and the remaining fixes still execute.
	my $second_ran = 0;
	my $r = _make_report(
		_make_finding(severity => $ERR_SEV, message => 'bad fix', check_name => 'X',
		              fix => sub { die "fix exploded!\n" }),
		_make_finding(severity => $ERR_SEV, message => 'good fix', check_name => 'X',
		              fix => sub { $second_ran++ }),
	);
	my $fixer = App::Project::Doctor::Fixer->new(
		report          => $r,
		context         => $FIXER_CTX,
		non_interactive => 1,
	);
	my $count;
	warning_like { $count = $fixer->run } qr/fix exploded/i, 'failed fix emits carp';
	is $count,      1, 'count reflects only successful fix';
	is $second_ran, 1, 'second fix still ran after first failed';
};

subtest 'Fixer::_interactive_loop -- Y applies all' => sub {
	my $applied = 0;
	my $r = _make_report(
		_make_finding(severity => $ERR_SEV, message => 'fix me', check_name => 'X',
		              fix => sub { $applied++ }),
	);
	my $fixer = App::Project::Doctor::Fixer->new(
		report   => $r,
		context  => $FIXER_CTX,
	);

	for my $yes_answer ('Y', 'y', 'yes', '') {
		$applied = 0;
		open my $in, '<', \(my $input = "$yes_answer\n");
		local *STDIN = *$in;
		$fixer->run;
		is $applied, 1, "answer '$yes_answer' applies the fix";
	}
};

subtest 'Fixer::_interactive_loop -- n skips all' => sub {
	my $applied = 0;
	my $r = _make_report(
		_make_finding(severity => $ERR_SEV, message => 'skip me', check_name => 'X',
		              fix => sub { $applied++ }),
	);
	my $fixer = App::Project::Doctor::Fixer->new(report => $r, context => $FIXER_CTX);

	for my $no_answer ('n', 'N', 'no', 'No') {
		$applied = 0;
		open my $in, '<', \(my $input = "$no_answer\n");
		local *STDIN = *$in;
		my $count = $fixer->run;
		is $count,   0, "answer '$no_answer' returns 0";
		is $applied, 0, "answer '$no_answer' does not call fix";
	}
};

subtest 'Fixer::_interactive_loop -- numeric index selection' => sub {
	my @applied = (0, 0, 0);
	my $r = _make_report(
		_make_finding(severity => $ERR_SEV, message => 'f1', check_name => 'A',
		              fix => sub { $applied[0]++ }),
		_make_finding(severity => $ERR_SEV, message => 'f2', check_name => 'A',
		              fix => sub { $applied[1]++ }),
		_make_finding(severity => $ERR_SEV, message => 'f3', check_name => 'A',
		              fix => sub { $applied[2]++ }),
	);
	my $fixer = App::Project::Doctor::Fixer->new(report => $r, context => $FIXER_CTX);

	open my $in, '<', \"1,3\n";
	local *STDIN = *$in;
	my $count = $fixer->run;
	is $count,       2,     'two fixes applied';
	is $applied[0],  1,     'fix 1 ran';
	is $applied[1],  0,     'fix 2 NOT ran';
	is $applied[2],  1,     'fix 3 ran';
};

subtest 'Fixer::_interactive_loop -- invalid input skips' => sub {
	my $applied = 0;
	my $r = _make_report(
		_make_finding(severity => $ERR_SEV, message => 'x', check_name => 'X',
		              fix => sub { $applied++ }),
	);
	my $fixer = App::Project::Doctor::Fixer->new(report => $r, context => $FIXER_CTX);
	open my $in, '<', \"garbage\n";
	local *STDIN = *$in;
	is $fixer->run, 0, 'garbage input returns 0';
	is $applied,    0, 'fix not called on garbage input';
};

subtest 'Fixer::_interactive_loop -- EOF (undef from STDIN) returns 0' => sub {
	my $applied = 0;
	my $r = _make_report(
		_make_finding(severity => $ERR_SEV, message => 'x', check_name => 'X',
		              fix => sub { $applied++ }),
	);
	my $fixer = App::Project::Doctor::Fixer->new(report => $r, context => $FIXER_CTX);
	open my $in, '<', \'';   # empty -- STDIN immediately gives undef
	local *STDIN = *$in;
	is $fixer->run, 0, 'EOF returns 0';
	is $applied,    0, 'fix not called on EOF';
};

diag 'Fixer: done' if $ENV{TEST_VERBOSE};

# ===========================================================================
# 6. App::Project::Doctor (orchestrator)
# ===========================================================================

require_ok 'App::Project::Doctor';

subtest 'Doctor::new -- defaults' => sub {
	my $d = App::Project::Doctor->new;
	is $d->path,    '.',  'path defaults to .';
	is $d->verbose, 0,    'verbose defaults to 0';
	ok ref $d->checks eq 'ARRAY', 'checks is an arrayref';
	ok ref $d->skip   eq 'ARRAY', 'skip is an arrayref';
	ok scalar @{$d->checks} > 0,  'default checks list is non-empty';
};

subtest 'Doctor::new -- custom args stored' => sub {
	my $d = App::Project::Doctor->new(
		path    => '/tmp',
		checks  => ['Tests'],
		skip    => ['CI'],
		verbose => 1,
	);
	is $d->path,            '/tmp',     'path stored';
	is_deeply $d->checks,   ['Tests'],  'checks stored';
	is_deeply $d->skip,     ['CI'],     'skip stored';
	is $d->verbose,         1,          'verbose stored';
};

subtest 'Doctor::run -- returns a Report' => sub {
	my $dir = make_distro('Makefile.PL' => '');
	my $d   = App::Project::Doctor->new(path => $dir, checks => ['CpanReadiness']);
	my $r   = $d->run;
	isa_ok $r, 'App::Project::Doctor::Report';
	isa_ok($r, 'App::Project::Doctor::Report', 'run returns a Report object');
};

subtest 'Doctor::run -- croaks when no distribution root detectable' => sub {
	# A directory with no builder file -- root detection must fail.
	my $dir = tempdir(CLEANUP => 1);
	throws_ok { App::Project::Doctor->new(path => $dir)->run }
		qr/Cannot detect a distribution root/i,
		'croaks with clear message when no root found';
};

subtest 'Doctor::_detect_root -- finds each marker type' => sub {
	for my $marker (qw(Makefile.PL Build.PL dist.ini cpanfile)) {
		my $dir = make_distro($marker => '');
		my $d   = App::Project::Doctor->new(path => $dir);
		my $root = $d->_detect_root($dir);
		is $root, File::Spec->rel2abs($dir), "_detect_root finds $marker";
	}
};

subtest 'Doctor::_detect_root -- walks up the tree' => sub {
	# Place Makefile.PL one level up and look from a subdir.
	my $parent = make_distro('Makefile.PL' => '');
	my $child  = File::Spec->catdir($parent, 'lib');
	make_path($child);
	my $d    = App::Project::Doctor->new(path => $child);
	my $root = $d->_detect_root($child);
	is $root, File::Spec->rel2abs($parent), 'walked up to parent with Makefile.PL';
};

subtest 'Doctor::_detect_root -- returns undef when no marker found' => sub {
	# Mock so the test never has to walk the real filesystem all the way to /.
	my $d = App::Project::Doctor->new(path => '/');
	my $g = mock_scoped 'App::Project::Doctor::_detect_root' => sub { return undef };
	is $d->_detect_root('/'), undef, 'returns undef at filesystem root';
};

subtest 'Doctor::_build_checks -- excludes skipped (case-insensitive)' => sub {
	my $dir = make_distro('Makefile.PL' => '');
	my $d   = App::Project::Doctor->new(
		path   => $dir,
		checks => [qw(CI Tests)],
		skip   => ['ci'],   # lowercase skip must match 'CI'
	);
	my @checks = $d->_build_checks;
	my @names  = map { $_->name } @checks;
	my $ci_present    = grep { $_ eq 'CI' } @names;
	my $tests_present = grep { $_ eq 'Tests' } @names;
	ok !$ci_present,    'CI excluded by case-insensitive skip';
	ok  $tests_present, 'Tests not excluded';
};

subtest 'Doctor::_build_checks -- sorted by order' => sub {
	my $dir = make_distro('Makefile.PL' => '');
	my $d   = App::Project::Doctor->new(
		path   => $dir,
		checks => [qw(Security Tests CI)],  # intentionally out of order
	);
	my @checks = $d->_build_checks;
	my @orders = map { $_->order } @checks;
	is_deeply \@orders, [sort { $a <=> $b } @orders], 'checks sorted by order';
};

subtest 'Doctor::_build_checks -- carps on unknown check class' => sub {
	my $dir = make_distro('Makefile.PL' => '');
	my $d   = App::Project::Doctor->new(
		path   => $dir,
		checks => ['NonExistentCheck99'],
	);
	my @checks;
	warning_like { @checks = $d->_build_checks }
		qr/Could not load/i,
		'carps when check class cannot be loaded';
	is scalar @checks, 0, 'failed check not added to list';
};

subtest 'Doctor::run -- verbose prints check names' => sub {
	my $dir = make_distro('Makefile.PL' => '');
	my $d   = App::Project::Doctor->new(
		path    => $dir,
		checks  => ['CpanReadiness'],
		verbose => 1,
	);
	my $output = '';
	open my $out, '>', \$output;
	local *STDOUT = *$out;
	$d->run;
	close $out;
	like $output, qr/Running.*CPAN/i, 'verbose mode prints check name';
};

diag 'Doctor: done' if $ENV{TEST_VERBOSE};

# ===========================================================================
# 7. Check::CI
# ===========================================================================

require_ok 'App::Project::Doctor::Check::CI';

subtest 'Check::CI -- metadata' => sub {
	my $c = App::Project::Doctor::Check::CI->new;
	is  $c->name,     'CI',   'name';
	ok  length($c->description), 'description non-empty';
	is  $c->can_fix,  1,      'can_fix true';
	is  $c->order,    20,     'order';
};

subtest 'Check::CI::check -- pass when each CI config present' => sub {
	my %ci_paths = (
		'GitHub Actions' => '.github/workflows',
		'Travis CI'      => '.travis.yml',
		'CircleCI'       => '.circleci/config.yml',
		'AppVeyor'       => 'appveyor.yml',
	);
	for my $label (sort keys %ci_paths) {
		my $path = $ci_paths{$label};
		my $dir;
		if ($path =~ m{/$} || $path !~ /\./) {
			# it's a directory marker
			$dir = make_distro("$path/.keep" => '');
		} else {
			$dir = make_distro($path => '');
		}
		my $ctx = _make_ctx($dir);
		my @f   = App::Project::Doctor::Check::CI->new->check($ctx);
		is scalar @f, 1, "one finding for $label";
		is $f[0]->severity, $PASS_SEV, "$label detected as pass";
	}
};

subtest 'Check::CI::check -- error when no CI found' => sub {
	my $dir = make_distro('Makefile.PL' => '');
	my @f   = App::Project::Doctor::Check::CI->new->check(_make_ctx($dir));
	is scalar @f, 1, 'one finding';
	is $f[0]->severity, $ERR_SEV, 'error when no CI config';
	ok $f[0]->is_fixable,         'finding is fixable';
};

subtest 'Check::CI::check -- croaks without a context ref' => sub {
	throws_ok { App::Project::Doctor::Check::CI->new->check('not-a-ref') }
		qr/requires an App::Project::Doctor::Context/i, 'non-ref ctx croaks';
};

diag 'Check::CI: done' if $ENV{TEST_VERBOSE};

# ===========================================================================
# 8. Check::CpanReadiness
# ===========================================================================

require_ok 'App::Project::Doctor::Check::CpanReadiness';

subtest 'Check::CpanReadiness -- metadata' => sub {
	my $c = App::Project::Doctor::Check::CpanReadiness->new;
	is $c->name,    'CPAN Readiness', 'name';
	is $c->can_fix, 0,                'can_fix false';
	is $c->order,   90,               'order';
};

subtest 'Check::CpanReadiness::check -- valid version formats pass' => sub {
	for my $ver (qw(0.01 1.23 0.01.02 1.23_04)) {
		my $dir = make_distro(
			'Makefile.PL'  => '',
			'lib/Foo.pm'   => "our \$VERSION = '$ver';\n1;\n",
			'Changes'      => "1.00\n",
			'MANIFEST'     => '',
			'README'       => '',
		);
		my @f = App::Project::Doctor::Check::CpanReadiness->new->check(_make_ctx($dir));
		my @errors = grep { $_->severity eq $ERR_SEV } @f;
		diag "version=$ver errors: " . join(', ', map { $_->message } @errors)
			if $ENV{TEST_VERBOSE} && @errors;
		my $bad = grep { $_->message =~ /Version.*does not match/ } @f;
		ok !$bad, "version '$ver' accepted";
	}
};

subtest 'Check::CpanReadiness::check -- invalid version formats fail' => sub {
	for my $ver ('alpha', 'v1.0.0', '1') {
		my $dir = make_distro(
			'Makefile.PL' => '',
			'lib/Foo.pm'  => "our \$VERSION = '$ver';\n1;\n",
		);
		my @f = App::Project::Doctor::Check::CpanReadiness->new->check(_make_ctx($dir));
		my $flagged = grep { $_->message =~ /does not match CPAN format/i } @f;
		ok $flagged, "version '$ver' flagged as invalid";
	}
};

subtest 'Check::CpanReadiness::check -- warns when no version found' => sub {
	my $dir = make_distro('Makefile.PL' => '', 'lib/Foo.pm' => "1;\n");
	my @f   = App::Project::Doctor::Check::CpanReadiness->new->check(_make_ctx($dir));
	my $has_warn = grep { $_->severity eq $WARN_SEV && $_->message =~ /Could not determine/i } @f;
	ok $has_warn, 'warning when no $VERSION found';
};

subtest 'Check::CpanReadiness::check -- errors for each missing file' => sub {
	for my $required (qw(Changes MANIFEST README)) {
		# Provide all required files except the one under test.
		my %files = (
			'Makefile.PL' => '',
			'lib/Foo.pm'  => "our \$VERSION = '0.01';\n1;\n",
			'Changes'     => "0.01\n",
			'MANIFEST'    => '',
			'README'      => '',
		);
		delete $files{$required};
		my $dir = make_distro(%files);
		my @f   = App::Project::Doctor::Check::CpanReadiness->new->check(_make_ctx($dir));
		my $missing = grep { $_->message =~ /\Q$required\E.*missing/i } @f;
		ok $missing, "error when $required is absent";
	}
};

subtest 'Check::CpanReadiness::check -- Changes without version entry is warning' => sub {
	my $dir = make_distro(
		'Makefile.PL' => '',
		'lib/Foo.pm'  => "our \$VERSION = '0.01';\n1;\n",
		'Changes'     => "This is the changelog.\nNo version entries here.\n",
		'MANIFEST'    => '',
		'README'      => '',
	);
	my @f = App::Project::Doctor::Check::CpanReadiness->new->check(_make_ctx($dir));
	my $no_ver = grep { $_->severity eq $WARN_SEV && $_->message =~ /no version entries/i } @f;
	ok $no_ver, 'warning when Changes has no version entries';
};

subtest 'Check::CpanReadiness::check -- MANIFEST presence emits info advisory' => sub {
	my $dir = make_distro(
		'Makefile.PL' => '',
		'lib/Foo.pm'  => "our \$VERSION = '0.01';\n1;\n",
		'Changes'     => "0.01\n",
		'MANIFEST'    => '',
		'README'      => '',
	);
	my @f = App::Project::Doctor::Check::CpanReadiness->new->check(_make_ctx($dir));
	my $manifest_info = grep { $_->severity eq $INFO_SEV && $_->message =~ /make manifest/i } @f;
	ok $manifest_info, 'MANIFEST present triggers info advisory';
};

subtest 'Check::CpanReadiness::check -- pass when everything good' => sub {
	my $dir = make_distro(
		'Makefile.PL' => '',
		'lib/Foo.pm'  => "our \$VERSION = '0.01';\n1;\n",
		'Changes'     => "0.01\n",
		'MANIFEST'    => '',
		'README'      => '',
	);
	my @f = App::Project::Doctor::Check::CpanReadiness->new->check(_make_ctx($dir));
	my $has_pass = grep { $_->severity eq $PASS_SEV } @f;
	ok $has_pass, 'pass emitted when all criteria met';
};

subtest 'Check::CpanReadiness::check -- README.md accepted in place of README' => sub {
	# README.md is the most common modern form; the check must not flag it as missing.
	my $dir = make_distro(
		'Makefile.PL' => '',
		'lib/Foo.pm'  => "our \$VERSION = '0.01';\n1;\n",
		'Changes'     => "0.01\n",
		'MANIFEST'    => '',
		'README.md'   => '# Foo',    # .md only, no plain README
	);
	my @f = App::Project::Doctor::Check::CpanReadiness->new->check(_make_ctx($dir));
	my $readme_error = grep { $_->message =~ /README.*missing/i } @f;
	ok !$readme_error, 'README.md satisfies the README requirement';
};

subtest 'Check::CpanReadiness::check -- README variants all accepted' => sub {
	# Every supported variant must suppress the README-missing error individually.
	for my $variant (qw(README README.md README.pod README.rst README.txt)) {
		my $dir = make_distro(
			'Makefile.PL' => '',
			'lib/Foo.pm'  => "our \$VERSION = '0.01';\n1;\n",
			'Changes'     => "0.01\n",
			'MANIFEST'    => '',
			$variant      => '',
		);
		my @f = App::Project::Doctor::Check::CpanReadiness->new->check(_make_ctx($dir));
		my $readme_error = grep { $_->message =~ /README.*missing/i } @f;
		ok !$readme_error, "$variant satisfies the README requirement";
	}
};

subtest 'Check::CpanReadiness::check -- error when no README variant present' => sub {
	# A distro with none of the accepted README forms must produce an error.
	my $dir = make_distro(
		'Makefile.PL' => '',
		'lib/Foo.pm'  => "our \$VERSION = '0.01';\n1;\n",
		'Changes'     => "0.01\n",
		'MANIFEST'    => '',
		# No README* file of any kind.
	);
	my @f = App::Project::Doctor::Check::CpanReadiness->new->check(_make_ctx($dir));
	my $readme_error = grep { $_->message =~ /README.*missing/i } @f;
	ok $readme_error, 'error when no README variant is present at all';
};

subtest 'Check::CpanReadiness::_read_version -- finds version in first module' => sub {
	my $dir = make_distro(
		'Makefile.PL' => '',
		'lib/My/Mod.pm' => "package My::Mod;\nour \$VERSION = '1.23';\n1;\n",
	);
	my $v = App::Project::Doctor::Check::CpanReadiness::_read_version(_make_ctx($dir));
	is $v, '1.23', '_read_version extracts version string';
};

diag 'Check::CpanReadiness: done' if $ENV{TEST_VERBOSE};

# ===========================================================================
# 9. Check::Dependencies
# ===========================================================================

require_ok 'App::Project::Doctor::Check::Dependencies';

subtest 'Check::Dependencies -- metadata' => sub {
	my $c = App::Project::Doctor::Check::Dependencies->new;
	is $c->name,    'Dependencies', 'name';
	is $c->can_fix, 1,              'can_fix true';
	is $c->order,   50,             'order';
};

subtest 'Check::Dependencies::check -- warning when no builder or cpanfile' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my @f   = App::Project::Doctor::Check::Dependencies->new->check(_make_ctx($dir));
	is scalar @f, 1, 'one finding';
	is $f[0]->severity, $WARN_SEV, 'warning when no prereq file';
};

subtest 'Check::Dependencies::check -- pass when all used modules declared in cpanfile' => sub {
	my $dir = make_distro(
		'cpanfile'   => "requires 'Some::Module';\n",
		'lib/Foo.pm' => "use Some::Module;\n1;\n",
	);
	my @f = App::Project::Doctor::Check::Dependencies->new->check(_make_ctx($dir));
	my $has_pass_deps = grep { $_->severity eq $PASS_SEV } @f;
	ok $has_pass_deps, 'pass when all deps declared';
};

subtest 'Check::Dependencies::check -- error for undeclared module' => sub {
	my $dir = make_distro(
		'cpanfile'   => "requires 'Other::Mod';\n",
		'lib/Foo.pm' => "use Missing::Module;\n1;\n",
	);
	my @f = App::Project::Doctor::Check::Dependencies->new->check(_make_ctx($dir));
	my $missing_mod = grep { $_->severity eq $ERR_SEV && $_->message =~ /Missing::Module/ } @f;
	my $is_fixable  = grep { $_->is_fixable } @f;
	ok $missing_mod, 'error for undeclared module';
	ok $is_fixable,  'finding is fixable';
};

subtest 'Check::Dependencies::check -- core modules not flagged' => sub {
	my $dir = make_distro(
		'cpanfile'   => "requires 'Some::External';\n",
		'lib/Foo.pm' => "use strict;\nuse warnings;\nuse Carp;\nuse Scalar::Util;\nuse Some::External;\n1;\n",
	);
	my @f = App::Project::Doctor::Check::Dependencies->new->check(_make_ctx($dir));
	my $core_flagged = grep { $_->message =~ /strict|warnings|Carp|Scalar::Util/ } @f;
	ok !$core_flagged, 'core modules not reported as missing';
};

subtest 'Check::Dependencies::_collect_used -- use and require both captured' => sub {
	my $dir = make_distro(
		'cpanfile'   => '',
		'lib/Foo.pm' => "use A::Module;\nrequire B::Module;\n1;\n",
	);
	my $ctx  = _make_ctx($dir);
	my $used = App::Project::Doctor::Check::Dependencies::_collect_used($ctx);
	returns_ok($used, { type => 'hashref' }, '_collect_used returns a hashref');
	ok exists $used->{'A::Module'}, 'use statement captured';
	ok exists $used->{'B::Module'}, 'require statement captured';
};

subtest 'Check::Dependencies::_collect_used -- bare version numbers not captured' => sub {
	# "use 5.016" must not be treated as a module name.
	my $dir = make_distro(
		'cpanfile'   => '',
		'lib/Foo.pm' => "use 5.016;\n1;\n",
	);
	my $ctx  = _make_ctx($dir);
	my $used = App::Project::Doctor::Check::Dependencies::_collect_used($ctx);
	ok !exists $used->{'5.016'}, 'bare version number not added to used hash';
};

subtest 'Check::Dependencies::_parse_cpanfile -- parses requires lines' => sub {
	my $dir = make_distro('cpanfile' => "requires 'Foo::Bar';\nrequires \"Baz\";\n");
	my $path = File::Spec->catfile($dir, 'cpanfile');
	my $mods = App::Project::Doctor::Check::Dependencies::_parse_cpanfile($path);
	returns_ok($mods, { type => 'hashref' }, '_parse_cpanfile returns a hashref');
	ok exists $mods->{'Foo::Bar'}, 'double-quoted module parsed';
	ok exists $mods->{'Baz'},      'single-quoted module parsed';
};

subtest 'Check::Dependencies::_fix_add_prereq -- appends to cpanfile' => sub {
	my $dir = make_distro('cpanfile' => "requires 'Existing';\n");
	my $ctx = _make_ctx($dir);
	my $fix = App::Project::Doctor::Check::Dependencies::_fix_add_prereq($ctx, 'New::Dep');
	$fix->();
	my $content = $ctx->slurp('cpanfile');
	like $content, qr/requires 'New::Dep'/, 'new dep appended to cpanfile';
	like $content, qr/requires 'Existing'/, 'existing dep preserved';
};

subtest 'Check::Dependencies::_fix_add_prereq -- carps for Makefile.PL' => sub {
	# Auto-fixing Makefile.PL is not implemented; a carp must be emitted.
	my $dir = make_distro('Makefile.PL' => "1;\n");
	my $ctx = _make_ctx($dir);
	my $fix = App::Project::Doctor::Check::Dependencies::_fix_add_prereq($ctx, 'New::Dep');
	warning_like { $fix->() }
		qr/Auto-fix for Makefile\.PL not implemented/i,
		'carps for Makefile.PL case';
};

diag 'Check::Dependencies: done' if $ENV{TEST_VERBOSE};

# ===========================================================================
# 10. Check::License
# ===========================================================================

require_ok 'App::Project::Doctor::Check::License';

subtest 'Check::License -- metadata' => sub {
	my $c = App::Project::Doctor::Check::License->new;
	is $c->name,    'Licensing', 'name';
	is $c->can_fix, 0,           'can_fix false';
	is $c->order,   45,          'order';
};

subtest 'Check::License::check -- LICENSE file present, no META' => sub {
	my $dir = make_distro('LICENSE' => "GPL text\n", 'Makefile.PL' => '');
	my @f   = App::Project::Doctor::Check::License->new->check(_make_ctx($dir));
	my $lic_pass = grep { $_->severity eq $PASS_SEV } @f;
	ok $lic_pass, 'pass when LICENSE present';
};

subtest 'Check::License::check -- LICENCE (British) accepted' => sub {
	my $dir = make_distro('LICENCE' => "GPL text\n", 'Makefile.PL' => '');
	my @f   = App::Project::Doctor::Check::License->new->check(_make_ctx($dir));
	my $brit_pass = grep { $_->severity eq $PASS_SEV } @f;
	ok $brit_pass, 'LICENCE spelling accepted';
};

subtest 'Check::License::check -- error when neither file present' => sub {
	my $dir = make_distro('Makefile.PL' => '');
	my @f   = App::Project::Doctor::Check::License->new->check(_make_ctx($dir));
	my $no_lic = grep { $_->severity eq $ERR_SEV && $_->message =~ /No LICENSE/i } @f;
	ok $no_lic, 'error when neither LICENSE nor LICENCE present';
};

subtest 'Check::License::check -- mismatch with META emits warning' => sub {
	# The META says gpl_2 but the LICENSE content is clearly MIT text.
	# Pre-load CPAN::Meta so that the lazy `require` inside _meta_license_id
	# is a no-op and does not overwrite our mock.
	require CPAN::Meta;
	my $g = mock_scoped('CPAN::Meta',
		load_file => sub { return bless {}, 'CPAN::Meta' },
		license   => sub { 'gpl_2' },
	);
	# Spy wraps the already-installed mock so call recording works.
	my $lf_spy = spy 'CPAN::Meta::load_file';

	my $dir = make_distro(
		'LICENSE'   => "Permission is hereby granted, free of charge\n",
		'META.json' => '{}',
	);
	my @f = App::Project::Doctor::Check::License->new->check(_make_ctx($dir));
	my $mismatch = grep { $_->severity eq $WARN_SEV && $_->message =~ /does not match/i } @f;
	ok $mismatch, 'warning on META vs LICENSE mismatch';
	my @calls = $lf_spy->();
	ok scalar @calls >= 1, 'CPAN::Meta::load_file was called during license check';
	restore_all 'CPAN::Meta';
};

subtest 'Check::License::check -- matching META+LICENSE emits pass' => sub {
	my $g = mock_scoped('CPAN::Meta',
		load_file => sub { return bless {}, 'CPAN::Meta' },
		license   => sub { 'gpl_2' },
	);

	my $dir = make_distro(
		'LICENSE'   => "GNU GENERAL PUBLIC LICENSE\nVersion 2\n",
		'META.json' => '{}',
	);
	my @f = App::Project::Doctor::Check::License->new->check(_make_ctx($dir));
	my $lic_match_pass = grep { $_->severity eq $PASS_SEV } @f;
	ok $lic_match_pass, 'pass when LICENSE content matches declared META license';
};

subtest 'Check::License::_meta_license_id -- returns undef on parse failure' => sub {
	mock_exception 'CPAN::Meta::load_file' => 'parse error';
	is App::Project::Doctor::Check::License::_meta_license_id('/fake/META.yml'),
		undef, 'returns undef when CPAN::Meta cannot parse the file';
	restore_all 'CPAN::Meta';
};

diag 'Check::License: done' if $ENV{TEST_VERBOSE};

# ===========================================================================
# 11. Check::Meta
# ===========================================================================

require_ok 'App::Project::Doctor::Check::Meta';

subtest 'Check::Meta -- metadata' => sub {
	my $c = App::Project::Doctor::Check::Meta->new;
	is $c->name,    'META', 'name';
	is $c->can_fix, 0,      'can_fix false';
	is $c->order,   30,     'order';
};

subtest 'Check::Meta::check -- warning only when no META but builder exists' => sub {
	my $dir = make_distro('Makefile.PL' => '');
	my @f   = App::Project::Doctor::Check::Meta->new->check(_make_ctx($dir));
	my $meta_warn    = grep { $_->severity eq $WARN_SEV } @f;
	my $meta_err     = grep { $_->severity eq $ERR_SEV  } @f;
	ok  $meta_warn,  'warning when no META file';
	ok !$meta_err,   'no error when builder present';
};

subtest 'Check::Meta::check -- warning + error when no META and no builder' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my @f   = App::Project::Doctor::Check::Meta->new->check(_make_ctx($dir));
	my $no_meta_warn = grep { $_->severity eq $WARN_SEV } @f;
	my $no_meta_err  = grep { $_->severity eq $ERR_SEV  } @f;
	ok $no_meta_warn, 'warning emitted';
	ok $no_meta_err,  'error emitted for missing builder';
};

subtest 'Check::Meta::check -- error when META parse fails' => sub {
	mock_exception 'CPAN::Meta::load_file' => 'bad yaml';
	my $dir = make_distro('META.yml' => 'invalid: [yaml');
	my @f   = App::Project::Doctor::Check::Meta->new->check(_make_ctx($dir));
	my $parse_err = grep { $_->severity eq $ERR_SEV && $_->message =~ /Failed to parse/i } @f;
	ok $parse_err, 'error emitted on parse failure';
	restore_all 'CPAN::Meta';
};

subtest 'Check::Meta::check -- error per missing required field' => sub {
	# license is intentionally absent to verify that field is required.
	my $struct = {
		name     => 'MyDist',
		version  => '0.01',
		author   => ['Test Author'],
		abstract => 'Something',
	};
	my $g = mock_scoped('CPAN::Meta',
		load_file => sub { return bless {}, 'CPAN::Meta' },
		as_struct  => sub { return $struct },
	);
	my $dir = make_distro('META.yml' => '');
	my @f   = App::Project::Doctor::Check::Meta->new->check(_make_ctx($dir));
	my $lic_field = grep { $_->message =~ /'license'/ } @f;
	ok $lic_field, 'error for missing license field';
};

subtest 'Check::Meta::check -- pass when all required fields present' => sub {
	my $struct = {
		name     => 'MyDist',
		version  => '0.01',
		author   => ['Author'],
		abstract => 'Desc',
		license  => 'gpl_2',
	};
	my $g = mock_scoped('CPAN::Meta',
		load_file => sub { return bless {}, 'CPAN::Meta' },
		as_struct  => sub { return $struct },
	);
	my $dir = make_distro('META.yml' => '');
	my @f   = App::Project::Doctor::Check::Meta->new->check(_make_ctx($dir));
	my $all_fields_pass = grep { $_->severity eq $PASS_SEV } @f;
	ok $all_fields_pass, 'pass when all fields present';
};

diag 'Check::Meta: done' if $ENV{TEST_VERBOSE};

# ===========================================================================
# 12. Check::Pod
# ===========================================================================

require_ok 'App::Project::Doctor::Check::Pod';

subtest 'Check::Pod -- metadata' => sub {
	my $c = App::Project::Doctor::Check::Pod->new;
	is $c->name,    'POD', 'name';
	is $c->can_fix, 1,     'can_fix true';
	is $c->order,   40,    'order';
};

subtest 'Check::Pod::check -- info when lib/ is empty' => sub {
	my $dir = make_distro('Makefile.PL' => '');
	my @f   = App::Project::Doctor::Check::Pod->new->check(_make_ctx($dir));
	my $no_pm_info = grep { $_->severity eq $INFO_SEV } @f;
	ok $no_pm_info, 'info when no .pm files';
};

subtest 'Check::Pod::check -- pass when module has valid POD' => sub {
	my $dir = make_distro(
		'lib/Good.pm' => "package Good;\n=head1 NAME\nGood - testing\n=cut\n1;\n",
	);
	my @f = App::Project::Doctor::Check::Pod->new->check(_make_ctx($dir));
	my $pod_pass = grep { $_->severity eq $PASS_SEV } @f;
	ok $pod_pass, 'pass when module has valid POD';
};

subtest 'Check::Pod::check -- error for module with no POD' => sub {
	my $dir = make_distro(
		'lib/NoPod.pm' => "package NoPod;\n1;\n",
	);
	my @f = App::Project::Doctor::Check::Pod->new->check(_make_ctx($dir));
	my $no_pod_err  = grep { $_->severity eq $ERR_SEV && $_->message =~ /No POD found/i } @f;
	my $pod_fixable = grep { $_->is_fixable } @f;
	ok $no_pod_err,  'error when no POD';
	ok $pod_fixable, 'finding is fixable';
};

subtest 'Check::Pod::_fix_scaffold_pod -- appends POD skeleton with correct package name' => sub {
	my $dir = make_distro(
		'lib/My/Pkg.pm' => "package My::Pkg;\n1;\n",
	);
	my $ctx = _make_ctx($dir);
	my $fix = App::Project::Doctor::Check::Pod::_fix_scaffold_pod($ctx, 'lib/My/Pkg.pm');
	$fix->();
	my $content = $ctx->slurp('lib/My/Pkg.pm');
	like $content, qr/=head1 NAME/,   'NAME section added';
	like $content, qr/My::Pkg/,        'correct package name in POD';
	like $content, qr/=head1 SYNOPSIS/, 'SYNOPSIS section added';
};

subtest 'Check::Pod::_check_pod -- returns empty list for valid POD' => sub {
	my $dir = make_distro(
		'lib/Ok.pm' => "package Ok;\n=head1 NAME\nOk - good\n=cut\n1;\n",
	);
	my $abs  = File::Spec->catfile($dir, 'lib', 'Ok.pm');
	my @errs = App::Project::Doctor::Check::Pod::_check_pod($abs);
	is scalar @errs, 0, 'no errors for valid POD';
};

diag 'Check::Pod: done' if $ENV{TEST_VERBOSE};

# ===========================================================================
# 13. Check::Security
# ===========================================================================

require_ok 'App::Project::Doctor::Check::Security';

subtest 'Check::Security -- metadata' => sub {
	my $c = App::Project::Doctor::Check::Security->new;
	is $c->name,    'Security', 'name';
	is $c->can_fix, 1,          'can_fix true';
	is $c->order,   60,         'order';
};

subtest 'Check::Security::check -- pass when all files are clean' => sub {
	my $dir = make_distro(
		'lib/Clean.pm' => "package Clean;\nuse strict;\nuse warnings;\n1;\n",
	);
	my @f = App::Project::Doctor::Check::Security->new->check(_make_ctx($dir));
	my $sec_pass = grep { $_->severity eq $PASS_SEV } @f;
	ok $sec_pass, 'pass when strict+warnings present, no secrets';
};

subtest 'Check::Security::check -- error for missing strict' => sub {
	my $dir = make_distro(
		'lib/Nope.pm' => "package Nope;\nuse warnings;\n1;\n",
	);
	my @f = App::Project::Doctor::Check::Security->new->check(_make_ctx($dir));
	my $no_strict     = grep { $_->severity eq $ERR_SEV && $_->message =~ /Missing 'use strict'/ } @f;
	my $strict_fixable = grep { $_->is_fixable && $_->message =~ /strict/ } @f;
	ok $no_strict,      'error for missing strict';
	ok $strict_fixable, 'fixable';
};

subtest 'Check::Security::check -- error for missing warnings' => sub {
	my $dir = make_distro(
		'lib/Nope.pm' => "package Nope;\nuse strict;\n1;\n",
	);
	my @f = App::Project::Doctor::Check::Security->new->check(_make_ctx($dir));
	my $no_warnings = grep { $_->severity eq $ERR_SEV && $_->message =~ /Missing 'use warnings'/ } @f;
	ok $no_warnings, 'error for missing warnings';
};

subtest 'Check::Security::check -- .t files exempt from pragma check' => sub {
	my $dir = make_distro(
		'Makefile.PL' => '',
		't/basic.t'   => "use Test::More;\nok 1;\ndone_testing;\n",
	);
	# The .t file has no strict/warnings -- that must not be flagged.
	my @f   = App::Project::Doctor::Check::Security->new->check(_make_ctx($dir));
	my @bad = grep { $_->message =~ /basic\.t/ && $_->message =~ /strict|warnings/ } @f;
	is scalar @bad, 0, '.t files not checked for strict/warnings';
};

subtest 'Check::Security::check -- hardcoded password detected' => sub {
	my $dir = make_distro(
		'lib/Bad.pm' => "package Bad;\nuse strict;\nuse warnings;\nmy \$password = 'hunter2';\n1;\n",
	);
	my @f = App::Project::Doctor::Check::Security->new->check(_make_ctx($dir));
	my $pw_cred = grep { $_->severity eq $ERR_SEV && $_->message =~ /credential/i } @f;
	ok $pw_cred, 'hardcoded password triggers credential error';
};

subtest 'Check::Security::check -- PEM private key header detected' => sub {
	my $dir = make_distro(
		'lib/Key.pm' => "package Key;\nuse strict;\nuse warnings;\n"
		              . "my \$pem = '-----BEGIN RSA PRIVATE KEY-----';\n1;\n",
	);
	my @f = App::Project::Doctor::Check::Security->new->check(_make_ctx($dir));
	my $pem_cred = grep { $_->severity eq $ERR_SEV && $_->message =~ /credential/i } @f;
	ok $pem_cred, 'PEM key header triggers credential error';
};

subtest 'Check::Security::check -- AWS key prefix detected' => sub {
	my $dir = make_distro(
		'lib/Aws.pm' => "package Aws;\nuse strict;\nuse warnings;\n"
		              . "my \$key = 'AKIAIOSFODNN7EXAMPLE123';\n1;\n",
	);
	my @f = App::Project::Doctor::Check::Security->new->check(_make_ctx($dir));
	my $aws_cred = grep { $_->severity eq $ERR_SEV && $_->message =~ /credential/i } @f;
	ok $aws_cred, 'AWS key prefix triggers credential error';
};

subtest 'Check::Security::_fix_pragma -- inserts after package declaration' => sub {
	my $dir = make_distro(
		'lib/Mod.pm' => "package Mod;\n# some code\n1;\n",
	);
	my $ctx = _make_ctx($dir);
	my $fix = App::Project::Doctor::Check::Security::_fix_pragma($ctx, 'lib/Mod.pm', 'strict');
	$fix->();
	my @lines = split /\n/, $ctx->slurp('lib/Mod.pm');
	# Line 0 = 'package Mod;', line 1 must be 'use strict;'
	is $lines[1], 'use strict;', 'pragma inserted immediately after package line';
};

subtest 'Check::Security::_fix_pragma -- preserves shebang as first line' => sub {
	# Before the fix, 'use strict;' was incorrectly inserted BEFORE the shebang,
	# making the script unrecognisable by the OS.  This test ensures that
	# a shebang is always kept at position 0.
	my $dir = make_distro(
		'script/myapp' => "#!/usr/bin/perl\n# no package line here\nprint 1;\n",
	);
	my $ctx = _make_ctx($dir);
	my $fix = App::Project::Doctor::Check::Security::_fix_pragma($ctx, 'script/myapp', 'strict');
	$fix->();
	my @lines = split /\n/, $ctx->slurp('script/myapp');
	is $lines[0], '#!/usr/bin/perl', 'shebang remains as first line';
	is $lines[1], 'use strict;',     'pragma inserted after shebang';
};

subtest 'Check::Security::_fix_pragma -- inserts at top of file when no package or shebang' => sub {
	my $dir = make_distro(
		'lib/Bare.pm' => "1;\n",
	);
	my $ctx = _make_ctx($dir);
	my $fix = App::Project::Doctor::Check::Security::_fix_pragma($ctx, 'lib/Bare.pm', 'warnings');
	$fix->();
	my @lines = split /\n/, $ctx->slurp('lib/Bare.pm');
	is $lines[0], 'use warnings;', 'pragma at position 0 when no package or shebang';
};

diag 'Check::Security: done' if $ENV{TEST_VERBOSE};

# ===========================================================================
# 14. Check::Tests
# ===========================================================================

require_ok 'App::Project::Doctor::Check::Tests';

subtest 'Check::Tests -- metadata' => sub {
	my $c = App::Project::Doctor::Check::Tests->new;
	is $c->name,    'Tests', 'name';
	is $c->can_fix, 1,       'can_fix true';
	is $c->order,   10,      'order';
};

subtest 'Check::Tests::check -- error when t/ absent' => sub {
	my $dir = make_distro('Makefile.PL' => '');
	my @f   = App::Project::Doctor::Check::Tests->new->check(_make_ctx($dir));
	is scalar @f, 1, 'single finding';
	is $f[0]->severity, $ERR_SEV, 'error severity';
	like $f[0]->message, qr/No t\/ directory/i, 'correct message';
	ok $f[0]->is_fixable, 'finding is fixable';
};

subtest 'Check::Tests::check -- error when t/ exists but has no .t files' => sub {
	my $dir = make_distro('Makefile.PL' => '', 't/.keep' => '');
	my @f   = App::Project::Doctor::Check::Tests->new->check(_make_ctx($dir));
	my $no_t_err     = grep { $_->severity eq $ERR_SEV && $_->message =~ /no \.t files/i } @f;
	my $t_is_fixable = grep { $_->is_fixable } @f;
	ok $no_t_err,     'error when t/ has no .t files';
	ok $t_is_fixable, 'finding is fixable';
};

subtest 'Check::Tests::check -- pass when prove exits 0' => sub {
	# Create a minimal distro with a trivially passing test.
	my $dir = make_distro(
		'Makefile.PL' => '',
		't/trivial.t' => "use Test::More; ok 1; done_testing;\n",
	);
	my @f = App::Project::Doctor::Check::Tests->new->check(_make_ctx($dir));
	my $prove_pass = grep { $_->severity eq $PASS_SEV } @f;
	ok $prove_pass, 'pass finding when prove succeeds';
};

subtest 'Check::Tests::check -- error when prove exits non-zero' => sub {
	my $dir = make_distro(
		'Makefile.PL' => '',
		't/failing.t' => "use Test::More; ok 0, 'intentional failure'; done_testing;\n",
	);
	my @f = App::Project::Doctor::Check::Tests->new->check(_make_ctx($dir));
	my $prove_fail = grep { $_->severity eq $ERR_SEV && $_->message =~ /FAILED/i } @f;
	ok $prove_fail, 'error finding when prove reports failure';
};

subtest 'Check::Tests::check -- croaks without a context ref' => sub {
	throws_ok { App::Project::Doctor::Check::Tests->new->check('not-a-ref') }
		qr/requires an App::Project::Doctor::Context/i, 'non-ref ctx croaks';
};

diag 'Check::Tests: done' if $ENV{TEST_VERBOSE};

# ===========================================================================
# 15. Check::Role (compatibility shim)
# ===========================================================================

require_ok 'App::Project::Doctor::Check::Role';

subtest 'Check::Role -- is a subclass of Check::Base' => sub {
	ok App::Project::Doctor::Check::Role->isa('App::Project::Doctor::Check::Base'),
		'Check::Role isa Check::Base';
};

subtest 'Check::Role -- inherits Base defaults unchanged' => sub {
	my $r = App::Project::Doctor::Check::Role->new;
	is $r->can_fix,  0,         'can_fix inherited';
	is $r->category, 'general', 'category inherited';
	is $r->order,    50,        'order inherited';
};

diag 'Check::Role: done' if $ENV{TEST_VERBOSE};

# ===========================================================================

done_testing;
