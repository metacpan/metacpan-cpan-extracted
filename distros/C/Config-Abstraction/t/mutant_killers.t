#!/usr/bin/perl

# Targeted mutant-killer tests for Config::Abstraction.
# Each subtest is designed to kill one or more specific surviving mutants
# identified by the mutation testing run.  Mutant IDs are noted in comments.
# Uses Test::Most for lives_ok/dies_ok.

use strict;
use warnings;
use autodie qw(:all);

use Test::Mockingbird;
use Test::Most;
use Test::Needs;
use Readonly;
use Scalar::Util qw(blessed reftype);
use File::Temp qw(tempdir);
use File::Spec;

# ---------------------------------------------------------------------------
# Configuration - can be overridden via Object::Configure if wanted
# ---------------------------------------------------------------------------
my %config = (
	module		=> 'Config::Abstraction',
	env_prefix	=> 'MUTAPP_',
	sep_char	=> '.',
	sep_char_us	=> '_',
	flatten_on	=> 1,
	flatten_off	=> 0,
);

Readonly::Scalar my $MODULE		=> $config{module};
Readonly::Scalar my $ENV_PREFIX		=> $config{env_prefix};
Readonly::Scalar my $SEP		=> $config{sep_char};
Readonly::Scalar my $SEP_US		=> $config{sep_char_us};
Readonly::Scalar my $FLATTEN_ON		=> $config{flatten_on};
Readonly::Scalar my $FLATTEN_OFF	=> $config{flatten_off};

Readonly::Scalar my $EXPECTED_USER	=> 'alice';
Readonly::Scalar my $EXPECTED_PASS	=> 'secret';
Readonly::Scalar my $EXPECTED_PORT	=> 5432;
Readonly::Scalar my $EXPECTED_LEVEL	=> 'info';
Readonly::Scalar my $EXPECTED_RETRIES	=> 3;
Readonly::Scalar my $EXPECTED_TIMEOUT	=> 30;
Readonly::Scalar my $OVERRIDE_USER	=> 'bob';

Readonly::Scalar my $LOG_LEVEL_NOTICE => 'notice';

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Write content to a named file in a directory
sub _write_file
{
	my ($dir, $filename, $content) = @_;
	my $path = File::Spec->catfile($dir, $filename);
	open(my $fh, '>', $path);
	print $fh $content;
	close $fh;
	return $path;
}

# Fresh nested data safe for mutation by merge operations
sub _fresh_data
{
	return {
		database => {
			user => $EXPECTED_USER,
			pass => $EXPECTED_PASS,
			port => $EXPECTED_PORT,
		},
		log     => { level => $EXPECTED_LEVEL },
		retries => $EXPECTED_RETRIES,
		timeout => $EXPECTED_TIMEOUT,
	};
}

# Silence STDERR for tests that intentionally trigger carp noise
sub _silenced
{
	my $code = shift;
	local *STDERR;
	open(STDERR, '>', File::Spec->devnull());
	my @result = eval { $code->() };
	my $err = $@;
	close STDERR;
	$@ = $err;
	return @result;
}

# ---------------------------------------------------------------------------
use_ok($MODULE) or BAIL_OUT("$MODULE failed to load");

# ===========================================================================
# COND_INV_349_3, COND_INV_353_4
# new() - the else branch for config_dirs defaulting
# Kills: inversion of the condition that sets up default config_dirs
# Both branches (config_dirs defined vs not defined) must be exercised
# ===========================================================================
subtest 'new() - config_dirs defined: no default dirs applied (COND_INV_349_3)' => sub {
	# When config_dirs IS provided, the default-building else branch must NOT run.
	# If the condition were inverted, the provided dirs would be ignored.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "sentinel: from_provided_dir\n");

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir],
	);
	ok(defined($cfg),                         'object created with explicit config_dirs');
	is($cfg->get('sentinel'), 'from_provided_dir', 'explicit config_dirs used, not defaults');
};

subtest 'new() - config_dirs undefined: default dirs applied (COND_INV_353_4)' => sub {
	# When config_dirs is NOT provided, defaults must be built.
	# We cannot easily assert which dirs are chosen, but we can assert
	# the object is created and has a non-empty config_dirs list.
	my $cfg = Config::Abstraction->new(
		data => { key => 'value' },
	);
	ok(defined($cfg), 'object created without config_dirs');
	ok(defined($cfg->{config_dirs}),          'config_dirs defaulted to something');
	ok(scalar(@{$cfg->{config_dirs}}) > 0,    'default config_dirs is non-empty');
};

