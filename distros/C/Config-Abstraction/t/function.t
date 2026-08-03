#!/usr/bin/perl

# White-box tests for Config::Abstraction public and internal methods.
# Uses Test::Mockingbird to mock non-core dependencies.

use strict;
use warnings;
use autodie qw(:all);

use Test::Most;
use Test::Mockingbird 0.12;
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

# ===========================================================================
# TestProxy -- minimal subclass that satisfies the UNIVERSAL::isa guard on
# _load_remote_dir and _parse_config_string.  Calling those methods directly
# from 'main' would croak; routing through a genuine subclass keeps the guard
# happy without altering the behaviour under test.
# ===========================================================================
package Config::Abstraction::TestProxy;
use parent -norequire, 'Config::Abstraction';
sub test_load_remote_dir     { my $self = shift; return $self->_load_remote_dir(@_)     }
sub test_parse_config_string { my $self = shift; return $self->_parse_config_string(@_) }
package main;

# Provide a minimal stub so remote-path tests run whether or not
# File::Slurp::Remote is installed.  Individual subtests mock the body.
unless(eval { require File::Slurp::Remote; 1 }) {
	no warnings 'once';
	*File::Slurp::Remote::read_file = sub {};
	$INC{'File/Slurp/Remote.pm'} = 1;
}

Readonly::Scalar my $REMOTE_HOST  => 'cfg.example.com';
Readonly::Scalar my $REMOTE_DIR   => '/etc/myapp';
Readonly::Scalar my $REMOTE_USER  => 'deploy';
Readonly::Scalar my $YAML_CONTENT => "---\nfoo: bar\nbaz: 42\n";
Readonly::Scalar my $JSON_CONTENT => '{"foo":"bar","baz":42}';
Readonly::Scalar my $INI_CONTENT  => "[section]\nkey=value\nother=123\n";

# ===========================================================================
# _parse_remote_dir()
# ===========================================================================
subtest '_parse_remote_dir() - returns empty list for a plain absolute path' => sub {
	my $cfg    = _make_cfg();
	my @result = $cfg->_parse_remote_dir('/etc/myapp');
	is(scalar(@result), 0, 'plain absolute path returns empty list');
};

subtest '_parse_remote_dir() - returns empty list for a relative path' => sub {
	my $cfg    = _make_cfg();
	my @result = $cfg->_parse_remote_dir('conf/local');
	is(scalar(@result), 0, 'relative path returns empty list');
};

subtest '_parse_remote_dir() - returns empty list for undef without error' => sub {
	my $cfg    = _make_cfg();
	my @result = $cfg->_parse_remote_dir(undef);
	is(scalar(@result), 0, 'undef returns empty list without dying');
};

subtest '_parse_remote_dir() - returns empty list for empty string' => sub {
	my $cfg    = _make_cfg();
	my @result = $cfg->_parse_remote_dir('');
	is(scalar(@result), 0, 'empty string returns empty list');
};

subtest '_parse_remote_dir() - parses /../host/path into (host, path)' => sub {
	my $cfg          = _make_cfg();
	my ($host, $dir) = $cfg->_parse_remote_dir("/../$REMOTE_HOST$REMOTE_DIR");
	is($host, $REMOTE_HOST, 'hostname extracted correctly');
	is($dir,  $REMOTE_DIR,  'directory path extracted correctly');
};

subtest '_parse_remote_dir() - preserves user@host format verbatim' => sub {
	# user@ must be left intact so _is_local_host can strip and compare it
	my $cfg          = _make_cfg();
	my $spec         = "$REMOTE_USER\@$REMOTE_HOST";
	my ($host, $dir) = $cfg->_parse_remote_dir("/../$spec$REMOTE_DIR");
	is($host, $spec,       'user@host preserved verbatim in returned hostname');
	is($dir,  $REMOTE_DIR, 'path still extracted correctly with user@host');
};

subtest '_parse_remote_dir() - defaults path to / when no path component given' => sub {
	my $cfg          = _make_cfg();
	my ($host, $dir) = $cfg->_parse_remote_dir("/../$REMOTE_HOST");
	is($host, $REMOTE_HOST, 'hostname extracted when path omitted');
	is($dir,  '/',          'path defaults to / when omitted');
};

# ===========================================================================
# _is_local_host()
# ===========================================================================
subtest '_is_local_host() - returns 1 for "localhost"' => sub {
	ok(_make_cfg()->_is_local_host('localhost'), '"localhost" is local');
};

subtest '_is_local_host() - loopback name matching is case-insensitive' => sub {
	my $cfg = _make_cfg();
	ok($cfg->_is_local_host('LOCALHOST'),  '"LOCALHOST" is local');
	ok($cfg->_is_local_host('LocalHost'), '"LocalHost" is local');
};

subtest '_is_local_host() - returns 1 for IPv4 loopback address' => sub {
	ok(_make_cfg()->_is_local_host('127.0.0.1'), '"127.0.0.1" is local');
};

subtest '_is_local_host() - returns 1 for IPv6 loopback address' => sub {
	ok(_make_cfg()->_is_local_host('::1'), '"::1" is local');
};

subtest '_is_local_host() - returns 0 for an obviously remote hostname' => sub {
	# Pick a name unlikely to match the FQDN or short name of any real machine
	ok(!_make_cfg()->_is_local_host('definitely-not-local-xyzzy-42.test'),
		'remote hostname returns 0');
};

subtest '_is_local_host() - returns 0 for undef without error' => sub {
	ok(!_make_cfg()->_is_local_host(undef), 'undef returns 0 without dying');
};

subtest '_is_local_host() - returns 0 for empty string' => sub {
	ok(!_make_cfg()->_is_local_host(''), 'empty string returns 0');
};

subtest '_is_local_host() - strips user@ prefix before comparing' => sub {
	my $cfg = _make_cfg();
	ok($cfg->_is_local_host("$REMOTE_USER\@localhost"),
		'user@localhost treated as local after stripping prefix');
	ok($cfg->_is_local_host("$REMOTE_USER\@127.0.0.1"),
		'user@127.0.0.1 treated as local after stripping prefix');
};

subtest '_is_local_host() - matches FQDN and short name from Sys::Hostname' => sub {
	# Mock Sys::Hostname so the test is deterministic on any machine and
	# exercises both the full-FQDN and domain-stripped short-name code paths.
	my $guard = mock_scoped 'Sys::Hostname::hostname' => sub { 'myserver.example.com' };
	my $cfg   = _make_cfg();
	ok($cfg->_is_local_host('myserver.example.com'),     'FQDN matches');
	ok($cfg->_is_local_host('MYSERVER.EXAMPLE.COM'),     'FQDN matches case-insensitively');
	ok($cfg->_is_local_host('myserver'),                 'short hostname matches');
	ok(!$cfg->_is_local_host('otherserver.example.com'), 'different FQDN does not match');
	ok(!$cfg->_is_local_host('myserver.other.com'),      'same short name, different domain rejected');
};

# ===========================================================================
# _slurp_remote()
# ===========================================================================
subtest '_slurp_remote() - returns file content verbatim on success' => sub {
	my $cfg   = _make_cfg();
	my $guard = mock_scoped 'File::Slurp::Remote::read_file' => sub { $YAML_CONTENT };
	is($cfg->_slurp_remote($REMOTE_HOST, "$REMOTE_DIR/base.yaml"),
		$YAML_CONTENT, 'file content returned verbatim');
};

subtest '_slurp_remote() - returns undef and does not propagate exceptions' => sub {
	my $cfg   = _make_cfg();
	my $guard = mock_scoped 'File::Slurp::Remote::read_file' => sub {
		die "Connection refused\n";
	};
	my $result;
	lives_ok { $result = $cfg->_slurp_remote($REMOTE_HOST, "$REMOTE_DIR/base.yaml") }
		'exception from read_file is caught, not re-thrown';
	ok(!defined($result), 'undef returned when read fails');
};

