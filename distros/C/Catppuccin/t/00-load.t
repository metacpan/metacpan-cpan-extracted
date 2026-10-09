#!perl

use warnings;
use strict;

use Test::More tests => 1;

require_ok('Catppuccin');

local $Catppuccin::VERSION = $Catppuccin::VERSION || 'from repo';
note("Catppuccin $Catppuccin::VERSION, Perl $], $^X");
