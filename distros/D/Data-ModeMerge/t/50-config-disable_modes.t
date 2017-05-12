#!perl

use strict;
use warnings;
use Test::More tests => 9;
use Test::Exception;

use lib './t';
do 'testlib.pm';

use Data::ModeMerge;

my $h1 = { 'a'=> 1,  'c'=> 2,  'd'=> 3,  'k'=> 4,  'n'=> 5, 'n2'=> 5,  's'=> 6};
my $h2 = {'+a'=>10, '.c'=>20, '!d'=>30, '^k'=>40, '*n'=>50, 'n2'=>50, '-s'=>60};

dies_ok(sub {mode_merge($h1, $h2, {disable_modes=>'ADD'})},  "invalid disable_mode");

mmerge_is($h1, $h2, undef                              , {a=>11, c=>220, "^k"=>40, n=>50, n2=>50, s=>-54}                 , "no disable_modes");
mmerge_is($h1, $h2, {disable_modes=>[qw/ADD/]}         , {a=>1, '+a'=>10, c=>220, "^k"=>40, n=>50, n2=>50, s=>-54}        , "disable_modes ADD");
mmerge_is($h1, $h2, {disable_modes=>[qw/CONCAT/]}      , {a=>11, c=>2, '.c'=>20, "^k"=>40, n=>50, n2=>50, s=>-54}         , "disable_modes CONCAT");
mmerge_is($h1, $h2, {disable_modes=>[qw/DELETE/]}      , {a=>11, c=>220, d=>3, '!d'=>30, "^k"=>40, n=>50, n2=>50, s=>-54} , "disable_modes DELETE");
mmerge_is($h1, $h2, {disable_modes=>[qw/KEEP/]}        , {a=>11, c=>220, k=>4, "^k"=>40, n=>50, n2=>50, s=>-54}           , "disable_modes KEEP");
mmerge_is($h1, $h2, {disable_modes=>[qw/NORMAL/]}      , {a=>11, c=>220, "^k"=>40, n=>5, '*n'=>50, n2=>50, s=>-54}        , "disable_modes NORMAL");
mmerge_is($h1, $h2, {disable_modes=>[qw/SUBTRACT/]}    , {a=>11, c=>220, "^k"=>40, n=>50, n2=>50, s=>6, '-s'=>60}         , "disable_modes SUBTRACT");
mmerge_is($h1, $h2, {disable_modes=>[qw/ADD CONCAT/]}  , {a=>1, '+a'=>10, c=>2, '.c'=>20, "^k"=>40, n=>50, n2=>50, s=>-54}, "disable_modes ADD+CONCAT");