subtest '_slurp_remote() - logs at debug level on failure when a logger is present' => sub {
	my @logged;
	# Must bless the logger so new() does not try to wrap it in Log::Abstraction
	my $logger = bless {}, '_SlurpTestLogger';
	{
		no warnings 'once';
		*_SlurpTestLogger::debug = sub { push @logged, join('', @_[1..$#_]) };
		# Stub other log levels so new() and _load_config() don't croak
		for my $m (qw(trace info warn error)) {
			no strict 'refs';
			*{"_SlurpTestLogger::$m"} = sub {};
		}
	}

	my $cfg   = Config::Abstraction->new(data => \%NESTED_DATA, config_dirs => [], logger => $logger);
	my $guard = mock_scoped 'File::Slurp::Remote::read_file' => sub { die "SSH timeout\n" };
	$cfg->_slurp_remote($REMOTE_HOST, "$REMOTE_DIR/base.yaml");

	ok(scalar(@logged) > 0,     'at least one debug message emitted on failure');
	like($logged[0], qr/Could not read/, 'message describes the failure');
	diag("logged: $logged[0]") if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# _load_remote_dir() - access guard + functional behaviour via TestProxy
# ===========================================================================
subtest '_load_remote_dir() - croaks when called from outside the package hierarchy' => sub {
	my $cfg = _make_cfg();
	eval { $cfg->_load_remote_dir($REMOTE_HOST, $REMOTE_DIR, {}) };
	like($@, qr/Illegal Operation/, 'croaks with expected message for external caller');
};

subtest '_load_remote_dir() - warns and returns cleanly when driver is absent' => sub {
	my $cfg = Config::Abstraction::TestProxy->new(data => \%NESTED_DATA, config_dirs => []);
	# Inject the negative cache entry so _load_driver returns 0 without touching the FS
	$cfg->{failed}{'File::Slurp::Remote'} = 1;

	my %merged;
	my @warnings;
	my $guard = mock_scoped 'Carp::carp' => sub { push @warnings, $_[0] };
	lives_ok { $cfg->test_load_remote_dir($REMOTE_HOST, $REMOTE_DIR, \%merged) }
		'no crash when driver unavailable';
	ok(scalar(@warnings) > 0,   'warning emitted when File::Slurp::Remote is absent');
	is(scalar(keys %merged), 0, 'merged hash unchanged when driver is absent');
};

subtest '_load_remote_dir() - merges YAML data fetched from a remote file' => sub {
	my $cfg = Config::Abstraction::TestProxy->new(data => \%NESTED_DATA, config_dirs => []);
	$cfg->{loaded}{'File::Slurp::Remote'} = 1;	# skip driver require

	my %merged;
	my $guard = mock_scoped 'Config::Abstraction::_slurp_remote' => sub {
		my ($self, $host, $path) = @_;
		return $YAML_CONTENT if $path =~ /base\.yaml$/;
		return undef;	# all other standard files absent on remote
	};

	$cfg->test_load_remote_dir($REMOTE_HOST, $REMOTE_DIR, \%merged);

	is($merged{foo},    'bar', 'string value from remote YAML merged correctly');
	is($merged{baz},    42,    'integer value from remote YAML merged correctly');
	ok(scalar(@{$merged{config_path} // []}) > 0,      'config_path populated');
	like($merged{config_path}[0], qr/\Q$REMOTE_HOST\E/, 'config_path entry names the host');
	diag("config_path: $merged{config_path}[0]") if $ENV{TEST_VERBOSE};
};

subtest '_load_remote_dir() - leaves merged hash untouched when all fetches return undef' => sub {
	my $cfg = Config::Abstraction::TestProxy->new(data => \%NESTED_DATA, config_dirs => []);
	$cfg->{loaded}{'File::Slurp::Remote'} = 1;

	my %merged  = (pre_existing => 'value');
	my $guard   = mock_scoped 'Config::Abstraction::_slurp_remote' => sub { undef };
	$cfg->test_load_remote_dir($REMOTE_HOST, $REMOTE_DIR, \%merged);

	is($merged{pre_existing}, 'value', 'pre-existing key untouched when no files fetched');
	ok(!exists $merged{config_path},   'config_path not added when nothing loaded');
};

subtest '_load_remote_dir() - skips and warns when parsed data is not a hashref' => sub {
	# A YAML list parses fine but is not a valid config root -- must warn and skip
	my $cfg = Config::Abstraction::TestProxy->new(data => \%NESTED_DATA, config_dirs => []);
	$cfg->{loaded}{'File::Slurp::Remote'} = 1;

	my %merged;
	my @warnings;
	my $slurp_guard = mock_scoped 'Config::Abstraction::_slurp_remote' => sub {
		my ($self, $host, $path) = @_;
		return "- item1\n- item2\n" if $path =~ /base\.yaml$/;
		return undef;
	};
	my $carp_guard = mock_scoped 'Carp::carp' => sub { push @warnings, $_[0] };

	lives_ok { $cfg->test_load_remote_dir($REMOTE_HOST, $REMOTE_DIR, \%merged) }
		'non-hash remote result does not crash';
	ok(!exists $merged{foo},      'non-hash result not merged into config');
	ok(scalar(@warnings) > 0,    'warning emitted for non-hash result');
	like($warnings[0], qr/hash/i, 'warning message mentions hash');
};

# ===========================================================================
# _parse_config_string() - access guard + one subtest per supported format
# ===========================================================================
subtest '_parse_config_string() - croaks when called from outside the package hierarchy' => sub {
	my $cfg = _make_cfg();
	eval { $cfg->_parse_config_string($YAML_CONTENT, 'base.yaml', 'test') };
	like($@, qr/Illegal Operation/, 'croaks with expected message for external caller');
};

subtest '_parse_config_string() - parses YAML content correctly' => sub {
	my $cfg    = Config::Abstraction::TestProxy->new(data => \%NESTED_DATA, config_dirs => []);
	my $result = $cfg->test_parse_config_string($YAML_CONTENT, 'base.yaml', 'test');
	ok(defined($result),      'YAML returns defined value');
	is(ref($result), 'HASH',  'YAML returns a hashref');
	is($result->{foo}, 'bar', 'YAML string value correct');
	is($result->{baz}, 42,    'YAML integer value correct');
};

subtest '_parse_config_string() - parses JSON content correctly' => sub {
	my $cfg    = Config::Abstraction::TestProxy->new(data => \%NESTED_DATA, config_dirs => []);
	my $result = $cfg->test_parse_config_string($JSON_CONTENT, 'local.json', 'test');
	ok(defined($result),      'JSON returns defined value');
	is(ref($result), 'HASH',  'JSON returns a hashref');
	is($result->{foo}, 'bar', 'JSON string value correct');
	is($result->{baz}, 42,    'JSON integer value correct');
};

subtest '_parse_config_string() - parses INI content via a temp file' => sub {
	# Config::IniFiles requires a real path; the implementation writes to
	# File::Temp and removes it immediately after parsing
	my $cfg    = Config::Abstraction::TestProxy->new(data => \%NESTED_DATA, config_dirs => []);
	my $result = $cfg->test_parse_config_string($INI_CONTENT, 'base.ini', 'test');
	ok(defined($result),                  'INI returns defined value');
	is(ref($result), 'HASH',              'INI returns a hashref');
	is($result->{section}{key},   'value', 'INI key correct');
	is($result->{section}{other}, '123',   'INI second key correct');
};

subtest '_parse_config_string() - catches parser exceptions and returns undef' => sub {
	my $cfg = Config::Abstraction::TestProxy->new(data => \%NESTED_DATA, config_dirs => []);
	# Pre-populate cache so _load_driver short-circuits; then the mock on
	# YAML::XS::Load takes clean effect without an import side-effect.
	$cfg->{loaded}{'YAML::XS'} = 1;
	my $guard = mock_scoped 'YAML::XS::Load' => sub { die "synthetic parse failure\n" };

	my $result;
	lives_ok { $result = $cfg->test_parse_config_string('bad', 'base.yaml', 'test-label') }
		'parser exception caught, not re-thrown';
	ok(!defined($result), 'returns undef when parser dies');
};

subtest '_parse_config_string() - returns undef for an unrecognised file extension' => sub {
	# No format handler is registered for .toml; the inner eval exits without
	# setting $data and the method returns undef without logging anything
	my $cfg    = Config::Abstraction::TestProxy->new(data => \%NESTED_DATA, config_dirs => []);
	my $result = $cfg->test_parse_config_string('key = value', 'config.toml', 'test');
	ok(!defined($result), 'unrecognised extension returns undef');
};

subtest '_parse_config_string() - parses XML content via XML::Simple or XML::PP' => sub {
	# This exercises the elsif($filename =~ /\.xml$/i) branch which had 0 coverage hits
	my $cfg = Config::Abstraction::TestProxy->new(data => \%NESTED_DATA, config_dirs => []);
	my $xml = "<?xml version=\"1.0\" encoding=\"UTF-8\"?><config><key>xmlval</key><count>7</count></config>";
	my $result = $cfg->test_parse_config_string($xml, 'base.xml', 'test-xml-label');
	ok(defined($result),        'XML content returns defined value');
	is(ref($result), 'HASH',    'XML content returns a hashref');
	is($result->{key}, 'xmlval', 'XML string value parsed correctly');
	diag('XML result: ' . join(', ', map { "$_=$result->{$_}" } sort keys %{$result})) if $ENV{TEST_VERBOSE};
};

subtest '_parse_config_string() - returns undef for malformed INI (no valid sections)' => sub {
	# Config::IniFiles->new returns undef for content it cannot parse; the
	# method must return undef without crashing when the INI temp-file parse fails
	my $cfg = Config::Abstraction::TestProxy->new(data => \%NESTED_DATA, config_dirs => []);
	# An INI-extension file whose content has broken section syntax
	my $bad_ini = "[broken section\nkey=val\n";
	my $result;
	lives_ok { $result = $cfg->test_parse_config_string($bad_ini, 'config.ini', 'bad-ini') }
		'malformed INI does not crash _parse_config_string';
	ok(!defined($result), 'malformed INI returns undef');
};

# ===========================================================================
# _load_data_reuse() - caching layer around the optional Data::Reuse module
# ===========================================================================
subtest '_load_data_reuse() - returns 0 immediately when no_fixate is set' => sub {
	# no_fixate lets callers opt out of Data::Reuse entirely; the early
	# return must fire before any require is attempted
	my $cfg = _make_cfg(no_fixate => 1);
	is($cfg->_load_data_reuse(), 0, 'returns 0 when no_fixate flag is set');
};

subtest '_load_data_reuse() - returns 1 from positive cache without re-loading' => sub {
	my $cfg = _make_cfg();
	$cfg->{reuse_loaded} = 1;
	is($cfg->_load_data_reuse(), 1, 'returns 1 from reuse_loaded cache immediately');
};

subtest '_load_data_reuse() - returns 0 from negative cache without re-attempting' => sub {
	my $cfg = _make_cfg();
	$cfg->{reuse_failed} = 1;
	is($cfg->_load_data_reuse(), 0, 'returns 0 from reuse_failed cache immediately');
};

# ===========================================================================
# Add test_load_config to TestProxy so the access guard can be tested from a
# legitimate subclass caller (existing package block already declared above)
# ===========================================================================
{
	no warnings 'once';
	package Config::Abstraction::TestProxy;
	sub test_load_config { my $self = shift; $self->_load_config(@_) }
	package main;
}

# ===========================================================================
# returns_ok type assertions for core public API
# ===========================================================================
use Test::Returns;

subtest 'returns_ok: get() returns defined value for present key' => sub {
	my $cfg = _make_cfg();
	returns_ok($cfg->get('retries'), { type => 'scalar' }, 'get() returns scalar');
};

subtest 'returns_ok: all() returns hashref' => sub {
	my $cfg = _make_cfg();
	returns_ok($cfg->all(), { type => 'hashref' }, 'all() returns hashref');
};

subtest 'returns_ok: exists() returns integer' => sub {
	my $cfg = _make_cfg();
	returns_ok($cfg->exists('retries'), { type => 'integer' }, 'exists() integer return');
};

subtest 'returns_ok: explain_sources() returns hashref' => sub {
	my $cfg = _make_cfg();
	returns_ok($cfg->explain_sources(), { type => 'hashref' }, 'explain_sources() hashref');
};

# ===========================================================================
# get() and exists() - undef key guard (no warning, returns clean value)
# ===========================================================================
subtest 'get() - undef key returns undef without warning' => sub {
	my $cfg = _make_cfg();
	my @warns;
	local $SIG{__WARN__} = sub { push @warns, $_[0] };
	my $result;
	lives_ok { $result = $cfg->get(undef) } 'get(undef) does not die';
	ok(!defined($result),      'get(undef) returns undef');
	is(scalar(@warns), 0,     'get(undef) produces no warnings');
};

subtest 'exists() - undef key returns 0 without warning' => sub {
	my $cfg = _make_cfg();
	my @warns;
	local $SIG{__WARN__} = sub { push @warns, $_[0] };
	my $result;
	lives_ok { $result = $cfg->exists(undef) } 'exists(undef) does not die';
	is($result, 0,            'exists(undef) returns 0');
	is(scalar(@warns), 0,     'exists(undef) produces no warnings');
};

# ===========================================================================
# _get_environment() -- environment name resolution priority chain
# ===========================================================================
subtest '_get_environment() - returns undef when nothing configured' => sub {
	local %ENV = %ENV;
	delete $ENV{APP_ENV};
	delete $ENV{PLACK_ENV};
	delete $ENV{NODE_ENV};

	# Constructing with no environment option and no env vars
	my $cfg = Config::Abstraction->new(data => { x => 1 }, config_dirs => []);
	ok(!defined($cfg->_get_environment()), 'returns undef when no env is configured');
};

subtest '_get_environment() - empty string treated as undef (not an environment)' => sub {
	local %ENV = %ENV;
	delete $ENV{APP_ENV};
	$ENV{PLACK_ENV} = '';
	delete $ENV{NODE_ENV};

	my $cfg = Config::Abstraction->new(data => { x => 1 }, config_dirs => []);
	ok(!defined($cfg->_get_environment()), 'empty string returns undef');
};

subtest '_get_environment() - constructor option wins over all env vars' => sub {
	local %ENV = %ENV;
	$ENV{PLACK_ENV} = 'staging';
	$ENV{APP_ENV}   = 'test';

	my $cfg = Config::Abstraction->new(
		data        => { x => 1 },
		config_dirs => [],
		environment => 'production',
	);
	is($cfg->_get_environment(), 'production', 'constructor environment option wins');
};

subtest '_get_environment() - {prefix}ENV second priority' => sub {
	local %ENV = %ENV;
	delete $ENV{PLACK_ENV};
	delete $ENV{NODE_ENV};
	$ENV{APP_ENV} = 'development';

	my $cfg = Config::Abstraction->new(data => { x => 1 }, config_dirs => []);
	is($cfg->_get_environment(), 'development', 'APP_ENV used when no constructor option');
};

subtest '_get_environment() - PLACK_ENV is third priority' => sub {
	local %ENV = %ENV;
	delete $ENV{APP_ENV};
	delete $ENV{NODE_ENV};
	$ENV{PLACK_ENV} = 'staging';

	my $cfg = Config::Abstraction->new(data => { x => 1 }, config_dirs => []);
	is($cfg->_get_environment(), 'staging', 'PLACK_ENV used as fallback');
};

subtest '_get_environment() - NODE_ENV is lowest-priority fallback' => sub {
	local %ENV = %ENV;
	delete $ENV{APP_ENV};
	delete $ENV{PLACK_ENV};
	$ENV{NODE_ENV} = 'test';

	my $cfg = Config::Abstraction->new(data => { x => 1 }, config_dirs => []);
	is($cfg->_get_environment(), 'test', 'NODE_ENV used as last fallback');
};

subtest '_get_environment() - croaks for invalid characters in environment name' => sub {
	for my $bad_name ('prod/v2', 'staging@DC1', 'env name', 'prod:v1') {
		throws_ok {
			Config::Abstraction->new(
				data        => { x => 1 },
				config_dirs => [],
				environment => $bad_name,
			);
		} qr/invalid environment name/, "croaks for '$bad_name'";
	}
};

subtest '_get_environment() - accepts alphanumerics, hyphens, underscores' => sub {
	local %ENV = %ENV;
	delete $ENV{PLACK_ENV};
	delete $ENV{NODE_ENV};

	for my $valid ('production', 'staging-v2', 'env_01', 'gb', 'GB', 'US-EAST-1') {
		my $cfg;
		lives_ok {
			$cfg = Config::Abstraction->new(
				data        => { x => 1 },
				config_dirs => [],
				environment => $valid,
			);
		} "'$valid' accepted as environment name";
		is($cfg->_get_environment(), $valid, "get_environment returns '$valid'") if $cfg;
	}
};

# ===========================================================================
# _get_encryption_key() -- key source resolution chain
# ===========================================================================
Readonly::Scalar my $HEX_KEY_A => 'a' x 64;
Readonly::Scalar my $HEX_KEY_B => 'b' x 64;
Readonly::Scalar my $HEX_KEY_C => 'c' x 64;
Readonly::Scalar my $HEX_KEY_D => 'd' x 64;

subtest '_get_encryption_key() - returns undef when nothing configured' => sub {
	local %ENV = %ENV;
	delete $ENV{APP_ENCRYPTION_KEY};
	delete $ENV{ENCRYPTION_KEY};
	delete $ENV{APP_ENCRYPTION_KEY_FILE};
	delete $ENV{ENCRYPTION_KEY_FILE};

	my $cfg = Config::Abstraction->new(data => { x => 1 }, config_dirs => []);
	ok(!defined($cfg->_get_encryption_key()), 'returns undef with nothing configured');
};

subtest '_get_encryption_key() - constructor encryption_key takes highest priority' => sub {
	local %ENV = %ENV;
	$ENV{ENCRYPTION_KEY} = $HEX_KEY_B;	# would win if constructor didn't

	my $cfg = Config::Abstraction->new(
		data           => { x => 1 },
		config_dirs    => [],
		encryption_key => $HEX_KEY_A,
	);
	my $key = $cfg->_get_encryption_key();
	ok(defined($key),    'key resolved from constructor option');
	is(length($key), 32, 'decoded to 32 bytes');
};

subtest '_get_encryption_key() - {prefix}ENCRYPTION_KEY env var second priority' => sub {
	local %ENV = %ENV;
	delete $ENV{ENCRYPTION_KEY};
	delete $ENV{APP_ENCRYPTION_KEY_FILE};
	delete $ENV{ENCRYPTION_KEY_FILE};
	$ENV{APP_ENCRYPTION_KEY} = $HEX_KEY_B;

	my $cfg = Config::Abstraction->new(data => { x => 1 }, config_dirs => []);
	my $key = $cfg->_get_encryption_key();
	ok(defined($key),    '{prefix}ENCRYPTION_KEY env var used');
	is(length($key), 32, 'decoded to 32 bytes');
};

subtest '_get_encryption_key() - ENCRYPTION_KEY env var third priority' => sub {
	local %ENV = %ENV;
	delete $ENV{APP_ENCRYPTION_KEY};
	delete $ENV{APP_ENCRYPTION_KEY_FILE};
	delete $ENV{ENCRYPTION_KEY_FILE};
	$ENV{ENCRYPTION_KEY} = $HEX_KEY_C;

	my $cfg = Config::Abstraction->new(data => { x => 1 }, config_dirs => []);
	my $key = $cfg->_get_encryption_key();
	ok(defined($key),    'ENCRYPTION_KEY env var used');
	is(length($key), 32, 'decoded to 32 bytes');
};

subtest '_get_encryption_key() - reads key from encryption_key_file' => sub {
	local %ENV = %ENV;
	delete $ENV{APP_ENCRYPTION_KEY};
	delete $ENV{ENCRYPTION_KEY};
	delete $ENV{APP_ENCRYPTION_KEY_FILE};
	delete $ENV{ENCRYPTION_KEY_FILE};

	require File::Temp;
	my ($fh, $fname) = File::Temp::tempfile(SUFFIX => '.key', UNLINK => 1);
	print {$fh} $HEX_KEY_D . "\n";
	close $fh;

	my $cfg = Config::Abstraction->new(
		data                => { x => 1 },
		config_dirs         => [],
		encryption_key_file => $fname,
	);
	my $key = $cfg->_get_encryption_key();
	ok(defined($key),    'key read from encryption_key_file');
	is(length($key), 32, 'decoded to 32 bytes');
};

# ===========================================================================
# _decode_encryption_key() -- key format conversion
# ===========================================================================
subtest '_decode_encryption_key() - 32 raw bytes passed through unchanged' => sub {
	my $cfg = _make_cfg();
	my $raw = 'x' x 32;
	is($cfg->_decode_encryption_key($raw), $raw, '32 raw bytes unchanged');
};

subtest '_decode_encryption_key() - 64-char hex decoded to 32 bytes' => sub {
	my $cfg  = _make_cfg();
	my $key  = $cfg->_decode_encryption_key('0' x 64);
	is(length($key), 32,    '64 hex chars -> 32 bytes');
	is($key, "\x00" x 32,   'decoded bytes are correct zero bytes');
};

subtest '_decode_encryption_key() - hex is case-insensitive' => sub {
	my $cfg  = _make_cfg();
	my $k1   = $cfg->_decode_encryption_key('ab' x 32);
	my $k2   = $cfg->_decode_encryption_key('AB' x 32);
	is($k1, $k2, 'lowercase and uppercase hex decode to same bytes');
};

subtest '_decode_encryption_key() - base64url string decoded to 32 bytes' => sub {
	my $cfg    = _make_cfg();
	my $raw_32 = 'y' x 32;
	require MIME::Base64;
	my $b64url = MIME::Base64::encode_base64url($raw_32, '');
	my $key    = $cfg->_decode_encryption_key($b64url);
	is($key, $raw_32, 'base64url string decoded correctly');
	is(length($key), 32, 'decoded to 32 bytes');
	diag("base64url len: " . length($b64url)) if $ENV{TEST_VERBOSE};
};

subtest '_decode_encryption_key() - croaks for invalid key length' => sub {
	my $cfg = _make_cfg();
	throws_ok { $cfg->_decode_encryption_key('short') }
		qr/encryption_key must be/, '5-byte key croaks';
	throws_ok { $cfg->_decode_encryption_key('z' x 33) }
		qr/encryption_key must be/, '33-byte non-hex key croaks';
};

# ===========================================================================
# _validate_type() -- named type validation (package function, no $self)
# ===========================================================================
subtest '_validate_type() - integer: valid inputs pass' => sub {
	lives_ok { Config::Abstraction::_validate_type('p', '8080', 'integer') }  'positive integer ok';
	lives_ok { Config::Abstraction::_validate_type('p', '-1',   'integer') }  'negative integer ok';
	lives_ok { Config::Abstraction::_validate_type('p', '0',    'integer') }  'zero ok';
};

subtest '_validate_type() - integer: invalid inputs croak' => sub {
	throws_ok { Config::Abstraction::_validate_type('p', '3.14', 'integer') }
		qr/must be an integer/, 'float rejected';
	throws_ok { Config::Abstraction::_validate_type('p', 'abc',  'integer') }
		qr/must be an integer/, 'string rejected';
	throws_ok { Config::Abstraction::_validate_type('p', undef,  'integer') }
		qr/must be an integer/, 'undef rejected';
};

subtest '_validate_type() - number/float: valid inputs pass' => sub {
	lives_ok { Config::Abstraction::_validate_type('r', '3.14',  'number') } 'float ok';
	lives_ok { Config::Abstraction::_validate_type('r', '42',    'float')  } 'integer ok as float';
	lives_ok { Config::Abstraction::_validate_type('r', '-0.5',  'number') } 'negative float ok';
};

subtest '_validate_type() - number/float: non-numeric croaks' => sub {
	throws_ok { Config::Abstraction::_validate_type('r', 'abc', 'number') }
		qr/must be a number/, 'string rejected as number';
	throws_ok { Config::Abstraction::_validate_type('r', undef, 'float') }
		qr/must be a number/, 'undef rejected as float';
};

subtest '_validate_type() - boolean: all canonical forms accepted' => sub {
	for my $v (qw(1 0 true false yes no TRUE FALSE YES NO)) {
		lives_ok { Config::Abstraction::_validate_type('f', $v, 'boolean') }
			"'$v' accepted as boolean";
	}
};

subtest '_validate_type() - boolean: rejects ambiguous values' => sub {
	throws_ok { Config::Abstraction::_validate_type('f', 'maybe', 'boolean') }
		qr/must be a boolean/, '"maybe" rejected';
	throws_ok { Config::Abstraction::_validate_type('f', '2',     'boolean') }
		qr/must be a boolean/, '"2" rejected';
	throws_ok { Config::Abstraction::_validate_type('f', undef,   'boolean') }
		qr/must be a boolean/, 'undef rejected';
};

subtest '_validate_type() - string: defined non-ref scalars pass' => sub {
	lives_ok { Config::Abstraction::_validate_type('s', 'hello', 'string') } 'string ok';
	lives_ok { Config::Abstraction::_validate_type('s', '',      'string') } 'empty string ok';
	lives_ok { Config::Abstraction::_validate_type('s', '0',     'string') } '"0" ok as string';
};

subtest '_validate_type() - string: undef croaks' => sub {
	throws_ok { Config::Abstraction::_validate_type('s', undef, 'string') }
		qr/must be a defined string/, 'undef rejected by string type';
};

subtest '_validate_type() - array: arrayrefs pass, others croak' => sub {
	lives_ok { Config::Abstraction::_validate_type('a', [],    'array') } 'empty arrayref ok';
	lives_ok { Config::Abstraction::_validate_type('a', [1,2], 'array') } 'populated arrayref ok';
	throws_ok { Config::Abstraction::_validate_type('a', 'str', 'array') }
		qr/must be an array reference/, 'string rejected for array type';
	throws_ok { Config::Abstraction::_validate_type('a', {}, 'array') }
		qr/must be an array reference/, 'hashref rejected for array type';
};

subtest '_validate_type() - hash: hashrefs pass, others croak' => sub {
	lives_ok { Config::Abstraction::_validate_type('h', {},     'hash') } 'empty hashref ok';
	lives_ok { Config::Abstraction::_validate_type('h', {a=>1}, 'hash') } 'populated hashref ok';
	throws_ok { Config::Abstraction::_validate_type('h', [], 'hash') }
		qr/must be a hash reference/, 'arrayref rejected for hash type';
};

subtest '_validate_type() - unknown type name croaks' => sub {
	throws_ok { Config::Abstraction::_validate_type('x', 'val', 'datetime') }
		qr/unknown type 'datetime'/, 'unknown type name croaks with informative message';
};

# ===========================================================================
# _run_validators() -- validator dispatch via construction
# ===========================================================================
subtest '_run_validators() - type string: passes for valid value' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { port => '8080' },
		config_dirs => [],
		validators  => { port => 'integer' },
	);
	ok(defined($cfg), 'type-string validator passes for valid value');
};

subtest '_run_validators() - type string: croaks for invalid value' => sub {
	throws_ok {
		Config::Abstraction->new(
			data        => { port => '3.14' },
			config_dirs => [],
			validators  => { port => 'integer' },
		);
	} qr/must be an integer/, 'type-string validator croaks for invalid value';
};

subtest '_run_validators() - regex: passes when value matches' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { email => 'user@example.com' },
		config_dirs => [],
		validators  => { email => qr/\@/ },
	);
	ok(defined($cfg), 'regex validator passes for matching value');
};

subtest '_run_validators() - regex: croaks when value does not match' => sub {
	throws_ok {
		Config::Abstraction->new(
			data        => { email => 'not_valid' },
			config_dirs => [],
			validators  => { email => qr/\@/ },
		);
	} qr/does not match required pattern/, 'regex validator croaks for non-match';
};

subtest '_run_validators() - regex: croaks when value is undef' => sub {
	# The key is absent from data; get() returns undef; regex check requires defined
	throws_ok {
		Config::Abstraction->new(
			data        => { x => 1 },
			config_dirs => [],
			validators  => { absent_key => qr/.+/ },
		);
	} qr/does not match required pattern/, 'regex validator croaks for undef value';
};

subtest '_run_validators() - coderef: passes when returns true' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { level => 3 },
		config_dirs => [],
		validators  => { level => sub { $_[0] >= 1 && $_[0] <= 5 } },
	);
	ok(defined($cfg), 'coderef validator passes when it returns true');
};

subtest '_run_validators() - coderef: croaks when returns false' => sub {
	throws_ok {
		Config::Abstraction->new(
			data        => { level => 99 },
			config_dirs => [],
			validators  => { level => sub { $_[0] <= 5 } },
		);
	} qr/custom validator returned false/, 'coderef validator croaks when false';
};

subtest '_run_validators() - hashref spec: required key missing croaks' => sub {
	throws_ok {
		Config::Abstraction->new(
			data        => { x => 1 },
			config_dirs => [],
			validators  => { password => { required => 1 } },
		);
	} qr/required key .* is missing/, 'required field missing causes croak';
};

subtest '_run_validators() - hashref spec: min/max bounds enforced' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { retries => 3 },
		config_dirs => [],
		validators  => { retries => { type => 'integer', min => 1, max => 10 } },
	);
	ok(defined($cfg), 'in-range value passes min/max');

	throws_ok {
		Config::Abstraction->new(
			data        => { retries => 0 },
			config_dirs => [],
			validators  => { retries => { min => 1 } },
		);
	} qr/less than minimum/, 'below-min value croaks';

	throws_ok {
		Config::Abstraction->new(
			data        => { retries => 20 },
			config_dirs => [],
			validators  => { retries => { max => 10 } },
		);
	} qr/exceeds maximum/, 'above-max value croaks';
};

