#!/usr/bin/perl

use Config::Tiny;

use Test::More tests => 4;

# ------------------------

my($source1) = 'One ; Two';
my($source2) = 'One;Two';
my($source3) = 'One; Two';

my($string) = <<EOS;
key1 = $source1
key2 = $source2
key3 = $source3
EOS

my($config) = Config::Tiny -> read_string($string);

isa_ok($config, 'Config::Tiny', 'read_string() returns an object');
ok($$config{_}{key1} eq 'One', "Source '$source1' read correctly as '$$config{_}{key1}'");
ok($$config{_}{key2} eq 'One;Two', "Source '$source2' read correctly as '$$config{_}{key2}'");
ok($$config{_}{key3} eq 'One; Two', "Source '$source3' read correctly as '$$config{_}{key3}'");
