#!/usr/bin/perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

BEGIN { use_ok('Dancer2::Plugin::Res') || print "Bail out!\n"; }

diag("Testing Dancer2::Plugin::Res $Dancer2::Plugin::Res::VERSION, Perl $], $^X");
