#!/usr/bin/env perl

use utf8;
use v5.40;

use Path::Tiny;
use Data::Dumper;
use List::Util 'uniq';

our %pkgmeta = (
  wktree => [$ENV],
  bare => [],
  remote => []
)

