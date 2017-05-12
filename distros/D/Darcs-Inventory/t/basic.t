#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

plan tests => 2;

use_ok('Darcs::Inventory');
use_ok('Darcs::Inventory::Diff');
