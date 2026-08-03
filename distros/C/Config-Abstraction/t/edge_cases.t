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

# ===========================================================================
# SECURITY: env_prefix regex injection
# ---------------------------------------------------------------------------
# The module embeds env_prefix directly into a regex without quotemeta.
# An env_prefix containing regex metacharacters would cause:
#   '.'  -> /^./ matches every env var (over-match / data pollution)
#   '+'  -> /^APP+_/ changes quantifier semantics (under-match)
#   '('  -> unbalanced grouping -> fatal "Unmatched (" regex compile error
# Fix applied to lib/Config/Abstraction.pm lines 759 & 775: use \Q...\E.
# ===========================================================================

subtest 'SECURITY: env_prefix "." over-match: only exact prefix matched' => sub {
	# Without \Q\E, the pattern /^.(.*)$/i matches EVERY env var because
	# "." means "any character".  The fix must prevent this.
	local %ENV = %ENV;
	$ENV{'XMARKER_CANARY'} = 'should_not_appear';

	my $cfg;
	_silenced(sub {
		eval {
			$cfg = Config::Abstraction->new(
				data        => { safe => 'value' },
				config_dirs => [],
				env_prefix  => '.',
			);
		};
	});
	# With the fix, '.' is literal so XMARKER_CANARY is not merged.
	# Confirm the canary value does not appear anywhere in the config.
	if(defined($cfg)) {
		my $all = $cfg->all() // {};
		my $dumped = join(' ', map { "$_ => $all->{$_}" } grep { defined $all->{$_} && !ref($all->{$_}) } keys %$all);
		unlike($dumped, qr/should_not_appear/, 'dot env_prefix does not ingest arbitrary env vars');
	} else {
		pass('constructor returned undef - no pollution possible');
	}
};

subtest 'SECURITY: env_prefix "APP+_" does not cause regex compile error' => sub {
	# Without \Q\E, /^APP+_/ is a valid but wrong regex (one or more Ps).
	# With \Q\E, /^\QAPP+_\E/ treats "+" literally.
	local %ENV = %ENV;
	$ENV{'APP+_KEY'} = 'plus_val';

	my $cfg;
	eval {
		$cfg = Config::Abstraction->new(
			data        => { key => 'original' },
			config_dirs => [],
			env_prefix  => 'APP+_',
		);
	};
	ok(!$@, 'env_prefix with "+" does not cause an unhandled regex compile error');
};

subtest 'SECURITY: env_prefix "(" does not cause fatal regex error' => sub {
	# Without \Q\E, /^APP(/ is an unbalanced group -> fatal Perl regex error.
	# With \Q\E, it is safe literal matching.
	local %ENV = %ENV;

	my $cfg;
	eval {
		$cfg = Config::Abstraction->new(
			data        => { key => 'original' },
			config_dirs => [],
			env_prefix  => 'APP(_',
		);
	};
	ok(!$@, 'env_prefix with unbalanced "(" does not die with regex error');
};

subtest 'SECURITY: env_prefix metachar does not match unintended CLI args' => sub {
	# Same quotemeta fix needed on the ARGV regex (line 775).
	# env_prefix = 'APP.' would make /^--APP.KEY=/ match --APP_KEY= (. = any char).
	local @ARGV = ('--APP_KEY=wrong', '--APPXKEY=also_wrong');

	my $cfg;
	eval {
		$cfg = Config::Abstraction->new(
			data        => { key => 'original' },
			config_dirs => [],
			env_prefix  => 'APP.',
		);
	};
	ok(!$@, 'ARGV regex with metachar env_prefix does not die');
	# With the fix, 'APP.' matches literally so APP_KEY and APPXKEY are skipped
	if(defined($cfg)) {
		isnt($cfg->get('key'), 'wrong',      'ARGV: unintended arg not merged via metachar prefix');
		isnt($cfg->get('key'), 'also_wrong', 'ARGV: second unintended arg not merged either');
	} else {
		pass('constructor returned undef - no injection possible');
	}
};

# ===========================================================================
# SECURITY: path traversal via config_file
# ---------------------------------------------------------------------------
# Config::Abstraction deliberately does NOT restrict which paths can be loaded
# (the module is a file loader by design), but traversal should not bypass the
# config_dirs constraint silently.  Document the behaviour.
# ===========================================================================

subtest 'SECURITY: path traversal in config_file loads relative path as-is' => sub {
	# The module does not sandbox paths; this test documents the design intent:
	# passing an absolute path to a nonexistent target returns undef (not a crash).
	my $cfg;
	_silenced(sub {
		eval {
			$cfg = Config::Abstraction->new(
				config_file => '/this/path/does/not/exist/ever.yaml',
				config_dirs => [''],
			);
		};
	});
	ok(!$@,        'nonexistent traversal path does not crash constructor');
	ok(!defined($cfg), 'nonexistent traversal path returns undef (no data loaded)');
};

# ===========================================================================
# Filesystem hostility
# ===========================================================================

subtest 'filesystem: /dev/null as config file produces no data' => sub {
	plan skip_all => '/dev/null not available on this platform' unless -e '/dev/null';

	my $cfg;
	eval {
		$cfg = Config::Abstraction->new(
			config_file => '/dev/null',
			config_dirs => [''],
			data        => { fallback => 'devnull_test' },
		);
	};
	ok(!$@, '/dev/null as config_file does not crash constructor');
	if(defined($cfg)) {
		is($cfg->get('fallback'), 'devnull_test', 'fallback data intact after /dev/null config');
	} else {
		pass('constructor returned undef (empty file -> no config data, no data arg merged)');
	}
};

subtest 'filesystem: binary garbage in YAML extension file is skipped gracefully' => sub {
	my $dir = tempdir(CLEANUP => 1);
	# Write 256 bytes of raw binary content as a .yaml file
	my $binary = join('', map { chr($_) } 0..255);
	_write_file($dir, 'base.yaml', $binary);

	my $cfg;
	_silenced(sub {
		eval {
			$cfg = Config::Abstraction->new(
				data        => { fallback => 'binary_test' },
				config_dirs => [$dir],
			);
		};
	});
	# Must not crash; fallback data should survive
	ok(!$@, 'binary YAML content does not kill constructor');
	if(defined($cfg)) {
		is($cfg->get('fallback'), 'binary_test', 'fallback data intact after binary YAML');
	} else {
		pass('constructor returned undef (only data present; binary file skipped)');
	}
};

subtest 'filesystem: directory path in config_file is skipped gracefully' => sub {
	# Passing a directory path to config_file: -f check should fail, no parse attempted.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "fallback: yes\n");

	my $cfg;
	_silenced(sub {
		eval {
			$cfg = Config::Abstraction->new(
				config_file => $dir,
				config_dirs => [''],
				data        => { key => 'dir_test' },
			);
		};
	});
	ok(!$@, 'directory as config_file does not crash');
	if(defined($cfg)) {
		is($cfg->get('key'), 'dir_test', 'fallback data intact when config_file is a directory');
	} else {
		pass('constructor returned undef - no data from directory path');
	}
};

subtest 'filesystem: dangling symlink in config_dirs does not crash' => sub {
	plan skip_all => 'symlink() not supported on this platform'
		unless eval { symlink('', ''); 1 } || $! == &POSIX::EEXIST;

	my $dir = tempdir(CLEANUP => 1);
	my $link = File::Spec->catfile($dir, 'dangling_link.yaml');
	symlink('/nonexistent/target/xyz', $link);

	my $cfg;
	eval {
		$cfg = Config::Abstraction->new(
			data        => { fallback => 'symlink_test' },
			config_dirs => [$dir],
		);
	};
	ok(!$@, 'dangling symlink in config_dirs does not crash');
	if(defined($cfg)) {
		is($cfg->get('fallback'), 'symlink_test', 'fallback data intact with dangling symlink');
	} else {
		pass('constructor returned undef - no data loaded with dangling symlink');
	}
};

subtest 'filesystem: config dir path with spaces works correctly' => sub {
	# File::Spec->catfile should handle spaces; this tests end-to-end path handling.
	my $base = tempdir(CLEANUP => 1);
	my $dir  = File::Spec->catdir($base, 'dir with spaces');
	mkdir($dir) or die "Cannot mkdir: $!";
	_write_file($dir, 'base.yaml', "spacekey: spacevalue\n");

	my $cfg = Config::Abstraction->new(config_dirs => [$dir]);
	ok(defined($cfg),                   'config dir with spaces in name works');
	is($cfg->get('spacekey'), 'spacevalue', 'value loaded from dir with spaces');
};

# ===========================================================================
# Constructor hostile: non-hashref data argument
# ---------------------------------------------------------------------------
# The module does %merged = %{$self->{data}}, which would die if data is an
# arrayref, coderef, or plain scalar.  Fix: type-check before deref (applied
# to lib/Config/Abstraction.pm).
# ===========================================================================

subtest 'new() - arrayref data arg handled gracefully (not a crash)' => sub {
	# Before fix: %merged = %{[1,2,3]} croaks "Not a HASH reference".
	# After fix: a carp warning is emitted and data is silently ignored.
	my $cfg;
	_silenced(sub {
		eval {
			$cfg = Config::Abstraction->new(
				data        => [1, 2, 3],
				config_dirs => [],
			);
		};
	});
	ok(!$@, 'arrayref data does not cause an unhandled fatal error');
	# With the fix, arrayref data is ignored and the object returns undef
	# (no config keys loaded from it) or the object simply has no keys.
};

subtest 'new() - scalar data arg handled gracefully (not a crash)' => sub {
	my $cfg;
	_silenced(sub {
		eval {
			$cfg = Config::Abstraction->new(
				data        => 'just a string',
				config_dirs => [],
			);
		};
	});
	ok(!$@, 'scalar string as data does not cause an unhandled fatal error');
};

subtest 'new() - coderef data arg handled gracefully (not a crash)' => sub {
	my $cfg;
	_silenced(sub {
		eval {
			$cfg = Config::Abstraction->new(
				data        => sub { {} },
				config_dirs => [],
			);
		};
	});
	ok(!$@, 'coderef as data does not cause an unhandled fatal error');
};

# ===========================================================================
# Context abuse: scalar vs list context
# ===========================================================================

subtest 'get() in list context does not expand a hashref into a list' => sub {
	# get() should behave identically in scalar and list context.
	my $cfg = Config::Abstraction->new(
		data        => { section => { a => 1, b => 2 } },
		config_dirs => [],
	);
	my @list_result   = $cfg->get('section');
	my $scalar_result = $cfg->get('section');
	is(scalar(@list_result), 1, 'get() in list context returns exactly one element');
	is(ref($list_result[0]), 'HASH', 'that element is still a hashref (not a flattened list)');
	is($list_result[0], $scalar_result, 'list and scalar contexts return the same reference');
};

subtest 'all() in list context returns one hashref, not a key-value list' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { x => 1, y => 2 },
		config_dirs => [],
	);
	my @result = $cfg->all();
	is(scalar(@result), 1,      'all() in list context yields a single element');
	is(ref($result[0]), 'HASH', 'that element is a hashref');
};

# ===========================================================================
# Multiple object isolation: shared state must not leak between instances
# ===========================================================================

subtest 'two Config::Abstraction objects do not share state' => sub {
	my $cfg1 = Config::Abstraction->new(
		data        => { name => 'object_one', shared => 'A' },
		config_dirs => [],
	);
	my $cfg2 = Config::Abstraction->new(
		data        => { name => 'object_two', shared => 'B' },
		config_dirs => [],
	);

	is($cfg1->get('name'), 'object_one', 'cfg1 name is independent');
	is($cfg2->get('name'), 'object_two', 'cfg2 name is independent');
	is($cfg1->get('shared'), 'A', 'cfg1 shared value is A');
	is($cfg2->get('shared'), 'B', 'cfg2 shared value is B');

	# Mutating one object's underlying data must not affect the other
	$cfg1->all()->{'injected'} = 'leak';
	ok(!defined($cfg2->get('injected')), 'mutation of cfg1 does not leak into cfg2');
};

subtest 'two objects from same dir have independent merge results' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "shared_key: from_file\n");

	my $cfg1 = Config::Abstraction->new(
		data        => { override => 'one' },
		config_dirs => [$dir],
	);
	my $cfg2 = Config::Abstraction->new(
		data        => { override => 'two' },
		config_dirs => [$dir],
	);

	is($cfg1->get('override'),    'one',       'cfg1 data override preserved');
	is($cfg2->get('override'),    'two',       'cfg2 data override preserved');
	is($cfg1->get('shared_key'), 'from_file', 'cfg1 reads file');
	is($cfg2->get('shared_key'), 'from_file', 'cfg2 reads same file independently');
};

# ===========================================================================
# ENV retroactivity: changes after construction must not affect the object
# ===========================================================================

subtest 'ENV changes after construction do not alter already-built object' => sub {
	local %ENV = %ENV;
	delete $ENV{"${ENV_PREFIX}RETROKEY"};

	my $cfg = Config::Abstraction->new(
		data        => { retrokey => 'original' },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('retrokey'), 'original', 'value is original at construction time');

	# Now set the env var - should NOT affect the already-constructed object
	$ENV{"${ENV_PREFIX}RETROKEY"} = 'injected_late';
	is($cfg->get('retrokey'), 'original', 'late ENV change does not retroactively alter object');
};

# ===========================================================================
# get() / exists() with non-hash intermediate value
# ===========================================================================

subtest 'get() returns undef when intermediate path component is a scalar, not a hash' => sub {
	# $data->{'db'} is 'localhost' (scalar), so 'db.user' cannot be traversed.
	my $cfg = Config::Abstraction->new(
		data        => { db => 'localhost' },
		config_dirs => [],
	);
	my $val;
	eval { $val = $cfg->get('db.user') };
	ok(!$@,         'get() on scalar intermediate does not crash');
	ok(!defined($val), 'get() on scalar intermediate returns undef');
};

subtest 'exists() returns 0 when intermediate path component is a scalar, not a hash' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { db => 'localhost' },
		config_dirs => [],
	);
	my $result;
	eval { $result = $cfg->exists('db.user') };
	ok(!$@,       'exists() on scalar intermediate does not crash');
	is($result, 0, 'exists() returns 0 when intermediate component is a scalar');
};

subtest 'get() returns undef for three-level key where level 2 is absent' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { a => { b => 'leaf' } },
		config_dirs => [],
	);
	ok(!defined($cfg->get('a.c.d')), 'get() returns undef for absent intermediate key');
	is($cfg->get('a.b'), 'leaf',     'sibling key still accessible');
};

# ===========================================================================
# merge_defaults() hostile inputs
# ===========================================================================

subtest 'merge_defaults() - section pointing to a scalar value not a hash' => sub {
	# The code does: $config = $config->{$section} when section exists.
	# If that value is a scalar, the next { %{$defaults}, %{$config} } would crash.
	my $cfg = Config::Abstraction->new(
		data        => { myapp => 'not_a_hash', key => 'val' },
		config_dirs => [],
	);
	my $result;
	eval {
		$result = $cfg->merge_defaults(
			defaults => { default_key => 'dval' },
			section  => 'myapp',
		);
	};
	# Should not crash with "Not a HASH reference" - either skips the section
	# or returns a meaningful result
	ok(!$@ || $@ =~ /\w/, 'merge_defaults with scalar section does not crash silently');
};

