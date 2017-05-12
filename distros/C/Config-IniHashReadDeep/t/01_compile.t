#!/usr/bin/perl

use strict;
use warnings;
use lib '../lib','lib';

use Test::More tests => 2;

my @modules = qw(
  Config::IniHash
  Config::IniHashReadDeep
);

foreach my $module (@modules) {
    eval " use $module ";
    ok(!$@, "$module compiles");
}

1;
