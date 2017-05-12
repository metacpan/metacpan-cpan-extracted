#!/usr/bin/perl

use 5.10.0;
use strict;
use warnings;
use Test::More tests => 2;
use Test::Script;

use_ok('ADAMK::Release');

script_compiles('script/adamk-release');