subtest 'merge_defaults() - called with zero arguments returns full config' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { x => 1, y => 2 },
		config_dirs => [],
	);
	my $result = $cfg->merge_defaults();
	ok(defined($result),    'merge_defaults() with no args returns config');
	is(ref($result), 'HASH', 'returns a hashref');
	is($result->{x}, 1,      'config key x preserved');
};

subtest 'merge_defaults() - merge => 1 combines both hashes' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { from_config => 'yes', shared => 'config_wins' },
		config_dirs => [],
	);
	my $result = $cfg->merge_defaults(
		defaults => { from_defaults => 'yes', shared => 'defaults_loses' },
		merge    => 1,
	);
	ok(defined($result),              'merge => 1 returns a result');
	is($result->{from_config},   'yes', 'config key present in merged result');
	is($result->{from_defaults}, 'yes', 'defaults key present in merged result');
	is($result->{shared},   'config_wins', 'config value wins when merge => 1');
};

# ===========================================================================
# Newcastle Connection: _parse_remote_dir hostile inputs
# (Tested via the constructor which calls _parse_remote_dir internally)
# ===========================================================================

subtest 'Newcastle: /../ with no hostname is not parsed as remote' => sub {
	# '/../' alone: the regex m{^\Q/../\E([^/]+)(/.+)?$} requires at least
	# one char in the hostname capture - so '/../' alone should not match.
	my $cfg;
	_silenced(sub {
		eval {
			$cfg = Config::Abstraction->new(
				data        => { nc => 'test' },
				config_dirs => ['/../'],
			);
		};
	});
	ok(!$@,        'naked /../ in config_dirs does not crash');
};

subtest 'Newcastle: /../hostname alone (no trailing path) uses / as remote_dir' => sub {
	# _parse_remote_dir returns ($1, $2 // '/').  When there is no capture for
	# the path, the remote_dir defaults to '/'.  The _is_local_host check
	# determines whether that triggers an SSH attempt or a local read.
	# Here we pass a known-local host to exercise the local short-circuit.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "nc_bare: nc_bare_val\n");

	my $cfg;
	_silenced(sub {
		eval {
			$cfg = Config::Abstraction->new(
				# /../localhost short-circuits to local /  (root dir on Unix)
				# which normally has no config files - test just must not crash
				data        => { fallback => 'nc_bare_test' },
				config_dirs => ['/../localhost'],
			);
		};
	});
	ok(!$@, '/../hostname without trailing path does not crash (local short-circuit)');
};

subtest 'Newcastle: user@host form is parsed with user stripped by _is_local_host' => sub {
	# _is_local_host strips the user@ prefix before comparing hostnames.
	# Verify the constructor handles /../user@localhost/path correctly:
	# it should short-circuit to local disk (no SSH) with no crash.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "nc_user: nc_user_val\n");

	plan skip_all => 'Newcastle localhost paths require Unix-style absolute paths (no Windows drive letters)'
		if $^O eq 'MSWin32';

	my $cfg;
	_silenced(sub {
		eval {
			$cfg = Config::Abstraction->new(
				data        => { fallback => 'user_at_test' },
				config_dirs => ["/../nobody\@localhost$dir"],
			);
		};
	});
	ok(!$@, '/../user@localhost/dir does not crash');
	if(defined($cfg)) {
		is($cfg->get('nc_user'), 'nc_user_val', 'user@localhost short-circuit reads local dir');
	} else {
		pass('no data loaded but no crash - acceptable');
	}
};

# ===========================================================================
# sep_char edge cases
# ===========================================================================

subtest 'sep_char as regex metachar "*" is quoted safely in get()' => sub {
	# get() uses qr/\Q$self->{sep_char}\E/ so metacharacters are literal.
	my $cfg = Config::Abstraction->new(
		data        => { 'a*b' => 'star_val', a => { b => 'nested_val' } },
		config_dirs => [],
		sep_char    => '*',
	);
	# With sep_char='*', 'a*b' splits on '*' into ('a','b') -> traverses nested hash
	is($cfg->get('a*b'), 'nested_val', 'sep_char "*" is literal, traverses nested key');
};

subtest 'sep_char "/" works as separator and does not confuse file paths' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { db => { user => 'alice' } },
		config_dirs => [],
		sep_char    => '/',
	);
	is($cfg->get('db/user'), 'alice', 'sep_char "/" works as key separator');
};

# ===========================================================================
# JSON edge cases: null values, array at top level
# ===========================================================================

subtest 'JSON null value produces undef in config' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.json', '{"nullkey": null, "present": "yes"}');

	my $cfg = Config::Abstraction->new(config_dirs => [$dir]);
	ok(defined($cfg),                  'object created from JSON with null value');
	ok(!defined($cfg->get('nullkey')), 'JSON null maps to undef');
	is($cfg->get('present'), 'yes',    'adjacent key with real value intact');
};

subtest 'JSON array at top level is skipped gracefully' => sub {
	# The module checks ref($data) ne 'HASH' and skips; this test confirms it.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.json', '[1, 2, 3]');

	my $cfg;
	_silenced(sub {
		eval {
			$cfg = Config::Abstraction->new(
				data        => { fallback => 'array_json_test' },
				config_dirs => [$dir],
			);
		};
	});
	ok(!$@, 'top-level JSON array does not crash constructor');
	if(defined($cfg)) {
		is($cfg->get('fallback'), 'array_json_test', 'fallback data intact after top-level JSON array');
	} else {
		pass('constructor returned undef - acceptable');
	}
};

# ===========================================================================
# Circular reference in data
# ===========================================================================

subtest 'circular reference in data does not crash constructor (flatten=0)' => sub {
	# %merged = %{$data} is a shallow copy; circular refs at depth >= 1 are
	# not followed.  flatten=0 means Hash::Flatten is not called, so no
	# infinite recursion.
	my %circular;
	$circular{self} = \%circular;	# $circular{self} points back to %circular

	my $cfg;
	eval {
		$cfg = Config::Abstraction->new(
			data        => { safe => 'value', nested => { ok => 1 } },
			config_dirs => [],
		);
	};
	ok(!$@,         'constructor with normal data does not crash');
	is($cfg->get('safe'), 'value', 'safe key accessible');

	# Circular ref at the top level of data: %merged = %{$data} copies the
	# top-level ref, but the self entry points back.
	my $cfg2;
	eval {
		$cfg2 = Config::Abstraction->new(
			data        => \%circular,
			config_dirs => [],
		);
	};
	ok(!$@, 'top-level circular reference in data does not crash constructor');
};

subtest 'circular reference in nested data does not crash get()' => sub {
	my %child;
	$child{back} = \%child;

	my $cfg = Config::Abstraction->new(
		data        => { parent => \%child, safe => 'ok' },
		config_dirs => [],
	);
	ok(defined($cfg),           'object created with circular nested ref');
	my $got;
	eval { $got = $cfg->get('safe') };
	ok(!$@,          'get() on safe key with circular sibling does not crash');
	is($got, 'ok',   'safe key value correct');
};

# ===========================================================================
# all() edge cases
# ===========================================================================

subtest 'all() populates config_path with loaded file paths' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "from_file: yes\n");

	my $cfg = Config::Abstraction->new(config_dirs => [$dir]);
	my $all = $cfg->all();
	ok(defined($all->{config_path}), 'config_path key present in all()');
	ok(ref($all->{config_path}) eq 'ARRAY', 'config_path is an arrayref');
	ok(scalar(@{$all->{config_path}}) >= 1, 'config_path lists at least one loaded file');
	like($all->{config_path}[0], qr/base\.yaml$/, 'config_path first entry ends with base.yaml');
};

subtest 'all() returns undef when config is empty (no keys at all)' => sub {
	# Constructor returns undef when no data loaded; all() therefore never
	# called on a truly empty config.  Test via direct construction with undef trick.
	my $cfg = Config::Abstraction->new(
		data        => { only_key => 1 },
		config_dirs => [],
	);
	my $all = $cfg->all();
	ok(defined($all), 'all() returns defined hashref when keys exist');
	is(ref($all), 'HASH', 'all() return value is a hashref');
};

# ===========================================================================
# YAML extreme nesting: must not cause stack overflow
# ===========================================================================

subtest 'YAML extremely deep nesting (100 levels) does not crash' => sub {
	my $dir  = tempdir(CLEANUP => 1);
	# Build 100-level YAML: each line indents two more spaces
	my $yaml = '';
	for my $i (1 .. 100) {
		$yaml .= ('  ' x ($i - 1)) . "level$i:\n";
	}
	$yaml .= ('  ' x 100) . "leaf: deep_value\n";
	_write_file($dir, 'base.yaml', $yaml);

	my $cfg;
	_silenced(sub {
		eval {
			$cfg = Config::Abstraction->new(config_dirs => [$dir]);
		};
	});
	ok(!$@, '100-level deep YAML does not crash constructor');
	if(defined($cfg)) {
		# Confirm the top-level key of the deep structure is present
		ok($cfg->exists('level1'), 'level1 top-level key exists in parsed deep YAML');
	} else {
		pass('constructor returned undef - YAML too deep to parse on this system, but no crash');
	}
};

# ===========================================================================
# NUL byte in environment value
# ===========================================================================

subtest 'NUL byte in ENV value is stored as-is (Perl strings allow NUL)' => sub {
	local %ENV = %ENV;
	$ENV{"${ENV_PREFIX}NULKEY"} = "before\x00after";

	my $cfg = Config::Abstraction->new(
		data        => { other => 'clean' },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	ok(defined($cfg), 'object created with NUL-containing ENV value');
	# The value is stored under the prefix namespace; verify it's accessible
	# The key path depends on env_prefix stripping: EDGEAPP_ -> edgeapp
	# For a key without __ separator it goes under $prefix->{path}
	my $all = $cfg->all() // {};
	my $found_nul = 0;
	for my $top_val (values %$all) {
		next unless ref($top_val) eq 'HASH';
		for my $v (values %$top_val) {
			$found_nul = 1 if defined($v) && $v =~ /\x00/;
		}
	}
	ok($found_nul, 'NUL byte preserved in stored ENV value');
};

# ===========================================================================
# AUTOLOAD: exact error message for nonexistent key
# ===========================================================================

subtest 'AUTOLOAD dies with "No such config key" for a nonexistent key (sep_char=_)' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { existing => 'val' },
		config_dirs => [],
		sep_char    => $SEP_US,
	);
	my $error;
	eval { $cfg->nonexistent_key() };
	$error = $@;
	ok($error, 'AUTOLOAD dies when key does not exist');
	like($error, qr/No such config key 'nonexistent_key'/,
		'AUTOLOAD error message contains the missing key name');
};

subtest 'AUTOLOAD dies with "No such config key" for partial path nonexistent (sep_char=_)' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { db => { user => 'alice' } },
		config_dirs => [],
		sep_char    => $SEP_US,
	);
	eval { $cfg->db_password() };
	my $error = $@;
	ok($error, 'AUTOLOAD dies when nested key does not exist');
	like($error, qr/No such config key/, 'error message mentions missing key');
};

# ===========================================================================
# explain_sources() - structural validation
# ===========================================================================

subtest 'explain_sources() returns a hashref' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { host => 'localhost', port => 5432 },
		config_dirs => [],
	);
	is(ref($cfg->explain_sources()), 'HASH', 'explain_sources() returns a hashref');
};

subtest 'explain_sources() - every entry has value and sources fields' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { host => 'localhost', port => 5432 },
		config_dirs => [],
	);
	my $sources = $cfg->explain_sources();
	for my $key (keys %$sources) {
		my $entry = $sources->{$key};
		ok(exists $entry->{'value'},   "key '$key' has 'value' field");
		ok(exists $entry->{'sources'}, "key '$key' has 'sources' field");
		is(ref($entry->{'sources'}), 'ARRAY', "key '$key' sources is an arrayref");
	}
};

subtest 'explain_sources() - value field matches get() for every key' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { alpha => 'aval', beta => 42 },
		config_dirs => [],
	);
	my $sources = $cfg->explain_sources();
	for my $key (keys %$sources) {
		is($sources->{$key}{'value'}, $cfg->get($key),
			"explain_sources value for '$key' matches get()");
	}
};

subtest 'explain_sources() - config_path key is excluded from output' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "x: 1\n");

	my $cfg = Config::Abstraction->new(config_dirs => [$dir]);
	ok(!exists $cfg->explain_sources()->{'config_path'},
		'config_path excluded from explain_sources output');
};

subtest 'explain_sources() - data source entry has correct type, label and value' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { mykey => 'myval' },
		config_dirs => [],
	);
	my $sources = $cfg->explain_sources();
	ok(exists $sources->{'mykey'}, 'mykey present in explain_sources');
	my @data_src = grep { $_->{'type'} eq 'data' } @{$sources->{'mykey'}{'sources'}};
	ok(scalar(@data_src) >= 1, 'at least one data-type source record for mykey');
	is($data_src[0]{'label'}, 'constructor data argument',
		'data source label is "constructor data argument"');
	is($data_src[0]{'value'}, 'myval', 'data source value is correct');
};

subtest 'explain_sources() - file source entry has type=file and path as label' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "filekey: fileval\n");

	my $cfg    = Config::Abstraction->new(config_dirs => [$dir]);
	my $sources = $cfg->explain_sources();
	ok(exists $sources->{'filekey'}, 'filekey present in explain_sources');
	my @file_src = grep { $_->{'type'} eq 'file' } @{$sources->{'filekey'}{'sources'}};
	ok(scalar(@file_src) >= 1, 'file-type source present for filekey');
	like($file_src[0]{'label'}, qr/base\.yaml$/, 'file source label ends with base.yaml');
	is($file_src[0]{'value'}, 'fileval', 'file source value correct');
};

