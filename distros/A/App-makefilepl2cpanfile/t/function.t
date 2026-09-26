use strict;
use warnings;

use Test::Most;
use lib 't/lib';
use Test::Permissions qw(can_revoke_read);
use Test::Memory::Cycle;
use Test::Mockingbird;
use Test::Returns;
use File::Temp qw(tempdir);
use Path::Tiny;
use Readonly;
use YAML::Tiny;

use App::makefilepl2cpanfile;

# White-box tests for every function in lib/App/makefilepl2cpanfile.pm,
# including the private (underscore-prefixed) helpers.  Private helpers are
# called by their fully-qualified names; the underscore is a convention only.
#
# Collaborators are replaced with Test::Mockingbird mocks wherever the test
# is about how a function *uses* them (delegation, argument passing, error
# propagation), so each subtest exercises exactly one function's logic.

Readonly my $PKG => 'App::makefilepl2cpanfile';

# Every literal the tests compare against lives here, so a change to the
# module's output format needs a single edit in the test file.
Readonly my %CFG => (
	cfg_dir         => '.config',
	cfg_file        => 'makefilepl2cpanfile.yml',
	header          => '# Generated from Makefile.PL using makefilepl2cpanfile',
	min_perl        => '5.010',
	top_indent      => q{},
	phase_indent    => "\t",
	comment_sep     => '   # ',
	sentinel_topic  => 'caller-owned topic',
	sentinel_evalerr=> 'caller-owned eval error',
	emit_stub       => "STUB CPANFILE\n",
	stub_min_perl   => '5.020',
	stub_dev_ver    => '1.23',
	utf8_error      => "Can't decode ill-formed UTF-8 octet sequence <FF>",
	io_error        => 'Permission denied',
);

# The built-in develop tools, as documented in the module's CONFIGURATION POD.
Readonly my @DEFAULT_DEV_TOOLS => qw(Devel::Cover Perl::Critic Test::Pod Test::Pod::Coverage);

# Shared fixture: a realistic Makefile.PL string exercising the common cases.
Readonly my $MF_SIMPLE => <<'END_MF';
WriteMakefile(
	PREREQ_PM => {
		'Try::Tiny' => 0,
		'Moo'       => '2.000',   # object system
	},
	TEST_REQUIRES => {
		'Test::More' => 0,
	},
	MIN_PERL_VERSION => '5.010',
);
END_MF

# A minimal deps hashref used to drive _emit without going through parse_prereqs.
my %DEPS_BASIC = (
	runtime => {
		requires => {
			'Moo' => { version => '2.000', comment => undef },
		},
	},
);

# -----------------------------------------------------------------------
# Test helpers
# -----------------------------------------------------------------------

# Route File::HomeDir to a fresh, empty directory so no test ever reads the
# developer's real ~/.config.  Returns the guard (hold it for the scope of
# the test) and the temp dir path.
sub empty_home {
	my $tmp = tempdir(CLEANUP => 1);
	my $guard = mock_scoped 'File::HomeDir::my_home' => sub { $tmp };
	return ($guard, $tmp);
}

# As empty_home, but also writes $data as the YAML config file.
sub home_with_config {
	my $data = $_[0];
	my ($guard, $tmp) = empty_home();
	my $dir = path($tmp)->child($CFG{cfg_dir});
	$dir->mkpath;
	YAML::Tiny->new($data)->write($dir->child($CFG{cfg_file})->stringify);
	return ($guard, $tmp);
}

# Runs $code with sentinel values in $_ and $@, then asserts they survive.
# A library helper that clobbers either of these breaks callers that call it
# inside a map/grep/for loop or between an eval and its $@ check.
sub globals_preserved_ok {
	my ($code, $name) = @_;
	local $_ = $CFG{sentinel_topic};
	local $@ = $CFG{sentinel_evalerr};
	$code->();
	is $_, $CFG{sentinel_topic},   "$name: \$_ is preserved";
	is $@, $CFG{sentinel_evalerr}, "$name: \$\@ is preserved";
	return;
}

# Collects warnings raised while running $code.
sub capture_warnings {
	my $code = $_[0];
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };
	$code->();
	return @warnings;
}

# -----------------------------------------------------------------------
# _has_version
# Purpose: decides whether a version is a real minimum worth emitting.
# Strategy: cover every input category - undef, empty, numeric/string zero,
# zero written as a decimal, positive numbers, and non-numeric v-strings.
# -----------------------------------------------------------------------
subtest '_has_version - boundary classification' => sub {
	# All of these mean "no minimum required" and must return false.
	for my $case ([undef, 'undef'], [q{}, 'empty string'], ['0', 'string "0"'],
			[0, 'numeric 0'], ['0.0', '"0.0" (numeric zero)'], ['0.000', '"0.000"']) {
		ok !App::makefilepl2cpanfile::_has_version($case->[0]), "$case->[1] -> false";
	}

	# These all represent real version constraints.
	for my $v (qw(1 1.0 0.001 5.010 6.64 1.6)) {
		ok App::makefilepl2cpanfile::_has_version($v), "\"$v\" -> true";
	}

	# A v-string is not numeric, but it is still a real constraint and must
	# be emitted rather than silently dropped.
	ok App::makefilepl2cpanfile::_has_version('v1.2.3'), '"v1.2.3" -> true';

	# The result is a plain boolean scalar, never a reference or list.
	returns_is(App::makefilepl2cpanfile::_has_version('1.0'), { type => 'scalar' },
		'_has_version returns a scalar');

	globals_preserved_ok(sub { App::makefilepl2cpanfile::_has_version('1.0') }, '_has_version');
};

