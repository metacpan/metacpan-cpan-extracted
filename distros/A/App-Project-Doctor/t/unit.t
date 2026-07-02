# t/unit.t -- Black-box unit tests, one subtest per documented public API.
#
# Strategy: every test asserts a contract stated in the module's POD, not an
# implementation detail.  Internal helpers (_collect_files, _worst_severity,
# etc.) are tested separately in t/function.t.
#
# Libraries:
#   Test::Most        -- strict mode + Test::More + Test::Exception exports
#   Test::Mockingbird -- mock_scoped / spy / mock_return / mock_exception
#   Test::Returns     -- returns_ok / returns_not_ok (schema validation)

use strict;
use warnings;

use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use File::Temp  qw(tempdir);
use File::Spec;
use File::Path  qw(make_path);
use Readonly;
use Scalar::Util qw(blessed);

# ---------------------------------------------------------------------------
# Test constants -- every magic string lives here, not in the subtests.
# ---------------------------------------------------------------------------

Readonly::Scalar my $SEV_ERROR => 'error';
Readonly::Scalar my $SEV_WARN  => 'warning';
Readonly::Scalar my $SEV_PASS  => 'pass';
Readonly::Scalar my $SEV_INFO  => 'info';

Readonly::Hash my %ICON_FOR => (
	$SEV_ERROR => '[X]',
	$SEV_WARN  => '[!]',
	$SEV_PASS  => '[v]',
	$SEV_INFO  => '[i]',
);

Readonly::Scalar my $DEFAULT_CHECK_NAME => 'Unknown';
Readonly::Scalar my $DEFAULT_CATEGORY   => 'general';
Readonly::Scalar my $DEFAULT_ORDER      => 50;

# ---------------------------------------------------------------------------
# Shared helpers
# ---------------------------------------------------------------------------

# Create a temporary distribution directory tree from a flat path=>content map.
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

# Build a minimal Finding, defaulting check_name so callers can omit it.
sub _f {
	require App::Project::Doctor::Finding;
	return App::Project::Doctor::Finding->new(check_name => 'Unit', @_);
}

