#!/usr/bin/env perl

use autodie;
use strict;
use utf8::all;
use v5.20;
use warnings;

use Test::Most;

my @modules = qw(

  App::ppll
  App::ppll::Worker

);

plan tests => scalar @modules;

use_ok $_ for @modules;

done_testing;
