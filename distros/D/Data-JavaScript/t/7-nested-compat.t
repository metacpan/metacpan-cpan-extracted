#!/usr/bin/env perl

use Modern::Perl;

use Test2::V0;

use Data::JavaScript qw(:all);

my $input = {
  a => {
    a1 => [qw/a1i a1ii a1iii/]
  },
  b => {
    b1 => "b1i",
  },
  c => "c1",
  d => [qw/d1 d2 d3/],
};

my $expected =
    qq/var output = new Object;\n/
  . qq/output["a"] = new Object;\n/
  . qq/output["a"]["a1"] = new Array;\n/
  . qq/output["a"]["a1"][0] = "a1i";\n/
  . qq/output["a"]["a1"][1] = "a1ii";\n/
  . qq/output["a"]["a1"][2] = "a1iii";\n/
  . qq/output["b"] = new Object;\n/
  . qq/output["b"]["b1"] = "b1i";\n/
  . qq/output["c"] = "c1";\n/
  . qq/output["d"] = new Array;\n/
  . qq/output["d"][0] = "d1";\n/
  . qq/output["d"][1] = "d2";\n/
  . qq/output["d"][2] = "d3";\n/;

is
  jsdump( 'output', $input ),
  $expected,
  'Nested jsdump()';

done_testing;
