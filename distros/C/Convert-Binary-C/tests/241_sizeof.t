################################################################################
#
# Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test::More tests => 71;
use Convert::Binary::C @ARGV;

my $c = new Convert::Binary::C IntSize => 4, CharSize => 1, Alignment => 1;

eval {
$c->parse(<<'ENDC');

struct normal {
  int  a;
  char b[3];
  char c[3][3][3];
};

struct flexible {
  int  a;
  char b[];
};

ENDC
};

is($@, '', "parse C code");

my @tests = (
  [ 'normal.a'             => 4 ],
  [ 'normal.b'             => 3 ],
  [ 'normal.b[0]'          => 1 ],
  [ 'normal.b[1]'          => 1 ],
  [ 'normal.b[2]'          => 1 ],
  [ 'normal.b[3]'          => 1 ],
  [ 'normal.b[4]'          => 1 ],
  [ 'normal.b[+4]'         => 1 ],
  [ 'normal.b[+1000000]'   => 1 ],
  [ 'normal.b[-0]'         => 1 ],
  [ 'normal.b[-1]'         => 1 ],
  [ 'normal.b[-2]'         => 1 ],
  [ 'normal.b[-3]'         => 1 ],
  [ 'normal.b[-4]'         => 1 ],
  [ 'normal.b[-5]'         => 1 ],
  [ 'normal.b[-1000000]'   => 1 ],
  [ 'normal.c[-10]'        => 9 ],
  [ 'normal.c[-10][-10]'   => 3 ],
  [ 'normal.c[-9][-9][-9]' => 1 ],

  [ 'flexible.a'           => 4 ],
  [ 'flexible.b'           => 0 ],
  [ 'flexible.b[0]'        => 1 ],
  [ 'flexible.b[1]'        => 1 ],
  [ 'flexible.b[2]'        => 1 ],
  [ 'flexible.b[3]'        => 1 ],
  [ 'flexible.b[4]'        => 1 ],
  [ 'flexible.b[+4]'       => 1 ],
  [ 'flexible.b[+1000000]' => 1 ],
  [ 'flexible.b[-0]'       => 1 ],
  [ 'flexible.b[-1]'       => 1 ],
  [ 'flexible.b[-2]'       => 1 ],
  [ 'flexible.b[-3]'       => 1 ],
  [ 'flexible.b[-4]'       => 1 ],
  [ 'flexible.b[-5]'       => 1 ],
  [ 'flexible.b[-1000000]' => 1 ],
);

for my $t (@tests) {
  my $size = eval { $c->sizeof($t->[0]) };
  is($@, '', "eval { sizeof($t->[0]) }");
  is($size, $t->[1], "sizeof($t->[0]) == $t->[1]");
}
