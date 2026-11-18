#!/usr/bin/env perl

# allow_includes: a top-level 'include' key pulls other files in beneath the
# including file.  Includes are confined, cycles are rejected.

use strict;
use warnings;

use File::Path qw(make_path);
use File::Slurp qw(write_file);
use File::Spec;
use Test::Most;
use Test::TempDir::Tiny;

use_ok('Config::Abstraction');

subtest 'off by default: include is an ordinary key' => sub {
	my $dir = tempdir();
	write_file("$dir/base.yaml", "include: other.yaml\nname: top\n");
	write_file("$dir/other.yaml", "extra: 1\n");
	my $c = Config::Abstraction->new(config_dirs => [$dir]);
	is($c->get('include'), 'other.yaml', 'include key left alone');
	ok(!$c->exists('extra'), 'nothing included');
};

subtest 'basic include, file wins over its include' => sub {
	my $dir = tempdir();
	write_file("$dir/base.yaml", "include: other.yaml\nname: top\ndb: { port: 1 }\n");
	write_file("$dir/other.yaml", "name: included\nextra: yes\ndb: { host: h, port: 2 }\n");
	my $c = Config::Abstraction->new(config_dirs => [$dir], allow_includes => 1);
	is($c->get('name'), 'top', 'including file wins');
	is($c->get('extra'), 'yes', 'included key present');
	is($c->get('db.host'), 'h', 'nested keys merge');
	is($c->get('db.port'), 1, 'nested including file wins');
	ok(!$c->exists('include'), 'include key removed');
	is_deeply([ map { File::Spec->abs2rel($_, $dir) } grep { !ref } @{$c->all->{'config_path'}} ],
		[ 'base.yaml', 'other.yaml' ], 'config_path lists both files');
};

subtest 'mixed formats, list order and sorted globs' => sub {
	my $dir = tempdir();
	make_path("$dir/conf.d");
	write_file("$dir/base.json", '{"include":["first.yaml","conf.d/*.json"],"own":"o"}');
	write_file("$dir/first.yaml", "k: first\nonly_first: 1\n");
	write_file("$dir/conf.d/10-a.json", '{"k":"a","a":1}');
	write_file("$dir/conf.d/20-b.json", '{"k":"b","b":1}');
	my $c = Config::Abstraction->new(config_dirs => [$dir], allow_includes => 1);
	is($c->get('k'), 'b', 'later include (and later glob match) wins');
	is($c->get('only_first'), 1);
	is($c->get('a'), 1);
	is($c->get('own'), 'o');
};

subtest 'relative to the including file, and nested' => sub {
	my $dir = tempdir();
	make_path("$dir/sub");
	write_file("$dir/base.yaml", "include: sub/one.yaml\n");
	write_file("$dir/sub/one.yaml", "include: two.yaml\nfrom_one: 1\n");
	write_file("$dir/sub/two.yaml", "from_two: 2\n");
	my $c = Config::Abstraction->new(config_dirs => [$dir], allow_includes => 1);
	is($c->get('from_one'), 1);
	is($c->get('from_two'), 2, 'nested include resolved against sub/');
};

subtest 'custom include_key and a TOML / INI / conf include' => sub {
	my $dir = tempdir();
	write_file("$dir/base.yaml", "'\@include': [a.toml, b.ini]\n");
	write_file("$dir/a.toml", "t = 1\n");
	write_file("$dir/b.ini", "[s]\ni = 2\n");
	my $c = Config::Abstraction->new(config_dirs => [$dir], allow_includes => 1, include_key => '@include');
	is($c->get('t'), 1, 'TOML');
	is($c->get('s.i'), 2, 'INI');
};

subtest 'include from a config_file' => sub {
	my $dir = tempdir();
	write_file("$dir/app.yaml", "include: more.yaml\nx: 1\n");
	write_file("$dir/more.yaml", "y: 2\n");
	my $c = Config::Abstraction->new(config_dirs => [], config_file => "$dir/app.yaml", allow_includes => 1);
	SKIP: {
		skip 'config_dirs => [] does not read config_file', 2 unless $c;
		is($c->get('x'), 1);
		is($c->get('y'), 2);
	}
	$c = Config::Abstraction->new(config_file => "$dir/app.yaml", allow_includes => 1);
	is($c->get('x'), 1, 'config_file');
	is($c->get('y'), 2, 'its include');
};

subtest 'explain_sources attributes included keys to the included file' => sub {
	my $dir = tempdir();
	write_file("$dir/base.yaml", "include: other.yaml\nname: top\n");
	write_file("$dir/other.yaml", "name: low\nextra: 1\n");
	my $c = Config::Abstraction->new(config_dirs => [$dir], allow_includes => 1);
	my $src = $c->explain_sources();
	is_deeply([ map { File::Spec->abs2rel($_->{'label'}, $dir) } @{$src->{'name'}{'sources'}} ],
		[ 'other.yaml', 'base.yaml' ], 'lowest precedence first');
	is_deeply([ map { File::Spec->abs2rel($_->{'label'}, $dir) } @{$src->{'extra'}{'sources'}} ], [ 'other.yaml' ]);
};

