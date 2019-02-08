#!/usr/bin/env perl

use strict;
use warnings;
use DataStruct::Flat;

use Test::More;

{
  my $flattener = DataStruct::Flat->new;
  is_deeply({
    'a' => 'string',
    'x' => 1,
    'y.0' => 42,
    'y.1' => 'second y',
    'y.2' => 44,
    'z.0.x' => 'the x',
    'z.0.y' => 89,
  }, $flattener->flatten({
    a => 'string',
    x => 1,
    y => [ 42, 'second y', 44 ],
    z => [ { x => 'the x', y => 89 } ],
  }), 'Got correct flattened datastructure');
}

{
  my $flattener = DataStruct::Flat->new;
  is_deeply({
    "a\\.dotted\\.entry" => 'string',
    "b.dotted\\.entry" => 'string2',
  }, $flattener->flatten({
    'a.dotted.entry' => 'string',
    b => { 'dotted.entry' => 'string2' },
  }), 'Got correct flattened datastructure');
}

done_testing;