# Build a minimal Context over an optional tempdir.
sub _ctx {
	require App::Project::Doctor::Context;
	return App::Project::Doctor::Context->new(root => shift // tempdir(CLEANUP => 1));
}

diag "Perl $]" if $ENV{TEST_VERBOSE};

# ===========================================================================
# 1. App::Project::Doctor::Finding
# ===========================================================================

require_ok 'App::Project::Doctor::Finding';

# --- Constructor and accessors ---------------------------------------------

subtest 'Finding::new -- documented defaults when only message supplied' => sub {
	# POD: severity defaults to 'info', check_name to 'Unknown',
	#      detail to '', file to '', line undef.
	my $f = App::Project::Doctor::Finding->new(message => 'minimal');
	is  $f->severity,   $SEV_INFO,           'severity defaults to info';
	is  $f->check_name, $DEFAULT_CHECK_NAME, 'check_name defaults to Unknown';
	is  $f->detail,     '',                  'detail defaults to empty string';
	is  $f->file,       '',                  'file defaults to empty string';
	ok !defined $f->line,                    'line is undef by default';
};

subtest 'Finding::new -- all documented fields round-trip through accessors' => sub {
	my $cref = sub { 1 };
	my $f = App::Project::Doctor::Finding->new(
		severity   => $SEV_ERROR,
		message    => 'broken',
		detail     => 'extended',
		fix        => $cref,
		check_name => 'Tests',
		file       => 'lib/A.pm',
		line       => 7,
	);
	is $f->severity,   $SEV_ERROR,   'severity';
	is $f->message,    'broken',     'message';
	is $f->detail,     'extended',   'detail';
	is $f->check_name, 'Tests',      'check_name';
	is $f->file,       'lib/A.pm',   'file';
	is $f->line,       7,            'line';
	is $f->fix,        $cref,        'fix coderef identity preserved';
};

subtest 'Finding::new -- invalid severity croaks naming the bad value' => sub {
	# POD: "Croaks on invalid severity."
	# Code: croak "Invalid severity '$args{severity}'"
	throws_ok {
		App::Project::Doctor::Finding->new(severity => 'critical', message => 'x')
	} qr/Invalid severity 'critical'/, 'severity name echoed in croak';

	throws_ok {
		App::Project::Doctor::Finding->new(severity => '', message => 'x')
	} qr/Invalid severity ''/, 'empty severity croaks';

	throws_ok {
		App::Project::Doctor::Finding->new(severity => 'ERROR', message => 'x')
	} qr/Invalid severity 'ERROR'/, 'case mismatch is invalid';
};

subtest 'Finding::new -- empty or undef message croaks with documented text' => sub {
	# Code: croak 'message must be a non-empty string'
	throws_ok {
		App::Project::Doctor::Finding->new(message => '')
	} qr/message must be a non-empty string/, 'empty message croaks';

	throws_ok {
		App::Project::Doctor::Finding->new(message => undef)
	} qr/message must be a non-empty string/, 'undef message croaks';
};

subtest 'Finding::new -- line must be a positive integer per POD' => sub {
	# POD: "line : positive Integer  optional"
	throws_ok {
		App::Project::Doctor::Finding->new(message => 'x', line => 0)
	} qr//i, 'line=0 is not positive -- rejected';

	throws_ok {
		App::Project::Doctor::Finding->new(message => 'x', line => -1)
	} qr//i, 'negative line rejected';

	# line=1 is the minimum positive integer -- must succeed.
	lives_ok {
		App::Project::Doctor::Finding->new(message => 'x', line => 1)
	} 'line=1 accepted';
};

subtest 'Finding::new -- does not disturb $@ after successful construction' => sub {
	# Global-state integrity: constructor uses eval internally; $@ must be
	# restored on the way out so callers are not confused.
	local $@ = 'pre-existing error';
	App::Project::Doctor::Finding->new(message => 'ok');
	is $@, 'pre-existing error', '$@ unchanged after Finding->new';
};

# --- is_fixable -----------------------------------------------------------

subtest 'Finding::is_fixable -- returns exactly 1 or 0, not just truthy' => sub {
	# POD: "Returns 1 when fix is defined, 0 otherwise."
	my $without = _f(message => 'no fix');
	is $without->is_fixable, 0, 'exactly 0 when no coderef';
	returns_ok($without->is_fixable, { type => 'integer' }, 'is_fixable type integer');

	my $with = _f(message => 'has fix', fix => sub {});
	is $with->is_fixable, 1, 'exactly 1 when coderef present';
	returns_ok($with->is_fixable, { type => 'integer' }, 'is_fixable type integer');
};

subtest 'Finding::has_fix -- accessor agrees with is_fixable' => sub {
	ok !_f(message => 'x')->has_fix,         'has_fix false without coderef';
	ok  _f(message => 'y', fix => sub {})->has_fix, 'has_fix true with coderef';
};

# --- icon -----------------------------------------------------------------

subtest 'Finding::icon -- exact documented strings for all four severities' => sub {
	# POD: "[v] pass  [X] error  [!] warning  [i] info"
	for my $sev (sort keys %ICON_FOR) {
		my $f = _f(severity => $sev, message => 'x');
		is $f->icon, $ICON_FOR{$sev},
			"icon for $sev is '$ICON_FOR{$sev}'";
		returns_ok($f->icon, { type => 'scalar' }, "icon returns scalar for $sev");
	}
};

# --- to_hash --------------------------------------------------------------

subtest 'Finding::to_hash -- documented keys present, fix excluded' => sub {
	# POD: "HashRef with keys: severity, message, detail, check_name, file,
	#       line (if set). fix is excluded."
	my $f = _f(
		severity   => $SEV_PASS,
		message    => 'good',
		detail     => 'noted',
		check_name => 'Meta',
		file       => 'META.yml',
		fix        => sub {},        # must NOT appear in hash
	);
	my $h = $f->to_hash;
	returns_ok($h, { type => 'hashref' }, 'to_hash returns hashref');
	ok !exists $h->{fix},       'fix key absent';
	is $h->{severity},   $SEV_PASS,  'severity present';
	is $h->{message},    'good',     'message present';
	is $h->{detail},     'noted',    'detail present';
	is $h->{check_name}, 'Meta',     'check_name present';
	is $h->{file},       'META.yml', 'file present';
};

subtest 'Finding::to_hash -- line key present only when line was set' => sub {
	my $with = _f(message => 'x', line => 42);
	ok exists $with->to_hash->{line}, 'line key present when set';
	is $with->to_hash->{line}, 42, 'line value correct';

	my $without = _f(message => 'y');
	ok !exists $without->to_hash->{line}, 'line key absent when not set';
};

diag 'Finding: OK' if $ENV{TEST_VERBOSE};

# ===========================================================================
# 2. App::Project::Doctor::Context
# ===========================================================================

require_ok 'App::Project::Doctor::Context';

# --- Constructor ----------------------------------------------------------

subtest 'Context::new -- default root (.) must be accepted' => sub {
	lives_ok { App::Project::Doctor::Context->new } 'no args construction succeeds';
};

subtest 'Context::new -- root accessor returns absolute path' => sub {
	# POD: root is normalised to absolute.
	my $dir = tempdir(CLEANUP => 1);
	my $ctx = App::Project::Doctor::Context->new(root => $dir);
	ok(File::Spec->file_name_is_absolute($ctx->root), 'root is absolute');
};

subtest 'Context::new -- verbose stored correctly' => sub {
	my $dir = tempdir(CLEANUP => 1);
	is(App::Project::Doctor::Context->new(root => $dir, verbose => 1)->verbose, 1, 'verbose 1');
	is(App::Project::Doctor::Context->new(root => $dir, verbose => 0)->verbose, 0, 'verbose 0');
};

subtest 'Context::new -- non-directory root croaks "not a directory"' => sub {
	# POD: "Croaks when root is not an existing directory."
	# Code: croak "root '$args{root}' is not a directory"
	throws_ok {
		App::Project::Doctor::Context->new(root => '/no/such/xyzzy99')
	} qr/not a directory/i, 'non-existent path croaks';

	my $tmp  = tempdir(CLEANUP => 1);
	my $file = File::Spec->catfile($tmp, 'f.txt');
	open my $fh, '>', $file; close $fh;
	throws_ok {
		App::Project::Doctor::Context->new(root => $file)
	} qr/not a directory/i, 'regular file path croaks';
};

# --- has_file -------------------------------------------------------------

subtest 'Context::has_file -- true for present, false for absent' => sub {
	# POD: "Returns true when rel_path (relative to root) exists on disk."
	my $dir = make_distro('Makefile.PL' => '');
	my $ctx = _ctx($dir);
	ok  $ctx->has_file('Makefile.PL'), 'true for existing file';
	ok !$ctx->has_file('no-such'),     'false for absent file';
};

subtest 'Context::has_file -- undef arg croaks' => sub {
	# Code: croak 'has_file requires a relative path'
	throws_ok { _ctx()->has_file(undef) }
		qr/has_file requires a relative path/i, 'undef arg croaks';
};

# --- abs_path -------------------------------------------------------------

subtest 'Context::abs_path -- returns an absolute path containing the input tail' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $abs = _ctx($dir)->abs_path('lib/Foo.pm');
	ok(File::Spec->file_name_is_absolute($abs), 'result is absolute');
	like $abs, qr/lib.Foo\.pm$/,                'tail matches input';
	returns_ok($abs, { type => 'scalar' },      'abs_path returns scalar');
};

subtest 'Context::abs_path -- undef arg croaks' => sub {
	# Code: croak 'abs_path requires a relative path'
	throws_ok { _ctx()->abs_path(undef) }
		qr/abs_path requires a relative path/i, 'undef arg croaks';
};

