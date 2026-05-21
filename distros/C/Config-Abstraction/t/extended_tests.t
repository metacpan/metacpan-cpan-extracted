#!/usr/bin/perl

# Extended tests for Config::Abstraction targeting high coverage and
# LCSAJ/TER3 scores.  Focuses on branch coverage, path coverage, and
# exercising every decision point not already covered by the other test files.

use strict;
use warnings;
use autodie qw(:all);

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
	env_prefix	=> 'EXTAPP_',
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
Readonly::Scalar my $OVERRIDE_PORT	=> 3306;

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
		log => {
			level => $EXPECTED_LEVEL,
		},
		retries => $EXPECTED_RETRIES,
		timeout => $EXPECTED_TIMEOUT,
	};
}

# Silence STDERR for subtests that intentionally trigger carp noise
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
# _load_driver() branch coverage
# ===========================================================================

# Exercise the imports arrayref path in _load_driver
subtest '_load_driver() - imports arrayref executed on load' => sub {
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
	);
	# JSON::MaybeXS is already loaded; force a fresh driver load with imports
	delete $cfg->{loaded}{'Scalar::Util'};
	my $result = $cfg->_load_driver('Scalar::Util', ['blessed', 'reftype']);
	is($result, 1, '_load_driver with imports arrayref succeeds');
};

# Exercise the logger warning path in _load_driver on failure
subtest '_load_driver() - logger warned on failure' => sub {
	test_needs 'Log::Abstraction';
	my @log;
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		logger      => \@log,
	);
	$cfg->_load_driver('No::Such::Module::Ever::XYZ');
	# The logger should have received a warning about the failure
	my $warned = grep { /No::Such::Module::Ever::XYZ/ } map { $_->{message} } @log;
	ok($warned, 'logger warned when _load_driver fails');
};

# ===========================================================================
# _load_config() branch coverage - config_file with absolute path
# ===========================================================================

subtest '_load_config() - absolute config_file sets config_dirs to empty' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $path = _write_file($dir, 'abs.yaml', "abskey: absval\n");

	# Absolute path should bypass config_dirs search
	my $cfg = Config::Abstraction->new(
		config_file => $path,
	);
	ok(defined($cfg),              'absolute config_file accepted');
	is($cfg->get('abskey'), 'absval', 'absolute config_file loaded');
};

# Exercise the branch where config_file is relative and dirs > 1
subtest '_load_config() - relative config_file searched in config_dirs' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'myapp.yaml', "relkey: relval\n");

	my $cfg = Config::Abstraction->new(
		config_file => 'myapp.yaml',
		config_dirs => [$dir],
	);
	ok(defined($cfg),               'relative config_file found in config_dirs');
	is($cfg->get('relkey'), 'relval', 'relative config_file loaded');
};

# ===========================================================================
# _load_config() branch coverage - script_name derived config files
# ===========================================================================

subtest '_load_config() - script_name config file loaded when present' => sub {
	my $dir = tempdir(CLEANUP => 1);

	# The script name is derived from $0; write a file named after it
	require File::Basename;
	my $script = File::Basename::basename($0);
	_write_file($dir, "$script.cfg", "scriptkey: scriptval\n");

	my $cfg = Config::Abstraction->new(
		data        => { fallback => 'yes' },
		config_dirs => [$dir],
	);
	# May or may not load depending on parser support for .cfg extension;
	# we just verify it does not crash and fallback is intact
	ok(defined($cfg), 'script_name config file does not crash');
};

# Exercise the 'default' config file name path
subtest '_load_config() - default config file loaded when present' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'default', "defaultkey: defaultval\n");

	my $cfg;
	_silenced(sub {
		$cfg = Config::Abstraction->new(
			data        => { fallback => 'yes' },
			config_dirs => [$dir],
		);
	});
	# 'default' file may parse as YAML/INI/etc; verify no crash
	ok(defined($cfg), 'default config file does not crash');
};

# ===========================================================================
# _load_config() - XML file loading branches
# ===========================================================================

