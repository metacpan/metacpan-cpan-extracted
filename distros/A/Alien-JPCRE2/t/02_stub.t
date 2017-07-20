use strict;
use warnings;
our $VERSION = 0.001_000;

use Test2::V0;
use Test::Alien;
use Alien::JPCRE2;
use Data::Dumper;  # DEBUG

plan(1);

# load alien
alien_ok('Alien::JPCRE2', 'Alien::JPCRE2 loads successfully and conforms to Alien::Base specifications');

done_testing;
