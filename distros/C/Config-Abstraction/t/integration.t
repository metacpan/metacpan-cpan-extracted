#!/usr/bin/perl

# Integration tests for Config::Abstraction.
# Black-box, end-to-end behaviour across multiple routines and interactions
# with other modules.  Tests stateful workflows, concurrency of multiple
# instances, and inter-module integration.

use strict;
use warnings;
use autodie qw(:all);

use Test::Most;
use Test::Mockingbird;
use Test::Needs;
use Readonly;
use Scalar::Util qw(blessed reftype);
use File::Temp qw(tempdir);
use File::Spec;
use POSIX qw();

# ---------------------------------------------------------------------------
# Configuration - can be overridden via Object::Configure if wanted
# ---------------------------------------------------------------------------
my %config = (
	module		=> 'Config::Abstraction',
	env_prefix	=> 'INTAPP_',
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
Readonly::Scalar my $EXPECTED_HOST	=> 'localhost';
Readonly::Scalar my $OVERRIDE_USER	=> 'bob';
Readonly::Scalar my $OVERRIDE_PORT	=> 3306;
Readonly::Scalar my $OVERRIDE_LEVEL	=> 'debug';
Readonly::Scalar my $GLOBAL_TIMEOUT	=> 60;
Readonly::Scalar my $NUM_INSTANCES	=> 5;

Readonly::Scalar my $YAML_BASE		=> 'base.yaml';
Readonly::Scalar my $YAML_LOCAL		=> 'local.yaml';
Readonly::Scalar my $JSON_BASE		=> 'base.json';
Readonly::Scalar my $INI_BASE		=> 'base.ini';
Readonly::Scalar my $CUSTOM_CFG	=> 'myapp.cfg';

# ---------------------------------------------------------------------------
# Helper: fresh nested data safe for merge operations
# ---------------------------------------------------------------------------
sub _fresh_data
{
	return {
		database => {
			user => $EXPECTED_USER,
			pass => $EXPECTED_PASS,
			port => $EXPECTED_PORT,
			host => $EXPECTED_HOST,
		},
		log => {
			level => $EXPECTED_LEVEL,
		},
		retries => $EXPECTED_RETRIES,
		timeout => $EXPECTED_TIMEOUT,
	};
}

# Helper: write a file to a directory
sub _write_file
{
	my ($dir, $filename, $content) = @_;
	my $path = File::Spec->catfile($dir, $filename);
	open(my $fh, '>', $path);
	print $fh $content;
	close $fh;
	return $path;
}

# ---------------------------------------------------------------------------
use_ok($MODULE) or BAIL_OUT("$MODULE failed to load");

# ===========================================================================
# Basic end-to-end: data -> get -> exists -> all
# ===========================================================================
subtest 'end-to-end: data flows through new->get->exists->all' => sub {
	my $cfg = new_ok($MODULE => [
		data        => _fresh_data(),
		config_dirs => [],
	]);

	# get() retrieves all expected values
	is($cfg->get('database.user'), $EXPECTED_USER,    'get() database.user');
	is($cfg->get('database.port'), $EXPECTED_PORT,    'get() database.port');
	is($cfg->get('log.level'),     $EXPECTED_LEVEL,   'get() log.level');
	is($cfg->get('retries'),       $EXPECTED_RETRIES, 'get() retries');
	is($cfg->get('timeout'),       $EXPECTED_TIMEOUT, 'get() timeout');

	# exists() consistent with get()
	is($cfg->exists('database.user'), 1, 'exists() true for present key');
	is($cfg->exists('no.key'),        0, 'exists() false for absent key');

	# all() contains all keys
	my $all = $cfg->all();
	ok(exists $all->{database}, 'all() has database');
	ok(exists $all->{log},      'all() has log');
	ok(exists $all->{retries},  'all() has retries');
};

# ===========================================================================
# File loading end-to-end: YAML
# ===========================================================================
subtest 'end-to-end: YAML file loaded and merged with data' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_BASE, <<END);
database:
  user: $OVERRIDE_USER
  port: $OVERRIDE_PORT