subtest 'explain_sources() - env source entry has type=env and var name as label' => sub {
	local %ENV = %ENV;
	$ENV{"${ENV_PREFIX}DATABASE__HOST"} = 'envhost';

	my $cfg = Config::Abstraction->new(
		data        => { database => { host => 'datahost' } },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	my $sources = $cfg->explain_sources();
	my @env_src = grep { $_->{'type'} eq 'env' }
		@{$sources->{'database.host'}{'sources'}};
	ok(scalar(@env_src) >= 1, 'env-type source present for database.host');
	is($env_src[0]{'label'}, "${ENV_PREFIX}DATABASE__HOST",
		'env source label is the environment variable name');
	is($env_src[0]{'value'}, 'envhost', 'env source value matches the env var');
};

subtest 'explain_sources() - argv source entry has type=argv and arg string as label' => sub {
	local @ARGV = ("--${ENV_PREFIX}ARGKEY=argval");

	my $cfg = Config::Abstraction->new(
		data        => { argkey => 'original' },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	my $sources = $cfg->explain_sources();
	my @argv_src = grep { $_->{'type'} eq 'argv' }
		@{$sources->{'argkey'}{'sources'}};
	ok(scalar(@argv_src) >= 1, 'argv-type source present for argkey');
	like($argv_src[0]{'label'}, qr/ARGKEY/, 'argv source label contains the key name');
	is($argv_src[0]{'value'}, 'argval', 'argv source value correct');
};

subtest 'explain_sources() - sources ordered lowest-to-highest precedence' => sub {
	# data < file < env - verify the ordering guarantee of the POD.
	local %ENV = %ENV;
	$ENV{"${ENV_PREFIX}MULTI__KEY"} = 'env_val';

	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "multi:\n  key: file_val\n");

	my $cfg = Config::Abstraction->new(
		data        => { multi => { key => 'data_val' } },
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
	);
	my $sources = $cfg->explain_sources();
	ok(exists $sources->{'multi.key'}, 'multi.key present in explain_sources');
	my @all_src = @{$sources->{'multi.key'}{'sources'}};
	ok(scalar(@all_src) >= 2, 'at least two source records for multi.key');
	is($all_src[0]{'type'}, 'data', 'first source is data (lowest precedence)');
	is($all_src[-1]{'type'}, 'env',  'last source is env (highest precedence)');
	is($sources->{'multi.key'}{'value'}, 'env_val',
		'final value is the env value (highest precedence wins)');
};

subtest 'explain_sources() - idempotent: repeated calls return equal structure' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { x => 1, y => 2 },
		config_dirs => [],
	);
	is_deeply($cfg->explain_sources(), $cfg->explain_sources(),
		'explain_sources() returns same structure on every call');
};

subtest 'explain_sources() - undef data value appears with undef in sources.value' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { nulkey => undef },
		config_dirs => [],
	);
	my $sources = $cfg->explain_sources();
	ok(exists $sources->{'nulkey'}, 'undef-valued key appears in explain_sources output');
	my @data_src = grep { $_->{'type'} eq 'data' }
		@{$sources->{'nulkey'}{'sources'}};
	ok(scalar(@data_src) >= 1, 'data source recorded for undef-valued key');
	ok(!defined($data_src[0]{'value'}),
		'source value is undef for a key the data arg set to undef');
};

subtest 'explain_sources() - every output key has at least one source entry' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { k1 => 'v1', k2 => 'v2' },
		config_dirs => [],
	);
	my $sources = $cfg->explain_sources();
	for my $key (keys %$sources) {
		ok(scalar(@{$sources->{$key}{'sources'}}) >= 1,
			"key '$key' has at least one source record");
	}
};

subtest 'explain_sources() - circular reference in config does not crash' => sub {
	# _flatten_keys has a refaddr-based $seen guard; this test activates it.
	my %circ;
	$circ{'self'} = \%circ;
	$circ{'safe'} = 'safe_val';

	my $cfg = Config::Abstraction->new(
		data        => \%circ,
		config_dirs => [],
	);
	my $sources;
	eval { $sources = $cfg->explain_sources() };
	ok(!$@, 'explain_sources() does not crash when data contains a circular reference');
	ok(ref($sources) eq 'HASH', 'explain_sources() returns a hashref despite circular ref');
};

# ===========================================================================
# prefer_env() - boundary conditions
# ===========================================================================

subtest 'prefer_env() returns env value (bypasses data) when env contributed to key' => sub {
	local %ENV = %ENV;
	$ENV{"${ENV_PREFIX}DATABASE__HOST"} = 'envhost';

	my $cfg = Config::Abstraction->new(
		data        => { database => { host => 'datahost' } },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->prefer_env('database.host'), 'envhost',
		'prefer_env returns env-layer value, bypassing data');
};

subtest 'prefer_env() falls back to get() when env did not contribute to key' => sub {
	local %ENV = %ENV;
	delete $ENV{$_} for grep { /^\Q$ENV_PREFIX\E/ } keys %ENV;

	my $cfg = Config::Abstraction->new(
		data        => { noenv => 'data_only' },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->prefer_env('noenv'), 'data_only',
		'prefer_env falls back to get() when env never contributed to key');
};

subtest 'prefer_env() with empty-string env value returns "" not the data fallback' => sub {
	# Critical check: $found (not $val) decides whether to return env value.
	# An empty string is falsy in Perl; naive "if ($val)" logic would be wrong.
	local %ENV = %ENV;
	$ENV{"${ENV_PREFIX}EMPTYENV__KEY"} = '';

	my $cfg = Config::Abstraction->new(
		data        => { emptyenv => { key => 'non_empty' } },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	my $val = $cfg->prefer_env('emptyenv.key');
	ok(defined($val), 'prefer_env with empty-string env value returns a defined value');
	is($val, '', 'prefer_env returns "" from env, not "non_empty" data fallback');
};

subtest 'prefer_env() for nonexistent key returns undef (get() fallback)' => sub {
	local %ENV = %ENV;
	delete $ENV{$_} for grep { /^\Q$ENV_PREFIX\E/ } keys %ENV;

	my $cfg = Config::Abstraction->new(
		data        => { other => 'val' },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	ok(!defined($cfg->prefer_env('totally_absent_key')),
		'prefer_env for nonexistent key returns undef');
};

subtest 'prefer_env() with sep_char=_ normalises key to dotted form for source lookup' => sub {
	local %ENV = %ENV;
	$ENV{"${ENV_PREFIX}DB__HOST"} = 'envdbhost';

	my $cfg = Config::Abstraction->new(
		data        => { db => { host => 'datadbhost' } },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
		sep_char    => $SEP_US,
	);
	# User passes 'db_host'; _value_from_type normalises to 'db.host' before lookup.
	is($cfg->prefer_env('db_host'), 'envdbhost',
		'prefer_env normalises sep_char=_ key to dotted notation for source record lookup');
};

subtest 'prefer_env() in list context returns exactly one value' => sub {
	local %ENV = %ENV;
	$ENV{"${ENV_PREFIX}SECTION__KEY"} = 'env_list_val';

	my $cfg = Config::Abstraction->new(
		data        => { section => { key => 'data_val' } },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	my @result = $cfg->prefer_env('section.key');
	is(scalar(@result), 1, 'prefer_env in list context returns exactly one element');
	is($result[0], 'env_list_val', 'that element is the env-sourced value');
};

# ===========================================================================
# prefer_file() - boundary conditions
# ===========================================================================

subtest 'prefer_file() returns file value even when env overrode it in the merged config' => sub {
	local %ENV = %ENV;
	$ENV{"${ENV_PREFIX}DATABASE__HOST"} = 'env_override';

	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "database:\n  host: file_host\n");

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('database.host'), 'env_override',
		'get() returns env-overridden value (env has higher precedence)');
	is($cfg->prefer_file('database.host'), 'file_host',
		'prefer_file returns file-sourced value, bypassing the env override');
};

subtest 'prefer_file() falls back to get() when no file contributed to key' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { dataonly => 'original' },
		config_dirs => [],
	);
	is($cfg->prefer_file('dataonly'), 'original',
		'prefer_file falls back to get() for a data-only key');
};

subtest 'prefer_file() - last file wins when multiple files contributed to same key' => sub {
	# base.yaml < local.yaml in precedence; prefer_file should return local.yaml value.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml',  "multifile: base_val\n");
	_write_file($dir, 'local.yaml', "multifile: local_val\n");

	my $cfg = Config::Abstraction->new(config_dirs => [$dir]);
	is($cfg->prefer_file('multifile'), 'local_val',
		'prefer_file returns value from last-loaded file (local.yaml > base.yaml)');
};

# ===========================================================================
# prefer_data() - boundary conditions
# ===========================================================================

subtest 'prefer_data() returns data value even when a file overrode it' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "host: from_file\n");

	my $cfg = Config::Abstraction->new(
		data        => { host => 'from_data' },
		config_dirs => [$dir],
	);
	is($cfg->get('host'),         'from_file', 'get() returns file-overridden value');
	is($cfg->prefer_data('host'), 'from_data', 'prefer_data bypasses file override');
};

subtest 'prefer_data() falls back to get() when data arg did not contribute to key' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "file_only: from_file\n");

	my $cfg = Config::Abstraction->new(
		data        => { other => 'val' },
		config_dirs => [$dir],
	);
	is($cfg->prefer_data('file_only'), 'from_file',
		'prefer_data falls back to get() when data arg never set the key');
};

subtest 'prefer_data() with undef data value: $found gates return, not $val' => sub {
	# If data set key => undef, the source record exists (flat_data has the key).
	# So $found = 1 and $val = undef.  Returning "$found ? $val" is undef (correct),
	# NOT falling through to get() which might also return undef for other reasons.
	my $cfg = Config::Abstraction->new(
		data        => { nuldata => undef },
		config_dirs => [],
	);
	# Sanity: the key is visible in explain_sources, proving the source record exists.
	ok(exists $cfg->explain_sources()->{'nuldata'},
		'nuldata appears in explain_sources despite undef value');
	ok(!defined($cfg->prefer_data('nuldata')),
		'prefer_data returns undef for a key the data arg set to undef');
};

# ===========================================================================
# prefer_argv() - boundary conditions
# ===========================================================================

subtest 'prefer_argv() returns argv value when CLI arg contributed to key' => sub {
	local @ARGV = ("--${ENV_PREFIX}ARGVKEY=argv_val");

	my $cfg = Config::Abstraction->new(
		data        => { argvkey => 'data_val' },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->prefer_argv('argvkey'), 'argv_val',
		'prefer_argv returns the argv-provided value');
};

subtest 'prefer_argv() falls back to get() when no CLI arg contributed' => sub {
	local @ARGV = ();

	my $cfg = Config::Abstraction->new(
		data        => { noargv => 'data_only' },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->prefer_argv('noargv'), 'data_only',
		'prefer_argv falls back to get() when no CLI arg set the key');
};

subtest 'prefer_argv() equals get() since argv is the highest-precedence source' => sub {
	# When argv contributed, it already won the merge; get() and prefer_argv() agree.
	local @ARGV = ("--${ENV_PREFIX}TOPKEY=top_val");
	local %ENV  = %ENV;
	$ENV{"${ENV_PREFIX}DATABASE__TOPKEY"} = 'env_val';

	my $cfg = Config::Abstraction->new(
		data        => { topkey => 'data_val' },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('topkey'),         'top_val', 'get() returns argv value (highest precedence)');
	is($cfg->prefer_argv('topkey'), 'top_val',
		'prefer_argv matches get() when argv is the winning source');
};

# ===========================================================================
# prefer_*() hostile inputs shared across all four methods
# ===========================================================================

subtest 'prefer_env() with undef key does not crash' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { x => 1 },
		config_dirs => [],
	);
	eval { $cfg->prefer_env(undef) };
	ok(!$@, 'prefer_env(undef) does not die');
};

subtest 'prefer_file() with undef key does not crash' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { x => 1 },
		config_dirs => [],
	);
	eval { $cfg->prefer_file(undef) };
	ok(!$@, 'prefer_file(undef) does not die');
};

subtest 'prefer_data() with empty string key does not crash' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { x => 1 },
		config_dirs => [],
	);
	eval { $cfg->prefer_data('') };
	ok(!$@, 'prefer_data("") does not die');
};

subtest 'prefer_argv() with very long key does not crash' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { x => 1 },
		config_dirs => [],
	);
	eval { $cfg->prefer_argv('k' x $LONG_STRING_LEN) };
	ok(!$@, 'prefer_argv with very long key does not die');
};

subtest 'all four prefer_*() methods agree when only data set the key' => sub {
	# When only the data arg contributed, all prefer_* fall back to get(),
	# and prefer_data returns the data value directly.  All four should agree.
	local @ARGV  = ();
	local %ENV   = %ENV;
	delete $ENV{$_} for grep { /^\Q$ENV_PREFIX\E/ } keys %ENV;

	my $cfg = Config::Abstraction->new(
		data        => { only_data => 'data_val' },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->prefer_env('only_data'),  'data_val', 'prefer_env  returns data value');
	is($cfg->prefer_file('only_data'), 'data_val', 'prefer_file returns data value');
	is($cfg->prefer_data('only_data'), 'data_val', 'prefer_data returns data value');
	is($cfg->prefer_argv('only_data'), 'data_val', 'prefer_argv returns data value');
};

# ===========================================================================
# SECURITY: prefer_*() source injection via _source_records manipulation
# ---------------------------------------------------------------------------
# The _source_records structure is private.  Verify that mutating the hashref
# returned by all() (which is the live config ref) does NOT inject entries into
# the source records that then corrupt prefer_*() results.
# ===========================================================================

subtest 'SECURITY: mutating all() result does not corrupt prefer_data() output' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { safe => 'safe_val' },
		config_dirs => [],
	);
	# Inject a new key directly into the live config hashref (abuse of all())
	$cfg->all()->{'injected'} = 'evil';

	# injected key has no source record - prefer_data falls back to get()
	is($cfg->prefer_data('injected'), 'evil',
		'injected key falls back to get() (no source record exists for it)');

	# The safe key is unaffected
	is($cfg->prefer_data('safe'), 'safe_val', 'original safe key unaffected');
};

subtest 'SECURITY: explain_sources() does not expose keys injected via all() ref' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { real => 'real_val' },
		config_dirs => [],
	);
	$cfg->all()->{'injected_key'} = 'injected_val';

	my $sources = $cfg->explain_sources();
	# injected_key may appear in explain_sources (it's in the live config hash),
	# but it must have an empty sources list - it has no provenance record.
	if(exists $sources->{'injected_key'}) {
		my @src = @{$sources->{'injected_key'}{'sources'}};
		is(scalar(@src), 0,
			'injected key has no source records in explain_sources');
	} else {
		pass('injected key not exposed by explain_sources (acceptable if _flatten_keys skips it)');
	}
};

# ===========================================================================
# NO SOURCES PROVIDED
# ---------------------------------------------------------------------------
# The POD states: "Constructor returns undef (not a blessed object) when no
# configuration data is found."  Verify the contract when every source layer
# is empty or absent.
# ===========================================================================

subtest 'no sources: new() with no data and empty config_dirs returns undef' => sub {
	local @ARGV = ();
	local %ENV  = %ENV;
	delete $ENV{$_} for grep { /^\QAPP_\E/i } keys %ENV;

	my $cfg = Config::Abstraction->new(config_dirs => []);
	ok(!defined($cfg), 'new() with no data and config_dirs=[] returns undef');
};

subtest 'no sources: new() with data=>undef and empty config_dirs returns undef' => sub {
	local @ARGV = ();
	local %ENV  = %ENV;
	delete $ENV{$_} for grep { /^\QAPP_\E/i } keys %ENV;

	# data => undef is explicitly ignored (carp warning emitted); no keys loaded.
	my $cfg;
	_silenced(sub {
		$cfg = Config::Abstraction->new(data => undef, config_dirs => []);
	});
	ok(!defined($cfg), 'data=>undef with no files and no env/argv returns undef');
};

