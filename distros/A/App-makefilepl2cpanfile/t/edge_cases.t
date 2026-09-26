use strict;
use warnings;

# Destructive, boundary-condition, pathological, and security tests.
#
# Two bugs were discovered during test authoring and fixed in the library:
#
#   BUG 1 - parse_prereqs: undef / reference input emitted Perl warnings.
#     The POD states "No errors or warnings - unrecognised content is silently
#     ignored."  Passing undef caused "Use of uninitialized value" warnings
#     from the pattern-match operators; a reference caused "reference used as
#     string" warnings.
#     FIX: return {} early when $content is undef or a reference.
#
#   BUG 2 - generate: develop-block merge truncated at '}; ' inside comments.
#     The regex /\{(.*?)\};/s terminated at the FIRST '};' anywhere in the
#     existing text, including inside inline comments, silently dropping any
#     module entries that followed the comment.
#     FIX: anchor the terminator to the start of a line (^}; with /m).
#
#   Found while extending this file (regression subtests at the end):
#
#   VULN-3 - generate: code injection via an existing cpanfile's develop
#     versions.  A version of '\' was written back inside single quotes,
#     escaping the closing quote; a following entry named 'x' then turned
#     the rest of the line into executable code when cpanm loaded the file.
#     FIX: validate merged versions; invalid ones are dropped with a carp.
#
#   BUG 4 - parse_prereqs: a dependency hash commented out on one line
#     ("# PREREQ_PM => { 'Old' => 0 },") was parsed as live.  Likewise
#     commented-out entries in an existing develop block were carried over.
#     FIX: skip blocks that start inside a comment; strip comments from the
#     existing develop block.  The comment scan is linear so a hostile
#     one-line Makefile.PL cannot make it quadratic.
#
#   BUG 5 - versions with no digit ('.', '_') and non-ASCII digits were
#     emitted, producing cpanfiles CPAN::Meta::Requirements rejects.
#     FIX: a single _valid_version rule for every version source.
#
#   BUG 6 - generate: a filehandle passed as makefile passed the -f guard
#     (-f tests open handles) and then failed inside Path::Tiny; an empty
#     home directory from File::HomeDir crashed path(''); an undef read
#     result produced "uninitialized" warnings.
#     FIX: stringify makefile; treat '' home as no home; guard undef.
#
# Out of scope: the module has no database or network access and parses
# no JSON, so the "upstream API" simulations below target the collaborators
# it does have (File::HomeDir, Path::Tiny, YAML::Tiny).

use Test::Most;
use lib 't/lib';
use Test::Permissions qw(can_revoke_read can_revoke_search can_revoke_write);
use Test::Mockingbird;
use File::Temp qw(tempdir);
use Path::Tiny;
use Readonly;
use YAML::Tiny;
use POSIX qw(EIO ENOSPC EINTR ENOENT ENOMEM);
use Capture::Tiny ();
use Config;
use FindBin qw($Bin);
use Test::Returns;
use Time::HiRes ();

use_ok('App::makefilepl2cpanfile');

# -----------------------------------------------------------------------
# Shared constants and helpers
# -----------------------------------------------------------------------

Readonly my $MF_SIMPLE =>
	"WriteMakefile(PREREQ_PM => { 'Carp' => 0 });\n";

# Fixtures for the $_ abuse subtest: every parsing path at once.
Readonly my $MF_FULL_FOR_TOPIC => <<'END_MF';
WriteMakefile(
	MIN_PERL_VERSION => '5.010',
	PREREQ_PM => { 'A::B' => '1.0', 'C::D' => 0,	# comment
	},
	TEST_REQUIRES => { 'T::U' => 0 },
	# PREREQ_PM => { 'Commented' => 0 },
	META_MERGE => {
		prereqs => { build => { suggests => { 'B::S' => 0 } } },
		recommends => { 'R::R' => 0 },
	},
);
END_MF
Readonly my $EXISTING_FOR_TOPIC =>
	"on 'develop' => sub {\n\trequires 'E::T', '1.0';\n\t# requires 'Old';\n};\n";

# Return a mock_scoped guard that routes File::HomeDir::my_home to an
# empty temp directory, isolating tests from the developer's real config.
sub empty_home {
	my $h = tempdir(CLEANUP => 1);
	return mock_scoped 'File::HomeDir::my_home' => sub { $h };
}

# Return a mock_scoped guard whose config directory contains a custom
# makefilepl2cpanfile.yml constructed from the supplied hashref.
sub home_with_config {
	my ($data) = @_;
	my $h = tempdir(CLEANUP => 1);
	path($h)->child('.config')->mkpath;
	YAML::Tiny->new($data)
		->write(
			path($h)->child('.config', 'makefilepl2cpanfile.yml')->stringify
		);
	return mock_scoped 'File::HomeDir::my_home' => sub { $h };
}

# Write $content to a fresh Makefile.PL in a temp dir and return its path.
sub make_mf {
	my ($content) = @_;
	my $dir = tempdir(CLEANUP => 1);
	my $mf = path($dir)->child('Makefile.PL');
	$mf->spew_utf8($content);
	return $mf;
}

# -----------------------------------------------------------------------
# SECTION 1: parse_prereqs - hostile and pathological inputs
# -----------------------------------------------------------------------

subtest 'parse_prereqs: undef input returns empty hashref with no warnings' => sub {
	# BUG 1 (fixed): before the fix, this emitted "Use of uninitialized value".
	# Strategy: capture all warnings via $SIG{__WARN__} and assert the list
	# is empty after the call, verifying the POD contract.
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	my $result;
	lives_ok { $result = App::makefilepl2cpanfile::parse_prereqs(undef) }
		'parse_prereqs(undef) does not die';

	isa_ok $result, 'HASH', 'undef input returns a hashref';
	is scalar keys %{$result}, 0, 'result is empty for undef input';
	is scalar @warnings, 0,
		'no warnings emitted (POD: "No errors or warnings")';

	diag "Captured warnings: @warnings" if $ENV{TEST_VERBOSE} && @warnings;
};

subtest 'parse_prereqs: reference inputs return empty hashref with no warnings' => sub {
	# BUG 1 (fixed): passing a reference caused "reference used as string"
	# warnings.  Strategy: cycle through four reference types and verify
	# each produces an empty hashref silently.
	Readonly my @CASES => (
		[ 'ARRAY ref',  []       ],
		[ 'HASH ref',   {}       ],
		[ 'CODE ref',   sub {}   ],
		[ 'SCALAR ref', \42      ],
	);

	for my $case (@CASES) {
		my ($name, $ref) = @{$case};

		my @warnings;
		local $SIG{__WARN__} = sub { push @warnings, @_ };

		my $result;
		lives_ok { $result = App::makefilepl2cpanfile::parse_prereqs($ref) }
			"parse_prereqs($name) does not die";

		isa_ok $result, 'HASH',  "$name returns a hashref";
		is scalar @warnings, 0,  "$name produces no warnings";
	}
};

subtest 'parse_prereqs: content with null bytes does not crash' => sub {
	# A null byte inside a module name is not a valid CPAN name but must not
	# crash the regex engine or emit warnings.
	Readonly my $CONTENT_WITH_NULL =>
		"PREREQ_PM => { 'Module\x00Name' => 0 },";

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	my $result;
	lives_ok {
		$result = App::makefilepl2cpanfile::parse_prereqs($CONTENT_WITH_NULL)
	} 'null bytes in content do not crash';

	isa_ok $result, 'HASH', 'returns a hashref for null-byte content';
	is scalar @warnings, 0,  'no warnings for null-byte content';
};

subtest 'parse_prereqs: deeply nested braces (5 levels) do not crash' => sub {
	# The parser supports up to 4 levels of brace nesting.  Content at the
	# 5th level must be silently skipped, not cause a crash or catastrophic
	# backtracking.  Strategy: build a module entry where the value is 5
	# levels deep and confirm the function returns without hanging.
	Readonly my $CONTENT_5_DEEP =>
		"PREREQ_PM => { 'Level1' => { a => { b => { c => { d => 0 } } } } },";

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	my $result;
	lives_ok {
		$result = App::makefilepl2cpanfile::parse_prereqs($CONTENT_5_DEEP)
	} '5-level brace nesting does not crash';

	isa_ok $result, 'HASH', 'returns a hashref with 5-level nesting';
	is scalar @warnings, 0,  'no warnings for 5-level nested content';

	diag 'Result: ' . join(', ', map { "phase=$_" } keys %{$result})
		if $ENV{TEST_VERBOSE};
};

subtest 'parse_prereqs: unclosed brace block does not crash or hang' => sub {
	# An unclosed outer brace means the regex cannot find a closing '}'.
	# The engine must fail the match cleanly and the function must return {}.
	Readonly my $UNCLOSED => "PREREQ_PM => { 'Module' => 0";    # missing }

	my $result;
	lives_ok {
		$result = App::makefilepl2cpanfile::parse_prereqs($UNCLOSED)
	} 'unclosed brace does not crash';

	isa_ok $result, 'HASH', 'returns a hashref for unclosed brace input';
	is scalar keys %{$result}, 0, 'result is empty when outer brace is unclosed';
};

subtest 'parse_prereqs: empty PREREQ_PM block returns no modules' => sub {
	# An explicit empty hash is valid Makefile.PL; no dependencies must appear.
	my $result = App::makefilepl2cpanfile::parse_prereqs(
		"PREREQ_PM => {},\n"
	);
	isa_ok $result, 'HASH', 'returns hashref for empty block';
	ok !exists $result->{runtime}, 'no runtime phase for empty PREREQ_PM';
};

subtest 'parse_prereqs: multiple PREREQ_PM blocks - first-occurrence wins' => sub {
	# When PREREQ_PM appears more than once (unusual but legal in generated
	# Makefile.PL), the first version string for a given module must survive;
	# a later block must not overwrite it.
	Readonly my $DOUBLE_BLOCK => <<'END';
PREREQ_PM => {
	'Moo' => '1.00',
},
PREREQ_PM => {
	'Moo' => '2.00',
},
END

	my $result = App::makefilepl2cpanfile::parse_prereqs($DOUBLE_BLOCK);
	is $result->{runtime}{requires}{'Moo'}{version}, '1.00',
		'first PREREQ_PM block wins for duplicate module';
};