# -----------------------------------------------------------------------
# _parse_min_perl
# Purpose: pull MIN_PERL_VERSION out of Makefile.PL text without eval.
# Strategy: every quoting style, underscore versions, absent key, and the
# word-boundary guard that stops a longer identifier from matching.
# -----------------------------------------------------------------------
subtest '_parse_min_perl - MIN_PERL_VERSION extraction' => sub {
	is App::makefilepl2cpanfile::_parse_min_perl("MIN_PERL_VERSION => '5.010'"),
		'5.010', 'single-quoted version extracted';
	is App::makefilepl2cpanfile::_parse_min_perl('MIN_PERL_VERSION => "5.036"'),
		'5.036', 'double-quoted version extracted';
	is App::makefilepl2cpanfile::_parse_min_perl('MIN_PERL_VERSION => 5.008'),
		'5.008', 'unquoted numeric version extracted';
	is App::makefilepl2cpanfile::_parse_min_perl('MIN_PERL_VERSION => 5.008_001'),
		'5.008_001', 'version with underscore extracted';
	is App::makefilepl2cpanfile::_parse_min_perl('WriteMakefile( NAME => "Foo" )'),
		undef, 'returns undef when key is absent';

	# The \b anchors mean a differently-named key that merely contains the
	# string must not be mistaken for the real one.
	is App::makefilepl2cpanfile::_parse_min_perl("X_MIN_PERL_VERSION => '5.030'"),
		undef, 'longer identifier containing the key does not match';

	is App::makefilepl2cpanfile::_parse_min_perl($MF_SIMPLE),
		$CFG{min_perl}, 'extracts version from realistic Makefile.PL content';

	returns_is(App::makefilepl2cpanfile::_parse_min_perl($MF_SIMPLE), { type => 'string' },
		'_parse_min_perl returns a string when present');

	globals_preserved_ok(sub { App::makefilepl2cpanfile::_parse_min_perl($MF_SIMPLE) },
		'_parse_min_perl');
};

# -----------------------------------------------------------------------
# _fmt_dep
# Purpose: render one requires/recommends/suggests line.
# Strategy: every combination that changes output - relationship keyword,
# indent, version present/absent/zero, comment present/absent/empty.
# -----------------------------------------------------------------------
subtest '_fmt_dep - single dependency line formatting' => sub {
	my $fmt = \&App::makefilepl2cpanfile::_fmt_dep;

	is $fmt->('requires', 'Moo', { version => 0, comment => undef }, $CFG{top_indent}),
		"requires 'Moo';\n",
		'requires, no version, no comment, no indent';

	is $fmt->('requires', 'Moo', { version => '2.000', comment => undef }, $CFG{top_indent}),
		"requires 'Moo', '2.000';\n",
		'non-zero version is emitted as the second argument';

	is $fmt->('requires', 'Moo', { version => 0, comment => undef }, $CFG{phase_indent}),
		"$CFG{phase_indent}requires 'Moo';\n",
		'phase-block indent is applied';

	is $fmt->('requires', 'Moo', { version => '2.000', comment => 'roles engine' }, $CFG{top_indent}),
		"requires 'Moo', '2.000';$CFG{comment_sep}roles engine\n",
		'inline comment follows the semicolon';

	# The relationship keyword must pass through unchanged, otherwise optional
	# dependencies would be silently promoted to hard requirements.
	is $fmt->('recommends', 'Future', { version => '0.33', comment => undef }, $CFG{top_indent}),
		"recommends 'Future', '0.33';\n",
		'recommends keyword emitted verbatim';
	is $fmt->('suggests', 'Log::Any', { version => 0, comment => undef }, $CFG{phase_indent}),
		"$CFG{phase_indent}suggests 'Log::Any';\n",
		'suggests keyword emitted verbatim';

	# _fmt_dep relies on its callers never storing an empty comment (it
	# only tests defined()).  Prove that premise at the source: a comment
	# that is empty, blank, or made only of stripped characters is undef.
	for my $raw ('#', '#   ', "# \x{202E}", "#\t\r") {
		my $d = App::makefilepl2cpanfile::parse_prereqs("PREREQ_PM => {\n\t'Foo' => 0, $raw\n},");
		is $d->{runtime}{requires}{Foo}{comment}, undef, 'empty comment stored as undef, never as the empty string';
	}

	is $fmt->('requires', 'Bar', { version => '0', comment => undef }, $CFG{top_indent}),
		"requires 'Bar';\n",
		'string "0" version suppressed';

	# _fmt_dep must defer to _has_version rather than re-implementing the
	# zero test; forcing the helper's answer proves the delegation.
	{
		my $g = mock_scoped "${PKG}::_has_version" => sub { 0 };
		is $fmt->('requires', 'Baz', { version => '9.99', comment => undef }, $CFG{top_indent}),
			"requires 'Baz';\n",
			'version omitted when _has_version says so';
	}

	returns_is($fmt->('requires', 'Moo', { version => 0, comment => undef }, $CFG{top_indent}),
		{ type => 'string' }, '_fmt_dep returns a string');

	globals_preserved_ok(
		sub { $fmt->('requires', 'Moo', { version => 1, comment => 'c' }, $CFG{top_indent}) },
		'_fmt_dep');
};

