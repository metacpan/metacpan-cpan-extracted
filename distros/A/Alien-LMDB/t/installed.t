use strict;
use warnings;
 
use Test::More tests => 3;
use Alien::LMDB;
 
use Text::ParseWords qw/shellwords/;
 
my @libs = shellwords( Alien::LMDB->libs );
 
ok(grep { /^-llmdb$/ } @libs, 'found -llmdb in libs');

ok(exists($Alien::LMDB::AlienLoaded{-llmdb}), 'AlienLoaded hash populated with -llmdb');
ok(-e $Alien::LMDB::AlienLoaded{-llmdb}, 'AlienLoaded hash of -llmdb points to existant file');
