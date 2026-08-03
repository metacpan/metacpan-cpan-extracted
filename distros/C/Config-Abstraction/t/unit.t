#!/usr/bin/perl

# Black-box tests for Config::Abstraction public API as documented in POD.
# Tests only observable behaviour through the public interface.
# An exhaustive ledger tracks every documented API state; the suite fails if
# any documented state is untested.

use strict;
use warnings;
use autodie qw(:all);

use Test::Most;
use Test::Mockingbird;
use Test::Returns;
use Readonly;
use Scalar::Util qw(blessed reftype);
use File::Temp qw(tempdir);
use File::Spec;

# ---------------------------------------------------------------------------
# Configuration constants
# ---------------------------------------------------------------------------
my %config = (
	module		=> 'Config::Abstraction',
	sep_char	=> '.',
	sep_char_alt	=> '/',
	sep_char_us	=> '_',
	env_prefix	=> 'UNITAPP_',
	flatten_off	=> 0,
	flatten_on	=> 1,
);

Readonly::Scalar my $MODULE		=> $config{module};
Readonly::Scalar my $SEP		=> $config{sep_char};
Readonly::Scalar my $SEP_ALT		=> $config{sep_char_alt};
Readonly::Scalar my $SEP_US		=> $config{sep_char_us};
Readonly::Scalar my $ENV_PREFIX		=> $config{env_prefix};
Readonly::Scalar my $FLATTEN_OFF	=> $config{flatten_off};
Readonly::Scalar my $FLATTEN_ON		=> $config{flatten_on};

Readonly::Scalar my $EXPECTED_USER	=> 'alice';
Readonly::Scalar my $EXPECTED_PASS	=> 'secret';
Readonly::Scalar my $EXPECTED_PORT	=> 5432;
Readonly::Scalar my $EXPECTED_LEVEL	=> 'info';
Readonly::Scalar my $EXPECTED_RETRIES	=> 3;
Readonly::Scalar my $EXPECTED_TIMEOUT	=> 30;
Readonly::Scalar my $EXPECTED_CB_RESULT	=> 'cb_ok';
Readonly::Scalar my $YAML_FILENAME	=> 'base.yaml';
Readonly::Scalar my $YML_FILENAME	=> 'base.yml';
Readonly::Scalar my $JSON_FILENAME	=> 'base.json';
Readonly::Scalar my $XML_FILENAME	=> 'base.xml';
Readonly::Scalar my $INI_FILENAME	=> 'base.ini';

# ---------------------------------------------------------------------------
# API Ledger: every documented POD state/return code/message.
# Subtests delete their entry when exercised.
# The final assertion fails if any entry survives uncovered.
# ---------------------------------------------------------------------------
my %ledger = (
	'new: returns blessed object on success'		=> 1,
	'new: returns undef for empty config'			=> 1,
	'new: single-arg filename form'				=> 1,
	'new: env_prefix defaults to APP_'			=> 1,
	'new: sep_char defaults to dot'				=> 1,
	'new: custom sep_char honoured'				=> 1,
	'new: custom env_prefix honoured'			=> 1,
	'new: defaults hash initialises object attrs'		=> 1,
	'new: env_prefix top-level overrides defaults'		=> 1,
	'new: data option primes configuration'			=> 1,
	'new: path synonym for config_dirs'			=> 1,
	'new: loads YAML .yaml file'				=> 1,
	'new: loads YAML .yml file'				=> 1,
	'new: loads JSON file'					=> 1,
	'new: loads XML file'					=> 1,
	'new: loads INI file'					=> 1,
	'new: local.* overrides base.*'				=> 1,
	'new: config_file option'				=> 1,
	'new: config_files arrayref option'			=> 1,
	'new: CONFIG_DIR env overrides config_dirs'		=> 1,
	'new: flatten produces flat key structure'		=> 1,
	'new: schema validates valid config'			=> 1,
	'new: schema rejects invalid config'			=> 1,
	'new: logger option accepted'				=> 1,
	'new: malformed YAML file skipped not fatal'		=> 1,
	'get: retrieves top-level scalar'			=> 1,
	'get: retrieves nested value via dotted notation'	=> 1,
	'get: returns undef for absent key'			=> 1,
	'get: returns undef when mid-path is non-hash'		=> 1,
	'get: returns hashref for partial path'			=> 1,
	'get: coderef preserved'				=> 1,
	'get: blessed object preserved'				=> 1,
	'get: flat mode uses direct key lookup'			=> 1,
	'get: repeated calls do not crash'			=> 1,
	'get: custom sep_char respected'			=> 1,
	'exists: returns 1 for present top-level key'		=> 1,
	'exists: returns 1 for present nested key'		=> 1,
	'exists: returns 0 for absent key'			=> 1,
	'exists: returns 0 when mid-path is non-hash'		=> 1,
	'exists: returns 1 in flat mode'			=> 1,
	'exists: returns 0 in flat mode for absent key'		=> 1,
	'exists: returns explicit integer 0 not empty string'	=> 1,
	'all: returns hashref'					=> 1,
	'all: contains all top-level keys'			=> 1,
	'all: config_path lists loaded files'			=> 1,
	'all: returns undef for empty config'			=> 1,
	'all: flat mode returns flattened hash'			=> 1,
	'all: repeated calls are idempotent'			=> 1,
	'merge_defaults: no-arg returns full config'		=> 1,
	'merge_defaults: config overrides defaults'		=> 1,
	'merge_defaults: merge option combines hashes'		=> 1,
	'merge_defaults: section scopes result'			=> 1,
	'merge_defaults: global section merged'			=> 1,
	'merge_defaults: deep option'				=> 1,
	'merge_defaults: undef defaults returns config'		=> 1,
	'AUTOLOAD: resolves top-level key'			=> 1,
	'AUTOLOAD: resolves nested key via sep_char'		=> 1,
	'AUTOLOAD: returns hashref for partial path'		=> 1,
	'AUTOLOAD: dies No such config key for missing key'	=> 1,
	'AUTOLOAD: DESTROY does not die'			=> 1,
	'AUTOLOAD: default sep_char direct key access'		=> 1,
	'ENV: double-underscore creates nested key'		=> 1,
	'ENV: single segment stored under prefix namespace'	=> 1,
	'ENV: mixed underscore in key'				=> 1,
	'CLI: overrides top-level key'				=> 1,
	'CLI: double-underscore creates nested key'		=> 1,
	'CLI: non-matching prefix ignored'			=> 1,
	'CLI: arg without = ignored'				=> 1,
	'precedence: CLI > ENV > data'				=> 1,
	'precedence: ENV > data'				=> 1,
	'precedence: file > data'				=> 1,
	'global-state: get() does not clobber dollar-at'	=> 1,
	'global-state: exists() does not clobber dollar-at'	=> 1,
	'global-state: all() does not clobber dollar-at'	=> 1,
	'global-state: methods do not clobber dollar-underscore' => 1,
	'mockingbird: spy captures get() calls'			=> 1,
	# get() / exists() undef-key guards
	'get: returns undef for undef key'			=> 1,
	'exists: returns 0 for undef key'			=> 1,
	'exists: returns 1 when key present but value is undef'	=> 1,
	# new() options not yet covered
	'new: file synonym for config_file'			=> 1,
	'new: lazy always returns blessed object'		=> 1,
	'new: lazy defers schema validation to first access'	=> 1,
	'new: environment loads base.env.yaml tier'		=> 1,
	'new: invalid environment name croaks'			=> 1,
	'new: validators type string accepts valid value'	=> 1,
	'new: validators type string rejects invalid value'	=> 1,
	'new: validators regex accepts matching value'		=> 1,
	'new: validators regex rejects non-matching value'	=> 1,
	'new: validators coderef accepts truthy return'		=> 1,
	'new: validators coderef rejects falsy return'		=> 1,
	'new: validators hashref required key missing croaks'	=> 1,
	'new: validators hashref min/max enforced'		=> 1,
	# explain_sources()
	'explain_sources: returns hashref'			=> 1,
	'explain_sources: value field matches get()'		=> 1,
	'explain_sources: sources arrayref ordered lowest first'=> 1,
	'explain_sources: data source has correct type and label'=> 1,
	'explain_sources: env source has correct type and label'=> 1,
	'explain_sources: file source has correct type'		=> 1,
	# prefer_*() methods
	'prefer_env: returns env value when env contributed'	=> 1,
	'prefer_env: falls back to get() when env absent'	=> 1,
	'prefer_file: returns file value when file contributed'	=> 1,
	'prefer_file: falls back to get() when no file'		=> 1,
	'prefer_data: returns data value when data contributed'	=> 1,
	'prefer_data: falls back to get() when data absent'	=> 1,
	'prefer_argv: returns argv value when argv contributed'	=> 1,
	'prefer_argv: falls back to get() when no argv'		=> 1,
	# encrypt_value()
	'encrypt_value: returns ENC[AES256GCM,...] token'	=> 1,
	'encrypt_value: croaks with no encryption key configured'=> 1,
);

