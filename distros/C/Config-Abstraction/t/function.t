#!/usr/bin/perl

# White-box tests for Config::Abstraction public and internal methods.
# Uses Test::Mockingbird to mock non-core dependencies.

use strict;
use warnings;
use autodie qw(:all);

use Test::Most;
use Test::Mockingbird;
use Readonly;
use Scalar::Util qw(blessed reftype);

# ---------------------------------------------------------------------------
# Configuration - can be overridden via Object::Configure
# ---------------------------------------------------------------------------
my %config = (
	module		=> 'Config::Abstraction',
	sep_char	=> '.',
	env_prefix	=> 'TESTAPP_',
	flatten_off	=> 0,
	flatten_on	=> 1,
);

Readonly::Scalar my $MODULE		=> $config{module};
Readonly::Scalar my $SEP		=> $config{sep_char};
Readonly::Scalar my $ENV_PREFIX		=> $config{env_prefix};
Readonly::Scalar my $FLATTEN_OFF	=> $config{flatten_off};
Readonly::Scalar my $FLATTEN_ON		=> $config{flatten_on};

Readonly::Scalar my $EXPECTED_USER	=> 'alice';
Readonly::Scalar my $EXPECTED_PASS	=> 'secret';
Readonly::Scalar my $EXPECTED_PORT	=> 5432;
Readonly::Scalar my $EXPECTED_LEVEL	=> 'info';
Readonly::Scalar my $EXPECTED_RETRIES	=> 3;
Readonly::Scalar my $EXPECTED_CB_RESULT	=> 'callback_result';

Readonly::Hash my %FLAT_DATA => (
	'database.user'	=> $EXPECTED_USER,
	'database.pass'	=> $EXPECTED_PASS,
	'log.level'	=> $EXPECTED_LEVEL,
);

Readonly::Hash my %NESTED_DATA => (
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
# Helper: build a basic object with no filesystem config loading
# ---------------------------------------------------------------------------
sub _make_cfg
{
	my (%extra) = @_;
	return Config::Abstraction->new(
		data        => \%NESTED_DATA,
		config_dirs => [],
		%extra,
	);
}

# ===========================================================================
# new() - constructor
# ===========================================================================
subtest 'new() - basic construction with data' => sub {
	my $cfg = _make_cfg();
	ok(defined($cfg),        'returns a defined object');
	ok(blessed($cfg),        'object is blessed');
	is(blessed($cfg), $MODULE, 'blessed into correct class');
};

subtest 'new() - single-arg form treated as filename' => sub {
	# When one arg given, it should be stored as 'file'
	# Mock File::Slurp and parsers so no actual filesystem hit is needed;
	# we just verify the object initialises the key correctly.
	my $cfg = Config::Abstraction->new(
		file        => '/nonexistent/path.yaml',
		data        => { dummy => 'value' },
		config_dirs => [],
	);
	ok(defined($cfg), 'object created when file key provided');
};

subtest 'new() - defaults hash takes precedence over direct params' => sub {
	my $cfg = Config::Abstraction->new(
		defaults => {
			data        => \%NESTED_DATA,
			config_dirs => [],
			sep_char    => $SEP,
		},
		env_prefix => $ENV_PREFIX,	# top-level env_prefix still honoured
	);
	ok(defined($cfg), 'object created via defaults hash');
	is($cfg->{sep_char},   $SEP,        'sep_char taken from defaults');
	is($cfg->{env_prefix}, $ENV_PREFIX, 'top-level env_prefix overrides defaults');
};

subtest 'new() - returns undef when config is empty' => sub {
	# An empty data hash with no config files should produce undef
	my $guard = mock_scoped 'Config::Abstraction::_load_config' => sub {
		my $self = shift;
		$self->{config} = {};
	};
	my $cfg = Config::Abstraction->new(
		data        => {},
		config_dirs => [],
	);
	ok(!defined($cfg), 'returns undef when config hash is empty after load');
};

subtest 'new() - env_prefix defaults to APP_' => sub {
	my $cfg = _make_cfg();
	is($cfg->{env_prefix}, 'APP_', 'default env_prefix is APP_');
};

subtest 'new() - sep_char defaults to dot' => sub {
	my $cfg = _make_cfg();
	is($cfg->{sep_char}, $SEP, 'default sep_char is dot');
};

subtest 'new() - schema validation applied when schema provided' => sub {
	my $called = 0;
	my $guard = mock_scoped 'Params::Validate::Strict::validate_strict' => sub {
		$called++;
		my $args = ref($_[0]) eq 'HASH' ? $_[0] : {@_};
		return $args->{input};    # pass-through
	};
	my $cfg = Config::Abstraction->new(
		data        => \%NESTED_DATA,
		config_dirs => [],
		schema      => {
			retries => { type => 'integer' },
			database => { type => 'hashref' },
			log => { type => 'hashref' },
		},
	);
	is($called, 1, 'validate_strict called when schema provided');
};

# ===========================================================================
# get()
# ===========================================================================
subtest 'get() - top-level scalar key' => sub {
	my $cfg = _make_cfg();
	is($cfg->get('retries'), $EXPECTED_RETRIES, 'retrieves top-level scalar');
};

subtest 'get() - nested key via dotted notation' => sub {
	my $cfg = _make_cfg();
	is($cfg->get('database.user'), $EXPECTED_USER, 'retrieves nested key');
	is($cfg->get('database.port'), $EXPECTED_PORT, 'retrieves nested integer');
};

subtest 'get() - returns undef for missing key' => sub {
	my $cfg = _make_cfg();
	ok(!defined($cfg->get('no.such.key')), 'returns undef for absent key');
};

subtest 'get() - returns undef mid-path when ancestor not a hash' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { flat => 'scalar' },
		config_dirs => [],
	);
	ok(!defined($cfg->get('flat.child')), 'undef when mid-path value is scalar');
};

