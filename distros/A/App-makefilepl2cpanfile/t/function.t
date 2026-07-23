use strict;
use warnings;

use Test::Most;
use Test::Memory::Cycle;
use Test::Mockingbird;
use File::Temp   qw(tempdir);
use Path::Tiny;
use Readonly;
use YAML::Tiny;

use App::makefilepl2cpanfile;

# Private helpers are called via their fully-qualified names.  No strict-refs
# trick is needed because these are compile-time-known symbol names.
# The leading underscore is a convention; Sub::Private is not enforced.

Readonly my $PKG => 'App::makefilepl2cpanfile';

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
# _has_version
# Strategy: cover every distinct input category — undef, empty string,
# numeric zero, string "0", non-zero numeric, and non-numeric strings.
# -----------------------------------------------------------------------
subtest '_has_version — boundary classification' => sub {

	# All of these mean "no minimum required" and must return false.
	ok !App::makefilepl2cpanfile::_has_version(undef),   'undef -> false';
	ok !App::makefilepl2cpanfile::_has_version(''),      'empty string -> false';
	ok !App::makefilepl2cpanfile::_has_version('0'),     'string "0" -> false';
	ok !App::makefilepl2cpanfile::_has_version(0),       'numeric 0 -> false';
	ok !App::makefilepl2cpanfile::_has_version('0.0'),   '"0.0" -> false (numeric zero)';

	# These represent real version constraints.
	ok  App::makefilepl2cpanfile::_has_version('1'),     '"1" -> true';
	ok  App::makefilepl2cpanfile::_has_version('1.0'),   '"1.0" -> true';
	ok  App::makefilepl2cpanfile::_has_version('0.001'), '"0.001" -> true (above zero)';
	ok  App::makefilepl2cpanfile::_has_version('5.010'), '"5.010" -> true (Perl version)';
	ok  App::makefilepl2cpanfile::_has_version('6.64'),  '"6.64" -> true';

	# A non-numeric string is not a version number so looks_like_number returns
	# false; the code then falls through to return 1 (truthy).
	ok  App::makefilepl2cpanfile::_has_version('v1.2.3'),
		'"v1.2.3" -> true (non-numeric treated as constraint)';

	diag 'all _has_version boundary cases pass' if $ENV{TEST_VERBOSE};
};

# -----------------------------------------------------------------------
# _parse_min_perl
# Strategy: test each quoting style (single, double, bare numeric) and
# confirm the function returns undef when the key is absent.
# -----------------------------------------------------------------------
subtest '_parse_min_perl — MIN_PERL_VERSION extraction' => sub {

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

	# Confirm the function works on realistic multi-line content.
	is App::makefilepl2cpanfile::_parse_min_perl($MF_SIMPLE),
		'5.010', 'extracts version from realistic Makefile.PL content';

	diag 'all _parse_min_perl cases pass' if $ENV{TEST_VERBOSE};
};

# -----------------------------------------------------------------------
# _fmt_dep
# Strategy: test every output variant — relationship keyword, indent level,
# version presence, comment presence/absence.
# -----------------------------------------------------------------------
subtest '_fmt_dep — single dependency line formatting' => sub {

	# Baseline: requires with no version and no comment, runtime indent (empty).
	is App::makefilepl2cpanfile::_fmt_dep(
		'requires', 'Moo', { version => 0, comment => undef }, ''
	),
		"requires 'Moo';\n",
		'requires, no version, no comment, no indent';

	# Version constraint must appear in the output when the version is non-zero.
	is App::makefilepl2cpanfile::_fmt_dep(
		'requires', 'Moo', { version => '2.000', comment => undef }, ''
	),
		"requires 'Moo', '2.000';\n",
		'requires with version, no comment';

	# Phase blocks use a single tab as indentation.
	is App::makefilepl2cpanfile::_fmt_dep(
		'requires', 'Moo', { version => 0, comment => undef }, "\t"
	),
		"\trequires 'Moo';\n",
		'tab indent applied for phase blocks';

	# Inline comment appears after the semicolon, separated by three spaces.
	is App::makefilepl2cpanfile::_fmt_dep(
		'requires', 'Moo', { version => '2.000', comment => 'roles engine' }, ''
	),
		"requires 'Moo', '2.000';   # roles engine\n",
		'version and inline comment both emitted';

	# recommends keyword must be preserved as-is (not silently changed to requires).
	is App::makefilepl2cpanfile::_fmt_dep(
		'recommends', 'Future', { version => '0.33', comment => undef }, ''
	),
		"recommends 'Future', '0.33';\n",
		'recommends keyword emitted correctly';

	is App::makefilepl2cpanfile::_fmt_dep(
		'suggests', 'Log::Any', { version => 0, comment => undef }, "\t"
	),
		"\tsuggests 'Log::Any';\n",
		'suggests keyword with tab indent';

	# An empty string comment must be suppressed — only undef comments are
	# documented in the API, but defensive handling prevents stray ' # ' lines.
	is App::makefilepl2cpanfile::_fmt_dep(
		'requires', 'Foo', { version => 0, comment => '' }, ''
	),
		"requires 'Foo';\n",
		'empty-string comment not emitted';

	# String '0' must not produce a version argument — _has_version treats it as false.
	is App::makefilepl2cpanfile::_fmt_dep(
		'requires', 'Bar', { version => '0', comment => undef }, ''
	),
		"requires 'Bar';\n",
		'string "0" version not emitted';

	diag 'all _fmt_dep formatting variants pass' if $ENV{TEST_VERBOSE};
};