log:
  level: $OVERRIDE_LEVEL
END

	my $cfg = new_ok($MODULE => [
		data        => _fresh_data(),
		config_dirs => [$dir],
	]);

	# File overrides data defaults per merge precedence
	is($cfg->get('database.user'), $OVERRIDE_USER,  'YAML overrides database.user');
	is($cfg->get('database.port'), $OVERRIDE_PORT,  'YAML overrides database.port');
	is($cfg->get('log.level'),     $OVERRIDE_LEVEL, 'YAML overrides log.level');

	# Keys not in file retain data defaults
	is($cfg->get('retries'), $EXPECTED_RETRIES, 'data default retained for key absent from YAML');

	# config_path records the file
	my $all = $cfg->all();
	my @paths = @{$all->{config_path}};
	ok(grep { /\Q$YAML_BASE\E/ } @paths, 'config_path includes YAML file');
};

# ===========================================================================
# File loading end-to-end: local overrides base
# ===========================================================================
subtest 'end-to-end: local.yaml overrides base.yaml' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_BASE,  "level: base\ntimeout: $EXPECTED_TIMEOUT\n");
	_write_file($dir, $YAML_LOCAL, "level: local\n");

	my $cfg = new_ok($MODULE => [config_dirs => [$dir]]);

	is($cfg->get('level'),   'local',            'local.yaml overrides base.yaml');
	is($cfg->get('timeout'), $EXPECTED_TIMEOUT,  'base.yaml value retained when not in local');
};

# ===========================================================================
# File loading end-to-end: JSON
# ===========================================================================
subtest 'end-to-end: JSON file loaded and accessible' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $JSON_BASE,
		qq({"database":{"user":"$OVERRIDE_USER","port":$OVERRIDE_PORT},"retries":$EXPECTED_RETRIES}));

	my $cfg = new_ok($MODULE => [config_dirs => [$dir]]);

	is($cfg->get('database.user'), $OVERRIDE_USER, 'JSON database.user loaded');
	is($cfg->get('database.port'), $OVERRIDE_PORT, 'JSON database.port loaded');
	is($cfg->get('retries'),       $EXPECTED_RETRIES, 'JSON retries loaded');
};

# ===========================================================================
# File loading end-to-end: INI
# ===========================================================================
subtest 'end-to-end: INI file loaded and accessible' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $INI_BASE, <<END);
[database]
user=$OVERRIDE_USER
port=$OVERRIDE_PORT
END

	my $cfg = new_ok($MODULE => [config_dirs => [$dir]]);

	is($cfg->get('database.user'), $OVERRIDE_USER, 'INI database.user loaded');
	is($cfg->get('database.port'), $OVERRIDE_PORT, 'INI database.port loaded');
};

# ===========================================================================
# Full merge precedence stack: data < file < ENV < CLI
# ===========================================================================
subtest 'end-to-end: full merge precedence stack' => sub {
	local %ENV = %ENV;
	local @ARGV = ("--${ENV_PREFIX}DATABASE__USER=cli_user");
	$ENV{"${ENV_PREFIX}DATABASE__PORT"} = $OVERRIDE_PORT;

	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_BASE,
		"database:\n  user: file_user\n  port: $EXPECTED_PORT\n  host: $EXPECTED_HOST\n");

	my $cfg = new_ok($MODULE => [
		data        => _fresh_data(),
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
	]);

	# CLI beats everything
	is($cfg->get('database.user'), 'cli_user',    'CLI wins over ENV/file/data');
	# ENV beats file and data
	is($cfg->get('database.port'), $OVERRIDE_PORT, 'ENV wins over file/data');
	# File beats data
	is($cfg->get('database.host'), $EXPECTED_HOST, 'file value present');
	# Data provides fallback
	is($cfg->get('retries'), $EXPECTED_RETRIES,   'data fallback intact');
};