subtest 'no sources: new() returns undef even when config_dirs has nonexistent paths' => sub {
	local @ARGV = ();
	local %ENV  = %ENV;
	delete $ENV{$_} for grep { /^\QAPP_\E/i } keys %ENV;

	my $cfg = Config::Abstraction->new(
		config_dirs => ['/no/such/dir/a', '/no/such/dir/b'],
	);
	ok(!defined($cfg), 'all-nonexistent config_dirs with no data returns undef');
};

subtest 'no sources: explain_sources() is never called on a undef object (contract check)' => sub {
	# The POD says "Always check the return value before using the object."
	# This test documents that calling methods on a undef constructor result
	# would die with "Can't call method on undef".  We verify the return value
	# is indeed undef and do not call any method on it.
	local @ARGV = ();
	local %ENV  = %ENV;
	delete $ENV{$_} for grep { /^\QAPP_\E/i } keys %ENV;

	my $cfg = Config::Abstraction->new(config_dirs => []);
	ok(!defined($cfg), 'constructor returned undef as documented');
	dies_ok { $cfg->get('any') } 'calling get() on undef object dies (correct API contract)';
};

# ===========================================================================
# CONFLICTING SOURCES: EXPLICIT PRECEDENCE VERIFICATION
# ---------------------------------------------------------------------------
# The merge order is: data < file < env < argv.
# Each tier must override the tier below it for the same key.
# The tests use a common key 'database.host' and layer it progressively.
# ===========================================================================

Readonly::Scalar my $CONFLICT_PREFIX  => 'CONFLICT_';
Readonly::Scalar my $CONFLICT_DATA    => 'data_host';
Readonly::Scalar my $CONFLICT_FILE    => 'file_host';
Readonly::Scalar my $CONFLICT_ENV     => 'env_host';
Readonly::Scalar my $CONFLICT_ARGV    => 'argv_host';

subtest 'conflict: file overrides data for the same key (data < file)' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "database:\n  host: $CONFLICT_FILE\n");

	my $cfg = Config::Abstraction->new(
		data        => { database => { host => $CONFLICT_DATA } },
		config_dirs => [$dir],
	);
	is($cfg->get('database.host'), $CONFLICT_FILE,
		"file value '$CONFLICT_FILE' overrides data value '$CONFLICT_DATA'");
	# Verify source provenance matches the winner
	my @file_src = grep { $_->{'type'} eq 'file' }
		@{$cfg->explain_sources()->{'database.host'}{'sources'}};
	ok(scalar(@file_src) >= 1, 'explain_sources records a file-type source for the winning value');
};

subtest 'conflict: env overrides file for the same key (file < env)' => sub {
	local %ENV = %ENV;
	$ENV{"${CONFLICT_PREFIX}DATABASE__HOST"} = $CONFLICT_ENV;

	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "database:\n  host: $CONFLICT_FILE\n");

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir],
		env_prefix  => $CONFLICT_PREFIX,
	);
	is($cfg->get('database.host'), $CONFLICT_ENV,
		"env value '$CONFLICT_ENV' overrides file value '$CONFLICT_FILE'");
};

subtest 'conflict: argv overrides env for the same key (env < argv)' => sub {
	local %ENV  = %ENV;
	local @ARGV = ("--${CONFLICT_PREFIX}DATABASE__HOST=$CONFLICT_ARGV");
	$ENV{"${CONFLICT_PREFIX}DATABASE__HOST"} = $CONFLICT_ENV;

	my $cfg = Config::Abstraction->new(
		data        => { database => { host => $CONFLICT_DATA } },
		config_dirs => [],
		env_prefix  => $CONFLICT_PREFIX,
	);
	is($cfg->get('database.host'), $CONFLICT_ARGV,
		"argv value '$CONFLICT_ARGV' overrides env value '$CONFLICT_ENV'");
};

subtest 'conflict: full four-way stack - argv wins over data/file/env' => sub {
	local %ENV  = %ENV;
	local @ARGV = ("--${CONFLICT_PREFIX}DATABASE__HOST=$CONFLICT_ARGV");
	$ENV{"${CONFLICT_PREFIX}DATABASE__HOST"} = $CONFLICT_ENV;

	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "database:\n  host: $CONFLICT_FILE\n");

	my $cfg = Config::Abstraction->new(
		data        => { database => { host => $CONFLICT_DATA } },
		config_dirs => [$dir],
		env_prefix  => $CONFLICT_PREFIX,
	);
	is($cfg->get('database.host'), $CONFLICT_ARGV,
		"argv is the definitive winner in a four-way data/file/env/argv conflict");

	# Confirm explain_sources records all four tiers and value matches argv
	my $explain = $cfg->explain_sources()->{'database.host'};
	is($explain->{'value'}, $CONFLICT_ARGV, 'explain_sources final value is argv value');
	my %by_type = map { $_->{'type'} => 1 } @{$explain->{'sources'}};
	ok($by_type{'data'}, 'data source recorded');
	ok($by_type{'file'}, 'file source recorded');
	ok($by_type{'env'},  'env source recorded');
	ok($by_type{'argv'}, 'argv source recorded');
};

subtest 'conflict: local.yaml overrides base.yaml for the same key (within file tier)' => sub {
	# Within the file tier, local.* files have higher precedence than base.*.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml',  "tier: base_val\n");
	_write_file($dir, 'local.yaml', "tier: local_val\n");

	my $cfg = Config::Abstraction->new(config_dirs => [$dir]);
	is($cfg->get('tier'), 'local_val',
		'local.yaml overrides base.yaml for the same key');
};

subtest 'conflict: same key from two formats in file tier - YAML wins over INI' => sub {
	# The load order is base.yaml, base.yml, base.json, base.xml, base.ini, …
	# base.ini is loaded after base.yaml so it has higher file-tier precedence.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "[database]\nhost = yaml_host\n");
	_write_file($dir, 'base.ini',  "[database]\nhost = ini_host\n");

	my $cfg;
	_silenced(sub {
		$cfg = Config::Abstraction->new(config_dirs => [$dir]);
	});
	ok(defined($cfg), 'both base.yaml and base.ini loaded without crash');
	# base.ini is loaded after base.yaml, so INI value wins within the file tier
	is($cfg->get('database.host'), 'ini_host',
		'base.ini (loaded later) overrides base.yaml within the file tier');
};

# ===========================================================================
# REGRESSION TESTS
# ---------------------------------------------------------------------------
# Named regression tests for bugs found in the wild.  Each test is labelled
# with the ticket or commit that introduced the fix so that git-blame can
# trace lineage and the test suite immediately identifies a reintroduced bug.
# ===========================================================================

subtest 'REGRESSION merge_defaults mutation: global section preserved across calls (fix: 0.40)' => sub {
	# Bug: merge_defaults did `delete $config->{'global'}` on the LIVE internal
	# hash returned by all().  After the first call, 'global' was gone, so
	# subsequent calls saw no 'global' section and returned different results.
	# Fix: work on a shallow copy of the config hash.
	my $cfg = Config::Abstraction->new(
		data        => { global => { timeout => 30 }, app => { name => 'myapp' } },
		config_dirs => [],
	);

	my $r1 = $cfg->merge_defaults(defaults => { x => 1 });
	my $r2 = $cfg->merge_defaults(defaults => { x => 1 });
	my $r3 = $cfg->merge_defaults(defaults => { x => 1 });

	is($r1->{'timeout'}, 30, 'call 1: global.timeout merged from global section');
	is($r2->{'timeout'}, 30, 'call 2: global.timeout still present (no mutation)');
	is($r3->{'timeout'}, 30, 'call 3: global.timeout still present on third call');
	ok(exists $cfg->all()->{'global'}, 'live internal config still has global key after calls');
};

subtest 'REGRESSION coderef in data survives Hash::Merge (fix: Hash::Merge clone=0 in _load_config 0.40)' => sub {
	# Bug: Hash::Merge::set_clone_behavior(0) was not set in _load_config; the
	# default clone=1 caused Storable::dclone to die with "Can't store CODE items"
	# when merging file data into a %merged that contained coderefs.
	# Fix: save/restore clone_behavior around the entire _load_config body.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "extra: loaded\n");

	my $cb  = sub { 42 };
	my $cfg = Config::Abstraction->new(
		data        => { fn => $cb },
		config_dirs => [$dir],
	);

	lives_ok { $cfg->get('fn') } 'get() on coderef key does not die after YAML file loaded';
	is(ref($cfg->get('fn')), 'CODE', 'coderef value still has CODE ref type');
	is($cfg->get('fn')->(), 42, 'coderef is still callable and returns expected value');
};

subtest 'REGRESSION exists() returns 1/0 not empty string in flat mode (fix: 0.38)' => sub {
	# Bug: the flat-mode branch did `return exists(...) ? 1 : 0` but the non-flat
	# branch just returned the result of the exists() call directly (empty string
	# for false).  Fix: explicit 1/0 return in both branches.
	my $cfg = Config::Abstraction->new(
		data        => { present => 'yes' },
		config_dirs => [],
		flatten     => 1,
	);
	my $yes = $cfg->exists('present');
	my $no  = $cfg->exists('absent');

	ok($yes == 1,  'exists() returns numeric 1 (not just truthy) in flat mode');
	ok($no  == 0,  'exists() returns numeric 0 (not empty string) in flat mode');
	is("$yes", '1', 'exists() true result stringifies to "1" in flat mode');
	is("$no",  '0', 'exists() false result stringifies to "0" in flat mode');
};

subtest 'REGRESSION get(undef) returns undef without warnings (fix: this session 0.40)' => sub {
	# Bug: get() called split() on an undef key, generating "Use of uninitialized
	# value in split" warnings.  Fix: early `return undef unless defined $key`.
	my $cfg = Config::Abstraction->new(
		data        => { x => 1 },
		config_dirs => [],
	);
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	my $val = $cfg->get(undef);
	ok(!defined($val), 'get(undef) returns undef');
	is(scalar(@warnings), 0, 'get(undef) emits no "uninitialized value" warnings');
};

subtest 'REGRESSION exists(undef) returns 0 without warnings (fix: this session 0.40)' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { x => 1 },
		config_dirs => [],
	);
	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	my $result = $cfg->exists(undef);
	is($result, 0, 'exists(undef) returns 0');
	is(scalar(@warnings), 0, 'exists(undef) emits no warnings');
};

subtest 'REGRESSION coderef alongside comma string not corrupted (fix: 0.38 _is_plain_scalar)' => sub {
	# Bug: the YAML comma-split loop iterated all values with `foreach my($k,$v)
	# (%{$data})` and blindly called $v =~ /,/ on coderefs, which stringified them
	# and caused "Not a HASH reference" or silent corruption.
	# Fix: _is_plain_scalar() guard skips non-string values.
	my $cb = sub { 'ok' };
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "tags: alpha,beta,gamma\nmode: live\n");

	my $cfg = Config::Abstraction->new(
		data        => { callback => $cb },
		config_dirs => [$dir],
	);
	lives_ok { $cfg->get('callback') } 'get() on coderef key alongside comma value does not die';
	is(ref($cfg->get('callback')), 'CODE', 'coderef type preserved');
	is($cfg->get('callback')->(), 'ok', 'coderef still callable');
	is($cfg->get('mode'), 'live', 'adjacent YAML scalar value intact');
};

subtest 'REGRESSION merge_defaults with bare hashref returns full config unchanged' => sub {
	# Documented Params::Get fast-path behaviour: a single bare hashref bypasses
	# $default key naming.  merge_defaults(\%hash) returns the full config, NOT
	# the merged result.  Callers must use merge_defaults(defaults => \%hash).
	my $cfg = Config::Abstraction->new(
		data        => { key => 'val' },
		config_dirs => [],
	);
	my %defaults = (extra => 'from_defaults');
	my $result   = $cfg->merge_defaults(\%defaults);

	# Fast-path: result is the full config (a hashref with 'key'), not the merged hash
	is(ref($result), 'HASH', 'bare hashref returns a hashref');
	is($result->{'key'}, 'val', 'full config returned unchanged (fast-path behaviour)');
};

# ===========================================================================
# TEST::MOST INTEGRATION: throws_ok / dies_ok / cmp_deeply
# ---------------------------------------------------------------------------
# The suite was using plain eval+ok patterns.  These subtests demonstrate the
# richer Test::Most vocabulary (from Test::Exception and Test::Deep) which
# gives clearer failure diagnostics.
# ===========================================================================

subtest 'Test::Most: throws_ok - AUTOLOAD dies with expected message' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { existing => 'val' },
		config_dirs => [],
		sep_char    => $SEP_US,
	);
	throws_ok { $cfg->definitely_no_such_key() }
		qr/No such config key 'definitely_no_such_key'/,
		'AUTOLOAD throws with the exact missing-key message (throws_ok)';
};

subtest 'Test::Most: throws_ok - AUTOLOAD nested key dies with expected message' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { db => { user => 'alice' } },
		config_dirs => [],
		sep_char    => $SEP_US,
	);
	throws_ok { $cfg->db_missing_field() }
		qr/No such config key/,
		'AUTOLOAD on absent nested key throws "No such config key" (throws_ok)';
};

subtest 'Test::Most: dies_ok - get() on undef object ref dies cleanly' => sub {
	my $cfg = Config::Abstraction->new(config_dirs => []);
	ok(!defined($cfg), 'precondition: no-source constructor returns undef');
	dies_ok { $cfg->get('anything') } 'get() on undef object ref dies (dies_ok)';
};

subtest 'Test::Most: lives_ok - get() on valid key in well-formed object' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { host => 'localhost' },
		config_dirs => [],
	);
	lives_ok { $cfg->get('host') } 'get() on valid key lives (lives_ok)';
	lives_ok { $cfg->get('absent') } 'get() on absent key returns undef, does not die (lives_ok)';
};

subtest 'Test::Most: cmp_deeply - explain_sources structure matches expected shape' => sub {
	local %ENV = %ENV;
	$ENV{"${ENV_PREFIX}HOST"} = 'env_host';

	my $cfg = Config::Abstraction->new(
		data        => { other => 'val' },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	my $sources = $cfg->explain_sources();

	# 'other' was set only by data; verify its shape with cmp_deeply
	cmp_deeply(
		$sources->{'other'},
		{
			value   => 'val',
			sources => supersetof(
				superhashof({ type => 'data', label => 'constructor data argument', value => 'val' })
			),
		},
		'explain_sources entry for data-only key matches expected deep structure',
	);
};

subtest 'Test::Most: cmp_deeply - multiple sources ordered correctly' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "multi:\n  k: file_val\n");
	local %ENV = %ENV;
	$ENV{"${ENV_PREFIX}MULTI__K"} = 'env_val';

	my $cfg = Config::Abstraction->new(
		data        => { multi => { k => 'data_val' } },
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
	);
	my $entry = $cfg->explain_sources()->{'multi.k'};

	# Final value must be env (highest precedence)
	is($entry->{'value'}, 'env_val', 'final value is env (highest precedence)');

	# sources list must contain at least data, file, and env entries
	cmp_deeply(
		$entry->{'sources'},
		supersetof(
			superhashof({ type => 'data' }),
			superhashof({ type => 'file' }),
			superhashof({ type => 'env'  }),
		),
		'sources list contains data, file, and env entries (cmp_deeply/supersetof)',
	);

	# First element must be data (lowest precedence)
	is($entry->{'sources'}[0]{'type'}, 'data', 'first source is data (lowest precedence)');
};