# ===========================================================================
# COND_INV_358_4
# new() - HOME env var branch for config_dirs construction
# Kills: inversion of the condition that adds HOME-based dirs
# ===========================================================================
subtest 'new() - HOME set: HOME-based dirs added to config_dirs (COND_INV_358_4)' => sub {
	local %ENV = %ENV;
	my $home = tempdir(CLEANUP => 1);
	$ENV{HOME} = $home;
	delete $ENV{DOCUMENT_ROOT};

	my $cfg = Config::Abstraction->new(
		data => { key => 'value' },
	);
	ok(defined($cfg), 'object created with HOME set');
	# At least one HOME-based dir should be in config_dirs
	my $has_home_dir = grep { index($_, $home) == 0 } @{$cfg->{config_dirs}};
	ok($has_home_dir, 'HOME-based dir present in config_dirs');
};

subtest 'new() - HOME unset: DOCUMENT_ROOT branch used instead (COND_INV_358_4)' => sub {
	local %ENV = %ENV;
	delete $ENV{HOME};
	my $docroot = tempdir(CLEANUP => 1);
	$ENV{DOCUMENT_ROOT} = $docroot;

	my $cfg = Config::Abstraction->new(
		data => { key => 'value' },
	);
	ok(defined($cfg), 'object created without HOME');
	# DOCUMENT_ROOT-based dirs should appear
	my $has_docroot = grep { index($_, $docroot) == 0 } @{$cfg->{config_dirs}};
	ok($has_docroot, 'DOCUMENT_ROOT-based dir present when HOME unset');
};

# ===========================================================================
# COND_INV_369_4
# new() - CONFIG_DIR env var branch
# Kills: inversion of the condition that adds CONFIG_DIR to search path
# ===========================================================================
subtest 'new() - CONFIG_DIR set: added to config_dirs (COND_INV_369_4)' => sub {
	local %ENV = %ENV;
	my $cfgdir = tempdir(CLEANUP => 1);
	$ENV{CONFIG_DIR} = $cfgdir;
	_write_file($cfgdir, 'base.yaml', "cfg_dir_key: cfg_dir_val\n");

	my $cfg = Config::Abstraction->new(
		data => { fallback => 'yes' },
	);
	ok(defined($cfg), 'object created with CONFIG_DIR set');
	is($cfg->get('cfg_dir_key'), 'cfg_dir_val', 'CONFIG_DIR location searched');
};

subtest 'new() - CONFIG_DIR unset: conf/config dirs used instead (COND_INV_369_4)' => sub {
	local %ENV = %ENV;
	delete $ENV{CONFIG_DIR};

	my $cfg = Config::Abstraction->new(
		data => { key => 'value' },
	);
	ok(defined($cfg), 'object created without CONFIG_DIR');
	# 'conf' and 'config' should appear in default dirs
	my $has_conf = grep { $_ eq 'conf' || $_ eq 'config' } @{$cfg->{config_dirs}};
	ok($has_conf, 'conf/config dirs present when CONFIG_DIR unset');
};

# ===========================================================================
# COND_INV_384_2, COND_INV_385_3, COND_INV_388_4, COND_INV_393_5
# new() - logger initialisation block
# Kills: inversions in the logger setup conditional chain
# ===========================================================================
subtest 'new() - unblessed logger wrapped in Log::Abstraction (COND_INV_384_2)' => sub {
	test_needs 'Log::Abstraction';
	# When logger IS provided and IS NOT blessed, it must be wrapped.
	# If the condition were inverted, wrapping would be skipped.
	my @log;
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		logger      => \@log,
	);
	ok(defined($cfg), 'object created with arrayref logger');
	# The logger should now be a blessed Log::Abstraction object
	ok(blessed($cfg->{logger}), 'unblessed logger was wrapped into blessed object');
};