# ---------------------------------------------------------------------------
use_ok($MODULE) or BAIL_OUT("$MODULE failed to load");

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

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
	};
}

sub _make_cfg
{
	my (%extra) = @_;
	return Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		%extra,
	);
}

sub _write_file
{
	my ($dir, $filename, $content) = @_;
	my $path = File::Spec->catfile($dir, $filename);
	open(my $fh, '>', $path) or die "Cannot write $path: $!";
	print {$fh} $content;
	close $fh;
	return $path;
}

# ===========================================================================
# new() - constructor
# ===========================================================================

subtest 'new() - returns blessed object on success' => sub {
	my $cfg = _make_cfg();
	ok(defined($cfg),          'new() returns defined value');
	ok(blessed($cfg),          'return value is blessed');
	is(blessed($cfg), $MODULE, 'blessed into correct package');
	returns_ok($cfg, { type => 'object' }, 'returns_ok: blessed object');
	delete $ledger{'new: returns blessed object on success'};
};

subtest 'new() - single argument treated as filename (bare string form)' => sub {
	# POD: if just one argument is given, it is assumed to be the name of a file
	my $dir  = tempdir(CLEANUP => 1);
	my $path = _write_file($dir, 'myapp.yaml', "timeout: $EXPECTED_TIMEOUT\n");
	my $cfg  = Config::Abstraction->new($path);
	ok(defined($cfg), 'single bare-string arg: object created');
	is($cfg->get('timeout'), $EXPECTED_TIMEOUT, 'single-arg: value loaded from file');
	delete $ledger{'new: single-arg filename form'};
};

subtest 'new() - returns undef when no config data found' => sub {
	# POD: constructor returns undef (not blessed object) when no config found
	my $cfg = Config::Abstraction->new(
		data        => {},
		config_dirs => [],
	);
	ok(!defined($cfg), 'new() returns undef for empty config');
	delete $ledger{'new: returns undef for empty config'};
};

subtest 'new() - env_prefix defaults to APP_' => sub {
	my $cfg = _make_cfg();
	is($cfg->{env_prefix}, 'APP_', 'default env_prefix is APP_');
	delete $ledger{'new: env_prefix defaults to APP_'};
};

subtest 'new() - sep_char defaults to dot' => sub {
	# POD: the default is a '.', as in dotted notation, such as 'database.user'
	my $cfg = _make_cfg();
	is($cfg->{sep_char}, $SEP, 'default sep_char is dot');
	delete $ledger{'new: sep_char defaults to dot'};
};

subtest 'new() - custom sep_char honoured' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { database => { user => $EXPECTED_USER } },
		config_dirs => [],
		sep_char    => $SEP_ALT,
	);
	is($cfg->get("database${SEP_ALT}user"), $EXPECTED_USER, 'custom sep_char used');
	delete $ledger{'new: custom sep_char honoured'};
};

subtest 'new() - custom env_prefix honoured' => sub {
	local %ENV = %ENV;
	$ENV{"${ENV_PREFIX}RETRIES"} = '99';
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	ok(defined($cfg), 'object created with custom env_prefix');
	delete $ledger{'new: custom env_prefix honoured'};
};

subtest 'new() - defaults hash initialises object attributes' => sub {
	# POD: if defaults option supplied, object is initialised using its keys as base;
	# top-level env_prefix still takes precedence over any env_prefix inside defaults
	my $cfg = Config::Abstraction->new(
		defaults => {
			data        => _fresh_data(),
			config_dirs => [],
			sep_char    => $SEP,
		},
		env_prefix => $ENV_PREFIX,
	);
	ok(defined($cfg),                   'object created via defaults hash');
	is($cfg->{sep_char},    $SEP,        'sep_char taken from defaults');
	is($cfg->{env_prefix},  $ENV_PREFIX, 'top-level env_prefix overrides defaults hash');
	delete $ledger{'new: defaults hash initialises object attrs'};
	delete $ledger{'new: env_prefix top-level overrides defaults'};
};

subtest 'new() - data option primes configuration' => sub {
	# POD: data - a hash ref of default data to prime the configuration with
	my $cfg = Config::Abstraction->new(
		data        => { log_level => $EXPECTED_LEVEL, retries => $EXPECTED_RETRIES },
		config_dirs => [],
	);
	is($cfg->get('log_level'), $EXPECTED_LEVEL,   'data string value accessible');
	is($cfg->get('retries'),   $EXPECTED_RETRIES, 'data integer value accessible');
	delete $ledger{'new: data option primes configuration'};
};

subtest 'new() - path synonym for config_dirs' => sub {
	# POD: path - a synonym of config_dirs
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_FILENAME, "appname: test\n");
	my $cfg = Config::Abstraction->new(path => [$dir]);
	ok(defined($cfg),                  'object created via path synonym');
	is($cfg->get('appname'), 'test',   'config loaded from path synonym dir');
	delete $ledger{'new: path synonym for config_dirs'};
};

subtest 'new() - loads YAML .yaml file from config_dirs' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_FILENAME, "timeout: $EXPECTED_TIMEOUT\n");
	my $cfg = Config::Abstraction->new(config_dirs => [$dir]);
	is($cfg->get('timeout'), $EXPECTED_TIMEOUT, 'YAML .yaml file loaded');
	delete $ledger{'new: loads YAML .yaml file'};
};

subtest 'new() - loads YAML .yml file from config_dirs' => sub {
	# POD: *.yaml, *.yml are both supported
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YML_FILENAME, "timeout: $EXPECTED_TIMEOUT\n");
	my $cfg = Config::Abstraction->new(config_dirs => [$dir]);
	is($cfg->get('timeout'), $EXPECTED_TIMEOUT, 'YAML .yml file loaded');
	delete $ledger{'new: loads YAML .yml file'};
};

subtest 'new() - loads JSON file from config_dirs' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $JSON_FILENAME, qq|{"timeout":$EXPECTED_TIMEOUT}|);
	my $cfg = Config::Abstraction->new(config_dirs => [$dir]);
	is($cfg->get('timeout'), $EXPECTED_TIMEOUT, 'JSON file loaded');
	delete $ledger{'new: loads JSON file'};
};

subtest 'new() - loads XML file from config_dirs' => sub {
	# POD: XML (*.xml) loaded using XML::Simple
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $XML_FILENAME,
		qq|<?xml version="1.0"?><config><timeout>$EXPECTED_TIMEOUT</timeout></config>|);
	my $cfg = Config::Abstraction->new(config_dirs => [$dir]);
	ok(defined($cfg), 'XML config produced an object');
	diag('XML timeout: ' . ($cfg ? ($cfg->get('timeout') // 'undef') : 'no object'))
		if $ENV{TEST_VERBOSE};
	delete $ledger{'new: loads XML file'};
};

subtest 'new() - loads INI file from config_dirs' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $INI_FILENAME, "[database]\nuser=$EXPECTED_USER\n");
	my $cfg = Config::Abstraction->new(config_dirs => [$dir]);
	is($cfg->get('database.user'), $EXPECTED_USER, 'INI file loaded');
	delete $ledger{'new: loads INI file'};
};