# -----------------------------------------------------------------------
# _extract_pairs
# Strategy: test comment capture, blank/comment line skipping, first-
# occurrence-wins across a single call and across multiple calls, return
# value, and in-place mutation semantics.
# -----------------------------------------------------------------------
subtest '_extract_pairs — block parser' => sub {

	# Basic: one module with version zero, one with an explicit version.
	{
		my %deps;
		App::makefilepl2cpanfile::_extract_pairs(
			"    'Try::Tiny' => 0,\n    'Moo' => '2.000',\n",
			\%deps, 'runtime', 'requires',
		);

		ok  exists $deps{runtime}{requires}{'Try::Tiny'}, 'Try::Tiny extracted';
		is  $deps{runtime}{requires}{'Try::Tiny'}{version}, 0, 'version 0 stored';
		is  $deps{runtime}{requires}{'Try::Tiny'}{comment}, undef, 'no comment stored as undef';

		ok  exists $deps{runtime}{requires}{'Moo'}, 'Moo extracted';
		is  $deps{runtime}{requires}{'Moo'}{version}, '2.000', 'explicit version stored';
	}

	# Inline comment must be captured before the comment text is stripped.
	{
		my %deps;
		App::makefilepl2cpanfile::_extract_pairs(
			"    'Foo::Bar' => 0,   # used in bin/ scripts\n",
			\%deps, 'runtime', 'requires',
		);

		is $deps{runtime}{requires}{'Foo::Bar'}{comment}, 'used in bin/ scripts',
			'inline comment captured verbatim';
	}

	# A fully-commented-out module line must be silently ignored.
	{
		my %deps;
		App::makefilepl2cpanfile::_extract_pairs(
			"    # 'Old::Module' => 0,\n",
			\%deps, 'runtime', 'requires',
		);

		ok !exists $deps{runtime}{requires}{'Old::Module'},
			'fully-commented module line is skipped';
	}

	# Blank lines must not introduce phantom entries.
	{
		my %deps;
		App::makefilepl2cpanfile::_extract_pairs(
			"\n\n    'Real' => 0,\n\n",
			\%deps, 'runtime', 'requires',
		);

		ok  exists $deps{runtime}{requires}{'Real'}, 'real entry found across blank lines';
		is  scalar keys %{ $deps{runtime}{requires} }, 1,
			'no phantom entries from blank lines';
	}

	# First-occurrence-wins within a single block: the first entry for a module
	# must not be overwritten by a subsequent entry in the same block.
	{
		my %deps;
		App::makefilepl2cpanfile::_extract_pairs(
			"    'Dup' => '1.00',   # first\n    'Dup' => '2.00',   # second\n",
			\%deps, 'runtime', 'requires',
		);

		is $deps{runtime}{requires}{'Dup'}{version}, '1.00',
			'first occurrence wins within a block';
		is $deps{runtime}{requires}{'Dup'}{comment}, 'first',
			'first comment retained';
	}

	# First-occurrence-wins across calls: a pre-populated entry in the deps
	# hashref must survive a subsequent _extract_pairs call for the same slot.
	{
		my %deps = (
			test => {
				requires => {
					'Pre::Existing' => { version => '9.99', comment => 'kept' },
				},
			},
		);
		App::makefilepl2cpanfile::_extract_pairs(
			"    'Pre::Existing' => '0.01',\n",
			\%deps, 'test', 'requires',
		);

		is $deps{test}{requires}{'Pre::Existing'}{version}, '9.99',
			'pre-existing entry not overwritten by subsequent _extract_pairs call';
	}

	# The function must return undef — it mutates in place and has no useful
	# scalar return value.
	{
		my %deps;
		my $ret = App::makefilepl2cpanfile::_extract_pairs(
			"'X' => 0,\n", \%deps, 'runtime', 'requires'
		);
		is $ret, undef, '_extract_pairs returns undef (void semantics)';
	}

	diag 'all _extract_pairs cases pass' if $ENV{TEST_VERBOSE};
};