# -----------------------------------------------------------------------
# _extract_pairs
# Purpose: turn the text between a dependency hash's braces into entries.
# Strategy: comment capture, comment/blank line skipping, first-occurrence
# wins (within and across calls), module-name validation (the injection
# guard), bareword keys, and void return.
# -----------------------------------------------------------------------
subtest '_extract_pairs - block parser' => sub {
	my $extract = \&App::makefilepl2cpanfile::_extract_pairs;

	# Basic: one module with version zero, one with an explicit version.
	{
		my %deps;
		$extract->("\t'Try::Tiny' => 0,\n\t'Moo' => '2.000',\n", \%deps, 'runtime', 'requires');

		is_deeply $deps{runtime}{requires}, {
			'Try::Tiny' => { version => 0,       comment => undef },
			'Moo'       => { version => '2.000', comment => undef },
		}, 'modules and versions stored in the requested phase/relationship';
	}

	# The phase and relationship arguments must be honoured, not hard-coded.
	{
		my %deps;
		$extract->("'Opt::Mod' => 0,\n", \%deps, 'test', 'suggests');
		ok exists $deps{test}{suggests}{'Opt::Mod'}, 'entry filed under test/suggests';
		ok !exists $deps{runtime}, 'nothing leaked into runtime';
	}

	# Inline comment must be captured before the comment text is stripped.
	{
		my %deps;
		$extract->("\t'Foo::Bar' => 0,   # used in bin/ scripts\n", \%deps, 'runtime', 'requires');
		is $deps{runtime}{requires}{'Foo::Bar'}{comment}, 'used in bin/ scripts',
			'inline comment captured verbatim';
	}

	# A commented-out module must stay out: the author disabled it on purpose.
	{
		my %deps;
		$extract->("\t# 'Old::Module' => 0,\n", \%deps, 'runtime', 'requires');
		ok !exists $deps{runtime}, 'fully-commented module line is skipped';
	}

	# Blank lines must not introduce phantom entries.
	{
		my %deps;
		$extract->("\n\n\t'Real' => 0,\n\n", \%deps, 'runtime', 'requires');
		is_deeply [ keys %{ $deps{runtime}{requires} } ], ['Real'],
			'exactly one entry despite blank lines';
	}

	# First-occurrence-wins within a single block.
	{
		my %deps;
		$extract->("\t'Dup' => '1.00',   # first\n\t'Dup' => '2.00',   # second\n",
			\%deps, 'runtime', 'requires');
		is_deeply $deps{runtime}{requires}{'Dup'}, { version => '1.00', comment => 'first' },
			'first occurrence (version and comment) wins within a block';
	}

	# First-occurrence-wins across calls: a pre-populated entry must survive.
	{
		my %deps = (test => { requires => {
			'Pre::Existing' => { version => '9.99', comment => 'kept' },
		} });
		$extract->("\t'Pre::Existing' => '0.01',\n", \%deps, 'test', 'requires');
		is_deeply $deps{test}{requires}{'Pre::Existing'}, { version => '9.99', comment => 'kept' },
			'pre-existing entry not overwritten';
	}

	# Module-name validation is the defence against code injection into the
	# generated cpanfile, which cpanm evaluates as Perl.  Anything that is
	# not a plain Perl package name must be dropped.
	{
		my %deps;
		my @hostile = (
			q{'1Leading::Digit' => 0,},
			q{'Has Space' => 0,},
			q{'Bad::' => 0,},
			q{'Semi;colon' => 0,},
			q{'Dash-ed' => 0,},
		);
		$extract->(join("\n", @hostile, q{'Good::Name' => 0,}), \%deps, 'runtime', 'requires');
		is_deeply [ keys %{ $deps{runtime}{requires} } ], ['Good::Name'],
			'only the valid package name survives validation';
	}

	# Bareword keys cannot be matched safely by the regex parser and must be
	# ignored rather than half-parsed.
	{
		my %deps;
		$extract->("\tBareword => 0,\n", \%deps, 'runtime', 'requires');
		ok !exists $deps{runtime}, 'bareword key is ignored';
	}

	# Void semantics: the function mutates its argument and returns nothing.
	{
		my %deps;
		my $ret = $extract->("'X' => 0,\n", \%deps, 'runtime', 'requires');
		is $ret, undef, '_extract_pairs returns undef';
		memory_cycle_ok(\%deps, 'populated deps hash has no memory cycles');
	}

	globals_preserved_ok(
		sub { $extract->("'X' => 0, # c\n'Y' => 1,\n", {}, 'runtime', 'requires') },
		'_extract_pairs');
};