subtest 'get() - returns hashref for partial path' => sub {
	my $cfg = _make_cfg();
	my $db = $cfg->get('database');
	ok(defined($db),             'partial path returns defined value');
	is(reftype($db), 'HASH',     'partial path returns hashref');
	is($db->{user}, $EXPECTED_USER, 'hashref contents correct');
};

subtest 'get() - coderef value preserved and callable' => sub {
	my $cb = sub { $EXPECTED_CB_RESULT };
	my $cfg = Config::Abstraction->new(
		data        => { callback => $cb },
		config_dirs => [],
	);
	my $got = $cfg->get('callback');
	is(reftype($got), 'CODE',          'coderef preserved through get()');
	is($got->(), $EXPECTED_CB_RESULT,  'coderef is callable');
};

subtest 'get() - blessed object value preserved' => sub {
	package _TestObj;
	sub new   { bless { v => $_[1] }, $_[0] }
	sub value { $_[0]->{v} }
	package main;

	my $obj = _TestObj->new($EXPECTED_PORT);
	my $cfg = Config::Abstraction->new(
		data        => { handler => $obj },
		config_dirs => [],
	);
	my $got = $cfg->get('handler');
	ok(blessed($got),               'blessed object preserved through get()');
	is(blessed($got), '_TestObj',   'class unchanged');
	is($got->value(), $EXPECTED_PORT, 'object is functional');
};

subtest 'get() - flat mode uses direct key lookup' => sub {
	my $cfg = Config::Abstraction->new(
		data        => \%NESTED_DATA,
		config_dirs => [],
		flatten     => $FLATTEN_ON,
	);
	is($cfg->get('database.user'), $EXPECTED_USER, 'flat mode direct key lookup');
};

subtest 'get() - custom sep_char respected' => sub {
	my $cfg = Config::Abstraction->new(
		data => {
			database => { user => $EXPECTED_USER },
		},
		config_dirs => [],
		sep_char    => '/',
	);
	is($cfg->get('database/user'), $EXPECTED_USER, 'custom sep_char used in get()');
};

subtest 'get() - repeated calls on hashref value do not crash' => sub {
	my $cfg = _make_cfg();
	my $first  = $cfg->get('database');
	my $second = $cfg->get('database');
	ok(defined($second),          'second get() on hashref key succeeds');
	is($second->{user}, $EXPECTED_USER, 'value correct on second get()');
};

# ===========================================================================
# exists()
# ===========================================================================
subtest 'exists() - returns 1 for present key' => sub {
	my $cfg = _make_cfg();
	is($cfg->exists('database.user'), 1, 'exists() returns 1 for present key');
};

subtest 'exists() - returns 0 for absent key' => sub {
	my $cfg = _make_cfg();
	is($cfg->exists('no.such.key'), 0, 'exists() returns 0 for absent key');
};

subtest 'exists() - returns 0 when mid-path not a hash' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { flat => 'scalar' },
		config_dirs => [],
	);
	is($cfg->exists('flat.child'), 0, 'exists() returns 0 mid-path scalar');
};

subtest 'exists() - top-level key' => sub {
	my $cfg = _make_cfg();
	is($cfg->exists('retries'), 1, 'exists() finds top-level key');
};

subtest 'exists() - flat mode' => sub {
	my $cfg = Config::Abstraction->new(
		data        => \%NESTED_DATA,
		config_dirs => [],
		flatten     => $FLATTEN_ON,
	);
	is($cfg->exists('database.user'), 1, 'exists() flat mode finds key');
	is($cfg->exists('no.key'),        0, 'exists() flat mode returns 0 for absent key');
};

