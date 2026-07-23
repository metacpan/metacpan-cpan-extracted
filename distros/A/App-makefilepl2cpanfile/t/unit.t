use strict;
use warnings;

# Black-box tests for the two public functions: generate() and parse_prereqs().
# Tests are derived strictly from the POD API contracts, not the implementation.

use Test::Most;
use Test::Mockingbird;
use File::Temp qw(tempdir);
use Path::Tiny;
use Readonly;
use YAML::Tiny;

use App::makefilepl2cpanfile;

# -----------------------------------------------------------------------
# Ledger — every documented message and return state is registered here.
# Each subtest deletes the entry it covers.  After all subtests run, we
# assert the ledger is empty; any remaining entries mean the test suite
# has a coverage gap for a documented API contract.
# -----------------------------------------------------------------------

my %LEDGER = (
	# generate() — documented error messages (MESSAGES section)
	'generate.croak.cannot_read.missing'         => q{Cannot read '$makefile' — file missing},
	'generate.croak.cannot_read.directory'       => q{Cannot read '$makefile' — path is a directory},
	'generate.croak.failed_to_parse_yaml'        => q{Failed to parse $cfg_file: ...},
	'generate.carp.no_develop_key'               => q{No 'develop' key found in $cfg_file; using defaults},

	# generate() — documented return state / API contracts
	'generate.return.string_single_newline'      => q{Returns Str terminated with a single newline},
	'generate.arg.default_makefile'              => q{Default makefile is 'Makefile.PL'},
	'generate.arg.default_existing_empty'        => q{Default existing is empty string},
	'generate.arg.default_with_develop_true'     => q{Default with_develop is 1 (true)},
	'generate.calling.flat_hash'                 => q{Flat hash calling style accepted},
	'generate.calling.hashref'                   => q{Single hashref calling style accepted},
	'generate.develop.injected_when_true'        => q{Develop block present when with_develop => 1},
	'generate.develop.suppressed_when_false'     => q{No develop block when with_develop => 0},
	'generate.develop.merge_existing_requires'   => q{Existing develop requires entries merged},
	'generate.develop.merge_existing_recommends' => q{Existing develop recommends entries merged},
	'generate.develop.merge_existing_suggests'   => q{Existing develop suggests entries merged},
	'generate.develop.no_overwrite'              => q{Hand-curated develop entries not overwritten},

	# parse_prereqs() — documented return structure contracts
	'parse_prereqs.return.hashref'               => q{Returns a HashRef},
	'parse_prereqs.return.absent_phase_missing'  => q{Absent phases not present in hashref},
	'parse_prereqs.return.version_zero'          => q{version is 0 when no minimum declared},
	'parse_prereqs.return.comment_undef'         => q{comment is undef when no inline comment},
	'parse_prereqs.map.prereq_pm'                => q{PREREQ_PM maps to runtime/requires},
	'parse_prereqs.map.build_requires'           => q{BUILD_REQUIRES maps to build/requires},
	'parse_prereqs.map.test_requires'            => q{TEST_REQUIRES maps to test/requires},
	'parse_prereqs.map.configure_requires'       => q{CONFIGURE_REQUIRES maps to configure/requires},
	'parse_prereqs.structured.requires'          => q{Structured prereqs block: requires},
	'parse_prereqs.structured.recommends'        => q{Structured prereqs block: recommends},
	'parse_prereqs.structured.suggests'          => q{Structured prereqs block: suggests},
	'parse_prereqs.meta_merge.prereqs'           => q{META_MERGE nested prereqs extracted},
	'parse_prereqs.inline_comment'               => q{Inline comment captured verbatim},
	'parse_prereqs.silent.unrecognised'          => q{Unrecognised content silently ignored},
);

# Helper: mark a ledger entry as covered, fail loudly if the key was never registered.
sub covered {
	my ($key) = @_;
	fail("Unknown ledger key '$key'") unless exists $LEDGER{$key};
	delete $LEDGER{$key};
}

# -----------------------------------------------------------------------
# Shared fixture factories
# -----------------------------------------------------------------------