subtest '_run_validators() - hashref spec: pattern enforced' => sub {
	throws_ok {
		Config::Abstraction->new(
			data        => { code => 'abc' },
			config_dirs => [],
			validators  => { code => { pattern => qr/^[0-9]+$/ } },
		);
	} qr/does not match required pattern/, 'pattern in hashref spec enforced';
};

subtest '_run_validators() - arrayref spec type croaks with informative error' => sub {
	# Arrayrefs are not a valid validator spec; must croak clearly
	throws_ok {
		Config::Abstraction->new(
			data        => { x => 1 },
			config_dirs => [],
			validators  => { x => ['invalid', 'spec'] },
		);
	} qr/invalid validator/, 'arrayref spec croaks with helpful message';
};

# ===========================================================================
# _run_checker() -- Config::Checker structural validation
# ===========================================================================
subtest '_run_checker() - emits carp and returns cleanly when Config::Checker absent' => sub {
	my $cfg = _make_cfg();
	# Inject Config::Checker into the failure cache to simulate it being absent
	# without actually uninstalling it; this avoids %INC manipulation complexities
	$cfg->{'failed'}{'Config::Checker'} = 1;

	my @warnings;
	my $guard = mock_scoped 'Carp::carp' => sub { push @warnings, $_[0] };
	lives_ok { $cfg->_run_checker({ some => 'prototype' }) }
		'_run_checker does not croak when Config::Checker is absent';
	ok(scalar(@warnings) > 0,           'carp emitted when Config::Checker absent');
	like($warnings[0], qr/Config::Checker/, 'warning message names Config::Checker');
	diag("checker warning: $warnings[0]") if $ENV{TEST_VERBOSE} && @warnings;
};

