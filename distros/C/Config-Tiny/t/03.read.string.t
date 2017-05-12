#!/usr/bin/perl

use Config::Tiny;

use Test::More tests => 2;

# ------------------------

my($string) = <<'EOS';
param1=One
param2=Two
EOS

my($config) = Config::Tiny -> read_string($string);

isa_ok($config, 'Config::Tiny', 'read_string() returns an object');
ok($$config{_}{param1} eq 'One', 'Access to hashref returns correct value');
