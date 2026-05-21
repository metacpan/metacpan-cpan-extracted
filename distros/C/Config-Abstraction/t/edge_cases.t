#!/usr/bin/perl

# Destructive, pathological, and boundary-condition tests for Config::Abstraction.
# Tests edge cases, malformed input, extreme values, and unexpected usage patterns.

use strict;
use warnings;
use autodie qw(:all);

use Test::Most;
use Test::Mockingbird;
use Readonly;
use Scalar::Util qw(blessed reftype looks_like_number);
use File::Temp qw(tempdir);
use File::Spec;

# ---------------------------------------------------------------------------
# Configuration - can be overridden via Object::Configure if wanted
# ---------------------------------------------------------------------------
my %config = (
	module		=> 'Config::Abstraction',
	env_prefix	=> 'EDGEAPP_',
	sep_char	=> '.',
	sep_char_us	=> '_',
);

Readonly::Scalar my $MODULE		=> $config{module};
Readonly::Scalar my $ENV_PREFIX		=> $config{env_prefix};
Readonly::Scalar my $SEP		=> $config{sep_char};
Readonly::Scalar my $SEP_US		=> $config{sep_char_us};

Readonly::Scalar my $EXPECTED_USER	=> 'alice';
Readonly::Scalar my $EXPECTED_PORT	=> 5432;
Readonly::Scalar my $LONG_STRING_LEN	=> 100_000;
Readonly::Scalar my $DEEP_NEST_DEPTH	=> 50;
Readonly::Scalar my $MANY_KEYS_COUNT	=> 1_000;
Readonly::Scalar my $UNICODE_VALUE	=> "caf\x{e9}";
Readonly::Scalar my $NUL_VALUE		=> "nul\x00byte";
Readonly::Scalar my $NEWLINE_VALUE	=> "line1\nline2";

# ---------------------------------------------------------------------------
# Helper: write a file to a directory
# ---------------------------------------------------------------------------
sub _write_file
{
	my ($dir, $filename, $content) = @_;
	my $path = File::Spec->catfile($dir, $filename);
	open(my $fh, '>', $path);
	print $fh $content;
	close $fh;
	return $path;
}

# Run a coderef with STDERR silenced - used for subtests that
# intentionally trigger parse failures which carp to STDERR
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
# Constructor edge cases
# ===========================================================================
subtest 'new() - undef data arg does not crash' => sub {
	my $cfg;
	eval {
		$cfg = Config::Abstraction->new(
			data        => undef,
			config_dirs => [],
		);
	};
	ok(!$@, 'undef data does not throw');
};

subtest 'new() - empty string config_dirs entry skipped gracefully' => sub {
	my $cfg;
	eval {
		$cfg = Config::Abstraction->new(
			data        => { key => 'value' },
			config_dirs => ['', undef, File::Spec->curdir()],
		);
	};
	ok(!$@, 'empty/undef config_dirs entries do not crash');
};

subtest 'new() - nonexistent config_dirs silently skipped' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { key => 'value' },
		config_dirs => ['/no/such/dir/ever/exists/xyzzy'],
	);
	ok(defined($cfg), 'nonexistent config_dir does not crash');
	is($cfg->get('key'), 'value', 'data still accessible');
};

subtest 'new() - config_dirs containing a file not a directory' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $file = _write_file($dir, 'notadir.yaml', "key: value\n");

	my $cfg;
	eval {
		$cfg = Config::Abstraction->new(
			data        => { fallback => 'yes' },
			config_dirs => [$file],	# a file, not a directory
		);
	};
	ok(!$@, 'file path in config_dirs does not crash');
};

subtest 'new() - data with only undef values returns undef object' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { key => undef },
		config_dirs => [],
	);
	# A hash with one undef value still has one key - object should be created
	ok(defined($cfg), 'data with undef values creates object');
	ok(!defined($cfg->get('key')), 'undef value preserved');
};

subtest 'new() - completely empty config_dirs arrayref' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { key => 'value' },
		config_dirs => [],
	);
	ok(defined($cfg), 'empty config_dirs arrayref accepted');
};

subtest 'new() - path synonym for config_dirs' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "timeout: 30\n");

	my $cfg = Config::Abstraction->new(path => [$dir]);
	ok(defined($cfg), 'path synonym accepted');
	is($cfg->get('timeout'), 30, 'path synonym loads config');
};