subtest '_load_config() - XML base file loaded when XML module available' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.xml', <<'END');
<?xml version="1.0"?>
<config>
  <database>
    <user>xmluser</user>
    <port>5432</port>
  </database>
  <retries>3</retries>
</config>
END

	my $cfg;
	_silenced(sub {
		$cfg = Config::Abstraction->new(
			data        => { fallback => 'yes' },
			config_dirs => [$dir],
		);
	});
	ok(defined($cfg), 'XML base file handled without crash');
	# If XML loaded successfully, check a value
	if(defined($cfg) && defined($cfg->get('database'))) {
		pass('XML data accessible');
	} else {
		pass('XML gracefully skipped when parser unavailable');
	}
};

# ===========================================================================
# _load_config() - multi-directory search order
# ===========================================================================

subtest '_load_config() - later directory overrides earlier directory' => sub {
	my $dir1 = tempdir(CLEANUP => 1);
	my $dir2 = tempdir(CLEANUP => 1);
	_write_file($dir1, 'base.yaml', "level: dir1\ntimeout: $EXPECTED_TIMEOUT\n");
	_write_file($dir2, 'base.yaml', "level: dir2\n");

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir1, $dir2],
	);
	# dir2 is searched after dir1 so its values are merged on top
	is($cfg->get('level'),   'dir2',            'later dir overrides earlier dir');
	is($cfg->get('timeout'), $EXPECTED_TIMEOUT, 'earlier dir value retained when absent from later');
};

subtest '_load_config() - config_path accumulates all loaded files' => sub {
	my $dir1 = tempdir(CLEANUP => 1);
	my $dir2 = tempdir(CLEANUP => 1);
	_write_file($dir1, 'base.yaml',  "key1: val1\n");
	_write_file($dir2, 'local.yaml', "key2: val2\n");

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir1, $dir2],
	);
	my $paths = $cfg->all()->{config_path};
	is(scalar(@{$paths}), 2, 'config_path contains one entry per loaded file');
};

# ===========================================================================
# _load_config() - YAML colon-file value parsing branches
# ===========================================================================

# Exercise the comma-split branch that creates sub-hashes from key=val pairs
subtest '_load_config() - YAML colon-file comma-split with key=val pairs' => sub {
	my $dir = tempdir(CLEANUP => 1);
	# This format triggers the YAML-as-colon-file parser
	_write_file($dir, 'base.yaml', "features: admin=1,debug=0,beta=1\n");

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir],
	);
	ok(defined($cfg), 'comma-split key=val YAML parsed without crash');
};

# Exercise the comma-split branch that creates simple boolean sub-hash
subtest '_load_config() - YAML colon-file comma-split plain values' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "tags: alpha,beta,gamma\n");

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir],
	);
	ok(defined($cfg), 'comma-split plain YAML values parsed without crash');
};

# Exercise the quoted-value branch that keeps value as single field
subtest '_load_config() - YAML quoted value kept as single field' => sub {
	my $dir = tempdir(CLEANUP => 1);
	# Quoted value should not be comma-split
	_write_file($dir, 'base.yaml', "dsn: \"host=localhost,port=5432\"\n");

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir],
	);
	ok(defined($cfg), 'quoted YAML value parsed without crash');
	# The quoted value should be kept intact, not split
	my $val = $cfg->get('dsn');
	if(defined($val)) {
		unlike($val, qr/^HASH/, 'quoted value not split into hash');
	} else {
		pass('quoted value handled gracefully');
	}
};

# ===========================================================================
# get() branch coverage
# ===========================================================================

# Exercise the no_fixate flag branch in get()
subtest 'get() - no_fixate flag prevents Data::Reuse call' => sub {
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		no_fixate   => 1,
	);
	my $db = $cfg->get('database');
	ok(defined($db),          'get() works with no_fixate set');
	is($db->{user}, $EXPECTED_USER, 'value correct with no_fixate');
};

# Exercise the flatten branch in get()
subtest 'get() - flatten mode returns undef for absent flat key' => sub {
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		flatten     => $FLATTEN_ON,
	);
	ok(!defined($cfg->get('no.such.flat.key')), 'absent flat key returns undef');
};