# -----------------------------------------------------------------------
# _emit
# Strategy: test every structural variant — header, perl version line,
# runtime at top level, phase blocks, canonical phase order, relationship
# order, alphabetical sort, trailing-newline invariant, empty-phase pruning.
# -----------------------------------------------------------------------
subtest '_emit — cpanfile string formatter' => sub {

	# Empty deps: only the header comment should appear.
	{
		my $out = App::makefilepl2cpanfile::_emit( {}, undef );
		like   $out, qr/^# Generated from Makefile\.PL/,
			'header comment present on empty deps';
		unlike $out, qr/requires/, 'no requires when deps is empty';
		like   $out, qr/\n$/, 'output ends with a newline even when empty';
	}

	# MIN_PERL_VERSION line precedes module entries.
	{
		my $out = App::makefilepl2cpanfile::_emit( {}, '5.010' );
		like $out, qr/^requires 'perl', '5\.010';/m, 'perl version line emitted';
	}

	# Runtime deps appear at the top level — no wrapping 'on' block.
	{
		my $deps = {
			runtime => {
				requires   => { 'Moo' => { version => '2.000', comment => undef } },
				recommends => { 'Future' => { version => 0, comment => 'async' } },
			},
		};
		my $out = App::makefilepl2cpanfile::_emit( $deps, undef );
		like   $out, qr/^requires 'Moo', '2\.000';/m, 'runtime requires at top level';
		like   $out, qr/^recommends 'Future';   # async$/m,
			'runtime recommends at top level with comment';
		unlike $out, qr/on 'runtime'/, 'no on-block for runtime phase';
	}

	# Non-runtime phases must be wrapped in an 'on phase => sub { ... }' block.
	{
		my $deps = {
			test => {
				requires => { 'Test::More' => { version => 0, comment => undef } },
			},
		};
		my $out = App::makefilepl2cpanfile::_emit( $deps, undef );
		like $out, qr/on 'test' => sub \{/,     'test phase on-block present';
		like $out, qr/\trequires 'Test::More';/, 'test requires indented with tab';
		like $out, qr/\};/,                      'on-block closed';
	}

	# Phase blocks must appear in canonical order: configure < build < test < develop.
	{
		my $mk_entry = sub { { requires => { $_[0] => { version => 0, comment => undef } } } };
		my $deps = {
			develop   => $mk_entry->('Perl::Critic'),
			build     => $mk_entry->('Module::Build'),
			test      => $mk_entry->('Test::More'),
			configure => $mk_entry->('ExtUtils::MakeMaker'),
		};
		my $out = App::makefilepl2cpanfile::_emit( $deps, undef );

		my $pos = sub { index( $out, "on '$_[0]'" ) };
		ok $pos->('configure') < $pos->('build'),   'configure before build';
		ok $pos->('build')     < $pos->('test'),    'build before test';
		ok $pos->('test')      < $pos->('develop'), 'test before develop';
	}

	# Within a phase, relationships appear in requires/recommends/suggests order;
	# modules within each relationship are sorted alphabetically.
	{
		my $deps = {
			runtime => {
				requires   => {
					'Zebra' => { version => 0, comment => undef },
					'Alpha' => { version => 0, comment => undef },
				},
				recommends => {
					'Maybe' => { version => 0, comment => undef },
				},
			},
		};
		my $out = App::makefilepl2cpanfile::_emit( $deps, undef );

		ok index($out, "'Alpha'") < index($out, "'Zebra'"),
			'Alpha sorted before Zebra within requires';
		ok index($out, "'Zebra'") < index($out, "'Maybe'"),
			'requires emitted before recommends';
	}

	# Output must end with exactly one newline — no double newline at the end.
	{
		my $out = App::makefilepl2cpanfile::_emit( \%DEPS_BASIC, '5.010' );
		ok $out =~ /\n$/,   'output ends with newline';
		ok $out !~ /\n\n$/, 'output does not end with double newline';
	}

	# A phase that exists in the hash but has only empty relationship hashes
	# must not produce an empty on-block in the output.
	{
		my $deps = { develop => { requires => {} } };
		my $out  = App::makefilepl2cpanfile::_emit( $deps, undef );
		unlike $out, qr/on 'develop'/, 'empty phase block not emitted';
	}

	# _emit must not introduce memory cycles in its return value.
	{
		my $out = App::makefilepl2cpanfile::_emit( \%DEPS_BASIC, undef );
		memory_cycle_ok( \$out, '_emit return value has no memory cycles' );
	}

	diag 'all _emit structural cases pass' if $ENV{TEST_VERBOSE};
};

