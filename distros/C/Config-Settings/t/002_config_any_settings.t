#!/usr/bin/env perl

use Test::More;

use strict;
use warnings;

plan tests => 2;

SKIP: {
  eval { require Config::Any };

  skip "Config::Any not installed",2 if $@;

  Config::Any->import;

  {
    my $config = Config::Any->load_files ({ files => [ "t/test.settings" ],use_ext => 1 });

    is_deeply $config,[ { "t/test.settings" => { foo => 42 } } ],"load_files";
  }

  {
    my $config = Config::Any->load_stems ({ stems => ["t/test" ],use_ext => 1 });

    is_deeply $config,[ { "t/test.settings" => { foo => 42 } } ],"load_stems";
  }
}