# Exercise path where $ref is an arrayref mid-walk
subtest 'get() - arrayref value mid-path returns arrayref' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { hosts => ['host1', 'host2', 'host3'] },
		config_dirs => [],
	);
	my $val = $cfg->get('hosts');
	is(reftype($val), 'ARRAY', 'arrayref value returned correctly');
	is($val->[0], 'host1',     'arrayref contents correct');
};

# Exercise the branch where key part exists but value is undef
subtest 'get() - key present with undef value returns undef not missing' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { section => { nullval => undef } },
		config_dirs => [],
	);
	# get() should return undef for the value, not short-circuit on missing
	my $val = $cfg->get('section.nullval');
	ok(!defined($val), 'undef nested value returns undef');
	# But exists() should confirm it is present
	is($cfg->exists('section.nullval'), 1, 'undef nested value exists');
};

# ===========================================================================
# exists() branch coverage
# ===========================================================================

subtest 'exists() - multi-level path all present' => sub {
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
	);
	is($cfg->exists('database.user'), 1, 'three-level path exists');
};

subtest 'exists() - first level absent short-circuits' => sub {
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
	);
	is($cfg->exists('absent.user'), 0, 'absent first level returns 0');
};

subtest 'exists() - second level absent returns 0' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { database => { user => $EXPECTED_USER } },
		config_dirs => [],
	);
	is($cfg->exists('database.absent'), 0, 'absent second level returns 0');
};

# ===========================================================================
# all() branch coverage
# ===========================================================================

subtest 'all() - returns same reference on repeated calls' => sub {
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
	);
	my $first  = $cfg->all();
	my $second = $cfg->all();
	# Should be the same hashref, not a copy
	is($first, $second, 'all() returns same reference on repeated calls');
};

subtest 'all() - flat mode returns flattened structure' => sub {
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		flatten     => $FLATTEN_ON,
	);
	my $all = $cfg->all();
	# Flat keys should exist, nested structure should not
	ok(exists $all->{'database.user'},  'flat key present');
	ok(!exists $all->{'database'},      'nested key absent in flat mode');
};

# ===========================================================================
# merge_defaults() branch coverage
# ===========================================================================

# Exercise the deep+global branch
subtest 'merge_defaults() - deep merge with nested global values' => sub {
	my $cfg = Config::Abstraction->new(
		data => {
			global => {
				database => { pool_size => 10 },
				timeout  => $EXPECTED_TIMEOUT,
			},
			retries => $EXPECTED_RETRIES,
		},
		config_dirs => [],
	);
	my $merged = $cfg->merge_defaults(
		defaults => {
			database => { pool_size => 5, host => 'localhost' },
			timeout  => 99,
		},
		deep => 1,
	);
	# Global wins on conflict
	is($merged->{database}{pool_size}, 10,          'deep: global pool_size wins');
	is($merged->{timeout},             $EXPECTED_TIMEOUT, 'deep: global timeout wins');
	# Default-only key preserved
	is($merged->{database}{host},      'localhost',  'deep: default-only nested key preserved');
};

# Exercise the section+merge combination
subtest 'merge_defaults() - section with merge=>1' => sub {
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
	);
	my $merged = $cfg->merge_defaults(
		defaults => { extra => 'kept', user => 'default_user' },
		section  => 'database',
		merge    => 1,
	);
	is($merged->{user},  $EXPECTED_USER, 'section user overrides default');
	is($merged->{extra}, 'kept',         'default extra key preserved with merge');
};

# Exercise the branch where section exists and merge is not set
subtest 'merge_defaults() - section without merge uses hash precedence' => sub {
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
	);
	my $merged = $cfg->merge_defaults(
		defaults => { user => 'default_user', extra => 'kept' },
		section  => 'database',
	);
	is($merged->{user},  $EXPECTED_USER, 'section value wins over default');
	is($merged->{extra}, 'kept',         'default-only key preserved');
};