subtest 'parse_prereqs: module name with Perl regex metacharacters' => sub {
	# Module names may not normally contain metacharacters, but the parser
	# must not crash.  The [^'"]+ capture class is safe for these characters.
	Readonly my $META_CONTENT => "PREREQ_PM => { 'Foo.Bar+Baz*Quux' => 0 },";

	my $result;
	lives_ok {
		$result = App::makefilepl2cpanfile::parse_prereqs($META_CONTENT)
	} 'module name with regex metacharacters does not crash';

	isa_ok $result, 'HASH', 'returns a hashref';
	diag 'Captured modules: ' . join(', ', keys %{ $result->{runtime}{requires} // {} })
		if $ENV{TEST_VERBOSE};
};

subtest 'parse_prereqs: version string edge cases for _has_version' => sub {
	# These edge cases test _has_version's numeric/non-numeric classification
	# and the convention that numeric zero means "any version" (no constraint).

	# "0.0" is numerically zero - no version constraint should be emitted.
	ok !App::makefilepl2cpanfile::_has_version('0.0'),
		'"0.0" classified as no version constraint (numeric zero)';

	# "0e0" is scientific-notation zero - still zero.
	ok !App::makefilepl2cpanfile::_has_version('0e0'),
		'"0e0" classified as no version constraint (scientific zero)';

	# "-0" is negative zero - numerically equal to positive zero.
	ok !App::makefilepl2cpanfile::_has_version('-0'),
		'"-0" classified as no version constraint (negative zero)';

	# "-1" is non-zero; unusual but constitutes a real version constraint.
	ok  App::makefilepl2cpanfile::_has_version('-1'),
		'"-1" classified as a real constraint (non-zero)';

	# " 1" has a leading space; looks_like_number returns true, value is 1.
	ok  App::makefilepl2cpanfile::_has_version(' 1'),
		'" 1" (leading space) classified as a real constraint';

	# "v1.2.3" is not a plain decimal number; treated as a real constraint.
	ok  App::makefilepl2cpanfile::_has_version('v1.2.3'),
		'"v1.2.3" (non-numeric) classified as a real constraint';

	diag '_has_version edge-case classifications all correct' if $ENV{TEST_VERBOSE};
};

subtest 'parse_prereqs: PREREQ_PM as variable reference - documented limitation' => sub {
	# When PREREQ_PM => $var (no literal brace block), the regex cannot match.
	# Strategy: verify the function silently returns {} with no warnings.
	Readonly my $DYNAMIC_DEPS =>
		"my \$deps = { 'Module' => 0 };\nWriteMakefile(PREREQ_PM => \$deps);\n";

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	my $result = App::makefilepl2cpanfile::parse_prereqs($DYNAMIC_DEPS);

	isa_ok $result, 'HASH', 'returns hashref for variable PREREQ_PM';
	ok !exists $result->{runtime},
		'no runtime phase (dynamic deps are a documented limitation)';
	is scalar @warnings, 0, 'no warnings for variable PREREQ_PM';
};

subtest 'parse_prereqs: list context returns a single hashref (not exploded)' => sub {
	# The POD says Returns: HashRef.  In list context the function must not
	# accidentally expand into a multi-element list.
	my @result = App::makefilepl2cpanfile::parse_prereqs(
		"PREREQ_PM => { 'Carp' => 0 },"
	);
	is scalar @result, 1,     'list context: exactly one element returned';
	isa_ok $result[0], 'HASH','the single element is a hashref';
};

# -----------------------------------------------------------------------
# SECTION 2: generate - hostile path and argument inputs
# -----------------------------------------------------------------------

subtest 'generate: makefile => undef defaults to Makefile.PL, croaks when absent' => sub {
	# undef is passed through the '// Makefile.PL' default, so the effective
	# path becomes 'Makefile.PL' in cwd.  In a directory without that file
	# the Cannot-read guard fires.
	my $g       = empty_home();
	my $workdir = tempdir(CLEANUP => 1);
	my $orig    = Path::Tiny->cwd;
	chdir $workdir;

	throws_ok {
		App::makefilepl2cpanfile::generate(makefile => undef)
	} qr/Cannot read 'Makefile\.PL'/, 'undef defaults to Makefile.PL, then croaks when absent';

	chdir "$orig";
};

subtest 'generate: empty string makefile path croaks' => sub {
	my $g = empty_home();
	throws_ok {
		App::makefilepl2cpanfile::generate(makefile => '')
	} qr/Cannot read/, 'empty-string makefile path causes croak';
};

subtest 'generate: /dev/null is not a regular file - must croak' => sub {
	# On POSIX systems -f '/dev/null' is false (character device, not a file).
	# The Cannot-read guard must fire before any slurp attempt.
	my $g = empty_home();
	throws_ok {
		App::makefilepl2cpanfile::generate(makefile => '/dev/null')
	} qr/Cannot read '\/dev\/null'/, '/dev/null causes croak';
};

subtest 'generate: path is a directory - must croak' => sub {
	my $g   = empty_home();
	my $dir = tempdir(CLEANUP => 1);
	throws_ok {
		App::makefilepl2cpanfile::generate(makefile => $dir)
	} qr/Cannot read/, 'directory path causes croak';
};

subtest 'generate: empty Makefile.PL returns header-only output without crashing' => sub {
	# A valid but content-free Makefile.PL must produce at least the generator
	# comment header and a single trailing newline.
	my $g  = empty_home();
	my $mf = make_mf('');    # completely empty file

	my $out;
	lives_ok {
		$out = App::makefilepl2cpanfile::generate(
			makefile     => "$mf",
			with_develop => 0,
		)
	} 'empty Makefile.PL does not crash';

	like   $out, qr/# Generated from Makefile\.PL/, 'header comment present';
	like   $out, qr/\n$/,                           'output ends with newline';
	unlike $out, qr/requires/,    'no requires for empty Makefile.PL';
	unlike $out, qr/on 'develop'/, 'no develop block for empty Makefile.PL';

	diag "Output:\n$out" if $ENV{TEST_VERBOSE};
};

subtest 'generate: no arguments in a directory without Makefile.PL - must croak' => sub {
	# With no arguments generate() defaults to 'Makefile.PL' in cwd.
	# In a directory that has no such file the guard must croak.
	my $g       = empty_home();
	my $workdir = tempdir(CLEANUP => 1);
	my $orig    = Path::Tiny->cwd;
	chdir $workdir;

	throws_ok {
		App::makefilepl2cpanfile::generate()
	} qr/Cannot read 'Makefile\.PL'/, 'no args + no Makefile.PL = croak';

	chdir "$orig";
};

subtest 'generate: existing => undef treated as empty string' => sub {
	# undef for 'existing' is equivalent to omitting the key; the develop
	# block should behave identically in both cases.
	my $g  = empty_home();
	my $mf = make_mf($MF_SIMPLE);

	my ($out_undef, $out_omit);
	lives_ok {
		$out_undef = App::makefilepl2cpanfile::generate(
			makefile     => "$mf",
			existing     => undef,
			with_develop => 0,
		);
		$out_omit = App::makefilepl2cpanfile::generate(
			makefile     => "$mf",
			with_develop => 0,
		);
	} 'existing => undef does not crash';

	is $out_undef, $out_omit,
		'existing => undef produces the same output as omitting existing';
};

subtest 'generate: existing develop block with }; inside comment - no truncation (BUG 2)' => sub {
	# BUG 2 (fixed): the old /s-only regex stopped at the first '};' anywhere
	# in the text, including inside an inline comment, silently dropping module
	# entries that followed the comment.
	# Strategy: place '};' inside a comment on a non-terminal line, then
	# confirm that a module declared AFTER the comment appears in the output.
	my $g  = empty_home();
	my $mf = make_mf($MF_SIMPLE);

	my $existing = "on 'develop' => sub {\n"
		. "    requires 'First::Tool';\n"
		. "    # Old Makefile syntax once used: };\n"    # '}; ' in comment
		. "    requires 'Second::Tool';\n"
		. "};\n";

	my $out = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		existing     => $existing,
		with_develop => 0,
	);

	diag "Output:\n$out" if $ENV{TEST_VERBOSE};

	like $out, qr/First::Tool/,
		'First::Tool present (before the commented }; )';
	like $out, qr/Second::Tool/,
		'Second::Tool present (after the commented }; ) - truncation bug fixed';
};

subtest 'generate: with_develop => "" (falsy) suppresses develop block' => sub {
	# An empty string is defined, bypasses '// 1', and is falsy.
	# The develop block must not appear in the output.
	my $g  = empty_home();
	my $mf = make_mf($MF_SIMPLE);

	my $out = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		with_develop => '',
	);

	unlike $out, qr/on 'develop' => sub/,
		"with_develop => '' (falsy) suppresses the develop block";

	diag "Output:\n$out" if $ENV{TEST_VERBOSE};
};

subtest "generate: with_develop => 'yes' (truthy string) injects develop block" => sub {
	# Any truthy value must activate the develop injection path.
	my $g  = empty_home();
	my $mf = make_mf($MF_SIMPLE);

	my $out = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		with_develop => 'yes',
	);

	like $out, qr/on 'develop' => sub/,
		"with_develop => 'yes' (truthy) injects develop block";

	diag "Output:\n$out" if $ENV{TEST_VERBOSE};
};

subtest 'generate: extra unknown keys in argument hash are silently ignored' => sub {
	# Callers sometimes pass extra context metadata; the function must not die.
	my $g  = empty_home();
	my $mf = make_mf($MF_SIMPLE);

	my $out;
	lives_ok {
		$out = App::makefilepl2cpanfile::generate(
			makefile      => "$mf",
			with_develop  => 0,
			unknown_key   => 'should be ignored',
			another_extra => 42,
		);
	} 'extra unknown keys do not cause a crash';

	like $out, qr/Carp/, 'normal output produced despite extra keys';
};

subtest 'generate: list context returns exactly one Str element' => sub {
	# The POD says Returns: Str.  Calling in list context must yield a
	# single-element list, not an accidentally exploded multi-value return.
	my $g  = empty_home();
	my $mf = make_mf($MF_SIMPLE);

	my @result = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		with_develop => 0,
	);

	is   scalar @result, 1,    'list context: exactly one element returned';
	ok   !ref $result[0],      'the element is a plain Str (not a reference)';
	like $result[0], qr/\n$/, 'the value ends with a newline';
};

# -----------------------------------------------------------------------
# SECTION 3: Security - module name content via YAML config
# -----------------------------------------------------------------------

subtest 'security: YAML config module name with single quote is rejected (injection guard)' => sub {
	# VULN-1 regression: a YAML config key such as
	#   Safe'; system('evil'); requires 'Safe2
	# used to reach _fmt_dep and produce a syntactically valid cpanfile line
	# that cpanm eval's, executing the injected command.
	#
	# After the fix, _load_develop_config validates every key against a strict
	# Perl module-name pattern and skips (with carp) anything that does not
	# match.  A key containing "'" can never be a valid module name.
	my $g  = home_with_config( { develop => { "Bad'Quote" => 0 } } );
	my $mf = make_mf($MF_SIMPLE);

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	my $out;
	lives_ok {
		$out = App::makefilepl2cpanfile::generate(
			makefile     => "$mf",
			with_develop => 1,
		);
	} 'invalid module name in config does not crash generate()';

	unlike $out, qr/Bad/,
		"module name containing \"'\" is rejected - does not reach output";
	ok scalar @warnings > 0,
		'carp emitted for rejected module name';
	like $warnings[0], qr/invalid module name/i,
		'carp message identifies the problem';

	diag "Output:\n$out\nWarnings: @warnings" if $ENV{TEST_VERBOSE};
};

subtest 'security: YAML config crafted name that would inject code is rejected' => sub {
	# Confirm the most dangerous payload - a name that closes the single-quoted
	# string and inserts a system() call - is blocked before it can reach
	# _fmt_dep and appear in the cpanfile.
	Readonly my $PAYLOAD => "Safe'; warn q(INJECTED); requires 'Safe2";

	my $g  = home_with_config( { develop => { $PAYLOAD => 0 } } );
	my $mf = make_mf($MF_SIMPLE);

	# The rejection is announced with a carp; capture it so it is asserted
	# rather than leaking into the test output.
	my @rejected;
	my $out = do {
		local $SIG{__WARN__} = sub { push @rejected, $_[0] };
		App::makefilepl2cpanfile::generate(
			makefile     => "$mf",
			with_develop => 1,
		);
	};
	like $rejected[0], qr/\ASkipping invalid module name in /, 'rejection announced';

	unlike $out, qr/INJECTED/,
		'injection payload does not appear in generated cpanfile';
	unlike $out, qr/warn/,
		'warn() call is not present in generated cpanfile';

	# Verify the output is safe to eval (no injection triggered).
	my $eval_warned = 0;
	local $SIG{__WARN__} = sub { $eval_warned = 1 };
	eval q{ sub requires {} sub on { my ($p, $cb) = @_; $cb->() } } . $out;
	ok !$eval_warned && !$@,
		'generated cpanfile evals cleanly with no injected side-effects';
};

subtest 'security: YAML config poisoned version string is rejected (VULN-2)' => sub {
	# VULN-2 regression: a YAML version value such as
	#   "1'; warn q(VERSION_INJECTED); '1"
	# used to pass _has_version (non-numeric -> truthy) and be embedded as
	# ", '$ver'" in _fmt_dep, injecting executable Perl into the cpanfile.
	Readonly my $POISON_VER => "1'; warn q(VERSION_INJECTED); '1";

	my $g  = home_with_config( { develop => { 'Safe::Mod' => $POISON_VER } } );
	my $mf = make_mf($MF_SIMPLE);

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	my $out = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		with_develop => 1,
	);

	unlike $out, qr/VERSION_INJECTED/,
		'poisoned version string does not appear in generated cpanfile';

	# The module itself must still be present (version falls back to 0).
	like $out, qr/Safe::Mod/,
		'module with invalid version is still emitted (version defaults to 0)';

	ok scalar @warnings > 0,
		'carp emitted for rejected version string';
	like $warnings[0], qr/invalid version/i,
		'carp message identifies the rejected version';
};

subtest 'security: valid YAML config module names and versions are accepted' => sub {
	# Confirm the validation rejects only invalid entries, not valid ones.
	my $g  = home_with_config( {
		develop => {
			'Perl::Critic'        => 0,
			'Devel::Cover'        => '1.00',
			'Test::Pod'           => 'v1.2.3',
			'My_Tool::With_Under' => '0.001',
		}
	} );
	my $mf = make_mf($MF_SIMPLE);

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	my $out = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		with_develop => 1,
	);

	like $out, qr/Perl::Critic/,    'Perl::Critic accepted';
	like $out, qr/Devel::Cover/,    'Devel::Cover accepted';
	like $out, qr/Test::Pod/,       'Test::Pod accepted';
	like $out, qr/My_Tool::With_Under/, 'underscore-containing name accepted';
	is scalar(grep { /invalid/i } @warnings), 0,
		'no warnings for well-formed module names and versions';
};

