#!/usr/bin/perl

use warnings;
use strict;

use Test::More 'no_plan';

use CAD::Format::STL;

my $stl = CAD::Format::STL->new;
isa_ok($stl, 'CAD::Format::STL');

my $part = $stl->add_part('cube');
isa_ok($part, 'CAD::Format::STL::part');
is($part->name, 'cube', 'part name');

$part->add_facets(
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
is(scalar($part->facets), 12, 'twelve triangles');

# XXX this is silly, no?
if($ENV{DO_REGEN}) {
  $stl->save("files/cube.stl");
  local $SIG{__DIE__};
  die "       bailing out after regen";
}

{
  my $string;
  open(my $ofh, '>', \$string) or die "ack";
  $stl->save($ofh);
  ok($string, 'wrote to filehandle');
  my $expect = do {
    open(my $fh, '<', 'files/cube.stl') or die "cannot open cube.stl $!";
    local $/; <$fh>;
  };

  s/ */ /g for($string, $expect);
  s/\015?\012/\n/g for($string, $expect);
  is($string, $expect, 'string match');
}

# vim:ts=2:sw=2:et:sta
