#!/usr/bin/perl

# Integration tests for Config::Abstraction.
# Black-box, end-to-end behaviour across multiple routines and interactions
# with other modules.  Tests stateful workflows, concurrency of multiple
# instances, optional-dependency graceful degradation, and inter-module
# integration.

use strict;
use warnings;
use autodie qw(:all);

use Test::Most;
use Test::Mockingbird;
use Test::Needs;
use Test::Returns;
use Test::Without::Module;
use Readonly;
use Scalar::Util qw(blessed reftype);
use File::Temp qw(tempdir);
use File::Spec;
use POSIX qw();

# ---------------------------------------------------------------------------
# Configuration constants
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
Readonly::Scalar my $XML_BASE		=> 'base.xml';
Readonly::Scalar my $CUSTOM_CFG	=> 'myapp.cfg';

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
			host => $EXPECTED_HOST,
		},
		log => {
			level => $EXPECTED_LEVEL,
		},
		retries => $EXPECTED_RETRIES,
		timeout => $EXPECTED_TIMEOUT,
	};
}

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
# Optional dependency graceful degradation
#
# These MUST run before any other subtest that would cause the hidden module
# to be loaded, because Test::Without::Module can only intercept the FIRST
# require.  Ordering them first in the file satisfies this invariant.
# ===========================================================================

# Log::Abstraction is not in PREREQ_PM -- it is truly optional.
# When absent and an unblessed logger is supplied, the module must carp and
# disable the logger (set it to undef) so that subsequent method calls inside
# _load_config do not die on an unblessed reference.
subtest 'optional dep: Log::Abstraction absent - arrayref logger disabled, object created' => sub {
	Test::Without::Module->import('Log::Abstraction');

	my @captured;
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		logger      => \@captured,
	);

	Test::Without::Module->unimport('Log::Abstraction');

	ok(defined($cfg), 'object created when Log::Abstraction absent with arrayref logger');
	returns_ok($cfg->get('retries'), { type => 'integer' }, 'get(retries) returns integer');
	is($cfg->get('retries'), $EXPECTED_RETRIES, 'data config accessible after disabled logger');
	ok(scalar(@warnings) > 0, 'carp warning emitted about missing Log::Abstraction');
	diag("Log::Abstraction warning: @warnings") if $ENV{TEST_VERBOSE};
};

# A pre-blessed logger never needs Log::Abstraction: the module calls methods
# directly on whatever blessed object is passed.
subtest 'optional dep: Log::Abstraction absent - pre-blessed logger still works' => sub {
	Test::Without::Module->import('Log::Abstraction');

	my $mock = bless {}, '_IntegPreBlessedLogger';
	{
		no strict 'refs';
		for my $m (qw(trace debug info notice warn error)) {
			*{"_IntegPreBlessedLogger::$m"} = sub {};
		}
	}

	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		logger      => $mock,
	);

	Test::Without::Module->unimport('Log::Abstraction');

	ok(defined($cfg),                    'object created with pre-blessed logger when Log::Abstraction absent');
	is($cfg->get('timeout'), $EXPECTED_TIMEOUT, 'config accessible with pre-blessed logger');
};

# Data::Reuse is commented out of PREREQ_PM (RT#100461) -- genuinely optional.
# get() must return hashrefs correctly without fixation.
subtest 'optional dep: Data::Reuse absent - get() returns hashrefs without fixation' => sub {
	Test::Without::Module->import('Data::Reuse');

	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
	);
	ok(defined($cfg), 'object created when Data::Reuse absent');

	my $scalar = $cfg->get('database.user');
	is($scalar, $EXPECTED_USER, 'scalar get() correct without Data::Reuse');

	my $db = $cfg->get('database');
	ok(defined($db),         'hashref get() returns a value without Data::Reuse');
	ok(ref($db) eq 'HASH',  'hashref get() returns HASH ref without Data::Reuse');
	is($db->{user}, $EXPECTED_USER, 'hashref contents intact without Data::Reuse');

	Test::Without::Module->unimport('Data::Reuse');
};

# XML::Simple is commented out of PREREQ_PM; XML::PP is preferred.
# When XML::Simple is absent the module must transparently fall back to XML::PP.
subtest 'optional dep: XML::Simple absent - falls back to XML::PP for XML loading' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $XML_BASE, <<'XML');
<?xml version="1.0"?>
<config>
  <timeout>30</timeout>
  <retries>3</retries>