subtest 'security: Makefile.PL module names cannot carry quote characters (injection safe)' => sub {
	# Module names from PREREQ_PM are captured via [^'"]+, which physically
	# prevents single or double quotes from entering the name.  This test
	# verifies that a Makefile.PL with a double-quoted key whose value includes
	# a single quote does NOT inject unmatched quotes into the cpanfile output.
	#
	# Given:  "Foo'Bar" => 0   (outer delimiter: double-quote)
	# [^'"]+ stops at the embedded ', so only "Foo" is captured.
	# The output must have balanced single quotes.
	my $g  = empty_home();
	my $mf = make_mf(
		"WriteMakefile(PREREQ_PM => { \"Foo'Bar\" => 0 });\n"
	);

	my $out = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		with_develop => 0,
	);

	my $single_quote_count = () = $out =~ /'/g;
	is $single_quote_count % 2, 0,
		'all single quotes in output are balanced (no quote injection from Makefile.PL)';

	diag "Quote count: $single_quote_count\nOutput:\n$out" if $ENV{TEST_VERBOSE};
};

subtest 'security: existing cpanfile module names cannot carry quotes (injection safe)' => sub {
	# Same property as above but for module names read back from an existing
	# cpanfile develop block.  The merge regex also uses [^'"]+ to capture
	# module names, so embedded quotes are impossible.
	my $g  = empty_home();
	my $mf = make_mf($MF_SIMPLE);

	# The module name between the outer quotes is "Safe::Module"; the
	# surrounding requires '...' is what gets parsed.  We craft an existing
	# block with no embedded quotes - just verify balanced output.
	Readonly my $EXISTING => <<'END';
on 'develop' => sub {
	requires 'Safe::Module';
};
END

	my $out = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		existing     => $EXISTING,
		with_develop => 0,
	);

	my $count = () = $out =~ /'/g;
	is $count % 2, 0, 'quotes are balanced when merging existing develop block';
	like $out, qr/Safe::Module/, 'existing module preserved in output';
};

# -----------------------------------------------------------------------
# SECTION 4: State isolation - defensive copies and no shared state
# -----------------------------------------------------------------------

subtest 'parse_prereqs: mutating the returned hashref does not affect next call' => sub {
	# The returned hashref must be a fresh allocation per call; mutating it
	# must not contaminate subsequent calls (no shared module-level state).
	my $r1 = App::makefilepl2cpanfile::parse_prereqs(
		"PREREQ_PM => { 'Carp' => 0 },"
	);

	# Aggressively mutate the returned structure.
	$r1->{runtime}{requires}{'Injected::Evil'} =
		{ version => 99, comment => 'injected' };
	delete $r1->{runtime}{requires}{'Carp'};

	my $r2 = App::makefilepl2cpanfile::parse_prereqs(
		"PREREQ_PM => { 'Carp' => 0 },"
	);

	ok  exists $r2->{runtime}{requires}{'Carp'},
		'Carp still present in second call after first-call mutation';
	ok !exists $r2->{runtime}{requires}{'Injected::Evil'},
		'Injected key absent from second call - no shared state';
};

subtest 'generate: successive calls with different with_develop produce independent outputs' => sub {
	# Call generate() three times in sequence: no-develop, with-develop,
	# no-develop again.  The third output must match the first exactly,
	# proving that the second call left no residual develop state.
	my $g  = empty_home();
	my $mf = make_mf($MF_SIMPLE);

	my $no_dev = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		with_develop => 0,
	);
	my $with_dev = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		with_develop => 1,
	);
	my $no_dev_again = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		with_develop => 0,
	);

	unlike $no_dev,      qr/on 'develop' => sub/, 'first call: no develop block';
	like   $with_dev,    qr/on 'develop' => sub/, 'second call: develop block present';
	is     $no_dev_again, $no_dev,
		'third call matches first - no state bleed from second call';
};

# -----------------------------------------------------------------------
# SECTION 5: Input Hostility - Extended
#
# Bug found and fixed during authoring:
#   BUG 3 - _load_develop_config: File::HomeDir::my_home returning undef
#     caused path(undef) to croak with a Path::Tiny error message rather than
#     falling back to %DEFAULT_DEVELOP.  This breaks CI environments and
#     containers that have no home directory set.
#     FIX: early return of {%DEFAULT_DEVELOP} when my_home() returns undef.
# -----------------------------------------------------------------------

subtest 'parse_prereqs: circular reference returns empty hashref silently' => sub {
	# A reference that points to itself (circular) must not cause infinite
	# traversal.  The !ref guard returns {} before the regex engine is reached.
	my $circular;
	$circular = \$circular;    # REF type: ref($circular) eq 'REF'

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	my $result;
	lives_ok { $result = App::makefilepl2cpanfile::parse_prereqs($circular) }
		'circular reference does not cause infinite recursion or crash';

	isa_ok $result, 'HASH', 'circular ref input returns a hashref';
	is scalar keys %{$result}, 0, 'result is empty for circular reference input';
	is scalar @warnings, 0, 'no warnings for circular reference input';
};

subtest 'parse_prereqs: invalid UTF-8 bytes in content string - no crash, no warnings' => sub {
	# When the caller passes a byte string containing invalid UTF-8 sequences,
	# the regex engine must operate on the raw bytes without crashing or warning.
	# Byte strings (no UTF-8 flag) are valid Perl scalars; [^{}] matches any byte.
	my $content = "PREREQ_PM => { \x27Carp\x27 => 0 };\xFF\xFEjunk";

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	my $result;
	lives_ok { $result = App::makefilepl2cpanfile::parse_prereqs($content) }
		'invalid UTF-8 bytes in string content do not crash parse_prereqs';

	isa_ok $result, 'HASH', 'returns a hashref for content with invalid UTF-8 bytes';
	is scalar @warnings, 0, 'no warnings emitted for byte-string content';

	diag "Found phases: " . join(', ', keys %{$result}) if $ENV{TEST_VERBOSE};
};

subtest 'generate: Makefile.PL with trailing invalid UTF-8 bytes - warns, finds valid deps' => sub {
	# Path::Tiny slurp_utf8 emits Carp warnings for each ill-formed byte but
	# does NOT die - it returns the (possibly substituted) content and continues.
	# Strategy: write a file whose valid prefix contains a PREREQ_PM block and
	# whose suffix contains \xFF\xFE; verify generate() survives and finds Carp.
	my $g     = empty_home();
	my $dir   = tempdir(CLEANUP => 1);
	my $mf    = path($dir)->child('Makefile.PL');
	$mf->spew_raw("WriteMakefile(PREREQ_PM => { \x27Carp\x27 => 0 });\xFF\xFE\n");

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	my $out;
	lives_ok {
		$out = App::makefilepl2cpanfile::generate(
			makefile     => "$mf",
			with_develop => 0,
		)
	} 'invalid UTF-8 bytes in Makefile.PL do not crash generate()';

	like $out, qr/Carp/, 'valid dep before invalid bytes is captured correctly';
	ok scalar @warnings > 0,
		'invalid UTF-8 bytes trigger warnings from slurp_utf8 (not silent corruption)';

	diag "Warning count: " . scalar(@warnings) if $ENV{TEST_VERBOSE};
};

subtest 'parse_prereqs: extreme numerical version strings - _has_version contract' => sub {
	# Very large and very small numbers are valid versions and must be
	# classified by their digits: any digit 1-9 makes a real constraint.
	Readonly my @EXTREME_NONZERO_VERS => (
		[ '99999999999999999999',   1, '20-digit int overflows to ~1e20, != 0'       ],
		[ '0.000000001',            1, 'tiny positive fraction is non-zero'          ],
		[ '1e300',                  1, 'very large float is non-zero'                ],
	);
	Readonly my @EXTREME_ZERO_VERS => (
		[ '0.000',                  0, 'leading zeros - numerically zero'            ],
		[ '+0',                     0, 'explicit positive zero is still zero'        ],
	);

	for my $case (@EXTREME_NONZERO_VERS) {
		my ($ver, $expected, $label) = @{$case};
		is !!App::makefilepl2cpanfile::_has_version($ver), !!$expected, $label;
	}
	for my $case (@EXTREME_ZERO_VERS) {
		my ($ver, $expected, $label) = @{$case};
		is !!App::makefilepl2cpanfile::_has_version($ver), !!$expected, $label;
	}

	# Inf, -Inf and NaN are numbers to Perl but not versions.  _has_version
	# only ever sees validated versions, so prove they are stopped upstream:
	# none of them may reach the output as a requirement.
	for my $ver ('Inf', '-Inf', 'NaN', 'inf', 'nan') {
		my $d = App::makefilepl2cpanfile::parse_prereqs("PREREQ_PM => { 'M' => '$ver' },");
		is $d->{runtime}{requires}{M}{version}, 0, "'$ver' is rejected before it could reach _has_version";
	}
};

subtest 'parse_prereqs: 1 MB of noise with embedded PREREQ_PM - completes without crashing' => sub {
	# Defensive performance test: a megabyte of random-ish content must not
	# cause catastrophic regex backtracking.  [^{}] and \{...\} are mutually
	# exclusive at each position, so no backtracking occurs.
	# Strategy: embed a valid PREREQ_PM block inside 500 KB of ASCII noise on
	# either side and verify parse_prereqs finds the module.
	Readonly my $HALF_MB => 'abcdefg ' x 70_000;    # ~560 KB, no braces
	my $content = $HALF_MB
		. "PREREQ_PM => { \x27Carp\x27 => 0 },"
		. $HALF_MB;

	my $result;
	lives_ok { $result = App::makefilepl2cpanfile::parse_prereqs($content) }
		'1 MB of content does not crash parse_prereqs';

	ok exists $result->{runtime}{requires}{'Carp'},
		'Carp found inside 1 MB content - regex scans without hanging';
};

subtest 'parse_prereqs: 100-level brace nesting completes within time limit' => sub {
	# Verify no catastrophic backtracking when brace nesting far exceeds the
	# 4-level regex limit.  Uses alarm() to enforce a hard wall-clock ceiling.
	SKIP: {
		skip 'alarm() is unreliable on this platform', 3 if $^O eq 'MSWin32';

		Readonly my $ALARM_SECS => 5;
		my $timed_out = 0;

		local $SIG{ALRM} = sub { $timed_out = 1; die "TIMEOUT\n" };
		alarm($ALARM_SECS);

		my $content = 'PREREQ_PM => '
			. ('{' x 100)
			. "\x27Module\x27 => 0"    # 'Module' => 0 as raw bytes
			. ('}' x 100);

		my $result;
		lives_ok { $result = App::makefilepl2cpanfile::parse_prereqs($content) }
			'100-level brace nesting does not crash or time out';

		alarm(0);

		ok !$timed_out, "completed within ${ALARM_SECS}s (no catastrophic backtracking)";
		isa_ok $result, 'HASH', 'returns a hashref even for extreme brace nesting';
	}
};

subtest 'parse_prereqs: version as unevaluated Perl expression - security invariant' => sub {
	# A module version written as a Perl expression (e.g. 9**9**9) in the
	# source of Makefile.PL must NEVER be evaluated.  The regex captures only
	# the leading digit sequence; 9**9**9 becomes version '9', not Inf or error.
	my $content = "PREREQ_PM => { \x27Module\x27 => 9**9**9 },";

	my $result;
	lives_ok { $result = App::makefilepl2cpanfile::parse_prereqs($content) }
		'Perl expression as version does not crash or eval';

	my $ver = $result->{runtime}{requires}{'Module'}{version} // 'undef';
	ok defined $ver, 'version field is defined (regex captured leading digits)';
	unlike "$ver", qr/Inf|NaN/i, 'captured version is not Inf/NaN (no eval occurred)';
	ok $ver =~ /^\d/, 'captured version starts with a digit - just the literal text';

	diag "Captured version for 9**9**9: $ver" if $ENV{TEST_VERBOSE};
};

subtest 'generate: reference as existing arg - no crash, no spurious develop merge' => sub {
	# A reference passed as existing stringifies silently to e.g. "ARRAY(0x...)"
	# which the develop-block regex cannot match.  No warnings are emitted and
	# no develop block should appear in the output.
	my $g  = empty_home();
	my $mf = make_mf($MF_SIMPLE);

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	my $out;
	lives_ok {
		$out = App::makefilepl2cpanfile::generate(
			makefile     => "$mf",
			existing     => [],    # array ref, not a string
			with_develop => 0,
		)
	} 'array ref as existing does not crash';

	is scalar @warnings, 0, 'no warnings for reference existing arg';
	unlike $out, qr/on 'develop' => sub/,
		'no spurious develop block from reference existing';
	like $out, qr/Carp/, 'normal dep output produced';
};

# -----------------------------------------------------------------------
# SECTION 6: Filesystem Hostility
# -----------------------------------------------------------------------

