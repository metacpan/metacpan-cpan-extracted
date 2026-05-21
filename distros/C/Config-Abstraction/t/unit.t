#!/usr/bin/perl

# Black-box tests for Config::Abstraction public API as documented in POD.
# Tests only observable behaviour through the public interface.

use strict;
use warnings;
use autodie qw(:all);

use Test::Most;
use Readonly;
use Scalar::Util qw(blessed reftype);
use File::Temp qw(tempdir);
use File::Spec;

# ---------------------------------------------------------------------------
# Configuration - can be overridden via Object::Configure if wanted
# ---------------------------------------------------------------------------
my %config = (
	module		=> 'Config::Abstraction',
	sep_char	=> '.',
	sep_char_alt	=> '/',
	sep_char_us	=> '_',
	env_prefix	=> 'UNITAPP_',
	env_prefix_alt	=> 'MYAPP_',
	flatten_off	=> 0,
	flatten_on	=> 1,
);

Readonly::Scalar my $MODULE		=> $config{module};
Readonly::Scalar my $SEP		=> $config{sep_char};
Readonly::Scalar my $SEP_ALT		=> $config{sep_char_alt};
Readonly::Scalar my $SEP_US		=> $config{sep_char_us};
Readonly::Scalar my $ENV_PREFIX		=> $config{env_prefix};
Readonly::Scalar my $ENV_PREFIX_ALT	=> $config{env_prefix_alt};
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
Readonly::Scalar my $JSON_FILENAME	=> 'base.json';
Readonly::Scalar my $INI_FILENAME	=> 'base.ini';

# Reusable nested data - use fresh anon hash copies where merging will occur
Readonly::Hash my %BASE_DATA => (
	database => {
		user => $EXPECTED_USER,
		pass => $EXPECTED_PASS,
		port => $EXPECTED_PORT,
	},
	log => {
		level => $EXPECTED_LEVEL,
	},
	retries => $EXPECTED_RETRIES,
);

# ---------------------------------------------------------------------------
use_ok($MODULE) or BAIL_OUT("$MODULE failed to load");

# ---------------------------------------------------------------------------
# Helper: fresh anon copy of BASE_DATA safe for merge operations
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

# Helper: build object with no filesystem config loading
sub _make_cfg
{
	my (%extra) = @_;
	return Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		%extra,
	);
}

# ===========================================================================
# new() - constructor
# POD: constructor for creating a new configuration object
# ===========================================================================
subtest 'new() - returns blessed object on success' => sub {
	my $cfg = _make_cfg();
	ok(defined($cfg),          'new() returns defined value');
	ok(blessed($cfg),          'return value is blessed');
	is(blessed($cfg), $MODULE, 'blessed into correct package');
};

subtest 'new() - single argument treated as filename' => sub {
	# POD: if just one argument is given, it is assumed to be the name of a file
	my $cfg = Config::Abstraction->new(
		file        => '/no/such/file.yaml',
		data        => { dummy => 'value' },
		config_dirs => [],
	);
	ok(defined($cfg), 'single-arg file form accepted');
};

subtest 'new() - returns undef when no config data found' => sub {
	# POD: returns undef when config hash is empty after loading
	my $cfg = Config::Abstraction->new(
		data        => {},
		config_dirs => [],
	);
	ok(!defined($cfg), 'new() returns undef for empty config');
};

subtest 'new() - env_prefix defaults to APP_' => sub {
	my $cfg = _make_cfg();
	is($cfg->{env_prefix}, 'APP_', 'default env_prefix is APP_');
};

subtest 'new() - sep_char defaults to dot' => sub {
	# POD: default is a '.', as in dotted notation
	my $cfg = _make_cfg();
	is($cfg->{sep_char}, $SEP, 'default sep_char is dot');
};

subtest 'new() - custom sep_char honoured' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { database => { user => $EXPECTED_USER } },
		config_dirs => [],
		sep_char    => $SEP_ALT,
	);
	is($cfg->get("database${SEP_ALT}user"), $EXPECTED_USER, 'custom sep_char used');
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
};

