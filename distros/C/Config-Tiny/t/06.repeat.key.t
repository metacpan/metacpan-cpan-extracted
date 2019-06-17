#!/usr/bin/perl

use Config::Tiny;

use Test::More tests => 3;

# ------------------------

my($string) = <<'EOS';
key1=One
key2=Infix
key1=Two
EOS

my($config) = Config::Tiny -> read_string($string);

isa_ok($config, 'Config::Tiny', 'read_string() returns an object');
ok($$config{_}{key1} eq 'Two', 'Access to hashref returns correct value');
ok($$config{_}{key2} eq 'Infix', 'Access to hashref returns correct value');
