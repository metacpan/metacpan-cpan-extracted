#!/usr/bin/perl
use lib qw (lib ../lib);
use warnings;
use strict;
use Test::More tests => 9;
use Config::Mini;

my $data = <<EOF;
  foo = bar
  baz = buz

  [section1]
  key1 = val1
  key2 = val2

  [section2]
  key3 = val3
  key4 = arrayvalue
  key4 = arrayvalue2
  key4 = arrayvalue3
EOF

Config::Mini::parse_data ($data);

my @array = Config::Mini::get ("section2", "key4");
is (Config::Mini::get ("general", "foo"), "bar");
is (Config::Mini::get ("general", "baz"), "buz");
is (Config::Mini::get ("section1", "key1"), "val1");
is (Config::Mini::get ("section1", "key2"), "val2");
is (Config::Mini::get ("section2", "key3"), "val3");
is (Config::Mini::get ("section2", "key4"), "arrayvalue");
is ($array[0], "arrayvalue");
is ($array[1], "arrayvalue2");
is ($array[2], "arrayvalue3");

