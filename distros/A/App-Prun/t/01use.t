#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

plan tests => 1;

require_ok ('App::Prun');

diag ( "Testing App::Prun $App::Prun::VERSION, Perl $], $^X" );