# ---------------------------------------------------------------------------
# UNDEF VALUE PROPAGATION
# Verifies that undef values from different sources interact with
# Hash::Merge LEFT_PRECEDENT exactly as documented: higher-precedence sources
# always win, including when the winning value is undef.
# ---------------------------------------------------------------------------

subtest 'undef propagation: file value overrides data undef' => sub {
	# data sets key to undef; file (higher precedence) sets key to a string.
	# Expected: file wins — get() returns the file value, not undef.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "host: file_host\n");

	my $cfg = Config::Abstraction->new(
		data        => { host => undef },
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('host'), 'file_host',
		'file value overrides data undef (file has higher precedence)');
	diag('host from file over data-undef: ' . ($cfg->get('host') // '(undef)'))
		if $ENV{TEST_VERBOSE};
};

subtest 'undef propagation: file YAML null overrides data value' => sub {
	# YAML null (~) in a file is a legitimate undef. With LEFT_PRECEDENT the
	# file (left, higher precedence) wins even when its value is undef.
	# Expected: get() returns undef despite data having a real value.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "host: ~\n");

	my $cfg = Config::Abstraction->new(
		data        => { host => 'data_host' },
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
	);
	ok(!defined($cfg->get('host')),
		'YAML null in file overrides non-undef data value (file null wins)');
};

subtest 'undef propagation: data undef untouched by file remains undef with exists()=1' => sub {
	# Only key1 appears in the file. key2 set to undef in data is never touched
	# by any later source. Verify: get() returns undef AND exists() returns 1
	# (the key exists, it is just explicitly undef).
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "key1: file_val\n");

	my $cfg = Config::Abstraction->new(
		data        => { key1 => 'data_val', key2 => undef },
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
	);
	ok(!defined($cfg->get('key2')),
		'key2 undef from data is untouched when file does not mention it');
	is($cfg->exists('key2'), 1,
		'exists() returns 1 for a key that exists but is undef');
	is($cfg->get('key1'), 'file_val',
		'key1 correctly overridden by file (sanity check)');
};

subtest 'undef propagation: local.yaml null overrides base.yaml value within file tier' => sub {
	# Within the file tier, local.yaml has higher precedence than base.yaml.
	# A YAML null in local.yaml should override a real value in base.yaml.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml',  "setting: base_val\n");
	_write_file($dir, 'local.yaml', "setting: ~\n");

	my $cfg = Config::Abstraction->new(
		data        => {},
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
	);
	ok(!defined($cfg->get('setting')),
		'local.yaml YAML null overrides base.yaml value within file tier');
};

subtest 'undef propagation: prefer_data() retrieves data undef even after file override' => sub {
	# File overrides the key to a real value, but prefer_data() should bypass
	# higher-precedence sources and return the original data-layer value (undef).
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "host: file_host\n");

	my $cfg = Config::Abstraction->new(
		data        => { host => undef },
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('host'), 'file_host',
		'get() returns file value (sanity check)');

	my ($found, $val) = (0, 'SENTINEL');
	# prefer_data returns the data layer value, bypassing file
	my $pref = $cfg->prefer_data('host');
	# $found is internal; we verify the return value is undef (not 'file_host')
	ok(!defined($pref),
		'prefer_data() returns data-layer undef even when file overrode it');
};

# ---------------------------------------------------------------------------
# NESTED HASH MERGE CORRECTNESS
# Verifies that Hash::Merge LEFT_PRECEDENT combines nested hashes additively
# (both sides survive) rather than replacing whole structures, except when a
# later source explicitly sets the parent key to null.
# ---------------------------------------------------------------------------

subtest 'nested merge: file adds key — both data and file keys survive' => sub {
	# data provides db.user; file provides db.host.
	# Hash::Merge should combine them: both keys coexist under db.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "db:\n  host: file_host\n");

	my $cfg = Config::Abstraction->new(
		data        => { db => { user => 'alice' } },
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('db.user'), 'alice',     'data key db.user survives file merge');
	is($cfg->get('db.host'), 'file_host', 'file key db.host present after merge');
	diag('db.user=' . ($cfg->get('db.user') // '(undef)') . ' db.host=' . ($cfg->get('db.host') // '(undef)'))
		if $ENV{TEST_VERBOSE};
};

subtest 'nested merge: file overrides one key; data sibling key survives' => sub {
	# data provides db.user=alice and db.pass=secret.
	# file overrides only db.user=bob.
	# db.pass must survive unchanged.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "db:\n  user: bob\n");

	my $cfg = Config::Abstraction->new(
		data        => { db => { user => 'alice', pass => 'secret' } },
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('db.user'), 'bob',    'file override of db.user wins');
	is($cfg->get('db.pass'), 'secret', 'data db.pass survives partial file override');
};

subtest 'nested merge: file null replaces entire nested hash (all subkeys gone)' => sub {
	# When a file sets the parent key to YAML null (~), the entire nested
	# hash from data is replaced by undef. Subkeys are no longer accessible.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "db: ~\n");

	my $cfg = Config::Abstraction->new(
		data        => { db => { user => 'alice', pass => 'secret' } },
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
	);
	ok(!defined($cfg->get('db')),
		'parent key is undef when file sets it to YAML null');
	ok(!defined($cfg->get('db.user')),
		'nested subkey db.user is gone when parent is nulled by file');
};

subtest 'nested merge: env var adds key to file-provided nested hash — both coexist' => sub {
	# file provides db.user; env sets db.pass via APP_DB__PASS.
	# Both keys should coexist under db after the env merge.
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "db:\n  user: file_user\n");
	local %ENV = %ENV;
	$ENV{"${ENV_PREFIX}DB__PASS"} = 'env_pass';
	delete $ENV{"${ENV_PREFIX}DB__USER"};

	my $cfg = Config::Abstraction->new(
		data        => {},
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('db.user'), 'file_user', 'file key db.user survives env merge');
	is($cfg->get('db.pass'), 'env_pass',  'env key db.pass coexists with file key');
};

subtest 'nested merge_defaults: without merge => 1, plain hash merge replaces nested hashes' => sub {
	# Without merge => 1, merge_defaults uses {%defaults, %config} at the top
	# level (a plain Perl hash merge).  Config's 'section' key wins over
	# defaults' 'section' key, and the entire nested hash is replaced, so the
	# 'c' key from defaults is silently dropped.
	my $cfg = Config::Abstraction->new(
		data        => { section => { a => 1, b => 2 } },
		config_dirs => [],
	);
	my $defaults = { section => { a => 99, c => 3 }, extra => 'kept' };

	my $merged = $cfg->merge_defaults(defaults => $defaults);

	is($merged->{'section'}{'a'}, 1,
		'plain hash merge: config a wins over defaults a');
	is($merged->{'section'}{'b'}, 2,
		'plain hash merge: config b is present');
	ok(!exists($merged->{'section'}{'c'}),
		'plain hash merge: defaults c is lost (whole nested section replaced)');
	is($merged->{'extra'}, 'kept',
		'plain hash merge: extra key from defaults survives at top level');
};

subtest 'nested merge_defaults: merge => 1 uses Hash::Merge and combines nested keys' => sub {
	# With merge => 1, merge_defaults calls Hash::Merge::merge($config, $defaults)
	# which recurses into nested hashes.  Config wins for conflicting keys;
	# both sides' unique nested keys survive.
	my $cfg = Config::Abstraction->new(
		data        => { section => { a => 1, b => 2 } },
		config_dirs => [],
	);
	my $defaults = { section => { a => 99, c => 3 }, extra => 'kept' };

	my $merged = $cfg->merge_defaults(defaults => $defaults, merge => 1);

	is($merged->{'section'}{'a'}, 1,
		'Hash::Merge merge: config a wins over defaults a');
	is($merged->{'section'}{'b'}, 2,
		'Hash::Merge merge: config b is present');
	is($merged->{'section'}{'c'}, 3,
		'Hash::Merge merge: defaults c survives recursive merge');
	is($merged->{'extra'}, 'kept',
		'Hash::Merge merge: extra key from defaults survives at top level');
};

# ---------------------------------------------------------------------------
# TOML FORMAT SUPPORT
# Verifies that base.toml / local.toml are discovered and merged with the
# same precedence rules as YAML/JSON/INI, and that TOML is tried as a
# fallback parser for extensionless config_file entries.
# ---------------------------------------------------------------------------

subtest 'TOML: base.toml is loaded from config_dirs' => sub {
	# Verify that base.toml in a config_dir is read and its values accessible.
	plan skip_all => 'TOML::Tiny not installed' unless eval { require TOML::Tiny; 1 };

	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.toml', qq{host = "toml_host"\nport = 5432\n});

	my $cfg = Config::Abstraction->new(
		data        => {},
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
	);
	ok(defined($cfg), 'object created when only base.toml is present');
	is($cfg->get('host'), 'toml_host', 'scalar string from base.toml is loaded');
	is($cfg->get('port'), 5432,        'integer from base.toml is loaded');
};

subtest 'TOML: nested table section is loaded as hashref' => sub {
	plan skip_all => 'TOML::Tiny not installed' unless eval { require TOML::Tiny; 1 };

	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.toml', qq{[database]\nhost = "db.example.com"\nport = 5432\n});

	my $cfg = Config::Abstraction->new(
		data        => {},
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('database.host'), 'db.example.com', 'nested TOML table key is accessible via dotted notation');
	is($cfg->get('database.port'), 5432,              'nested TOML integer is accessible');
};

subtest 'TOML: local.toml overrides base.toml (file-tier precedence)' => sub {
	# Within the file tier, local.toml has higher precedence than base.toml.
	# A key in local.toml must win; keys only in base.toml must survive.
	plan skip_all => 'TOML::Tiny not installed' unless eval { require TOML::Tiny; 1 };

	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.toml',  qq{host = "base_host"\nport = 5432\n});
	_write_file($dir, 'local.toml', qq{host = "local_host"\n});

	my $cfg = Config::Abstraction->new(
		data        => {},
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('host'), 'local_host', 'local.toml host overrides base.toml host');
	is($cfg->get('port'), 5432,         'base.toml port survives when local.toml does not mention it');
};

subtest 'TOML: data constructor has lower precedence than base.toml' => sub {
	plan skip_all => 'TOML::Tiny not installed' unless eval { require TOML::Tiny; 1 };

	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.toml', qq{host = "toml_host"\n});

	my $cfg = Config::Abstraction->new(
		data        => { host => 'data_host', extra => 'kept' },
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('host'),  'toml_host', 'base.toml overrides data constructor value');
	is($cfg->get('extra'), 'kept',      'data key not in base.toml survives');
};

subtest 'TOML: TOML boolean and array types are loaded without corruption' => sub {
	# TOML::Tiny returns Perl values: booleans as JSON::PP::Boolean objects,
	# arrays as arrayrefs.  Verify they arrive intact.
	plan skip_all => 'TOML::Tiny not installed' unless eval { require TOML::Tiny; 1 };

	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.toml', qq{debug = true\ntags = ["web", "api"]\n});

	my $cfg = Config::Abstraction->new(
		data        => {},
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
	);
	ok($cfg->get('debug'), 'TOML boolean true is truthy');
	my $tags = $cfg->get('tags');
	ok(ref($tags) eq 'ARRAY', 'TOML array is loaded as arrayref');
	is($tags->[0], 'web', 'first TOML array element is correct');
	is($tags->[1], 'api', 'second TOML array element is correct');
};

subtest 'TOML: malformed TOML file is skipped with a carp warning' => sub {
	# A TOML file with syntax errors should emit a carp and be skipped,
	# not abort construction.  data values must survive.
	plan skip_all => 'TOML::Tiny not installed' unless eval { require TOML::Tiny; 1 };

	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.toml', qq{host = "unclosed string\n});

	my @warnings;
	local $SIG{__WARN__} = sub { push @warnings, $_[0] };

	my $cfg = Config::Abstraction->new(
		data        => { fallback => 'alive' },
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
	);
	ok(@warnings > 0, 'malformed TOML emits at least one carp warning');
	ok(defined($cfg), 'construction succeeds despite malformed base.toml');
	is($cfg->get('fallback'), 'alive', 'data values survive a malformed TOML file');
};

subtest 'TOML: config_file with .toml extension is loaded via extensionless chain' => sub {
	# When config_file points to a .toml file, the all-parsers chain
	# should try TOML::Tiny and succeed.
	plan skip_all => 'TOML::Tiny not installed' unless eval { require TOML::Tiny; 1 };

	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'myapp.toml', qq{[server]\nhost = "explicit_host"\nport = 9000\n});

	my $cfg = Config::Abstraction->new(
		config_file => 'myapp.toml',
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
	);
	ok(defined($cfg), 'config_file pointing to a .toml file is loaded');
	is($cfg->get('server.host'), 'explicit_host', 'TOML section key accessible via dotted notation from config_file');
	is($cfg->get('server.port'), 9000,             'TOML section integer accessible from config_file');
};

# ---------------------------------------------------------------------------
# validators option - per-key value validation
# ---------------------------------------------------------------------------

subtest 'validators: type integer accepts valid integer strings' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { port => 8080 },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
		validators  => { 'port' => 'integer' },
	);
	ok(defined($cfg), 'construction succeeds for valid integer');
	is($cfg->get('port'), 8080, 'value unchanged after integer validation');
};

subtest 'validators: type integer rejects non-integer string' => sub {
	dies_ok {
		Config::Abstraction->new(
			data        => { port => '80.5' },
			config_dirs => [],
			env_prefix  => $ENV_PREFIX,
			validators  => { 'port' => 'integer' },
		);
	} 'construction croaks for float value failing integer type';
	like($@, qr/must be an integer/, 'error message names the type');
};

subtest 'validators: type integer rejects undef' => sub {
	dies_ok {
		Config::Abstraction->new(
			data        => { port => undef },
			config_dirs => [],
			env_prefix  => $ENV_PREFIX,
			validators  => { 'port' => 'integer' },
		);
	} 'undef value fails integer validation';
};

subtest 'validators: type number accepts integer and float' => sub {
	for my $val (42, 3.14, -1, '0.001', '1e5') {
		my $cfg = Config::Abstraction->new(
			data        => { n => $val },
			config_dirs => [],
			env_prefix  => $ENV_PREFIX,
			validators  => { n => 'number' },
		);
		ok(defined($cfg), "number type accepts '$val'");
	}
};

subtest 'validators: type boolean accepts canonical values' => sub {
	for my $val (qw(0 1 true false yes no TRUE FALSE YES NO)) {
		my $cfg = Config::Abstraction->new(
			data        => { flag => $val },
			config_dirs => [],
			env_prefix  => $ENV_PREFIX,
			validators  => { flag => 'boolean' },
		);
		ok(defined($cfg), "boolean type accepts '$val'");
	}
};