# -----------------------------------------------------------------------
# _emit
# Purpose: pure formatter from the deps structure to cpanfile text.
# Strategy: header, perl line, runtime at top level, on-blocks for other
# phases in canonical order, relationship order, alphabetical sort, the
# single-trailing-newline invariant, pruning of empty phases, and that each
# line is produced by _fmt_dep.
# -----------------------------------------------------------------------
subtest '_emit - cpanfile string formatter' => sub {
	my $emit = \&App::makefilepl2cpanfile::_emit;

	# Empty deps: only the header comment should appear.
	is $emit->({}, undef), "$CFG{header}\n", 'empty deps yields only the header';

	# MIN_PERL_VERSION line follows the header.
	is $emit->({}, $CFG{min_perl}),
		"$CFG{header}\n\nrequires 'perl', '$CFG{min_perl}';\n",
		'perl version line emitted after the header';

	# Runtime deps appear at the top level with no wrapping 'on' block.
	{
		my $out = $emit->({ runtime => {
			requires   => { 'Moo'    => { version => '2.000', comment => undef } },
			recommends => { 'Future' => { version => 0,       comment => 'async' } },
			suggests   => { 'Pod'    => { version => 0,       comment => undef } },
		} }, undef);
		is $out, join(q{},
			"$CFG{header}\n\n",
			"requires 'Moo', '2.000';\n",
			"recommends 'Future';$CFG{comment_sep}async\n",
			"suggests 'Pod';\n",
		), 'runtime relationships at top level in requires/recommends/suggests order';
	}

	# Non-runtime phases are wrapped in an 'on' block with indented lines.
	is $emit->({ test => { requires => { 'Test::More' => { version => 0, comment => undef } } } }, undef),
		"$CFG{header}\n\non 'test' => sub {\n$CFG{phase_indent}requires 'Test::More';\n};\n",
		'test phase rendered as an indented on-block';

	# Phase blocks must appear in canonical order regardless of hash order.
	{
		my $mk = sub { { requires => { $_[0] => { version => 0, comment => undef } } } };
		my $out = $emit->({
			develop   => $mk->('Perl::Critic'),
			build     => $mk->('Module::Build'),
			test      => $mk->('Test::More'),
			configure => $mk->('ExtUtils::MakeMaker'),
		}, undef);
		my @order = $out =~ /^on '(\w+)'/mg;
		is_deeply \@order, [qw(configure build test develop)], 'phases in canonical order';
	}

	# Modules within a relationship are sorted so output is reproducible.
	{
		my $out = $emit->({ runtime => { requires => {
			'Zebra' => { version => 0, comment => undef },
			'Alpha' => { version => 0, comment => undef },
			'Mid'   => { version => 0, comment => undef },
		} } }, undef);
		my @mods = $out =~ /^requires '([^']+)'/mg;
		is_deeply \@mods, [qw(Alpha Mid Zebra)], 'modules sorted alphabetically';
	}

	# Output must end with exactly one newline in every shape.
	for my $case ([{}, undef], [\%DEPS_BASIC, $CFG{min_perl}],
			[{ test => { requires => { 'T' => { version => 0, comment => undef } } } }, undef]) {
		my $out = $emit->(@{$case});
		like   $out, qr/\n\z/,   'output ends with a newline';
		unlike $out, qr/\n\n\z/, 'output does not end with a blank line';
	}

	# A phase whose relationships are all empty must not yield an empty block,
	# and unknown phases are not part of the cpanfile vocabulary.
	{
		my $out = $emit->({ develop => { requires => {} }, bogus => { requires => {
			'X' => { version => 0, comment => undef } } } }, undef);
		is $out, "$CFG{header}\n", 'empty and unknown phases produce no output';
	}

	# Each dependency line must come from _fmt_dep, so formatting rules live
	# in one place.  A spy records the calls while keeping real behaviour.
	{
		my @calls;
		my $real = \&App::makefilepl2cpanfile::_fmt_dep;
		my $g = mock_scoped "${PKG}::_fmt_dep" => sub { push @calls, [@_]; $real->(@_) };
		$emit->({ runtime => { requires => { 'A' => { version => 0, comment => undef } } },
			test => { suggests => { 'B' => { version => 0, comment => undef } } } }, undef);
		is_deeply [ map { [ @{$_}[0, 1, 3] ] } @calls ],
			[ ['requires', 'A', $CFG{top_indent}], ['suggests', 'B', $CFG{phase_indent}] ],
			'_fmt_dep called once per dependency with the right rel/module/indent';
	}

	# The input structure is caller-owned and must not be modified.
	{
		my %copy = (runtime => { requires => { 'Moo' => { version => '2.000', comment => undef } } });
		$emit->(\%copy, $CFG{min_perl});
		is_deeply \%copy, \%DEPS_BASIC, '_emit does not mutate its input';
	}

	my $out = $emit->(\%DEPS_BASIC, undef);
	returns_is($out, { type => 'string' }, '_emit returns a string');
	memory_cycle_ok(\$out, '_emit return value has no memory cycles');

	globals_preserved_ok(sub { $emit->(\%DEPS_BASIC, $CFG{min_perl}) }, '_emit');
};