subtest 'generate: unreadable Makefile.PL (mode 000) must croak' => sub {
	# Strategy: create a file, remove all permissions, then verify the
	# -r guard fires.  Root bypasses permissions, so skip under euid 0.
	SKIP: {
		skip 'chmod cannot make a file unreadable here (root or Windows)', 1
			unless can_revoke_read();

		my $g   = empty_home();
		my $dir = tempdir(CLEANUP => 1);
		my $mf  = path($dir)->child('Makefile.PL');
		$mf->spew_utf8($MF_SIMPLE);
		chmod 0000, "$mf";

		throws_ok {
			App::makefilepl2cpanfile::generate(makefile => "$mf")
		} qr/Cannot read/, 'mode-000 Makefile.PL causes croak';

		chmod 0644, "$mf";    # restore so temp-cleanup can remove it
	}
};

subtest 'generate: dangling symlink must croak' => sub {
	# A symlink whose target does not exist: -f returns false (target absent),
	# so the Cannot-read guard must fire.
	my $g      = empty_home();
	my $dir    = tempdir(CLEANUP => 1);
	my $target = path($dir)->child('nonexistent_target.pl');
	my $link   = path($dir)->child('Makefile.PL');

	SKIP: {
		symlink("$target", "$link") or skip 'symlinks not supported on this platform', 1;

		throws_ok {
			App::makefilepl2cpanfile::generate(makefile => "$link")
		} qr/Cannot read/, 'dangling symlink causes croak (-f is false for missing target)';
	}
};

subtest 'generate: /dev/urandom is a character device - must croak' => sub {
	# Character devices pass -e but fail -f (not a regular file).
	my $g = empty_home();
	SKIP: {
		skip '/dev/urandom not available on this platform', 1
			unless -e '/dev/urandom';

		throws_ok {
			App::makefilepl2cpanfile::generate(makefile => '/dev/urandom')
		} qr/Cannot read '\/dev\/urandom'/, '/dev/urandom causes croak (character device)';
	}
};

subtest 'generate: path containing spaces is handled correctly' => sub {
	# Paths with spaces are ordinary filesystem paths on POSIX; the module uses
	# Perl file-test operators and Path::Tiny (not shell commands), so no quoting
	# issues arise.
	my $g       = empty_home();
	my $dir     = path(tempdir(CLEANUP => 1))->child('dir with spaces');
	$dir->mkpath;
	my $mf = $dir->child('Makefile.PL');
	$mf->spew_utf8($MF_SIMPLE);

	my $out;
	lives_ok {
		$out = App::makefilepl2cpanfile::generate(
			makefile     => "$mf",
			with_develop => 0,
		)
	} 'path with spaces does not trigger shell-quoting issues';

	like $out, qr/Carp/, 'correct output from path with spaces';
};

subtest 'generate: path with shell-injection characters is rejected by Cannot-read guard' => sub {
	# Paths like "/tmp; rm -rf /" contain shell metacharacters, but since
	# Perl and Path::Tiny never pass them to a shell, they are benign file
	# paths.  No such file exists, so the guard croaks safely.
	my $g = empty_home();

	throws_ok {
		App::makefilepl2cpanfile::generate(makefile => '/tmp/; rm -rf /; #.pl')
	} qr/Cannot read/, 'shell-injection path is rejected (file does not exist)';

	throws_ok {
		App::makefilepl2cpanfile::generate(makefile => "/tmp/Make\nfile.PL")
	} qr/Cannot read/, 'path with embedded newline is rejected (file does not exist)';
};

subtest 'generate: extremely long path is rejected by Cannot-read guard' => sub {
	# Most filesystems cap path lengths well below PATH_MAX (4096 on Linux).
	# A 5000-char path cannot correspond to an existing file; the guard must
	# croak cleanly without crashing the regex or OS call.
	my $g         = empty_home();
	my $long_path = 'M' x 5000;

	throws_ok {
		App::makefilepl2cpanfile::generate(makefile => $long_path)
	} qr/Cannot read/, 'extremely long path causes croak gracefully';
};

# -----------------------------------------------------------------------
# SECTION 7: Upstream Failure Simulation via Test::Mockingbird
#
# These tests simulate real-world upstream failures: I/O interruptions,
# missing home directory (containers), and YAML service timeouts.
# They verify that the module propagates errors clearly without masking
# the root cause or leaving the process in a corrupted state.
# -----------------------------------------------------------------------

subtest 'upstream: Path::Tiny::slurp_utf8 dies - generate propagates the I/O error' => sub {
	# Simulates a network filesystem going down between the readability check
	# and the actual read, or a catastrophic hardware read error.
	# Strategy: create a valid Makefile.PL (passes -f && -r), then mock
	# slurp_utf8 to die so the error surfaces after the guard.
	my $g_home  = empty_home();
	my $mf      = make_mf($MF_SIMPLE);
	my $g_slurp = mock_scoped 'Path::Tiny::slurp_utf8' => sub {
		die "Input/output error: simulated disk failure\n";
	};

	throws_ok {
		App::makefilepl2cpanfile::generate(
			makefile     => "$mf",
			with_develop => 0,
		)
	} qr/Input\/output error.*simulated disk failure/,
		'slurp_utf8 I/O failure propagates transparently from generate()';
};

subtest 'upstream: File::HomeDir::my_home returns undef - falls back to defaults (BUG 3)' => sub {
	# Simulates a container or CI job that runs under a user with no home
	# directory set (e.g., nobody, or a UID with no passwd entry).
	# BUG 3 (fixed): before the fix, path(undef) croaked from Path::Tiny
	# with "positive-length parts" error, not a clean fallback to defaults.
	my $g_home = mock_scoped 'File::HomeDir::my_home' => sub { undef };
	my $mf     = make_mf($MF_SIMPLE);

	my $out;
	lives_ok {
		$out = App::makefilepl2cpanfile::generate(
			makefile     => "$mf",
			with_develop => 1,    # forces _load_develop_config call
		)
	} 'undef my_home does not crash (BUG 3 fixed - falls back to defaults)';

	like $out, qr/Perl::Critic/,
		'default develop tool present - fallback to %DEFAULT_DEVELOP works';
	like $out, qr/on 'develop' => sub/,
		'develop block was emitted using default tools';

	diag "Output:\n$out" if $ENV{TEST_VERBOSE};
};

subtest 'upstream: YAML::Tiny simulated timeout - croak includes path and message' => sub {
	# Simulates a YAML parsing backend that fails mid-operation (e.g. a remote
	# config service returning an error, or a corrupt/truncated YAML file).
	# The croak message must include both the config file path and the upstream
	# error text so operators can diagnose the failure.
	my $dir = tempdir(CLEANUP => 1);
	path($dir)->child('.config')->mkpath;
	path($dir)->child('.config', 'makefilepl2cpanfile.yml')->spew_utf8(
		"develop:\n  Perl::Critic: 0\n"    # valid YAML on disk
	);

	my $g_home = mock_scoped 'File::HomeDir::my_home' => sub { $dir };
	my $g_yaml = mock_scoped(
		'YAML::Tiny::read'   => sub { undef },
		'YAML::Tiny::errstr' => sub { 'connection timed out after 30s' },
	);

	my $mf = make_mf($MF_SIMPLE);

	throws_ok {
		App::makefilepl2cpanfile::generate(
			makefile     => "$mf",
			with_develop => 1,
		)
	} qr/Failed to parse .+ connection timed out/s,
		'YAML upstream failure croaks with path and error message';
};

subtest 'upstream: config path cannot be examined (stat() failure) - croaks' => sub {
	# Simulates a filesystem that denies access after the home directory was
	# resolved (the same class of failure as an NFS mount going stale).  The
	# config may exist, so silently falling back to the defaults would change
	# the output without explanation; the error must reach the caller.  A
	# real EACCES is produced by making ~/.config unsearchable.
	SKIP: {
		skip 'chmod cannot make a directory unsearchable here (root or Windows)', 1 unless can_revoke_search();
		my $home = path(tempdir(CLEANUP => 1));
		my $cfg_dir = $home->child('.config');
		$cfg_dir->mkpath;
		$cfg_dir->child('makefilepl2cpanfile.yml')->spew_utf8("develop:\n  X: 1\n");
		chmod 0, "$cfg_dir";
		my $g  = mock_scoped 'File::HomeDir::my_home' => sub { "$home" };
		my $mf = make_mf($MF_SIMPLE);
		my $msg_eacces = do { local $! = POSIX::EACCES(); "$!" };

		throws_ok {
			App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 1)
		} qr/\AFailed to parse \Q$cfg_dir\E\/makefilepl2cpanfile\.yml: \Q$msg_eacces\E at /,
			'stat() failure on the config path croaks with the errno text';
		chmod 0755, "$cfg_dir";
	}
};

# -----------------------------------------------------------------------
# SECTION 8: Mid-flight Hardware/OS Failure Simulation
#
# Injects POSIX errno-flavoured failures into the I/O wrapper layer
# (Path::Tiny, YAML::Tiny) AFTER the readability guards have already
# passed.  This simulates hardware faults, TOCTOU races, interrupted
# syscalls, and truncated reads that cannot be detected by file-test
# operators before the call.
#
# Three invariants are verified throughout:
#   1. The error propagates unmasked from generate().
#   2. No global Perl state ($@, Readonly constants) is corrupted.
#   3. A subsequent call with working I/O produces correct output.
# -----------------------------------------------------------------------

# OS-canonical errno strings derived from Perl's $! layer rather than
# POSIX::strerror() to stay locale-consistent (see locales.t guidance).
Readonly my $MSG_EIO    => do { local $! = EIO;    "$!" };
Readonly my $MSG_ENOSPC => do { local $! = ENOSPC; "$!" };
Readonly my $MSG_EINTR  => do { local $! = EINTR;  "$!" };
Readonly my $MSG_ENOENT => do { local $! = ENOENT; "$!" };
Readonly my $MSG_ENOMEM => do { local $! = ENOMEM; "$!" };

subtest 'io-failure-read: EIO (hardware fault) mid-slurp - propagates with POSIX errno string' => sub {
	# A hardware read error (disk controller failure, bit-rot) that occurs
	# AFTER the -f / -r guard has already confirmed the file's existence.
	# Strategy: file is real (passes guard); slurp_utf8 is mocked to die
	# with local $! = EIO, matching what the kernel would set.
	my $g_home  = empty_home();
	my $mf      = make_mf($MF_SIMPLE);
	my $g_slurp = mock_scoped 'Path::Tiny::slurp_utf8' => sub {
		local $! = EIO;
		die "read: $!\n";
	};

	throws_ok {
		App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 0)
	} qr/\Q$MSG_EIO\E/,
		"EIO mid-slurp propagates with canonical '$MSG_EIO' string";
};

subtest 'io-failure-read: EINTR (interrupted syscall) mid-slurp - propagates' => sub {
	# An async signal (SIGALRM, SIGTERM) arrived while sysread() was blocked.
	# The kernel set errno = EINTR.  Path::Tiny does not automatically retry;
	# the exception propagates to generate()'s caller.
	my $g_home  = empty_home();
	my $mf      = make_mf($MF_SIMPLE);
	my $g_slurp = mock_scoped 'Path::Tiny::slurp_utf8' => sub {
		local $! = EINTR;
		die "sysread: $!\n";
	};

	throws_ok {
		App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 0)
	} qr/\Q$MSG_EINTR\E/,
		"EINTR mid-slurp propagates with canonical '$MSG_EINTR' string";
};

subtest 'io-failure-read: ENOENT (TOCTOU race) - file removed between guard and slurp' => sub {
	# Race window: another process deletes Makefile.PL after the -f/-r check
	# passes (TOCTOU).  slurp_utf8 then fails with ENOENT.  The error must
	# propagate clearly and not be confused with the Cannot-read guard croak.
	my $g_home  = empty_home();
	my $mf      = make_mf($MF_SIMPLE);
	my $g_slurp = mock_scoped 'Path::Tiny::slurp_utf8' => sub {
		local $! = ENOENT;
		die "open: $!\n";
	};

	throws_ok {
		App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 0)
	} qr/\Q$MSG_ENOENT\E/,
		"ENOENT from TOCTOU race propagates with canonical '$MSG_ENOENT' string";
};

subtest 'io-failure-read: ENOMEM (OOM) during Makefile.PL buffer allocation - propagates' => sub {
	# The kernel cannot allocate the page-cache buffer for the file content.
	# Possible under strict cgroup memory limits in containers.
	my $g_home  = empty_home();
	my $mf      = make_mf($MF_SIMPLE);
	my $g_slurp = mock_scoped 'Path::Tiny::slurp_utf8' => sub {
		local $! = ENOMEM;
		die "mmap: $!\n";
	};

	throws_ok {
		App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 0)
	} qr/\Q$MSG_ENOMEM\E/,
		"ENOMEM during buffer alloc propagates with canonical '$MSG_ENOMEM' string";
};