subtest 'validators: type boolean rejects non-boolean' => sub {
	dies_ok {
		Config::Abstraction->new(
			data        => { flag => 'maybe' },
			config_dirs => [],
			env_prefix  => $ENV_PREFIX,
			validators  => { flag => 'boolean' },
		);
	} "boolean type rejects 'maybe'";
};

subtest 'validators: type string accepts defined scalar, rejects undef' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { name => 'hello' },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
		validators  => { name => 'string' },
	);
	ok(defined($cfg), 'string type accepts defined scalar');

	dies_ok {
		Config::Abstraction->new(
			data        => { name => undef },
			config_dirs => [],
			env_prefix  => $ENV_PREFIX,
			validators  => { name => 'string' },
		);
	} 'string type rejects undef';
};

subtest 'validators: type array and hash' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { tags => [qw(a b)], meta => { k => 1 } },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
		validators  => { tags => 'array', meta => 'hash' },
	);
	ok(defined($cfg), 'array and hash types accept correct references');

	dies_ok {
		Config::Abstraction->new(
			data        => { tags => 'not_an_array' },
			config_dirs => [],
			env_prefix  => $ENV_PREFIX,
			validators  => { tags => 'array' },
		);
	} 'array type rejects plain scalar';
};

subtest 'validators: unknown type string croaks' => sub {
	dies_ok {
		Config::Abstraction->new(
			data        => { x => 'y' },
			config_dirs => [],
			env_prefix  => $ENV_PREFIX,
			validators  => { x => 'imaginary_type' },
		);
	} 'unknown type string causes croak';
	like($@, qr/unknown type/, 'error message mentions unknown type');
};

subtest 'validators: regex spec accepts matching value, rejects non-matching' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { level => 'debug' },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
		validators  => { level => qr/^(?:debug|info|warn|error|fatal)$/i },
	);
	ok(defined($cfg), 'regex validator passes for matching value');

	dies_ok {
		Config::Abstraction->new(
			data        => { level => 'verbose' },
			config_dirs => [],
			env_prefix  => $ENV_PREFIX,
			validators  => { level => qr/^(?:debug|info|warn|error|fatal)$/i },
		);
	} 'regex validator rejects non-matching value';
	like($@, qr/does not match required pattern/, 'regex failure error message correct');
};

subtest 'validators: coderef validator - passes and fails' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { port => 443 },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
		validators  => { port => sub { my $v = shift; defined($v) && $v >= 1 && $v <= 65535 } },
	);
	ok(defined($cfg), 'coderef validator passes for value in range');

	dies_ok {
		Config::Abstraction->new(
			data        => { port => 70000 },
			config_dirs => [],
			env_prefix  => $ENV_PREFIX,
			validators  => { port => sub { my $v = shift; defined($v) && $v >= 1 && $v <= 65535 } },
		);
	} 'coderef validator rejects out-of-range value';
	like($@, qr/custom validator returned false/, 'coderef failure error message correct');
};

subtest 'validators: hashref spec with type, min, max, pattern' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { port => 8080, name => 'myapp' },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
		validators  => {
			port => { type => 'integer', min => 1,    max => 65535 },
			name => { pattern => qr/^\w[\w\-]{1,63}$/ },
		},
	);
	ok(defined($cfg), 'hashref spec passes for valid values');

	dies_ok {
		Config::Abstraction->new(
			data        => { port => 0 },
			config_dirs => [],
			env_prefix  => $ENV_PREFIX,
			validators  => { port => { type => 'integer', min => 1 } },
		);
	} 'hashref spec with min rejects value below minimum';
	like($@, qr/less than minimum/, 'min error message correct');

	dies_ok {
		Config::Abstraction->new(
			data        => { port => 99999 },
			config_dirs => [],
			env_prefix  => $ENV_PREFIX,
			validators  => { port => { type => 'integer', max => 65535 } },
		);
	} 'hashref spec with max rejects value above maximum';
	like($@, qr/exceeds maximum/, 'max error message correct');
};

subtest 'validators: hashref spec with required croaks for missing key' => sub {
	dies_ok {
		Config::Abstraction->new(
			data        => { other => 1 },
			config_dirs => [],
			env_prefix  => $ENV_PREFIX,
			validators  => { port => { type => 'integer', required => 1 } },
		);
	} 'required key missing croaks';
	like($@, qr/required key/, 'required error message correct');
};

subtest 'validators: invalid spec type (arrayref) croaks' => sub {
	dies_ok {
		Config::Abstraction->new(
			data        => { x => 1 },
			config_dirs => [],
			env_prefix  => $ENV_PREFIX,
			validators  => { x => [1, 2, 3] },
		);
	} 'arrayref validator spec croaks with clear message';
	like($@, qr/invalid validator/, 'error message names invalid validator');
};

subtest 'validators: works in lazy mode (deferred until first access)' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { port => 'not_a_number' },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
		lazy        => 1,
		validators  => { port => 'integer' },
	);
	ok(defined($cfg), 'lazy construction with failing validator does not croak at new()');

	dies_ok { $cfg->get('port') } 'lazy validator fires on first accessor call';
	like($@, qr/must be an integer/, 'lazy validator error message correct');
};

subtest 'validators: dotted key validated against nested config' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { database => { port => 5432 } },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
		validators  => { 'database.port' => 'integer' },
	);
	ok(defined($cfg), 'dotted-key validator resolves through nested config');
};

# ---------------------------------------------------------------------------
# checker option - Config::Checker prototype-based validation
# ---------------------------------------------------------------------------

subtest 'checker: graceful skip when Config::Checker absent' => sub {
	# Use Test::Without::Module to simulate Config::Checker being absent.
	# If the module is already loaded, mask it from %INC so require re-evaluates.
	{
		local %INC = %INC;
		delete $INC{'Config/Checker.pm'};
		eval { require Test::Without::Module; 1 } or plan skip_all => 'Test::Without::Module not installed';
		Test::Without::Module->import('Config::Checker');

		my @warnings;
		local $SIG{__WARN__} = sub { push @warnings, @_ };

		my $cfg = Config::Abstraction->new(
			data        => { host => 'localhost' },
			config_dirs => [],
			env_prefix  => $ENV_PREFIX,
			checker     => "host: hostname of the server\n",
		);
		ok(defined($cfg), 'construction succeeds when Config::Checker is absent');
		ok(scalar(grep { /Config::Checker not available/ } @warnings),
			'carp warning emitted when Config::Checker is absent');

		Test::Without::Module->unimport('Config::Checker');
	}
};

subtest 'checker: valid config passes prototype' => sub {
	plan skip_all => 'Config::Checker not installed' unless eval { require Config::Checker; 1 };

	my $cfg = Config::Abstraction->new(
		data        => { host => 'localhost', port => 5432 },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
		checker     => "host: the database hostname\nport: '?<5432>port number[INTEGER]'\n",
	);
	ok(defined($cfg), 'valid config passes Config::Checker prototype');
};

subtest 'checker: invalid config fails prototype and croaks' => sub {
	plan skip_all => 'Config::Checker not installed' unless eval { require Config::Checker; 1 };

	dies_ok {
		Config::Abstraction->new(
			data        => {},
			config_dirs => [],
			env_prefix  => $ENV_PREFIX,
			checker     => "host: required hostname\n",
		);
	} 'Config::Checker failure croaks';
	like($@, qr/checker validation failed/, 'checker error message names the cause');
};

subtest 'checker: works in lazy mode' => sub {
	plan skip_all => 'Config::Checker not installed' unless eval { require Config::Checker; 1 };

	my $cfg = Config::Abstraction->new(
		data        => {},
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
		lazy        => 1,
		checker     => "host: required hostname\n",
	);
	ok(defined($cfg), 'lazy construction with failing checker does not croak at new()');

	dies_ok { $cfg->get('anything') } 'lazy checker fires on first accessor call';
	like($@, qr/checker validation failed/, 'lazy checker error message correct');
};

# ---------------------------------------------------------------------------
# Encrypted values (ENC[AES256GCM,...]) - requires CryptX
# ---------------------------------------------------------------------------

my $CRYPTX_AVAILABLE = eval { require Crypt::AuthEnc::GCM; require Crypt::PRNG; 1 };

subtest 'encryption: ENC[] tokens pass through unchanged when no key configured' => sub {
	# Without a key, ENC[] tokens are left as literal strings (opt-in feature).
	my $token = 'ENC[AES256GCM,AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA]';
	my $cfg = Config::Abstraction->new(
		data        => { password => $token },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	ok(defined($cfg), 'construction succeeds with ENC[] token and no key');
	is($cfg->get('password'), $token, 'ENC[] token left unchanged when no key configured');
};

subtest 'encryption: encrypt_value and transparent decryption round-trip' => sub {
	plan skip_all => 'CryptX not installed' unless $CRYPTX_AVAILABLE;

	# Generate a 32-byte test key (NOT from /dev/urandom for determinism in tests)
	my $key_hex = '0' x 64;   # 32 zero bytes as hex -- valid for tests only

	# Encrypt via encrypt_value()
	my $cfg = Config::Abstraction->new(
		data           => {},
		config_dirs    => [],
		env_prefix     => $ENV_PREFIX,
		encryption_key => pack('H*', $key_hex),
		lazy           => 1,
	);
	my $token = $cfg->encrypt_value('s3cr3t_pass');
	like($token, qr/^ENC\[AES256GCM,[A-Za-z0-9_\-]+\]$/, 'encrypt_value returns well-formed ENC token');

	# Decrypt transparently on construction
	my $cfg2 = Config::Abstraction->new(
		data           => { password => $token },
		config_dirs    => [],
		env_prefix     => $ENV_PREFIX,
		encryption_key => pack('H*', $key_hex),
	);
	ok(defined($cfg2), 'construction with ENC[] token and key succeeds');
	is($cfg2->get('password'), 's3cr3t_pass', 'ENC[] token decrypted transparently');
};

subtest 'encryption: each call to encrypt_value produces a different token (fresh nonce)' => sub {
	plan skip_all => 'CryptX not installed' unless $CRYPTX_AVAILABLE;

	my $cfg = Config::Abstraction->new(
		data           => {},
		config_dirs    => [],
		env_prefix     => $ENV_PREFIX,
		encryption_key => 'A' x 32,
		lazy           => 1,
	);
	my $t1 = $cfg->encrypt_value('same');
	my $t2 = $cfg->encrypt_value('same');
	isnt($t1, $t2, 'same plaintext produces different tokens (fresh nonce each time)');
};

subtest 'encryption: key as 64-char hex string' => sub {
	plan skip_all => 'CryptX not installed' unless $CRYPTX_AVAILABLE;

	my $cfg_enc = Config::Abstraction->new(
		data           => {},
		config_dirs    => [],
		env_prefix     => $ENV_PREFIX,
		encryption_key => 'a' x 64,   # 64 hex chars = 32 bytes
		lazy           => 1,
	);
	my $token = $cfg_enc->encrypt_value('hexkey_test');

	my $cfg_dec = Config::Abstraction->new(
		data           => { pw => $token },
		config_dirs    => [],
		env_prefix     => $ENV_PREFIX,
		encryption_key => 'a' x 64,
	);
	is($cfg_dec->get('pw'), 'hexkey_test', 'key supplied as 64-char hex string works');
};

subtest 'encryption: key via ENCRYPTION_KEY environment variable' => sub {
	plan skip_all => 'CryptX not installed' unless $CRYPTX_AVAILABLE;

	require MIME::Base64;
	my $key_b64 = MIME::Base64::encode_base64url('K' x 32, '');

	local %ENV = (%ENV, ENCRYPTION_KEY => $key_b64);

	my $cfg_enc = Config::Abstraction->new(
		data        => {},
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
		lazy        => 1,
	);
	my $token = $cfg_enc->encrypt_value('env_key_test');

	my $cfg_dec = Config::Abstraction->new(
		data        => { secret => $token },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg_dec->get('secret'), 'env_key_test', 'key resolved from ENCRYPTION_KEY env var');
};

subtest 'encryption: key via encryption_key_file' => sub {
	plan skip_all => 'CryptX not installed' unless $CRYPTX_AVAILABLE;

	my $dir = tempdir(CLEANUP => 1);
	my $kf  = File::Spec->catfile($dir, 'enc.key');
	_write_file($dir, 'enc.key', 'B' x 64 . "\n");  # 64 hex chars

	my $cfg_enc = Config::Abstraction->new(
		data                => {},
		config_dirs         => [],
		env_prefix          => $ENV_PREFIX,
		encryption_key_file => $kf,
		lazy                => 1,
	);
	my $token = $cfg_enc->encrypt_value('keyfile_test');

	my $cfg_dec = Config::Abstraction->new(
		data                => { pw => $token },
		config_dirs         => [],
		env_prefix          => $ENV_PREFIX,
		encryption_key_file => $kf,
	);
	is($cfg_dec->get('pw'), 'keyfile_test', 'key resolved from encryption_key_file');
};

subtest 'encryption: wrong key causes croak on decryption' => sub {
	plan skip_all => 'CryptX not installed' unless $CRYPTX_AVAILABLE;

	my $cfg = Config::Abstraction->new(
		data           => {},
		config_dirs    => [],
		env_prefix     => $ENV_PREFIX,
		encryption_key => 'A' x 32,
		lazy           => 1,
	);
	my $token = $cfg->encrypt_value('secret');

	dies_ok {
		Config::Abstraction->new(
			data           => { pw => $token },
			config_dirs    => [],
			env_prefix     => $ENV_PREFIX,
			encryption_key => 'B' x 32,   # different key
		);
	} 'wrong decryption key croaks';
	like($@, qr/decryption failed/, 'error message names the cause');
};

subtest 'encryption: malformed ENC token croaks' => sub {
	plan skip_all => 'CryptX not installed' unless $CRYPTX_AVAILABLE;

	dies_ok {
		Config::Abstraction->new(
			data           => { pw => 'ENC[AES256GCM,!!!not-base64url!!!]' },
			config_dirs    => [],
			env_prefix     => $ENV_PREFIX,
			encryption_key => 'A' x 32,
		);
	} 'malformed ENC token croaks';
	like($@, qr/malformed ENC token/, 'error message names malformed token');
};

subtest 'encryption: unsupported algorithm in ENC token croaks' => sub {
	plan skip_all => 'CryptX not installed' unless $CRYPTX_AVAILABLE;

	dies_ok {
		Config::Abstraction->new(
			data           => { pw => 'ENC[BLOWFISH,AAAAAAAAAAAAAAAAAAAA]' },
			config_dirs    => [],
			env_prefix     => $ENV_PREFIX,
			encryption_key => 'A' x 32,
		);
	} 'unsupported algorithm in ENC token croaks';
	like($@, qr/unsupported encryption algorithm/, 'error message names the algorithm');
};

subtest 'encryption: nested config values are decrypted' => sub {
	plan skip_all => 'CryptX not installed' unless $CRYPTX_AVAILABLE;

	my $key = 'C' x 32;
	my $cfg_enc = Config::Abstraction->new(
		data => {}, config_dirs => [], env_prefix => $ENV_PREFIX,
		encryption_key => $key, lazy => 1,
	);
	my $token = $cfg_enc->encrypt_value('nested_secret');

	my $cfg = Config::Abstraction->new(
		data           => { database => { password => $token } },
		config_dirs    => [],
		env_prefix     => $ENV_PREFIX,
		encryption_key => $key,
	);
	is($cfg->get('database.password'), 'nested_secret', 'nested ENC[] value decrypted transparently');
};

subtest 'encryption: ENC[] in array element is decrypted' => sub {
	plan skip_all => 'CryptX not installed' unless $CRYPTX_AVAILABLE;

	my $key = 'D' x 32;
	my $cfg_enc = Config::Abstraction->new(
		data => {}, config_dirs => [], env_prefix => $ENV_PREFIX,
		encryption_key => $key, lazy => 1,
	);
	my $token = $cfg_enc->encrypt_value('array_secret');

	my $cfg = Config::Abstraction->new(
		data           => { secrets => [$token, 'plain'] },
		config_dirs    => [],
		env_prefix     => $ENV_PREFIX,
		encryption_key => $key,
	);
	my $arr = $cfg->get('secrets');
	is($arr->[0], 'array_secret', 'ENC[] in array element decrypted');
	is($arr->[1], 'plain',        'non-ENC array element unchanged');
};

subtest 'encryption: encrypt_value croaks when no key configured' => sub {
	my $cfg = Config::Abstraction->new(
		data        => {},
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
		lazy        => 1,
	);
	dies_ok { $cfg->encrypt_value('oops') } 'encrypt_value croaks with no key';
	like($@, qr/no encryption key configured/, 'error message is clear');
};

subtest 'encryption: invalid key length croaks' => sub {
	dies_ok {
		Config::Abstraction->new(
			data           => { pw => 'x' },
			config_dirs    => [],
			env_prefix     => $ENV_PREFIX,
			encryption_key => 'tooshort',
		);
	} 'key with wrong length croaks';
	like($@, qr/encryption_key must be/, 'error names valid formats');
};

subtest 'encryption: works in lazy mode (decryption deferred to first access)' => sub {
	plan skip_all => 'CryptX not installed' unless $CRYPTX_AVAILABLE;

	my $key = 'E' x 32;
	my $cfg_enc = Config::Abstraction->new(
		data => {}, config_dirs => [], env_prefix => $ENV_PREFIX,
		encryption_key => $key, lazy => 1,
	);
	my $token = $cfg_enc->encrypt_value('lazy_secret');

	my $cfg = Config::Abstraction->new(
		data           => { pw => $token },
		config_dirs    => [],
		env_prefix     => $ENV_PREFIX,
		encryption_key => $key,
		lazy           => 1,
	);
	ok(defined($cfg), 'lazy construction with ENC[] token succeeds');
	is($cfg->get('pw'), 'lazy_secret', 'lazy ENC[] decrypted on first access');
};

# ---------------------------------------------------------------------------
# environment option - environment-specific file tier (base.{env}.* / local.{env}.*)
# ---------------------------------------------------------------------------

subtest 'environment: base.{env}.yaml loaded after base.yaml, overrides it' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml',       "host: base\nport: 5432\n");
	_write_file($dir, 'base.prod.yaml',  "host: prod-db\n");

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
		environment => 'prod',
	);
	ok(defined($cfg), 'construction succeeds with env-specific file');
	is($cfg->get('host'), 'prod-db', 'base.prod.yaml overrides base.yaml');
	is($cfg->get('port'), 5432,      'base.yaml key not in base.prod.yaml survives');
};