# --- slurp ----------------------------------------------------------------

subtest 'Context::slurp -- returns full UTF-8 content verbatim' => sub {
	my $dir = make_distro('README' => "hello world\n");
	my $got = _ctx($dir)->slurp('README');
	is $got, "hello world\n", 'content verbatim';
	returns_ok($got, { type => 'scalar' }, 'slurp returns scalar');
};

subtest 'Context::slurp -- missing file croaks "File not found"' => sub {
	# POD: "Croaks if the file does not exist."
	# Code: croak "File not found: $abs"
	throws_ok { _ctx()->slurp('absent.txt') }
		qr/File not found/i, 'missing file croaks';
};

subtest 'Context::slurp -- undef arg croaks' => sub {
	# Code: croak 'slurp requires a relative path'
	throws_ok { _ctx()->slurp(undef) }
		qr/slurp requires a relative path/i, 'undef arg croaks';
};

subtest 'Context::slurp -- does not clobber $/ (global state integrity)' => sub {
	# slurp uses "local $/" internally; $/ must be restored when it returns.
	my $dir = make_distro('data.txt' => "a\nb\n");
	my $sep = $/;
	_ctx($dir)->slurp('data.txt');
	is $/, $sep, '$/ unchanged after slurp';
};

# --- perl_files -----------------------------------------------------------

subtest 'Context::perl_files -- returns arrayref containing .pm .pl .t .PL only' => sub {
	# POD: "(.pm .pl .t .PL) found recursively"
	my $dir = make_distro(
		'lib/Mod.pm'  => '',
		'lib/run.pl'  => '',
		't/test.t'    => '',
		'lib/Gen.PL'  => '',
		'lib/data.txt'=> '',   # must be excluded
		'lib/cfg.yaml'=> '',   # must be excluded
	);
	my $files = _ctx($dir)->perl_files('lib', 't');
	returns_ok($files, { type => 'arrayref' }, 'perl_files returns arrayref');
	my %seen = map { $_ => 1 } @{$files};
	ok  $seen{'lib/Mod.pm'},  '.pm included';
	ok  $seen{'lib/run.pl'},  '.pl included';
	ok  $seen{'t/test.t'},    '.t included';
	ok  $seen{'lib/Gen.PL'},  '.PL included';
	ok !$seen{'lib/data.txt'},'non-Perl .txt excluded';
	ok !$seen{'lib/cfg.yaml'},'non-Perl .yaml excluded';
};

subtest 'Context::perl_files -- defaults to lib/ script/ bin/ t/' => sub {
	# POD: "Defaults to lib/, script/, bin/, t/."
	my $dir = make_distro(
		'lib/A.pm'      => '',
		't/b.t'         => '',
		'script/run.pl' => '',
	);
	my %seen = map { $_ => 1 } @{ _ctx($dir)->perl_files };
	ok $seen{'lib/A.pm'},      'lib/ searched by default';
	ok $seen{'t/b.t'},         't/ searched by default';
	ok $seen{'script/run.pl'}, 'script/ searched by default';
};

# --- lib_modules ----------------------------------------------------------

subtest 'Context::lib_modules -- only .pm files under lib/' => sub {
	# POD: "ArrayRef[String] -- .pm files under lib/."
	my $dir = make_distro(
		'lib/Foo.pm' => '',
		'lib/bar.pl' => '',
		't/c.t'      => '',
	);
	my $mods     = _ctx($dir)->lib_modules;
	returns_ok($mods, { type => 'arrayref' }, 'lib_modules returns arrayref');
	my $has_pm   = grep { /\.pm$/ } @{$mods};
	my $has_pl   = grep { /\.pl$/ } @{$mods};
	my $has_t    = grep { /\.t$/  } @{$mods};
	ok  $has_pm, '.pm returned';
	ok !$has_pl, '.pl excluded';
	ok !$has_t,  '.t excluded';
};

# --- test_files -----------------------------------------------------------

subtest 'Context::test_files -- only .t files under t/' => sub {
	# POD: "ArrayRef[String] -- .t files under t/."
	my $dir = make_distro(
		't/a.t'    => '',
		't/b.t'    => '',
		'lib/c.pm' => '',
	);
	my $tests      = _ctx($dir)->test_files;
	returns_ok($tests, { type => 'arrayref' }, 'test_files returns arrayref');
	is scalar @{$tests}, 2, 'two .t files';
	my $non_t_count = grep { !/\.t$/ } @{$tests};
	ok !$non_t_count, 'no non-.t files in result';
};

# --- git_root -------------------------------------------------------------

subtest 'Context::git_root -- returns String when inside a repo, undef outside' => sub {
	# POD: "Returns the git repository root, or undef if not in a git repo."
	my $ctx = _ctx();
	{
		my $g = mock_scoped 'App::Project::Doctor::Context::git_root' => sub { '/repo' };
		my $r = $ctx->git_root;
		ok defined $r, 'defined string returned when in a repo';
		returns_ok($r, { type => 'scalar' }, 'git_root returns scalar');
	}
	{
		my $g = mock_scoped 'App::Project::Doctor::Context::git_root' => sub { undef };
		ok !defined $ctx->git_root, 'undef returned when not in a repo';
	}
};

subtest 'Context::git_root -- does not reset a pending alarm()' => sub {
	# Global-state integrity: git_root shells out; it must not call alarm(0).
	# Use a 3-second alarm with a local no-op handler so the test cannot block
	# the suite if the mock fails.
	SKIP: {
		skip 'alarm() is not available on Windows', 2 if $^O eq 'MSWin32';
		my $fired = 0;
		local $SIG{ALRM} = sub { $fired = 1; alarm(0) };
		my $ctx = _ctx();
		alarm(3);
		{
			my $g = mock_scoped 'App::Project::Doctor::Context::git_root' => sub { undef };
			$ctx->git_root;
		}
		my $remaining = alarm(0);
		ok !$fired,         'alarm did not fire during git_root call';
		ok $remaining >= 1, "alarm still had $remaining s remaining -- git_root did not call alarm()";
	}
};

