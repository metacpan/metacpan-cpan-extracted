#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use File::Spec;
use File::Slurp qw(write_file);
use Test::TempDir::Tiny;

BEGIN { use_ok('Config::Abstraction') }

local @ARGV = ('--APP_foo=baz');
my $test_dir = tempdir();

write_file("$test_dir/base.yaml", <<'YAML');
---
foo: bar
YAML

my $config = Config::Abstraction->new(
	config_dirs => [$test_dir],
	env_prefix => 'APP_',
	flatten => 0,
);

ok(defined($config));

unlink("$test_dir/base.yaml");

ok($config->foo() eq 'baz');

done_testing();
