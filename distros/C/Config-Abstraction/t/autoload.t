#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;

BEGIN { use_ok('Config::Abstraction') }

my $data = {
	database => {
		user => 'admin',
		pass => 'secret',
	},
	api => {
		key => 'XYZ123',
	},
};

subtest 'AUTOLOAD with flattening OFF' => sub {
	my $cfg = Config::Abstraction->new(
		data => $data,
		flatten => 0,
		sep_char => '_'
	);

	is($cfg->database_user(), 'admin', 'AUTOLOAD: database_user');
	is($cfg->database_pass(), 'secret', 'AUTOLOAD: database_pass');
	is($cfg->api_key(), 'XYZ123', 'AUTOLOAD: api_key');

	throws_ok { $cfg->nonexistent_key } qr/No such config key/, 'AUTOLOAD throws for unknown key';
};

subtest 'AUTOLOAD with flattening ON' => sub {
	my $cfg = Config::Abstraction->new(
		data => $data,
		flatten => 1,
		sep_char => '_',
		config_dirs => [],
	);

	is($cfg->database_user(), 'admin', 'AUTOLOAD: database_user (flattened)');
	is($cfg->database_pass(), 'secret', 'AUTOLOAD: database_pass (flattened)');
	is($cfg->api_key(), 'XYZ123', 'AUTOLOAD: api_key (flattened)');
};

# Regression: AUTOLOAD must see file-layer overrides, not the raw data defaults.
# Before the fix, $self->{data} was used here, which bypassed all file and env merging.
subtest 'AUTOLOAD sees file overrides, not raw data defaults' => sub {
	plan skip_all => 'Requires filesystem' if $^O eq 'MSWin32';

	require File::Temp;
	my $dir = File::Temp::tempdir(CLEANUP => 1);

	open my $fh, '>', "$dir/base.yaml" or die "Cannot write base.yaml: $!";
	print $fh "database:\n  host: file_host\n";
	close $fh;

	my $cfg = Config::Abstraction->new(
		data        => { database => { host => 'data_host' } },
		config_dirs => [$dir],
		sep_char    => '_',
	);

	# The file must override the in-memory data default.
	# With sep_char='_', get() uses underscore notation too.
	is($cfg->database_host(), 'file_host', 'AUTOLOAD returns file-layer value, not data default');
	is($cfg->get('database_host'), 'file_host', 'get() also returns file-layer value');
};

done_testing();