subtest 'confinement' => sub {
	my $root = tempdir();
	make_path("$root/conf", "$root/shared");
	write_file("$root/shared/secret.yaml", "leak: 1\n");
	write_file("$root/conf/base.yaml", "include: ../shared/secret.yaml\n");
	throws_ok { Config::Abstraction->new(config_dirs => ["$root/conf"], allow_includes => 1) }
		qr/outside the permitted directories/, 'relative escape croaks';

	write_file("$root/conf/base.yaml", "include: $root/shared/secret.yaml\n");
	throws_ok { Config::Abstraction->new(config_dirs => ["$root/conf"], allow_includes => 1) }
		qr/outside the permitted directories/, 'absolute path outside croaks';

	my $c = Config::Abstraction->new(config_dirs => ["$root/conf"], allow_includes => 1, include_dirs => ["$root/shared"]);
	is($c->get('leak'), 1, 'include_dirs widens the allowance');

	SKIP: {
		skip 'symlinks unavailable', 1 unless eval { symlink('', ''); 1 } && $^O ne 'MSWin32';
		write_file("$root/conf/base.yaml", "include: link.yaml\n");
		symlink("$root/shared/secret.yaml", "$root/conf/link.yaml");
		throws_ok { Config::Abstraction->new(config_dirs => ["$root/conf"], allow_includes => 1) }
			qr/outside the permitted directories/, 'a symlink out is resolved before the check';
	}
};

subtest 'circular and too-deep includes croak' => sub {
	my $dir = tempdir();
	write_file("$dir/base.yaml", "include: a.yaml\n");
	write_file("$dir/a.yaml", "include: b.yaml\n");
	write_file("$dir/b.yaml", "include: a.yaml\n");
	throws_ok { Config::Abstraction->new(config_dirs => [$dir], allow_includes => 1) }
		qr/circular include/, 'cycle';

	write_file("$dir/base.yaml", "include: a.yaml\n");
	write_file("$dir/a.yaml", "include: b.yaml\n");
	write_file("$dir/b.yaml", "include: c.yaml\n");
	write_file("$dir/c.yaml", "k: 1\n");
	throws_ok { Config::Abstraction->new(config_dirs => [$dir], allow_includes => 1, include_max_depth => 2) }
		qr/nested more than 2 deep/, 'depth limit';
	lives_ok { Config::Abstraction->new(config_dirs => [$dir], allow_includes => 1) } 'default depth is ample';

	write_file("$dir/base.yaml", "include: base.yaml\nk: 1\n");
	throws_ok { Config::Abstraction->new(config_dirs => [$dir], allow_includes => 1) }
		qr/circular include/, 'self include';
};

subtest 'missing or bad includes are skipped with a warning' => sub {
	my $dir = tempdir();
	write_file("$dir/base.yaml", "include: [nope.yaml, [nested], bad.json]\nk: 1\n");
	write_file("$dir/bad.json", '[1,2]');
	my @w;
	my $c;
	{
		local $SIG{__WARN__} = sub { push @w, @_ };
		$c = Config::Abstraction->new(config_dirs => [$dir], allow_includes => 1);
	}
	is($c->get('k'), 1, 'the rest still loads');
	like(join('', @w), qr/nope\.yaml.*not found/, 'missing warned');
	like(join('', @w), qr/invalid 'include' entry/, 'non-string warned');
	like(join('', @w), qr/did not contain a configuration hash/, 'non-hash warned');

	write_file("$dir/base.yaml", "include: 'conf.d/*.yaml'\nk: 1\n");
	@w = ();
	{
		local $SIG{__WARN__} = sub { push @w, @_ };
		$c = Config::Abstraction->new(config_dirs => [$dir], allow_includes => 1);
	}
	is_deeply(\@w, [], 'a glob matching nothing is silent');
};

subtest 'an included program is not read' => sub {
	my $dir = tempdir();
	write_file("$dir/base.yaml", "include: prog.pl\nk: 1\n");
	write_file("$dir/prog.pl", "#!/usr/bin/perl\nk: 2\n");
	my @w;
	my $c;
	{
		local $SIG{__WARN__} = sub { push @w, @_ };
		$c = Config::Abstraction->new(config_dirs => [$dir], allow_includes => 1);
	}
	is($c->get('k'), 1);
};

subtest 'unknown extension is detected by content' => sub {
	my $dir = tempdir();
	write_file("$dir/base.yaml", "include: [a.rc, b.rc]\n");
	write_file("$dir/a.rc", '{"from_json": 1}');
	write_file("$dir/b.rc", "from_yaml: 2\n");
	my $c = Config::Abstraction->new(config_dirs => [$dir], allow_includes => 1);
	is($c->get('from_json'), 1);
	is($c->get('from_yaml'), 2);
};

subtest 'flatten mode and lazy mode' => sub {
	my $dir = tempdir();
	write_file("$dir/base.yaml", "include: o.yaml\n");
	write_file("$dir/o.yaml", "a: { b: 3 }\n");
	my $c = Config::Abstraction->new(config_dirs => [$dir], allow_includes => 1, flatten => 1);
	is($c->get('a.b'), 3, 'flatten');
	$c = Config::Abstraction->new(config_dirs => [$dir], allow_includes => 1, lazy => 1);
	is($c->get('a.b'), 3, 'lazy');
};

done_testing();
