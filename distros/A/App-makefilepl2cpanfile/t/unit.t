use strict;
use warnings;

# Black-box tests for the public API: generate() and parse_prereqs().
# Every expectation below is taken from the POD (PURPOSE, ARGUMENTS,
# RETURNS, SIDE EFFECTS, API SPECIFICATION and MESSAGES), never from the
# implementation.  External collaborators (File::HomeDir, YAML::Tiny,
# Path::Tiny) are mocked only where needed to force a documented branch
# that cannot be reached reliably with real files.

use Test::Most;
use lib 't/lib';
use Test::Permissions qw(can_revoke_read);
use Test::Mockingbird;
use Test::Returns;
use File::Temp qw(tempdir);
use Path::Tiny;
use Readonly;
use YAML::Tiny;
use Errno qw(EINTR);

use App::makefilepl2cpanfile;

# -----------------------------------------------------------------------
# Constants taken from the POD
# -----------------------------------------------------------------------

Readonly my %CFG => (
	header          => '# Generated from Makefile.PL using makefilepl2cpanfile',
	default_mf      => 'Makefile.PL',
	cfg_dir         => '.config',
	cfg_file        => 'makefilepl2cpanfile.yml',
	comment_sep     => '   # ',
	phase_indent    => "\t",
	min_perl        => '5.010',
	sentinel_topic  => 'caller-owned topic',
	sentinel_evalerr=> 'caller-owned eval error',
	alarm_seconds   => 1000,	# far longer than the test runs
	utf8_error      => "Can't decode ill-formed UTF-8 octet sequence <FF>",
	io_error        => 'Input/output error',
	yaml_error      => 'synthetic YAML failure',
);

# An errno that no file operation in the module could plausibly set, so a
# match after the call proves $! was restored rather than coincidentally
# re-set (ENOENT, for example, is set by every failed stat).
Readonly my $SENTINEL_ERRNO => EINTR;

# Built-in develop tools listed under the with_develop argument.
Readonly my @DEFAULT_DEV_TOOLS => qw(Devel::Cover Perl::Critic Test::Pod Test::Pod::Coverage);

# Canonical order of the phase blocks, from RETURNS.
Readonly my @PHASE_ORDER => qw(configure build test develop);

# OUTPUT schema from generate()'s API SPECIFICATION.
Readonly my %GENERATE_OUTPUT => (
	type    => 'string',
	matches => qr/\A\Q$CFG{header}\E\n.*(?<!\n)\n\z/s,
);

# OUTPUT schema from parse_prereqs()'s API SPECIFICATION.
Readonly my %PARSE_OUTPUT => (type => 'hashref');

Readonly my $MF_SIMPLE => "WriteMakefile(PREREQ_PM => { 'Try::Tiny' => 0 });\n";

# -----------------------------------------------------------------------
# Ledger: every documented message and return state.  Each subtest calls
# covered() for what it proves; the final subtest fails for anything left.
# -----------------------------------------------------------------------