# --- builder_file ---------------------------------------------------------

subtest 'Context::builder_file -- detects each documented marker' => sub {
	# POD: "first found of Makefile.PL Build.PL dist.ini cpanfile"
	for my $marker (qw(Makefile.PL Build.PL dist.ini cpanfile)) {
		my $dir = make_distro($marker => '');
		is _ctx($dir)->builder_file, $marker, "detects $marker";
	}
};

subtest 'Context::builder_file -- Makefile.PL takes priority over all others' => sub {
	my $dir = make_distro(
		'Makefile.PL' => '',
		'cpanfile'    => '',
		'dist.ini'    => '',
	);
	is _ctx($dir)->builder_file, 'Makefile.PL', 'Makefile.PL wins';
};

subtest 'Context::builder_file -- returns undef when no builder present' => sub {
	is _ctx(tempdir(CLEANUP => 1))->builder_file, undef, 'undef when absent';
};

# --- find_files -----------------------------------------------------------

subtest 'Context::find_files -- string suffix pattern' => sub {
	my $dir = make_distro(
		'.github/workflows/ci.yml'  => '',
		'.github/workflows/rel.yml' => '',
		'.github/CODEOWNERS'        => '',
	);
	my $found      = _ctx($dir)->find_files('.github/workflows', '.yml');
	returns_ok($found, { type => 'arrayref' }, 'find_files returns arrayref');
	is scalar @{$found}, 2, 'two .yml files found';
	my $non_yml    = grep { !/\.yml$/ } @{$found};
	ok !$non_yml, 'no non-.yml files';
};

subtest 'Context::find_files -- compiled Regexp pattern' => sub {
	my $dir = make_distro(
		'.github/workflows/ci.yaml' => '',
		'.github/workflows/ci.yml'  => '',
		'.github/CODEOWNERS'        => '',
	);
	my $found = _ctx($dir)->find_files('.github/workflows', qr/\.ya?ml$/i);
	is scalar @{$found}, 2, 'Regexp matches .yml and .yaml';
};

subtest 'Context::find_files -- undef pattern returns all files in dir' => sub {
	my $dir = make_distro(
		'.github/workflows/a.yml' => '',
		'.github/workflows/b.txt' => '',
	);
	my $found = _ctx($dir)->find_files('.github/workflows', undef);
	is scalar @{$found}, 2, 'undef pattern = all files';
};

subtest 'Context::find_files -- undef dir arg croaks' => sub {
	# Code: croak 'find_files requires a directory'
	throws_ok { _ctx()->find_files(undef) }
		qr/find_files requires a directory/i, 'undef dir croaks';
};

diag 'Context: OK' if $ENV{TEST_VERBOSE};

# ===========================================================================
# 3. App::Project::Doctor::Check::Base
# ===========================================================================

require_ok 'App::Project::Doctor::Check::Base';

subtest 'Check::Base::new -- creates blessed object' => sub {
	isa_ok App::Project::Doctor::Check::Base->new,
		'App::Project::Doctor::Check::Base';
};

subtest 'Check::Base::name -- croaks naming the calling class' => sub {
	# POD: "Calling name ... on an instance that has not overridden them will
	#       croak at runtime with a clear message."
	# Code: croak ref(shift) . ' must implement name()'
	my $b = App::Project::Doctor::Check::Base->new;
	throws_ok { $b->name }
		qr/App::Project::Doctor::Check::Base must implement name\(\)/,
		'croak text includes class name and method signature';
};

subtest 'Check::Base::description -- croaks naming the calling class' => sub {
	throws_ok { App::Project::Doctor::Check::Base->new->description }
		qr/App::Project::Doctor::Check::Base must implement description\(\)/,
		'croak text includes class name';
};

subtest 'Check::Base::check -- croaks naming the calling class' => sub {
	throws_ok { App::Project::Doctor::Check::Base->new->check }
		qr/App::Project::Doctor::Check::Base must implement check\(\)/,
		'croak text includes class name';
};

subtest 'Check::Base -- optional methods return documented defaults' => sub {
	# POD: can_fix=0, category='general', order=50
	my $b = App::Project::Doctor::Check::Base->new;
	is $b->can_fix,  0,                  'can_fix default exactly 0';
	is $b->category, $DEFAULT_CATEGORY,  'category default "general"';
	is $b->order,    $DEFAULT_ORDER,     'order default 50';
	returns_ok($b->can_fix,  { type => 'integer' }, 'can_fix returns integer');
	returns_ok($b->order,    { type => 'integer' }, 'order returns integer');
	returns_ok($b->category, { type => 'scalar'  }, 'category returns scalar');
};

subtest 'Check::Base -- croak message names the subclass, not Base' => sub {
	# POD: "will croak at runtime with a clear message" -- the message must
	# name the subclass so the developer knows where to add the implementation.
	{
		package My::PartialCheck;
		use parent -norequire, 'App::Project::Doctor::Check::Base';
		sub name        { 'Partial' }
		sub description { 'No check() yet.' }
		# check() absent
	}
	throws_ok { My::PartialCheck->new->check }
		qr/My::PartialCheck must implement check/,
		'subclass name in croak, not Check::Base';
};

subtest 'Check::Base -- subclass can override every optional method' => sub {
	{
		package My::FullCheck;
		use parent -norequire, 'App::Project::Doctor::Check::Base';
		sub name        { 'Full' }
		sub description { 'Complete.' }
		sub check       { () }
		sub can_fix     { 1 }
		sub category    { 'ci' }
		sub order       { 99 }
	}
	my $c = My::FullCheck->new;
	is $c->name,        'Full',      'overridden name';
	is $c->description, 'Complete.', 'overridden description';
	is $c->can_fix,     1,           'overridden can_fix';
	is $c->category,    'ci',        'overridden category';
	is $c->order,       99,          'overridden order';
};

