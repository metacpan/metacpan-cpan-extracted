use strict;
use warnings;
our $VERSION = 0.001_000;

use Test2::V0;
use Test::Alien;
use Test::Alien::Diag;
use Alien::PCRE2;

alien_diag 'Alien::PCRE2';
alien_ok 'Alien::PCRE2';

done_testing;