subtest '_run_checker() - passes for valid config when Config::Checker is installed' => sub {
	plan skip_all => 'Config::Checker not installed'
		unless eval { require Config::Checker; 1 };

	# Suppress the spurious "uninitialized value $where" warning emitted by
	# Config::Checker.pm line 234; it is a bug in the installed module, not ours.
	local $SIG{__WARN__} = sub {
		warn @_ unless $_[0] =~ /uninitialized value \$where/;
	};

	my $cfg = Config::Abstraction->new(
		data        => { host => 'localhost', port => '8080' },
		config_dirs => [],
		checker     => { host => '', port => '' },
	);
	ok(defined($cfg), 'construction succeeds when config matches checker prototype');
};

# ===========================================================================
# encrypt_value() -- public AES-256-GCM encryption API
# ===========================================================================
Readonly::Scalar my $HAS_CRYPTX => eval {
	require Crypt::AuthEnc::GCM;
	require Crypt::PRNG;
	1;
} // 0;

subtest 'encrypt_value() - croaks when no encryption key configured' => sub {
	local %ENV = %ENV;
	delete $ENV{APP_ENCRYPTION_KEY};
	delete $ENV{ENCRYPTION_KEY};
	delete $ENV{APP_ENCRYPTION_KEY_FILE};
	delete $ENV{ENCRYPTION_KEY_FILE};

	my $cfg = Config::Abstraction->new(data => { x => 1 }, config_dirs => [], lazy => 1);
	throws_ok { $cfg->encrypt_value('val') }
		qr/no encryption key configured/, 'croaks without key';
};