diag 'Check::Base: OK' if $ENV{TEST_VERBOSE};

# ===========================================================================
# 4. App::Project::Doctor::Report
# ===========================================================================

require_ok 'App::Project::Doctor::Report';

subtest 'Report::new -- starts empty with exit_code 0' => sub {
	my $r = App::Project::Doctor::Report->new;
	isa_ok $r, 'App::Project::Doctor::Report';
	is scalar($r->all_findings), 0, 'all_findings empty at construction';
	is $r->exit_code,            0, 'exit_code 0 when clean';
	ok !$r->has_errors,             'has_errors false initially';
	ok !$r->has_warnings,           'has_warnings false initially';
};

subtest 'Report::add_findings -- returns $self for chaining' => sub {
	# POD: "Returns $self for chaining."
	my $r   = App::Project::Doctor::Report->new;
	my $ret = $r->add_findings(_f(severity => $SEV_PASS, message => 'ok'));
	is $ret, $r, 'returns $self';
};

subtest 'Report::add_findings -- rejects non-Finding with documented croak text' => sub {
	# Code: croak 'Expected an App::Project::Doctor::Finding'
	my $r = App::Project::Doctor::Report->new;
	throws_ok { $r->add_findings('string') }
		qr/Expected an App::Project::Doctor::Finding/,
		'plain string rejected';
	throws_ok { $r->add_findings({}) }
		qr/Expected an App::Project::Doctor::Finding/,
		'hashref rejected';
	throws_ok { $r->add_findings(undef) }
		qr/Expected an App::Project::Doctor::Finding/,
		'undef rejected';
};

subtest 'Report -- filter methods partition findings correctly' => sub {
	my $r = App::Project::Doctor::Report->new;
	$r->add_findings(
		_f(severity => $SEV_ERROR, message => 'e1'),
		_f(severity => $SEV_ERROR, message => 'e2'),
		_f(severity => $SEV_WARN,  message => 'w1'),
		_f(severity => $SEV_PASS,  message => 'p1'),
		_f(severity => $SEV_INFO,  message => 'i1'),
		_f(severity => $SEV_ERROR, message => 'fx', fix => sub {}),
	);
	is scalar($r->errors),   3, 'errors() count';
	is scalar($r->warnings), 1, 'warnings() count';
	is scalar($r->passes),   1, 'passes() count';
	is scalar($r->fixable),  1, 'fixable() count (only error-with-fix)';
	is scalar($r->all_findings), 6, 'all_findings() count';
};

subtest 'Report::has_errors / has_warnings -- return exactly 1 or 0' => sub {
	my $r_clean = App::Project::Doctor::Report->new;
	$r_clean->add_findings(_f(severity => $SEV_PASS, message => 'ok'));
	is $r_clean->has_errors,   0, 'has_errors exactly 0 when no errors';
	is $r_clean->has_warnings, 0, 'has_warnings exactly 0 when no warnings';

	my $r_bad = App::Project::Doctor::Report->new;
	$r_bad->add_findings(
		_f(severity => $SEV_ERROR, message => 'e'),
		_f(severity => $SEV_WARN,  message => 'w'),
	);
	is $r_bad->has_errors,   1, 'has_errors exactly 1';
	is $r_bad->has_warnings, 1, 'has_warnings exactly 1';
};

subtest 'Report::exit_code -- 0 for warnings-only, 1 for errors' => sub {
	# POD: "Returns 0 (clean) or 1 (errors present)."
	my $r_warn = App::Project::Doctor::Report->new;
	$r_warn->add_findings(_f(severity => $SEV_WARN, message => 'w'));
	is $r_warn->exit_code, 0, 'warnings alone give exit_code 0';

	my $r_err = App::Project::Doctor::Report->new;
	$r_err->add_findings(_f(severity => $SEV_ERROR, message => 'e'));
	is $r_err->exit_code, 1, 'errors give exit_code 1';
	returns_ok($r_err->exit_code, { type => 'integer' }, 'exit_code returns integer');
};

subtest 'Report::render_text -- uses worst-severity icon per check group' => sub {
	# POD: groups by check_name; icon reflects the worst finding in the group.
	my $r = App::Project::Doctor::Report->new;
	$r->add_findings(
		_f(severity => $SEV_PASS,  message => 'clean', check_name => 'Tests'),
		_f(severity => $SEV_ERROR, message => 'broke', check_name => 'Tests'),
	);
	my $text = $r->render_text;
	returns_ok($text, { type => 'scalar' }, 'render_text returns scalar');
	like $text, qr/\[X\].*Tests/, 'error icon shown (worst wins over pass)';
	like $text, qr/1 error\(s\)/, 'error count in summary';
};

subtest 'Report::render_text -- verbose exposes detail; non-verbose hides it' => sub {
	my $r = App::Project::Doctor::Report->new;
	$r->add_findings(_f(
		severity   => $SEV_ERROR,
		message    => 'Problem',
		detail     => 'Extended explanation',
		check_name => 'Pod',
	));
	unlike $r->render_text(verbose => 0), qr/Extended explanation/,
		'detail hidden in non-verbose mode';
	like $r->render_text(verbose => 1), qr/Extended explanation/,
		'detail shown in verbose mode';
};

subtest 'Report::render_text -- fix prompt only when fixable findings exist' => sub {
	my $r_fix = App::Project::Doctor::Report->new;
	$r_fix->add_findings(_f(
		severity   => $SEV_ERROR,
		message    => 'Fixme',
		check_name => 'CI',
		fix        => sub {},
	));
	like $r_fix->render_text, qr/Suggested fixes:/, 'fix list header present';
	like $r_fix->render_text, qr/Would you like me to apply/, 'prompt present';

	my $r_nof = App::Project::Doctor::Report->new;
	$r_nof->add_findings(_f(severity => $SEV_PASS, message => 'ok', check_name => 'CI'));
	unlike $r_nof->render_text, qr/Suggested fixes:/, 'no fix list when unfixable';
};