my %LEDGER = (
	# generate() MESSAGES
	'generate.msg.cannot_read.missing'      => q{croak "Cannot read '$makefile'" - missing file},
	'generate.msg.cannot_read.directory'    => q{croak "Cannot read '$makefile'" - directory},
	'generate.msg.cannot_read.unreadable'   => q{croak "Cannot read '$makefile'" - no read permission},
	'generate.msg.invalid_utf8'             => q{carp "Warning: '$makefile' contains invalid UTF-8; ..."},
	'generate.msg.io_error_rethrown'        => q{other read errors re-thrown unchanged},
	'generate.msg.failed_to_parse'          => q{croak "Failed to parse $cfg_file: $error"},
	'generate.msg.no_develop_key'           => q{carp "No 'develop' key found in $cfg_file; using defaults"},
	'generate.msg.invalid_module_name'      => q{carp "Skipping invalid module name in $cfg_file: '$module'"},
	'generate.msg.invalid_version'          => q{carp "Skipping invalid version for '$module' in $cfg_file: '$version'"},
	'generate.msg.invalid_existing_version' => q{carp "Ignoring invalid version for '$module' in existing cpanfile: '$version'"},

	# generate() ARGUMENTS
	'generate.arg.makefile_default'         => q{makefile defaults to 'Makefile.PL'},
	'generate.arg.existing_default'         => q{existing defaults to ''},
	'generate.arg.with_develop_default'     => q{with_develop defaults to true},
	'generate.arg.flat_list'                => q{arguments accepted as a flat list},
	'generate.arg.hashref'                  => q{arguments accepted as a single hashref},
	'generate.arg.content'                  => q{content is used instead of reading makefile},
	'read_makefile.ret.text'                => q{read_makefile returns the file text},
	'read_makefile.default'                 => q{read_makefile defaults to Makefile.PL},
	'read_makefile.msg.cannot_read'         => q{read_makefile croaks "Cannot read '$path'"},
	'read_makefile.msg.invalid_utf8'        => q{read_makefile warns on invalid UTF-8 and returns raw bytes},
	'generate.arg.existing.merge_all_rels'  => q{existing develop requires/recommends/suggests carried over},
	'generate.arg.existing.invalid_dropped' => q{existing develop entries with invalid names dropped},
	'generate.arg.existing.develop_only'    => q{only the develop block of existing is used},
	'generate.arg.with_develop.defaults'    => q{built-in develop tools added when no config},
	'generate.arg.with_develop.config'      => q{configured develop tools used instead of the defaults},
	'generate.arg.with_develop.no_home'     => q{built-in develop tools used when there is no home dir},
	'generate.arg.with_develop.false'       => q{with_develop false adds no develop tools},
	'generate.arg.with_develop.no_overwrite'=> q{listed develop tool never re-added or overwritten},

	# generate() RETURNS
	'generate.ret.schema'                   => q{Str matching the OUTPUT schema},
	'generate.ret.min_perl_line'            => q{requires 'perl' line when MIN_PERL_VERSION declared},
	'generate.ret.no_min_perl_line'         => q{no perl line when MIN_PERL_VERSION absent},
	'generate.ret.runtime_top_level'        => q{runtime at top level},
	'generate.ret.phase_blocks_ordered'     => q{other phases in on-blocks in canonical order},
	'generate.ret.rel_order_sorted'         => q{grouped requires/recommends/suggests, sorted},
	'generate.ret.inline_comment'           => q{inline comments reproduced},

	# generate() SIDE EFFECTS
	'generate.side.no_disk_writes'          => q{never writes to disk},
	'generate.side.globals_preserved'       => q{$@, $! and $_ unchanged},
	'generate.side.alarm_untouched'         => q{pending alarm() not disturbed},

	# parse_prereqs() ARGUMENTS
	'parse.arg.undef_or_ref'                => q{undef or reference treated as no dependencies},
	'parse.arg.simple_keys'                 => q{PREREQ_PM/BUILD/TEST/CONFIGURE_REQUIRES mapped},
	'parse.arg.structured'                  => q{prereqs => { phase => { rel => ... } } parsed},
	'parse.arg.structured_invalid_ignored'  => q{unknown phases/relationships ignored},
	'parse.arg.meta_merge'                  => q{prereqs under META_MERGE parsed},
	'parse.arg.legacy_recommends'           => q{top-level recommends mapped to runtime},
	'parse.arg.legacy_suggests'             => q{top-level suggests mapped to runtime},
	'parse.arg.legacy_scoped'               => q{recommends/suggests inside prereqs stay in their phase},
	'parse.arg.commented_skipped'           => q{commented-out lines skipped},
	'parse.arg.invalid_names_ignored'       => q{only quoted, valid package names used},
	'parse.arg.first_wins'                  => q{first occurrence wins},
	'parse.arg.simple_before_structured'    => q{simple keys read before prereqs blocks},

	# parse_prereqs() RETURNS
	'parse.ret.schema'                      => q{HashRef matching the OUTPUT schema},
	'parse.ret.absent_omitted'              => q{empty phases/relationships absent},
	'parse.ret.version_zero'                => q{version 0 when no minimum},
	'parse.ret.comment'                     => q{comment text captured, undef when none},

	# parse_prereqs() SIDE EFFECTS / MESSAGES
	'parse.side.no_warnings'                => q{no warnings - unrecognised content ignored},
	'parse.side.globals_preserved'          => q{$@, $! and $_ unchanged},
);

# Marks a ledger entry as proven.  An unknown key is a typo in the test and
# must fail loudly rather than silently leave the real entry uncovered.
sub covered {
	my $key = $_[0];
	if(exists $LEDGER{$key}) {
		delete $LEDGER{$key};
		diag "ledger: covered $key" if $ENV{TEST_VERBOSE};
	} else {
		fail("Unknown or already-covered ledger key '$key'");
	}
	return;
}

# -----------------------------------------------------------------------
# Fixture helpers
# -----------------------------------------------------------------------

# Points File::HomeDir at a fresh directory with no config file, so the
# developer's real ~/.config never leaks into a test.  Hold the guard.
sub empty_home {
	my $home = tempdir(CLEANUP => 1);
	return (mock_scoped('File::HomeDir::my_home' => sub { $home }), $home);
}

# As empty_home, plus a YAML config file containing $data.  Also returns the
# config path so message assertions can check it is named.
sub home_with_config {
	my $data = $_[0];
	my ($guard, $home) = empty_home();
	my $cfg = path($home)->child($CFG{cfg_dir}, $CFG{cfg_file});
	$cfg->parent->mkpath;
	YAML::Tiny->new($data)->write("$cfg");
	return ($guard, $cfg);
}

# Writes $content to a Makefile.PL in its own temp dir.
sub make_mf {
	my $content = $_[0];
	my $mf = path(tempdir(CLEANUP => 1))->child($CFG{default_mf});
	$mf->spew_utf8($content);
	return $mf;
}