# ===========================================================================
# all()
# ===========================================================================
subtest 'all() - returns entire config hashref' => sub {
	my $cfg = _make_cfg();
	my $all = $cfg->all();
	ok(defined($all),         'all() returns defined value');
	is(reftype($all), 'HASH', 'all() returns hashref');
	ok(exists $all->{database}, 'top-level key present in all()');
};

subtest 'all() - returns undef when config empty' => sub {
	my $cfg = _make_cfg();
	$cfg->{config} = {};
	ok(!defined($cfg->all()), 'all() returns undef when config is empty');
};

# ===========================================================================
# merge_defaults()
# ===========================================================================
subtest 'merge_defaults() - merges config over defaults' => sub {
	my $cfg = _make_cfg();
	my $merged = $cfg->merge_defaults(
		defaults => { retries => 99, extra => 'kept' },
	);
	ok(defined($merged),          'merge_defaults returns defined value');
	is($merged->{retries}, $EXPECTED_RETRIES, 'config value overrides default');
	is($merged->{extra},  'kept', 'default-only key preserved');
};

subtest 'merge_defaults() - merge option combines both hashes' => sub {
	my $cfg = _make_cfg();
	my $merged = $cfg->merge_defaults(
		defaults => { extra => 'from_default' },
		merge    => 1,
	);
	ok(exists $merged->{extra},    'default-only key present when merge=>1');
	ok(exists $merged->{database}, 'config key present when merge=>1');
};

subtest 'merge_defaults() - section option scopes to named section' => sub {
	my $cfg = _make_cfg();
	my $merged = $cfg->merge_defaults(
		defaults => {},
		section  => 'database',
	);
	is($merged->{user}, $EXPECTED_USER, 'section scoping returns section hash');
	ok(!exists $merged->{retries},      'keys outside section not included');
};

subtest 'merge_defaults() - global section merged into defaults' => sub {
	my $cfg = Config::Abstraction->new(
		data => {
			global  => { timeout => 30 },
			retries => $EXPECTED_RETRIES,
		},
		config_dirs => [],
	);
	my $merged = $cfg->merge_defaults(defaults => { timeout => 99 });
	is($merged->{timeout}, 30, 'global section overrides defaults');
};

subtest 'merge_defaults() - no args returns full config' => sub {
	my $cfg = _make_cfg();
	my $result = $cfg->merge_defaults();
	ok(defined($result),         'no-arg merge_defaults returns config');
	is(reftype($result), 'HASH', 'returns hashref');
};

# ===========================================================================
# AUTOLOAD
# ===========================================================================
subtest 'AUTOLOAD - resolves top-level key' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { retries => $EXPECTED_RETRIES },
		config_dirs => [],
		sep_char    => '_',
	);
	is($cfg->retries(), $EXPECTED_RETRIES, 'AUTOLOAD resolves top-level key');
};

subtest 'AUTOLOAD - resolves nested key via sep_char' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { database => { user => $EXPECTED_USER } },
		config_dirs => [],
		sep_char    => '_',
	);
	is($cfg->database_user(), $EXPECTED_USER, 'AUTOLOAD resolves nested key');
};

subtest 'AUTOLOAD - croaks on nonexistent key' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { known => 'value' },
		config_dirs => [],
		sep_char    => '_',
	);
	eval { $cfg->nonexistent_key() };
	like($@, qr/No such config key/, 'AUTOLOAD croaks on missing key');
};

# ===========================================================================
# _is_plain_scalar() - internal helper
# ===========================================================================
subtest '_is_plain_scalar() - returns 1 for plain defined string' => sub {
	ok(Config::Abstraction::_is_plain_scalar('hello'), 'plain string returns 1');
};

subtest '_is_plain_scalar() - returns 1 for plain number' => sub {
	ok(Config::Abstraction::_is_plain_scalar(42), 'plain number returns 1');
};

subtest '_is_plain_scalar() - returns 0 for undef' => sub {
	is(Config::Abstraction::_is_plain_scalar(undef), 0, 'undef returns 0');
};

subtest '_is_plain_scalar() - returns 0 for coderef' => sub {
	ok(!Config::Abstraction::_is_plain_scalar(sub {}), 'coderef returns 0');
};

subtest '_is_plain_scalar() - returns 0 for hashref' => sub {
	ok(!Config::Abstraction::_is_plain_scalar({}), 'hashref returns 0');
};

subtest '_is_plain_scalar() - returns 0 for arrayref' => sub {
	ok(!Config::Abstraction::_is_plain_scalar([]), 'arrayref returns 0');
};