subtest 'Report::render_text -- "No errors or warnings" when fully clean' => sub {
	my $r = App::Project::Doctor::Report->new;
	$r->add_findings(_f(severity => $SEV_PASS, message => 'ok', check_name => 'A'));
	like $r->render_text, qr/No errors or warnings/, 'clean summary text';
};

subtest 'Report::render_json -- parseable UTF-8 JSON; fix excluded' => sub {
	# POD: "Returns findings as a pretty-printed JSON string."
	my $r = App::Project::Doctor::Report->new;
	$r->add_findings(_f(
		severity   => $SEV_INFO,
		message    => 'noted',
		check_name => 'Meta',
		fix        => sub {},
	));
	my $json = $r->render_json;
	returns_ok($json, { type => 'scalar' }, 'render_json returns scalar');
	require JSON::MaybeXS;
	my $decoded = JSON::MaybeXS->new->decode($json);
	is ref $decoded, 'ARRAY', 'decodes to arrayref';
	ok !exists $decoded->[0]{fix},        'fix key absent from JSON';
	is $decoded->[0]{severity},   'info', 'severity in JSON';
	is $decoded->[0]{check_name}, 'Meta', 'check_name in JSON';
};

subtest 'Report::render_tap -- plan line; pass/info = ok, error/warning = not ok' => sub {
	# POD: "Returns a TAP-format string for CI pipeline consumption."
	my $r = App::Project::Doctor::Report->new;
	$r->add_findings(
		_f(severity => $SEV_PASS,  message => 'p', check_name => 'A'),
		_f(severity => $SEV_INFO,  message => 'i', check_name => 'B'),
		_f(severity => $SEV_WARN,  message => 'w', check_name => 'C'),
		_f(severity => $SEV_ERROR, message => 'e', check_name => 'D'),
	);
	my $tap = $r->render_tap;
	returns_ok($tap, { type => 'scalar' }, 'render_tap returns scalar');
	like $tap, qr/^1\.\.4/m,   'plan line present and correct';
	like $tap, qr/^ok 1/m,     'pass = ok';
	like $tap, qr/^ok 2/m,     'info = ok';
	like $tap, qr/^not ok 3/m, 'warning = not ok';
	like $tap, qr/^not ok 4/m, 'error = not ok';
};

diag 'Report: OK' if $ENV{TEST_VERBOSE};

# ===========================================================================
# 5. App::Project::Doctor::Fixer
# ===========================================================================

require_ok 'App::Project::Doctor::Fixer';

# Build a real Context once -- Fixer::new validates the type.
Readonly::Scalar my $FIXER_DIR => make_distro('Makefile.PL' => '');
my $FIXER_CTX = _ctx($FIXER_DIR);

subtest 'Fixer::new -- stores all documented accessors' => sub {
	# POD: accessors: report, context, non_interactive (default 0)
	my $r  = App::Project::Doctor::Report->new;
	my $fx = App::Project::Doctor::Fixer->new(report => $r, context => $FIXER_CTX);
	isa_ok $fx, 'App::Project::Doctor::Fixer';
	is $fx->report,          $r,         'report accessor';
	is $fx->context,         $FIXER_CTX, 'context accessor';
	is $fx->non_interactive, 0,          'non_interactive defaults to 0';
};

subtest 'Fixer::new -- wrong type for report or context is rejected' => sub {
	my $r = App::Project::Doctor::Report->new;
	throws_ok {
		App::Project::Doctor::Fixer->new(report => 'string', context => $FIXER_CTX)
	} qr//i, 'non-Report object for report rejected';
	throws_ok {
		App::Project::Doctor::Fixer->new(report => $r, context => 'string')
	} qr//i, 'non-Context object for context rejected';
};

subtest 'Fixer::run -- returns 0 immediately when no fixable findings' => sub {
	# POD: "Returns the count of fixes applied."
	my $r = App::Project::Doctor::Report->new;
	$r->add_findings(_f(severity => $SEV_PASS, message => 'ok'));
	my $fx    = App::Project::Doctor::Fixer->new(
		report => $r, context => $FIXER_CTX, non_interactive => 1
	);
	my $count = $fx->run;
	is $count, 0, 'returns 0 with no fixable findings';
	returns_ok($count, { type => 'integer' }, 'run returns integer');
};

subtest 'Fixer::run -- non_interactive applies all fixable, returns count' => sub {
	my $applied = 0;
	my $r = App::Project::Doctor::Report->new;
	$r->add_findings(
		_f(severity => $SEV_ERROR, message => 'f1', fix => sub { $applied++ }),
		_f(severity => $SEV_ERROR, message => 'f2', fix => sub { $applied++ }),
		_f(severity => $SEV_PASS,  message => 'np'),   # no fix -- ignored
	);
	my $fx = App::Project::Doctor::Fixer->new(
		report => $r, context => $FIXER_CTX, non_interactive => 1
	);
	is $fx->run, 2, 'count of applied fixes returned';
	is $applied,  2, 'both coderefs called';
};

subtest 'Fixer::run -- throwing fix is caught and carped; run continues' => sub {
	# POD message F001: "A fix coderef throws -- Fix skipped; error logged via carp"
	my $second_ok = 0;
	my $r = App::Project::Doctor::Report->new;
	$r->add_findings(
		_f(severity => $SEV_ERROR, message => 'boom', fix => sub { die "exploded!\n" }),
		_f(severity => $SEV_ERROR, message => 'fine', fix => sub { $second_ok++ }),
	);
	my $fx = App::Project::Doctor::Fixer->new(
		report => $r, context => $FIXER_CTX, non_interactive => 1
	);
	my $count;
	warning_like { $count = $fx->run } qr/exploded/i,
		'exception in fix emitted as carp';
	is $count,     1, 'count reflects only successful fix';
	is $second_ok, 1, 'second fix ran despite first failure';
};