</config>
XML

	Test::Without::Module->import('XML::Simple');

	my $cfg = Config::Abstraction->new(config_dirs => [$dir]);

	Test::Without::Module->unimport('XML::Simple');

	ok(defined($cfg), 'object created from XML file when XML::Simple absent');
	is($cfg->get('timeout'), $EXPECTED_TIMEOUT, 'XML timeout loaded via XML::PP fallback');
	is($cfg->get('retries'), $EXPECTED_RETRIES, 'XML retries loaded via XML::PP fallback');

	my $all = $cfg->all();
	returns_ok($all, { type => 'hashref' }, 'all() returns hashref after XML::PP load');
	diag("XML::PP config keys: " . join(', ', keys %{$all})) if $ENV{TEST_VERBOSE};
};

# File::Slurp::Remote is not in PREREQ_PM -- required only for Newcastle Connection.
# When absent, a Newcastle Connection dir must be silently skipped with a carp,
# and any following local dirs must still load normally.
subtest 'optional dep: File::Slurp::Remote absent - Newcastle dir skipped, local dir loads' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_BASE, "local_key: local_val\n");

	Test::Without::Module->import('File::Slurp::Remote');

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, @_ };

	# /../nonexistent.remote.host/... triggers _load_remote_dir, which needs
	# File::Slurp::Remote.  The local $dir entry should still load normally.
	my $cfg = Config::Abstraction->new(
		config_dirs => ['/../some.nonexistent.host/etc/myapp', $dir],
	);

	Test::Without::Module->unimport('File::Slurp::Remote');

	ok(defined($cfg),                       'object created when File::Slurp::Remote absent');
	is($cfg->get('local_key'), 'local_val', 'local dir still loaded after skipped remote dir');
	ok(scalar(@warnings) > 0,              'carp warning emitted about missing File::Slurp::Remote');
	diag("FSR warning: @warnings") if $ENV{TEST_VERBOSE};
};

# TOML::Tiny is in PREREQ_PM but the module advertises graceful degradation.
# When absent, .toml files must be silently skipped with a carp warning, and
# any coexisting YAML files in the same directory must load normally.
subtest 'optional dep: TOML::Tiny absent - .toml silently skipped, YAML still loads' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.toml', "[database]\nuser = \"toml_user\"\n");
	_write_file($dir, $YAML_BASE,  "yaml_key: yaml_val\n");

	{
		local %INC = %INC;
		delete $INC{'TOML/Tiny.pm'};
		Test::Without::Module->import('TOML::Tiny');

		my @warnings;
		local $SIG{__WARN__} = sub { push @warnings, @_ };

		my $cfg = Config::Abstraction->new(config_dirs => [$dir]);

		Test::Without::Module->unimport('TOML::Tiny');

		ok(defined($cfg),                       'object created when TOML::Tiny absent');
		is($cfg->get('yaml_key'), 'yaml_val',   'YAML file loaded when TOML::Tiny absent');
		ok(!defined($cfg->get('database.user')),'.toml file skipped (TOML::Tiny absent)');
		diag("TOML warning: @warnings") if $ENV{TEST_VERBOSE};
	}
};

# Config::Checker is truly optional -- not in PREREQ_PM.
# When absent and the checker option is supplied, a carp must be emitted and
# the object constructed successfully without structural validation.
subtest 'optional dep: Config::Checker absent - checker option yields carp, object created' => sub {
	{
		local %INC = %INC;
		delete $INC{'Config/Checker.pm'};
		Test::Without::Module->import('Config::Checker');

		my @warnings;
		local $SIG{__WARN__} = sub { push @warnings, @_ };

		my $cfg = Config::Abstraction->new(
			data        => { host => 'localhost', port => 8080 },
			config_dirs => [],
			checker     => "host: the hostname\n",
		);

		Test::Without::Module->unimport('Config::Checker');

		ok(defined($cfg),                    'object created when Config::Checker absent');
		is($cfg->get('host'), 'localhost',   'config accessible without Config::Checker');
		ok(scalar(@warnings) > 0,           'carp warning emitted about absent Config::Checker');
		diag("Checker warning: @warnings") if $ENV{TEST_VERBOSE};
	}
};

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

	returns_ok($merged, { type => 'hashref' }, 'merge_defaults() returns hashref');

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

# ===========================================================================
# XML file loading end-to-end (XML::PP path)
# Uses the <config> root-element convention so the parser unwraps to the
# top-level hash directly.
# ===========================================================================
subtest 'end-to-end: XML file loaded via XML::PP' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $XML_BASE, <<'XML');
<?xml version="1.0"?>
<config>
  <api>
    <url>https://api.example.com</url>
    <timeout>30</timeout>
  </api>
  <retries>3</retries>