# Runs $code and returns (result, warnings).
sub with_warnings {
	my $code = $_[0];
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	my $r = $code->();
	return ($r, @w);
}

# Runs $code with sentinel values in $@, $! and $_ and checks all three
# survive.  Callers commonly check $@ or $! after other work, or call
# library code inside map/grep, so clobbering any of them is a bug.
sub globals_preserved {
	my ($code, $name) = @_;
	local $_ = $CFG{sentinel_topic};
	local $@ = $CFG{sentinel_evalerr};
	local $! = $SENTINEL_ERRNO;
	my $errno_text = "$!";
	$code->();
	my $ok = is($_, $CFG{sentinel_topic}, "$name: \$_ preserved");
	$ok = is($@, $CFG{sentinel_evalerr}, "$name: \$\@ preserved") && $ok;
	$ok = is(0 + $!, $SENTINEL_ERRNO, "$name: \$! preserved ($errno_text)") && $ok;
	return $ok;
}

# -----------------------------------------------------------------------
# generate() - MESSAGES
# -----------------------------------------------------------------------

# Strategy: each documented croak for an unusable path, with the exact
# message naming the path the caller passed.
subtest 'generate() - "Cannot read" croak for every unusable path' => sub {
	my ($g) = empty_home();

	my $missing = path(tempdir(CLEANUP => 1))->child('absent', $CFG{default_mf});
	throws_ok { App::makefilepl2cpanfile::generate(makefile => "$missing") }
		qr/\ACannot read '\Q$missing\E' at /, 'missing file';
	covered('generate.msg.cannot_read.missing');

	my $dir = tempdir(CLEANUP => 1);
	throws_ok { App::makefilepl2cpanfile::generate(makefile => $dir) }
		qr/\ACannot read '\Q$dir\E' at /, 'directory';
	covered('generate.msg.cannot_read.directory');

	SKIP: {
		skip 'chmod cannot make a file unreadable here (root or Windows)', 1 unless can_revoke_read();
		my $locked = make_mf($MF_SIMPLE);
		chmod 0, "$locked";
		throws_ok { App::makefilepl2cpanfile::generate(makefile => "$locked") }
			qr/\ACannot read '\Q$locked\E' at /, 'unreadable file';
		chmod 0600, "$locked";
	}
	covered('generate.msg.cannot_read.unreadable');
};

# Strategy: Path::Tiny only dies on bad UTF-8 in some configurations, so the
# decode error is forced with a mock.  The documented behaviour is a warning
# followed by normal processing of the raw bytes.
subtest 'generate() - invalid UTF-8 warns and falls back to raw bytes' => sub {
	my ($g_home) = empty_home();
	my $mf = make_mf($MF_SIMPLE);
	my $g = mock_scoped(
		'Path::Tiny::slurp_utf8' => sub { die "$CFG{utf8_error}\n" },
		'Path::Tiny::slurp_raw'  => sub { "WriteMakefile(PREREQ_PM => { 'Raw::Mod' => 0 });\n" },
	);

	my ($out, @w) = with_warnings(sub {
		App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 0)
	});
	is scalar @w, 1, 'exactly one warning';
	like $w[0],
		qr/\AWarning: '\Q$mf\E' contains invalid UTF-8; reading as raw bytes: \Q$CFG{utf8_error}\E/,
		'warning text as documented';
	like $out, qr/^requires 'Raw::Mod';$/m, 'processing continues with the raw bytes';
	covered('generate.msg.invalid_utf8');
};

# Strategy: a non-encoding read failure must reach the caller unchanged,
# not be converted into a warning.
subtest 'generate() - genuine I/O errors are re-thrown' => sub {
	my ($g_home) = empty_home();
	my $mf = make_mf($MF_SIMPLE);
	my $g = mock_scoped 'Path::Tiny::slurp_utf8' => sub { die "$CFG{io_error}\n" };

	my ($r, @w) = with_warnings(sub {
		throws_ok { App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 0) }
			qr/\A\Q$CFG{io_error}\E\n\z/, 'error propagates unchanged';
	});
	is scalar @w, 0, 'no fallback warning';
	covered('generate.msg.io_error_rethrown');
};

# Strategy: YAML::Tiny accepts much malformed input, so a parse failure is
# forced with a mock; the croak must name the config file and the error.
subtest 'generate() - "Failed to parse" croak for bad config' => sub {
	my ($g_home, $cfg) = home_with_config({});
	my $g_yaml = mock_scoped(
		'YAML::Tiny::read'   => sub { undef },
		'YAML::Tiny::errstr' => sub { $CFG{yaml_error} },
	);
	my $mf = make_mf($MF_SIMPLE);

	throws_ok { App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 1) }
		qr/\AFailed to parse \Q$cfg\E: \Q$CFG{yaml_error}\E at /, 'croak text as documented';

	# The config is only consulted for develop tools; without them a broken
	# config must not stop generation.
	lives_ok { App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 0) }
		'config not read when with_develop is false';
	covered('generate.msg.failed_to_parse');
};