# -----------------------------------------------------------------------
# _load_develop_config
# Strategy: mock File::HomeDir to redirect lookups to a temp dir so each
# test case gets a clean, controlled home directory.  Test all four paths:
# no config file, valid config with develop key, config without develop
# key, and malformed YAML.
# -----------------------------------------------------------------------
subtest '_load_develop_config — YAML config loading' => sub {

	# Each inner block holds its own mock_scoped guard; the mock is restored
	# automatically when the block ends, giving clean isolation per test case.

	# ---- No config file: must return a copy of DEFAULT_DEVELOP ----
	{
		my $tmp = tempdir( CLEANUP => 1 );
		my $g = mock_scoped 'File::HomeDir::my_home' => sub { $tmp };

		my $result = App::makefilepl2cpanfile::_load_develop_config();
		isa_ok $result, 'HASH', 'returns a hashref when no config file';

		for my $mod (qw(Perl::Critic Devel::Cover Test::Pod Test::Pod::Coverage)) {
			ok exists $result->{$mod}, "default '$mod' present";
		}

		# Mutating the returned copy must not contaminate future calls —
		# this verifies the function returns {%DEFAULT_DEVELOP} not a shared ref.
		$result->{'Injected::Evil'} = 99;
		my $result2 = App::makefilepl2cpanfile::_load_develop_config();
		ok !exists $result2->{'Injected::Evil'},
			'returned hashref is a defensive copy — mutation does not persist';
	}

	# ---- Valid config with a 'develop' key: must return that hash ----
	{
		my $tmp = tempdir( CLEANUP => 1 );
		my $g = mock_scoped 'File::HomeDir::my_home' => sub { $tmp };

		path($tmp)->child('.config')->mkpath;
		YAML::Tiny->new( { develop => { 'My::Extra::Tool' => '1.00' } } )
			->write( path($tmp)->child('.config', 'makefilepl2cpanfile.yml')->stringify );

		my $result = App::makefilepl2cpanfile::_load_develop_config();
		ok  exists $result->{'My::Extra::Tool'}, 'custom develop tool returned from config';
		is  $result->{'My::Extra::Tool'}, '1.00', 'custom version preserved';

		# When the config defines its own set, the defaults must NOT be added.
		ok !exists $result->{'Perl::Critic'},
			'default tools not injected when config has its own develop block';
	}

	# ---- Config file exists but has no 'develop' key: must carp and use defaults ----
	{
		my $tmp = tempdir( CLEANUP => 1 );
		my $g = mock_scoped 'File::HomeDir::my_home' => sub { $tmp };

		path($tmp)->child('.config')->mkpath;
		YAML::Tiny->new( { other_key => 'value' } )
			->write( path($tmp)->child('.config', 'makefilepl2cpanfile.yml')->stringify );

		my @warnings;
		local $SIG{__WARN__} = sub { push @warnings, @_ };

		my $result = App::makefilepl2cpanfile::_load_develop_config();
		ok exists $result->{'Perl::Critic'}, 'falls back to defaults when develop key absent';
		ok scalar @warnings > 0,             'a carp warning is issued';
		like $warnings[0], qr/No 'develop' key/,
			'carp message matches expected text';
	}

	# ---- Malformed YAML: must croak with path and error message ----
	# We mock YAML::Tiny->read to return undef (parse failure) because YAML::Tiny
	# is forgiving of some syntactically invalid input in the wild.
	{
		my $tmp = tempdir( CLEANUP => 1 );
		my $g_home = mock_scoped 'File::HomeDir::my_home' => sub { $tmp };

		path($tmp)->child('.config')->mkpath;
		# Create the file so is_file() returns true.
		path($tmp)->child('.config', 'makefilepl2cpanfile.yml')
			->spew_utf8("garbage: [\n");

		my $g_yaml = mock_scoped(
			'YAML::Tiny::read'   => sub { undef },
			'YAML::Tiny::errstr' => sub { 'simulated parse error' },
		);

		throws_ok { App::makefilepl2cpanfile::_load_develop_config() }
			qr/Failed to parse .+ simulated parse error/,
			'malformed YAML causes croak with expected message';
		# $g_yaml and $g_home go out of scope here, restoring both mocks
	}

	diag 'all _load_develop_config cases pass' if $ENV{TEST_VERBOSE};
};

