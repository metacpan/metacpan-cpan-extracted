#!/usr/bin/env perl
use warnings;
use strict;
use lib 't/lib';
use Brickyard;
use Test::Most;
my $brickyard = Brickyard->new(base_package => 'BrickyardTest::StringMunger');
my $root_config = RootConfig->new;

my $config = <<EOINI;
key1.subkey1 = foo
key1.subkey2 = bar
key2 = baz

[\@Default]
EOINI

$brickyard->init_from_config(\$config, $root_config);
is_deeply $root_config,
  bless(
    {   key2 => 'baz',
        key1 => {
            subkey2 => 'bar',
            subkey1 => 'foo'
        }
    },
    'RootConfig'
  ),
  'root section from inline config';
done_testing();

package RootConfig;
use Brickyard::Accessor new => 1, rw => [qw(key1 key2)];