subtest 'encrypt_value() - croaks when CryptX absent (simulated)' => sub {
	local %ENV = %ENV;
	$ENV{ENCRYPTION_KEY} = $HEX_KEY_A;

	my $cfg = Config::Abstraction->new(data => {}, config_dirs => [], lazy => 1);
	# Inject failure cache so _load_driver returns 0 for Crypt::AuthEnc::GCM
	$cfg->{'failed'}{'Crypt::AuthEnc::GCM'} = 1;
	throws_ok { $cfg->encrypt_value('val') }
		qr/CryptX.*is required/, 'croaks when Crypt::AuthEnc::GCM absent';
};

SKIP: {
	skip 'CryptX not installed', 5 unless $HAS_CRYPTX;

	subtest 'encrypt_value() - produces ENC[AES256GCM,...] token' => sub {
		my $cfg = Config::Abstraction->new(
			data           => {},
			config_dirs    => [],
			encryption_key => $HEX_KEY_A,
			lazy           => 1,
		);
		my $token = $cfg->encrypt_value('my_secret');
		like($token, qr/^ENC\[AES256GCM,/, 'token starts with ENC[AES256GCM,');
		like($token, qr/\]$/,              'token ends with ]');
		diag("token: $token") if $ENV{TEST_VERBOSE};
	};

	subtest 'encrypt_value() - same plaintext produces different tokens (fresh nonce)' => sub {
		my $cfg = Config::Abstraction->new(
			data           => {},
			config_dirs    => [],
			encryption_key => $HEX_KEY_B,
			lazy           => 1,
		);
		isnt($cfg->encrypt_value('secret'), $cfg->encrypt_value('secret'),
			'different token each call due to random nonce');
	};

	subtest 'encrypt_value() - round-trip via _decrypt_enc_value' => sub {
		my $cfg = Config::Abstraction->new(
			data           => {},
			config_dirs    => [],
			encryption_key => $HEX_KEY_C,
			lazy           => 1,
		);
		my $token     = $cfg->encrypt_value('round_trip_test');
		my $key       = $cfg->_get_encryption_key();
		my $plaintext = $cfg->_decrypt_enc_value($token, $key);
		is($plaintext, 'round_trip_test', 'round-trip recovers original plaintext');
	};

	subtest 'encrypt_value() - encrypts empty string without error' => sub {
		my $cfg = Config::Abstraction->new(
			data           => {},
			config_dirs    => [],
			encryption_key => $HEX_KEY_D,
			lazy           => 1,
		);
		my $token;
		lives_ok { $token = $cfg->encrypt_value('') } 'empty string encrypts without error';
		like($token, qr/^ENC\[/, 'empty string produces valid ENC token');
	};

	subtest 'encrypt_value() - returns_ok: token is a defined scalar' => sub {
		my $cfg = Config::Abstraction->new(
			data           => {},
			config_dirs    => [],
			encryption_key => $HEX_KEY_A,
			lazy           => 1,
		);
		returns_ok($cfg->encrypt_value('x'), { type => 'scalar' },
			'encrypt_value returns scalar string');
	};
}

# ===========================================================================
# _decrypt_enc_value() -- token decryption error paths (no CryptX needed)
# ===========================================================================
subtest '_decrypt_enc_value() - croaks for malformed ENC token (no closing bracket)' => sub {
	my $cfg = _make_cfg();
	throws_ok { $cfg->_decrypt_enc_value('ENC[AES256GCM,abc', 'x' x 32) }
		qr/malformed ENC token/, 'truncated token croaks';
};

subtest '_decrypt_enc_value() - croaks for unsupported algorithm in token' => sub {
	my $cfg = _make_cfg();
	require MIME::Base64;
	# 40-byte payload (>28) in base64url, but wrong algorithm name
	my $payload = MIME::Base64::encode_base64url('x' x 40, '');
	throws_ok { $cfg->_decrypt_enc_value("ENC[ChaCha20,$payload]", 'x' x 32) }
		qr/unsupported encryption algorithm/, 'unknown algo croaks';
};

subtest '_decrypt_enc_value() - croaks when payload too short for nonce+tag' => sub {
	my $cfg = _make_cfg();
	require MIME::Base64;
	# 27 bytes -- less than minimum of 28 (nonce 12 + tag 16)
	my $short = MIME::Base64::encode_base64url('x' x 27, '');
	throws_ok { $cfg->_decrypt_enc_value("ENC[AES256GCM,$short]", 'x' x 32) }
		qr/too short/, 'payload shorter than nonce+tag croaks';
};

SKIP: {
	skip 'CryptX not installed', 2 unless $HAS_CRYPTX;

	subtest '_decrypt_enc_value() - croaks when GCM tag verification fails' => sub {
		# Corrupt the first byte of the GCM authentication tag (last 16 of the
		# decoded payload) by XOR-ing with 0x01.  Doing this at the binary level
		# is reliable regardless of which base64url characters happen to appear at
		# the end of the encoded string (the previous regex approach failed whenever
		# the last char was a digit, underscore, or hyphen).
		require MIME::Base64;
		my $cfg = Config::Abstraction->new(
			data           => {},
			config_dirs    => [],
			encryption_key => $HEX_KEY_A,
			lazy           => 1,
		);
		my $token = $cfg->encrypt_value('original');
		$token =~ /^ENC\[AES256GCM,([A-Za-z0-9_\-]+)\]$/ or die "unexpected token format: $token";
		my $raw = MIME::Base64::decode_base64url($1);
		# XOR the first byte of the 16-byte GCM tag to guarantee a tag mismatch
		substr($raw, -16, 1) = chr(ord(substr($raw, -16, 1)) ^ 0x01);
		my $corrupted = 'ENC[AES256GCM,' . MIME::Base64::encode_base64url($raw, '') . ']';
		my $key = $cfg->_get_encryption_key();
		throws_ok { $cfg->_decrypt_enc_value($corrupted, $key) }
			qr/decryption failed/, 'tampered GCM tag causes authentication failure croak';
	};

	subtest '_decrypt_config_values() - terminates on circular references (regression: no $seen guard caused deep recursion under inverted-condition mutant)' => sub {
		my $cfg = Config::Abstraction->new(
			data           => {},
			config_dirs    => [],
			encryption_key => $HEX_KEY_B,
			lazy           => 1,
		);
		my $key = $cfg->_get_encryption_key();

		# Build a config hash that contains a cycle: $child points back to $parent.
		# Hash::Merge no-clone mode can produce shared/cyclic refs in production.
		# Without the $seen guard this call never returns.
		my $parent = { plain => 'ok' };
		my $child  = { up    => $parent };
		$parent->{down} = $child;

		# Must return without exhausting the stack.
		lives_ok { $cfg->_decrypt_config_values($parent, $key) }
			'does not recurse infinitely on a circular reference';
		is($parent->{plain}, 'ok', 'non-ENC leaf preserved through circular walk');
	};

	subtest '_decrypt_config_values() - decrypts nested leaves and skips config_path' => sub {
		my $cfg = Config::Abstraction->new(
			data           => {},
			config_dirs    => [],
			encryption_key => $HEX_KEY_B,
			lazy           => 1,
		);
		my $key   = $cfg->_get_encryption_key();
		my $token = $cfg->encrypt_value('nested_secret');

		my $config = {
			db          => { password => $token },
			plain       => 'not_encrypted',
			config_path => ['/etc/myapp'],  # must be skipped
		};
		$cfg->_decrypt_config_values($config, $key);

		is($config->{db}{password},   'nested_secret',  'nested ENC[] leaf decrypted');
		is($config->{plain},          'not_encrypted',   'plain leaf unchanged');
		is($config->{config_path}[0], '/etc/myapp',      'config_path array skipped');
	};
}

# ===========================================================================
# explain_sources() -- per-key source audit trail
# ===========================================================================
subtest 'explain_sources() - per-key audit structure is correct' => sub {
	my $cfg = _make_cfg();
	my $es  = $cfg->explain_sources();

	ok(defined($es),               'explain_sources returns defined value');
	is(ref($es), 'HASH',           'explain_sources returns hashref');
	ok(exists $es->{'retries'},    'top-level key has audit record');
	is(ref($es->{'retries'}{sources}), 'ARRAY', 'sources field is an arrayref');
};

subtest 'explain_sources() - data source recorded with correct type and label' => sub {
	my $cfg = _make_cfg();
	my $es  = $cfg->explain_sources();

	my @data_srcs = grep { $_->{type} eq 'data' } @{$es->{'retries'}{sources}};
	ok(scalar(@data_srcs) > 0,       'at least one data-layer source found');
	is($data_srcs[0]{label}, 'constructor data argument',
		'data source label is "constructor data argument"');
	is($data_srcs[0]{value}, $EXPECTED_RETRIES, 'data source value correct');
};

subtest 'explain_sources() - final value matches get() for same key' => sub {
	my $cfg = _make_cfg();
	my $es  = $cfg->explain_sources();
	is($es->{'retries'}{value}, $cfg->get('retries'),
		'explain_sources final value equals get() result');
};

subtest 'explain_sources() - env source recorded with env var name as label' => sub {
	local %ENV = %ENV;
	delete $ENV{APP_DATABASE__HOST};
	$ENV{APP_DATABASE__HOST} = 'env_host_value';

	my $cfg = Config::Abstraction->new(
		data        => { database => { host => 'default' } },
		config_dirs => [],
		env_prefix  => 'APP_',
	);
	my $es = $cfg->explain_sources();

	my @env_srcs = grep { $_->{type} eq 'env' } @{$es->{'database.host'}{sources}};
	ok(scalar(@env_srcs) > 0,                  'env source recorded');
	is($env_srcs[0]{label}, 'APP_DATABASE__HOST', 'env label is the env var name');
	is($env_srcs[0]{value}, 'env_host_value',     'env source value correct');
	diag("env source: " . $env_srcs[0]{label}) if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# _value_from_type() -- source record lookup internals
# ===========================================================================
subtest '_value_from_type() - (0, undef) for undef key' => sub {
	my $cfg = _make_cfg();
	my ($found, $val) = $cfg->_value_from_type('data', undef);
	is($found, 0,      'found=0 for undef key');
	ok(!defined($val), 'val=undef for undef key');
};

subtest '_value_from_type() - (1, value) for data-sourced key' => sub {
	my $cfg = _make_cfg();
	my ($found, $val) = $cfg->_value_from_type('data', 'retries');
	is($found, 1,                 'found=1');
	is($val,   $EXPECTED_RETRIES, 'correct value');
};

subtest '_value_from_type() - (0, undef) when type did not contribute' => sub {
	# No CLI args in @ARGV, so argv layer should not have contributed
	local @ARGV = ();
	my $cfg = _make_cfg();
	my ($found, $val) = $cfg->_value_from_type('argv', 'retries');
	ok(!$found,        'found is false when argv did not set the key');
	ok(!defined($val), 'val=undef when argv did not contribute');
};

subtest '_value_from_type() - normalises sep_char to dot before lookup' => sub {
	# Source records always use '.' regardless of sep_char.
	# _value_from_type must translate sep_char-separated keys before searching.
	my $cfg = Config::Abstraction->new(
		data        => { database => { user => $EXPECTED_USER } },
		config_dirs => [],
		sep_char    => '/',
	);
	my ($found, $val) = $cfg->_value_from_type('data', 'database/user');
	is($found, 1,                'sep_char normalised to dot for record lookup');
	is($val,   $EXPECTED_USER,   'correct value after normalisation');
};

# ===========================================================================
# prefer_env() / prefer_file() / prefer_data() / prefer_argv()
# ===========================================================================
subtest 'prefer_data() - returns data-layer value even when file overrides it' => sub {
	plan skip_all => 'requires filesystem' if $^O eq 'MSWin32';
	require File::Temp;
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	open my $fh, '>', "$dir/base.yaml" or die "Cannot write: $!";
	print $fh "retries: 99\n";
	close $fh;

	my $cfg = Config::Abstraction->new(
		data        => { retries => $EXPECTED_RETRIES },
		config_dirs => [$dir],
	);
	# file sets retries=99; prefer_data must bypass the file and return the data value
	is($cfg->prefer_data('retries'), $EXPECTED_RETRIES,
		'prefer_data returns data value (3) despite file override (99)');
	is($cfg->get('retries'), 99, 'get() confirms file override wins in merged config');
};

subtest 'prefer_data() - falls back to get() when data layer did not set the key' => sub {
	plan skip_all => 'requires filesystem' if $^O eq 'MSWin32';
	require File::Temp;
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	open my $fh, '>', "$dir/base.yaml" or die;
	print $fh "only_in_file: yes\n";
	close $fh;

	my $cfg = Config::Abstraction->new(
		data        => { something_else => 1 },
		config_dirs => [$dir],
	);
	is($cfg->prefer_data('only_in_file'), 'yes',
		'prefer_data falls back to get() for key not in data layer');
};

subtest 'prefer_env() - returns env value, not higher-priority argv override' => sub {
	local %ENV = %ENV;
	delete $ENV{APP_DATABASE__HOST};
	$ENV{APP_DATABASE__HOST} = 'env-host';
	local @ARGV = ('--APP_DATABASE__HOST=argv-host');

	my $cfg = Config::Abstraction->new(
		data        => { database => { host => 'default' } },
		config_dirs => [],
		env_prefix  => 'APP_',
	);
	is($cfg->prefer_env('database.host'), 'env-host',
		'prefer_env returns env value, bypassing argv');
	is($cfg->get('database.host'), 'argv-host',
		'get() confirms argv wins in merged config');
};

subtest 'prefer_env() - falls back to get() when no env contributed' => sub {
	local %ENV = %ENV;
	delete $ENV{APP_RETRIES};

	my $cfg = _make_cfg();
	is($cfg->prefer_env('retries'), $EXPECTED_RETRIES,
		'prefer_env falls back to get() when env did not contribute');
};

subtest 'prefer_argv() - returns argv value when CLI arg provided' => sub {
	local @ARGV = ('--APP_DATABASE__HOST=argv-host');
	local %ENV  = %ENV;
	delete $ENV{APP_DATABASE__HOST};

	my $cfg = Config::Abstraction->new(
		data        => { database => { host => 'default' } },
		config_dirs => [],
		env_prefix  => 'APP_',
	);
	is($cfg->prefer_argv('database.host'), 'argv-host',
		'prefer_argv returns argv-layer value');
};

subtest 'prefer_argv() - falls back to get() when no argv contributed' => sub {
	local @ARGV = ();
	my $cfg = _make_cfg();
	is($cfg->prefer_argv('retries'), $EXPECTED_RETRIES,
		'prefer_argv falls back to get() when @ARGV did not contribute');
};

subtest 'prefer_file() - returns file value when a file set the key' => sub {
	plan skip_all => 'requires filesystem' if $^O eq 'MSWin32';
	require File::Temp;
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	open my $fh, '>', "$dir/base.yaml" or die;
	print $fh "retries: 99\n";
	close $fh;

	local %ENV = %ENV;
	delete $ENV{APP_RETRIES};

	my $cfg = Config::Abstraction->new(
		data        => { retries => $EXPECTED_RETRIES },
		config_dirs => [$dir],
	);
	is($cfg->prefer_file('retries'), 99,
		'prefer_file returns file-layer value (99)');
};

subtest 'prefer_file() - falls back to get() when no file set the key' => sub {
	# data-only config: no file layer contributed
	my $cfg = _make_cfg();
	is($cfg->prefer_file('retries'), $EXPECTED_RETRIES,
		'prefer_file falls back to get() when no file contributed');
};

# ===========================================================================
# _flatten_keys() -- nested hash flattening (package function, no $self)
# ===========================================================================
subtest '_flatten_keys() - three-level nesting produces dotted key' => sub {
	my %flat = Config::Abstraction::_flatten_keys({ a => { b => { c => 'leaf' } } });
	is($flat{'a.b.c'}, 'leaf', 'three-level nesting produces a.b.c');
	is(scalar(keys %flat), 1,  'exactly one key');
};

subtest '_flatten_keys() - top-level scalars passed through' => sub {
	my %flat = Config::Abstraction::_flatten_keys({ x => 1, y => 'str' });
	is($flat{x}, 1,     'integer preserved');
	is($flat{y}, 'str', 'string preserved');
};

subtest '_flatten_keys() - config_path key skipped at every level' => sub {
	my %flat = Config::Abstraction::_flatten_keys({
		normal      => 'v',
		config_path => ['/path'],
		nested      => { config_path => ['/n'] },
	});
	ok( exists $flat{normal},             'normal key present');
	ok(!exists $flat{config_path},        'top-level config_path skipped');
};

subtest '_flatten_keys() - empty hash gives empty flat hash' => sub {
	my %flat = Config::Abstraction::_flatten_keys({});
	is(scalar(keys %flat), 0, 'empty input -> empty output');
};

subtest '_flatten_keys() - circular reference handled without infinite loop' => sub {
	my $h = { a => 1 };
	$h->{self} = $h;
	my %flat;
	lives_ok { %flat = Config::Abstraction::_flatten_keys($h) }
		'circular reference does not cause infinite recursion';
	ok(exists $flat{a}, 'non-circular key still present');
};

subtest '_flatten_keys() - optional prefix prepended to keys' => sub {
	my %flat = Config::Abstraction::_flatten_keys({ b => 2 }, 'prefix');
	ok(exists  $flat{'prefix.b'}, 'prefix.b exists');
	is($flat{'prefix.b'}, 2,      'prefix.b value correct');
	ok(!exists $flat{b},          'unprefixed key absent');
};

# ===========================================================================
# _ensure_loaded() -- lazy loading lifecycle
# ===========================================================================
subtest '_ensure_loaded() - lazy object loads config on first accessor call' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { lazy_key => 'lazy_val' },
		config_dirs => [],
		lazy        => 1,
	);
	ok($cfg->{'lazy'}, 'lazy flag set before any accessor call');
	is($cfg->get('lazy_key'), 'lazy_val', 'first get() loads and returns value');
	ok(!$cfg->{'lazy'},       'lazy flag cleared after first access');
};

