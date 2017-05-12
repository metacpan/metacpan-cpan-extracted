#!/usr/bin/env perl
use warnings;
use strict;
use lib 't/lib';
use Brickyard;
use Test::Most;
my $brickyard = Brickyard->new(base_package => 'BrickyardTest::StringMunger');
my $root_config = RootConfig->new;
$brickyard->init_from_config('t/config/config1.ini:t/config/config2.ini',
    $root_config);
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
  'merged root section';
done_testing();

package RootConfig;
use Brickyard::Accessor new => 1, rw => [qw(key1 key2)];