subtest 'io-failure-read: unexpected EOF - slurp_utf8 returns truncated Makefile.PL' => sub {
	# Simulate a file whose size shrank between stat() and read() (a log
	# rotator truncated the wrong file, or a network FS returned a stale
	# inode size).  The truncated string ends mid-PREREQ_PM (no closing
	# brace), so generate() must return a valid header-only cpanfile, not
	# a partial or malformed entry.
	my $g_home  = empty_home();
	my $mf      = make_mf($MF_SIMPLE);
	my $g_slurp = mock_scoped 'Path::Tiny::slurp_utf8' => sub {
		return "WriteMakefile(PREREQ_PM => { \x27Carp\x27 =>";    # truncated mid-value
	};

	my $out;
	lives_ok {
		$out = App::makefilepl2cpanfile::generate(
			makefile     => "$mf",
			with_develop => 0,
		)
	} 'truncated Makefile.PL (unexpected EOF) does not crash generate()';

	like   $out, qr/# Generated from/, 'header present in output for truncated input';
	unlike $out, qr/requires 'Carp'/,  'unclosed PREREQ_PM block produces no partial dep entry';

	diag "Output (truncated input):\n$out" if $ENV{TEST_VERBOSE};
};

subtest 'io-failure-config: ENOSPC during YAML config read - croak includes path and errno' => sub {
	# On copy-on-write (ZFS, BTRFS) and journaling (ext4) filesystems,
	# even read operations can fail with ENOSPC when the FS needs to
	# allocate metadata blocks.  The croak must include the config file
	# path so operators can identify the failing mount.
	my $dir = tempdir(CLEANUP => 1);
	path($dir)->child('.config')->mkpath;
	path($dir)->child('.config', 'makefilepl2cpanfile.yml')
		->spew_utf8("develop:\n  Perl::Critic: 0\n");

	my $g_home = mock_scoped 'File::HomeDir::my_home' => sub { $dir };
	my $g_yaml = mock_scoped(
		'YAML::Tiny::read'   => sub { return undef },
		'YAML::Tiny::errstr' => sub { "No space left on device (ENOSPC)" },
	);
	my $mf = make_mf($MF_SIMPLE);

	throws_ok {
		App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 1)
	} qr/Failed to parse .+ No space left on device/,
		'ENOSPC on config FS propagates with file path and errno description';
};

subtest 'io-failure-config: EIO during YAML config read - croak includes file path' => sub {
	# Simulates a hardware error on the filesystem holding the user config
	# (e.g., USB drive physically removed while the config was being read).
	my $dir = tempdir(CLEANUP => 1);
	path($dir)->child('.config')->mkpath;
	path($dir)->child('.config', 'makefilepl2cpanfile.yml')
		->spew_utf8("develop:\n  Perl::Critic: 0\n");

	my $g_home = mock_scoped 'File::HomeDir::my_home' => sub { $dir };
	my $g_yaml = mock_scoped(
		'YAML::Tiny::read'   => sub { return undef },
		'YAML::Tiny::errstr' => sub { "Input/output error (EIO)" },
	);
	my $mf = make_mf($MF_SIMPLE);

	throws_ok {
		App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 1)
	} qr/Failed to parse .+ Input\/output error/,
		'EIO on config filesystem propagates with file path in croak';
};

subtest 'io-failure-config: truncated YAML (partial config write) - carp and use defaults' => sub {
	# Simulates a config file left in a partial state after a crash mid-write:
	# YAML syntax is valid but the expected 'develop' key is absent because
	# the write was killed before that section was flushed to disk.
	# Expected: carp (not croak) naming the missing key; generate() falls
	# back to %DEFAULT_DEVELOP and produces correct output.
	my $dir = tempdir(CLEANUP => 1);
	path($dir)->child('.config')->mkpath;
	path($dir)->child('.config', 'makefilepl2cpanfile.yml')
		->spew_utf8("develop:\n  Perl::Critic: 0\n");

	my $g_home = mock_scoped 'File::HomeDir::my_home' => sub { $dir };
	my $g_yaml = mock_scoped 'YAML::Tiny::read' => sub {
		# Return a valid YAML::Tiny object whose first document has metadata
		# keys but no 'develop' key - simulating a file truncated before the
		# developer-tools section was written.
		return YAML::Tiny->new( { name => 'my-project', version => '0.01' } );
	};
	my $mf = make_mf($MF_SIMPLE);

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	my $out;
	lives_ok {
		$out = App::makefilepl2cpanfile::generate(
			makefile     => "$mf",
			with_develop => 1,
		)
	} "truncated YAML (no 'develop' key) does not croak - falls back to defaults";

	ok scalar @warnings > 0,   "carp emitted when 'develop' key is absent from config";
	like $warnings[0], qr/No 'develop' key/, "carp message identifies the missing 'develop' key";
	like $out, qr/Perl::Critic/, '%DEFAULT_DEVELOP tools present in output - fallback succeeded';

	diag "Warnings: @warnings\nOutput:\n$out" if $ENV{TEST_VERBOSE};
};

subtest 'io-failure-integrity: successful call after EIO failure - no state corruption' => sub {
	# After generate() throws due to a mid-slurp EIO, all module-level
	# Readonly constants must be intact and a subsequent call with working
	# I/O must produce output identical to a call never preceded by failure.
	my $g   = empty_home();
	my $mf  = make_mf($MF_SIMPLE);
	my $mf2 = make_mf($MF_SIMPLE);    # identical content, separate temp file

	# First call: inject EIO failure.
	{
		my $g_slurp = mock_scoped 'Path::Tiny::slurp_utf8' => sub {
			local $! = EIO;
			die "disk: $!\n";
		};
		eval { App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 0) };
		like $@, qr/disk/, 'first call failed as expected (EIO)';
	}    # $g_slurp destroyed here - real slurp_utf8 is restored

	# Second call: no mock active - real I/O must succeed.
	my $out_after = App::makefilepl2cpanfile::generate(
		makefile     => "$mf",
		with_develop => 0,
	);

	# Reference: a fresh call never preceded by any failure.
	my $out_ref = App::makefilepl2cpanfile::generate(
		makefile     => "$mf2",
		with_develop => 0,
	);

	is $out_after, $out_ref,
		'output after EIO failure matches fresh reference call - no state corruption';
};

subtest 'io-failure-integrity: $! and $@ contract after successful generate()' => sub {
	# Pre-poisoning $! with ENOSPC must not prevent generate() from completing
	# (Perl code treats $! as write-only; only syscalls write to the kernel
	# errno slot).  After a successful call, $@ must be empty - no leaked
	# eval artefacts from YAML::Tiny or other internal eval blocks.
	my $g  = empty_home();
	my $mf = make_mf($MF_SIMPLE);

	local $! = ENOSPC;    # pre-set errno to "disk full" as a hostile pre-condition

	my $out;
	lives_ok {
		$out = App::makefilepl2cpanfile::generate(
			makefile     => "$mf",
			with_develop => 0,
		)
	} "generate() succeeds even with pre-existing \$! = ENOSPC ($MSG_ENOSPC)";

	like $out, qr/Carp/, 'correct dependency output produced';
	is $@, '', '$@ is empty after successful generate() - no leaked eval artefacts';
};

# =======================================================================
# Extended hostile suite
#
# Everything below was added in a second pass.  Configuration lives in
# %HOSTILE so that limits and payloads are named, not magic.
# =======================================================================

Readonly my %HOSTILE => (
	header        => '# Generated from Makefile.PL using makefilepl2cpanfile',
	time_limit    => 5,			# seconds; generous, catches quadratic blow-ups
	many_blocks   => 20_000,		# one-line Makefile.PL with this many hashes
	huge_name_len => 100_000,
	huge_ver_len  => 10_000,
	bomb_depth    => 50_000,
	pwn_var       => 'main::EDGE_PWNED',
	canary        => 'CANARY_FILE',
	cpanfile      => 'cpanfile',
	written       => 'cpanfile written successfully.',
);

# OUTPUT schema from generate()'s API SPECIFICATION.
Readonly my %GENERATE_OUTPUT => (
	type    => 'string',
	matches => qr/\A\Q$HOSTILE{header}\E\n.*(?<!\n)\n\z/s,
);

Readonly my $BIN_PATH => path($Bin)->parent->child('bin', 'makefilepl2cpanfile')->absolute->stringify;
Readonly my $LIB_PATH => path($Bin)->parent->child('lib')->absolute->stringify;

# Loads cpanfile text the way cpanm does (Module::CPANfile evaluates it as
# Perl) and reports whether that ran any code other than dependency
# declarations.  Every security payload below tries to set $EDGE_PWNED.
sub loads_safely {
	my ($text, $name) = @_;
	require Module::CPANfile;
	no strict 'refs';
	local ${ $HOSTILE{pwn_var} };
	my $file = path(tempdir(CLEANUP => 1))->child($HOSTILE{cpanfile});
	$file->spew_utf8($text);
	my $ok = eval { Module::CPANfile->load("$file"); 1 };
	my $err = $@;
	diag "loads_safely($name): $err\n$text" if $ENV{TEST_VERBOSE} && !$ok;
	ok $ok, "$name: generated cpanfile loads" or diag $err;
	ok !defined ${ $HOSTILE{pwn_var} }, "$name: no injected code executed";
	return;
}

# Runs $code with warnings captured; returns (result, @warnings).
sub capture_warns {
	my $code = $_[0];
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	my $r = $code->();
	return ($r, @w);
}

# Fails if $code takes longer than the time limit (or hangs).
sub within_time_limit {
	my ($code, $name) = @_;
	my $start = Time::HiRes::time();
	my $r = eval {
		local $SIG{ALRM} = sub { die "timeout\n" };
		alarm $HOSTILE{time_limit} * 2;
		my $v = $code->();
		alarm 0;
		$v;
	};
	alarm 0;
	my $elapsed = Time::HiRes::time() - $start;
	diag sprintf('%s: %.3fs', $name, $elapsed) if $ENV{TEST_VERBOSE};
	ok !$@ && $elapsed < $HOSTILE{time_limit}, "$name: completes within $HOSTILE{time_limit}s"
		or diag "error: $@ elapsed: $elapsed";
	return $r;
}

# -----------------------------------------------------------------------
# Security: code injection through the existing cpanfile (VULN-3)
#
# Strategy: an existing cpanfile is untrusted input (it can arrive in a
# pull request).  Its develop entries are written back into generated
# Perl, so every character that could end a quoted literal or start code
# must be neutralised.  Each payload is loaded with Module::CPANfile to
# prove nothing runs.
# -----------------------------------------------------------------------
subtest 'security: existing develop versions cannot inject code (VULN-3 regression)' => sub {
	my $g  = empty_home();
	my $mf = make_mf($MF_SIMPLE);

	# The working exploit found in the wild: a trailing backslash escapes
	# the closing quote, and the module name 'x' becomes Perl's repetition
	# operator, leaving the rest of the line as live code.
	my $exploit = <<"END_CPANFILE";
on 'develop' => sub {
	requires 'A1', '\\';
	requires 'x', ',1;\$$HOSTILE{pwn_var}=1;';
};
END_CPANFILE
	my ($out, @w) = capture_warns(sub {
		App::makefilepl2cpanfile::generate(makefile => "$mf", existing => $exploit, with_develop => 0)
	});
	diag "exploit output:\n$out" if $ENV{TEST_VERBOSE};
	like $w[0], qr/\AIgnoring invalid version for 'A1' in existing cpanfile: '\\' at /,
		'backslash version rejected with the documented warning';
	like $out, qr/^\trequires 'A1';$/m, 'entry kept without the hostile version';
	loads_safely($out, 'backslash exploit');

	# Further characters that are meaningful inside or around a literal.
	for my $ver ('\\\\', '1.0\\', '$x', '@{[1]}', '1;2', '1 2', ' 1.0', '1.0 ', '.', '_', "1\t0") {
		my $existing = "on 'develop' => sub {\n\trequires 'Hostile::Ver', '$ver';\n};\n";
		my ($o, @ww) = capture_warns(sub {
			App::makefilepl2cpanfile::generate(makefile => "$mf", existing => $existing, with_develop => 0)
		});
		like $o, qr/^\trequires 'Hostile::Ver';$/m, "version '$ver' dropped";
		is scalar @ww, 1, "version '$ver' warned about";
	}

	# Legitimate spellings must survive untouched and silently.
	for my $ver (qw(1 1.0 0.001 v1.2.3 1.23_01 5.010001)) {
		my $existing = "on 'develop' => sub {\n\trequires 'Good::Ver', '$ver';\n};\n";
		my ($o, @ww) = capture_warns(sub {
			App::makefilepl2cpanfile::generate(makefile => "$mf", existing => $existing, with_develop => 0)
		});
		like $o, qr/^\trequires 'Good::Ver', '\Q$ver\E';$/m, "version '$ver' kept";
		is scalar @ww, 0, "version '$ver' raises no warning";
	}
};