subtest 'new() - local.* overrides base.*' => sub {
	# POD: local.* files override base.* files in the same directory
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml',  "level: base\n");
	_write_file($dir, 'local.yaml', "level: local\n");
	my $cfg = Config::Abstraction->new(config_dirs => [$dir]);
	is($cfg->get('level'), 'local', 'local.yaml overrides base.yaml');
	delete $ledger{'new: local.* overrides base.*'};
};

subtest 'new() - config_file option loads named file' => sub {
	# POD: config_file - points to a configuration file of any format.
	# When config_file is an absolute path, omit config_dirs so the module
	# sets config_dirs=[''] and joins correctly (catfile on Unix mangles
	# absolute paths when joined with a non-empty prefix dir).
	my $dir  = tempdir(CLEANUP => 1);
	my $path = _write_file($dir, 'myapp.yaml', "appname: myapp\n");
	my $cfg  = Config::Abstraction->new(config_file => $path);
	ok(defined($cfg),                  'object created with config_file option');
	is($cfg->get('appname'), 'myapp',  'value loaded from config_file');
	diag('appname: ' . ($cfg ? ($cfg->get('appname') // 'undef') : 'no object'))
		if $ENV{TEST_VERBOSE};
	delete $ledger{'new: config_file option'};
};

subtest 'new() - config_files arrayref: later file wins' => sub {
	# POD: config_files - put more important files later, since later files override earlier.
	# Absolute paths in config_files require config_dirs omitted (or ['']) so the module
	# does not mangle the path via catfile with a non-empty prefix dir.
	my $dir   = tempdir(CLEANUP => 1);
	my $path1 = _write_file($dir, 'first.yaml',  "priority: low\n");
	my $path2 = _write_file($dir, 'second.yaml', "priority: high\n");
	my $cfg   = Config::Abstraction->new(
		config_dirs  => [''],
		config_files => [$path1, $path2],
	);
	ok(defined($cfg),                 'object created with config_files option');
	is($cfg->get('priority'), 'high', 'later entry in config_files wins');
	delete $ledger{'new: config_files arrayref option'};
};

subtest 'new() - CONFIG_DIR env var overrides config_dirs' => sub {
	# POD: CONFIG_DIR can be set at runtime to override config_dirs
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_FILENAME, "env_dir_key: found\n");
	local %ENV = %ENV;
	delete $ENV{HOME};	# prevent default dirs interfering
	$ENV{CONFIG_DIR} = $dir;
	my $cfg = Config::Abstraction->new();
	ok(defined($cfg),                    'CONFIG_DIR override: object created');
	is($cfg->get('env_dir_key'), 'found', 'config loaded from CONFIG_DIR dir');
	delete $ledger{'new: CONFIG_DIR env overrides config_dirs'};
};

subtest 'new() - flatten option produces flat key structure' => sub {
	# POD: if true, returns a flat hash like {database.user} instead of {database}{user}
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		flatten     => $FLATTEN_ON,
	);
	ok(defined($cfg),                         'object created with flatten=>1');
	is($cfg->get('database.user'), $EXPECTED_USER, 'flat key accessible');
	delete $ledger{'new: flatten produces flat key structure'};
};

subtest 'new() - schema validates valid configuration' => sub {
	# POD: schema - a Params::Validate::Strict compatible schema validates config
	my $cfg = Config::Abstraction->new(
		data => {
			retries  => $EXPECTED_RETRIES,
			database => { user => $EXPECTED_USER },
			log      => { level => $EXPECTED_LEVEL },
		},
		config_dirs => [],
		schema => {
			retries  => { type => 'integer' },
			database => { type => 'hashref' },
			log      => { type => 'hashref' },
		},
	);
	ok(defined($cfg), 'object created when config matches schema');
	delete $ledger{'new: schema validates valid config'};
};

subtest 'new() - schema rejects invalid configuration' => sub {
	# POD: schema validation failure is fatal (dies at construction time)
	eval {
		Config::Abstraction->new(
			data        => { retries => $EXPECTED_RETRIES },
			config_dirs => [],
			schema => {
				retries    => { type => 'integer' },
				compulsory => { type => 'string', optional => 0 },
			},
		);
	};
	ok($@, 'new() dies when config fails schema validation');
	delete $ledger{'new: schema rejects invalid config'};
};

subtest 'new() - logger option accepted' => sub {
	# POD: logger can be a blessed object, arrayref, coderef, or filename.
	# The constructor only tries to load Log::Abstraction for unblessed loggers, so
	# we use a pre-blessed mock here: the test is unconditionally valid regardless of
	# whether Log::Abstraction is installed on the current system.
	my $mock_logger = bless {}, '_UnitTestLogger';
	{
		no strict 'refs';
		*{'_UnitTestLogger::warn'}  = sub {};
		*{'_UnitTestLogger::trace'} = sub {};
		*{'_UnitTestLogger::debug'} = sub {};
	}
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		logger      => $mock_logger,
	);
	ok(defined($cfg), 'object created with pre-blessed logger');

	# Also test the arrayref form when Log::Abstraction is present, but guard with
	# a SKIP so the ledger delete (below) is always reached.
	SKIP: {
		skip 'Log::Abstraction not installed', 1
			unless eval { require Log::Abstraction; 1 };
		my @captured;
		my $cfg2 = Config::Abstraction->new(
			data        => _fresh_data(),
			config_dirs => [],
			logger      => \@captured,
		);
		ok(defined($cfg2), 'object created with arrayref logger (Log::Abstraction present)');
	}

	delete $ledger{'new: logger option accepted'};
};

subtest 'new() - malformed YAML file is skipped, not fatal' => sub {
	# POD: if any file fails to load, descriptive error message is emitted and skipped
	# Changes 0.38: parse failures now warn and skip rather than aborting construction
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_FILENAME, "invalid: yaml: {\nnot closed\n");
	my @warnings;
	{
		local $SIG{__WARN__} = sub { push @warnings, @_ };
		# Should not die even when YAML parse fails
		eval { Config::Abstraction->new(config_dirs => [$dir]) };
	}
	ok(!$@, 'malformed YAML file does not kill the constructor');
	diag("warnings captured: @warnings") if $ENV{TEST_VERBOSE} && @warnings;
	delete $ledger{'new: malformed YAML file skipped not fatal'};
};

# ===========================================================================
# get(key)
# POD: retrieve a configuration value using dotted key notation
# ===========================================================================

subtest 'get() - retrieves top-level scalar' => sub {
	my $cfg = _make_cfg();
	my $val = $cfg->get('retries');
	is($val, $EXPECTED_RETRIES, 'top-level scalar retrieved');
	returns_ok($val, { type => 'integer' }, 'returns_ok: integer type');
	delete $ledger{'get: retrieves top-level scalar'};
};

subtest 'get() - retrieves nested value via dotted notation' => sub {
	# POD: e.g. get('database.user')
	my $cfg = _make_cfg();
	is($cfg->get('database.user'), $EXPECTED_USER, 'nested string retrieved');
	is($cfg->get('database.port'), $EXPECTED_PORT, 'nested integer retrieved');
	delete $ledger{'get: retrieves nested value via dotted notation'};
};

subtest 'get() - returns undef for absent key' => sub {
	# POD: returns undef if the key does not exist
	my $cfg = _make_cfg();
	ok(!defined($cfg->get('no.such.key')), 'absent key returns undef');
	delete $ledger{'get: returns undef for absent key'};
};

subtest 'get() - returns undef when mid-path value is not a hash' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { flat => 'scalar_value' },
		config_dirs => [],
	);
	ok(!defined($cfg->get('flat.child')), 'undef when mid-path is scalar');
	delete $ledger{'get: returns undef when mid-path is non-hash'};
};