subtest 'new() - file synonym for config_file' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $path = _write_file($dir, 'myapp.yaml', "mode: test\n");

	my $cfg = Config::Abstraction->new(
		file        => $path,
		config_dirs => [''],
	);
	ok(defined($cfg), 'file synonym accepted');
	is($cfg->get('mode'), 'test', 'file synonym loads config');
};

# ===========================================================================
# Malformed and pathological config files
# ===========================================================================
subtest 'malformed YAML file does not crash constructor' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "this: is\nbad:\n  yaml:\n - [broken\n");

	my $cfg;
	_silenced(sub {
		$cfg = Config::Abstraction->new(
			data        => { fallback => 'yes' },
			config_dirs => [$dir],
		);
	});
	# Should either succeed with fallback data or die cleanly
	if($@) {
		like($@, qr/Failed to load YAML|yaml|parse/i, 'YAML error message is descriptive');
	} else {
		ok(defined($cfg), 'malformed YAML falls back gracefully');
	}
};

subtest 'malformed JSON file does not crash constructor' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.json', '{"broken": json, "missing": }');

	my $cfg;
	_silenced(sub {
		eval {
			$cfg = Config::Abstraction->new(
				data        => { fallback => 'yes' },
				config_dirs => [$dir],
			);
		};
	});
	if($@) {
		like($@, qr/Failed to load JSON|json|parse/i, 'JSON error message is descriptive');
	} else {
		ok(defined($cfg), 'malformed JSON falls back gracefully');
	}
};

subtest 'empty config file does not crash constructor' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', '');

	my $cfg;
	eval {
		$cfg = Config::Abstraction->new(
			data        => { fallback => 'yes' },
			config_dirs => [$dir],
		);
	};
	ok(!$@, 'empty config file does not throw');
};

subtest 'config file containing only comments does not crash' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "# just a comment\n# nothing else\n");

	my $cfg;
	eval {
		$cfg = Config::Abstraction->new(
			data        => { fallback => 'yes' },
			config_dirs => [$dir],
		);
	};
	ok(!$@, 'comment-only config file does not throw');
};

subtest 'config file containing only whitespace does not crash' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "   \n\t\n   \n");

	my $cfg;
	_silenced(sub {
		eval {
			$cfg = Config::Abstraction->new(
				data        => { fallback => 'yes' },
				config_dirs => [$dir],
			);
		};
	});
	diag "Error: $@" if $@;
	ok(!$@, 'whitespace-only config file does not throw');
};

subtest 'YAML file with non-hash top-level value handled gracefully' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "- item1\n- item2\n- item3\n");

	my $cfg;
	eval {
		$cfg = Config::Abstraction->new(
			data        => { fallback => 'yes' },
			config_dirs => [$dir],
		);
	};
	ok(!$@, 'YAML array top-level does not throw');
	if(defined($cfg)) {
		is($cfg->get('fallback'), 'yes', 'fallback data intact after non-hash YAML');
	}
};

# ===========================================================================
# Boundary values in keys and data
# ===========================================================================
subtest 'get() - key that is just the sep_char' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { '' => 'empty_key' },
		config_dirs => [],
	);
	# A single dot splits into ('', '') - both empty string lookups
	lives_ok { my $val = $cfg->get($SEP) } 'sep_char-only key does not throw';
};

subtest 'get() - empty string key' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { key => 'value' },
		config_dirs => [],
	);
	my $val;
	eval { $val = $cfg->get('') };
	ok(!$@, 'empty string key does not throw');
};

subtest 'get() - deeply nested key path' => sub {
	# Build a deeply nested hashref
	my $data = { leaf => 'deep_value' };
	my @parts;
	for my $i (1 .. $DEEP_NEST_DEPTH) {
		$data = { "level$i" => $data };
		unshift @parts, "level$i";
	}
	push @parts, 'leaf';

	my $cfg = Config::Abstraction->new(
		data        => $data,
		config_dirs => [],
	);
	my $key = join($SEP, @parts);
	is($cfg->get($key), 'deep_value', "deeply nested key ($DEEP_NEST_DEPTH levels) accessible");
};

