#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

plan tests => 1;

require_ok ('App::Prun::Scaled');

diag ( "Testing App::Prun::Scaled $App::Prun::Scaled::VERSION, Perl $], $^X" );
