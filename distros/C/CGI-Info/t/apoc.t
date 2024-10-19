#!perl -w

use strict;
use warnings;

use Test::Needs 'Test::Apocalypse';

Test::Apocalypse->import();
is_apocalypse_here();