# -----------------------------------------------------------------------
# _load_develop_config
# Purpose: return the develop tools from ~/.config, or the defaults.
# Strategy: redirect File::HomeDir to a temp dir per case and walk every
# path - no home, no file, valid file, file without 'develop', unparseable
# file, and the security validation of keys and values.
# -----------------------------------------------------------------------
subtest '_load_develop_config - YAML config loading' => sub {
	my $load = \&App::makefilepl2cpanfile::_load_develop_config;
	my %defaults = map { $_ => 0 } @DEFAULT_DEV_TOOLS;

	# No home directory at all (containers, chroots): defaults, no croak.
	{
		my $g = mock_scoped 'File::HomeDir::my_home' => sub { undef };
		my $result;
		lives_ok { $result = $load->() } 'undef home directory does not croak';
		is_deeply $result, \%defaults, 'undef home directory yields the defaults';
	}

	# No config file: a copy of the defaults that callers may freely modify.
	{
		my ($g) = empty_home();
		my $result = $load->();
		is_deeply $result, \%defaults, 'missing config file yields the defaults';
		returns_is($result, { type => 'hashref' }, 'returns a hashref');

		# Mutating the returned copy must not contaminate future calls.
		$result->{'Injected::Tool'} = 1;
		ok !exists $load->()->{'Injected::Tool'}, 'returned hashref is a defensive copy';
	}

	# Valid config with a 'develop' key replaces (not extends) the defaults.
	{
		my ($g) = home_with_config({ develop => { 'My::Extra::Tool' => '1.00' } });
		is_deeply $load->(), { 'My::Extra::Tool' => '1.00' },
			'config develop block replaces the defaults entirely';
	}

	# Config without a 'develop' key: warn so the user notices, use defaults.
	{
		my ($g, $home) = home_with_config({ other_key => 'value' });
		my $cfg_path = path($home)->child($CFG{cfg_dir}, $CFG{cfg_file});
		my $result;
		my @w = capture_warnings(sub { $result = $load->() });
		is_deeply $result, \%defaults, 'falls back to defaults when develop key absent';
		is scalar @w, 1, 'exactly one warning';
		like $w[0], qr/\ANo 'develop' key found in \Q$cfg_path\E; using defaults/,
			'warning text names the file';
	}

	# Unparseable YAML must croak rather than silently use defaults, because
	# the user clearly intended to configure something.
	{
		my ($g_home, $home) = empty_home();
		my $cfg_path = path($home)->child($CFG{cfg_dir}, $CFG{cfg_file});
		$cfg_path->parent->mkpath;
		$cfg_path->spew_utf8("garbage: [\n");
		my $g_yaml = mock_scoped(
			'YAML::Tiny::read'   => sub { undef },
			'YAML::Tiny::errstr' => sub { 'simulated parse error' },
		);
		throws_ok { $load->() }
			qr/\AFailed to parse \Q$cfg_path\E: simulated parse error/,
			'unparseable YAML croaks with the path and parser error';
	}

	# SECURITY: a module name that is not a package name would be written
	# verbatim into the cpanfile; it must be skipped with a warning.
	{
		my $evil = q{Safe'; system('id'); requires 'X};
		my ($g, $home) = home_with_config({ develop => { $evil => 0, 'Good::Tool' => 0 } });
		my $cfg_path = path($home)->child($CFG{cfg_dir}, $CFG{cfg_file});
		my $result;
		my @w = capture_warnings(sub { $result = $load->() });
		is_deeply $result, { 'Good::Tool' => 0 }, 'invalid module name skipped';
		like $w[0], qr/\ASkipping invalid module name in \Q$cfg_path\E: '\Q$evil\E'/,
			'warning names the file and the rejected key';
	}

	# SECURITY: a hostile version string is neutralised to 0 (any version);
	# the module itself is a valid name and is kept.
	{
		my $evil_ver = q{1'; system('id'); '};
		my ($g, $home) = home_with_config({ develop => { 'Some::Tool' => $evil_ver } });
		my $cfg_path = path($home)->child($CFG{cfg_dir}, $CFG{cfg_file});
		my $result;
		my @w = capture_warnings(sub { $result = $load->() });
		is_deeply $result, { 'Some::Tool' => 0 }, 'invalid version replaced by 0';
		like $w[0],
			qr/\ASkipping invalid version for 'Some::Tool' in \Q$cfg_path\E: '\Q$evil_ver\E'/,
			'warning names the module, file and rejected version';
	}

	# Legitimate version spellings must all pass validation untouched.
	{
		my %good = ('A::Tool' => '1.23', 'B::Tool' => 'v1.2.3', 'C::Tool' => '1.23_01', 'D::Tool' => q{});
		my ($g) = home_with_config({ develop => \%good });
		my @w = capture_warnings(sub { is_deeply $load->(), \%good, 'valid versions preserved' });
		is scalar @w, 0, 'no warnings for valid versions';
	}

	{
		my ($g) = home_with_config({ develop => { 'A::Tool' => 0 } });
		memory_cycle_ok($load->(), 'returned hashref has no memory cycles');
		globals_preserved_ok(sub { $load->() }, '_load_develop_config');
	}
};

