#!/usr/bin/env perl
use strict;
use warnings;
use Crypt::Random::TESHA2;

use Test::More  tests => 1;

can_ok( 'Crypt::Random::TESHA2',
  qw( random_bytes random_values irand rand) );
