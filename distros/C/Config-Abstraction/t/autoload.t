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
		sep_char => '_'
	);

	is($cfg->database_user(), 'admin', 'AUTOLOAD: database_user (flattened)');
	is($cfg->database_pass(), 'secret', 'AUTOLOAD: database_pass (flattened)');
	is($cfg->api_key(), 'XYZ123', 'AUTOLOAD: api_key (flattened)');
};

done_testing();