subtest 'new() - defaults hash initialises object attributes' => sub {
	# POD: if defaults option supplied, object initialised using keys in that hash
	my $cfg = Config::Abstraction->new(
		defaults => {
			data        => _fresh_data(),
			config_dirs => [],
			sep_char    => $SEP,
		},
		env_prefix => $ENV_PREFIX,
	);
	ok(defined($cfg),            'object created via defaults hash');
	is($cfg->{sep_char}, $SEP,   'sep_char taken from defaults');
	is($cfg->{env_prefix}, $ENV_PREFIX, 'top-level env_prefix overrides defaults');
};

subtest 'new() - data option primes configuration' => sub {
	# POD: data - a hash ref of default data to prime the configuration with
	my $cfg = Config::Abstraction->new(
		data        => { log_level => $EXPECTED_LEVEL, retries => $EXPECTED_RETRIES },
		config_dirs => [],
	);
	is($cfg->get('log_level'), $EXPECTED_LEVEL,   'data value accessible');
	is($cfg->get('retries'),   $EXPECTED_RETRIES, 'data integer accessible');
};

subtest 'new() - loads YAML file from config_dirs' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $path = File::Spec->catfile($dir, $YAML_FILENAME);
	open(my $fh, '>', $path);
	print $fh "timeout: $EXPECTED_TIMEOUT\n";
	close $fh;

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir],
	);
	is($cfg->get('timeout'), $EXPECTED_TIMEOUT, 'YAML file loaded from config_dirs');
};

subtest 'new() - loads JSON file from config_dirs' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $path = File::Spec->catfile($dir, $JSON_FILENAME);
	open(my $fh, '>', $path);
	print $fh '{"timeout":' . $EXPECTED_TIMEOUT . '}';
	close $fh;

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir],
	);
	is($cfg->get('timeout'), $EXPECTED_TIMEOUT, 'JSON file loaded from config_dirs');
};

subtest 'new() - loads INI file from config_dirs' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $path = File::Spec->catfile($dir, $INI_FILENAME);
	open(my $fh, '>', $path);
	print $fh "[database]\nuser=$EXPECTED_USER\n";
	close $fh;

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir],
	);
	is($cfg->get('database.user'), $EXPECTED_USER, 'INI file loaded from config_dirs');
};

subtest 'new() - later config_files override earlier ones' => sub {
	# POD: put the more important files later, since later files override earlier ones
	my $dir = tempdir(CLEANUP => 1);

	my $base = File::Spec->catfile($dir, 'base.yaml');
	open(my $fh, '>', $base);
	print $fh "level: base\n";
	close $fh;

	my $local = File::Spec->catfile($dir, 'local.yaml');
	open($fh, '>', $local);
	print $fh "level: local\n";
	close $fh;

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir],
	);
	is($cfg->get('level'), 'local', 'local.yaml overrides base.yaml');
};

subtest 'new() - flatten option produces flat key structure' => sub {
	# POD: if true, returns a flat hash structure like {database.user}
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		flatten     => $FLATTEN_ON,
	);
	ok(defined($cfg),                          'object created with flatten=>1');
	is($cfg->get('database.user'), $EXPECTED_USER, 'flat key accessible');
};

subtest 'new() - schema validates configuration' => sub {
	# POD: a Params::Validate::Strict compatible schema to validate config against
	my $cfg = Config::Abstraction->new(
		data => {
			retries  => $EXPECTED_RETRIES,
			database => { user => $EXPECTED_USER },
			log      => { level => $EXPECTED_LEVEL },
		},
		config_dirs => [],
		schema      => {
			retries  => { type => 'integer' },
			database => { type => 'hashref' },
			log      => { type => 'hashref' },
		},
	);
	ok(defined($cfg), 'object created when config matches schema');
};

subtest 'new() - schema rejects invalid configuration' => sub {
	eval {
		Config::Abstraction->new(
			data        => { retries => $EXPECTED_RETRIES },
			config_dirs => [],
			schema      => {
				retries    => { type => 'integer' },
				compulsory => { type => 'string', optional => 0 },
			},
		);
	};
	ok($@, 'new() dies when config fails schema validation');
};