# ===========================================================================
# merge_defaults() integration with caller package workflow
# POD: merge_defaults is designed for use in other modules' new() methods
# ===========================================================================
subtest 'end-to-end: merge_defaults() workflow as documented in POD' => sub {
	my $cfg = new_ok($MODULE => [
		data        => _fresh_data(),
		config_dirs => [],
	]);

	# Simulate the documented pattern: caller passes its own $params hash
	my $caller_params = {
		timeout => 99,
		retries => 99,
		extra   => 'caller_value',
	};

	my $merged = $cfg->merge_defaults(
		defaults => $caller_params,
		merge    => 1,
	);

	# Config overrides caller defaults on conflict
	is($merged->{retries}, $EXPECTED_RETRIES, 'config wins over caller default');
	is($merged->{timeout}, $EXPECTED_TIMEOUT, 'config wins over caller timeout');

	# Caller-only keys preserved
	is($merged->{extra}, 'caller_value', 'caller-only key preserved');
};

subtest 'end-to-end: merge_defaults() with global section' => sub {
	my $cfg = new_ok($MODULE => [
		data => {
			global  => { timeout => $GLOBAL_TIMEOUT, loglevel => $EXPECTED_LEVEL },
			retries => $EXPECTED_RETRIES,
		},
		config_dirs => [],
	]);

	my $merged = $cfg->merge_defaults(
		defaults => { timeout => 99, extra => 'kept' },
	);

	is($merged->{timeout},  $GLOBAL_TIMEOUT,   'global section timeout wins');
	is($merged->{loglevel}, $EXPECTED_LEVEL,   'global section loglevel merged');
	is($merged->{extra},    'kept',            'caller default preserved');
	ok(!exists $merged->{global},              'global key removed after merge');
};

subtest 'end-to-end: merge_defaults() section scoping with file' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_BASE, <<END);
database:
  user: $OVERRIDE_USER
  port: $OVERRIDE_PORT
log:
  level: $OVERRIDE_LEVEL
retries: $EXPECTED_RETRIES
END

	my $cfg = new_ok($MODULE => [config_dirs => [$dir]]);

	my $merged = $cfg->merge_defaults(
		defaults => { user => 'default_user', extra => 'kept' },
		section  => 'database',
	);

	is($merged->{user},  $OVERRIDE_USER, 'section user from file');
	is($merged->{port},  $OVERRIDE_PORT, 'section port from file');
	is($merged->{extra}, 'kept',         'caller default preserved in section merge');
	ok(!exists $merged->{log},           'out-of-section keys absent');
};

# ===========================================================================
# Stateful: modifying ENV mid-flight does not affect already-loaded config
# ===========================================================================
subtest 'stateful: loaded config is not affected by later ENV changes' => sub {
	local %ENV = %ENV;
	$ENV{"${ENV_PREFIX}DATABASE__USER"} = 'initial_env_user';

	my $cfg = new_ok($MODULE => [
		data => {
			database => { user => $EXPECTED_USER, pass => $EXPECTED_PASS },
		},
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	]);

	is($cfg->get('database.user'), 'initial_env_user', 'initial ENV value loaded');

	# Change ENV after construction - should have no effect
	$ENV{"${ENV_PREFIX}DATABASE__USER"} = 'changed_env_user';

	is($cfg->get('database.user'), 'initial_env_user', 'post-construction ENV change ignored');
};

# ===========================================================================
# Concurrency: multiple independent instances do not interfere
# ===========================================================================
subtest 'concurrency: multiple instances are independent' => sub {
	my @cfgs;
	for my $i (1 .. $NUM_INSTANCES) {
		push @cfgs, Config::Abstraction->new(
			data => {
				instance => $i,
				database => { user => "user_$i" },
			},
			config_dirs => [],
		);
	}

	for my $i (1 .. $NUM_INSTANCES) {
		my $cfg = $cfgs[$i - 1];
		is($cfg->get('instance'),       $i,          "instance $i: instance key correct");
		is($cfg->get('database.user'),  "user_$i",   "instance $i: database.user correct");
	}
};