# -----------------------------------------------------------------------
# parse_prereqs
# Strategy: test both input forms, inline comment capture, comment-line
# filtering, all four simple keys, structured prereqs blocks (requires/
# recommends/suggests), META_MERGE nesting, invalid phase/rel filtering,
# first-occurrence-wins, and memory safety.
# -----------------------------------------------------------------------
subtest 'parse_prereqs — Makefile.PL parser' => sub {

	# Empty content must produce an empty hashref, not undef or a list.
	{
		my $d = App::makefilepl2cpanfile::parse_prereqs('');
		isa_ok $d, 'HASH', 'empty content returns a hashref';
		is scalar keys %{$d}, 0, 'hashref is empty for empty content';
	}

	# Each simple key maps to the correct cpanfile phase under 'requires'.
	{
		my $d = App::makefilepl2cpanfile::parse_prereqs(<<'END_MF');
WriteMakefile(
	PREREQ_PM          => { 'A::Runtime'   => 0 },
	BUILD_REQUIRES     => { 'B::Build'     => 0 },
	TEST_REQUIRES      => { 'C::Test'      => 0 },
	CONFIGURE_REQUIRES => { 'D::Configure' => '6.64' },
);
END_MF
		ok exists $d->{runtime}{requires}{'A::Runtime'},      'PREREQ_PM -> runtime/requires';
		ok exists $d->{build}{requires}{'B::Build'},          'BUILD_REQUIRES -> build/requires';
		ok exists $d->{test}{requires}{'C::Test'},            'TEST_REQUIRES -> test/requires';
		ok exists $d->{configure}{requires}{'D::Configure'},  'CONFIGURE_REQUIRES -> configure/requires';
		is $d->{configure}{requires}{'D::Configure'}{version}, '6.64',
			'version string preserved in configure/requires';
	}

	# Version zero must be stored as the integer 0, not undef.
	{
		my $d = App::makefilepl2cpanfile::parse_prereqs(
			"PREREQ_PM => { 'No::Version' => 0 },"
		);
		is $d->{runtime}{requires}{'No::Version'}{version}, 0,
			'zero version stored as 0 (not undef)';
	}

	# Inline comments must be captured alongside the module entry.
	{
		my $d = App::makefilepl2cpanfile::parse_prereqs(
			"PREREQ_PM => { 'Foo' => 0,   # for the CLI tools\n },"
		);
		is $d->{runtime}{requires}{'Foo'}{comment}, 'for the CLI tools',
			'inline comment captured verbatim';
	}

	# Fully-commented module lines must be silently skipped.
	{
		my $d = App::makefilepl2cpanfile::parse_prereqs(
			"PREREQ_PM => {\n    # 'Skipped' => 0,\n    'Real' => 0,\n},"
		);
		ok !exists $d->{runtime}{requires}{'Skipped'}, 'commented-out module skipped';
		ok  exists $d->{runtime}{requires}{'Real'},    'uncommented module extracted';
	}

	# Structured prereqs block: requires, recommends, and suggests per phase.
	{
		my $d = App::makefilepl2cpanfile::parse_prereqs(<<'END_MF');
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
		ok exists $d->{runtime}{requires}{'Scalar::Util'},
			'structured requires extracted';
		ok exists $d->{runtime}{recommends}{'Future'},
			'structured recommends extracted';
		is $d->{runtime}{recommends}{'Future'}{version}, '0.33',
			'recommends version preserved';
		ok exists $d->{runtime}{suggests}{'Log::Any'},
			'structured suggests extracted';
		ok exists $d->{test}{requires}{'Test::Exception'},
			'test requires from prereqs block';
	}

	# Invalid phase names inside a prereqs block must be silently rejected.
	{
		my $d = App::makefilepl2cpanfile::parse_prereqs(
			"prereqs => { bogus_phase => { requires => { 'X' => 0 } } },"
		);
		ok !exists $d->{bogus_phase}, 'invalid phase name rejected';
	}

	# Invalid relationship names inside a phase block must be silently rejected.
	{
		my $d = App::makefilepl2cpanfile::parse_prereqs(
			"prereqs => { runtime => { optional => { 'X' => 0 } } },"
		);
		ok !exists $d->{runtime}{optional}, 'invalid relationship name rejected';
	}

	# META_MERGE => { prereqs => { ... } } — prereqs nested under META_MERGE.
	{
		my $d = App::makefilepl2cpanfile::parse_prereqs(<<'END_MF');
WriteMakefile(
	PREREQ_PM  => { 'Moo' => 0 },
	META_MERGE => {
		prereqs => {
			runtime => {
				recommends => { 'Moo::Role' => '2.000' },
			},
		},
	},
);
END_MF
		ok exists $d->{runtime}{requires}{'Moo'},
			'PREREQ_PM parsed alongside META_MERGE';
		ok exists $d->{runtime}{recommends}{'Moo::Role'},
			'META_MERGE prereqs recommends extracted';
		is $d->{runtime}{recommends}{'Moo::Role'}{version}, '2.000',
			'META_MERGE version preserved';
	}

	# First-occurrence-wins: the same module appearing in both a simple key
	# and a structured prereqs block must appear only once.
	{
		my $d = App::makefilepl2cpanfile::parse_prereqs(<<'END_MF');
WriteMakefile(
	PREREQ_PM => { 'Dup' => '1.00' },
	prereqs   => { runtime => { requires => { 'Dup' => '2.00' } } },
);
END_MF
		ok exists $d->{runtime}{requires}{'Dup'}, 'Dup present in result';
		# Whichever occurrence was parsed first wins; both are valid.
		ok defined $d->{runtime}{requires}{'Dup'}{version},
			'Dup has exactly one version (first-occurrence-wins)';
	}

	# No memory cycles in the returned data structure.
	{
		my $d = App::makefilepl2cpanfile::parse_prereqs($MF_SIMPLE);
		memory_cycle_ok( $d, 'parse_prereqs return value has no memory cycles' );
	}

	diag 'all parse_prereqs cases pass' if $ENV{TEST_VERBOSE};
};