# ===========================================================================
# get(key)
# POD: retrieve a configuration value using dotted key notation
# ===========================================================================
subtest 'get() - retrieves top-level scalar' => sub {
	my $cfg = _make_cfg();
	is($cfg->get('retries'), $EXPECTED_RETRIES, 'top-level scalar retrieved');
};

subtest 'get() - retrieves nested value via dotted notation' => sub {
	# POD: e.g. 'database.user'
	my $cfg = _make_cfg();
	is($cfg->get('database.user'), $EXPECTED_USER, 'nested value retrieved');
	is($cfg->get('database.port'), $EXPECTED_PORT, 'nested integer retrieved');
};

subtest 'get() - returns undef for absent key' => sub {
	# POD: returns undef if the key does not exist
	my $cfg = _make_cfg();
	ok(!defined($cfg->get('no.such.key')), 'absent key returns undef');
};

subtest 'get() - returns undef when mid-path value is not a hash' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { flat => 'scalar_value' },
		config_dirs => [],
	);
	ok(!defined($cfg->get('flat.child')), 'undef when mid-path is scalar');
};

subtest 'get() - returns hashref for partial path' => sub {
	my $cfg = _make_cfg();
	my $db = $cfg->get('database');
	is(reftype($db), 'HASH',        'partial path returns hashref');
	is($db->{user}, $EXPECTED_USER, 'hashref contents correct');
};

subtest 'get() - coderef value survives round-trip' => sub {
	my $cb = sub { $EXPECTED_CB_RESULT };
	my $cfg = Config::Abstraction->new(
		data        => { callback => $cb },
		config_dirs => [],
	);
	my $got = $cfg->get('callback');
	is(reftype($got), 'CODE',          'coderef type preserved');
	is($got->(), $EXPECTED_CB_RESULT,  'coderef is callable');
};

subtest 'get() - blessed object survives round-trip' => sub {
	my $obj = bless { val => $EXPECTED_PORT }, '_UnitTestObj';
	my $cfg = Config::Abstraction->new(
		data        => { handler => $obj },
		config_dirs => [],
	);
	my $got = $cfg->get('handler');
	ok(blessed($got),                  'blessed object preserved');
	is(blessed($got), '_UnitTestObj',  'class unchanged');
};

subtest 'get() - flat mode uses direct key lookup' => sub {
	# POD: if flatten true, returns a flat hash structure like {database.user}
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		flatten     => $FLATTEN_ON,
	);
	is($cfg->get('database.user'), $EXPECTED_USER, 'flat mode key lookup');
};

subtest 'get() - repeated calls on same hashref key do not crash' => sub {
	my $cfg = _make_cfg();
	my $first  = $cfg->get('database');
	my $second = $cfg->get('database');
	ok(defined($second),             'second call on hashref key succeeds');
	is($second->{user}, $EXPECTED_USER, 'value correct on second call');
};

subtest 'get() - custom sep_char respected' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { database => { user => $EXPECTED_USER } },
		config_dirs => [],
		sep_char    => $SEP_ALT,
	);
	is($cfg->get("database${SEP_ALT}user"), $EXPECTED_USER, 'custom sep_char in get()');
};

# ===========================================================================
# exists(key)
# POD: does a configuration value using dotted key notation exist?
# ===========================================================================
subtest 'exists() - returns 1 for present top-level key' => sub {
	my $cfg = _make_cfg();
	is($cfg->exists('retries'), 1, 'present top-level key returns 1');
};

subtest 'exists() - returns 1 for present nested key' => sub {
	my $cfg = _make_cfg();
	is($cfg->exists('database.user'), 1, 'present nested key returns 1');
};

subtest 'exists() - returns 0 for absent key' => sub {
	my $cfg = _make_cfg();
	is($cfg->exists('no.such.key'), 0, 'absent key returns 0');
};

subtest 'exists() - returns 0 when mid-path is not a hash' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { flat => 'scalar_value' },
		config_dirs => [],
	);
	is($cfg->exists('flat.child'), 0, 'mid-path scalar returns 0');
};

subtest 'exists() - returns 1 in flat mode for present key' => sub {
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		flatten     => $FLATTEN_ON,
	);
	is($cfg->exists('database.user'), 1, 'flat mode present key returns 1');
};