# -----------------------------------------------------------------------
# Security: every source of text that reaches the output
#
# Strategy: a single Makefile.PL, existing cpanfile and config, each laced
# with a different breakout attempt (quote, backslash, CR inside a comment,
# statement separators, heredoc markers).  Whatever survives validation must
# load under Module::CPANfile without executing anything.
# -----------------------------------------------------------------------
subtest 'security: combined breakout attempts across all inputs' => sub {
	my $pwn = "\$$HOSTILE{pwn_var}=1";
	my $mf = make_mf(<<"END_MF");
WriteMakefile(
	MIN_PERL_VERSION => '5.010'; $pwn; #',
	PREREQ_PM => {
		'Comment::CR' => 0,	# harmless\r$pwn;
		'Quote::Ver'  => '1.0\\'; $pwn; #',
		"Double'Q"    => 0,
		'Semi;colon'  => 0,
		'Here::Doc'   => 0,	# <<EOT
	},
	META_MERGE => {
		recommends => { 'Legacy::Rec' => '2.0', # \\
		},
	},
);
END_MF
	my $g = home_with_config({ develop => {
		"Cfg'; $pwn; '" => 0,
		'Cfg::Ver'       => "1'; $pwn; '",
	} });
	my $existing = "on 'develop' => sub {\n\trequires 'Ex::Tool', '1\\';\n\trequires 'x', ',1;$pwn;';\n};\n";

	my ($out) = capture_warns(sub {
		App::makefilepl2cpanfile::generate(makefile => "$mf", existing => $existing)
	});
	diag "combined output:\n$out" if $ENV{TEST_VERBOSE};
	returns_is($out, \%GENERATE_OUTPUT, 'output still matches the documented schema');
	unlike $out, qr/Double|Semi/, 'invalid module names never reach the output';
	loads_safely($out, 'combined');
};

# -----------------------------------------------------------------------
# Commented-out code (BUG 4 regression)
#
# Strategy: authors disable dependencies by commenting them out.  Every
# kind of block, commented on one line, must be ignored - while a '#'
# inside a quoted string earlier on the same line must not hide a real one.
# -----------------------------------------------------------------------
subtest 'parse_prereqs: one-line commented-out blocks are ignored (BUG 4 regression)' => sub {
	my $d = App::makefilepl2cpanfile::parse_prereqs(<<'END_MF');
WriteMakefile(
	# PREREQ_PM => { 'Old::Runtime' => 0 },
	#TEST_REQUIRES => { 'Old::Test' => 0 },
	NAME => 'x',  # BUILD_REQUIRES => { 'Old::Build' => 0 },
	# prereqs => { runtime => { requires => { 'Old::Struct' => 0 } } },
	META_MERGE => {
		# recommends => { 'Old::Rec' => 0 },
		## suggests => { 'Old::Sug' => 0 },
	},
	ABSTRACT => 'a C# tool', PREREQ_PM => { 'Live::Runtime' => 0 },
	DESCRIPTION => "issue #1", TEST_REQUIRES => { 'Live::Test' => 0 },
);
END_MF
	is_deeply $d, {
		runtime => { requires => { 'Live::Runtime' => { version => 0, comment => undef } } },
		test    => { requires => { 'Live::Test'    => { version => 0, comment => undef } } },
	}, 'only the live blocks are parsed; quoted # does not hide a block';
};

subtest 'generate: commented-out develop entries are not carried over (BUG 4 regression)' => sub {
	my $g  = empty_home();
	my $mf = make_mf($MF_SIMPLE);
	my $existing = <<'END_CPANFILE';
on 'develop' => sub {
	# requires 'Old::Tool';
	requires 'Live::Tool';	# requires 'Trailing::Old';
	#recommends 'Old::Rec', '1.0';
};
END_CPANFILE
	my $out = App::makefilepl2cpanfile::generate(makefile => "$mf", existing => $existing, with_develop => 0);
	like   $out, qr/^\trequires 'Live::Tool';$/m, 'live entry kept';
	unlike $out, qr/Old::Tool|Trailing::Old|Old::Rec/, 'commented-out entries dropped';
};

# -----------------------------------------------------------------------
# Version shapes (BUG 5 regression)
#
# Strategy: versions that match a naive [\d._]+ but are not versions, and
# digits from other scripts that \d matches without /a.  None may reach
# the output, and the result must be a cpanfile the toolchain accepts.
# -----------------------------------------------------------------------
subtest 'versions: digitless and non-ASCII versions are treated as no minimum (BUG 5 regression)' => sub {
	my $g = empty_home();
	my $arabic_digits = "\x{0661}\x{0662}";		# ARABIC-INDIC ONE, TWO
	for my $case (['.', 'lone dot'], ['_', 'lone underscore'], ['._.', 'punctuation only'],
			[$arabic_digits, 'Arabic-Indic digits']) {
		my ($ver, $name) = @{$case};
		my $mf = make_mf("WriteMakefile(MIN_PERL_VERSION => '$ver', PREREQ_PM => { 'Some::Mod' => '$ver' });\n");
		my ($out, @w) = capture_warns(sub {
			App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 0)
		});
		unlike $out, qr/'perl'/, "$name: no perl line";
		like $out, qr/^requires 'Some::Mod';$/m, "$name: module kept without version";
		is scalar @w, 0, "$name: no warnings";
		loads_safely($out, $name);
	}

	# The same rule protects the config file.
	my $gc = home_with_config({ develop => { 'Cfg::Tool' => $arabic_digits } });
	my ($out, @w) = capture_warns(sub {
		App::makefilepl2cpanfile::generate(makefile => make_mf($MF_SIMPLE)->stringify)
	});
	like $w[0], qr/\ASkipping invalid version for 'Cfg::Tool' in /, 'config: non-ASCII digits rejected';
	like $out, qr/^\trequires 'Cfg::Tool';$/m, 'config: tool kept without version';
};

# -----------------------------------------------------------------------
# Hostile argument types (BUG 6 regression)
#
# Strategy: makefile is documented as a string path.  References of every
# kind, typeglobs, and circular structures must all be rejected by the same
# "Cannot read" guard - never slip through to Path::Tiny or hang.
# -----------------------------------------------------------------------
subtest 'generate: non-path makefile values are rejected with "Cannot read"' => sub {
	my $g  = empty_home();
	my $mf = make_mf($MF_SIMPLE);
	open my $fh, '<', "$mf" or die "open $mf: $!";
	my $cycle = {};
	$cycle->{self} = $cycle;

	for my $case (
		[$fh, 'open filehandle'], [\*STDIN, 'glob reference'], [*STDIN, 'bare typeglob'],
		[[], 'arrayref'], [{}, 'hashref'], [sub { "$mf" }, 'coderef'], [\"$mf", 'scalar ref to a valid path'],
		[$cycle, 'circular hashref'], [0, 'zero'], [q{}, 'empty string'], [q{ }, 'single space'],
	) {
		my ($value, $name) = @{$case};
		throws_ok { App::makefilepl2cpanfile::generate(makefile => $value, with_develop => 0) }
			qr/\ACannot read '\Q$value\E' at /, "$name rejected";
	}
	close $fh;

	# An object that stringifies to a path is a path.
	my $out = App::makefilepl2cpanfile::generate(makefile => $mf, with_develop => 0);
	like $out, qr/^requires 'Carp';$/m, 'Path::Tiny object accepted';

	# Duplicate keys in the flat form: the last one wins, as for any hash.
	$out = App::makefilepl2cpanfile::generate(
		makefile => '/no/such/file', makefile => "$mf", with_develop => 0,
	);
	like $out, qr/^requires 'Carp';$/m, 'duplicate makefile key: last value used';

	# A lone positional argument is not a documented calling style.
	throws_ok { App::makefilepl2cpanfile::generate("$mf") } qr/\AUsage: /,
		'positional path rejected with a usage message';
};

subtest 'generate/parse_prereqs: hostile existing and content values' => sub {
	my $g  = empty_home();
	my $mf = make_mf($MF_SIMPLE);
	my $cycle = [];
	push @{$cycle}, $cycle;

	for my $case ([0, 'zero'], [$cycle, 'circular arrayref'], [*STDOUT, 'typeglob'],
			["on 'develop' => sub {\n\trequires 'Never::Closed';\n", 'unterminated develop block']) {
		my ($value, $name) = @{$case};
		my ($out, @w) = capture_warns(sub {
			App::makefilepl2cpanfile::generate(makefile => "$mf", existing => $value, with_develop => 0)
		});
		unlike $out, qr/on 'develop'/, "existing $name: nothing merged";
		is scalar @w, 0, "existing $name: no warnings";
	}

	for my $case ([*STDOUT, 'typeglob'], [\*STDOUT, 'glob ref'], [$cycle, 'circular arrayref'], [0, 'zero']) {
		my ($value, $name) = @{$case};
		my ($d, @w) = capture_warns(sub { App::makefilepl2cpanfile::parse_prereqs($value) });
		is_deeply $d, {}, "parse_prereqs($name): empty result";
		is scalar @w, 0, "parse_prereqs($name): no warnings";
	}
};

# -----------------------------------------------------------------------
# Hostile file names
#
# Strategy: real files whose names are shell syntax.  If any of them
# reached a shell or a 2-argument open, the canary file would appear or
# the victim file would be truncated.  Each must simply be read.
# -----------------------------------------------------------------------
subtest 'filesystem: hostile but real file names are read safely' => sub {
	my $g   = empty_home();
	my $dir = path(tempdir(CLEANUP => 1));
	my $victim = $dir->child('victim');
	$victim->spew_utf8($MF_SIMPLE);

	# Windows forbids these characters in file names, so names using them
	# are only tried where the file system accepts them.  The cmd.exe
	# metacharacters (& ^ %) are legal everywhere and always tried.
	my $illegal = $^O eq 'MSWin32' ? qr/[<>:"|?*\x00-\x1f]/ : qr/\x00/;
	my @names = grep { $_ !~ $illegal } (
		"with space.PL", " leading.PL", "trailing.PL ", "semi;touch $HOSTILE{canary};.PL",
		"pipe | touch $HOSTILE{canary}", "touch $HOSTILE{canary} |", '>victim', '<victim',
		"\$(touch $HOSTILE{canary})", "`touch $HOSTILE{canary}`", "new\nline.PL", '-dash.PL', '*glob?.PL',
		"amp & type nul > $HOSTILE{canary}", "and & echo $HOSTILE{canary}.PL", 'caret^.PL', 'pct %PATH%.PL',
	);
	my $cwd = Path::Tiny->cwd;
	chdir $dir or die "chdir $dir: $!";
	for my $name (@names) {
		(my $shown = $name) =~ s/\n/\\n/g;
		path($name)->spew_utf8("WriteMakefile(PREREQ_PM => { 'Named::Ok' => 0 });\n");
		my $out = eval { App::makefilepl2cpanfile::generate(makefile => $name, with_develop => 0) };
		like $out, qr/^requires 'Named::Ok';$/m, "'$shown' read correctly" or diag $@;
	}
	my $canary = -e $HOSTILE{canary};
	my $victim_intact = $victim->slurp_utf8 eq $MF_SIMPLE;
	chdir $cwd or die "chdir $cwd: $!";
	ok !$canary, 'no shell command ran';
	ok $victim_intact, 'no file was truncated by a mode character in a name';
};

# -----------------------------------------------------------------------
# Special files and degenerate content
#
# Strategy: things that are not regular files must be refused before any
# read (a FIFO would block forever, a device could stream endlessly), and
# regular files with no dependencies must still yield a valid cpanfile.
# -----------------------------------------------------------------------
subtest 'filesystem: special files are refused without blocking' => sub {
	my $g   = empty_home();
	my $dir = path(tempdir(CLEANUP => 1));

	SKIP: {
		skip 'mkfifo not available', 1 unless $Config{d_mkfifo};
		my $fifo = $dir->child('fifo.PL');
		POSIX::mkfifo("$fifo", oct 600) or skip "mkfifo: $!", 1;
		within_time_limit(sub {
			throws_ok { App::makefilepl2cpanfile::generate(makefile => "$fifo") }
				qr/\ACannot read '\Q$fifo\E' at /, 'FIFO refused';
		}, 'FIFO');
	}

	for my $dev (qw(/dev/zero /dev/full /dev/tty)) {
		next unless -e $dev;
		throws_ok { App::makefilepl2cpanfile::generate(makefile => $dev) }
			qr/\ACannot read '\Q$dev\E' at /, "$dev refused";
	}

	SKIP: {
		skip 'symlinks not supported', 3 unless $Config{d_symlink};
		my $loop = $dir->child('loop.PL');
		symlink 'loop.PL', "$loop";
		throws_ok { App::makefilepl2cpanfile::generate(makefile => "$loop") }
			qr/\ACannot read /, 'symlink loop refused';

		my $to_dir = $dir->child('dir.PL');
		symlink "$dir", "$to_dir";
		throws_ok { App::makefilepl2cpanfile::generate(makefile => "$to_dir") }
			qr/\ACannot read /, 'symlink to a directory refused';

		my $real = make_mf($MF_SIMPLE);
		my $link = $dir->child('link.PL');
		# Perl may support symlink() on Windows while the account lacks the
		# privilege to create one.
		symlink "$real", "$link" or skip "cannot create a symlink here: $!", 1;
		like App::makefilepl2cpanfile::generate(makefile => "$link", with_develop => 0),
			qr/^requires 'Carp';$/m, 'symlink to a regular file followed';
	}
};

subtest 'filesystem: degenerate but valid files' => sub {
	my $g = empty_home();
	for my $case ([q{}, '0-byte file'], ["\n", 'single LF'], ["\r\n", 'single CRLF'],
			[" \t \n\n", 'whitespace only'], ["\x{feff}", 'BOM only'], ["\0\0\0", 'NUL bytes']) {
		my ($content, $name) = @{$case};
		my $mf = make_mf($content);
		my ($out, @w) = capture_warns(sub {
			App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 0)
		});
		is $out, "$HOSTILE{header}\n", "$name: header only";
		is scalar @w, 0, "$name: no warnings";
	}

	# CRLF line endings must parse exactly like LF, with no stray CR in comments.
	my $lf   = "WriteMakefile(\n\tMIN_PERL_VERSION => '5.010',\n\tPREREQ_PM => {\n\t\t'A::B' => '1.0',\t# note\n\t},\n);\n";
	(my $crlf = $lf) =~ s/\n/\r\n/g;
	is App::makefilepl2cpanfile::generate(makefile => make_mf($crlf)->stringify, with_develop => 0),
		App::makefilepl2cpanfile::generate(makefile => make_mf($lf)->stringify, with_develop => 0),
		'CRLF Makefile.PL gives the same output as LF';
};