subtest 'Fixer::run -- interactive: Y/y/yes/empty applies all' => sub {
	for my $yes ('Y', 'y', 'yes', '') {
		my $applied = 0;
		my $r = App::Project::Doctor::Report->new;
		$r->add_findings(_f(severity => $SEV_ERROR, message => 'm', fix => sub { $applied++ }));
		my $fx = App::Project::Doctor::Fixer->new(report => $r, context => $FIXER_CTX);
		open my $in, '<', \"$yes\n";
		local *STDIN = *$in;
		$fx->run;
		is $applied, 1, "answer '$yes' applied fix";
	}
};

subtest 'Fixer::run -- interactive: n/N/no/No skips all and returns 0' => sub {
	for my $no ('n', 'N', 'no', 'No') {
		my $applied = 0;
		my $r = App::Project::Doctor::Report->new;
		$r->add_findings(_f(severity => $SEV_ERROR, message => 'm', fix => sub { $applied++ }));
		my $fx = App::Project::Doctor::Fixer->new(report => $r, context => $FIXER_CTX);
		open my $in, '<', \"$no\n";
		local *STDIN = *$in;
		is $fx->run, 0, "answer '$no' returns 0";
		is $applied,  0, "answer '$no' did not call fix";
	}
};

subtest 'Fixer::run -- interactive: comma-separated indices select specific fixes' => sub {
	my @ran = (0, 0, 0);
	my $r = App::Project::Doctor::Report->new;
	$r->add_findings(
		_f(severity => $SEV_ERROR, message => 'a', fix => sub { $ran[0]++ }),
		_f(severity => $SEV_ERROR, message => 'b', fix => sub { $ran[1]++ }),
		_f(severity => $SEV_ERROR, message => 'c', fix => sub { $ran[2]++ }),
	);
	my $fx = App::Project::Doctor::Fixer->new(report => $r, context => $FIXER_CTX);
	open my $in, '<', \"1,3\n";
	local *STDIN = *$in;
	is $fx->run, 2,  '1,3 -> two fixes applied';
	is $ran[0],  1,  'fix 1 ran';
	is $ran[1],  0,  'fix 2 skipped';
	is $ran[2],  1,  'fix 3 ran';
};

subtest 'Fixer::run -- interactive: EOF returns 0 without calling any fix' => sub {
	my $applied = 0;
	my $r = App::Project::Doctor::Report->new;
	$r->add_findings(_f(severity => $SEV_ERROR, message => 'x', fix => sub { $applied++ }));
	my $fx = App::Project::Doctor::Fixer->new(report => $r, context => $FIXER_CTX);
	open my $in, '<', \'';
	local *STDIN = *$in;
	is $fx->run, 0, 'EOF returns 0';
	is $applied,  0, 'fix not called';
};

subtest 'Fixer::run -- interactive: unrecognised input returns 0' => sub {
	my $applied = 0;
	my $r = App::Project::Doctor::Report->new;
	$r->add_findings(_f(severity => $SEV_ERROR, message => 'x', fix => sub { $applied++ }));
	my $fx = App::Project::Doctor::Fixer->new(report => $r, context => $FIXER_CTX);
	open my $in, '<', \"??!\n";
	local *STDIN = *$in;
	is $fx->run, 0, 'garbage returns 0';
	is $applied,  0, 'fix not called';
};

diag 'Fixer: OK' if $ENV{TEST_VERBOSE};

# ===========================================================================
# 6. App::Project::Doctor (orchestrator)
# ===========================================================================

require_ok 'App::Project::Doctor';

subtest 'Doctor::new -- documented defaults' => sub {
	# POD: path='.', checks=[all], skip=[], verbose=0
	my $d = App::Project::Doctor->new;
	is $d->path,    '.',  'path defaults to .';
	is $d->verbose, 0,    'verbose defaults to 0';
	ok ref($d->checks) eq 'ARRAY' && @{$d->checks} > 0, 'checks non-empty arrayref';
	is_deeply $d->skip, [], 'skip defaults to empty arrayref';
};

subtest 'Doctor::new -- all args stored through accessors' => sub {
	my $d = App::Project::Doctor->new(
		path    => '/tmp',
		checks  => ['Tests'],
		skip    => ['CI'],
		verbose => 1,
	);
	is $d->path,            '/tmp',    'path';
	is $d->verbose,         1,         'verbose';
	is_deeply $d->checks,   ['Tests'], 'checks';
	is_deeply $d->skip,     ['CI'],    'skip';
};

subtest 'Doctor::run -- returns App::Project::Doctor::Report' => sub {
	my $dir = make_distro('Makefile.PL' => '');
	my $r   = App::Project::Doctor->new(path => $dir, checks => ['CpanReadiness'])->run;
	isa_ok $r, 'App::Project::Doctor::Report';
	isa_ok($r, 'App::Project::Doctor::Report', 'run returns Report');
};

subtest 'Doctor::run -- croaks with documented DR01 message when no root found' => sub {
	# POD message DR01: "Cannot detect a distribution root"
	# Code: croak "Cannot detect a distribution root from '$path'"
	my $dir = tempdir(CLEANUP => 1);
	throws_ok { App::Project::Doctor->new(path => $dir)->run }
		qr/Cannot detect a distribution root from '\Q$dir\E'/,
		'DR01 croak text includes path';
};