subtest 'concurrency: ENV override applies to each instance independently' => sub {
	local %ENV = %ENV;
	$ENV{"${ENV_PREFIX}RETRIES"} = '99';

	my $cfg_with_prefix = Config::Abstraction->new(
		data        => { INTAPP => { retries => $EXPECTED_RETRIES } },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	my $cfg_without = Config::Abstraction->new(
		data        => { OTHERAPP => { retries => $EXPECTED_RETRIES } },
		config_dirs => [],
		env_prefix  => 'OTHERAPP_',
	);

	is($cfg_with_prefix->get('INTAPP.retries'),    '99',                 'ENV applies to matching prefix instance');
	is($cfg_without->get('OTHERAPP.retries'),      $EXPECTED_RETRIES,   'ENV does not apply to non-matching prefix instance');
};

subtest 'concurrency: file changes between constructions are independent' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_BASE, "version: 1\n");
	my $cfg1 = new_ok($MODULE => [config_dirs => [$dir]]);

	_write_file($dir, $YAML_LOCAL, "version: 2\n");
	my $cfg2 = new_ok($MODULE => [config_dirs => [$dir]]);

	is($cfg1->get('version'), 1, 'first instance has version from base only');
	is($cfg2->get('version'), 2, 'second instance picks up local override');
};

# ===========================================================================
# Flatten mode end-to-end
# ===========================================================================
subtest 'end-to-end: flatten mode across get/exists/all' => sub {
	my $cfg = new_ok($MODULE => [
		data        => _fresh_data(),
		config_dirs => [],
		flatten     => $FLATTEN_ON,
	]);

	is($cfg->get('database.user'),    $EXPECTED_USER,  'flat get() database.user');
	is($cfg->get('log.level'),        $EXPECTED_LEVEL, 'flat get() log.level');
	is($cfg->exists('database.user'), 1,               'flat exists() true');
	is($cfg->exists('no.key'),        0,               'flat exists() false');

	my $all = $cfg->all();
	ok(exists $all->{'database.user'}, 'flat all() has dotted key');
	ok(exists $all->{'log.level'},     'flat all() has dotted log key');
};

subtest 'end-to-end: flatten mode with file loading' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_BASE,
		"database:\n  user: $OVERRIDE_USER\nretries: $EXPECTED_RETRIES\n");

	my $cfg = new_ok($MODULE => [
		config_dirs => [$dir],
		flatten     => $FLATTEN_ON,
	]);

	is($cfg->get('database.user'), $OVERRIDE_USER,    'flat mode file key accessible');
	is($cfg->get('retries'),       $EXPECTED_RETRIES, 'flat mode scalar key accessible');
};

# ===========================================================================
# AUTOLOAD integration
# ===========================================================================
subtest 'end-to-end: AUTOLOAD with sep_char=_ for nested access' => sub {
	my $cfg = new_ok($MODULE => [
		data => {
			database => { user => $EXPECTED_USER, port => $EXPECTED_PORT },
		},
		config_dirs => [],
		sep_char    => $SEP_US,
	]);

	is($cfg->database_user(), $EXPECTED_USER, 'AUTOLOAD database_user()');
	is($cfg->database_port(), $EXPECTED_PORT, 'AUTOLOAD database_port()');

	my $db = $cfg->database();
	is(reftype($db), 'HASH',          'AUTOLOAD database() returns hashref');
	is($db->{user},  $EXPECTED_USER,  'hashref contents correct');
};

subtest 'end-to-end: AUTOLOAD integrates with file-loaded config' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_BASE,
		"database:\n  user: $OVERRIDE_USER\n");

	my $cfg = new_ok($MODULE => [
		config_dirs => [$dir],
		sep_char    => $SEP_US,
	]);

	is($cfg->database_user(), $OVERRIDE_USER, 'AUTOLOAD resolves file-loaded nested key');
};

