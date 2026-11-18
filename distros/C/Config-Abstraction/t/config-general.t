#!/usr/bin/env perl

# Apache-style configuration through the optional Config::General.

use strict;
use warnings;

use File::Slurp qw(write_file);
use Test::Most;
use Test::Needs 'Config::General';
use Test::TempDir::Tiny;

use_ok('Config::Abstraction');

my $APACHE = <<'EOT';
name = myapp
log debug
log trace
# a comment
<database>
	host = db.example.com
	port = 5432
</database>
<host www.example.com>
	root /var/www
</host>
EOT

subtest 'base.conf and local.conf are layered like the other formats' => sub {
	my $dir = tempdir();
	write_file("$dir/base.conf", $APACHE);
	write_file("$dir/local.conf", "name = override\n<database>\n\tport = 1\n</database>\n");
	my $c = Config::Abstraction->new(config_dirs => [$dir]);
	is($c->get('name'), 'override', 'local wins');
	is($c->get('database.host'), 'db.example.com', 'blocks nest and merge');
	is($c->get('database.port'), 1);
	is_deeply($c->get('log'), [ 'debug', 'trace' ], 'repeated keys become an array');
	is($c->get('host.www.example.com.root'), undef, 'dots in a named block are not special to get()');
	is($c->all->{'host'}{'www.example.com'}{'root'}, '/var/www', 'named block');
};

subtest 'environment-specific .conf' => sub {
	my $dir = tempdir();
	write_file("$dir/base.conf", "k = base\n");
	write_file("$dir/base.prod.conf", "k = prod\n");
	my $c = Config::Abstraction->new(config_dirs => [$dir], environment => 'prod');
	is($c->get('k'), 'prod');
};

subtest 'extensionless config_file falls through to Config::General' => sub {
	my $dir = tempdir();
	# Not YAML/JSON/TOML/INI/XML: only Apache-style blocks
	write_file("$dir/app", "<server>\n\tport 80\n</server>\nflag on\n");
	my $c = Config::Abstraction->new(config_dirs => [''], config_file => "$dir/app");
	ok($c, "loaded");
	is($c->get("server.port"), 80, "block parsed by Config::General");
	is($c->get("flag"), "on");
};

subtest 'Config::General <<include>> is refused' => sub {
	my $dir = tempdir();
	write_file("$dir/secret.txt", "leak = 1\n");
	write_file("$dir/base.conf", "k = 1\n<<include $dir/secret.txt>>\n");
	my @w;
	my $c;
	{
		local $SIG{__WARN__} = sub { push @w, @_ };
		$c = Config::Abstraction->new(config_dirs => [$dir]);
	}
	ok(!$c || !$c->exists('leak'), 'nothing was included');
	like(join('', @w), qr/<<include>> directives are not permitted/, 'warned');
};

subtest 'the include key works in a .conf file' => sub {
	my $dir = tempdir();
	write_file("$dir/base.conf", "include = more.yaml\nk = 1\n");
	write_file("$dir/more.yaml", "m: 2\n");
	my $c = Config::Abstraction->new(config_dirs => [$dir], allow_includes => 1);
	is($c->get('k'), 1);
	is($c->get('m'), 2);
};

subtest 'interpolation is ours, not Config::General\'s' => sub {
	my $dir = tempdir();
	write_file("$dir/base.conf", "a = 1\nb = \${a}x\nc = \$a\n");
	my $c = Config::Abstraction->new(config_dirs => [$dir]);
	is($c->get('b'), '${a}x', 'not interpolated by default');
	is($c->get('c'), '$a');
	$c = Config::Abstraction->new(config_dirs => [$dir], interpolate => 1);
	is($c->get('b'), '1x', 'interpolated by Config::Abstraction when asked');
};

subtest 'an empty or unparseable .conf contributes nothing' => sub {
	my $dir = tempdir();
	write_file("$dir/base.conf", "# only a comment\n");
	write_file("$dir/local.yaml", "k: 1\n");
	my $c = Config::Abstraction->new(config_dirs => [$dir]);
	is($c->get('k'), 1);
	is(scalar(grep { /base\.conf$/ } @{$c->all->{'config_path'}}), 0, 'not in config_path');
};

subtest 'a .conf file is skipped when Config::General is absent' => sub {
	local %INC = %INC;
	delete $INC{'Config/General.pm'};
	require Test::Without::Module;
	Test::Without::Module->import('Config::General');
	my $dir = tempdir();
	write_file("$dir/base.conf", "k = 1\n");
	write_file("$dir/local.yaml", "other: 2\n");
	my $c = Config::Abstraction->new(config_dirs => [$dir]);
	is($c->get('other'), 2, 'rest of config loads');
	ok(!$c->exists('k'), '.conf skipped');
	Test::Without::Module->unimport('Config::General');
};

done_testing();