subtest q{generate() - "No 'develop' key" warning uses the defaults} => sub {
	my ($g, $cfg) = home_with_config({ other_section => { tool => 1 } });
	my $mf = make_mf($MF_SIMPLE);

	my ($out, @w) = with_warnings(sub {
		App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 1)
	});
	is scalar @w, 1, 'exactly one warning';
	like $w[0], qr/\ANo 'develop' key found in \Q$cfg\E; using defaults at /,
		'warning text as documented';
	like $out, qr/^\trequires '\Q$_\E';$/m, "default tool $_ used" for @DEFAULT_DEV_TOOLS;
	covered('generate.msg.no_develop_key');
};

# Strategy: the two security warnings.  A hostile key must never reach the
# output; a hostile version must be replaced by "no minimum".
subtest 'generate() - invalid config entries are rejected with a warning' => sub {
	my $evil_mod = q{Evil'; system('id'); requires 'X};
	my $evil_ver = q{1'; system('id'); '};
	my ($g, $cfg) = home_with_config({ develop => {
		$evil_mod    => 0,
		'Odd::Ver'   => $evil_ver,
		'Good::Tool' => '1.5',
	} });
	my $mf = make_mf($MF_SIMPLE);

	my ($out, @w) = with_warnings(sub {
		App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 1)
	});
	is scalar @w, 2, 'one warning per invalid entry';

	my ($mod_w) = grep { /module name/ } @w;
	like $mod_w, qr/\ASkipping invalid module name in \Q$cfg\E: '\Q$evil_mod\E' at /,
		'invalid module name warning text as documented';
	unlike $out, qr/system/, 'hostile module name absent from the output';
	covered('generate.msg.invalid_module_name');

	my ($ver_w) = grep { /invalid version/ } @w;
	like $ver_w, qr/\ASkipping invalid version for 'Odd::Ver' in \Q$cfg\E: '\Q$evil_ver\E' at /,
		'invalid version warning text as documented';
	like $out, qr/^\trequires 'Odd::Ver';$/m, 'module kept with no minimum version';
	like $out, qr/^\trequires 'Good::Tool', '1\.5';$/m, 'valid entry unaffected';
	covered('generate.msg.invalid_version');
};

# Strategy: a develop entry in the existing cpanfile whose version is not a
# version number must be kept without a version, with the documented warning.
subtest 'generate() - invalid version in existing cpanfile is dropped with a warning' => sub {
	my ($g) = empty_home();
	my $mf = make_mf($MF_SIMPLE);
	my $bad = q{1.0\\};
	my $existing = "on 'develop' => sub {\n\trequires 'Pinned::Tool', '$bad';\n};\n";

	my ($out, @w) = with_warnings(sub {
		App::makefilepl2cpanfile::generate(makefile => "$mf", existing => $existing, with_develop => 0)
	});
	is scalar @w, 1, 'exactly one warning';
	like $w[0],
		qr/\AIgnoring invalid version for 'Pinned::Tool' in existing cpanfile: '\Q$bad\E' at /,
		'warning text as documented';
	like $out, qr/^\trequires 'Pinned::Tool';$/m, 'entry kept with no minimum version';
	covered('generate.msg.invalid_existing_version');
};

# -----------------------------------------------------------------------
# generate() - ARGUMENTS
# -----------------------------------------------------------------------

subtest 'generate() - argument defaults' => sub {
	my ($g) = empty_home();

	# makefile: relative 'Makefile.PL' resolved against the working directory.
	{
		my $mf  = make_mf($MF_SIMPLE);
		my $cwd = Path::Tiny->cwd;
		chdir $mf->parent or die "chdir: $!";
		my $out = eval { App::makefilepl2cpanfile::generate(with_develop => 0) };
		my $err = $@;
		chdir $cwd or die "chdir: $!";
		is $err, q{}, 'no makefile argument does not croak';
		like $out, qr/^requires 'Try::Tiny';$/m, './Makefile.PL was read';
		covered('generate.arg.makefile_default');
	}

	my $mf = make_mf($MF_SIMPLE);

	# existing: omitting it must be identical to passing ''.
	is App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 0),
		App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 0, existing => q{}),
		q{omitted existing behaves as ''};
	covered('generate.arg.existing_default');

	# with_develop: omitting it must be identical to passing a true value.
	is App::makefilepl2cpanfile::generate(makefile => "$mf"),
		App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 1),
		'omitted with_develop behaves as true';
	covered('generate.arg.with_develop_default');
};