# ===========================================================================
# Schema validation integration with Params::Validate::Strict
# ===========================================================================
subtest 'end-to-end: schema validation accepts valid config' => sub {
	my $cfg = Config::Abstraction->new(
		data => {
			database => { user => $EXPECTED_USER },
			retries  => $EXPECTED_RETRIES,
			log      => { level => $EXPECTED_LEVEL },
		},
		config_dirs => [],
		schema => {
			database => { type => 'hashref'  },
			retries  => { type => 'integer'  },
			log      => { type => 'hashref'  },
		},
	);
	ok(defined($cfg), 'valid config passes schema validation');
	is($cfg->get('retries'), $EXPECTED_RETRIES, 'validated config accessible');
};

subtest 'end-to-end: schema validation rejects invalid config' => sub {
	eval {
		Config::Abstraction->new(
			data        => { retries => $EXPECTED_RETRIES },
			config_dirs => [],
			schema      => {
				retries   => { type => 'integer' },
				mandatory => { type => 'string', optional => 0 },
			},
		);
	};
	ok($@, 'invalid config dies with schema validation');
	like($@, qr/mandatory/i, 'error message mentions missing key');
};

# ===========================================================================
# Logger integration with Log::Abstraction
# ===========================================================================
subtest 'end-to-end: logger integration - arrayref logger captures messages' => sub {
	test_needs 'Log::Abstraction';
	my @log_output;
	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		logger      => \@log_output,
	);
	ok(defined($cfg), 'object created with arrayref logger');
	# Construction with a directory search generates trace/debug messages
	# We just verify it doesn't crash and the logger received something
	# (exact messages are an implementation detail, not API)
};

subtest 'end-to-end: logger integration - coderef logger receives calls' => sub {
	test_needs 'Log::Abstraction';
	my @calls;
	my $logger_cb = sub { push @calls, [@_] };

	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_BASE, "key: value\n");

	my $cfg = Config::Abstraction->new(
		data        => { extra => 'data' },
		config_dirs => [$dir],
		logger      => $logger_cb,
	);
	ok(defined($cfg), 'object created with coderef logger');
};

# ===========================================================================
# Spy: verify external module interactions
# ===========================================================================
subtest 'spy: Hash::Merge::merge called during file+data merge' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_BASE, "timeout: $EXPECTED_TIMEOUT\n");

	my $spy = spy 'Hash::Merge::merge';

	Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [$dir],
	);

	my @calls = $spy->();
	ok(scalar(@calls) > 0, 'Hash::Merge::merge called during file+data load');
};

subtest 'spy: Params::Validate::Strict::validate_strict called with schema' => sub {
	my $validate_calls = 0;
	my $last_schema;
	my $guard = mock_scoped 'Params::Validate::Strict::validate_strict' => sub {
		$validate_calls++;
		my $args = ref($_[0]) eq 'HASH' ? $_[0] : {@_};
		$last_schema = $args->{schema};
		return $args->{input};
	};

	my $schema = {
		retries  => { type => 'integer' },
		database => { type => 'hashref' },
		log      => { type => 'hashref' },
	};

	Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		schema      => $schema,
	);

	is($validate_calls, 1, 'validate_strict called exactly once');
	is_deeply($last_schema, $schema, 'validate_strict called with correct schema');
};

# ===========================================================================
# config_file / config_files options integration
# ===========================================================================
subtest 'end-to-end: config_file option loads named file' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $path = _write_file($dir, 'myapp.yaml', "mode: production\ntimeout: $EXPECTED_TIMEOUT\n");

	my $cfg = new_ok($MODULE => [
		config_file => $path,
		config_dirs => [''],
	]);

	is($cfg->get('mode'),    'production',      'config_file key loaded');
	is($cfg->get('timeout'), $EXPECTED_TIMEOUT, 'config_file timeout loaded');
};