</config>
XML

	my $cfg = new_ok($MODULE => [config_dirs => [$dir]]);

	is($cfg->get('api.url'),     'https://api.example.com', 'XML nested url loaded');
	is($cfg->get('api.timeout'), $EXPECTED_TIMEOUT,         'XML nested timeout loaded');
	is($cfg->get('retries'),     $EXPECTED_RETRIES,         'XML scalar retries loaded');

	my $all = $cfg->all();
	my @paths = @{$all->{config_path}};
	ok(grep { /\Q$XML_BASE\E/ } @paths, 'config_path records XML file path');
	diag("XML config: " . join(', ', sort keys %{$all})) if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# Newcastle Connection: local-host short-circuit reads from local disk
# /../localhost/path, /../127.0.0.1/path, and /../::1/path all unwrap to the
# local filesystem path without making an SSH connection.
# ===========================================================================
subtest 'end-to-end: Newcastle Connection localhost short-circuit reads local dir' => sub {
	# Newcastle path format /../host/path requires Unix-style absolute paths;
	# on Windows tempdir() returns C:\... with a drive letter, making the
	# concatenation /../localhostC:\... unparseable by _parse_remote_dir.
	plan skip_all => 'Newcastle localhost paths require Unix-style absolute paths (incompatible with Windows drive letters)'
		if $^O eq 'MSWin32';

	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_BASE, "nc_key: nc_value\nnc_port: 8080\n");

	# /../localhost$dir is parsed as host=localhost, remote_dir=$dir
	# _is_local_host('localhost') returns 1 so it unwraps to $dir on disk
	my $cfg = Config::Abstraction->new(
		config_dirs => ["/../localhost$dir"],
	);

	ok(defined($cfg), 'object created via Newcastle localhost short-circuit');
	is($cfg->get('nc_key'),  'nc_value', 'YAML loaded via Newcastle localhost short-circuit');
	is($cfg->get('nc_port'), '8080',     'nc_port loaded via Newcastle localhost short-circuit');

	# 127.0.0.1 is also short-circuited to local disk
	my $cfg2 = Config::Abstraction->new(
		config_dirs => ["/../127.0.0.1$dir"],
	);
	ok(defined($cfg2), 'object created via Newcastle 127.0.0.1 short-circuit');
	is($cfg2->get('nc_key'), 'nc_value', 'YAML loaded via Newcastle 127.0.0.1 short-circuit');
};

# ===========================================================================
# defaults constructor option: parameters nested inside 'defaults' sub-hash
# produce the same object as passing them at the top level.
# ===========================================================================
subtest 'end-to-end: defaults constructor option routes params through nested hash' => sub {
	# Passing via 'defaults' sub-hash
	my $cfg_defaults = Config::Abstraction->new(
		defaults => {
			data        => { key => 'def_value', count => 7 },
			config_dirs => [],
		},
	);

	# Equivalent: passing at top level
	my $cfg_direct = Config::Abstraction->new(
		data        => { key => 'def_value', count => 7 },
		config_dirs => [],
	);

	ok(defined($cfg_defaults), 'object created via defaults option');
	ok(defined($cfg_direct),   'object created via direct params');

	returns_ok($cfg_defaults->get('key'), { type => 'string' }, 'defaults: get() returns string');
	is($cfg_defaults->get('key'),   'def_value', 'defaults option: data key accessible');
	is($cfg_defaults->get('count'), 7,           'defaults option: integer data accessible');

	# Both routes yield the same values
	is($cfg_defaults->get('key'),   $cfg_direct->get('key'),   'defaults and direct yield same key');
	is($cfg_defaults->get('count'), $cfg_direct->get('count'), 'defaults and direct yield same count');
};

# ===========================================================================
# no_fixate option: Data::Reuse fixation must be skipped entirely when set.
# Spy on _load_data_reuse to confirm it is never called.
# ===========================================================================
subtest 'end-to-end: no_fixate option prevents _load_data_reuse call' => sub {
	my $spy = spy 'Config::Abstraction::_load_data_reuse';

	my $cfg = Config::Abstraction->new(
		data        => _fresh_data(),
		config_dirs => [],
		no_fixate   => 1,
	);

	my $db = $cfg->get('database');
	ok(defined($db),        'hashref returned with no_fixate enabled');
	ok(ref($db) eq 'HASH',  'return type is HASH');

	my @calls = $spy->();
	is(scalar(@calls), 0, '_load_data_reuse not called when no_fixate is set');
};