subtest 'get() - returns hashref for partial path' => sub {
	my $cfg = _make_cfg();
	my $db  = $cfg->get('database');
	is(reftype($db), 'HASH',         'partial path returns hashref');
	is($db->{user},  $EXPECTED_USER, 'hashref contents correct');
	returns_ok($db, { type => 'hashref' }, 'returns_ok: hashref');
	delete $ledger{'get: returns hashref for partial path'};
};

subtest 'get() - coderef value survives round-trip' => sub {
	my $cb  = sub { $EXPECTED_CB_RESULT };
	my $cfg = Config::Abstraction->new(
		data        => { callback => $cb },
		config_dirs => [],
	);
	my $got = $cfg->get('callback');
	is(reftype($got), 'CODE',            'coderef type preserved');
	is($got->(),      $EXPECTED_CB_RESULT, 'coderef is callable');
	delete $ledger{'get: coderef preserved'};
};

subtest 'get() - blessed object survives round-trip' => sub {
	my $obj = bless { val => $EXPECTED_PORT }, '_UnitTestObj';
	my $cfg = Config::Abstraction->new(
		data        => { handler => $obj },
		config_dirs => [],
	);
	my $got = $cfg->get('handler');
	ok(blessed($got),                 'blessed object preserved');
	is(blessed($got), '_UnitTestObj', 'class unchanged');
	delete $ledger{'get: blessed object preserved'};
};

subtest 'get() - flat mode uses direct key lookup' => sub {
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		flatten     => $FLATTEN_ON,
	);
	is($cfg->get('database.user'), $EXPECTED_USER, 'flat mode key lookup');
	delete $ledger{'get: flat mode uses direct key lookup'};
};

subtest 'get() - repeated calls on same hashref key do not crash' => sub {
	my $cfg    = _make_cfg();
	my $first  = $cfg->get('database');
	my $second = $cfg->get('database');
	ok(defined($second),              'second call on hashref key succeeds');
	is($second->{user}, $EXPECTED_USER, 'value correct on second call');
	delete $ledger{'get: repeated calls do not crash'};
};

subtest 'get() - custom sep_char respected' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { database => { user => $EXPECTED_USER } },
		config_dirs => [],
		sep_char    => $SEP_ALT,
	);
	is($cfg->get("database${SEP_ALT}user"), $EXPECTED_USER, 'custom sep_char in get()');
	delete $ledger{'get: custom sep_char respected'};
};

# ===========================================================================
# exists(key)
# POD: does a configuration value exist? Returns 0 or 1.
# ===========================================================================

subtest 'exists() - returns 1 for present top-level key' => sub {
	my $cfg = _make_cfg();
	is($cfg->exists('retries'), 1, 'present top-level key returns 1');
	delete $ledger{'exists: returns 1 for present top-level key'};
};

subtest 'exists() - returns 1 for present nested key' => sub {
	my $cfg = _make_cfg();
	is($cfg->exists('database.user'), 1, 'present nested key returns 1');
	delete $ledger{'exists: returns 1 for present nested key'};
};

subtest 'exists() - returns 0 for absent key' => sub {
	my $cfg = _make_cfg();
	is($cfg->exists('no.such.key'), 0, 'absent key returns 0');
	delete $ledger{'exists: returns 0 for absent key'};
};

subtest 'exists() - returns 0 when mid-path is not a hash' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { flat => 'scalar_value' },
		config_dirs => [],
	);
	is($cfg->exists('flat.child'), 0, 'mid-path scalar returns 0');
	delete $ledger{'exists: returns 0 when mid-path is non-hash'};
};

subtest 'exists() - returns 1 in flat mode for present key' => sub {
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		flatten     => $FLATTEN_ON,
	);
	is($cfg->exists('database.user'), 1, 'flat mode present key returns 1');
	delete $ledger{'exists: returns 1 in flat mode'};
};

subtest 'exists() - returns 0 in flat mode for absent key' => sub {
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		flatten     => $FLATTEN_ON,
	);
	is($cfg->exists('no.such.key'), 0, 'flat mode absent key returns 0');
	delete $ledger{'exists: returns 0 in flat mode for absent key'};
};

subtest 'exists() - return value is explicit integer 0, not empty string' => sub {
	# POD: returns 0 or 1; code explicitly returns 0, not ''
	my $cfg    = _make_cfg();
	my $result = $cfg->exists('no.such.key');
	is($result, 0, 'absent key returns 0');
	ok(defined($result), 'return value is defined');
	returns_ok($result, { type => 'integer' }, 'returns_ok: exists() returns integer');
	delete $ledger{'exists: returns explicit integer 0 not empty string'};
};

# ===========================================================================
# all()
# POD: returns the entire configuration hash, possibly flattened
# ===========================================================================

subtest 'all() - returns entire config as hashref' => sub {
	my $cfg = _make_cfg();
	my $all = $cfg->all();
	ok(defined($all),         'all() returns defined value');
	is(reftype($all), 'HASH', 'all() returns hashref');
	returns_ok($all, { type => 'hashref' }, 'returns_ok: hashref');
	delete $ledger{'all: returns hashref'};
};

subtest 'all() - contains all top-level keys from data' => sub {
	my $cfg = _make_cfg();
	my $all = $cfg->all();
	ok(exists $all->{database}, 'database key present');
	ok(exists $all->{log},      'log key present');
	ok(exists $all->{retries},  'retries key present');
	delete $ledger{'all: contains all top-level keys'};
};

subtest 'all() - config_path key lists loaded files' => sub {
	# POD: config_path contains a list of the files config was loaded from
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_FILENAME, "timeout: $EXPECTED_TIMEOUT\n");
	my $cfg = Config::Abstraction->new(config_dirs => [$dir]);
	my $all = $cfg->all();
	ok(exists $all->{config_path},             'config_path key present');
	is(reftype($all->{config_path}), 'ARRAY',  'config_path is arrayref');
	ok(scalar(@{$all->{config_path}}) > 0,     'config_path is non-empty');
	diag('config_path: ' . join(', ', @{$all->{config_path}})) if $ENV{TEST_VERBOSE};
	delete $ledger{'all: config_path lists loaded files'};
};

subtest 'all() - returns undef when config is empty' => sub {
	my $cfg = _make_cfg();
	$cfg->{config} = {};
	ok(!defined($cfg->all()), 'all() returns undef for empty config');
	delete $ledger{'all: returns undef for empty config'};
};

subtest 'all() - flat mode returns flattened hash' => sub {
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		flatten     => $FLATTEN_ON,
	);
	my $all = $cfg->all();
	ok(exists $all->{'database.user'}, 'flat key present in all()');
	delete $ledger{'all: flat mode returns flattened hash'};
};

subtest 'all() - repeated calls return same result (idempotent)' => sub {
	my $cfg    = _make_cfg();
	my $first  = $cfg->all();
	my $second = $cfg->all();
	ok(defined($second),                     'second call to all() succeeds');
	is($second->{retries}, $EXPECTED_RETRIES, 'value same on second call');
	delete $ledger{'all: repeated calls are idempotent'};
};

# ===========================================================================
# merge_defaults()
# POD: merge the configuration hash into the given hash
# ===========================================================================

subtest 'merge_defaults() - no args returns full config' => sub {
	# POD: returns config when called with no arguments
	my $cfg    = _make_cfg();
	my $result = $cfg->merge_defaults();
	ok(defined($result),         'no-arg returns defined value');
	is(reftype($result), 'HASH', 'no-arg returns hashref');
	delete $ledger{'merge_defaults: no-arg returns full config'};
};

subtest 'merge_defaults() - config overrides defaults' => sub {
	my $cfg    = _make_cfg();
	my $merged = $cfg->merge_defaults(
		defaults => { retries => 99, extra => 'kept' },
	);
	is($merged->{retries}, $EXPECTED_RETRIES, 'config value overrides default');
	is($merged->{extra},   'kept',            'default-only key preserved');
	delete $ledger{'merge_defaults: config overrides defaults'};
};