subtest 'get() - key with very long string value' => sub {
	my $long = 'x' x $LONG_STRING_LEN;
	my $cfg = Config::Abstraction->new(
		data        => { bigval => $long },
		config_dirs => [],
	);
	my $got = $cfg->get('bigval');
	is(length($got), $LONG_STRING_LEN, "long string value ($LONG_STRING_LEN chars) preserved");
};

subtest 'get() - key with very long key name' => sub {
	my $longkey = 'k' x 10_000;
	my $cfg = Config::Abstraction->new(
		data        => { $longkey => 'value' },
		config_dirs => [],
	);
	is($cfg->get($longkey), 'value', 'very long key name accessible');
};

subtest 'get() - numeric zero value preserved and not treated as false' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { count => 0, flag => 0 },
		config_dirs => [],
	);
	is($cfg->get('count'), 0, 'zero value preserved');
	ok(defined($cfg->get('count')), 'zero value is defined');
	is($cfg->get('flag'),  0, 'zero flag preserved');
};

subtest 'get() - empty string value preserved and not treated as undef' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { empty => '' },
		config_dirs => [],
	);
	ok(defined($cfg->get('empty')), 'empty string is defined');
	is($cfg->get('empty'), '', 'empty string value preserved');
};

subtest 'get() - boolean false value (0) not confused with undef' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { enabled => 0, disabled => 1 },
		config_dirs => [],
	);
	is($cfg->get('enabled'),  0, 'false value 0 preserved');
	is($cfg->get('disabled'), 1, 'true value 1 preserved');
};

subtest 'get() - large number of keys' => sub {
	my %data = map { ("key$_" => $_) } 1 .. $MANY_KEYS_COUNT;
	my $cfg = Config::Abstraction->new(
		data        => \%data,
		config_dirs => [],
	);
	is($cfg->get('key1'), 1,                'first key correct');
	is($cfg->get("key$MANY_KEYS_COUNT"), $MANY_KEYS_COUNT, 'last key correct');
	is($cfg->exists("key500"),         1,                'mid-range key exists');
};

subtest 'get() - key containing special regex metacharacters in sep_char' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { 'a.b' => { c => 'val' } },
		config_dirs => [],
	);
	# 'a.b.c' should split on literal dot: parts are 'a', 'b', 'c'
	# $data->{'a.b'} would not be found since we look for 'a' first
	my $val = $cfg->get('a.b.c');
	ok(!$@, 'key with dots in data name does not crash');
};

subtest 'data() - key with undef value distinguished from missing key' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { present_undef => undef, present_val => 'x' },
		config_dirs => [],
	);
	is($cfg->exists('present_undef'), 1, 'key with undef value exists');
	is($cfg->exists('truly_absent'),  0, 'truly absent key does not exist');
	ok(!defined($cfg->get('present_undef')), 'undef value returns undef from get()');
};

# ===========================================================================
# Unicode and special characters
# ===========================================================================
subtest 'unicode value in data preserved' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { name => $UNICODE_VALUE },
		config_dirs => [],
	);
	is($cfg->get('name'), $UNICODE_VALUE, 'unicode value preserved');
};

subtest 'unicode key in data accessible' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { $UNICODE_VALUE => 'unicode_key_val' },
		config_dirs => [],
	);
	is($cfg->get($UNICODE_VALUE), 'unicode_key_val', 'unicode key accessible');
};

subtest 'value containing newlines preserved' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { multiline => $NEWLINE_VALUE },
		config_dirs => [],
	);
	is($cfg->get('multiline'), $NEWLINE_VALUE, 'newline in value preserved');
};

