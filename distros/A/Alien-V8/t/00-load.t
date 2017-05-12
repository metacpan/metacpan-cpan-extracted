#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;

use_ok('Alien::V8');
diag("Testing Alien::V8 $Alien::V8::VERSION under Perl $]");