# Set up a redirected home directory so _load_develop_config never touches
# the developer's real ~/.config during testing.  Each helper returns a
# mock_scoped guard; callers must hold it (my $g = empty_home()) so the
# mock stays active for the lifetime of the enclosing subtest block.

# A fresh tempdir representing a home dir with NO config file.
sub empty_home {
	my $h = tempdir( CLEANUP => 1 );
	return mock_scoped 'File::HomeDir::my_home' => sub { $h };
}

# Write a YAML config to a fake home dir and return the scoped guard.
sub home_with_config {
	my ($data) = @_;
	my $h = tempdir( CLEANUP => 1 );
	path($h)->child('.config')->mkpath;
	YAML::Tiny->new($data)
		->write( path($h)->child('.config', 'makefilepl2cpanfile.yml')->stringify );
	return mock_scoped 'File::HomeDir::my_home' => sub { $h };
}

# Write a Makefile.PL into a tempdir and return its path object.
sub make_mf {
	my ($content) = @_;
	my $dir = tempdir( CLEANUP => 1 );
	my $mf  = path($dir)->child('Makefile.PL');
	$mf->spew_utf8($content);
	return $mf;
}

Readonly my $MF_SIMPLE =>
	"WriteMakefile(PREREQ_PM => { 'Try::Tiny' => 0 });\n";

Readonly my $MF_VERSIONED =>
	"WriteMakefile(PREREQ_PM => { 'Moo' => '2.000' });\n";

# -----------------------------------------------------------------------
# generate() — error / message paths
# -----------------------------------------------------------------------

subtest 'generate() — croak on unreadable makefile' => sub {
	my $g = empty_home();

	# Missing file: the path does not exist at all.
	my $missing = '/no/such/path/Makefile.PL';
	throws_ok {
		App::makefilepl2cpanfile::generate( makefile => $missing )
	} qr/Cannot read '\Q$missing\E'/, q{exact croak message for missing file};
	covered('generate.croak.cannot_read.missing');

	# Directory: the path exists but is not a file.
	my $dir = tempdir( CLEANUP => 1 );
	throws_ok {
		App::makefilepl2cpanfile::generate( makefile => $dir )
	} qr/Cannot read '\Q$dir\E'/, q{exact croak message when path is a directory};
	covered('generate.croak.cannot_read.directory');

	diag 'generate croak paths verified' if $ENV{TEST_VERBOSE};
};

subtest 'generate() — croak on malformed YAML config' => sub {
	# Config file must exist so _load_develop_config proceeds to YAML::Tiny->read.
	my $g_home = home_with_config( {} );    # creates the file; content irrelevant

	# mock_scoped with multiple pairs restores both methods when $g_yaml goes out
	# of scope at the end of this subtest block.
	my $g_yaml = mock_scoped(
		'YAML::Tiny::read'   => sub { undef },
		'YAML::Tiny::errstr' => sub { 'synthetic YAML failure' },
	);

	my $mf = make_mf($MF_SIMPLE);
	throws_ok {
		App::makefilepl2cpanfile::generate(
			makefile     => "$mf",
			with_develop => 1,
		)
	} qr/Failed to parse .+: synthetic YAML failure/,
		q{croak message includes path and YAML error string};
	covered('generate.croak.failed_to_parse_yaml');

	diag 'generate YAML croak verified' if $ENV{TEST_VERBOSE};
};

subtest 'generate() — carp when config has no develop key' => sub {
	# Config file exists but its 'develop' key is absent.
	my $g = home_with_config( { other_section => { tool => 1 } } );

	my $mf = make_mf($MF_SIMPLE);

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		with_develop => 1,
	);

	ok scalar @warnings > 0, 'a carp warning was issued';
	like $warnings[0], qr/No 'develop' key found in .+; using defaults/,
		q{carp message matches documented text exactly};
	covered('generate.carp.no_develop_key');

	diag 'generate carp verified' if $ENV{TEST_VERBOSE};
};