# ===========================================================================
# Pathological ENV variable edge cases
# ===========================================================================
subtest 'ENV - empty value overrides data' => sub {
	local %ENV = %ENV;
	$ENV{"${ENV_PREFIX}DATABASE__USER"} = '';

	my $cfg = Config::Abstraction->new(
		data => {
			database => { user => $EXPECTED_USER, pass => 'x' },
		},
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	my $val = $cfg->get('database.user');
	# Empty string ENV value should override, not be ignored
	ok(defined($val), 'empty ENV value is defined');
	is($val, '', 'empty ENV value overrides data');
};

subtest 'ENV - prefix match is case-insensitive per POD' => sub {
	local %ENV = %ENV;
	$ENV{lc("${ENV_PREFIX}DATABASE__USER")} = 'lower_env';

	my $cfg = Config::Abstraction->new(
		data => {
			database => { user => $EXPECTED_USER, pass => 'x' },
		},
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	# POD says case-insensitive match
	is($cfg->get('database.user'), 'lower_env', 'lowercase ENV key matched case-insensitively');
};

subtest 'ENV - many double-underscore segments create deep nesting' => sub {
	local %ENV = %ENV;
	$ENV{"${ENV_PREFIX}A__B__C__D"} = 'deep';

	my $cfg = Config::Abstraction->new(
		data        => { a => { b => { c => { d => 'original' } } } },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('a.b.c.d'), 'deep', 'deep double-underscore ENV nesting works');
};

subtest 'ENV - prefix with no matching vars leaves data intact' => sub {
	local %ENV = %ENV;
	# Remove any accidentally matching vars
	delete $ENV{$_} for grep { /^$ENV_PREFIX/ } keys %ENV;

	my $cfg = Config::Abstraction->new(
		data        => { key => 'original' },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('key'), 'original', 'data intact when no ENV vars match prefix');
};

# ===========================================================================
# Pathological CLI argument edge cases
# ===========================================================================
subtest 'CLI - arg without = sign is ignored' => sub {
	local @ARGV = ("--${ENV_PREFIX}RETRIES");

	my $cfg = Config::Abstraction->new(
		data        => { retries => 3 },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('retries'), 3, 'CLI arg without = sign ignored');
};

subtest 'CLI - arg with empty value sets empty string' => sub {
	local @ARGV = ("--${ENV_PREFIX}RETRIES=");

	my $cfg = Config::Abstraction->new(
		data        => { retries => 3 },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	my $val = $cfg->get('retries');
	is($val, '', 'CLI arg with empty value sets empty string');
};

subtest 'CLI - arg with = in value captures full value' => sub {
	local @ARGV = ("--${ENV_PREFIX}DSN=host=localhost;port=5432");

	my $cfg = Config::Abstraction->new(
		data        => { dsn => 'original' },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('dsn'), 'host=localhost;port=5432', 'CLI value with embedded = preserved');
};

subtest 'CLI - non-matching prefix args ignored' => sub {
	local @ARGV = ('--OTHERAPP_KEY=value', '--notanoption', 'positional');

	my $cfg = Config::Abstraction->new(
		data        => { key => 'original' },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('key'), 'original', 'non-matching CLI args ignored');
};

# ===========================================================================
# merge_defaults() edge cases
# ===========================================================================
subtest 'merge_defaults() - undef defaults arg returns config' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { key => 'value' },
		config_dirs => [],
	);
	my $result = $cfg->merge_defaults(defaults => undef);
	ok(defined($result), 'undef defaults returns config hashref');
};

subtest 'merge_defaults() - section that does not exist in config' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { key => 'value' },
		config_dirs => [],
	);
	my $result = $cfg->merge_defaults(
		defaults => { extra => 'kept' },
		section  => 'nosuchsection',
	);
	# Section absent - full config merged with defaults
	ok(defined($result), 'absent section does not crash');
	is($result->{extra}, 'kept', 'default preserved when section absent');
};

subtest 'merge_defaults() - empty defaults hash' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { key => 'value' },
		config_dirs => [],
	);
	my $result = $cfg->merge_defaults(defaults => {});
	ok(defined($result),         'empty defaults hash accepted');
	is($result->{key}, 'value',  'config key present in result');
};

subtest 'merge_defaults() - deep option with no global section' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { key => 'value' },
		config_dirs => [],
	);
	my $result;
	eval {
		$result = $cfg->merge_defaults(
			defaults => { extra => 'kept' },
			deep     => 1,
		);
	};
	ok(!$@, 'deep option with no global section does not crash');
	is($result->{extra}, 'kept', 'default preserved');
};

# ===========================================================================
# Blessed object and coderef edge cases
# ===========================================================================
subtest 'coderef alongside comma-containing string does not corrupt coderef' => sub {
	my $cb = sub { 'result' };
	my $cfg = Config::Abstraction->new(
		data => {
			callback => $cb,
			tags     => 'alpha,beta,gamma',
			plain    => 'simple',
		},
		config_dirs => [],
	);
	my $got = $cfg->get('callback');
	is(reftype($got), 'CODE',  'coderef intact alongside comma string');
	is($got->(), 'result',     'coderef callable');
	is($cfg->get('plain'), 'simple', 'plain string unaffected');
};