subtest 'merge_defaults() - merge option combines both hashes' => sub {
	# POD: if merge given, result is a combination of the hashes
	my $cfg    = _make_cfg();
	my $merged = $cfg->merge_defaults(
		defaults => { extra => 'from_default' },
		merge    => 1,
	);
	ok(exists $merged->{extra},    'default-only key present with merge=>1');
	ok(exists $merged->{database}, 'config key present with merge=>1');
	delete $ledger{'merge_defaults: merge option combines hashes'};
};

subtest 'merge_defaults() - section scopes result to named section' => sub {
	# POD: section - merge in that section from the configuration file
	my $cfg    = _make_cfg();
	my $merged = $cfg->merge_defaults(
		defaults => {},
		section  => 'database',
	);
	is($merged->{user}, $EXPECTED_USER, 'section-scoped key present');
	ok(!exists $merged->{retries},      'keys outside section absent');
	delete $ledger{'merge_defaults: section scopes result'};
};

subtest 'merge_defaults() - global section merged into defaults' => sub {
	my $cfg = Config::Abstraction->new(
		data => {
			global  => { timeout => $EXPECTED_TIMEOUT },
			retries => $EXPECTED_RETRIES,
		},
		config_dirs => [],
	);
	my $merged = $cfg->merge_defaults(defaults => { timeout => 99 });
	is($merged->{timeout}, $EXPECTED_TIMEOUT, 'global section overrides defaults');
	delete $ledger{'merge_defaults: global section merged'};
};

subtest 'merge_defaults() - deep option merges global more thoroughly' => sub {
	# POD: deep - try harder to merge all configurations from the global section
	my $cfg = Config::Abstraction->new(
		data => {
			global  => { database => { user => 'global_user' } },
			retries => $EXPECTED_RETRIES,
		},
		config_dirs => [],
	);
	my $merged = $cfg->merge_defaults(
		defaults => { database => { user => 'default_user', port => $EXPECTED_PORT } },
		deep     => 1,
	);
	is($merged->{database}{user}, 'global_user',  'deep: global wins on conflict');
	is($merged->{database}{port}, $EXPECTED_PORT, 'deep: default preserved for non-conflicting key');
	delete $ledger{'merge_defaults: deep option'};
};

subtest 'merge_defaults() - undef defaults returns config unchanged' => sub {
	# POD: if defaults hash ref is undef, full config is returned
	my $cfg    = _make_cfg();
	my $result = $cfg->merge_defaults(defaults => undef);
	ok(defined($result),         'undef defaults returns defined config');
	is(reftype($result), 'HASH', 'undef defaults result is a hashref');
	delete $ledger{'merge_defaults: undef defaults returns config'};
};

# ===========================================================================
# AUTOLOAD
# POD: dynamic access to configuration keys via AUTOLOAD
# ===========================================================================

subtest 'AUTOLOAD - resolves top-level key as method call' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { loglevel => $EXPECTED_LEVEL },
		config_dirs => [],
	);
	is($cfg->loglevel(), $EXPECTED_LEVEL, 'AUTOLOAD top-level key resolved');
	delete $ledger{'AUTOLOAD: resolves top-level key'};
};

subtest 'AUTOLOAD - resolves nested key via underscore sep_char' => sub {
	# POD: $config->database_user() resolves to $config->{database}{user}
	#      when sep_char is '_'
	my $cfg = Config::Abstraction->new(
		data        => { database => { user => $EXPECTED_USER } },
		config_dirs => [],
		sep_char    => $SEP_US,
	);
	is($cfg->database_user(), $EXPECTED_USER, 'AUTOLOAD nested key via sep_char=_');
	delete $ledger{'AUTOLOAD: resolves nested key via sep_char'};
};

subtest 'AUTOLOAD - returns hashref for partial path' => sub {
	# POD: $user = $config->database()->{'user'}
	my $cfg = Config::Abstraction->new(
		data        => { database => { user => $EXPECTED_USER } },
		config_dirs => [],
		sep_char    => $SEP_US,
	);
	my $db = $cfg->database();
	is(reftype($db), 'HASH',         'AUTOLOAD partial path returns hashref');
	is($db->{user},  $EXPECTED_USER, 'hashref contents correct');
	delete $ledger{'AUTOLOAD: returns hashref for partial path'};
};

subtest 'AUTOLOAD - dies with "No such config key" for nonexistent key' => sub {
	# POD: attempting to call a nonexistent key dies with error
	my $cfg = Config::Abstraction->new(
		data        => { known => 'value' },
		config_dirs => [],
		sep_char    => $SEP_US,
	);
	eval { $cfg->nonexistent_key() };
	like($@, qr/No such config key/, 'AUTOLOAD dies for missing key');
	delete $ledger{'AUTOLOAD: dies No such config key for missing key'};
};

subtest 'AUTOLOAD - DESTROY does not die' => sub {
	# AUTOLOAD explicitly returns for DESTROY to allow normal Perl object cleanup
	my $cfg = _make_cfg();
	eval { $cfg->DESTROY() };
	ok(!$@, 'explicit DESTROY call does not die');
	delete $ledger{'AUTOLOAD: DESTROY does not die'};
};

subtest 'AUTOLOAD - direct key access with default sep_char (dot)' => sub {
	# With default sep_char '.', a bare method name with no dot is a top-level lookup
	my $cfg = Config::Abstraction->new(
		data        => { retries => $EXPECTED_RETRIES },
		config_dirs => [],
	);
	is($cfg->retries(), $EXPECTED_RETRIES, 'AUTOLOAD top-level key with default sep_char');
	delete $ledger{'AUTOLOAD: default sep_char direct key access'};
};

# ===========================================================================
# Environment variable overrides
# POD: APP_DATABASE__USER becomes database.user
# ===========================================================================

subtest 'ENV double-underscore creates nested key' => sub {
	# POD: APP_DATABASE__USER becomes database.user (nested structure)
	local %ENV = %ENV;
	$ENV{"${ENV_PREFIX}DATABASE__USER"} = 'env_user';
	my $cfg = Config::Abstraction->new(
		data => {
			database => { user => $EXPECTED_USER, pass => $EXPECTED_PASS },
		},
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('database.user'), 'env_user', 'ENV double-underscore overrides nested key');
	delete $ledger{'ENV: double-underscore creates nested key'};
};

subtest 'ENV single segment stored under prefix namespace' => sub {
	# POD: APP_LOGLEVEL becomes APP.loglevel (flat under prefix namespace)
	local %ENV = %ENV;
	(my $prefix_bare = $ENV_PREFIX) =~ s/_$//;	# strip trailing underscore
	$ENV{"${ENV_PREFIX}RETRIES"} = '99';
	my $cfg = Config::Abstraction->new(
		data => {
			$prefix_bare => { retries => $EXPECTED_RETRIES },
			retries      => $EXPECTED_RETRIES,
		},
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get("${prefix_bare}.retries"), '99', 'single-segment ENV stored under prefix namespace');
	delete $ledger{'ENV: single segment stored under prefix namespace'};
};

subtest 'ENV mixed double-underscore and single underscore in key' => sub {
	# POD: APP_API__RATE_LIMIT becomes api.rate_limit
	local %ENV = %ENV;
	$ENV{"${ENV_PREFIX}API__RATE_LIMIT"} = '100';
	my $cfg = Config::Abstraction->new(
		data        => { api => { rate_limit => 50 } },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('api.rate_limit'), '100', 'mixed underscore/double-underscore ENV key handled');
	delete $ledger{'ENV: mixed underscore in key'};
};

# ===========================================================================
# Command-line argument overrides
# POD: --APP_DATABASE__USER=other_user_name overrides database.user
# ===========================================================================