subtest 'filesystem: hostile config file locations' => sub {
	my $mf = make_mf($MF_SIMPLE);
	my %defaults = map { $_ => 1 } qw(Devel::Cover Perl::Critic Test::Pod Test::Pod::Coverage);

	my $with_home = sub {
		my ($setup, $name, $check) = @_;
		my $home = path(tempdir(CLEANUP => 1));
		my $cfg  = $home->child('.config', 'makefilepl2cpanfile.yml');
		$cfg->parent->mkpath;
		$setup->($cfg);
		my $g = mock_scoped 'File::HomeDir::my_home' => sub { "$home" };
		my ($out, @w);
		my $ok = within_time_limit(sub {
			($out, @w) = capture_warns(sub { App::makefilepl2cpanfile::generate(makefile => "$mf") });
			1;
		}, $name);
		$check->($out, \@w, $cfg) if $ok;
	};
	my $uses_defaults = sub {
		my ($out, $name) = @_;
		is_deeply { map { $_ => 1 } $out =~ /^\trequires '([^']+)';$/mg }, \%defaults,
			"$name: built-in tools used";
	};

	$with_home->(sub { $_[0]->mkpath }, 'config is a directory', sub {
		$uses_defaults->($_[0], 'config is a directory');
		is scalar @{ $_[1] }, 0, 'config is a directory: silent';
	});
	SKIP: {
		skip 'symlinks not supported', 4 unless $Config{d_symlink};
		$with_home->(sub { symlink '/no/such/target', "$_[0]" }, 'dangling config symlink', sub {
			$uses_defaults->($_[0], 'dangling config symlink');
		});
		skip 'no /dev/urandom', 2 unless -e '/dev/urandom';
		$with_home->(sub { symlink '/dev/urandom', "$_[0]" }, 'config symlink to /dev/urandom', sub {
			$uses_defaults->($_[0], 'config symlink to /dev/urandom');
		});
	}
	SKIP: {
		skip 'mkfifo not available', 2 unless $Config{d_mkfifo};
		$with_home->(sub { POSIX::mkfifo("$_[0]", oct 600) }, 'config is a FIFO', sub {
			$uses_defaults->($_[0], 'config is a FIFO');
			is scalar @{ $_[1] }, 0, 'config is a FIFO: silent';
		});
	}
	{
		# A real (unmocked) syntax error must produce the documented message.
		my $home = path(tempdir(CLEANUP => 1));
		my $cfg  = $home->child('.config', 'makefilepl2cpanfile.yml');
		$cfg->parent->mkpath;
		$cfg->spew_utf8("develop: [\n  x");
		my $g = mock_scoped 'File::HomeDir::my_home' => sub { "$home" };
		throws_ok { App::makefilepl2cpanfile::generate(makefile => "$mf") }
			qr/\AFailed to parse \Q$cfg\E: YAML::Tiny \S.* at t\/edge_cases\.t /,
			'real YAML syntax error: documented croak, reported at the caller';
	}
	$with_home->(sub { $_[0]->spew_utf8(q{}) }, 'empty config file', sub {
		$uses_defaults->($_[0], 'empty config file');
		like $_[1][0], qr/\ANo 'develop' key found in /, 'empty config file: warned';
	});
	$with_home->(sub { $_[0]->spew_utf8("develop:\n  - Perl::Critic\n") }, 'develop is a list', sub {
		$uses_defaults->($_[0], 'develop is a list');
		like $_[1][0], qr/\ANo 'develop' key found in /, 'develop is a list: warned';
	});
	SKIP: {
		skip 'chmod cannot make a file unreadable here (root or Windows)', 1 unless can_revoke_read();
		my $home = path(tempdir(CLEANUP => 1));
		my $cfg  = $home->child('.config', 'makefilepl2cpanfile.yml');
		$cfg->parent->mkpath;
		$cfg->spew_utf8("develop:\n  X: 1\n");
		chmod 0, "$cfg";
		my $g = mock_scoped 'File::HomeDir::my_home' => sub { "$home" };
		throws_ok { App::makefilepl2cpanfile::generate(makefile => "$mf") }
			qr/\AFailed to parse \Q$cfg\E: \S.* at /, 'unreadable config: documented croak with the reason';
		chmod 0600, "$cfg";
	}
};

# -----------------------------------------------------------------------
# Upstream failures (BUG 6 regression for the '' home and undef read)
#
# Strategy: each collaborator returns the classic "failure" values -
# undef, '', 0, empty objects - and the module must degrade exactly as
# documented instead of crashing or warning.
# -----------------------------------------------------------------------
subtest 'upstream: File::HomeDir returns failure values' => sub {
	my $mf = make_mf($MF_SIMPLE);
	for my $case ([undef, 'undef'], [q{}, 'empty string']) {
		my ($home, $name) = @{$case};
		my $g = mock_scoped 'File::HomeDir::my_home' => sub { $home };
		my ($out, @w);
		lives_ok { ($out, @w) = capture_warns(sub { App::makefilepl2cpanfile::generate(makefile => "$mf") }) }
			"my_home() returning $name does not crash";
		like $out, qr/^\trequires 'Perl::Critic';$/m, "my_home() returning $name: built-in tools used";
		is scalar @w, 0, "my_home() returning $name: no warnings";
	}
};

subtest 'security: CLI refuses a cpanfile that is a symlink (arbitrary file overwrite)' => sub {
	# A cloned repository controls its own files.  Path::Tiny's spew follows
	# symlinks, so 'cpanfile -> ~/.bashrc' made the tool overwrite a file
	# outside the repository.  Both a live and a dangling link (which would
	# create a file wherever it points) must be refused, and nothing written.
	SKIP: {
		skip 'symlinks not supported', 8 unless $Config{d_symlink};
		my $outside = path(tempdir(CLEANUP => 1));
		my $victim  = $outside->child('victim_rc');
		$victim->spew_utf8("precious\n");
		for my $target ("$victim", $outside->child('not_yet_created')->stringify) {
			my $kind = -e $target ? 'live link' : 'dangling link';
			my $repo = path(tempdir(CLEANUP => 1));
			$repo->child('Makefile.PL')->spew_utf8($MF_SIMPLE);
			symlink $target, $repo->child($HOSTILE{cpanfile})->stringify
				or skip "cannot create a symlink here: $!", 8;
			my $cwd = Path::Tiny->cwd;
			local $ENV{HOME} = tempdir(CLEANUP => 1);
			chdir $repo or die "chdir: $!";
			my ($out, $err, $exit) = Capture::Tiny::capture(sub { system $^X, "-I$LIB_PATH", $BIN_PATH });
			chdir $cwd or die "chdir: $!";
			isnt $exit >> 8, 0, "$kind: non-zero exit";
			like $err, qr/Refusing to use 'cpanfile': it is a symbolic link/, "$kind: refused with the documented message";
			unlike $out, qr/\Q$HOSTILE{written}\E/, "$kind: no success message";
		}
		is $victim->slurp_utf8, "precious\n", 'the linked file was not changed';
		ok !-e $outside->child('not_yet_created'), 'no file was created through the dangling link';
	}
};

subtest 'security: untrusted text in warnings and errors cannot drive the terminal' => sub {
	# Values from the existing cpanfile, the config file and the parser's
	# own error text are echoed in messages.  Raw, an ESC ] 0 ; ... BEL
	# sequence retitles the terminal and CR + ESC [ 2 K erases the line, so
	# a warning could be hidden or forged.  They must arrive escaped.
	my $esc = "\e]0;OWNED\a\e[2K\r";
	my $no_controls = qr/\A[^\x00-\x08\x0B-\x1F\x7F]*\z/;

	my $g  = empty_home();
	my $mf = make_mf($MF_SIMPLE);
	my (undef, @w) = capture_warns(sub {
		App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 0,
			existing => "on 'develop' => sub {\n\trequires 'X', '1${esc}';\n};\n")
	});
	like $w[0], qr/'1\\x\{1B\}\]0;OWNED\\x\{7\}\\x\{1B\}\[2K\\x\{D\}'/, 'existing-cpanfile version shown escaped';
	like $w[0] =~ s/\n\z//r, $no_controls, 'no raw control characters in the warning';

	my ($gc) = home_with_config({ develop => { "Bad${esc}Name" => 0, 'Tool' => "1${esc}" } });
	(undef, @w) = capture_warns(sub { App::makefilepl2cpanfile::generate(makefile => "$mf") });
	is scalar @w, 2, 'one warning per bad config entry';
	like $_ =~ s/\n\z//r, $no_controls, 'config warning has no raw control characters' for @w;
};

subtest 'upstream: I/O error whose path contains decoder keywords is not mistaken for bad UTF-8' => sub {
	# Path::Tiny's I/O errors are objects whose text includes the path.
	# Matching /decode|ill-formed|utf/ against that text treated an I/O
	# failure in a directory named e.g. "utf8-tools" as an encoding error
	# and hid it behind a raw re-read.  Objects must always be rethrown.
	my $g  = empty_home();
	my $mf = make_mf($MF_SIMPLE);
	my $raw_reads = 0;
	my $m = mock_scoped(
		'Path::Tiny::slurp_utf8' => sub {
			Path::Tiny::Error->throw('open', '/src/utf8-tools/decode/ill-formed/Makefile.PL', $MSG_EIO);
		},
		'Path::Tiny::slurp_raw' => sub { $raw_reads++; q{} },
	);
	my ($out, @w) = capture_warns(sub {
		eval { App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 0) }
	});
	isa_ok $@, 'Path::Tiny::Error', 'the I/O error reaches the caller';
	is $raw_reads, 0, 'no raw re-read was attempted';
	is scalar @w, 0, 'no invalid-UTF-8 warning';
};

subtest 'upstream: Path::Tiny read returns failure values' => sub {
	my $g  = empty_home();
	my $mf = make_mf($MF_SIMPLE);
	for my $case ([undef, 'undef'], [q{}, 'empty string'], ['0', 'zero']) {
		my ($value, $name) = @{$case};
		my $m = mock_scoped 'Path::Tiny::slurp_utf8' => sub { $value };
		my ($out, @w) = capture_warns(sub {
			App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 0)
		});
		is $out, "$HOSTILE{header}\n", "slurp_utf8 returning $name: header only";
		is scalar @w, 0, "slurp_utf8 returning $name: no warnings";
	}

	# Decode failure followed by an empty raw read: only the documented warning.
	my $m = mock_scoped(
		'Path::Tiny::slurp_utf8' => sub { die "Can't decode ill-formed UTF-8\n" },
		'Path::Tiny::slurp_raw'  => sub { undef },
	);
	my ($out, @w) = capture_warns(sub {
		App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 0)
	});
	is $out, "$HOSTILE{header}\n", 'raw fallback returning undef: header only';
	is scalar @w, 1, 'raw fallback returning undef: only the UTF-8 warning';
};