subtest '_ensure_loaded() - loads config exactly once regardless of accessor count' => sub {
	my $call_count = 0;
	my $guard = mock_scoped 'Config::Abstraction::_load_config' => sub {
		$call_count++;
		my $self = shift;
		$self->{'config'} = { key => 'val' };
	};

	my $cfg = Config::Abstraction->new(
		data        => { x => 1 },
		config_dirs => [],
		lazy        => 1,
	);
	$cfg->get('key');      # first
	$cfg->get('key');      # second
	$cfg->all();           # third
	$cfg->exists('key');   # fourth
	is($call_count, 1, '_load_config called exactly once despite multiple accessors');
};

subtest '_ensure_loaded() - defers validators to first access' => sub {
	my $validated = 0;
	my $cfg = Config::Abstraction->new(
		data        => { count => '5' },
		config_dirs => [],
		lazy        => 1,
		validators  => { count => sub { $validated++; 1 } },
	);
	is($validated, 0, 'validator not called at construction with lazy=>1');
	$cfg->get('count');
	is($validated, 1, 'validator triggered on first access');
};

subtest '_ensure_loaded() - non-lazy object is a no-op' => sub {
	my $cfg = _make_cfg();
	ok(!$cfg->{'lazy'}, 'non-lazy object has no lazy flag');
	# _ensure_loaded must not croak or alter the object for non-lazy objects
	lives_ok { $cfg->_ensure_loaded() } '_ensure_loaded is a no-op on non-lazy objects';
	ok(defined($cfg->get('retries')), 'config still accessible after redundant _ensure_loaded');
};