# Strategy: read_makefile() is the reading step of generate(), exposed so
# that one read can feed several calls; content => is the matching input.
subtest 'read_makefile() and generate(content => ...)' => sub {
	my ($g) = empty_home();
	my $mf = make_mf($MF_SIMPLE);

	my $text = App::makefilepl2cpanfile::read_makefile("$mf");
	is $text, $MF_SIMPLE, 'returns the file text';
	returns_is($text, { type => 'string' }, 'returns a string');
	covered('read_makefile.ret.text');

	{
		my $cwd = Path::Tiny->cwd;
		chdir $mf->parent or die "chdir: $!";
		my $default = eval { App::makefilepl2cpanfile::read_makefile() };
		chdir $cwd or die "chdir: $!";
		is $default, $MF_SIMPLE, 'no argument reads ./Makefile.PL';
		covered('read_makefile.default');
	}

	throws_ok { App::makefilepl2cpanfile::read_makefile('/no/such/Makefile.PL') }
		qr/\ACannot read '\/no\/such\/Makefile\.PL' at /, 'documented croak';
	covered('read_makefile.msg.cannot_read');

	{
		my $m = mock_scoped(
			'Path::Tiny::slurp_utf8' => sub { die "$CFG{utf8_error}\n" },
			'Path::Tiny::slurp_raw'  => sub { 'raw bytes' },
		);
		my ($raw, @w) = with_warnings(sub { App::makefilepl2cpanfile::read_makefile("$mf") });
		is $raw, 'raw bytes', 'raw bytes returned';
		like $w[0], qr/\AWarning: '\Q$mf\E' contains invalid UTF-8; reading as raw bytes: /, 'documented warning';
		covered('read_makefile.msg.invalid_utf8');
	}

	# content => is used as is: the makefile argument is then not read at all.
	is App::makefilepl2cpanfile::generate(content => $text, makefile => '/no/such/file', with_develop => 0),
		App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 0),
		'content gives the same result as reading the file, and makefile is ignored';
	covered('generate.arg.content');
};

subtest 'generate() - flat-list and hashref calling styles are equivalent' => sub {
	my ($g) = empty_home();
	my $mf = make_mf($MF_SIMPLE);
	my %args = (makefile => "$mf", with_develop => 0);

	my $flat = App::makefilepl2cpanfile::generate(%args);
	like $flat, qr/^requires 'Try::Tiny';$/m, 'flat list accepted';
	covered('generate.arg.flat_list');

	is App::makefilepl2cpanfile::generate(\%args), $flat, 'hashref gives identical output';
	covered('generate.arg.hashref');
};

# Strategy: an existing cpanfile with entries in every relationship, runtime
# entries outside the develop block, and an invalid name.
subtest 'generate() - existing cpanfile develop block' => sub {
	my ($g) = empty_home();
	my $mf = make_mf($MF_SIMPLE);
	my $existing = <<'END_CPANFILE';
requires 'Outside::Develop';

on 'develop' => sub {
	requires 'Dev::Req', '2.5';
	recommends 'Dev::Rec';
	suggests 'Dev::Sug';
	requires 'Not A Package';
};
END_CPANFILE

	my $out = App::makefilepl2cpanfile::generate(
		makefile => "$mf", existing => $existing, with_develop => 0,
	);
	like $out, qr/^\trequires 'Dev::Req', '2\.5';$/m, 'requires carried over with version';
	like $out, qr/^\trecommends 'Dev::Rec';$/m,       'recommends carried over';
	like $out, qr/^\tsuggests 'Dev::Sug';$/m,         'suggests carried over';
	covered('generate.arg.existing.merge_all_rels');

	unlike $out, qr/Not A Package/, 'invalid module name dropped';
	covered('generate.arg.existing.invalid_dropped');

	unlike $out, qr/Outside::Develop/, 'entries outside the develop block ignored';
	covered('generate.arg.existing.develop_only');
};

subtest 'generate() - with_develop sources of develop tools' => sub {
	my $mf = make_mf($MF_SIMPLE);

	# No config file: exactly the built-in tools, as requires, no version.
	{
		my ($g) = empty_home();
		my $out = App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 1);
		my @tools = $out =~ /^\trequires '([^']+)';$/mg;
		is_deeply \@tools, [@DEFAULT_DEV_TOOLS], 'built-in tools added as requires';
		covered('generate.arg.with_develop.defaults');
	}

	# A config file replaces the built-in list entirely.
	{
		my ($g) = home_with_config({ develop => { 'My::Tool' => '1.00' } });
		my $out = App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 1);
		like   $out, qr/^\trequires 'My::Tool', '1\.00';$/m, 'configured tool added';
		unlike $out, qr/Perl::Critic/, 'built-in tools not added alongside';
		covered('generate.arg.with_develop.config');
	}

	# Containers and chroots may have no home directory at all.
	{
		my $g = mock_scoped 'File::HomeDir::my_home' => sub { undef };
		my $out;
		lives_ok { $out = App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 1) }
			'no home directory does not croak';
		like $out, qr/^\trequires 'Perl::Critic';$/m, 'built-in tools used';
		covered('generate.arg.with_develop.no_home');
	}

	# False: no develop phase at all for this Makefile.PL.
	{
		my ($g) = empty_home();
		my $out = App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 0);
		unlike $out, qr/on 'develop'/, 'no develop block';
		covered('generate.arg.with_develop.false');
	}
};