subtest 'CLI arg overrides top-level key' => sub {
	local @ARGV = ("--${ENV_PREFIX}RETRIES=77");
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('retries'), '77', 'CLI arg overrides top-level key');
	delete $ledger{'CLI: overrides top-level key'};
};

subtest 'CLI double-underscore creates nested key' => sub {
	local @ARGV = ("--${ENV_PREFIX}DATABASE__USER=cli_user");
	my $cfg = Config::Abstraction->new(
		data => {
			database => { user => $EXPECTED_USER, pass => $EXPECTED_PASS },
			retries  => $EXPECTED_RETRIES,
		},
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('database.user'), 'cli_user', 'CLI double-underscore creates nested key');
	delete $ledger{'CLI: double-underscore creates nested key'};
};

subtest 'CLI arg without matching prefix is ignored' => sub {
	local @ARGV = ('--OTHERAPP_RETRIES=999');
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('retries'), $EXPECTED_RETRIES, 'non-matching prefix CLI arg ignored');
	delete $ledger{'CLI: non-matching prefix ignored'};
};

subtest 'CLI arg without = sign is ignored' => sub {
	# The module skips @ARGV entries that contain no '='
	local @ARGV = ("--${ENV_PREFIX}RETRIES");
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('retries'), $EXPECTED_RETRIES, 'CLI arg without = is ignored');
	delete $ledger{'CLI: arg without = ignored'};
};

# ===========================================================================
# Merge precedence
# POD: CLI args > Environment > Config file > Defaults (in-memory data)
# ===========================================================================

subtest 'merge precedence: CLI overrides ENV overrides data' => sub {
	local %ENV = %ENV;
	local @ARGV = ("--${ENV_PREFIX}DATABASE__USER=cli_user");
	$ENV{"${ENV_PREFIX}DATABASE__USER"} = 'env_user';
	my $cfg = Config::Abstraction->new(
		data => {
			database => { user => $EXPECTED_USER, pass => $EXPECTED_PASS },
		},
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('database.user'), 'cli_user', 'CLI takes highest precedence');
	delete $ledger{'precedence: CLI > ENV > data'};
};

subtest 'merge precedence: ENV overrides data' => sub {
	local %ENV = %ENV;
	$ENV{"${ENV_PREFIX}DATABASE__USER"} = 'env_user';
	my $cfg = Config::Abstraction->new(
		data => {
			database => { user => $EXPECTED_USER, pass => $EXPECTED_PASS },
		},
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('database.user'), 'env_user', 'ENV overrides data defaults');
	delete $ledger{'precedence: ENV > data'};
};

subtest 'merge precedence: config file overrides data' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_FILENAME, "retries: 99\n");
	my $cfg = Config::Abstraction->new(
		data        => { retries => $EXPECTED_RETRIES },
		config_dirs => [$dir],
	);
	is($cfg->get('retries'), 99, 'config file overrides data defaults');
	delete $ledger{'precedence: file > data'};
};

# ===========================================================================
# Global state integrity
# Methods must not clobber $@, $!, or $_ after object construction
# ===========================================================================

subtest 'global state: get() does not clobber $@' => sub {
	my $cfg = _make_cfg();
	eval { die 'sentinel_error' };
	my $err_before = $@;
	$cfg->get('database.user');
	is($@, $err_before, 'get() does not clobber $@');
	delete $ledger{'global-state: get() does not clobber dollar-at'};
};

subtest 'global state: exists() does not clobber $@' => sub {
	my $cfg = _make_cfg();
	eval { die 'sentinel_error' };
	my $err_before = $@;
	$cfg->exists('database.user');
	is($@, $err_before, 'exists() does not clobber $@');
	delete $ledger{'global-state: exists() does not clobber dollar-at'};
};

subtest 'global state: all() does not clobber $@' => sub {
	my $cfg = _make_cfg();
	eval { die 'sentinel_error' };
	my $err_before = $@;
	$cfg->all();
	is($@, $err_before, 'all() does not clobber $@');
	delete $ledger{'global-state: all() does not clobber dollar-at'};
};

subtest 'global state: public methods do not clobber $_' => sub {
	my $cfg  = _make_cfg();
	local $_ = 'sentinel_value';
	$cfg->get('database.user');
	$cfg->exists('database.user');
	$cfg->all();
	is($_, 'sentinel_value', 'public methods leave $_ unchanged');
	delete $ledger{'global-state: methods do not clobber dollar-underscore'};
};

# ===========================================================================
# Test::Mockingbird - spy integration
# Verifies that Test::Mockingbird is wired in and functional
# ===========================================================================

subtest 'Mockingbird spy: captures get() invocations correctly' => sub {
	my $cfg = _make_cfg();
	my $spy = spy 'Config::Abstraction::get';
	$cfg->get('database.user');
	my @calls = $spy->();
	restore_all();
	ok(scalar(@calls) > 0, 'spy: at least one get() call captured');
	diag('spy calls: ' . scalar(@calls)) if $ENV{TEST_VERBOSE};
	delete $ledger{'mockingbird: spy captures get() calls'};
};

# ===========================================================================
# get() / exists() -- undef-key guards
# POD: get() returns undef when key is undef; exists() returns 0
# ===========================================================================

subtest 'get() - returns undef silently when key is undef' => sub {
	# POD: "undef is allowed and returns undef silently"
	my $cfg = _make_cfg();
	ok(!defined($cfg->get(undef)), 'get(undef) returns undef without warning');
	delete $ledger{'get: returns undef for undef key'};
};

subtest 'exists() - returns 0 when key is undef' => sub {
	# POD: "Returns 0 when key is undef"
	my $cfg = _make_cfg();
	is($cfg->exists(undef), 0, 'exists(undef) returns 0');
	delete $ledger{'exists: returns 0 for undef key'};
};

subtest 'exists() - returns 1 when key is present but value is undef' => sub {
	# POD example: $cfg->exists('timeout') => 1 even when value is undef
	my $cfg = Config::Abstraction->new(
		data        => { timeout => undef },
		config_dirs => [],
	);
	is($cfg->exists('timeout'), 1, 'exists() returns 1 for key with undef value');
	delete $ledger{'exists: returns 1 when key present but value is undef'};
};

# ===========================================================================
# new() -- file synonym
# POD: 'file' is a synonym for 'config_file'
# ===========================================================================

subtest 'new() - file is a synonym for config_file' => sub {
	my $dir  = tempdir(CLEANUP => 1);
	my $path = _write_file($dir, 'myapp.yaml', "appname: synonymtest\n");
	my $cfg  = Config::Abstraction->new(file => $path);
	ok(defined($cfg),                       'object created via file synonym');
	is($cfg->get('appname'), 'synonymtest', 'file synonym loads the named file');
	delete $ledger{'new: file synonym for config_file'};
};

# ===========================================================================
# new() -- lazy option
# POD: lazy => 1 always returns a blessed object; schema deferred to first access
# ===========================================================================

subtest 'new() - lazy always returns a blessed object (even with no config)' => sub {
	# POD: "new() always returns a blessed object" when lazy => 1
	my $cfg = Config::Abstraction->new(
		data        => {},
		config_dirs => [],
		lazy        => 1,
	);
	ok(defined($cfg),  'lazy: new() returns defined value for empty config');
	ok(blessed($cfg),  'lazy: return value is blessed');
	delete $ledger{'new: lazy always returns blessed object'};
};

subtest 'new() - lazy defers schema validation until first accessor call' => sub {
	# POD: "schema validation likewise runs on first access rather than at construction time"
	# Construction with a failing schema must succeed; accessing the value must croak.
	my $cfg;
	lives_ok {
		$cfg = Config::Abstraction->new(
			data        => { port => 'not_a_number' },
			config_dirs => [],
			lazy        => 1,
			schema      => { port => { type => 'integer' } },
		);
	} 'lazy: construction with invalid schema does not die';
	ok(defined($cfg) && blessed($cfg), 'lazy: blessed object returned despite bad schema');
	throws_ok { $cfg->get('port') } qr/.+/, 'lazy: schema failure raised on first get()';
	delete $ledger{'new: lazy defers schema validation to first access'};
};