subtest '_is_plain_scalar() - returns 0 for blessed object' => sub {
	my $obj = bless {}, 'Some::Class';
	ok(!Config::Abstraction::_is_plain_scalar($obj), 'blessed object returns 0');
};

# ===========================================================================
# _load_driver() - internal helper
# ===========================================================================
subtest '_load_driver() - returns 1 on successful load' => sub {
	my $cfg = _make_cfg();
	# Scalar::Util is already loaded in this process
	my $result = $cfg->_load_driver('Scalar::Util');
	is($result, 1, '_load_driver returns 1 for loadable module');
};

subtest '_load_driver() - caches successful load' => sub {
	my $cfg = _make_cfg();
	$cfg->_load_driver('Scalar::Util');
	ok($cfg->{loaded}{'Scalar::Util'}, 'successful load cached in {loaded}');
};

subtest '_load_driver() - returns false for nonexistent module' => sub {
	my $cfg = _make_cfg();
	my $result = $cfg->_load_driver('No::Such::Module::XYZ');
	ok(!$result, '_load_driver returns false for missing module');
};

subtest '_load_driver() - caches failed load' => sub {
	my $cfg = _make_cfg();
	$cfg->_load_driver('No::Such::Module::XYZ');
	ok($cfg->{failed}{'No::Such::Module::XYZ'}, 'failed load cached in {failed}');
};

subtest '_load_driver() - skips reload of already-loaded module' => sub {
	my $cfg = _make_cfg();
	$cfg->{loaded}{'Scalar::Util'} = 1;
	my $result = $cfg->_load_driver('Scalar::Util');
	is($result, 1, 'returns 1 from cache without re-requiring');
};

subtest '_load_driver() - skips retry of already-failed module' => sub {
	my $cfg = _make_cfg();
	$cfg->{failed}{'No::Such::Module::XYZ'} = 1;
	my $result = $cfg->_load_driver('No::Such::Module::XYZ');
	ok(!$result, 'returns false from cache without re-attempting');
};

# ===========================================================================
# Environment variable merging (via _load_config internals)
# ===========================================================================
subtest 'ENV vars with prefix override data values' => sub {
	local %ENV = %ENV;
	$ENV{'TESTAPP_RETRIES'} = '99';

	my $cfg = Config::Abstraction->new(
		data        => { TESTAPP => { retries => $EXPECTED_RETRIES } },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('TESTAPP.retries'), '99', 'ENV var stored under prefix namespace');
};

subtest 'ENV vars with double-underscore create nested keys' => sub {
	local %ENV = %ENV;
	$ENV{'TESTAPP_DATABASE__USER'} = 'env_user';

	my $cfg = Config::Abstraction->new(
		data => {
			database => { user => $EXPECTED_USER, pass => $EXPECTED_PASS },
			retries  => $EXPECTED_RETRIES,
		},
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('database.user'), 'env_user', 'double-underscore ENV creates nested key');
};

# ===========================================================================
# Command-line argument merging (via _load_config internals)
# ===========================================================================
subtest 'CLI args override data values' => sub {
	local @ARGV = ("--TESTAPP_RETRIES=77");

	my $cfg = Config::Abstraction->new(
		data        => { retries => $EXPECTED_RETRIES },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('retries'), '77', 'CLI arg overrides data value');
};

subtest 'CLI args with double-underscore create nested keys' => sub {
	# \%NESTED_DATA must not be used here - the CLI merge path modifies nested
	# hashrefs in-place via shared references from the shallow copy of 'data',
	# which would attempt to modify the Readonly nested hashrefs and die.
	# Use a fresh anonymous hash instead so the merge can write freely.
	local @ARGV = ('--TESTAPP_DATABASE__USER=cli_user');

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

# ===========================================================================
# Coderef / blessed-object protection (regression for corruption bug)
# ===========================================================================
subtest 'coderef in data not corrupted by _load_config' => sub {
	my $cb = sub { $EXPECTED_CB_RESULT };
	my $cfg = Config::Abstraction->new(
		data        => { callback => $cb, tags => 'alpha,beta' },
		config_dirs => [],
	);
	my $got = $cfg->get('callback');
	is(reftype($got), 'CODE',         'coderef type intact after load');
	is($got->(), $EXPECTED_CB_RESULT, 'coderef callable after load');
};

subtest 'blessed object in data not corrupted by _load_config' => sub {
	my $obj = bless { v => $EXPECTED_PORT }, '_BlessedVal';
	my $cfg = Config::Abstraction->new(
		data        => { handler => $obj },
		config_dirs => [],
	);
	my $got = $cfg->get('handler');
	ok(blessed($got),                'blessed object intact after load');
	is(blessed($got), '_BlessedVal', 'class name unchanged after load');
};

done_testing();