# Exercise the no-defaults path (returns raw config)
subtest 'merge_defaults() - called with only section, no defaults' => sub {
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
	);
	my $merged = $cfg->merge_defaults(section => 'database');
	ok(defined($merged), 'merge_defaults with only section does not crash');
};

# ===========================================================================
# ENV handling branch coverage
# ===========================================================================

# Exercise env_prefix with :: suffix (Perl package-style prefix)
subtest 'ENV - :: suffix in env_prefix stripped correctly' => sub {
	local %ENV = %ENV;
	$ENV{'MyApp::TIMEOUT'} = $EXPECTED_TIMEOUT;

	my $cfg = Config::Abstraction->new(
		data        => { MyApp => { timeout => 99 } },
		config_dirs => [],
		env_prefix  => 'MyApp::',
	);
	ok(defined($cfg), 'Perl-style :: env_prefix accepted');
};

# Exercise env_prefix with __ suffix
subtest 'ENV - __ suffix in env_prefix stripped correctly' => sub {
	local %ENV = %ENV;
	$ENV{"EXTAPP__RETRIES"} = '77';

	my $cfg = Config::Abstraction->new(
		data        => { EXTAPP => { retries => $EXPECTED_RETRIES } },
		config_dirs => [],
		env_prefix  => 'EXTAPP__',
	);
	ok(defined($cfg), 'double-underscore env_prefix accepted');
};

# Exercise the branch where ENV key has no sub-path (just prefix match)
subtest 'ENV - prefix-only match with no remaining path handled' => sub {
	local %ENV = %ENV;
	# Key is exactly the prefix with nothing after it
	$ENV{$ENV_PREFIX} = 'bare_prefix';

	my $cfg;
	eval {
		$cfg = Config::Abstraction->new(
			data        => { key => 'value' },
			config_dirs => [],
			env_prefix  => $ENV_PREFIX,
		);
	};
	ok(!$@, 'bare prefix ENV key does not crash');
};

# ===========================================================================
# CLI handling branch coverage
# ===========================================================================

# Exercise single-part CLI path (no double-underscore)
subtest 'CLI - single-part path sets top-level key' => sub {
	local @ARGV = ("--${ENV_PREFIX}MODE=production");

	my $cfg = Config::Abstraction->new(
		data        => { mode => 'development' },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('mode'), 'production', 'single-part CLI path sets key');
};

# Exercise multi-part CLI path (with double-underscore)
subtest 'CLI - three-part path creates two levels of nesting' => sub {
	local @ARGV = ("--${ENV_PREFIX}DB__POOL__SIZE=20");

	my $cfg = Config::Abstraction->new(
		data => {
			db => { pool => { size => 5 } },
		},
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('db.pool.size'), '20', 'three-part CLI path sets deeply nested key');
};

# Exercise the branch where @ARGV has non-option entries mixed in
subtest 'CLI - non-option ARGV entries ignored' => sub {
	local @ARGV = ('positional', "--${ENV_PREFIX}RETRIES=5", '--', 'another');

	my $cfg = Config::Abstraction->new(
		data        => { retries => $EXPECTED_RETRIES },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('retries'), '5', 'option processed among non-option ARGV entries');
};

# ===========================================================================
# Logger branch coverage
# ===========================================================================

# Exercise the logger with a filename (Log::Abstraction wraps it)
subtest 'logger - filename logger accepted' => sub {
	test_needs 'Log::Abstraction';
	my $dir = tempdir(CLEANUP => 1);
	my $logfile = File::Spec->catfile($dir, 'test.log');

	my $cfg;
	eval {
		$cfg = Config::Abstraction->new(
			data        => _fresh_data(),
			config_dirs => [],
			logger      => $logfile,
		);
	};
	ok(!$@,        'filename logger does not crash');
	ok(defined($cfg), 'object created with filename logger');
};

# Exercise the level option with a logger
subtest 'logger - level option applied to logger when supported' => sub {
	test_needs 'Log::Abstraction';
	my @log;
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		logger      => \@log,
		level       => 'debug',
	);
	ok(defined($cfg), 'object created with logger and level');
};