subtest 'upstream: YAML::Tiny returns failure values' => sub {
	my $mf = make_mf($MF_SIMPLE);
	my $home = path(tempdir(CLEANUP => 1));
	my $cfg  = $home->child('.config', 'makefilepl2cpanfile.yml');
	$cfg->parent->mkpath;
	$cfg->spew_utf8("develop: {}\n");
	my $g = mock_scoped 'File::HomeDir::my_home' => sub { "$home" };

	# Any false return is a parse failure, whatever errstr says.
	for my $case ([undef, 'undef'], [0, 'zero'], [q{}, 'empty string']) {
		my ($value, $name) = @{$case};
		my $m = mock_scoped(
			'YAML::Tiny::read'   => sub { $value },
			'YAML::Tiny::errstr' => sub { q{} },
		);
		throws_ok { App::makefilepl2cpanfile::generate(makefile => "$mf") }
			qr/\AFailed to parse \Q$cfg\E: +at /, "read() returning $name: croak";
	}

	# A parsed document that is empty or lacks a usable develop hash.
	for my $case ([ bless([], 'YAML::Tiny'), 'no documents' ],
			[ bless([undef], 'YAML::Tiny'), 'undef document' ],
			[ bless([{ develop => undef }], 'YAML::Tiny'), 'develop is undef' ],
			[ bless([{ develop => 'text' }], 'YAML::Tiny'), 'develop is a string' ]) {
		my ($value, $name) = @{$case};
		my $m = mock_scoped 'YAML::Tiny::read' => sub { $value };
		my ($out, @w) = capture_warns(sub { App::makefilepl2cpanfile::generate(makefile => "$mf") });
		like $w[0], qr/\ANo 'develop' key found in /, "$name: warned";
		like $out, qr/^\trequires 'Perl::Critic';$/m, "$name: built-in tools used";
	}

	# An explicitly empty develop hash means "no develop tools".
	{
		my $m = mock_scoped 'YAML::Tiny::read' => sub { bless [{ develop => {} }], 'YAML::Tiny' };
		my ($out, @w) = capture_warns(sub { App::makefilepl2cpanfile::generate(makefile => "$mf") });
		unlike $out, qr/on 'develop'/, 'empty develop hash: no tools added';
		is scalar @w, 0, 'empty develop hash: no warnings';
	}

	# A develop value that is itself a structure is not a version.
	{
		my $m = mock_scoped 'YAML::Tiny::read' => sub {
			bless [{ develop => { 'Nested::Ver' => { a => 1 }, 'List::Ver' => [1] } }], 'YAML::Tiny'
		};
		my ($out, @w) = capture_warns(sub { App::makefilepl2cpanfile::generate(makefile => "$mf") });
		is scalar(grep { /\ASkipping invalid version for '(?:Nested|List)::Ver'/ } @w), 2,
			'structured versions rejected';
		like $out, qr/^\trequires 'Nested::Ver';$/m, 'module kept without version';
	}
};

# -----------------------------------------------------------------------
# I/O failure while the CLI writes the cpanfile
#
# Strategy: the library never writes, so write failures belong to the CLI.
# Force ENOSPC ("disk full") inside Path::Tiny's write in a child process,
# and separately make the directory genuinely unwritable.  In both cases
# the tool must fail loudly (non-zero exit, no success message) and leave
# the previous cpanfile exactly as it was.
# -----------------------------------------------------------------------
subtest 'CLI: write failures are reported and leave the old cpanfile intact' => sub {
	my $run = sub {
		my ($dir, @perl_args) = @_;
		my $cwd = Path::Tiny->cwd;
		local $ENV{HOME} = tempdir(CLEANUP => 1);
		chdir $dir or die "chdir $dir: $!";
		my ($out, $err, $exit) = Capture::Tiny::capture(sub { system $^X, "-I$LIB_PATH", @perl_args });
		s/\r\n/\n/g for $out, $err;		# CRLF on Windows
		chdir $cwd or die "chdir $cwd: $!";
		diag "STDOUT: $out\nSTDERR: $err" if $ENV{TEST_VERBOSE};
		return ($out, $err, $exit >> 8);
	};
	my $old = "# previous cpanfile\nrequires 'Keep::Me';\n";

	{
		my $dir = path(tempdir(CLEANUP => 1));
		$dir->child('Makefile.PL')->spew_utf8($MF_SIMPLE);
		$dir->child($HOSTILE{cpanfile})->spew_utf8($old);
		# The wrapper goes in a file, not on the command line: Windows
		# flattens system()'s argument list into one string, and a
		# multi-line -e program with quotes does not survive that.
		my $wrapper = path(tempdir(CLEANUP => 1))->child('enospc.pl');
		$wrapper->spew_utf8(<<'END_PERL');
use Path::Tiny;
use POSIX qw(ENOSPC);
use Test::Mockingbird;
Test::Mockingbird::mock('Path::Tiny', 'tempfile', sub { local $! = ENOSPC; die "Error tempfile: $!\n" });
do $ARGV[0];
die $@ if $@;
END_PERL
		my ($out, $err, $exit) = $run->($dir, "$wrapper", $BIN_PATH);
		isnt $exit, 0, 'ENOSPC: non-zero exit';
		like $err, qr/\Q$MSG_ENOSPC\E/, 'ENOSPC: error reported';
		unlike $out, qr/\Q$HOSTILE{written}\E/, 'ENOSPC: no success message';
		is $dir->child($HOSTILE{cpanfile})->slurp_utf8, $old, 'ENOSPC: previous cpanfile intact';
		is_deeply [ sort map { $_->basename } $dir->children ], [ 'Makefile.PL', $HOSTILE{cpanfile} ],
			'ENOSPC: no other files left behind';
	}

	SKIP: {
		skip 'chmod cannot make a directory read-only here (root or Windows)', 4 unless can_revoke_write();
		my $dir = path(tempdir(CLEANUP => 1));
		$dir->child('Makefile.PL')->spew_utf8($MF_SIMPLE);
		$dir->child($HOSTILE{cpanfile})->spew_utf8($old);
		chmod 0555, "$dir";
		my ($out, $err, $exit) = $run->($dir, $BIN_PATH);
		chmod 0755, "$dir";
		isnt $exit, 0, 'read-only directory: non-zero exit';
		isnt $err, q{}, 'read-only directory: error reported';
		unlike $out, qr/\Q$HOSTILE{written}\E/, 'read-only directory: no success message';
		is $dir->child($HOSTILE{cpanfile})->slurp_utf8, $old, 'read-only directory: previous cpanfile intact';
	}
};

# -----------------------------------------------------------------------
# Pathological sizes and shapes
#
# Strategy: inputs that would expose super-linear regexes or recursion:
# thousands of blocks on one line (the shape that made the first comment
# fix quadratic), deep unbalanced braces, and enormous names and versions.
# -----------------------------------------------------------------------
subtest 'performance: pathological inputs complete in linear-ish time' => sub {
	my $n = $HOSTILE{many_blocks};
	my $one_line = join q{, }, map {
		"PREREQ_PM => { 'M$_' => 0 }, recommends => { 'R$_' => 0 }"
	} 1 .. $n;
	my $d = within_time_limit(sub { App::makefilepl2cpanfile::parse_prereqs($one_line) },
		"$n blocks on one line");
	is scalar keys %{ $d->{runtime}{requires} || {} }, $n, 'every requires found';
	is scalar keys %{ $d->{runtime}{recommends} || {} }, $n, 'every recommends found';

	# Legacy blocks interleaved with prereqs blocks: each legacy block is
	# checked against the prereqs spans, which was a linear scan (quadratic
	# overall: about 25s here) before it became a binary search.
	my $interleaved = join "\n", map {
		"prereqs => { test => { requires => { 'T$_' => 0 } } },\nrecommends => { 'R$_' => 0 },"
	} 1 .. $n;
	my $mixed = within_time_limit(sub { App::makefilepl2cpanfile::parse_prereqs($interleaved) },
		"$n legacy blocks among $n prereqs blocks");
	is scalar keys %{ $mixed->{runtime}{recommends} || {} }, $n, 'every legacy block found';

	# Regex ReDoS regressions: each shape below was quadratic in its length
	# (tens of seconds at these sizes) before the regex was rewritten.
	{
		my $g   = empty_home();
		my $mfr = make_mf($MF_SIMPLE);
		within_time_limit(sub {
			App::makefilepl2cpanfile::generate(makefile => "$mfr", with_develop => 0,
				existing => "on 'develop' => sub {\n" x $HOSTILE{bomb_depth})
		}, 'many unclosed develop openers in the existing cpanfile');
	}
	my $spaces = ' ' x ($HOSTILE{bomb_depth} * 2);
	my $blank = within_time_limit(sub { App::makefilepl2cpanfile::parse_prereqs("PREREQ_PM => {\n'A' => 0, #$spaces\n},") },
		"'#' followed only by spaces");
	is $blank->{runtime}{requires}{A}{comment}, undef, 'blank comment is still undef';
	# The trim was quadratic with a smaller constant, so it needs a longer run.
	my $run = ' ' x ($HOSTILE{bomb_depth} * 8);
	my $inner = within_time_limit(sub { App::makefilepl2cpanfile::parse_prereqs("PREREQ_PM => {\n'A' => 0, # a${run}b \n},") },
		'long whitespace run inside a comment');
	is $inner->{runtime}{requires}{A}{comment}, "a${run}b", 'inner whitespace kept, outer trimmed';

	within_time_limit(sub { App::makefilepl2cpanfile::parse_prereqs('recommends => {' x $HOSTILE{bomb_depth}) },
		'unclosed legacy blocks');
	within_time_limit(sub { App::makefilepl2cpanfile::parse_prereqs("PREREQ_PM => {" . ('{' x $HOSTILE{bomb_depth})) },
		'brace bomb');
	within_time_limit(sub { App::makefilepl2cpanfile::parse_prereqs(q{'} x $HOSTILE{bomb_depth} . "# PREREQ_PM => { 'X' => 0 }") },
		'quote bomb before a comment');

	my $long_name = 'A' x $HOSTILE{huge_name_len};
	my $long_ver  = '1' x $HOSTILE{huge_ver_len};
	my $big = within_time_limit(sub {
		App::makefilepl2cpanfile::parse_prereqs("PREREQ_PM => { '$long_name' => '$long_ver' },")
	}, 'huge name and version');
	is $big->{runtime}{requires}{$long_name}{version}, $long_ver, 'huge values preserved intact';
};

# -----------------------------------------------------------------------
# Context and $_ abuse
#
# Strategy: callers run library code inside loops where $_ is aliased to
# something read-only, or tied.  An unlocalised write to $_ would die with
# "Modification of a read-only value" or be recorded by the tie.
# -----------------------------------------------------------------------
{
	package Edge::TiedTopic;
	sub TIESCALAR { my ($class, $log) = @_; return bless { log => $log, value => 'topic' }, $class }
	sub FETCH { return $_[0]{value} }
	sub STORE { push @{ $_[0]{log} }, $_[1]; $_[0]{value} = $_[1]; return }
}

subtest 'context: $_ is never written, even when read-only or tied' => sub {
	my $g  = empty_home();
	my $mf = make_mf($MF_FULL_FOR_TOPIC);

	for (1) {
		lives_ok { App::makefilepl2cpanfile::generate(makefile => "$mf") } 'generate with read-only $_';
		lives_ok { App::makefilepl2cpanfile::parse_prereqs($MF_FULL_FOR_TOPIC) } 'parse_prereqs with read-only $_';
	}
	my @r = map { App::makefilepl2cpanfile::generate(makefile => "$mf") } 'constant';
	is scalar @r, 1, 'generate inside map over a constant: one result';

	my @stores;
	{
		local $_;
		tie $_, 'Edge::TiedTopic', \@stores;
		App::makefilepl2cpanfile::generate(makefile => "$mf", existing => $EXISTING_FOR_TOPIC);
		App::makefilepl2cpanfile::parse_prereqs($MF_FULL_FOR_TOPIC);
		untie $_;
	}
	is_deeply \@stores, [], 'no writes to a tied $_';

	# Scalar and list context give the same single value.
	my $scalar = App::makefilepl2cpanfile::generate(makefile => "$mf");
	my @list   = App::makefilepl2cpanfile::generate(makefile => "$mf");
	is_deeply \@list, [$scalar], 'list context returns exactly the scalar result';
	my @plist  = App::makefilepl2cpanfile::parse_prereqs($MF_FULL_FOR_TOPIC);
	is scalar @plist, 1, 'parse_prereqs in list context returns one hashref';
	returns_is($plist[0], { type => 'hashref' }, 'and it is a hashref');
};

done_testing();
