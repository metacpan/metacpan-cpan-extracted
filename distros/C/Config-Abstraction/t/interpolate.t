#!/usr/bin/env perl

# interpolate: ${key}, ${env:NAME}, ${...:-default} and $$ in string values.

use strict;
use warnings;

use File::Slurp qw(write_file);
use Test::Most;
use Test::TempDir::Tiny;

use_ok('Config::Abstraction');

sub cfg
{
	my ($data, %opts) = @_;
	return Config::Abstraction->new(config_dirs => [], data => $data, interpolate => 1, %opts);
}

subtest 'off by default' => sub {
	my $c = Config::Abstraction->new(config_dirs => [], data => { a => 1, b => '${a}' });
	is($c->get('b'), '${a}', 'left as written');
};

subtest 'key references, nested and chained' => sub {
	my $c = cfg({ db => { host => 'h', port => 5 }, dsn => 'x=${db.host}:${db.port}', again => '<${dsn}>', plain => 'no refs' });
	is($c->get('dsn'), 'x=h:5');
	is($c->get('again'), '<x=h:5>', 'chains');
	is($c->get('plain'), 'no refs');
	is($c->get('db.port'), 5, 'untouched values stay numeric-looking');
};

subtest 'environment variables' => sub {
	local $ENV{'CA_TEST_VAR'} = 'from env';
	local $ENV{'CA_TEST_MISSING'} = 'x';
	delete $ENV{'CA_TEST_MISSING'};
	my $c = cfg({ a => '${env:CA_TEST_VAR}!', b => '${env:CA_TEST_MISSING:-fallback}', c => '${ENV:CA_TEST_VAR}' });
	is($c->get('a'), 'from env!');
	is($c->get('b'), 'fallback');
	is($c->get('c'), 'from env', 'prefix is case-insensitive');
	throws_ok { cfg({ a => '${env:CA_TEST_MISSING}' }) } qr/\$\{CA_TEST_MISSING\}|env:CA_TEST_MISSING/, 'missing var croaks';
};

subtest 'text read through env: is not expanded again' => sub {
	local $ENV{'CA_TEST_NESTED'} = 'a${k}$$';
	my $c = cfg({ k => 'v', e => '${env:CA_TEST_NESTED}' });
	is($c->get('e'), 'a${k}$$', 'inserted as it is');
};

subtest 'defaults and escapes' => sub {
	my $c = cfg({ k => 'v', a => '${nope:-dflt}', b => '${k:-unused}', c => '$$5 and $$${k}', d => 'lone $ sign and $name', e => '${nope:-}' });
	is($c->get('a'), 'dflt');
	is($c->get('b'), 'v');
	is($c->get('c'), '$5 and $v');
	is($c->get('d'), 'lone $ sign and $name', 'bare $ and $name are not special');
	is($c->get('e'), '', 'empty default');
};

subtest 'errors' => sub {
	throws_ok { cfg({ a => '${missing}' }) } qr/\$\{missing\} in a is not defined/, 'undefined';
	throws_ok { cfg({ a => '${b}', b => '${a}' }) } qr/circular reference/, 'cycle';
	throws_ok { cfg({ a => '${a}' }) } qr/circular reference/, 'self reference';
	throws_ok { cfg({ h => { x => 1 }, a => '${h}' }) } qr/non-scalar/, 'hash reference';
	throws_ok { cfg({ a => '${ }' }) } qr/empty/, 'empty reference';
	throws_ok { cfg({ a => undef_ref(), b => '${a}' }) } qr/not defined/, 'undef value is not a value';
};

sub undef_ref { return undef }

subtest 'interpolate_strict => 0 leaves unresolved references' => sub {
	my $c = cfg({ a => '${nope} ${k}', k => 'v' }, interpolate_strict => 0);
	is($c->get('a'), '${nope} v');
};

subtest 'arrays, nested hashes, non-strings' => sub {
	my $code = sub { 1 };
	my $c = cfg({ k => 'v', list => [ '${k}', 'x', { deep => '${k}!' } ], h => { i => { j => '${k}' } }, n => 3, code => $code });
	is_deeply($c->get('list'), [ 'v', 'x', { deep => 'v!' } ], 'arrays');
	is($c->get('h.i.j'), 'v');
	is($c->get('n'), 3);
	is($c->get('code'), $code, 'code refs pass through');
};

subtest 'the data argument is not modified' => sub {
	my %data = (k => 'v', nested => { a => '${k}' });
	my $c = cfg(\%data);
	is($c->get('nested.a'), 'v');
	is($data{'nested'}{'a'}, '${k}', 'caller data untouched');
};

subtest 'values from files, env and argv are expanded after merging' => sub {
	my $dir = tempdir();
	write_file("$dir/base.yaml", "host: base\nurl: http://\${host}/\n");
	write_file("$dir/local.yaml", "host: local\n");
	my $c = Config::Abstraction->new(config_dirs => [$dir], interpolate => 1);
	is($c->get('url'), 'http://local/', 'sees the final value of host');

	local $ENV{'APP_HOST'} = 'x';	# APP.host - not top-level
	local $ENV{'APP_NAME__X'} = 'viaenv';
	$c = Config::Abstraction->new(config_dirs => [$dir], interpolate => 1, data => { y => '${name.x}' });
	is($c->get('y'), 'viaenv', 'env-sourced key');
};

subtest 'ENC tokens are left alone' => sub {
	my $c = cfg({ t => 'ENC[AES256GCM,abc${x}]' }, encryption_key => undef);
	is($c->get('t'), 'ENC[AES256GCM,abc${x}]');
};

subtest 'flatten, sep_char and lazy' => sub {
	my $c = cfg({ a => { b => 'v' }, c => '${a.b}' }, flatten => 1);
	is($c->get('c'), 'v', 'flatten');
	$c = cfg({ a => { b => 'v' }, c => '${a.b}' }, sep_char => '_');
	is($c->get('c'), 'v', 'references always use dots');
	$c = cfg({ a => { b => 'v' }, c => '${a.b}' }, lazy => 1);
	is($c->get('c'), 'v', 'lazy');
	$c = cfg({ a => '${nope}' }, lazy => 1);
	throws_ok { $c->get('a') } qr/not defined/, 'lazy errors surface on first access';
};

subtest 'a literal key containing a dot is found' => sub {
	my $c = cfg({ 'a.b' => 'lit', c => '${a.b}' });
	is($c->get('c'), 'lit');
};

done_testing();