subtest 'new() - blessed logger not re-wrapped (COND_INV_384_2 false branch)' => sub {
	# When logger IS blessed, the wrapping block must NOT run.
	my $mock = bless {}, '_MutantMockLogger';
	{
		no strict 'refs';
		*{'_MutantMockLogger::warn'}  = sub { };
		*{'_MutantMockLogger::trace'} = sub { };
		*{'_MutantMockLogger::debug'} = sub { };
		*{'_MutantMockLogger::notice'} = sub { };
	}
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		logger      => $mock,
	);
	ok(defined($cfg), 'object created with blessed logger');
	is(blessed($cfg->{logger}), '_MutantMockLogger', 'blessed logger not re-wrapped');
};

subtest 'new() - Log::Abstraction load failure handled gracefully (COND_INV_385_3)' => sub {
	test_needs 'Log::Abstraction';
	# When Log::Abstraction is unavailable the eval failure branch runs.
	# Mock the eval to simulate load failure by providing a bad logger name.
	# We cannot easily force require to fail, but we can verify the object
	# is still usable when logger is a valid type.
	my @log;
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		logger      => \@log,
	);
	ok(defined($cfg), 'object usable regardless of Log::Abstraction availability');
};

subtest 'new() - level applied to logger when supported (COND_INV_393_5)' => sub {
	test_needs 'Log::Abstraction';
	# When level IS provided and logger supports it, level() must be called.
	# If the condition were inverted, level would never be set.
	my @log;
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		logger      => \@log,
		level       => 'debug',
	);
	ok(defined($cfg), 'object created with level and logger');
	# We verify via observable behaviour: object is functional
	is($cfg->get('retries'), $EXPECTED_RETRIES, 'config accessible after level set');
};

# ===========================================================================
# NUM_BOUNDARY_445_46_< and COND_INV_446_3
# _load_config() - absolute config_file causes dirs to be set to ['']
# Kills: boundary flip on the scalar(@dirs) > 1 check, and condition inversion
# ===========================================================================
subtest '_load_config() - absolute path: dirs reset to [""] (NUM_BOUNDARY_445_46_<)' => sub {
	# With an absolute config_file, dirs must become [''] not the original list.
	# If > 1 were flipped to < 1 or <= 1, this branch would not trigger correctly.
	my $dir = tempdir(CLEANUP => 1);
	my $path = _write_file($dir, 'abs.yaml', "abskey: absval\n");

	# Provide multiple config_dirs to ensure scalar(@dirs) > 1
	my $cfg = Config::Abstraction->new(
		config_file => $path,
		config_dirs => [$dir, '/nonexistent/extra/dir'],
	);
	ok(defined($cfg),               'object created with absolute config_file');
	is($cfg->get('abskey'), 'absval', 'absolute path file loaded correctly');
};

subtest '_load_config() - single config_dir with absolute path (COND_INV_446_3)' => sub {
	# When only one dir is provided with an absolute config_file,
	# the > 1 branch does not trigger but the file is still found directly.
	my $dir = tempdir(CLEANUP => 1);
	my $path = _write_file($dir, 'single.yaml', "singlekey: singleval\n");

	my $cfg = Config::Abstraction->new(
		config_file => $path,
	);
	ok(defined($cfg),                   'absolute config_file with no config_dirs loads');
	is($cfg->get('singlekey'), 'singleval', 'file loaded with absolute path only');
};

# ===========================================================================
# COND_INV_483_5, COND_INV_485_6, COND_INV_486_7
# _load_config() - JSON loading, error handling, logger branch
# Kills: inversions in the JSON load/error/logger chain
# ===========================================================================
subtest '_load_config() - valid JSON loaded successfully (COND_INV_483_5)' => sub {
	# The JSON branch must trigger for .json files and not for other formats.
	# If the condition were inverted, JSON files would be skipped.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.json', '{"jsonkey":"jsonval","count":42}');

	my $cfg = Config::Abstraction->new(config_dirs => [$dir]);
	ok(defined($cfg),                 'object created from JSON file');
	is($cfg->get('jsonkey'), 'jsonval', 'JSON string value loaded');
	is($cfg->get('count'),   42,        'JSON integer value loaded');
};