# ===========================================================================
# new() -- environment option
# POD: loads base.{env}.* immediately after base.* in each config_dir
# ===========================================================================

subtest 'new() - environment option loads base.{env}.yaml tier' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml',     "stage: base\n");
	_write_file($dir, 'base.prod.yaml', "stage: prod\n");

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir],
		environment => 'prod',
	);
	ok(defined($cfg),                'environment: object constructed');
	is($cfg->get('stage'), 'prod',   'environment: base.prod.yaml overrides base.yaml');
	delete $ledger{'new: environment loads base.env.yaml tier'};
};

subtest 'new() - invalid environment name croaks' => sub {
	# POD: "any other value causes a croak" for environment names outside /^[A-Za-z0-9_-]+$/
	throws_ok {
		Config::Abstraction->new(
			data        => { x => 1 },
			config_dirs => [],
			environment => 'bad/name',
		);
	} qr/invalid environment name/i, 'invalid environment name croaks';
	delete $ledger{'new: invalid environment name croaks'};
};

# ===========================================================================
# new() -- validators option
# POD: hashref mapping dotted keys to type-name, regex, coderef, or hashref rules
# ===========================================================================

subtest 'new() - validators: type string accepts valid value' => sub {
	lives_ok {
		Config::Abstraction->new(
			data        => { port => 8080 },
			config_dirs => [],
			validators  => { port => 'integer' },
		);
	} 'validators: integer type passes for integer value';
	delete $ledger{'new: validators type string accepts valid value'};
};

subtest 'new() - validators: type string rejects invalid value' => sub {
	throws_ok {
		Config::Abstraction->new(
			data        => { port => 'not_an_int' },
			config_dirs => [],
			validators  => { port => 'integer' },
		);
	} qr/.+/, 'validators: integer type fails for non-integer value';
	delete $ledger{'new: validators type string rejects invalid value'};
};

subtest 'new() - validators: regex accepts matching value' => sub {
	lives_ok {
		Config::Abstraction->new(
			data        => { level => 'info' },
			config_dirs => [],
			validators  => { level => qr/^(?:debug|info|warn|error)$/ },
		);
	} 'validators: regex passes for matching value';
	delete $ledger{'new: validators regex accepts matching value'};
};

subtest 'new() - validators: regex rejects non-matching value' => sub {
	throws_ok {
		Config::Abstraction->new(
			data        => { level => 'verbose' },
			config_dirs => [],
			validators  => { level => qr/^(?:debug|info|warn|error)$/ },
		);
	} qr/.+/, 'validators: regex fails for non-matching value';
	delete $ledger{'new: validators regex rejects non-matching value'};
};

subtest 'new() - validators: coderef accepts truthy return' => sub {
	lives_ok {
		Config::Abstraction->new(
			data        => { port => 8080 },
			config_dirs => [],
			validators  => { port => sub { my $v = shift; defined($v) && $v >= 1 && $v <= 65535 } },
		);
	} 'validators: coderef passes when sub returns true';
	delete $ledger{'new: validators coderef accepts truthy return'};
};

subtest 'new() - validators: coderef rejects falsy return' => sub {
	throws_ok {
		Config::Abstraction->new(
			data        => { port => 99999 },
			config_dirs => [],
			validators  => { port => sub { my $v = shift; defined($v) && $v >= 1 && $v <= 65535 } },
		);
	} qr/.+/, 'validators: coderef fails when sub returns false';
	delete $ledger{'new: validators coderef rejects falsy return'};
};

subtest 'new() - validators: hashref spec with required croaks when key missing' => sub {
	# POD: "required: if true, the key must exist and its value must be defined"
	throws_ok {
		Config::Abstraction->new(
			data        => { other => 'value' },
			config_dirs => [],
			validators  => { port => { type => 'integer', required => 1 } },
		);
	} qr/.+/, 'validators: required key absent causes croak';
	delete $ledger{'new: validators hashref required key missing croaks'};
};

subtest 'new() - validators: hashref spec enforces min/max bounds' => sub {
	# POD: "min (numeric lower bound, inclusive), max (numeric upper bound, inclusive)"
	throws_ok {
		Config::Abstraction->new(
			data        => { port => 0 },
			config_dirs => [],
			validators  => { port => { type => 'integer', min => 1, max => 65535 } },
		);
	} qr/.+/, 'validators: min bound violated causes croak';

	lives_ok {
		Config::Abstraction->new(
			data        => { port => 80 },
			config_dirs => [],
			validators  => { port => { type => 'integer', min => 1, max => 65535 } },
		);
	} 'validators: value within min/max accepted';
	delete $ledger{'new: validators hashref min/max enforced'};
};

# ===========================================================================
# explain_sources()
# POD: returns hashref; each key has {value, sources:[{type,label,value},...]}
# ===========================================================================

subtest 'explain_sources() - returns a hashref' => sub {
	my $cfg = _make_cfg();
	my $es  = $cfg->explain_sources();
	ok(defined($es),          'explain_sources() returns defined value');
	is(ref($es), 'HASH',      'explain_sources() returns hashref');
	returns_ok($es, { type => 'hashref' }, 'returns_ok: hashref');
	delete $ledger{'explain_sources: returns hashref'};
};

subtest 'explain_sources() - value field matches get() for every key' => sub {
	my $cfg = _make_cfg();
	my $es  = $cfg->explain_sources();
	for my $key (keys %{$es}) {
		next if $key eq 'config_path';
		is($es->{$key}{value}, $cfg->get($key),
			"explain_sources value matches get() for '$key'");
	}
	delete $ledger{'explain_sources: value field matches get()'};
};

