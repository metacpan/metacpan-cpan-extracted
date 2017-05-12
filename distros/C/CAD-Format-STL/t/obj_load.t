#!/usr/bin/perl

use warnings;
use strict;

use Test::More 'no_plan';

use CAD::Format::STL;

my $stl = CAD::Format::STL->new or die "ack";
my $file = 'files/cube.stl';
{
  my $check = eval {$stl->load($file)};
  ok(not $@) or die $@;
  is($check, $stl);
}

my @parts = $stl->parts;
is(scalar(@parts), 1, 'one part');

my $part = $parts[0];
is($part->name, 'cube', 'part name');
is(scalar($part->facets), 12, 'twelve triangles');

{
  my $check = $stl->part(0);
  is($check, $part, 'got part 0');
  eval {$stl->part(1)};
  like($@, qr/no part/, 'nothing there');
  is($stl->part(-1), $part, 'got part -1');
  eval {$stl->part(-2)};
  like($@, qr/no part/, 'nothing there');
}

my @cube_def = (
  [[0,0,0], [0,1,0], [1,1,0]],
  [[0,0,0], [1,1,0], [1,0,0]],
  [[0,0,0], [0,0,1], [0,1,1]],
  [[0,0,0], [0,1,1], [0,1,0]],
  [[0,0,0], [1,0,0], [1,0,1]],
  [[0,0,0], [1,0,1], [0,0,1]],
  [[0,0,1], [1,0,1], [1,1,1]],
  [[0,0,1], [1,1,1], [0,1,1]],
  [[1,0,0], [1,1,0], [1,1,1]],
  [[1,0,0], [1,1,1], [1,0,1]],
  [[0,1,0], [0,1,1], [1,1,1]],
  [[0,1,0], [1,1,1], [1,1,0]],
);
{ # try adding parts
  my $p = $stl->add_part('cube2');
  isa_ok($p, 'CAD::Format::STL::part');
  is($p->name, 'cube2', 'part name');
  $p->add_facets(@cube_def);
  is(scalar($p->facets), 12, 'twelve triangles');
  is_deeply([$p->facets], [map({[[0,0,0], @$_]} @cube_def)]);
}
{ # once more with immediate data passing
  my $p = $stl->add_part('cube2', @cube_def);
  isa_ok($p, 'CAD::Format::STL::part');
  is($p->name, 'cube2', 'part name');
  is(scalar($p->facets), 12, 'twelve triangles');
  is_deeply([$p->facets], [map({[[0,0,0], @$_]} @cube_def)]);
}

# vim:ts=2:sw=2:et:sta