# Strategy: a tool already listed in the develop phase, from the existing
# cpanfile and from the Makefile.PL under a non-requires relationship, must
# be left exactly as listed.
subtest 'generate() - listed develop tools are never re-added or overwritten' => sub {
	my ($g) = empty_home();
	my $mf = make_mf(<<'END_MF');
WriteMakefile(
	PREREQ_PM => { 'Try::Tiny' => 0 },
	META_MERGE => { prereqs => { develop => { recommends => { 'Test::Pod' => '1.52' } } } },
);
END_MF
	my $existing = "on 'develop' => sub {\n\trequires 'Perl::Critic', '1.140';\n};\n";

	my $out = App::makefilepl2cpanfile::generate(
		makefile => "$mf", existing => $existing, with_develop => 1,
	);
	my @critic = $out =~ /Perl::Critic/g;
	my @pod    = $out =~ /'Test::Pod'/g;
	is scalar @critic, 1, 'Perl::Critic listed once';
	is scalar @pod,    1, 'Test::Pod listed once';
	like $out, qr/^\trequires 'Perl::Critic', '1\.140';$/m, 'existing version kept';
	like $out, qr/^\trecommends 'Test::Pod', '1\.52';$/m,   'Makefile.PL relationship kept';
	covered('generate.arg.with_develop.no_overwrite');
};

# -----------------------------------------------------------------------
# generate() - RETURNS
# -----------------------------------------------------------------------

# Strategy: one Makefile.PL that populates every phase and relationship,
# compared with the complete expected text so that layout, ordering,
# sorting and comments are all pinned by a single assertion.
subtest 'generate() - output layout' => sub {
	my ($g) = empty_home();
	my $mf = make_mf(<<'END_MF');
WriteMakefile(
	MIN_PERL_VERSION => '5.010',
	PREREQ_PM => {
		'Zeta'  => 0,
		'Alpha' => '1.5',	# first alphabetically
	},
	TEST_REQUIRES      => { 'Test::More' => 0 },
	BUILD_REQUIRES     => { 'Build::Thing' => 0 },
	CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => '6.64' },
	META_MERGE => {
		prereqs => { runtime => { suggests => { 'Sug::Mod' => 0 } } },
		recommends => { 'Rec::Mod' => 0 },
	},
);
END_MF

	my $out = App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 0);
	diag "generate() output:\n$out" if $ENV{TEST_VERBOSE};

	is $out, join(q{},
		"$CFG{header}\n",
		"\n",
		"requires 'perl', '$CFG{min_perl}';\n",
		"\n",
		"requires 'Alpha', '1.5';$CFG{comment_sep}first alphabetically\n",
		"requires 'Zeta';\n",
		"recommends 'Rec::Mod';\n",
		"suggests 'Sug::Mod';\n",
		"\n",
		"on 'configure' => sub {\n$CFG{phase_indent}requires 'ExtUtils::MakeMaker', '6.64';\n};\n",
		"\n",
		"on 'build' => sub {\n$CFG{phase_indent}requires 'Build::Thing';\n};\n",
		"\n",
		"on 'test' => sub {\n$CFG{phase_indent}requires 'Test::More';\n};\n",
	), 'complete output matches the documented layout';
	covered('generate.ret.min_perl_line');
	covered('generate.ret.runtime_top_level');
	covered('generate.ret.rel_order_sorted');
	covered('generate.ret.inline_comment');

	returns_is($out, \%GENERATE_OUTPUT, 'output satisfies the OUTPUT schema');
	covered('generate.ret.schema');

	# The develop block (from with_develop) must come last.
	my $with_dev = App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 1);
	is_deeply [ $with_dev =~ /^on '(\w+)'/mg ], [@PHASE_ORDER], 'phase blocks in canonical order';
	covered('generate.ret.phase_blocks_ordered');

	$mf->spew_utf8($MF_SIMPLE);
	unlike App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 0),
		qr/'perl'/, 'no perl line without MIN_PERL_VERSION';
	covered('generate.ret.no_min_perl_line');
};

# -----------------------------------------------------------------------
# generate() - SIDE EFFECTS
# -----------------------------------------------------------------------