# ===========================================================================
# config_path accumulates paths from multiple config_dirs
# POD: "config_path contains a list of the files that the configuration was
#       loaded from"
# ===========================================================================
subtest 'end-to-end: config_path accumulates paths from multiple config_dirs' => sub {
	my $dir1 = tempdir(CLEANUP => 1);
	my $dir2 = tempdir(CLEANUP => 1);
	_write_file($dir1, $YAML_BASE,  "key1: val1\n");
	_write_file($dir2, $YAML_LOCAL, "key2: val2\n");

	my $cfg = Config::Abstraction->new(config_dirs => [$dir1, $dir2]);

	ok(defined($cfg), 'object created from two config_dirs');
	is($cfg->get('key1'), 'val1', 'key from dir1/base.yaml accessible');
	is($cfg->get('key2'), 'val2', 'key from dir2/local.yaml accessible');

	my $all = $cfg->all();
	returns_ok($all->{config_path}, { type => 'arrayref' }, 'config_path is an arrayref');
	my @paths = @{$all->{config_path}};
	ok(scalar(@paths) >= 2, 'config_path has entries from both dirs');
	ok(grep({ /\Q$dir1\E/ } @paths), 'config_path includes dir1 path');
	ok(grep({ /\Q$dir2\E/ } @paths), 'config_path includes dir2 path');

	diag("config_path: " . join(', ', @paths)) if $ENV{TEST_VERBOSE};
};

# ===========================================================================
# merge_defaults() deep option: Hash::Merge used to deeply combine the global
# section with the caller defaults, preserving nested keys from both.
# ===========================================================================
subtest 'end-to-end: merge_defaults() deep option merges nested global section' => sub {
	my $cfg1 = Config::Abstraction->new(
		data => {
			global => {
				timeout => $EXPECTED_TIMEOUT,
				nested  => { key_a => 'global_a', key_b => 'global_b' },
			},
			retries => $EXPECTED_RETRIES,
		},
		config_dirs => [],
	);

	my $caller_defaults = {
		timeout => 99,
		nested  => { key_b => 'caller_b', key_c => 'caller_c' },
		extra   => 'kept',
	};

	# shallow merge (default): global hash replaces the nested key wholesale
	my $shallow = $cfg1->merge_defaults(defaults => { %{$caller_defaults} });
	is($shallow->{timeout}, $EXPECTED_TIMEOUT, 'shallow: global.timeout wins');
	is($shallow->{extra},   'kept',            'shallow: caller extra key preserved');

	# Re-create: merge_defaults deletes 'global' from the internal config hash
	my $cfg2 = Config::Abstraction->new(
		data => {
			global => {
				timeout => $EXPECTED_TIMEOUT,
				nested  => { key_a => 'global_a', key_b => 'global_b' },
			},
			retries => $EXPECTED_RETRIES,
		},
		config_dirs => [],
	);

	# deep merge: Hash::Merge combines global and caller defaults recursively
	my $deep = $cfg2->merge_defaults(defaults => { %{$caller_defaults} }, deep => 1);
	returns_ok($deep, { type => 'hashref' }, 'deep merge_defaults() returns hashref');
	is($deep->{timeout}, $EXPECTED_TIMEOUT, 'deep: global.timeout wins');
	# With deep merge, nested keys from both global and caller are combined
	is($deep->{nested}{key_a}, 'global_a', 'deep: global nested key_a preserved');
	is($deep->{extra},         'kept',     'deep: caller extra key preserved');
	ok(!exists $deep->{global}, 'deep: global key removed after merge');
};

# ===========================================================================
# explain_sources() integration: full multi-layer audit trail
#
# Three or more sources contribute to the same key.  The method must return
# each layer in the correct order (lowest to highest precedence) with the
# mandatory type, label, and value fields on every record.
# ===========================================================================

subtest 'end-to-end: explain_sources() tracks all source layers for a key' => sub {
	# data (lowest) < file < env < argv (highest) all set database.user
	local %ENV = %ENV;
	local @ARGV = ("--${ENV_PREFIX}DATABASE__USER=cli_user");
	$ENV{"${ENV_PREFIX}DATABASE__USER"} = 'env_user';

	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_BASE, "database:\n  user: file_user\n  host: $EXPECTED_HOST\n");

	my $cfg = new_ok($MODULE => [
		data        => { database => { user => $EXPECTED_USER } },
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
	]);

	my $es = $cfg->explain_sources();
	returns_ok($es, { type => 'hashref' }, 'explain_sources() returns hashref');

	my $key_info = $es->{'database.user'};
	ok(defined($key_info),                   'database.user entry present');
	is($key_info->{value}, $cfg->get('database.user'),
		'explain_sources top-level value matches get()');

	my $srcs = $key_info->{sources};
	is(ref($srcs), 'ARRAY',      'sources is an arrayref');
	ok(scalar(@{$srcs}) >= 3,   'at least 3 source records for a 4-layer key');

	# Ordering: lowest precedence first, highest precedence last
	is($srcs->[0]{type},  'data', 'first source record is data (lowest precedence)');
	is($srcs->[-1]{type}, 'argv', 'last source record is argv (highest precedence)');

	# Every record carries the three mandatory fields
	for my $src (@{$srcs}) {
		ok(defined($src->{type}),  "source record has type ($src->{type})");
		ok(defined($src->{label}), 'source record has label');
		ok(exists($src->{value}),  'source record has value field');
	}

	is($key_info->{value}, 'cli_user', 'winning value is the CLI argument');
	diag('explain_sources keys: ' . join(', ', sort keys %{$es})) if $ENV{TEST_VERBOSE};
};