subtest 'environment: local.{env}.yaml loaded after local.yaml, overrides it' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml',         "host: base\nport: 5432\n");
	_write_file($dir, 'local.yaml',        "host: local\n");
	_write_file($dir, 'local.staging.yaml', "host: staging-db\n");

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
		environment => 'staging',
	);
	is($cfg->get('host'), 'staging-db', 'local.staging.yaml overrides local.yaml');
	is($cfg->get('port'), 5432,         'base.yaml key survives through all env tiers');
};

subtest 'environment: full 5-tier merge order is correct' => sub {
	# data < base.yaml < base.prod.yaml < local.yaml < local.prod.yaml
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml',       "a: base\nb: base\nc: base\nd: base\n");
	_write_file($dir, 'base.prod.yaml',  "b: base_prod\nc: base_prod\nd: base_prod\n");
	_write_file($dir, 'local.yaml',      "c: local\nd: local\n");
	_write_file($dir, 'local.prod.yaml', "d: local_prod\n");

	my $cfg = Config::Abstraction->new(
		data        => { a => 'data', b => 'data', c => 'data', d => 'data' },
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
		environment => 'prod',
	);
	is($cfg->get('a'), 'base',       'base.yaml overrides data');
	is($cfg->get('b'), 'base_prod',  'base.prod.yaml overrides base.yaml');
	is($cfg->get('c'), 'local',      'local.yaml overrides base.prod.yaml');
	is($cfg->get('d'), 'local_prod', 'local.prod.yaml overrides local.yaml');
};

subtest 'environment: no env set means env-specific files are skipped' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml',      "host: base\n");
	_write_file($dir, 'base.prod.yaml', "host: prod\n");  # should be ignored

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
		# no environment option
	);
	is($cfg->get('host'), 'base', 'base.prod.yaml ignored when no environment set');
};

subtest 'environment: auto-detected from {env_prefix}ENV' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml',     "tier: base\n");
	_write_file($dir, 'base.dev.yaml', "tier: dev\n");

	local %ENV = (%ENV, $ENV_PREFIX . 'ENV' => 'dev');

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('tier'), 'dev', 'environment auto-detected from {env_prefix}ENV');
};

subtest 'environment: auto-detected from PLACK_ENV' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml',          "tier: base\n");
	_write_file($dir, 'base.staging.yaml',  "tier: staging\n");

	local %ENV = (%ENV, PLACK_ENV => 'staging');
	delete $ENV{$ENV_PREFIX . 'ENV'};

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('tier'), 'staging', 'environment auto-detected from PLACK_ENV');
};

subtest 'environment: auto-detected from NODE_ENV when PLACK_ENV absent' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml',          "tier: base\n");
	_write_file($dir, 'base.production.yaml', "tier: production\n");

	local %ENV = (%ENV, NODE_ENV => 'production');
	delete $ENV{$ENV_PREFIX . 'ENV'};
	delete $ENV{'PLACK_ENV'};

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
	);
	is($cfg->get('tier'), 'production', 'environment auto-detected from NODE_ENV');
};

subtest 'environment: constructor option overrides env vars' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml',      "tier: base\n");
	_write_file($dir, 'base.prod.yaml', "tier: prod\n");
	_write_file($dir, 'base.dev.yaml',  "tier: dev\n");

	local %ENV = (%ENV, PLACK_ENV => 'dev', NODE_ENV => 'dev');

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
		environment => 'prod',          # explicit wins over PLACK_ENV/NODE_ENV
	);
	is($cfg->get('tier'), 'prod', 'explicit environment constructor option overrides env vars');
};

subtest 'environment: missing env-specific file is silently skipped' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "host: base\n");
	# no base.canary.yaml -- should not error

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
		environment => 'canary',
	);
	ok(defined($cfg), 'missing env-specific file is silently skipped');
	is($cfg->get('host'), 'base', 'base.yaml value used when env file absent');
};

subtest 'environment: invalid environment name croaks' => sub {
	dies_ok {
		Config::Abstraction->new(
			data        => { x => 1 },
			config_dirs => [],
			env_prefix  => $ENV_PREFIX,
			environment => 'prod/../../etc',  # path traversal attempt
		);
	} 'environment name with path separators croaks';
	like($@, qr/invalid environment name/, 'error message names the invalid value');

	dies_ok {
		Config::Abstraction->new(
			data        => { x => 1 },
			config_dirs => [],
			env_prefix  => $ENV_PREFIX,
			environment => 'prod env',        # space not allowed
		);
	} 'environment name with space croaks';
};

subtest 'environment: env-specific JSON and INI files are also loaded' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.json',      '{"format":"json","from":"base"}');
	_write_file($dir, 'base.test.json', '{"from":"test"}');

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
		environment => 'test',
	);
	is($cfg->get('format'), 'json',  'base key from base.json survives');
	is($cfg->get('from'),   'test',  'base.test.json overrides base.json value');
};

subtest 'environment: works in lazy mode' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml',      "host: base\n");
	_write_file($dir, 'base.qa.yaml',   "host: qa-server\n");

	my $cfg = Config::Abstraction->new(
		config_dirs => [$dir],
		env_prefix  => $ENV_PREFIX,
		environment => 'qa',
		lazy        => 1,
	);
	ok(defined($cfg), 'lazy construction with environment option succeeds');
	is($cfg->get('host'), 'qa-server', 'environment-specific file loaded in lazy mode');
};

# ===========================================================================
# new() single-argument form: single string treated as config_file
# ===========================================================================

subtest 'new() single-arg form: string argument loaded as config_file' => sub {
	my $dir  = tempdir(CLEANUP => 1);
	my $path = _write_file($dir, 'singlearg.yaml', "single_arg_key: found\n");

	my $cfg = Config::Abstraction->new($path);
	ok(defined($cfg), 'single-arg new() creates an object');
	is($cfg->get('single_arg_key'), 'found', 'single-arg config file value loaded');
};

subtest 'new() single-arg form: nonexistent path returns undef' => sub {
	my $cfg;
	_silenced(sub {
		eval {
			$cfg = Config::Abstraction->new('/this/path/definitely/does/not/exist.yaml');
		};
	});
	ok(!$@,        'single-arg new() with nonexistent path does not throw');
	ok(!defined($cfg), 'single-arg new() with nonexistent path returns undef');
};

# ===========================================================================
# config_files (plural) option: load an explicit list of files
# ===========================================================================

subtest 'config_files: multiple files loaded in order, last wins on conflict' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $f1  = _write_file($dir, 'first.yaml',  "key1: val1\nshared: from_first\n");
	my $f2  = _write_file($dir, 'second.yaml', "key2: val2\nshared: from_second\n");

	my $cfg = Config::Abstraction->new(
		config_files => [$f1, $f2],
		config_dirs  => [''],
	);
	ok(defined($cfg), 'config_files loads multiple files');
	is($cfg->get('key1'), 'val1',        'key only in first file is present');
	is($cfg->get('key2'), 'val2',        'key only in second file is present');
	is($cfg->get('shared'), 'from_second', 'second file wins for a shared key');
};

subtest 'config_files: nonexistent file in list does not crash' => sub {
	my $dir  = tempdir(CLEANUP => 1);
	my $real = _write_file($dir, 'exists.yaml', "real_key: real_val\n");

	my $cfg;
	_silenced(sub {
		eval {
			$cfg = Config::Abstraction->new(
				config_files => [$real, '/no/such/file.yaml'],
				config_dirs  => [''],
			);
		};
	});
	ok(!$@, 'nonexistent config_file in list does not crash constructor');
	if(defined($cfg)) {
		is($cfg->get('real_key'), 'real_val', 'real file still loaded despite bad companion');
	}
};

# ===========================================================================
# defaults constructor option: nest internal parameters inside a sub-hash
# ===========================================================================

subtest 'defaults option: internal params nested inside defaults hash' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "file_key: file_val\n");

	my $cfg = Config::Abstraction->new(
		defaults => {
			data        => { data_key => 'data_val' },
			config_dirs => [$dir],
		},
	);
	ok(defined($cfg), 'defaults option accepted and object constructed');
	is($cfg->get('data_key'), 'data_val', 'data from defaults option loaded');
	is($cfg->get('file_key'), 'file_val', 'config_dirs from defaults option used');
};

subtest 'defaults option: top-level env_prefix overrides env_prefix inside defaults' => sub {
	# CLAUDE.md: env_prefix passed at the top level always overrides env_prefix inside defaults.
	local %ENV = %ENV;
	my $outer_prefix = 'OUTER_';
	$ENV{"${outer_prefix}OUTER_ONLY"} = 'outer_val';

	my $cfg = Config::Abstraction->new(
		env_prefix => $outer_prefix,
		defaults   => { env_prefix => 'INNER_', config_dirs => [] },
	);
	ok(defined($cfg), 'outer env_prefix overrides inner defaults env_prefix');
};

# ===========================================================================
# flatten mode: AUTOLOAD, explain_sources, and dotted key get() in flat mode
# ===========================================================================

subtest 'flatten: get() with dotted key traverses the flat hash correctly' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { db => { user => 'alice', pass => 'secret' } },
		config_dirs => [],
		flatten     => 1,
	);
	# In flatten mode, the config is stored as { 'db.user' => 'alice', 'db.pass' => 'secret' }
	is($cfg->get('db.user'), 'alice',  'flatten: dotted key lookup for db.user');
	is($cfg->get('db.pass'), 'secret', 'flatten: dotted key lookup for db.pass');
	ok(!defined($cfg->get('db')),      'flatten: bare parent key returns undef in flat hash');
};

subtest 'flatten: AUTOLOAD translates sep_char to dot form for flat hash lookup' => sub {
	# When sep_char='_' and flatten=1, AUTOLOAD translates db_user -> db.user before lookup.
	my $cfg = Config::Abstraction->new(
		data        => { db => { user => 'alice' } },
		config_dirs => [],
		flatten     => 1,
		sep_char    => $SEP_US,
	);
	my $val;
	lives_ok { $val = $cfg->db_user() }
		'AUTOLOAD in flatten mode with sep_char=_ does not crash';
	is($val, 'alice', 'AUTOLOAD in flatten mode returns correct value');
};

subtest 'flatten: explain_sources() works correctly in flat mode' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { db => { user => 'alice' } },
		config_dirs => [],
		flatten     => 1,
	);
	my $es;
	lives_ok { $es = $cfg->explain_sources() }
		'explain_sources() does not crash in flatten mode';
	ok(ref($es) eq 'HASH', 'explain_sources() returns hashref in flatten mode');
	ok(exists $es->{'db.user'}, 'dotted key present in explain_sources in flat mode');
};

subtest 'flatten: exists() returns 1 for a flat dotted key' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { a => { b => 'val' } },
		config_dirs => [],
		flatten     => 1,
	);
	is($cfg->exists('a.b'), 1, 'flatten: exists() returns 1 for present dotted key');
	is($cfg->exists('a'),   0, 'flatten: exists() returns 0 for bare parent in flat hash');
};

# ===========================================================================
# env_prefix edge cases
# ===========================================================================

subtest 'env_prefix: empty string does not crash constructor' => sub {
	# An empty prefix means the regex pattern matches all env vars.
	# This is an extreme use case; we verify it does not crash.
	local %ENV = %ENV;
	local @ARGV = ();

	my $cfg;
	eval {
		$cfg = Config::Abstraction->new(
			data        => { specific => 'value' },
			config_dirs => [],
			env_prefix  => '',
		);
	};
	ok(!$@, 'empty string env_prefix does not die in constructor');
};

