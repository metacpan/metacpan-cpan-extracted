use strict;
use Test::More 0.98;

# Skip this test in environments where alien hasn't been built yet
plan skip_all => "Skipping in environments without built alien" 
    unless $ENV{ALIEN_TURSO_CLI_TEST} || -d 'blib';

use_ok $_ for qw(
    Alien::Turso::CLI
);

done_testing;