subtest 'generate() - side effects' => sub {
	my ($g, $home) = empty_home();
	my $mf  = make_mf($MF_SIMPLE);
	my $dir = $mf->parent;

	# Snapshot every file the call could plausibly touch.
	my $snapshot = sub {
		return [ sort map { "$_" } $dir->children, path($home)->children ];
	};
	my $before = $snapshot->();
	App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 1);
	is_deeply $snapshot->(), $before, 'no files created or removed';
	covered('generate.side.no_disk_writes');

	my $ok = globals_preserved(
		sub { App::makefilepl2cpanfile::generate(makefile => "$mf", with_develop => 1) },
		'generate success');
	# The error paths must be just as careful: a caller who catches the
	# croak with Try::Tiny still expects $_ to be intact.
	{
		my ($g2) = home_with_config({ other => 1 });
		$ok = globals_preserved(sub {
			with_warnings(sub { App::makefilepl2cpanfile::generate(makefile => "$mf") });
		}, 'generate warning path') && $ok;
	}
	covered('generate.side.globals_preserved') if $ok;

	# A caller's pending alarm must be neither cancelled nor reset.
	SKIP: {
		skip 'alarm() not available', 1 if $^O eq 'MSWin32';
		local $SIG{ALRM} = sub { die "alarm fired\n" };
		alarm $CFG{alarm_seconds};
		App::makefilepl2cpanfile::generate(makefile => "$mf");
		my $remaining = alarm 0;
		ok $remaining > 0 && $remaining <= $CFG{alarm_seconds}, "pending alarm intact ($remaining s left)";
	}
	covered('generate.side.alarm_untouched');
};

# -----------------------------------------------------------------------
# parse_prereqs() - ARGUMENTS
# -----------------------------------------------------------------------

subtest 'parse_prereqs() - undef and references mean no dependencies' => sub {
	for my $case ([undef, 'undef'], [[], 'arrayref'], [{}, 'hashref'], [\q{x}, 'scalar ref']) {
		my ($r, @w) = with_warnings(sub { App::makefilepl2cpanfile::parse_prereqs($case->[0]) });
		is_deeply $r, {}, "$case->[1] gives an empty hashref";
		is scalar @w, 0, "$case->[1] raises no warnings";
	}
	covered('parse.arg.undef_or_ref');
};

subtest 'parse_prereqs() - simple keys map to their phases' => sub {
	my $d = App::makefilepl2cpanfile::parse_prereqs(<<'END_MF');
WriteMakefile(
	PREREQ_PM          => { 'Runtime::Dep'   => '1.00' },
	BUILD_REQUIRES     => { 'Build::Dep'     => 0 },
	TEST_REQUIRES      => { 'Test::Dep'      => 0 },
	CONFIGURE_REQUIRES => { 'Configure::Dep' => '6.64' },
);
END_MF
	is_deeply $d, {
		runtime   => { requires => { 'Runtime::Dep'   => { version => '1.00', comment => undef } } },
		build     => { requires => { 'Build::Dep'     => { version => 0,      comment => undef } } },
		test      => { requires => { 'Test::Dep'      => { version => 0,      comment => undef } } },
		configure => { requires => { 'Configure::Dep' => { version => '6.64', comment => undef } } },
	}, 'each key maps to the documented phase under requires';
	covered('parse.arg.simple_keys');
};

subtest 'parse_prereqs() - structured prereqs blocks' => sub {
	my $d = App::makefilepl2cpanfile::parse_prereqs(<<'END_MF');
prereqs => {
	runtime => {
		requires   => { 'Struct::Req' => '2.00' },
		recommends => { 'Struct::Rec' => '0.50' },
		suggests   => { 'Struct::Sug' => 0 },
		optional   => { 'Not::A::Rel' => 0 },
	},
	bogus_phase => { requires => { 'Not::A::Phase' => 0 } },
},
END_MF
	is_deeply $d, { runtime => {
		requires   => { 'Struct::Req' => { version => '2.00', comment => undef } },
		recommends => { 'Struct::Rec' => { version => '0.50', comment => undef } },
		suggests   => { 'Struct::Sug' => { version => 0,      comment => undef } },
	} }, 'every documented relationship parsed';
	covered('parse.arg.structured');
	covered('parse.arg.structured_invalid_ignored');

	my $mm = App::makefilepl2cpanfile::parse_prereqs(
		"META_MERGE => { prereqs => { test => { requires => { 'Meta::Dep' => '1.00' } } } },"
	);
	is_deeply $mm, { test => { requires => { 'Meta::Dep' => { version => '1.00', comment => undef } } } },
		'prereqs nested under META_MERGE parsed';
	covered('parse.arg.meta_merge');
};