# -----------------------------------------------------------------------
# parse_prereqs
# Purpose: public parser from Makefile.PL text to the deps structure.
# Strategy: invalid input types, all four simple keys, comments, structured
# prereqs blocks (all relationships), META_MERGE nesting, invalid phase/rel
# filtering, legacy top-level recommends/suggests, and that module entries
# are delegated to _extract_pairs.
# -----------------------------------------------------------------------
subtest 'parse_prereqs - Makefile.PL parser' => sub {
	my $parse = \&App::makefilepl2cpanfile::parse_prereqs;

	# Non-string input is documented as "silently ignored": an empty hashref,
	# with no warnings from the regex engine.
	for my $case ([q{}, 'empty string'], [undef, 'undef'], [[], 'arrayref'], [{}, 'hashref']) {
		my $d;
		my @w = capture_warnings(sub { $d = $parse->($case->[0]) });
		is_deeply $d, {}, "$case->[1] yields an empty hashref";
		is scalar @w, 0, "$case->[1] raises no warnings";
	}

	# Each simple key maps to the correct cpanfile phase under 'requires'.
	is_deeply $parse->(<<'END_MF'),
WriteMakefile(
	PREREQ_PM          => { 'A::Runtime'   => 0 },
	BUILD_REQUIRES     => { 'B::Build'     => 0 },
	TEST_REQUIRES      => { 'C::Test'      => 0 },
	CONFIGURE_REQUIRES => { 'D::Configure' => '6.64' },
);
END_MF
		{
			runtime   => { requires => { 'A::Runtime'   => { version => 0,      comment => undef } } },
			build     => { requires => { 'B::Build'     => { version => 0,      comment => undef } } },
			test      => { requires => { 'C::Test'      => { version => 0,      comment => undef } } },
			configure => { requires => { 'D::Configure' => { version => '6.64', comment => undef } } },
		}, 'each simple key maps to its phase under requires';

	# Inline comments and commented-out lines.
	{
		my $d = $parse->("PREREQ_PM => {\n\t# 'Skipped' => 0,\n\t'Real' => 0,   # for the CLI\n},");
		is_deeply $d->{runtime}{requires}, { 'Real' => { version => 0, comment => 'for the CLI' } },
			'comment captured; commented-out module skipped';
	}

	# Structured prereqs block: every relationship in every phase.
	is_deeply $parse->(<<'END_MF'),
WriteMakefile(
	prereqs => {
		runtime => {
			requires   => { 'Scalar::Util' => 0 },
			recommends => { 'Future' => '0.33' },
			suggests   => { 'Log::Any' => 0 },
		},
		test => {
			requires => { 'Test::Exception' => 0 },
		},
	},
);
END_MF
		{
			runtime => {
				requires   => { 'Scalar::Util' => { version => 0,      comment => undef } },
				recommends => { 'Future'       => { version => '0.33', comment => undef } },
				suggests   => { 'Log::Any'     => { version => 0,      comment => undef } },
			},
			test => { requires => { 'Test::Exception' => { version => 0, comment => undef } } },
		}, 'structured prereqs parsed for every relationship';

	# Names outside the CPAN Meta Spec vocabulary must not reach the output.
	is_deeply $parse->("prereqs => { bogus_phase => { requires => { 'X' => 0 } } },"), {},
		'invalid phase name rejected';
	is_deeply $parse->("prereqs => { runtime => { optional => { 'X' => 0 } } },"), {},
		'invalid relationship name rejected';

	# prereqs nested under META_MERGE are found alongside the simple keys.
	{
		my $d = $parse->(<<'END_MF');
WriteMakefile(
	PREREQ_PM  => { 'Moo' => 0 },
	META_MERGE => {
		prereqs => { runtime => { recommends => { 'Moo::Role' => '2.000' } } },
	},
);
END_MF
		ok exists $d->{runtime}{requires}{'Moo'}, 'PREREQ_PM parsed alongside META_MERGE';
		is $d->{runtime}{recommends}{'Moo::Role'}{version}, '2.000',
			'META_MERGE prereqs recommends extracted with version';
	}

	# Legacy META spec 1.x style: recommends/suggests directly under
	# META_MERGE mean runtime recommendations/suggestions.
	{
		my $d = $parse->(<<'END_MF');
WriteMakefile(
	META_MERGE => {
		'meta-spec' => { version => 2 },
		recommends => {
			# optional backends
			'JSON::MaybeXS' => 0,		# JSON backend
			'XML::Simple'   => '2.25',
		},
		'suggests' => { 'YAML::XS' => '0.88' },
	},
);
END_MF
		is_deeply $d, { runtime => {
			recommends => {
				'JSON::MaybeXS' => { version => 0,      comment => 'JSON backend' },
				'XML::Simple'   => { version => '2.25', comment => undef },
			},
			suggests => { 'YAML::XS' => { version => '0.88', comment => undef } },
		} }, 'legacy top-level recommends and (quoted) suggests map to runtime';
	}

	# A recommends/suggests block inside prereqs belongs to its phase only;
	# the legacy scan must not also file it under runtime.
	{
		my $d = $parse->(<<'END_MF');
WriteMakefile(
	META_MERGE => {
		prereqs => {
			test => {
				recommends => { 'Test::Deep' => 0 },
				suggests   => { 'Test::Differences' => 0 },
			},
		},
	},
);
END_MF
		is_deeply $d, { test => {
			recommends => { 'Test::Deep'        => { version => 0, comment => undef } },
			suggests   => { 'Test::Differences' => { version => 0, comment => undef } },
		} }, 'phase-scoped recommends/suggests are not duplicated into runtime';
	}

	# First-occurrence-wins across forms: the simple key is scanned first, so
	# its version must be the one kept.
	{
		my $d = $parse->(<<'END_MF');
WriteMakefile(
	PREREQ_PM => { 'Dup' => '1.00' },
	prereqs   => { runtime => { requires => { 'Dup' => '2.00' } } },
);
END_MF
		is $d->{runtime}{requires}{'Dup'}{version}, '1.00', 'PREREQ_PM entry wins over prereqs';
	}

	# Module-entry parsing is delegated to _extract_pairs; each recognised
	# block must be handed over with the correct phase and relationship.
	{
		my @calls;
		my $g = mock_scoped "${PKG}::_extract_pairs" => sub { push @calls, [ @_[2, 3] ] };
		$parse->(<<'END_MF');
WriteMakefile(
	TEST_REQUIRES => { 'T' => 0 },
	META_MERGE => {
		prereqs    => { build => { suggests => { 'B' => 0 } } },
		recommends => { 'R' => 0 },
	},
);
END_MF
		is_deeply [ sort { "@{$a}" cmp "@{$b}" } @calls ],
			[ ['build', 'suggests'], ['runtime', 'recommends'], ['test', 'requires'] ],
			'_extract_pairs called once per block with phase and relationship';
	}

	my $d = $parse->($MF_SIMPLE);
	returns_is($d, { type => 'hashref' }, 'parse_prereqs returns a hashref');
	memory_cycle_ok($d, 'parse_prereqs return value has no memory cycles');

	globals_preserved_ok(sub { $parse->($MF_SIMPLE) }, 'parse_prereqs');
};

