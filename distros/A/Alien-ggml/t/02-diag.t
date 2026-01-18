#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Alien::Diag;

BEGIN { plan tests => 1 }

use Alien::ggml;

alien_diag 'Alien::ggml';

pass 'diagnostics printed';