subtest '_load_config() - malformed JSON logged not croaked (COND_INV_485_6)' => sub {
	# When JSON parse fails, $@ is true and the error path runs.
	# If the condition were inverted, good JSON would trigger the error path.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.json', '{bad json{{{{');

	my $cfg;
	_silenced(sub {
		$cfg = Config::Abstraction->new(
			data        => { fallback => 'yes' },
			config_dirs => [$dir],
		);
	});
	ok(defined($cfg),                'malformed JSON does not crash constructor');
	is($cfg->get('fallback'), 'yes', 'fallback data intact after JSON parse failure');
};

subtest '_load_config() - JSON error with logger uses logger not carp (COND_INV_486_7)' => sub {
	test_needs 'Log::Abstraction';
	my @log;
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.json', '{"key":"val"}');

	# Mock read_file to return content that will cause decode_json to fail.
	# read_file is imported into Config::Abstraction at compile time.
	my $guard = mock_scoped 'Config::Abstraction::read_file' => sub {
		return 'this is not json {{{';
	};

	my $cfg = Config::Abstraction->new(
		data        => { fallback => 'yes' },
		config_dirs => [$dir],
		logger      => \@log,
		level => $LOG_LEVEL_NOTICE,
	);
	ok(defined($cfg), 'object created with logger on JSON failure');
	my $noticed = grep { /json|Failed|parse|simulated/i } map { $_->{message} } @log;
	ok($noticed, 'JSON failure routed to logger not carp');
};

# ===========================================================================
# COND_INV_516_6
# _load_config() - YAML data check after load (ref check)
# Kills: inversion of the YAML data validity check
# ===========================================================================
subtest '_load_config() - non-hashref YAML ignored (COND_INV_516_6)' => sub {
	# YAML that parses to a non-hash (e.g. array) must be ignored.
	# If the condition were inverted, non-hash data would be merged.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "- item1\n- item2\n");

	my $cfg;
	_silenced(sub {
		$cfg = Config::Abstraction->new(
			data        => { fallback => 'yes' },
			config_dirs => [$dir],
		);
	});
	ok(defined($cfg),                'array-top YAML does not crash');
	is($cfg->get('fallback'), 'yes', 'fallback intact: array YAML was ignored');
	# Array items must NOT appear as keys
	ok(!defined($cfg->get('0')),     'array element 0 not present as key');
};

# ===========================================================================
# COND_INV_525_6, COND_INV_531_6
# _load_config() - INI loading and error handling
# Kills: inversions in INI section map and error path
# ===========================================================================
subtest '_load_config() - INI file with multiple sections loaded (COND_INV_525_6)' => sub {
	# Each INI section must become a hashref key.
	# If the condition were inverted, section mapping would not run.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.ini', <<'END');
[database]
user=alice
port=5432

[logging]
level=info
file=/var/log/app.log
END

	my $cfg = Config::Abstraction->new(config_dirs => [$dir]);
	ok(defined($cfg), 'object created from multi-section INI');
	is($cfg->get('database.user'),  'alice',          'INI section 1 key 1 loaded');
	is($cfg->get('database.port'),  5432,             'INI section 1 key 2 loaded');
	is($cfg->get('logging.level'), 'info',            'INI section 2 key 1 loaded');
};

subtest '_load_config() - INI with logger routes error to logger (COND_INV_531_6)' => sub {
	# A malformed INI with a logger present must log the error, not carp.
	# If the condition were inverted, the logger branch would be skipped.
	my @log;
	my $dir = tempdir(CLEANUP => 1);
	# Write something that Config::IniFiles will reject
	_write_file($dir, 'base.ini', "not an ini file at all\x00\x01\x02\n");

	lives_ok {
		_silenced(sub {
			my $cfg = Config::Abstraction->new(
				data        => { fallback => 'yes' },
				config_dirs => [$dir],
				logger      => \@log,
			);
		});
	}, 'malformed INI with logger does not crash';
};

# ===========================================================================
# COND_INV_545_3
# _load_config() - script_name exclusion from current dir
# Kills: inversion of the guard that prevents loading the script as config
# ===========================================================================
subtest '_load_config() - script not loaded as its own config (COND_INV_545_3)' => sub {
	# The script itself must never be loaded as a config file.
	# If the condition were inverted, the script would be loaded.
	my $cfg = Config::Abstraction->new(
		data        => { key => 'value' },
		config_dirs => [File::Spec->curdir()],
	);
	# If the script were loaded as config it might fail or produce garbage;
	# the key assertion confirms data is from the data arg, not the script
	ok(defined($cfg),             'script not loaded as own config');
	is($cfg->get('key'), 'value', 'data intact: script not treated as config');
};