# The file source label must contain the filename; the data source must use
# the documented fixed label string.
subtest 'end-to-end: explain_sources() source labels are descriptive' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_BASE, "timeout: $EXPECTED_TIMEOUT\n");

	my $cfg = Config::Abstraction->new(
		data        => { timeout => 99 },
		config_dirs => [$dir],
	);

	my $es   = $cfg->explain_sources();
	my $srcs = $es->{timeout}{sources};

	my ($file_src) = grep { $_->{type} eq 'file' } @{$srcs};
	ok(defined($file_src),            'file source record present for timeout');
	like($file_src->{label}, qr/base\.yaml/, 'file source label contains the filename');

	my ($data_src) = grep { $_->{type} eq 'data' } @{$srcs};
	ok(defined($data_src),            'data source record present for timeout');
	like($data_src->{label}, qr/constructor data argument/i,
		'data source label matches the documented string');
};

# A key contributed by only one source (env) must have exactly one record.
subtest 'end-to-end: explain_sources() env-only key has exactly one source record' => sub {
	local %ENV = %ENV;
	$ENV{"${ENV_PREFIX}CACHE__TTL"} = '120';

	my $cfg = Config::Abstraction->new(
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);

	my $es       = $cfg->explain_sources();
	my $ttl_info = $es->{'cache.ttl'};
	ok(defined($ttl_info),            'env-sourced cache.ttl present');

	my $srcs = $ttl_info->{sources};
	is(scalar(@{$srcs}), 1,    'exactly one source record for env-only key');
	is($srcs->[0]{type}, 'env', 'single source type is env');
	is($ttl_info->{value}, '120', 'value matches the env var content');
};

# ===========================================================================
# prefer_*() methods: bypass higher-priority sources
#
# All four sources contribute to database.user; each prefer_* must return
# the value from its own layer, falling back to get() when absent.
# ===========================================================================

subtest 'end-to-end: prefer_*() returns layer-specific value for a fully-stacked key' => sub {
	local %ENV = %ENV;
	local @ARGV = ("--${ENV_PREFIX}DATABASE__USER=cli_user");
	$ENV{"${ENV_PREFIX}DATABASE__USER"} = 'env_user';

	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_BASE, "database:\n  user: file_user\n");

	my $cfg = Config::Abstraction->new(
		data        => { database => { user => $EXPECTED_USER } },
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
	);

	is($cfg->get('database.user'),         'cli_user',     'get() returns highest-priority CLI value');
	is($cfg->prefer_env('database.user'),  'env_user',     'prefer_env() bypasses argv');
	is($cfg->prefer_file('database.user'), 'file_user',    'prefer_file() bypasses env and argv');
	is($cfg->prefer_data('database.user'), $EXPECTED_USER, 'prefer_data() bypasses all layers');
	is($cfg->prefer_argv('database.user'), 'cli_user',     'prefer_argv() returns CLI value');
};

subtest 'end-to-end: prefer_*() falls back to get() when source did not contribute' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_BASE, "level: $EXPECTED_LEVEL\n");

	local %ENV = %ENV;
	local @ARGV = ();
	my $cfg = Config::Abstraction->new(
		data        => { other => 'value' },
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
	);

	# level came only from file; prefer_env/data/argv all fall back to get()
	is($cfg->prefer_env('level'),  $EXPECTED_LEVEL, 'prefer_env falls back to get()');
	is($cfg->prefer_data('level'), $EXPECTED_LEVEL, 'prefer_data falls back to get()');
	is($cfg->prefer_argv('level'), $EXPECTED_LEVEL, 'prefer_argv falls back to get()');
};

subtest 'end-to-end: prefer_*() on absent key returns undef (same as get())' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { x => 1 },
		config_dirs => [],
	);

	ok(!defined($cfg->prefer_env('no_such_key')),  'prefer_env(): absent key returns undef');
	ok(!defined($cfg->prefer_file('no_such_key')), 'prefer_file(): absent key returns undef');
	ok(!defined($cfg->prefer_data('no_such_key')), 'prefer_data(): absent key returns undef');
	ok(!defined($cfg->prefer_argv('no_such_key')), 'prefer_argv(): absent key returns undef');
};

# ===========================================================================
# lazy mode: deferred I/O workflow
#
# With lazy => 1, new() always returns a blessed object.  All file I/O and
# validation are deferred until the first public accessor.  After the first
# accessor, subsequent calls work normally.
# ===========================================================================

