#!/usr/bin/perl

use 5.018;
use strict;
use warnings;
use Test::More;

plan tests => 1;

use_ok('App::PTP');

diag("Testing App::Ptp $App::PTP::VERSION, Perl $], $^X, $ENV{SHELL}");
