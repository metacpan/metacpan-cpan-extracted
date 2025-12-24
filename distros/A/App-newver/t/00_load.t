#!/usr/bin/perl
use 5.016;
use strict;
use warnings;

use Test::More;

use_ok("App::newver");

diag("Testing App::newver $App::newver::VERSION, perl $], $^X");

done_testing;