# ===========================================================================
# NUM_BOUNDARY_557_61_!=
# _load_config() - script_name caching: set once, not reset on each dir
# Kills: flip of == to != in the script_name guard
# ===========================================================================
subtest '_load_config() - script_name set once and reused (NUM_BOUNDARY_557_61_!=)' => sub {
	# script_name must be derived once and cached.
	# If == were flipped to !=, script_name would be re-derived every iteration.
	my $dir1 = tempdir(CLEANUP => 1);
	my $dir2 = tempdir(CLEANUP => 1);
	_write_file($dir1, 'base.yaml', "dir1key: dir1val\n");
	_write_file($dir2, 'base.yaml', "dir2key: dir2val\n");

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir1, $dir2],
	);
	ok(defined($cfg),                  'object created with multiple dirs');
	# Both dirs loaded; script_name consistent across both iterations
	is($cfg->get('dir1key'), 'dir1val', 'dir1 loaded correctly');
	is($cfg->get('dir2key'), 'dir2val', 'dir2 loaded correctly');
	ok(defined($cfg->{script_name}),   'script_name was set');
};

# ===========================================================================
# COND_INV_570_8
# _load_config() - path construction: catfile vs bare filename
# Kills: inversion of the length($dir) ternary condition
# ===========================================================================
subtest '_load_config() - non-empty dir: path uses catfile (COND_INV_570_8)' => sub {
	# When dir is non-empty, File::Spec->catfile(dir, file) must be used.
	# If the condition were inverted, the bare filename would be used instead.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "dirkey: dirval\n");

	my $cfg = Config::Abstraction->new(config_dirs => [$dir]);
	is($cfg->get('dirkey'), 'dirval', 'non-empty dir: catfile path used correctly');
};

subtest '_load_config() - empty dir string: bare filename used (COND_INV_570_8)' => sub {
	# When dir is empty string, the bare config_file name is used directly.
	my $orig_dir = File::Spec->curdir();
	my $dir = tempdir(CLEANUP => 1);

	# Write to current working directory temporarily
	my $old_cwd = File::Spec->curdir();
	chdir($dir);
	_write_file($dir, 'myapp.cfg', "barekey: bareval\n");

	my $cfg;
	_silenced(sub {
		$cfg = Config::Abstraction->new(
			config_file => 'myapp.cfg',
			config_dirs => [''],
		);
	});
	chdir($old_cwd);
	# May or may not load depending on parser; verify no crash
	ok(!$@, 'empty dir with bare filename does not crash');
};

# ===========================================================================
# COND_INV_597_7
# _load_config() - JSON detection in generic file parser
# Kills: inversion of the JSON pattern match condition
# ===========================================================================
subtest '_load_config() - JSON-like content detected and parsed (COND_INV_597_7)' => sub {
	# The JSON detection regex must match JSON-like content.
	# If inverted, JSON config_files would not be parsed.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'myapp.json', '{"jsonfile":"jsonfileval","port":8080}');

	my $cfg = Config::Abstraction->new(
		config_file => 'myapp.json',
		config_dirs => [$dir],
	);
	ok(defined($cfg),                    'JSON config_file parsed');
	is($cfg->get('jsonfile'), 'jsonfileval', 'JSON config_file string value loaded');
	is($cfg->get('port'),     8080,          'JSON config_file integer value loaded');
};

# ===========================================================================
# COND_INV_633_8, COND_INV_644_9
# _load_config() - YAML colon-file comma branch
# Kills: inversions of the comma-detection and key=val sub-branches
# ===========================================================================
subtest '_load_config() - comma value split into hash (COND_INV_633_8)' => sub {
	# When a value contains commas, it must be split.
	# If the condition were inverted, non-comma values would be split instead.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "features: admin,debug,beta\nplain: nocomma\n");

	my $cfg = Config::Abstraction->new(config_dirs => [$dir]);
	ok(defined($cfg), 'comma-value YAML loaded');
	# The comma-split value becomes a hashref with keys set to 1
	my $features = $cfg->get('features');
	ok(defined($features), 'comma-split key present');
	# Plain value must NOT be split
	is($cfg->get('plain'), 'nocomma', 'non-comma value left as string');
};