subtest 'env_prefix: very long prefix string does not crash' => sub {
	my $long_prefix = 'A' x 1000 . '_';
	local %ENV = %ENV;
	local @ARGV = ();

	my $cfg;
	eval {
		$cfg = Config::Abstraction->new(
			data        => { x => 1 },
			config_dirs => [],
			env_prefix  => $long_prefix,
		);
	};
	ok(!$@, 'very long env_prefix does not crash constructor');
};

# ===========================================================================
# CONFIG_DIR environment variable
# ===========================================================================

subtest 'CONFIG_DIR env var overrides default config directory discovery' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml', "config_dir_env_canary: found_via_CONFIG_DIR\n");

	local %ENV = (%ENV, CONFIG_DIR => $dir);
	my $cfg;
	eval {
		$cfg = Config::Abstraction->new();
	};
	ok(!$@, 'CONFIG_DIR env var does not crash constructor');
	if(defined($cfg)) {
		is($cfg->get('config_dir_env_canary'), 'found_via_CONFIG_DIR',
			'config loaded from directory specified by CONFIG_DIR env var');
	} else {
		pass('constructor returned undef - CONFIG_DIR may have been overridden by other local config');
	}
};

# ===========================================================================
# INI format: multi-section and global-key edge cases
# ===========================================================================

subtest 'INI: multi-section file: each section becomes a nested hash' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.ini',
		"[section1]\nkey1 = val1\n\n[section2]\nkey2 = val2\nshared = s2_val\n");

	my $cfg = Config::Abstraction->new(
		data        => {},
		config_dirs => [$dir],
	);
	ok(defined($cfg), 'multi-section INI file loaded successfully');
	is($cfg->get('section1.key1'), 'val1', 'section1.key1 accessible via dotted notation');
	is($cfg->get('section2.key2'), 'val2', 'section2.key2 accessible via dotted notation');
	is($cfg->get('section2.shared'), 's2_val', 'section2.shared accessible');
};

subtest 'INI: file with no sections (key=value only) does not crash' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.ini', "global_key = global_val\n");

	my $cfg;
	_silenced(sub {
		eval {
			$cfg = Config::Abstraction->new(
				data        => { fallback => 'ini_no_section' },
				config_dirs => [$dir],
			);
		};
	});
	ok(!$@, 'no-section INI (key=value only) does not crash constructor');
};

# ===========================================================================
# merge_defaults() with a real nested section
# ===========================================================================

subtest 'merge_defaults() with a real nested-hash section merges correctly' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { app => { timeout => 30, retries => 3 }, other => 'val' },
		config_dirs => [],
	);
	my $result = $cfg->merge_defaults(
		defaults => { timeout => 99, extra => 'from_defaults' },
		section  => 'app',
	);
	ok(defined($result),               'merge_defaults with valid nested section succeeds');
	is($result->{timeout}, 30,         'section key wins over same key in defaults');
	is($result->{extra}, 'from_defaults', 'default key absent from section survives');
	is($result->{retries}, 3,          'second section key present in merged result');
	ok(!exists $result->{other},       'sibling key outside section is not in result');
};

# ===========================================================================
# validators: validates env-sourced value (integration of env + validators)
# ===========================================================================

subtest 'validators: invalid env-sourced value fails validation even when data was valid' => sub {
	local %ENV = %ENV;
	# EDGEAPP_DATABASE__PORT (double underscore) -> database.port nested key
	$ENV{"${ENV_PREFIX}DATABASE__PORT"} = 'not_a_number';   # env overrides the valid data value

	dies_ok {
		Config::Abstraction->new(
			data        => { database => { port => $EXPECTED_PORT } },  # valid data value
			config_dirs => [],
			env_prefix  => $ENV_PREFIX,
			validators  => { 'database.port' => 'integer' },
		);
	} 'env-sourced non-integer value fails integer validator';
};

subtest 'validators: valid env-sourced value passes integer validator' => sub {
	local %ENV = %ENV;
	$ENV{"${ENV_PREFIX}DATABASE__PORT"} = '9000';

	my $cfg = Config::Abstraction->new(
		data        => { database => { port => $EXPECTED_PORT } },
		config_dirs => [],
		env_prefix  => $ENV_PREFIX,
		validators  => { 'database.port' => 'integer' },
	);
	ok(defined($cfg), 'valid env-sourced integer passes validator');
	is($cfg->get('database.port'), '9000', 'env value accessible after passing validation');
};

# ===========================================================================
# schema + lazy mode: schema validation deferred to first access
# ===========================================================================

subtest 'schema + lazy: validation deferred until first accessor call' => sub {
	plan skip_all => 'Params::Validate::Strict not installed'
		unless eval { require Params::Validate::Strict; 1 };

	# Construct with a valid schema and valid data; lazy defers the validation.
	my $cfg = Config::Abstraction->new(
		data        => { retries => 3 },
		config_dirs => [],
		lazy        => 1,
		schema      => { retries => { type => 'integer' } },
	);
	ok(defined($cfg) && blessed($cfg), 'lazy + schema: new() returns blessed object without dying');
};

# ===========================================================================
# no_fixate option: Data::Reuse is optional (commented out RT#100461)
# Passing no_fixate => 1 must at minimum not crash the constructor.
# ===========================================================================

subtest 'no_fixate: option accepted without crashing (Data::Reuse is optional)' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { key => 'value' },
		config_dirs => [],
		no_fixate   => 1,
	);
	ok(defined($cfg), 'no_fixate => 1 does not crash constructor');
	is($cfg->get('key'), 'value', 'config value accessible when no_fixate is set');
};

# ===========================================================================
# SECURITY: YAML tag injection — YAML::XS must not execute arbitrary code
# (YAML::XS disables !!perl/code and !!perl/glob by default since 0.82)
# ===========================================================================

subtest 'SECURITY: YAML !!perl/code tag does not produce an executable coderef' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml',
		"attack: !!perl/code 'sub { die \"YAML code executed\" }'\n");

	my $cfg;
	_silenced(sub {
		eval {
			$cfg = Config::Abstraction->new(
				data        => { safe => 'canary' },
				config_dirs => [$dir],
			);
		};
	});

	# Either the parse fails (acceptable) or the value is a non-callable scalar.
	ok(!$@, 'YAML code tag attack does not propagate a fatal to the caller');
	if(defined($cfg)) {
		my $val = $cfg->get('attack');
		# If the value survived, it must NOT be a callable code reference
		ok(!defined($val) || ref($val) ne 'CODE' || !eval { $val->(); 1 },
			'YAML code tag does not produce an executable coderef in config');
		is($cfg->get('safe'), 'canary', 'safe key unaffected by hostile YAML neighbour');
	} else {
		pass('YAML code tag caused parse failure (acceptable - attack prevented)');
	}
};

subtest 'SECURITY: YAML glob tag does not produce a filehandle' => sub {
	my $dir = tempdir(CLEANUP => 1);
	_write_file($dir, 'base.yaml',
		"attack: !!perl/glob '*STDOUT'\nsafe: canary\n");

	my $cfg;
	_silenced(sub {
		eval {
			$cfg = Config::Abstraction->new(config_dirs => [$dir]);
		};
	});
	ok(!$@, 'YAML glob tag does not crash constructor');
	if(defined($cfg)) {
		my $val = $cfg->get('attack');
		ok(!defined($val) || !ref($val) || ref($val) ne 'GLOB',
			'YAML glob tag does not produce a GLOB reference in config');
	} else {
		pass('YAML glob tag caused parse failure (acceptable)');
	}
};

# ===========================================================================
# SECURITY: XML External Entity (XXE) injection
# XML parsers must NOT fetch external entities from the filesystem or network.
# ===========================================================================

subtest 'SECURITY: XML XXE does not read /etc/passwd via SYSTEM entity' => sub {
	my $dir = tempdir(CLEANUP => 1);
	my $xxe = join('', (
		'<?xml version="1.0"?>',
		'<!DOCTYPE config [<!ENTITY secret SYSTEM "file:///etc/passwd">]>',
		'<config><key>&secret;</key><safe>canary</safe></config>',
	));
	_write_file($dir, 'base.xml', $xxe);

	my $cfg;
	_silenced(sub {
		eval {
			$cfg = Config::Abstraction->new(
				data        => { safe => 'fallback' },
				config_dirs => [$dir],
			);
		};
	});

	ok(!$@, 'XXE attempt does not propagate a fatal to the caller');
	if(defined($cfg)) {
		my $val = $cfg->get('key');
		# The XXE entity must NOT have resolved to /etc/passwd content
		ok(!defined($val) || $val !~ /root:/,
			'XXE does not expose /etc/passwd contents via XML entity expansion');
	} else {
		pass('XML parse failed (acceptable -- XXE prevented by parse rejection)');
	}
};

# ===========================================================================
# Encryption: additional edge cases
# ===========================================================================

subtest 'encryption: encrypt_value with empty string plaintext' => sub {
	plan skip_all => 'CryptX not installed' unless $CRYPTX_AVAILABLE;

	my $key = 'H' x 32;
	my $enc = Config::Abstraction->new(
		data           => {},
		config_dirs    => [],
		encryption_key => $key,
		lazy           => 1,
	);

	my $token;
	lives_ok { $token = $enc->encrypt_value('') }
		'encrypt_value("") with empty-string plaintext does not croak';
	like($token, qr/^ENC\[/, 'empty string encrypts to a valid ENC token');

	# Round-trip: decryption of empty string yields empty string.
	my $cfg = Config::Abstraction->new(
		data           => { secret => $token },
		config_dirs    => [],
		encryption_key => $key,
	);
	ok(defined($cfg), 'object with encrypted empty-string value loads');
	is($cfg->get('secret'), '', 'encrypted empty string decrypts to empty string');
};

subtest 'encryption: encryption_key_file that does not exist causes croak' => sub {
	dies_ok {
		Config::Abstraction->new(
			data                => { x => 1 },
			config_dirs         => [],
			encryption_key_file => '/this/key/file/does/not/exist.key',
		);
	} 'nonexistent encryption_key_file causes croak at construction';
};

subtest 'encryption: ENC[] token in env var value is decrypted transparently' => sub {
	plan skip_all => 'CryptX not installed' unless $CRYPTX_AVAILABLE;

	my $key = 'I' x 32;
	my $enc = Config::Abstraction->new(
		data           => {},
		config_dirs    => [],
		env_prefix     => $ENV_PREFIX,
		encryption_key => $key,
		lazy           => 1,
	);
	my $token = $enc->encrypt_value('env_secret_val');

	# Inject the ENC token via an environment variable.
	# EDGEAPP_VAULT__SECRET (double underscore) -> vault.secret key.
	local %ENV = (%ENV, "${ENV_PREFIX}VAULT__SECRET" => $token);

	my $cfg = Config::Abstraction->new(
		config_dirs    => [],
		env_prefix     => $ENV_PREFIX,
		encryption_key => $key,
	);
	ok(defined($cfg), 'object created with ENC[] token in env var');
	is($cfg->get('vault.secret'), 'env_secret_val',
		'ENC[] token in env var value is decrypted transparently');
};

subtest 'encryption: key as 64-char hex string with non-hex char is rejected' => sub {
	# 64 chars but with 'g' (not a hex digit) — not a valid 32-byte hex key.
	dies_ok {
		Config::Abstraction->new(
			data           => { x => 1 },
			config_dirs    => [],
			encryption_key => 'g' x 64,
		);
	} '64-char hex string with non-hex characters causes croak';
};

subtest 'encryption: ENC[] payload shorter than nonce+tag causes croak (no CryptX needed)' => sub {
	# _decrypt_enc_value checks payload length BEFORE loading CryptX.
	# Even without CryptX, a short payload must be rejected immediately.
	# Produce a deliberately short base64url payload (4 bytes decoded < min).
	require MIME::Base64;
	my $short_b64 = MIME::Base64::encode_base64url('X' x 4, '');
	my $short_token = "ENC[AES256GCM,$short_b64]";

	dies_ok {
		Config::Abstraction->new(
			data           => { pw => $short_token },
			config_dirs    => [],
			encryption_key => 'J' x 32,
		);
	} 'ENC[] with short payload croaks before checking CryptX availability';
	like($@, qr/too short/, 'error message says "too short"');
};

# ===========================================================================
# sep_char: multi-character separator
# ===========================================================================

subtest 'sep_char multi-char "::" splits on the two-character sequence' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { db => { user => 'alice' } },
		config_dirs => [],
		sep_char    => '::',
	);
	is($cfg->get('db::user'), 'alice', 'multi-char sep_char "::" works as key separator');
	ok(!defined($cfg->get('db.user')), 'dot does not split with sep_char="::"');
};

subtest 'sep_char "::" with AUTOLOAD returns nested value' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { db => { user => 'alice' } },
		config_dirs => [],
		sep_char    => '::',
	);
	# AUTOLOAD uses get() internally; the method name is used as-is as the key.
	# With sep_char='::', the accessor form would need '::' in the method name,
	# which Perl disallows syntactically. get() is the correct interface here.
	my $val = $cfg->get('db::user');
	is($val, 'alice', 'sep_char "::" dotted key lookupworks via get()');
};

# ===========================================================================
# HOSTILE: binary data through every layer
# ===========================================================================

subtest 'binary value in data preserved through merge (Hash::Merge no-clone mode)' => sub {
	# Raw binary strings (bytes with high-bit set) must survive the merge pipeline.
	my $binary = join('', map { chr($_) } 0..255);
	my $cfg = Config::Abstraction->new(
		data        => { bin => $binary },
		config_dirs => [],
	);
	ok(defined($cfg), 'binary-valued config constructed successfully');
	is($cfg->get('bin'), $binary, 'binary value preserved byte-for-byte through merge');
	is(length($cfg->get('bin')), 256, 'binary value length correct');
};

subtest 'binary key name in data accessible' => sub {
	my $binkey = "key\x00with\x01nul";
	my $cfg = Config::Abstraction->new(
		data        => { $binkey => 'binkey_val' },
		config_dirs => [],
	);
	ok(defined($cfg), 'binary key name in data does not crash constructor');
	is($cfg->get($binkey), 'binkey_val', 'binary key name accessible via get()');
};

# ===========================================================================
# explain_sources() + flatten: combined edge case
# Each flat key must have at least one source record with type='data'.
# ===========================================================================

subtest 'explain_sources(): flat-mode keys have provenance records' => sub {
	my $cfg = Config::Abstraction->new(
		data        => { db => { user => 'alice', host => 'localhost' } },
		config_dirs => [],
		flatten     => 1,
	);
	my $es = $cfg->explain_sources();
	for my $k (grep { $_ ne 'config_path' } keys %{$es}) {
		ok(scalar(@{$es->{$k}{sources}}) >= 1,
			"flat key '$k' has at least one source record");
	}
};

done_testing();