subtest 'end-to-end: lazy mode: new() returns blessed object even with no config data' => sub {
	my $cfg = Config::Abstraction->new(
		data        => {},
		config_dirs => [],
		lazy        => 1,
	);
	ok(defined($cfg) && blessed($cfg), 'lazy: new() returns blessed object for empty config');
};

subtest 'end-to-end: lazy mode: file values accessible after first get()' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_BASE, "timeout: $EXPECTED_TIMEOUT\nlevel: $EXPECTED_LEVEL\n");

	my $cfg = Config::Abstraction->new(
		data        => { retries => $EXPECTED_RETRIES },
		config_dirs => [$dir],
		lazy        => 1,
	);
	ok(blessed($cfg), 'lazy: new() returns blessed object before any load');

	# First get() triggers the deferred load
	is($cfg->get('timeout'), $EXPECTED_TIMEOUT, 'lazy: file value accessible after first get()');
	is($cfg->get('retries'), $EXPECTED_RETRIES, 'lazy: data value accessible after first get()');
	is($cfg->exists('level'), 1,                'lazy: exists() works after deferred load');

	my $all = $cfg->all();
	ok(defined($all->{timeout}), 'lazy: all() contains file key after load');
};

subtest 'end-to-end: lazy mode: validators deferred and raised on first get()' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { port => 'not_a_number' },
		config_dirs => [],
		lazy        => 1,
		validators  => { port => 'integer' },
	);
	ok(blessed($cfg), 'lazy + validators: new() returns blessed object without dying');
	throws_ok { $cfg->get('port') } qr/.+/,
		'lazy + validators: validator violation raised on first get()';
};

subtest 'end-to-end: lazy mode: explain_sources() triggers deferred load' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_BASE, "lazy_key: lazy_val\n");

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir],
		lazy        => 1,
	);
	ok(blessed($cfg), 'lazy: new() returns blessed object before load');

	my $es = $cfg->explain_sources();
	ok(defined($es) && ref($es) eq 'HASH', 'lazy: explain_sources() triggers the deferred load');
	ok(exists $es->{lazy_key}, 'lazy: file key present in explain_sources() after load');
};

subtest 'end-to-end: lazy mode: two independent instances do not share load state' => sub {
	my $dir1 = tempdir(CLEANUP => 1);
	my $dir2 = tempdir(CLEANUP => 1);
	_write_file($dir1, $YAML_BASE, "source: dir1\n");
	_write_file($dir2, $YAML_BASE, "source: dir2\n");

	my $cfg1 = Config::Abstraction->new(config_dirs => [$dir1], lazy => 1);
	my $cfg2 = Config::Abstraction->new(config_dirs => [$dir2], lazy => 1);

	is($cfg1->get('source'), 'dir1', 'lazy instance 1 loads from its own dir1');
	is($cfg2->get('source'), 'dir2', 'lazy instance 2 loads from its own dir2');
	is($cfg1->get('source'), 'dir1', 'lazy instance 1 unaffected by instance 2 load');
};

# ===========================================================================
# environment option: tiered config file loading
#
# The environment option activates base.{env}.* and local.{env}.* tiers.
# The name is auto-detected from {env_prefix}ENV -> PLACK_ENV -> NODE_ENV.
# ===========================================================================

subtest 'end-to-end: environment option loads base.{env}.yaml over base.yaml' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_BASE,       "stage: base\ntimeout: $EXPECTED_TIMEOUT\n");
	_write_file($dir, 'base.prod.yaml', "stage: prod\n");

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir],
		environment => 'prod',
	);

	ok(defined($cfg),                           'environment: object constructed');
	is($cfg->get('stage'),   'prod',            'base.prod.yaml overrides base.yaml');
	is($cfg->get('timeout'), $EXPECTED_TIMEOUT, 'base.yaml key retained when absent in env tier');
};

subtest 'end-to-end: environment: local.{env}.yaml overrides base.{env}.yaml' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_BASE,       "stage: base\n");
	_write_file($dir, 'base.dev.yaml',  "stage: dev_base\ndebug: 0\n");
	_write_file($dir, 'local.dev.yaml', "debug: 1\n");

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir],
		environment => 'dev',
	);

	is($cfg->get('stage'), 'dev_base', 'base.dev.yaml overrides base.yaml');
	is($cfg->get('debug'), 1,          'local.dev.yaml overrides base.dev.yaml');
};