# ===========================================================================
# _load_config() -- access guard
# ===========================================================================
subtest '_load_config() - croaks when called from outside package hierarchy' => sub {
	my $cfg = _make_cfg();
	eval { $cfg->_load_config() };
	like($@, qr/Illegal Operation/, '_load_config croaks for caller outside the hierarchy');
};

subtest '_load_config() - accessible via subclass (TestProxy)' => sub {
	my $cfg = Config::Abstraction::TestProxy->new(
		data        => { x => 99 },
		config_dirs => [],
	);
	lives_ok { $cfg->test_load_config() } '_load_config accessible from a subclass';
};

# ===========================================================================
# _load_remote_dir() -- file list argument regression
# ===========================================================================
subtest '_load_remote_dir() - uses the passed file list verbatim' => sub {
	# Regression: before the fix, _load_remote_dir had a hardcoded file list that
	# omitted TOML files and environment-specific tiers.  Now it uses the list
	# passed in from _load_config so both features are supported remotely too.
	my $cfg = Config::Abstraction::TestProxy->new(data => \%NESTED_DATA, config_dirs => []);
	$cfg->{loaded}{'File::Slurp::Remote'} = 1;

	my @fetched;
	my $guard = mock_scoped 'Config::Abstraction::_slurp_remote' => sub {
		my ($self, $host, $path) = @_;
		push @fetched, (split '/', $path)[-1];
		return undef;
	};

	my @custom_list = ('base.yaml', 'base.prod.yaml', 'local.yaml', 'local.prod.yaml', 'base.toml');
	my %merged;
	$cfg->test_load_remote_dir($REMOTE_HOST, $REMOTE_DIR, \%merged, \@custom_list);

	is_deeply(\@fetched, \@custom_list,
		'remote dir used the passed file list (including env-specific and TOML files)');
};