subtest 'exists() - returns 0 in flat mode for absent key' => sub {
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		flatten     => $FLATTEN_ON,
	);
	is($cfg->exists('no.such.key'), 0, 'flat mode absent key returns 0');
};

# ===========================================================================
# all()
# POD: returns the entire configuration hash
# ===========================================================================
subtest 'all() - returns entire config as hashref' => sub {
	my $cfg = _make_cfg();
	my $all = $cfg->all();
	ok(defined($all),          'all() returns defined value');
	is(reftype($all), 'HASH',  'all() returns hashref');
};

subtest 'all() - contains all top-level keys from data' => sub {
	my $cfg = _make_cfg();
	my $all = $cfg->all();
	ok(exists $all->{database}, 'database key present');
	ok(exists $all->{log},      'log key present');
	ok(exists $all->{retries},  'retries key present');
};

subtest 'all() - config_path key lists loaded files' => sub {
	# POD: config_path contains a list of files config was loaded from
	my $dir = tempdir(CLEANUP => 1);
	my $path = File::Spec->catfile($dir, $YAML_FILENAME);
	open(my $fh, '>', $path);
	print $fh "timeout: $EXPECTED_TIMEOUT\n";
	close $fh;

	my $cfg = Config::Abstraction->new(config_dirs => [$dir]);
	my $all = $cfg->all();
	ok(exists $all->{config_path},          'config_path key present');
	is(reftype($all->{config_path}), 'ARRAY', 'config_path is arrayref');
	ok(scalar(@{$all->{config_path}}) > 0,  'config_path is non-empty');
};

subtest 'all() - returns undef when config is empty' => sub {
	my $cfg = _make_cfg();
	$cfg->{config} = {};
	ok(!defined($cfg->all()), 'all() returns undef for empty config');
};

subtest 'all() - flat mode returns flattened hash' => sub {
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		flatten     => $FLATTEN_ON,
	);
	my $all = $cfg->all();
	ok(exists $all->{'database.user'}, 'flat key present in all()');
};

# ===========================================================================
# merge_defaults()
# POD: merge the configuration hash into the given hash
# ===========================================================================
subtest 'merge_defaults() - no args returns full config' => sub {
	# POD: returns config when called with no arguments
	my $cfg = _make_cfg();
	my $result = $cfg->merge_defaults();
	ok(defined($result),          'no-arg returns defined value');
	is(reftype($result), 'HASH',  'no-arg returns hashref');
};

subtest 'merge_defaults() - config overrides defaults' => sub {
	my $cfg = _make_cfg();
	my $merged = $cfg->merge_defaults(
		defaults => { retries => 99, extra => 'kept' },
	);
	is($merged->{retries}, $EXPECTED_RETRIES, 'config value overrides default');
	is($merged->{extra},   'kept',            'default-only key preserved');
};

subtest 'merge_defaults() - merge option combines both hashes' => sub {
	# POD: if merge given, result is a combination of the hashes
	my $cfg = _make_cfg();
	my $merged = $cfg->merge_defaults(
		defaults => { extra => 'from_default' },
		merge    => 1,
	);
	ok(exists $merged->{extra},    'default-only key present with merge=>1');
	ok(exists $merged->{database}, 'config key present with merge=>1');
};

subtest 'merge_defaults() - section scopes result to named section' => sub {
	# POD: merge in that section from the configuration file
	my $cfg = _make_cfg();
	my $merged = $cfg->merge_defaults(
		defaults => {},
		section  => 'database',
	);
	is($merged->{user}, $EXPECTED_USER, 'section key present');
	ok(!exists $merged->{retries},      'keys outside section absent');
};

subtest 'merge_defaults() - global section merged into defaults' => sub {
	my $cfg = Config::Abstraction->new(
		data => {
			global  => { timeout => $EXPECTED_TIMEOUT },
			retries => $EXPECTED_RETRIES,
		},
		config_dirs => [],
	);
	my $merged = $cfg->merge_defaults(
		defaults => { timeout => 99 },
	);
	is($merged->{timeout}, $EXPECTED_TIMEOUT, 'global overrides defaults');
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
	is($merged->{database}{user}, 'global_user',   'deep merge: global wins on conflict');
	is($merged->{database}{port}, $EXPECTED_PORT,  'deep merge: default preserved for non-conflicting key');
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
	is($cfg->loglevel(), $EXPECTED_LEVEL, 'AUTOLOAD top-level key');
};