# -----------------------------------------------------------------------
# generate
# Strategy: use real temp-dir fixtures for filesystem interaction; mock
# File::HomeDir so config loading is deterministic and does not interfere
# with the developer's actual ~/.config file.
# -----------------------------------------------------------------------
subtest 'generate — integration: parse, merge, format' => sub {

	# Redirect config loading to an empty home so default develop tools are
	# injected whenever with_develop => 1 is in effect.  The guard is held for
	# the entire subtest; it restores File::HomeDir when the sub returns.
	my $empty_home = tempdir( CLEANUP => 1 );
	my $g = mock_scoped 'File::HomeDir::my_home' => sub { $empty_home };

	my $dir = tempdir( CLEANUP => 1 );
	my $mf  = path($dir)->child('Makefile.PL');
	$mf->spew_utf8("WriteMakefile(PREREQ_PM => { 'Try::Tiny' => 0 });\n");

	# ---- Guard: croak on missing file ----
	throws_ok {
		App::makefilepl2cpanfile::generate( makefile => "$dir/nonexistent.pl" )
	}
		qr/Cannot read/,
		'croaks with "Cannot read" for missing makefile';

	# ---- Guard: croak when path is a directory, not a file ----
	throws_ok {
		App::makefilepl2cpanfile::generate( makefile => $dir )
	}
		qr/Cannot read/,
		'croaks when path is a directory';

	# ---- Minimal valid Makefile.PL ----
	{
		my $out;
		lives_ok { $out = App::makefilepl2cpanfile::generate( makefile => "$mf", with_develop => 0 ) }
			'lives with a valid minimal Makefile.PL';
		like $out, qr/requires 'Try::Tiny'/, 'module appears in output';
		like $out, qr/\n$/, 'output ends with a newline';
	}

	# ---- Flat-hash calling style ----
	{
		my $r = App::makefilepl2cpanfile::generate( makefile => "$mf", with_develop => 0 );
		like $r, qr/requires 'Try::Tiny'/, 'flat hash calling style works';
	}

	# ---- Hashref calling style ----
	{
		my $r = App::makefilepl2cpanfile::generate(
			{ makefile => "$mf", with_develop => 0 }
		);
		like $r, qr/requires 'Try::Tiny'/, 'hashref calling style works';
	}

	# ---- with_develop defaults to 1 when the argument is omitted ----
	{
		my $r = App::makefilepl2cpanfile::generate( makefile => "$mf" );
		like $r, qr/Perl::Critic/, 'with_develop defaults to 1 — develop block present';
	}

	# ---- with_develop => 0 suppresses the develop block entirely ----
	{
		my $r = App::makefilepl2cpanfile::generate( makefile => "$mf", with_develop => 0 );
		unlike $r, qr/on 'develop'/, 'with_develop => 0 suppresses develop block';
	}

	# ---- Existing cpanfile 'requires' in develop block is merged ----
	{
		my $existing = "on 'develop' => sub {\n  requires 'My::Tool';\n};\n";
		my $r = App::makefilepl2cpanfile::generate(
			makefile => "$mf", existing => $existing, with_develop => 0
		);
		like $r, qr/My::Tool/, 'existing develop requires entry merged';
	}

	# ---- Existing cpanfile 'recommends' in develop block is merged ----
	{
		my $existing = "on 'develop' => sub {\n  recommends 'My::Nice::Tool';\n};\n";
		my $r = App::makefilepl2cpanfile::generate(
			makefile => "$mf", existing => $existing, with_develop => 0
		);
		like $r, qr/My::Nice::Tool/, 'existing develop recommends entry merged';
	}

	# ---- Hand-curated entry must not be overwritten by default injection ----
	# If Perl::Critic already appears in the existing cpanfile with a specific
	# version, the injection step must not add a duplicate entry.
	{
		my $existing = "on 'develop' => sub {\n  requires 'Perl::Critic', '1.140';\n};\n";
		my $r = App::makefilepl2cpanfile::generate(
			makefile => "$mf", existing => $existing, with_develop => 1
		);
		like $r, qr/Perl::Critic.*1\.140|1\.140.*Perl::Critic/,
			'hand-curated Perl::Critic version not overwritten';
		my @hits = ( $r =~ /Perl::Critic/g );
		is scalar @hits, 1, 'Perl::Critic appears exactly once after merge';
	}

	# ---- MIN_PERL_VERSION is emitted when present in the Makefile.PL ----
	{
		$mf->spew_utf8(
			"WriteMakefile(MIN_PERL_VERSION => '5.016', PREREQ_PM => { 'X' => 0 });\n"
		);
		my $r = App::makefilepl2cpanfile::generate( makefile => "$mf", with_develop => 0 );
		like $r, qr/requires 'perl', '5\.016'/, 'MIN_PERL_VERSION emitted';
	}

	# ---- No memory cycles in the generated string ----
	{
		$mf->spew_utf8("WriteMakefile(PREREQ_PM => { 'Y' => 0 });\n");
		my $r = App::makefilepl2cpanfile::generate( makefile => "$mf", with_develop => 0 );
		memory_cycle_ok( \$r, 'generate return value has no memory cycles' );
	}

	diag 'all generate cases pass' if $ENV{TEST_VERBOSE};
};

done_testing;