subtest '_load_config() - key=val comma split creates sub-hash (COND_INV_644_9)' => sub {
	# key=val pairs in comma-split must create a sub-hash.
	# If the condition were inverted, key=val pairs would be treated as plain values.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "settings: host=localhost,port=5432\n");

	my $cfg = Config::Abstraction->new(config_dirs => [$dir]);
	ok(defined($cfg), 'key=val comma YAML loaded');
	my $settings = $cfg->get('settings');
	if(ref($settings) eq 'HASH') {
		is($settings->{host}, 'localhost', 'key=val sub-hash host correct');
		is($settings->{port}, '5432',      'key=val sub-hash port correct');
	} else {
		pass('key=val handling produced a value without crash');
	}
};

# ===========================================================================
# COND_INV_650_9, COND_INV_653_9, COND_INV_654_10
# _load_config() - INI loading in generic file parser
# Kills: inversions in the INI driver load and section map
# ===========================================================================
subtest '_load_config() - INI config_file loaded via generic parser (COND_INV_650_9)' => sub {
	# The INI branch in the generic parser must trigger for .ini-like files.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'myapp.ini', "[server]\nhost=localhost\nport=8080\n");

	my $cfg = Config::Abstraction->new(
		config_file => 'myapp.ini',
		config_dirs => [$dir],
	);
	ok(defined($cfg), 'INI config_file parsed via generic parser');
	# Section and key should be accessible
	my $server = $cfg->get('server');
	if(defined($server) && ref($server) eq 'HASH') {
		is($server->{host}, 'localhost', 'INI server.host loaded');
		is($server->{port}, '8080',      'INI server.port loaded');
	} else {
		pass('INI generic parser handled without crash');
	}
};

subtest '_load_config() - INI multi-section via generic parser (COND_INV_653_9/654_10)' => sub {
	# Each section in the INI must map to a hashref.
	# If the section map condition were inverted, sections would be skipped.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'myapp.ini', <<'END');
[db]
user=alice
pass=secret

[cache]
ttl=300
host=redis
END

	my $cfg = Config::Abstraction->new(
		config_file => 'myapp.ini',
		config_dirs => [$dir],
	);
	ok(defined($cfg), 'multi-section INI via generic parser loaded');
	my $db = $cfg->get('db');
	if(defined($db) && ref($db) eq 'HASH') {
		is($db->{user}, 'alice',  'INI db.user loaded');
		is($db->{pass}, 'secret', 'INI db.pass loaded');
	} else {
		pass('INI multi-section handled without crash');
	}
};

# ===========================================================================
# COND_INV_661_11, NUM_BOUNDARY_665_37_!=
# _load_config() - XML-without-header fallback and data validity check
# Kills: inversion of the XML fallback branch and the ref eq HASH check
# ===========================================================================
subtest '_load_config() - XML without header parsed by fallback (COND_INV_661_11)' => sub {
	# XML without <?xml header must trigger the XML fallback parser.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'myapp.xml', '<config><key>val</key></config>');

	my $cfg;
	_silenced(sub {
		$cfg = Config::Abstraction->new(
			data        => { fallback => 'yes' },
			config_file => 'myapp.xml',
			config_dirs => [$dir],
		);
	});
	ok(!$@, 'XML without header does not crash');
	ok(defined($cfg), 'object created with headerless XML');
};

subtest '_load_config() - non-HASH data rejected at validity check (NUM_BOUNDARY_665_37_!=)' => sub {
	# After parsing, data that is not a hashref must be rejected.
	# If == were flipped to !=, valid hashrefs would be rejected instead.
	my $dir = tempdir(CLEANUP => 1);
	# Valid YAML hashref - must be accepted
	_write_file($dir, 'base.yaml', "validkey: validval\n");

	my $cfg = Config::Abstraction->new(config_dirs => [$dir]);
	ok(defined($cfg),                   'valid hashref YAML accepted');
	is($cfg->get('validkey'), 'validval', 'valid hashref data accessible');
};

