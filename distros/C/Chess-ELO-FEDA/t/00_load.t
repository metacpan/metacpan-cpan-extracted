#!perl
 
use strict;
use warnings;
 
use Test::More 0.88 tests => 1;
 
require_ok('Chess::ELO::FEDA');
 
local $Chess::ELO::FEDA::VERSION = $Chess::ELO::FEDA::VERSION || 'from repo';
note("Chess::ELO::FEDA $Chess::ELO::FEDA::VERSION, Perl $], $^X");