subtest '_load_remote_dir() - falls back to default file list when 4th arg absent' => sub {
	my $cfg = Config::Abstraction::TestProxy->new(data => \%NESTED_DATA, config_dirs => []);
	$cfg->{loaded}{'File::Slurp::Remote'} = 1;

	my @fetched;
	my $guard = mock_scoped 'Config::Abstraction::_slurp_remote' => sub {
		my ($self, $host, $path) = @_;
		push @fetched, (split '/', $path)[-1];
		return undef;
	};

	my %merged;
	$cfg->test_load_remote_dir($REMOTE_HOST, $REMOTE_DIR, \%merged);  # no 4th arg

	ok(scalar(@fetched) > 0,                    'some files fetched from fallback list');
	ok((grep { /^base\.yaml$/ } @fetched),       'base.yaml in fallback list');
	ok((grep { /^local\.yaml$/ } @fetched),      'local.yaml in fallback list');
};

# ===========================================================================
# AUTOLOAD regressions
# ===========================================================================
subtest 'AUTOLOAD regression: uses merged config, not stale data defaults' => sub {
	# Before the fix, AUTOLOAD used $self->{data} (raw defaults) instead of
	# $self->{'config'} (merged result).  File overrides were invisible.
	plan skip_all => 'requires filesystem' if $^O eq 'MSWin32';
	require File::Temp;
	my $dir = File::Temp::tempdir(CLEANUP => 1);
	open my $fh, '>', "$dir/base.yaml" or die;
	print $fh "level: file_value\n";
	close $fh;

	my $cfg = Config::Abstraction->new(
		data        => { level => 'data_value' },
		config_dirs => [$dir],
		sep_char    => '_',
	);
	is($cfg->level(), 'file_value',
		'AUTOLOAD returns file-overridden value, not stale data default');
};

subtest 'AUTOLOAD regression: flatten mode translates sep_char to dot for lookup' => sub {
	# Hash::Flatten always uses '.' regardless of sep_char.
	# AUTOLOAD must convert the sep_char-separated method name to dotted form before lookup.
	my $cfg = Config::Abstraction->new(
		data        => { database => { port => $EXPECTED_PORT } },
		config_dirs => [],
		flatten     => $FLATTEN_ON,
		sep_char    => '_',
	);
	is($cfg->database_port(), $EXPECTED_PORT,
		'AUTOLOAD in flatten mode translates _ separator to . for flat config lookup');
};

subtest 'AUTOLOAD regression: flatten mode croaks for absent key' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { known => 1 },
		config_dirs => [],
		flatten     => $FLATTEN_ON,
		sep_char    => '_',
	);
	throws_ok { $cfg->no_such_key() }
		qr/No such config key/, 'AUTOLOAD flatten mode croaks for absent key';
};

# ===========================================================================
# Test::Memory::Cycle -- verify no circular references in key object types
# ===========================================================================
require Test::Memory::Cycle;

subtest 'memory_cycle_ok: standard config object has no circular refs' => sub {
	my $cfg = _make_cfg();
	Test::Memory::Cycle::memory_cycle_ok($cfg, 'basic config object');
};

subtest 'memory_cycle_ok: lazy object before and after load' => sub {
	my $cfg = Config::Abstraction->new(
		data        => \%NESTED_DATA,
		config_dirs => [],
		lazy        => 1,
	);
	Test::Memory::Cycle::memory_cycle_ok($cfg, 'lazy object before load');
	$cfg->get('retries');
	Test::Memory::Cycle::memory_cycle_ok($cfg, 'lazy object after load');
};

subtest 'memory_cycle_ok: explain_sources result' => sub {
	my $cfg = _make_cfg();
	Test::Memory::Cycle::memory_cycle_ok($cfg->explain_sources(), 'explain_sources result');
};

done_testing();

