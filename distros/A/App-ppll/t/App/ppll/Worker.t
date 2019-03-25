#!/usr/bin/env perl

use autodie;
use strict;
use utf8::all;
use v5.20;
use warnings;

use Test::Most;

require_ok 'App::ppll::Worker';

my $worker = App::ppll::Worker->new(
  parameter => 'foo',
);

is "$worker", 'foo';

done_testing;