# -----------------------------------------------------------------------
# generate() — return value contract
# -----------------------------------------------------------------------

subtest 'generate() — return value is Str terminated with a single newline' => sub {
	my $g = empty_home();

	my $mf  = make_mf($MF_SIMPLE);
	my $out = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		with_develop => 0,
	);

	ok  defined $out,       'return value is defined';
	ok !ref $out,           'return value is a plain scalar (Str)';
	like $out, qr/\n$/,     'output ends with a newline';
	ok  $out !~ /\n\n$/,    'output does not end with a double newline';
	covered('generate.return.string_single_newline');

	diag 'generate return contract verified' if $ENV{TEST_VERBOSE};
};

# -----------------------------------------------------------------------
# generate() — default argument values
# -----------------------------------------------------------------------

subtest 'generate() — default argument: makefile is "Makefile.PL"' => sub {
	my $g = empty_home();

	# The POD says: default makefile is 'Makefile.PL'.  We test this by
	# chdir-ing to a tempdir that contains a Makefile.PL and calling generate()
	# without a makefile argument.
	my $dir = tempdir( CLEANUP => 1 );
	path($dir)->child('Makefile.PL')->spew_utf8($MF_SIMPLE);

	my $orig = Path::Tiny->cwd;
	chdir $dir;

	my $out;
	lives_ok {
		$out = App::makefilepl2cpanfile::generate( with_develop => 0 )
	} 'generate() reads Makefile.PL from cwd when no makefile arg given';
	like $out, qr/Try::Tiny/, 'content from default Makefile.PL appears in output';

	chdir "$orig";
	covered('generate.arg.default_makefile');
};

subtest 'generate() — default argument: existing is empty string' => sub {
	my $g = empty_home();

	# When 'existing' is omitted, no pre-existing develop entries should be
	# merged (there are none to merge from an empty string).
	my $mf = make_mf($MF_SIMPLE);
	my $out;
	lives_ok {
		$out = App::makefilepl2cpanfile::generate(
			makefile     => "$mf",
			with_develop => 0,
		)
	} 'generate() with no existing arg lives';

	# The output must contain the parsed module but no phantom develop entries
	# from a non-existent pre-existing cpanfile.
	like   $out, qr/Try::Tiny/, 'parsed module present';
	unlike $out, qr/on 'develop' => sub/, 'no develop block from empty existing';
	covered('generate.arg.default_existing_empty');
};

subtest 'generate() — default argument: with_develop is 1 (true)' => sub {
	my $g = empty_home();    # no config file -> uses DEFAULT_DEVELOP

	my $mf  = make_mf($MF_SIMPLE);
	my $out = App::makefilepl2cpanfile::generate( makefile => "$mf" );

	# A develop block must appear because with_develop defaults to 1.
	like $out, qr/on 'develop' => sub/,
		'develop block present when with_develop omitted (default true)';
	covered('generate.arg.default_with_develop_true');
};

# -----------------------------------------------------------------------
# generate() — calling style variants
# -----------------------------------------------------------------------

subtest 'generate() — flat hash calling style' => sub {
	my $g = empty_home();
	my $mf  = make_mf($MF_SIMPLE);
	my $out = App::makefilepl2cpanfile::generate( makefile => "$mf", with_develop => 0 );
	like $out, qr/Try::Tiny/, 'flat hash calling style works';
	covered('generate.calling.flat_hash');
};

subtest 'generate() — hashref calling style' => sub {
	my $g = empty_home();
	my $mf  = make_mf($MF_SIMPLE);
	my $out = App::makefilepl2cpanfile::generate(
		{ makefile => "$mf", with_develop => 0 }
	);
	like $out, qr/Try::Tiny/, 'single hashref calling style works';
	covered('generate.calling.hashref');
};

# -----------------------------------------------------------------------
# generate() — with_develop behaviour
# -----------------------------------------------------------------------