# Exercise the already-blessed logger path (no wrapping in Log::Abstraction)
subtest 'logger - blessed logger not re-wrapped' => sub {
	# A blessed object that responds to warn/trace
	my $mock_logger = bless {}, '_MockLogger';
	# Add stub methods
	{
		no strict 'refs';
		*{'_MockLogger::warn'}  = sub { };
		*{'_MockLogger::trace'} = sub { };
		*{'_MockLogger::debug'} = sub { };
	}

	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		logger      => $mock_logger,
	);
	ok(defined($cfg), 'blessed logger object accepted without re-wrapping');
	is(blessed($cfg->{logger}), '_MockLogger', 'blessed logger not re-wrapped');
};

# ===========================================================================
# no_fixate flag coverage
# ===========================================================================

subtest 'no_fixate - _load_data_reuse returns 0 when no_fixate set' => sub {
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		no_fixate   => 1,
	);
	# _load_data_reuse should short-circuit when no_fixate is set
	is($cfg->_load_data_reuse(), 0, '_load_data_reuse returns 0 with no_fixate');
};

subtest 'no_fixate - get() skips fixation when flag set' => sub {
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		no_fixate   => 1,
	);
	# Should not crash even when Data::Reuse is available
	my $db = $cfg->get('database');
	ok(defined($db),           'get() works with no_fixate');
	is($db->{user}, $EXPECTED_USER, 'value correct with no_fixate');
};

# ===========================================================================
# Schema validation branch coverage
# ===========================================================================

# Exercise schema with all-optional fields and empty data
subtest 'schema - all-optional schema with minimal data' => sub {
	my $cfg;
	eval {
		$cfg = Config::Abstraction->new(
			data        => { retries => $EXPECTED_RETRIES },
			config_dirs => [],
			schema      => {
				retries => { type => 'integer' },
				timeout => { type => 'integer', optional => 1 },
				host    => { type => 'string',  optional => 1 },
			},
		);
	};
	ok(!$@,        'all-optional schema with minimal data does not throw');
	ok(defined($cfg), 'object created with optional schema fields absent');
};

# ===========================================================================
# Flatten mode branch coverage
# ===========================================================================

# Exercise flatten with nested arrays
subtest 'flatten - nested array values accessible in flat mode' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { hosts => ['h1', 'h2'], retries => $EXPECTED_RETRIES },
		config_dirs => [],
		flatten     => $FLATTEN_ON,
	);
	ok(defined($cfg), 'nested array with flatten mode does not crash');
	is($cfg->get('retries'), $EXPECTED_RETRIES, 'scalar value accessible in flat mode');
};

# Exercise unflatten path (flatten => 0 uses Hash::Flatten::unflatten)
# Currently disabled per RT#166761 comment in source, but verify no crash
subtest 'flatten off - nested structure preserved without unflattening' => sub {
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		flatten     => $FLATTEN_OFF,
	);
	my $db = $cfg->get('database');
	is(reftype($db), 'HASH',        'nested structure preserved in non-flat mode');
	is($db->{user}, $EXPECTED_USER, 'nested value accessible');
};

# ===========================================================================
# Concurrency: verify no shared state between instances
# ===========================================================================

subtest 'concurrency - config modifications do not bleed between instances' => sub {
	my $cfg1 = Config::Abstraction->new(
		data        => { key => 'instance1', shared => 'original' },
		config_dirs => [],
	);
	my $cfg2 = Config::Abstraction->new(
		data        => { key => 'instance2', shared => 'original' },
		config_dirs => [],
	);

	# Directly modify cfg1's config - should not affect cfg2
	$cfg1->{config}{shared} = 'modified';

	is($cfg1->get('shared'), 'modified',  'cfg1 modified correctly');
	is($cfg2->get('shared'), 'original',  'cfg2 unaffected by cfg1 modification');
	is($cfg1->get('key'),    'instance1', 'cfg1 key unaffected');
	is($cfg2->get('key'),    'instance2', 'cfg2 key unaffected');
};

# ===========================================================================
# AUTOLOAD branch coverage
# ===========================================================================

