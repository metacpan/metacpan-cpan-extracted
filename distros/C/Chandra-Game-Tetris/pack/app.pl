#!/usr/bin/env perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../../lib";

use Chandra::Game::Tetris;

Chandra::Game::Tetris->new->run;