subtest 'AUTOLOAD - resolves nested key via sep_char' => sub {
	# POD: $config->database_user() resolves to $config->{database}{user}
	#      when sep_char is '_'
	my $cfg = Config::Abstraction->new(
		data        => { database => { user => $EXPECTED_USER } },
		config_dirs => [],
		sep_char    => $SEP_US,
	);
	is($cfg->database_user(), $EXPECTED_USER, 'AUTOLOAD nested key via sep_char');
};

subtest 'AUTOLOAD - returns hashref for partial path' => sub {
	# POD: $user = $config->database()->{'user'}
	my $cfg = Config::Abstraction->new(
		data        => { database => { user => $EXPECTED_USER } },
		config_dirs => [],
		sep_char    => $SEP_US,
	);
	my $db = $cfg->database();
	is(reftype($db), 'HASH',        'AUTOLOAD partial path returns hashref');
	is($db->{user}, $EXPECTED_USER, 'hashref contents correct');
};

subtest 'AUTOLOAD - dies on nonexistent key' => sub {
	# POD: attempting to call a nonexistent key dies with error
	my $cfg = Config::Abstraction->new(
		data        => { known => 'value' },
		config_dirs => [],
		sep_char    => $SEP_US,
	);
	eval { $cfg->nonexistent_key() };
	like($@, qr/No such config key/, 'AUTOLOAD dies for missing key');
};

# ===========================================================================
# Environment variable overrides
# POD: APP_DATABASE__USER becomes database.user (nested structure)
# ===========================================================================
subtest 'ENV double-underscore creates nested key' => sub {
	# POD: APP_DATABASE__USER becomes database.user
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
};

subtest 'ENV single segment stored under prefix namespace' => sub {
	# POD: APP_LOGLEVEL becomes APP.loglevel
	local %ENV = %ENV;
	$ENV{"${ENV_PREFIX}RETRIES"} = '99';

	my $cfg = Config::Abstraction->new(
		data => {
			UNITAPP => { retries => $EXPECTED_RETRIES },
			retries => $EXPECTED_RETRIES,
		},
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('UNITAPP.retries'), '99', 'ENV single segment stored under prefix namespace');
};

subtest 'ENV mixed double-underscore and underscore in key' => sub {
	# POD: APP_API__RATE_LIMIT becomes api.rate_limit
	local %ENV = %ENV;
	$ENV{"${ENV_PREFIX}API__RATE_LIMIT"} = '100';

	my $cfg = Config::Abstraction->new(
		data => {
			api => { rate_limit => 50 },
		},
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('api.rate_limit'), '100', 'mixed underscore ENV key handled correctly');
};

# ===========================================================================
# Command-line argument overrides
# POD: adding --APP_DATABASE__USER=other_user_name to command line
# ===========================================================================
subtest 'CLI arg overrides top-level key' => sub {
	local @ARGV = ("--${ENV_PREFIX}RETRIES=77");

	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('retries'), '77', 'CLI arg overrides top-level key');
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
};

subtest 'CLI arg without matching prefix is ignored' => sub {
	local @ARGV = ('--OTHERAPP_RETRIES=999');

	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('retries'), $EXPECTED_RETRIES, 'non-matching prefix CLI arg ignored');
};

# ===========================================================================
# Merge precedence
# POD: CLI args > Environment > Config file > Defaults
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
};

subtest 'merge precedence: config file overrides data' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $path = File::Spec->catfile($dir, $YAML_FILENAME);
	open(my $fh, '>', $path);
	print $fh "retries: 99\n";
	close $fh;

	my $cfg = Config::Abstraction->new(
		data        => { retries => $EXPECTED_RETRIES },
		config_dirs => [$dir],
	);
	is($cfg->get('retries'), 99, 'config file overrides data defaults');
};

done_testing();