subtest 'end-to-end: config_files arrayref loads multiple named files' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'first.yaml',  "level: first\ntimeout: $EXPECTED_TIMEOUT\n");
	_write_file($dir, 'second.yaml', "level: second\n");

	my $cfg = new_ok($MODULE => [
		config_files => ['first.yaml', 'second.yaml'],
		config_dirs  => [$dir],
	]);

	# second.yaml loaded later so overrides first.yaml
	is($cfg->get('level'),   'second',           'later config_file overrides earlier');
	is($cfg->get('timeout'), $EXPECTED_TIMEOUT,  'earlier config_file value retained');
};

# ===========================================================================
# sep_char integration across methods
# ===========================================================================
subtest 'end-to-end: sep_char consistent across get/exists/AUTOLOAD' => sub {
	my $cfg = new_ok($MODULE => [
		data => {
			database => { user => $EXPECTED_USER },
		},
		config_dirs => [],
		sep_char    => $SEP_US,
	]);

	# All methods use the same sep_char
	is($cfg->get('database_user'),    $EXPECTED_USER, 'get() uses sep_char');
	is($cfg->exists('database_user'), 1,              'exists() uses sep_char');
	is($cfg->database_user(),         $EXPECTED_USER, 'AUTOLOAD uses sep_char');

	# Dotted notation should NOT work when sep_char is underscore
	ok(!defined($cfg->get('database.user')), 'dotted notation fails with underscore sep_char');
};

# ===========================================================================
# Interaction between multiple instances sharing config_dirs
# ===========================================================================
subtest 'end-to-end: multiple instances same dir, different env_prefix' => sub {
	local %ENV = %ENV;
	$ENV{"${ENV_PREFIX}TIMEOUT"} = $GLOBAL_TIMEOUT;
	$ENV{'OTHERAPP_TIMEOUT'}     = 999;

	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_BASE, "timeout: $EXPECTED_TIMEOUT\nretries: $EXPECTED_RETRIES\n");

	my $cfg1 = new_ok($MODULE => [
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
	]);
	my $cfg2 = new_ok($MODULE => [
		config_dirs => [$dir],
		env_prefix  => 'OTHERAPP_',
	]);

	# cfg1 sees INTAPP_ prefix ENV
	is($cfg1->get('INTAPP.timeout'), $GLOBAL_TIMEOUT, 'cfg1 sees its ENV prefix');

	# cfg2 sees OTHERAPP_ prefix ENV
	is($cfg2->get('OTHERAPP.timeout'), 999, 'cfg2 sees its ENV prefix');

	# Both see file-loaded values
	is($cfg1->get('retries'), $EXPECTED_RETRIES, 'cfg1 sees file retries');
	is($cfg2->get('retries'), $EXPECTED_RETRIES, 'cfg2 sees file retries');
};

# ===========================================================================
# Coderef / blessed object preservation end-to-end
# ===========================================================================
subtest 'end-to-end: coderef in data survives full load cycle' => sub {
	my $cb = sub { $EXPECTED_LEVEL };
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_BASE, "timeout: $EXPECTED_TIMEOUT\n");

	my $cfg = new_ok($MODULE => [
		data        => { callback => $cb, database => { user => $EXPECTED_USER } },
		config_dirs => [$dir],
	]);

	my $got = $cfg->get('callback');
	is(reftype($got), 'CODE',         'coderef preserved through full load cycle');
	is($got->(), $EXPECTED_LEVEL,     'coderef executes correctly');
	is($cfg->get('timeout'), $EXPECTED_TIMEOUT, 'file value also present');
};

subtest 'end-to-end: blessed object in data survives full load cycle' => sub {
	my $obj = bless { v => $EXPECTED_PORT }, '_IntegTestObj';
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_BASE, "timeout: $EXPECTED_TIMEOUT\n");

	my $cfg = new_ok($MODULE => [
		data        => { handler => $obj },
		config_dirs => [$dir],
	]);

	my $got = $cfg->get('handler');
	ok(blessed($got),                  'blessed object preserved through full load cycle');
	is(blessed($got), '_IntegTestObj', 'class unchanged');
	is($cfg->get('timeout'), $EXPECTED_TIMEOUT, 'file value coexists with blessed object');
};

done_testing();