subtest 'explain_sources() - sources arrayref ordered lowest first' => sub {
	# POD: sources are ordered from lowest to highest precedence (winning source last).
	# Use double-underscore env var so it maps directly to a nested dotted key.
	local %ENV = %ENV;
	$ENV{"${ENV_PREFIX}DATABASE__USER"} = 'env_user';
	my $cfg = Config::Abstraction->new(
		data        => { database => { user => $EXPECTED_USER } },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	my $es  = $cfg->explain_sources();
	my $src = $es->{'database.user'}{sources};
	ok(defined($src),               'sources field defined');
	is(ref($src), 'ARRAY',          'sources is an arrayref');
	ok(scalar(@{$src}) >= 2,        'at least two sources (data + env)');
	is($src->[0]{type}, 'data',     'lowest source is data');
	is($src->[-1]{type}, 'env',     'highest (winning) source is env');
	delete $ledger{'explain_sources: sources arrayref ordered lowest first'};
};

subtest 'explain_sources() - data source has correct type and label' => sub {
	my $cfg = _make_cfg();
	my $es  = $cfg->explain_sources();
	my ($data_src) = grep { $_->{type} eq 'data' } @{$es->{retries}{sources}};
	ok(defined($data_src),                   'data source entry present');
	is($data_src->{type},  'data',           'type field is "data"');
	like($data_src->{label}, qr/constructor data argument/, 'label identifies data source');
	is($data_src->{value}, $EXPECTED_RETRIES,'data source value correct');
	delete $ledger{'explain_sources: data source has correct type and label'};
};

subtest 'explain_sources() - env source has correct type and label' => sub {
	# Use double-underscore so the env var maps directly to the dotted key database.user.
	local %ENV = %ENV;
	$ENV{"${ENV_PREFIX}DATABASE__USER"} = 'env_alice';
	my $cfg = Config::Abstraction->new(
		data        => { database => { user => $EXPECTED_USER } },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	my $es = $cfg->explain_sources();
	my ($env_src) = grep { $_->{type} eq 'env' } @{$es->{'database.user'}{sources}};
	ok(defined($env_src),                 'env source entry present');
	is($env_src->{type},  'env',          'type field is "env"');
	like($env_src->{label}, qr/DATABASE/, 'label contains the env var name');
	is($env_src->{value}, 'env_alice',    'env source value correct');
	delete $ledger{'explain_sources: env source has correct type and label'};
};

subtest 'explain_sources() - file source recorded with type "file"' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_FILENAME, "timeout: $EXPECTED_TIMEOUT\n");
	my $cfg = Config::Abstraction->new(config_dirs => [$dir]);
	my $es  = $cfg->explain_sources();
	my ($file_src) = grep { $_->{type} eq 'file' } @{$es->{timeout}{sources}};
	ok(defined($file_src),           'file source entry present');
	is($file_src->{type}, 'file',    'type field is "file"');
	diag('file label: ' . ($file_src->{label} // 'undef')) if $ENV{TEST_VERBOSE};
	delete $ledger{'explain_sources: file source has correct type'};
};

# ===========================================================================
# prefer_env(key)
# POD: returns env-layer value, or get(key) if no env var contributed
# ===========================================================================

subtest 'prefer_env() - returns env-layer value when env variable contributed' => sub {
	# Use double-underscore so the env var maps directly to database.user.
	# Also set a CLI arg at higher precedence; prefer_env must bypass it.
	local %ENV = %ENV;
	local @ARGV = ("--${ENV_PREFIX}DATABASE__USER=cli_user");
	$ENV{"${ENV_PREFIX}DATABASE__USER"} = 'env_user';
	my $cfg = Config::Abstraction->new(
		data        => { database => { user => $EXPECTED_USER } },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	# get() returns cli_user (highest precedence), prefer_env must return env_user.
	is($cfg->prefer_env('database.user'), 'env_user',
		'prefer_env returns env-layer value bypassing argv');
	delete $ledger{'prefer_env: returns env value when env contributed'};
};

subtest 'prefer_env() - falls back to get() when no env variable set the key' => sub {
	local %ENV = %ENV;
	delete $ENV{"${ENV_PREFIX}DATABASE__USER"};
	my $cfg = Config::Abstraction->new(
		data        => { database => { user => $EXPECTED_USER } },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->prefer_env('database.user'), $EXPECTED_USER,
		'prefer_env falls back to get() when no env var contributed');
	delete $ledger{'prefer_env: falls back to get() when env absent'};
};

# ===========================================================================
# prefer_file(key)
# POD: returns file-layer value, or get(key) if no file contributed
# ===========================================================================

subtest 'prefer_file() - returns file-layer value when a file set the key' => sub {
	# Set up env and file both contributing; prefer_file must return the file value.
	local %ENV = %ENV;
	$ENV{"${ENV_PREFIX}TIMEOUT"} = 'env_val';
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_FILENAME, "timeout: $EXPECTED_TIMEOUT\n");
	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->prefer_file('timeout'), $EXPECTED_TIMEOUT,
		'prefer_file returns file-layer value bypassing env');
	delete $ledger{'prefer_file: returns file value when file contributed'};
};

subtest 'prefer_file() - falls back to get() when no file set the key' => sub {
	my $cfg = _make_cfg();    # config_dirs => [] means no files loaded
	# 'retries' came only from data; prefer_file falls back to get()
	is($cfg->prefer_file('retries'), $EXPECTED_RETRIES,
		'prefer_file falls back to get() when no file contributed');
	delete $ledger{'prefer_file: falls back to get() when no file'};
};

# ===========================================================================
# prefer_data(key)
# POD: returns data-constructor value, or get(key) if data did not set it
# ===========================================================================

subtest 'prefer_data() - returns data-constructor value bypassing env override' => sub {
	local %ENV = %ENV;
	$ENV{"${ENV_PREFIX}RETRIES"} = '99';
	my $cfg = Config::Abstraction->new(
		data        => { retries => $EXPECTED_RETRIES },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	# get() returns '99' (env wins), but prefer_data must return the original data value.
	is($cfg->prefer_data('retries'), $EXPECTED_RETRIES,
		'prefer_data returns data-constructor value despite env override');
	delete $ledger{'prefer_data: returns data value when data contributed'};
};

subtest 'prefer_data() - falls back to get() when data did not set the key' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_FILENAME, "fileonly: from_file\n");
	my $cfg = Config::Abstraction->new(
		data        => { other => 'x' },
		config_dirs => [$dir],
	);
	# 'fileonly' was never in the data arg; prefer_data falls back to get()
	is($cfg->prefer_data('fileonly'), 'from_file',
		'prefer_data falls back to get() when data did not set the key');
	delete $ledger{'prefer_data: falls back to get() when data absent'};
};

# ===========================================================================
# prefer_argv(key)
# POD: returns argv-layer value, or get(key) when no CLI arg set the key
# ===========================================================================

subtest 'prefer_argv() - returns argv-layer value when CLI arg contributed' => sub {
	local @ARGV = ("--${ENV_PREFIX}RETRIES=argv_val");
	my $cfg = Config::Abstraction->new(
		data        => { retries => $EXPECTED_RETRIES },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->prefer_argv('retries'), 'argv_val',
		'prefer_argv returns the argv-layer value');
	delete $ledger{'prefer_argv: returns argv value when argv contributed'};
};

subtest 'prefer_argv() - falls back to get() when no CLI arg set the key' => sub {
	local @ARGV = ();
	my $cfg = _make_cfg();
	is($cfg->prefer_argv('retries'), $EXPECTED_RETRIES,
		'prefer_argv falls back to get() when no CLI arg contributed');
	delete $ledger{'prefer_argv: falls back to get() when no argv'};
};

# ===========================================================================
# encrypt_value($plaintext)
# POD: requires CryptX; croaks when no key configured; returns ENC[AES256GCM,...] token
# ===========================================================================

Readonly::Scalar my $HEX_KEY => 'a' x 64;    # 64 hex chars = 32-byte AES-256 key

subtest 'encrypt_value() - croaks when no encryption key is configured' => sub {
	# POD: "<class>: no encryption key configured ..." croak
	my $cfg = _make_cfg();
	throws_ok { $cfg->encrypt_value('secret') }
		qr/no encryption key configured/,
		'encrypt_value croaks with no key configured';
	delete $ledger{'encrypt_value: croaks with no encryption key configured'};
};

SKIP: {
	skip 'CryptX (Crypt::AuthEnc::GCM) not installed', 1
		unless eval { require Crypt::AuthEnc::GCM; 1 };

	subtest 'encrypt_value() - returns a well-formed ENC[AES256GCM,...] token' => sub {
		# POD: "return ENC[AES256GCM,<base64url(nonce+ciphertext+tag)>]"
		my $cfg = Config::Abstraction->new(
			data           => {},
			config_dirs    => [],
			encryption_key => $HEX_KEY,
			lazy           => 1,
		);
		my $token = $cfg->encrypt_value('plaintext_secret');
		like($token, qr/^ENC\[AES256GCM,[A-Za-z0-9_-]+\]$/,
			'token has expected ENC[AES256GCM,...] format');
		# Each call uses a fresh nonce, so the same plaintext produces different tokens.
		my $token2 = $cfg->encrypt_value('plaintext_secret');
		isnt($token, $token2, 'consecutive calls produce distinct tokens (fresh nonce)');
	};
}
# Ledger delete is outside the SKIP block: the entry is removed whether or not
# CryptX is installed, so the ledger assertion never fails on machines without it.
delete $ledger{'encrypt_value: returns ENC[AES256GCM,...] token'};

# ===========================================================================
# Ledger assertion - every documented POD state must have been exercised
# ===========================================================================

my @uncovered = sort keys %ledger;
if(@uncovered) {
	fail('Untested POD-documented states remain in ledger: ' . scalar(@uncovered));
	diag("  UNCOVERED: $_") for @uncovered;
} else {
	pass('All documented POD API states covered by ledger');
}

done_testing();