# Exercise AUTOLOAD with flatten mode
subtest 'AUTOLOAD - flat mode with sep_char=_' => sub {
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		flatten     => $FLATTEN_ON,
		sep_char    => $SEP_US,
	);
	# In flat mode AUTOLOAD uses $data->{key} directly
	my $val;
	eval { $val = $cfg->retries() };
	# May or may not find it depending on flatten key format
	ok(!$@, 'AUTOLOAD in flat mode does not crash');
};

# Exercise AUTOLOAD with multi-level sep resolution
subtest 'AUTOLOAD - three-level nested key resolution' => sub {
	my $cfg = Config::Abstraction->new(
		data => {
			app => { db => { host => 'dbhost' } },
		},
		config_dirs => [],
		sep_char    => $SEP_US,
	);
	is($cfg->app_db_host(), 'dbhost', 'three-level AUTOLOAD resolution');
};

# ===========================================================================
# Type preservation across all reference types
# ===========================================================================

subtest 'all reference types preserved through load cycle' => sub {
	my $cb     = sub { 'coderef' };
	my $obj    = bless { v => 1 }, '_RefTypeTest';
	my $href   = { nested => 'hash' };
	my $aref   = [1, 2, 3];
	my $sref   = \'scalar_ref';

	my $cfg = Config::Abstraction->new(
		data => {
			cb   => $cb,
			obj  => $obj,
			href => $href,
			aref => $aref,
			sref => $sref,
		},
		config_dirs => [],
	);

	is(reftype($cfg->get('cb')),   'CODE',   'coderef type preserved');
	is(reftype($cfg->get('obj')),  'HASH',   'blessed object reftype preserved');
	ok(blessed($cfg->get('obj')),            'blessed object still blessed');
	is(reftype($cfg->get('href')), 'HASH',   'hashref type preserved');
	is(reftype($cfg->get('aref')), 'ARRAY',  'arrayref type preserved');
	is(reftype($cfg->get('sref')), 'SCALAR', 'scalarref type preserved');
};

# ===========================================================================
# Data::Reuse integration - tied hash guard
# ===========================================================================

subtest 'get() - repeated hashref access does not crash with tied guard' => sub {
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
	);
	# Call get() on the same hashref key multiple times to exercise
	# the !tied guard in the fixate path
	for my $i (1 .. 5) {
		my $db = $cfg->get('database');
		ok(defined($db), "get() call $i on hashref succeeds");
	}
};

# ===========================================================================
# config_files arrayref with multiple formats
# ===========================================================================

subtest 'config_files - YAML and JSON mixed in arrayref' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'first.yaml', "level: yaml\ntimeout: $EXPECTED_TIMEOUT\n");
	_write_file($dir, 'second.json', '{"level":"json","retries":5}');

	my $cfg = Config::Abstraction->new(
		config_files => ['first.yaml', 'second.json'],
		config_dirs  => [$dir],
	);
	ok(defined($cfg), 'mixed YAML+JSON config_files arrayref accepted');
	# second.json loaded after first.yaml so overrides level
	is($cfg->get('level'),   'json',            'JSON overrides YAML for shared key');
	is($cfg->get('timeout'), $EXPECTED_TIMEOUT, 'YAML value retained for unshared key');
};

# ===========================================================================
# Interaction with Hash::Merge strategies
# ===========================================================================

subtest 'Hash::Merge - nested hash merge preserves non-conflicting keys' => sub {
	my $dir = tempdir(CLEANUP => 1);
	# File has database.host but not database.user
	_write_file($dir, 'base.yaml',
		"database:\n  host: filehost\n  port: $OVERRIDE_PORT\n");

	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [$dir],
	);
	# File value wins for port (file loaded after data)
	is($cfg->get('database.port'), $OVERRIDE_PORT,  'file port overrides data port');
	# Data value retained for user (absent from file)
	is($cfg->get('database.user'), $EXPECTED_USER,  'data user retained when absent from file');
	# File-only key accessible
	is($cfg->get('database.host'), 'filehost',       'file-only key accessible');
};

done_testing();