subtest 'generate() — develop block injected when with_develop => 1' => sub {
	# Use an empty home so default tools (Perl::Critic etc.) are injected.
	my $g = empty_home();

	my $mf  = make_mf($MF_SIMPLE);
	my $out = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		with_develop => 1,
	);

	like $out, qr/on 'develop' => sub/, 'develop block present';
	# At least one of the four default tools must appear.
	like $out, qr/Perl::Critic|Devel::Cover|Test::Pod/, 'default dev tool present';
	covered('generate.develop.injected_when_true');
};

subtest 'generate() — develop block suppressed when with_develop => 0' => sub {
	my $g = empty_home();
	my $mf  = make_mf($MF_SIMPLE);
	my $out = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		with_develop => 0,
	);
	unlike $out, qr/on 'develop' => sub/, 'no develop block when with_develop is false';
	covered('generate.develop.suppressed_when_false');
};

# -----------------------------------------------------------------------
# generate() — existing develop block merging (all three relationship types)
# -----------------------------------------------------------------------

subtest 'generate() — merge existing develop requires' => sub {
	my $g = empty_home();
	my $mf       = make_mf($MF_SIMPLE);
	my $existing = "on 'develop' => sub {\n  requires 'My::Linter';\n};\n";
	my $out = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		existing     => $existing,
		with_develop => 0,
	);
	like $out, qr/My::Linter/, 'hand-curated develop requires entry preserved';
	covered('generate.develop.merge_existing_requires');
};

subtest 'generate() — merge existing develop recommends' => sub {
	my $g = empty_home();
	my $mf       = make_mf($MF_SIMPLE);
	my $existing = "on 'develop' => sub {\n  recommends 'My::NiceGUI';\n};\n";
	my $out = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		existing     => $existing,
		with_develop => 0,
	);
	like $out, qr/My::NiceGUI/, 'hand-curated develop recommends entry preserved';
	covered('generate.develop.merge_existing_recommends');
};

subtest 'generate() — merge existing develop suggests' => sub {
	my $g = empty_home();
	my $mf       = make_mf($MF_SIMPLE);
	my $existing = "on 'develop' => sub {\n  suggests 'My::OptionalTool';\n};\n";
	my $out = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		existing     => $existing,
		with_develop => 0,
	);
	like $out, qr/My::OptionalTool/, 'hand-curated develop suggests entry preserved';
	covered('generate.develop.merge_existing_suggests');
};

subtest 'generate() — hand-curated develop entries not overwritten' => sub {
	# If Perl::Critic with a specific version is already in the existing cpanfile,
	# the default-injection step must not clobber it or duplicate it.
	my $g = empty_home();
	my $mf       = make_mf($MF_SIMPLE);
	my $existing = "on 'develop' => sub {\n  requires 'Perl::Critic', '1.140';\n};\n";
	my $out = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		existing     => $existing,
		with_develop => 1,
	);

	# The version-pinned entry must appear exactly once.
	my @hits = ( $out =~ /Perl::Critic/g );
	is scalar @hits, 1, 'Perl::Critic appears exactly once (no duplicate)';
	like $out, qr/Perl::Critic.*1\.140|1\.140.*Perl::Critic/,
		'version-pinned entry preserved';
	covered('generate.develop.no_overwrite');
};

# -----------------------------------------------------------------------
# parse_prereqs() — return value contracts
# -----------------------------------------------------------------------

subtest 'parse_prereqs() — returns a HashRef' => sub {
	my $result = App::makefilepl2cpanfile::parse_prereqs('');
	ok  defined $result, 'return value is defined';
	isa_ok $result, 'HASH', 'return value';
	covered('parse_prereqs.return.hashref');
};

subtest 'parse_prereqs() — absent phases not present in hashref' => sub {
	# POD: "Absent phases/relationships are not present in the hashref."
	# Passing content with only PREREQ_PM means other phases must be absent.
	my $result = App::makefilepl2cpanfile::parse_prereqs(
		"PREREQ_PM => { 'Foo' => 0 },"
	);
	ok !exists $result->{build},     'build phase absent when no BUILD_REQUIRES';
	ok !exists $result->{test},      'test phase absent when no TEST_REQUIRES';
	ok !exists $result->{configure}, 'configure phase absent when no CONFIGURE_REQUIRES';
	ok !exists $result->{develop},   'develop phase absent (not injected by parse_prereqs)';
	covered('parse_prereqs.return.absent_phase_missing');
};