# Strategy: the Database-Abstraction style layout that motivated this
# feature - recommends/suggests directly under META_MERGE - alongside a
# phase-scoped block that must not leak into runtime.
subtest 'parse_prereqs() - legacy top-level recommends and suggests' => sub {
	my $d = App::makefilepl2cpanfile::parse_prereqs(<<'END_MF');
WriteMakefile(
	META_MERGE => {
		'meta-spec' => { version => 2 },
		recommends => {
			# Optional runtime backends
			'JSON::MaybeXS' => 0,		# JSON backend
		},
		'suggests' => { 'YAML::XS' => '0.88' },
		prereqs => { test => {
			recommends => { 'Test::Deep' => 0 },
			suggests   => { 'Test::Differences' => 0 },
		} },
	},
);
END_MF
	is_deeply $d->{runtime}{recommends},
		{ 'JSON::MaybeXS' => { version => 0, comment => 'JSON backend' } },
		'top-level recommends mapped to runtime';
	covered('parse.arg.legacy_recommends');

	is_deeply $d->{runtime}{suggests},
		{ 'YAML::XS' => { version => '0.88', comment => undef } },
		'top-level (quoted) suggests mapped to runtime';
	covered('parse.arg.legacy_suggests');

	is_deeply $d->{test}, {
		recommends => { 'Test::Deep'        => { version => 0, comment => undef } },
		suggests   => { 'Test::Differences' => { version => 0, comment => undef } },
	}, 'phase-scoped entries stay in their phase';
	is_deeply [ sort keys %{ $d->{runtime} } ], [qw(recommends suggests)],
		'and do not leak into runtime';
	covered('parse.arg.legacy_scoped');
};

subtest 'parse_prereqs() - which entries are used' => sub {
	my $d = App::makefilepl2cpanfile::parse_prereqs(<<'END_MF');
PREREQ_PM => {
	# 'Commented::Out' => 0,
	'Kept' => 0,
	Bareword => 0,
	'1Bad::Name' => 0,
	'Has Space' => 0,
},
END_MF
	is_deeply [ keys %{ $d->{runtime}{requires} } ], ['Kept'],
		'only the quoted, valid, uncommented entry is used';
	covered('parse.arg.commented_skipped');
	covered('parse.arg.invalid_names_ignored');

	my $dup = App::makefilepl2cpanfile::parse_prereqs(
		"PREREQ_PM => {\n\t'Dup' => '1.00',\n\t'Dup' => '2.00',\n},"
	);
	is $dup->{runtime}{requires}{'Dup'}{version}, '1.00', 'first occurrence wins';
	covered('parse.arg.first_wins');

	# prereqs appears first in the text, but the simple key is still read first.
	my $order = App::makefilepl2cpanfile::parse_prereqs(<<'END_MF');
prereqs   => { runtime => { requires => { 'Both' => '2.00' } } },
PREREQ_PM => { 'Both' => '1.00' },
END_MF
	is $order->{runtime}{requires}{'Both'}{version}, '1.00',
		'simple key wins over a prereqs block regardless of position';
	covered('parse.arg.simple_before_structured');
};

# -----------------------------------------------------------------------
# parse_prereqs() - RETURNS, SIDE EFFECTS and MESSAGES
# -----------------------------------------------------------------------

subtest 'parse_prereqs() - return value' => sub {
	my $d = App::makefilepl2cpanfile::parse_prereqs(
		"PREREQ_PM => {\n\t'No::Min' => 0,\n\t'Noted' => '1.2',   # used only on POSIX\n},"
	);
	returns_is($d, \%PARSE_OUTPUT, 'result satisfies the OUTPUT schema');
	returns_is(App::makefilepl2cpanfile::parse_prereqs(q{}), \%PARSE_OUTPUT,
		'empty input also satisfies the OUTPUT schema');
	covered('parse.ret.schema');

	is_deeply [ keys %{$d} ], ['runtime'], 'only populated phases present';
	is_deeply [ keys %{ $d->{runtime} } ], ['requires'], 'only populated relationships present';
	is_deeply App::makefilepl2cpanfile::parse_prereqs("PREREQ_PM => { },"), {},
		'an empty hash creates no phase';
	covered('parse.ret.absent_omitted');

	is $d->{runtime}{requires}{'No::Min'}{version}, 0, 'version 0 when no minimum';
	covered('parse.ret.version_zero');

	is $d->{runtime}{requires}{'Noted'}{comment}, 'used only on POSIX', 'comment captured';
	is $d->{runtime}{requires}{'No::Min'}{comment}, undef, 'comment undef when none';
	covered('parse.ret.comment');
};

subtest 'parse_prereqs() - no warnings and no global side effects' => sub {
	my ($r, @w) = with_warnings(sub {
		App::makefilepl2cpanfile::parse_prereqs("random text !!!\@\@\@### { } }{ =>\n\x{263A}")
	});
	is_deeply $r, {}, 'unrecognised content ignored';
	is scalar @w, 0, 'no warnings';
	covered('parse.side.no_warnings');

	globals_preserved(sub { App::makefilepl2cpanfile::parse_prereqs($MF_SIMPLE) }, 'parse_prereqs')
		and covered('parse.side.globals_preserved');
};

# -----------------------------------------------------------------------
# Ledger: every documented state must have been exercised above.
# -----------------------------------------------------------------------

subtest 'API ledger - every documented state was exercised' => sub {
	if(%LEDGER) {
		fail("Untested documented state: $_ - $LEDGER{$_}") for sort keys %LEDGER;
	} else {
		pass('all documented messages and return states covered');
	}
};

done_testing;
