#!/usr/bin/perl 

use strict;
use warnings;
use Test::More qw(no_plan);
use Config::YAMLMacros;
use FindBin;

my $finished = 0;

END { ok($finished, 'finished') }

my $path_to_t = $FindBin::Bin;

my $config = get_config("$path_to_t/data/config2.yml", path_to_t => $path_to_t);

ok($config, 'got a config');
is($config->{PTT}, $path_to_t, 'path_to_t substitution');

is($config->{something_from_2a}, 3, 'include of 2a');
is($config->{something_from_2b}, 4, 'include of 2b');
is($config->{something_from_2c}, 5, 'include of 2c');
is($config->{something_from_2d}, 7, 'include of 2c');

is($config->{furry1}, 'ateddy too', 'substitution in abear');
is($config->{pond1}, 'noisy frog', 'substitution in noisy ribbit');
is($config->{PTT2}, $path_to_t, 'substitution PTT2');

is($config->{furry2}, 'bear', 'no sub bear');
is($config->{pond2}, 'ribbit', 'no sub ribbit');
is($config->{path2}, '%TOP%', 'no sub %TOP%');

is($config->{ephemeral}, 'this is what you see', 'override');

$finished = 1;