subtest 'parse_prereqs() — version is 0 when no minimum declared' => sub {
	my $result = App::makefilepl2cpanfile::parse_prereqs(
		"PREREQ_PM => { 'No::Min' => 0 },"
	);
	is $result->{runtime}{requires}{'No::Min'}{version}, 0,
		'version stored as 0 when not declared';
	covered('parse_prereqs.return.version_zero');
};

subtest 'parse_prereqs() — comment is undef when no inline comment present' => sub {
	my $result = App::makefilepl2cpanfile::parse_prereqs(
		"PREREQ_PM => { 'Silent::Module' => 0 },"
	);
	is $result->{runtime}{requires}{'Silent::Module'}{comment}, undef,
		'comment is undef when the module line has no inline comment';
	covered('parse_prereqs.return.comment_undef');
};

# -----------------------------------------------------------------------
# parse_prereqs() — simple key mapping
# -----------------------------------------------------------------------

subtest 'parse_prereqs() — PREREQ_PM maps to runtime/requires' => sub {
	my $result = App::makefilepl2cpanfile::parse_prereqs(
		"PREREQ_PM => { 'Runtime::Dep' => '1.00' },"
	);
	ok exists $result->{runtime}{requires}{'Runtime::Dep'},
		'module present under runtime/requires';
	is $result->{runtime}{requires}{'Runtime::Dep'}{version}, '1.00',
		'version preserved';
	covered('parse_prereqs.map.prereq_pm');
};

subtest 'parse_prereqs() — BUILD_REQUIRES maps to build/requires' => sub {
	my $result = App::makefilepl2cpanfile::parse_prereqs(
		"BUILD_REQUIRES => { 'Build::Dep' => 0 },"
	);
	ok exists $result->{build}{requires}{'Build::Dep'},
		'module present under build/requires';
	covered('parse_prereqs.map.build_requires');
};

subtest 'parse_prereqs() — TEST_REQUIRES maps to test/requires' => sub {
	my $result = App::makefilepl2cpanfile::parse_prereqs(
		"TEST_REQUIRES => { 'Test::Dep' => 0 },"
	);
	ok exists $result->{test}{requires}{'Test::Dep'},
		'module present under test/requires';
	covered('parse_prereqs.map.test_requires');
};

subtest 'parse_prereqs() — CONFIGURE_REQUIRES maps to configure/requires' => sub {
	my $result = App::makefilepl2cpanfile::parse_prereqs(
		"CONFIGURE_REQUIRES => { 'Config::Dep' => '6.64' },"
	);
	ok exists $result->{configure}{requires}{'Config::Dep'},
		'module present under configure/requires';
	is $result->{configure}{requires}{'Config::Dep'}{version}, '6.64',
		'version preserved';
	covered('parse_prereqs.map.configure_requires');
};

# -----------------------------------------------------------------------
# parse_prereqs() — structured prereqs block (CPAN Meta Spec style)
# -----------------------------------------------------------------------

subtest 'parse_prereqs() — structured prereqs: requires relationship' => sub {
	my $result = App::makefilepl2cpanfile::parse_prereqs(<<'END_MF');
prereqs => {
	runtime => {
		requires => { 'Struct::Req' => '2.00' },
	},
},
END_MF
	ok exists $result->{runtime}{requires}{'Struct::Req'},
		'structured requires extracted';
	is $result->{runtime}{requires}{'Struct::Req'}{version}, '2.00',
		'structured requires version preserved';
	covered('parse_prereqs.structured.requires');
};

subtest 'parse_prereqs() — structured prereqs: recommends relationship' => sub {
	my $result = App::makefilepl2cpanfile::parse_prereqs(<<'END_MF');
prereqs => {
	runtime => {
		recommends => { 'Nice::Opt' => '0.50' },
	},
},
END_MF
	ok exists $result->{runtime}{recommends}{'Nice::Opt'},
		'structured recommends extracted';
	is $result->{runtime}{recommends}{'Nice::Opt'}{version}, '0.50',
		'structured recommends version preserved';
	covered('parse_prereqs.structured.recommends');
};

