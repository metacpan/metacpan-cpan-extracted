#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use File::Spec;
use File::Slurp qw(write_file);
use Test::TempDir::Tiny;

BEGIN { use_ok('Config::Abstraction') }

subtest 'return undef when there is no configuration data' => sub {
	ok(!defined(Config::Abstraction->new(data => { })));
};

my $test_dir = tempdir();

# base.yaml
write_file("$test_dir/base.yaml", <<'YAML');
---
database:
  user: base_user
  pass: base_pass
YAML

# local.json
write_file("$test_dir/local.json", <<'JSON');
{
  "database": {
    "pass": "local_pass"
  },
  "feature": {
    "enabled": true
  }
}
JSON

# base.xml
write_file("$test_dir/base.xml", <<'XML');
<?xml version="1.0"?>
<config>
  <api>
    <url>https://api.example.com</url>
    <timeout>30</timeout>
  </api>
</config>
XML

# local.xml
write_file("$test_dir/local.xml", <<'XML');
<?xml version="1.0"?>
<config>
  <api>
    <timeout>60</timeout>
  </api>
</config>
XML

# base.ini
write_file("$test_dir/base.ini", <<'INI');
[logging]
level=info
file=logfile.log
INI

# local.ini
write_file("$test_dir/local.ini", <<'INI');
[logging]
level=debug
INI

# Set ENV override
local %ENV;
$ENV{APP_DATABASE__USER} = 'env_user';
$ENV{APP_EXTRA__DEBUG} = '1';

# Load config
my $config = Config::Abstraction->new(
	config_dirs => [$test_dir],
	env_prefix => 'APP_',
	flatten => 0,
);

# YAML + JSON
is($config->get('database.user'), 'env_user', 'ENV override on database.user');
is $config->get('database.pass'), 'local_pass', 'local.json overrides base.yaml';
ok $config->get('feature.enabled'), 'feature.enabled from JSON';
is $config->get('extra.debug'), '1', 'extra.debug from ENV';
is($config->all()->{'database'}{'user'}, 'env_user', 'all() works, when not flattened');

# XML merge
is($config->get('api.url'), 'https://api.example.com', 'API URL from base.xml');
is($config->get('api.timeout'), '60', 'local.xml overrides base.xml');

# Check INI merging
is $config->get('logging.level'), 'debug', 'local.ini overrides base.ini';
is $config->get('logging.file'), 'logfile.log', 'base.ini sets logging.file';

# Check ENV merging
is $config->get('extra.debug'), '1', 'extra.debug from ENV';

# Undefined value
is($config->get('extra.foo'), undef, 'Undefined keys return undef');

$ENV{App_FOO} = 'bar';
$config = Config::Abstraction->new(
	config_dirs => [$test_dir],
	env_prefix => 'App_',
	flatten => 0,
);

is($config->get('App.foo'), 'bar', 'Lower case environment');

# Flattened test
my $flat = Config::Abstraction->new(
	config_dirs => [$test_dir],
	env_prefix => 'APP_',
	flatten => 1,
);

is $flat->get('api.timeout'), '60', 'Flattened: XML override timeout';
is($flat->get('database.user'), 'env_user', 'Flattened: ENV override still works');
is($flat->all()->{'database.user'}, 'env_user', 'all() works, when flattened');

# Test config_file
write_file("$test_dir/foo", <<'YAML');
first:
  second: value
YAML

$config = Config::Abstraction->new(
	config_dirs => [$test_dir],
	config_file => 'foo'
);

diag(Data::Dumper->new([$config])->Dump()) if($ENV{'TEST_VERBOSE'});

cmp_ok($config->get('first.second'), 'eq', 'value', 'Action similar to Config::Auto works');

done_testing();