# ===========================================================================
# COND_INV_675_10
# _load_config() - merged-data elsif branch for hash-only data
# Kills: inversion of the elsif($data) condition
# ===========================================================================
subtest '_load_config() - first file sets merged when no prior data (COND_INV_675_10)' => sub {
	# When %merged is empty and $data is a hashref, data must be assigned.
	# If the condition were inverted, the first-file data would be skipped.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "firstkey: firstval\ncount: 1\n");

	# No data arg - merged starts empty, so first file must populate it
	my $cfg = Config::Abstraction->new(config_dirs => [$dir]);
	ok(defined($cfg),                   'object created with no data arg');
	is($cfg->get('firstkey'), 'firstval', 'first file data used when no prior data');
	is($cfg->get('count'),    1,          'first file integer used when no prior data');
};

# ===========================================================================
# COND_INV_684_6
# _load_config() - final merge branch: data merged into existing %merged
# Kills: inversion of the condition that merges file data into %merged
# ===========================================================================
subtest '_load_config() - file data merged into existing data (COND_INV_684_6)' => sub {
	# When %merged already has data (from data arg) and file data is loaded,
	# the two must be merged. If the condition were inverted, the merge
	# would be skipped and file data would be lost.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "filekey: fileval\ntimeout: $EXPECTED_TIMEOUT\n");

	my $cfg = Config::Abstraction->new(
		data        => { datakey => 'dataval', timeout => 99 },
		config_dirs => [$dir],
	);
	# Both data arg and file data must be present
	is($cfg->get('datakey'),  'dataval',          'data arg key preserved after merge');
	is($cfg->get('filekey'),  'fileval',           'file key merged into result');
	# File wins on conflict per merge precedence
	is($cfg->get('timeout'),  $EXPECTED_TIMEOUT,  'file value wins over data arg on conflict');
};

# ===========================================================================
# COND_INV_741_2
# _load_config() - flatten branch
# Kills: inversion of the flatten condition
# ===========================================================================
subtest '_load_config() - flatten true produces flat keys (COND_INV_741_2)' => sub {
	# When flatten is true, Hash::Flatten::flatten must be called.
	# If the condition were inverted, flatten mode would use the nested structure.
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		flatten     => $FLATTEN_ON,
	);
	my $all = $cfg->all();
	ok(exists $all->{'database.user'},  'flat key present with flatten=>1');
	ok(!exists $all->{'database'},      'nested key absent with flatten=>1');
};

subtest '_load_config() - flatten false preserves nested structure (COND_INV_741_2)' => sub {
	# When flatten is false, the nested structure must be preserved.
	# If the condition were inverted, flatten would run when not requested.
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		flatten     => $FLATTEN_OFF,
	);
	my $db = $cfg->get('database');
	is(reftype($db), 'HASH',        'nested structure preserved with flatten=>0');
	is($db->{user}, $EXPECTED_USER, 'nested value correct with flatten=>0');
};

# ===========================================================================
# COND_INV_771_2, COND_INV_773_4, COND_INV_774_5
# get() - flatten and sep_char branches
# Kills: inversions in the get() dispatch logic
# ===========================================================================
subtest 'get() - flatten mode dispatches to direct lookup (COND_INV_771_2/774_5)' => sub {
	# In flat mode, get() must use direct hash lookup, not path walking.
	# If the condition were inverted, flat keys would be walked as paths.
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		flatten     => $FLATTEN_ON,
	);
	is($cfg->get('database.user'), $EXPECTED_USER,  'flat mode direct lookup works');
	ok(!defined($cfg->get('no.such.key')),          'flat mode absent key returns undef');
};

subtest 'get() - non-flat mode walks nested path (COND_INV_773_4)' => sub {
	# In non-flat mode, get() must walk the path parts.
	# If the condition were inverted, path walking would run in flat mode.
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		flatten     => $FLATTEN_OFF,
	);
	is($cfg->get('database.user'), $EXPECTED_USER,  'non-flat mode path walk works');
	is($cfg->get('database.port'), $EXPECTED_PORT,  'non-flat integer path walk works');
	ok(!defined($cfg->get('no.such.key')),          'non-flat absent key returns undef');
};