# -----------------------------------------------------------------------
# generate
# Purpose: orchestrate read -> parse -> merge -> inject -> emit.
# Strategy: first isolate generate's own logic by mocking every in-module
# collaborator and inspecting what it passes between them; then check the
# argument guards, the file-reading error handling (with Path::Tiny mocked
# to force each branch), and the develop-block merge on real fixtures.
# -----------------------------------------------------------------------
subtest 'generate - orchestration and error handling' => sub {
	my $generate = \&App::makefilepl2cpanfile::generate;

	my ($g_home) = empty_home();
	my $dir = tempdir(CLEANUP => 1);
	my $mf  = path($dir)->child('Makefile.PL');
	$mf->spew_utf8("WriteMakefile(PREREQ_PM => { 'Try::Tiny' => 0 });\n");

	# ---- Delegation with every collaborator mocked ----
	{
		my %seen;
		my $g = mock_scoped(
			"${PKG}::_parse_min_perl" => sub { $seen{min_perl_in} = $_[0]; $CFG{stub_min_perl} },
			"${PKG}::parse_prereqs"   => sub {
				$seen{parse_in} = $_[0];
				return { runtime => { requires => { 'Stub::Mod' => { version => 0, comment => undef } } } };
			},
			"${PKG}::_load_develop_config" => sub {
				$seen{config_calls}++;
				return { 'Stub::Dev' => $CFG{stub_dev_ver}, 'Kept::Tool' => '9' };
			},
			"${PKG}::_emit" => sub { @seen{qw(emit_deps emit_perl)} = @_; $CFG{emit_stub} },
		);

		my $existing = "on 'develop' => sub {\n\trequires 'Kept::Tool', '1.0';\n};\n";
		my $out = $generate->(makefile => "$mf", existing => $existing);

		is $out, $CFG{emit_stub}, 'returns exactly what _emit produced';
		is $seen{parse_in}, $mf->slurp_utf8, 'parse_prereqs receives the file content';
		is $seen{min_perl_in}, $mf->slurp_utf8, '_parse_min_perl receives the file content';
		is $seen{emit_perl}, $CFG{stub_min_perl}, '_emit receives the parsed perl version';
		is $seen{config_calls}, 1, 'develop config loaded once when with_develop defaults on';
		is_deeply $seen{emit_deps}, {
			runtime => { requires => { 'Stub::Mod' => { version => 0, comment => undef } } },
			develop => { requires => {
				'Kept::Tool' => { version => '1.0',              comment => undef },
				'Stub::Dev'  => { version => $CFG{stub_dev_ver}, comment => undef },
			} },
		}, 'parsed deps, merged develop block and injected tools reach _emit; existing entry wins';

		%seen = ();
		$generate->({ makefile => "$mf", with_develop => 0 });
		ok !$seen{config_calls}, 'with_develop => 0 (hashref style) skips config loading';
		ok !exists $seen{emit_deps}{develop}, 'and adds no develop phase';
	}

	# ---- Argument guards: exact croak text names the offending path ----
	throws_ok { $generate->(makefile => "$dir/nonexistent.PL") }
		qr/\ACannot read '\Q$dir\E\/nonexistent\.PL'/, 'croaks for a missing file';
	throws_ok { $generate->(makefile => $dir) }
		qr/\ACannot read '\Q$dir\E'/, 'croaks when the path is a directory';
	SKIP: {
		skip 'chmod cannot make a file unreadable here (root or Windows)', 1 unless can_revoke_read();
		my $locked = path($dir)->child('locked.PL');
		$locked->spew_utf8("WriteMakefile();\n");
		chmod 0, "$locked";
		throws_ok { $generate->(makefile => "$locked") }
			qr/\ACannot read '\Q$locked\E'/, 'croaks for an unreadable file';
	}

	# ---- Default makefile argument is Makefile.PL in the current directory ----
	{
		my $cwd = Path::Tiny->cwd;
		chdir $dir or die "chdir $dir: $!";
		my $out = eval { $generate->(with_develop => 0) };
		my $err = $@;
		chdir $cwd or die "chdir $cwd: $!";
		is $err, q{}, 'no makefile argument reads ./Makefile.PL';
		like $out, qr/^requires 'Try::Tiny';$/m, 'and parses it';
	}

	# ---- Invalid UTF-8: warn and fall back to raw bytes ----
	# Path::Tiny only dies on bad UTF-8 when Unicode::UTF8 is absent, so the
	# error is forced with a mock to make this branch deterministic.
	{
		my $raw_calls = 0;
		my $g = mock_scoped(
			'Path::Tiny::slurp_utf8' => sub { die "$CFG{utf8_error}\n" },
			'Path::Tiny::slurp_raw'  => sub { $raw_calls++; "WriteMakefile(PREREQ_PM => { 'Raw::Mod' => 0 });\n" },
		);
		my $out;
		my @w = capture_warnings(sub { $out = $generate->(makefile => "$mf", with_develop => 0) });
		is $raw_calls, 1, 'raw read used as the fallback';
		like $out, qr/^requires 'Raw::Mod';$/m, 'raw content is parsed';
		is scalar @w, 1, 'exactly one warning';
		like $w[0],
			qr/\AWarning: '\Q$mf\E' contains invalid UTF-8; reading as raw bytes: \Q$CFG{utf8_error}\E/,
			'warning names the file and the decode error';
	}

	# ---- Genuine I/O failure: must propagate, never degrade to raw read ----
	{
		my $raw_calls = 0;
		my $g = mock_scoped(
			'Path::Tiny::slurp_utf8' => sub { die "$CFG{io_error}\n" },
			'Path::Tiny::slurp_raw'  => sub { $raw_calls++; q{} },
		);
		throws_ok { $generate->(makefile => "$mf", with_develop => 0) }
			qr/\A\Q$CFG{io_error}\E/, 'I/O error is re-thrown unchanged';
		is $raw_calls, 0, 'raw fallback not attempted for I/O errors';
	}

	# ---- Develop-block merge from an existing cpanfile (real collaborators) ----
	{
		my $existing = <<'END_CPANFILE';
on 'develop' => sub {
	requires 'My::Tool', '2.5';   # a comment with }; inside
	recommends 'My::Nice::Tool';
	suggests 'My::Maybe::Tool';
	requires 'Bad Name';
};
END_CPANFILE
		my $out = $generate->(makefile => "$mf", existing => $existing, with_develop => 0);
		like $out, qr/^\trequires 'My::Tool', '2\.5';$/m,     'develop requires merged with version';
		like $out, qr/^\trecommends 'My::Nice::Tool';$/m,     'develop recommends merged';
		like $out, qr/^\tsuggests 'My::Maybe::Tool';$/m,      'develop suggests merged';
		unlike $out, qr/Bad Name/, 'invalid module name in existing cpanfile rejected';
	}

	# ---- A hand-curated develop entry is never overwritten by injection ----
	{
		my $existing = "on 'develop' => sub {\n\trequires 'Perl::Critic', '1.140';\n};\n";
		my $out = $generate->(makefile => "$mf", existing => $existing);
		my @hits = $out =~ /Perl::Critic/g;
		is scalar @hits, 1, 'Perl::Critic appears exactly once';
		like $out, qr/^\trequires 'Perl::Critic', '1\.140';$/m, 'hand-curated version kept';
	}

	# ---- generate() returns text and never writes to disk ----
	{
		my @before = sort map { "$_" } path($dir)->children;
		my $out = $generate->(makefile => "$mf");
		my @after = sort map { "$_" } path($dir)->children;
		is_deeply \@after, \@before, 'no files created or removed';
		returns_is($out, { type => 'string' }, 'generate returns a string');
		memory_cycle_ok(\$out, 'generate return value has no memory cycles');
	}

	globals_preserved_ok(sub { $generate->(makefile => "$mf") }, 'generate');
};

done_testing;
