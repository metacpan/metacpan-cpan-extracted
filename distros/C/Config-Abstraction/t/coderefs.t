#!/usr/bin/perl

# Test that Config::Abstraction does not corrupt coderefs or blessed objects
# passed in via the 'data' argument.

use strict;
use warnings;
use Test::More;
use Scalar::Util qw(blessed reftype);

use_ok('Config::Abstraction') or BAIL_OUT('Config::Abstraction failed to load');

# ----------------------------------------------------------------
# 1. Coderef in data survives round-trip
# ----------------------------------------------------------------
{
	my $called = 0;
	my $cb = sub { $called++ };

	my $cfg = Config::Abstraction->new(
		data        => { callback => $cb, name => 'test' },
		config_dirs => [],
	);
	ok(defined($cfg), 'object created with coderef in data');

	my $got = $cfg->get('callback');
	ok(defined($got),                      'coderef key is retrievable');
	is(reftype($got), 'CODE',              'retrieved value is still a CODE ref');
	is(ref($got),     ref($cb),            'ref type unchanged');
	$got->();
	is($called, 1,                         'coderef is callable and executes correctly');
}

# ----------------------------------------------------------------
# 2. Blessed object in data survives round-trip
# ----------------------------------------------------------------
{
	package My::Config::Test::Obj;
	sub new  { bless { value => $_[1] }, $_[0] }
	sub value { $_[0]->{value} }
}
{
	my $obj = My::Config::Test::Obj->new(42);

	my $cfg = Config::Abstraction->new(
		data        => { handler => $obj, mode => 'live' },
		config_dirs => [],
	);
	ok(defined($cfg), 'object created with blessed object in data');

	my $got = $cfg->get('handler');
	ok(defined($got),                        'blessed object key is retrievable');
	ok(blessed($got),                        'retrieved value is still blessed');
	is(blessed($got), 'My::Config::Test::Obj', 'blessed class is unchanged');
	is($got->value(), 42,                    'blessed object is functional');
}

# ----------------------------------------------------------------
# 3. Coderef alongside a comma-containing string (triggers the
#    YAML colon-file munging path indirectly)
# ----------------------------------------------------------------
{
	my $cb = sub { 'result' };

	my $cfg = Config::Abstraction->new(
		data => {
			callback => $cb,
			tags     => 'alpha,beta,gamma',	# this value hits the comma-split path
			plain    => 'simple',
		},
		config_dirs => [],
	);
	ok(defined($cfg), 'object created with mixed data');

	my $got_cb = $cfg->get('callback');
	is(reftype($got_cb), 'CODE', 'coderef intact when comma string also present');
	is($got_cb->(), 'result',    'coderef executes correctly');

	# The plain string should be untouched
	is($cfg->get('plain'), 'simple', 'plain string value unaffected');
}

# ----------------------------------------------------------------
# 4. Arrayref and hashref in data are not treated as file paths
# ----------------------------------------------------------------
{
	my $cfg = Config::Abstraction->new(
		data => {
			hosts   => [ 'host1', 'host2' ],
			db      => { user => 'alice', pass => 'secret' },
			timeout => 30,
		},
		config_dirs => [],
	);
	ok(defined($cfg), 'object created with nested refs in data');

	my $hosts = $cfg->get('hosts');
	is(reftype($hosts), 'ARRAY',           'arrayref preserved');
	is(scalar(@{$hosts}), 2,               'arrayref contents intact');
	is($hosts->[0], 'host1',               'arrayref element correct');

	my $db = $cfg->get('db');
	is(reftype($db), 'HASH',               'hashref preserved');
	is($db->{'user'}, 'alice',             'hashref contents intact');
}

done_testing();