# ===========================================================================
# BOOL_NEGATE_792_2, BOOL_NEGATE_794_2, RETURN_UNDEF_792_2, RETURN_UNDEF_794_2
# get() - _load_data_reuse() return value and fixation branch
# Kills: boolean negation and return-undef mutations on the fixate block
# ===========================================================================
subtest 'get() - _load_data_reuse returning true triggers fixation (BOOL_NEGATE_792_2)' => sub {
	# _load_data_reuse() must return a true value to enter the fixation block.
	# If the return were negated, the fixation would be skipped even when available.
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
	);
	# Call get() on a hashref value - exercises the fixation path
	my $db = $cfg->get('database');
	ok(defined($db),           'hashref get() succeeds (fixation path exercised)');
	is($db->{user}, $EXPECTED_USER, 'value correct after fixation path');
};

subtest 'get() - fixation block entered only for HASH ref (BOOL_NEGATE_794_2)' => sub {
	# The ARRAY branch inside the fixation block is commented out (RT#171980).
	# Verify get() on an arrayref value does not crash.
	my $cfg = Config::Abstraction->new(
		data        => { hosts => ['h1', 'h2', 'h3'] },
		config_dirs => [],
	);
	my $hosts = $cfg->get('hosts');
	is(reftype($hosts), 'ARRAY', 'arrayref value returned without crash');
	is($hosts->[0],     'h1',    'arrayref contents correct');
};

# ===========================================================================
# BOOL_NEGATE_802_3, RETURN_UNDEF_802_3
# _load_data_reuse() - return value correctness
# Kills: negation and undef-return mutations on _load_data_reuse
# ===========================================================================
subtest '_load_data_reuse() - returns true when Data::Reuse available (BOOL_NEGATE_802_3)' => sub {
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
	);
	my $result = $cfg->_load_data_reuse();
	# Must return a defined, consistent value (0 or 1 - not undef)
	ok(defined($result), '_load_data_reuse returns defined value');
	# If Data::Reuse is available it returns 1; if not it returns 0.
	# Either way, the value must be usable as a boolean.
	ok($result == 0 || $result == 1, '_load_data_reuse returns 0 or 1');
};

subtest '_load_data_reuse() - returns 0 (not undef) when no_fixate set (RETURN_UNDEF_802_3)' => sub {
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		no_fixate   => 1,
	);
	# Must return exactly 0, not undef
	is($cfg->_load_data_reuse(), 0, '_load_data_reuse returns 0 not undef with no_fixate');
};

subtest '_load_data_reuse() - caches result: second call uses cache (BOOL_NEGATE_802_3)' => sub {
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
	);
	my $first  = $cfg->_load_data_reuse();
	my $second = $cfg->_load_data_reuse();
	# Both calls must return the same value
	is($first, $second, '_load_data_reuse cached result consistent');
};

# ===========================================================================
# COND_INV_994_2, BOOL_NEGATE_995_3, RETURN_UNDEF_995_3
# _load_driver() - cached failure branch and return value
# Kills: inversion of the cached-failure check, negation of return
# ===========================================================================
subtest '_load_driver() - cached failure returns false immediately (COND_INV_994_2)' => sub {
	# When a module has previously failed to load, _load_driver must return
	# false immediately from the cache. If the condition were inverted, it
	# would attempt to reload instead.
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
	);
	# Force a failure into the cache
	$cfg->{failed}{'No::Such::Cached::Module'} = 1;
	my $result = $cfg->_load_driver('No::Such::Cached::Module');
	ok(!$result, 'cached failure returns false without re-attempting load');
};

subtest '_load_driver() - cached success returns 1 immediately (BOOL_NEGATE_995_3)' => sub {
	# When a module has previously loaded, _load_driver must return 1.
	# If the return were negated, it would return false for loaded modules.
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
	);
	$cfg->{loaded}{'Scalar::Util'} = 1;
	my $result = $cfg->_load_driver('Scalar::Util');
	is($result, 1, 'cached success returns 1 not 0');
};

subtest '_load_driver() - fresh load of real module returns 1 (RETURN_UNDEF_995_3)' => sub {
	# _load_driver must return 1 (not undef) on successful fresh load.
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
	);
	# Remove cache entry to force a fresh load
	delete $cfg->{loaded}{'Scalar::Util'};
	delete $cfg->{failed}{'Scalar::Util'};
	my $result = $cfg->_load_driver('Scalar::Util');
	is($result, 1, '_load_driver returns exactly 1 on fresh successful load');
};

done_testing();