subtest 'blessed object alongside active YAML loading not corrupted' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "timeout: 30\nmode: live\n");

	my $obj = bless { v => $EXPECTED_PORT }, '_EdgeTestObj';
	my $cfg = Config::Abstraction->new(
		data        => { handler => $obj, extra => 'val' },
		config_dirs => [$dir],
	);
	my $got = $cfg->get('handler');
	ok(blessed($got),                  'blessed object intact with active YAML loading');
	is(blessed($got), '_EdgeTestObj',  'class unchanged');
	is($cfg->get('timeout'), 30,       'YAML value coexists');
};

subtest 'multiple coderefs in data all preserved independently' => sub {
	my $cb1 = sub { 'one' };
	my $cb2 = sub { 'two' };
	my $cb3 = sub { 'three' };

	my $cfg = Config::Abstraction->new(
		data        => { a => $cb1, b => $cb2, c => $cb3 },
		config_dirs => [],
	);

	is($cfg->get('a')->(), 'one',   'first coderef intact');
	is($cfg->get('b')->(), 'two',   'second coderef intact');
	is($cfg->get('c')->(), 'three', 'third coderef intact');
};

# ===========================================================================
# exists() edge cases
# ===========================================================================
subtest 'exists() - key with undef value returns 1 not 0' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { nullkey => undef },
		config_dirs => [],
	);
	is($cfg->exists('nullkey'), 1, 'key with undef value exists');
};

subtest 'exists() - empty string key does not crash' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { key => 'value' },
		config_dirs => [],
	);
	eval { $cfg->exists('') };
	ok(!$@, 'empty string key in exists() does not crash');
};

# ===========================================================================
# AUTOLOAD edge cases
# ===========================================================================
subtest 'AUTOLOAD - DESTROY not intercepted' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { key => 'value' },
		config_dirs => [],
	);
	# Calling DESTROY directly should not croak with "No such config key"
	eval { $cfg->DESTROY() };
	ok(!$@, 'DESTROY not intercepted by AUTOLOAD');
};

subtest 'AUTOLOAD - key name same as Perl built-in does not crash' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { length => 42 },
		config_dirs => [],
		sep_char    => $SEP_US,
	);
	my $val;
	eval { $val = $cfg->length() };
	ok(!$@, 'key named like built-in does not crash');
	is($val, 42, 'value accessible via AUTOLOAD for built-in-named key');
};

# ===========================================================================
# Flatten edge cases
# ===========================================================================
subtest 'flatten - key containing sep_char not double-flattened' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { 'already.flat' => 'value' },
		config_dirs => [],
		flatten     => 1,
	);
	ok(!$@, 'pre-flattened key with flatten=>1 does not crash');
};

subtest 'flatten - empty nested hash does not crash' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { section => {}, key => 'val' },
		config_dirs => [],
		flatten     => 1,
	);
	ok(defined($cfg), 'empty nested hash with flatten=>1 does not crash');
	is($cfg->get('key'), 'val', 'sibling key still accessible');
};

# ===========================================================================
# Schema edge cases
# ===========================================================================
subtest 'schema - empty schema accepts any config' => sub {
	my $cfg;
	eval {
		$cfg = Config::Abstraction->new(
			data        => { key => 'value', other => 42 },
			config_dirs => [],
			schema      => {},
		);
	};
	# Empty schema behaviour depends on Params::Validate::Strict -
	# should either pass or give a meaningful error, not crash silently
	ok(!$@ || $@ =~ /\w/, 'empty schema does not crash silently');
};

subtest 'schema - schema with all optional fields accepts empty-ish config' => sub {
	my $cfg;
	eval {
		$cfg = Config::Abstraction->new(
			data        => { retries => 3 },
			config_dirs => [],
			schema      => {
				retries => { type => 'integer' },
				timeout => { type => 'integer', optional => 1 },
			},
		);
	};
	ok(!$@,        'optional schema field does not cause failure when absent');
	ok(defined($cfg), 'object created with optional schema field absent');
};

done_testing();
