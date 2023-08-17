#!/usr/bin/env perl

use strict;
use warnings;

use Alien::libpopt;
use Test::Alien;
use Test::Alien::Diag;
use Test::More;

alien_diag 'Alien::libpopt';
alien_ok 'Alien::libpopt';

done_testing;