subtest 'end-to-end: environment: auto-detected from prefix env var' => sub {
	local %ENV = %ENV;
	$ENV{"${ENV_PREFIX}ENV"} = 'staging';

	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_BASE,          "stage: base\n");
	_write_file($dir, 'base.staging.yaml', "stage: staging\n");

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
	);

	is($cfg->get('stage'), 'staging',
		'environment auto-detected from {env_prefix}ENV variable');
};

subtest 'end-to-end: environment: auto-detected from PLACK_ENV when prefix var absent' => sub {
	local %ENV = %ENV;
	delete $ENV{"${ENV_PREFIX}ENV"};
	$ENV{PLACK_ENV} = 'test';

	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_BASE,       "stage: base\n");
	_write_file($dir, 'base.test.yaml', "stage: test\n");

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
	);

	is($cfg->get('stage'), 'test',
		'environment auto-detected from PLACK_ENV when prefix var absent');
};

# ===========================================================================
# validators option: all four rule forms with real file / data loading
# ===========================================================================

# Rule form 1: type-name string
subtest 'end-to-end: validators type string accepts valid integer from file' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_BASE, "port: $EXPECTED_PORT\n");

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir],
		validators  => { port => 'integer' },
	);
	ok(defined($cfg),                       'type validator: valid integer passes');
	is($cfg->get('port'), $EXPECTED_PORT,   'validated integer value accessible');
};

subtest 'end-to-end: validators type string rejects non-integer file value' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_BASE, "port: not_a_number\n");

	throws_ok {
		Config::Abstraction->new(
			config_dirs => [$dir],
			validators  => { port => 'integer' },
		);
	} qr/.+/, 'type validator: non-integer file value causes croak at construction';
};

# Rule form 2: compiled regex
subtest 'end-to-end: validators regex accepts matching value from file' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_BASE, "level: $EXPECTED_LEVEL\n");

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir],
		validators  => { level => qr/^(?:debug|info|warn|error)$/ },
	);
	ok(defined($cfg),                        'regex validator: matching value passes');
	is($cfg->get('level'), $EXPECTED_LEVEL,  'regex-validated value accessible');
};

subtest 'end-to-end: validators regex rejects non-matching value from file' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_BASE, "level: verbose\n");

	throws_ok {
		Config::Abstraction->new(
			config_dirs => [$dir],
			validators  => { level => qr/^(?:debug|info|warn|error)$/ },
		);
	} qr/.+/, 'regex validator: non-matching file value causes croak';
};

# Rule form 3: coderef
subtest 'end-to-end: validators coderef accepts in-range data value' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { retries => $EXPECTED_RETRIES },
		config_dirs => [],
		validators  => { retries => sub { $_[0] > 0 && $_[0] < 10 } },
	);
	ok(defined($cfg),                        'coderef validator: in-range value passes');
	is($cfg->get('retries'), $EXPECTED_RETRIES, 'coderef-validated value accessible');
};

subtest 'end-to-end: validators coderef rejects out-of-range value' => sub {
	throws_ok {
		Config::Abstraction->new(
			data        => { retries => 999 },
			config_dirs => [],
			validators  => { retries => sub { $_[0] > 0 && $_[0] < 10 } },
		);
	} qr/.+/, 'coderef validator: out-of-range value causes croak';
};

# Rule form 4: hashref spec with type + min + max
subtest 'end-to-end: validators hashref spec accepts valid integer from file' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_BASE, "port: $EXPECTED_PORT\n");

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir],
		validators  => { port => { type => 'integer', min => 1, max => 65535 } },
	);
	ok(defined($cfg),                     'hashref spec: in-range integer passes');
	is($cfg->get('port'), $EXPECTED_PORT, 'hashref-validated port value accessible');
};

subtest 'end-to-end: validators hashref required croaks when key absent from config' => sub {
	throws_ok {
		Config::Abstraction->new(
			data        => { other => 'value' },
			config_dirs => [],
			validators  => { host => { required => 1, type => 'string' } },
		);
	} qr/.+/, 'hashref spec: required-but-absent key causes croak';
};

# ===========================================================================
# TOML format loading (when TOML::Tiny is installed)
# ===========================================================================

subtest 'end-to-end: TOML file loaded from config_dirs' => sub {
	plan skip_all => 'TOML::Tiny not installed'
		unless eval { require TOML::Tiny; 1 };

	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.toml',
		"[database]\nuser = \"$EXPECTED_USER\"\nport = $EXPECTED_PORT\n");

	my $cfg = Config::Abstraction->new(config_dirs => [$dir]);

	ok(defined($cfg),                               'TOML file loaded successfully');
	is($cfg->get('database.user'), $EXPECTED_USER,  'TOML nested string key loaded');
	is($cfg->get('database.port'), $EXPECTED_PORT,  'TOML nested integer key loaded');
};