subtest 'parse_prereqs() — structured prereqs: suggests relationship' => sub {
	my $result = App::makefilepl2cpanfile::parse_prereqs(<<'END_MF');
prereqs => {
	runtime => {
		suggests => { 'Cool::Extra' => 0 },
	},
},
END_MF
	ok exists $result->{runtime}{suggests}{'Cool::Extra'},
		'structured suggests extracted';
	covered('parse_prereqs.structured.suggests');
};

# -----------------------------------------------------------------------
# parse_prereqs() — META_MERGE nested prereqs
# -----------------------------------------------------------------------

subtest 'parse_prereqs() — META_MERGE nested prereqs extracted' => sub {
	my $result = App::makefilepl2cpanfile::parse_prereqs(<<'END_MF');
META_MERGE => {
	prereqs => {
		runtime => {
			recommends => { 'Meta::Optional' => '1.00' },
		},
	},
},
END_MF
	ok exists $result->{runtime}{recommends}{'Meta::Optional'},
		'META_MERGE prereqs recommends extracted';
	is $result->{runtime}{recommends}{'Meta::Optional'}{version}, '1.00',
		'META_MERGE recommends version preserved';
	covered('parse_prereqs.meta_merge.prereqs');
};

# -----------------------------------------------------------------------
# parse_prereqs() — inline comment capture
# -----------------------------------------------------------------------

subtest 'parse_prereqs() — inline comment captured verbatim' => sub {
	my $result = App::makefilepl2cpanfile::parse_prereqs(
		"PREREQ_PM => { 'Noted::Dep' => 0,   # used only on POSIX\n},"
	);
	is $result->{runtime}{requires}{'Noted::Dep'}{comment}, 'used only on POSIX',
		'inline comment captured verbatim';
	covered('parse_prereqs.inline_comment');
};

# -----------------------------------------------------------------------
# parse_prereqs() — unrecognised content silently ignored
# -----------------------------------------------------------------------

subtest 'parse_prereqs() — unrecognised content silently ignored' => sub {
	# POD: "No errors or warnings — unrecognised content is silently ignored."
	# We pass garbage and verify: no warnings, no die, returns a valid hashref.
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	my $result;
	lives_ok {
		$result = App::makefilepl2cpanfile::parse_prereqs(
			"this is not valid Perl or YAML, just random text !!!\@\@\@###"
		)
	} 'parse_prereqs lives on garbage input';

	isa_ok $result, 'HASH', 'garbage input returns a hashref';
	is scalar @warnings, 0,  'no warnings emitted for unrecognised content';
	covered('parse_prereqs.silent.unrecognised');
};

# -----------------------------------------------------------------------
# Global state integrity: verify generate() does not clobber $@ or $!
# -----------------------------------------------------------------------

subtest 'generate() — does not set $@ on success' => sub {
	my $g = empty_home();
	my $mf = make_mf($MF_SIMPLE);

	# Clear $@ to a known empty state, then assert it is still empty after a
	# successful call.  This catches the case where generate() uses internal
	# eval blocks that fail silently and leak the error into the caller's $@.
	# (Note: successful internal evals reset $@ to '' — that is normal Perl
	# behaviour and not what this test guards against.)
	$@ = '';

	App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		with_develop => 0,
	);

	is $@, '', '$@ is empty after a successful generate() call';
};

# -----------------------------------------------------------------------
# Ledger assertion — all documented states must have been triggered
# -----------------------------------------------------------------------

subtest 'API ledger — all documented states were exercised' => sub {
	if (%LEDGER) {
		for my $key (sort keys %LEDGER) {
			fail("Untested documented state: $key — $LEDGER{$key}");
		}
	} else {
		pass('All documented API states were covered by tests');
	}
};

done_testing;