subtest 'Doctor::run -- skip list is case-insensitive' => sub {
	# POD: "skip : ArrayRef -- check names to exclude"
	# Code: map { lc($_) => 1 } @{$self->skip}
	my $dir = make_distro('Makefile.PL' => '');
	my $r   = App::Project::Doctor->new(
		path   => $dir,
		checks => ['CpanReadiness'],
		skip   => ['CPANREADINESS'],   # upper-case must still match
	)->run;
	my $found_it = grep { $_->check_name eq 'CPAN Readiness' } $r->all_findings;
	ok !$found_it, 'check excluded by case-insensitive skip';
};

subtest 'Doctor::run -- unknown check class emits DR02 carp, run continues' => sub {
	# POD message DR02: "A check class cannot be loaded"
	# Code: carp "Could not load '$class': $@"
	my $dir = make_distro('Makefile.PL' => '');
	my $r;
	warning_like {
		$r = App::Project::Doctor->new(path => $dir, checks => ['NoSuchCheck999'])->run;
	} qr/Could not load/i, 'DR02 carp emitted';
	isa_ok $r, 'App::Project::Doctor::Report', 'run still returns a Report after carp';
};

subtest 'Doctor::run -- verbose=1 prints check name to STDOUT' => sub {
	# POD: verbose mode prints "Running: <check_name>" per check.
	my $dir = make_distro('Makefile.PL' => '');
	my $out = '';
	open my $fh, '>', \$out;
	{
		local *STDOUT = *$fh;
		App::Project::Doctor->new(
			path => $dir, checks => ['CpanReadiness'], verbose => 1
		)->run;
	}
	close $fh;
	like $out, qr/Running/i, 'verbose mode prints to STDOUT';
};

subtest 'Doctor::run -- does not clobber $_ or $@' => sub {
	# Global state integrity.
	my $dir = make_distro('Makefile.PL' => '');
	local $_ = 'sentinel';
	local $@ = 'prior_err';
	App::Project::Doctor->new(path => $dir, checks => ['CpanReadiness'])->run;
	is $_, 'sentinel',  '$_ unchanged after run';
	is $@, 'prior_err', '$@ unchanged after run';
};

diag 'Doctor: OK' if $ENV{TEST_VERBOSE};

# ===========================================================================
# 7. Check plugins -- interface conformance
#
# Each plugin must satisfy the interface defined in Check::Base POD:
#   name()        non-empty string
#   description() non-empty string
#   can_fix()     0 or 1
#   order()       positive integer
#   category()    non-empty string
#   isa           App::Project::Doctor::Check::Base
#   check($ctx)   returns a list (possibly empty) of Findings
#
# The detailed behavioural tests for each plugin live in t/function.t.
# ===========================================================================

Readonly::Array my @PLUGIN_METADATA => (
	# [ class_suffix, expected_name, expected_can_fix, expected_order ]
	[ 'CI',             'CI',              1, 20 ],
	[ 'Tests',          'Tests',           1, 10 ],
	[ 'GitHubActions',  'GitHub Actions',  1, 25 ],
	[ 'Meta',           'META',            0, 30 ],
	[ 'Pod',            'POD',             1, 40 ],
	[ 'Dependencies',   'Dependencies',    1, 50 ],
	[ 'License',        'Licensing',       0, 45 ],
	[ 'Security',       'Security',        1, 60 ],
	[ 'CpanReadiness',  'CPAN Readiness',  0, 90 ],
);

for my $spec (@PLUGIN_METADATA) {
	my ($suffix, $exp_name, $exp_can_fix, $exp_order) = @{$spec};
	my $class = "App::Project::Doctor::Check::$suffix";

	require_ok $class;

	subtest "Check::$suffix -- interface conformance" => sub {
		my $c = $class->new;

		isa_ok $c, 'App::Project::Doctor::Check::Base',
			"$suffix isa Check::Base";

		is $c->name, $exp_name,
			"name() returns '$exp_name'";

		ok length($c->description), 'description() non-empty';

		is $c->can_fix, $exp_can_fix,
			"can_fix() returns $exp_can_fix";

		is $c->order, $exp_order,
			"order() returns $exp_order";

		ok length($c->category), 'category() non-empty';

		diag sprintf("  %s: name=%s can_fix=%d order=%d",
			$suffix, $c->name, $c->can_fix, $c->order)
			if $ENV{TEST_VERBOSE};
	};
}

subtest 'Check plugins -- check($ctx) returns a list of Findings' => sub {
	# Verify the return-type contract of check() for each plugin.
	# Use a minimal distro; we care only about the return type, not the result.
	my $dir = make_distro('Makefile.PL' => '');
	my $ctx = _ctx($dir);

	for my $spec (@PLUGIN_METADATA) {
		my ($suffix) = @{$spec};
		my $class = "App::Project::Doctor::Check::$suffix";

		# Mock all external calls so the test is self-contained.
		my $g_wl = mock_scoped 'App::Workflow::Lint::lint'    => sub { () };
		my $g_gh = mock_scoped 'App::GHGen::generate'         => sub { 1  };

		my @findings;
		lives_ok {
			@findings = $class->new->check($ctx)
		} "$suffix: check() does not throw";

		for my $f (@findings) {
			isa_ok $f, 'App::Project::Doctor::Finding',
				"$suffix: each returned element isa Finding";
		}

		restore_all;
	}
};

# ===========================================================================
# 8. App::Project::Doctor::Check::Role (compatibility shim)
# ===========================================================================

require_ok 'App::Project::Doctor::Check::Role';

subtest 'Check::Role -- is a subclass of Check::Base (backward-compat shim)' => sub {
	ok App::Project::Doctor::Check::Role->isa('App::Project::Doctor::Check::Base'),
		'Check::Role isa Check::Base';
	my $r = App::Project::Doctor::Check::Role->new;
	is $r->can_fix,  0,                 'inherits can_fix default';
	is $r->category, $DEFAULT_CATEGORY, 'inherits category default';
	is $r->order,    $DEFAULT_ORDER,    'inherits order default';
};

diag 'Check plugins: OK' if $ENV{TEST_VERBOSE};

# ===========================================================================

done_testing;