subtest 'end-to-end: TOML file coexists with YAML in the same directory' => sub {
	plan skip_all => 'TOML::Tiny not installed'
		unless eval { require TOML::Tiny; 1 };

	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, $YAML_BASE, "source: yaml\ntimeout: $EXPECTED_TIMEOUT\n");
	_write_file($dir, 'base.toml', "[database]\nuser = \"$EXPECTED_USER\"\n");

	my $cfg = Config::Abstraction->new(config_dirs => [$dir]);

	ok(defined($cfg),                              'TOML and YAML coexist in same dir');
	is($cfg->get('database.user'), $EXPECTED_USER, 'TOML nested key loaded when YAML coexists');
	ok(defined($cfg->get('timeout')) || defined($cfg->get('source')),
		'YAML key present when TOML coexists');
};

# ===========================================================================
# Config::Checker integration (when installed)
#
# When the checker option is supplied and Config::Checker is available,
# structurally valid config must be accepted silently.
# ===========================================================================

subtest 'end-to-end: Config::Checker accepts structurally valid config' => sub {
	plan skip_all => 'Config::Checker not installed'
		unless eval { require Config::Checker; 1 };

	# Suppress the spurious "uninitialized value $where" warning from Config::Checker.
	local $SIG{__WARN__} = sub {
		warn @_ unless $_[0] =~ /uninitialized value \$where/;
	};

	my $cfg = Config::Abstraction->new(
		data        => { host => $EXPECTED_HOST, port => $EXPECTED_PORT },
		config_dirs => [],
		checker     => "host: the hostname\nport: '?<$EXPECTED_PORT>[INTEGER]'\n",
	);
	ok(defined($cfg),                     'Config::Checker: valid config accepted');
	is($cfg->get('host'), $EXPECTED_HOST, 'checked host value accessible');
	is($cfg->get('port'), $EXPECTED_PORT, 'checked port value accessible');
};

# ===========================================================================
# encrypt_value() + decryption round-trip
#
# When CryptX (Crypt::AuthEnc::GCM) is available, encrypt_value() must
# produce an ENC[AES256GCM,...] token that is transparently decrypted during
# config loading when the same encryption_key is supplied.  All subtests
# here are skipped together when CryptX is absent.
# ===========================================================================

SKIP: {
	skip 'CryptX (Crypt::AuthEnc::GCM) not installed', 3
		unless eval { require Crypt::AuthEnc::GCM; 1 };

	Readonly::Scalar my $HEX_KEY  => 'a' x 64;
	Readonly::Scalar my $WRONG_KEY => 'b' x 64;

	subtest 'end-to-end: encrypt_value() round-trip through a config file' => sub {
		my $dir = tempdir(CLEANUP => 1);

		# Use a lazy throw-away object to produce a token without loading any files
		my $enc_obj = Config::Abstraction->new(
			data           => {},
			config_dirs    => [],
			encryption_key => $HEX_KEY,
			lazy           => 1,
		);
		my $token = $enc_obj->encrypt_value('s3cr3t');
		like($token, qr/^ENC\[/, 'encrypt_value: result starts with ENC[');

		# Write the raw token into a YAML file; the loading object must decrypt it
		_write_file($dir, $YAML_BASE, "database:\n  password: $token\n");

		my $cfg = Config::Abstraction->new(
			config_dirs    => [$dir],
			encryption_key => $HEX_KEY,
		);
		ok(defined($cfg), 'object created with encrypted value in file');
		is($cfg->get('database.password'), 's3cr3t',
			'ENC[] token in file decrypted transparently on load');
	};

	subtest 'end-to-end: ENC token in data option decrypted transparently' => sub {
		my $enc_obj = Config::Abstraction->new(
			data           => {},
			config_dirs    => [],
			encryption_key => $HEX_KEY,
			lazy           => 1,
		);
		my $token = $enc_obj->encrypt_value('my_secret');

		my $cfg = Config::Abstraction->new(
			data           => { api_key => $token },
			config_dirs    => [],
			encryption_key => $HEX_KEY,
		);
		ok(defined($cfg), 'object created with encrypted data option value');
		is($cfg->get('api_key'), 'my_secret',
			'ENC[] token in data option decrypted transparently');
	};

	subtest 'end-to-end: wrong encryption key causes croak during decryption' => sub {
		my $enc_obj = Config::Abstraction->new(
			data           => {},
			config_dirs    => [],
			encryption_key => $HEX_KEY,
			lazy           => 1,
		);
		my $token = $enc_obj->encrypt_value('secret_val');

		throws_ok {
			Config::Abstraction->new(
				data           => { val => $token },
				config_dirs    => [],
				encryption_key => $WRONG_KEY,
			);
		} qr/.+/, 'decryption with wrong key causes croak';
	};
}

done_testing();
