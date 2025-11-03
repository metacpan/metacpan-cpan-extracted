#!/usr/bin/env perl

use Modern::Perl;

use Test2::V0;

use Data::JavaScript ( ':all' => { UNDEF => 0 } );

#Test undef value overloading
is join( q//, jsdump( 'foo', [ 1, undef, 1 ] ) ),
  'var foo = new Array;foo[0] = 1;foo[1] = undefined;foo[2] = 1;',
  'Literal undefined.';

is join( q//, jsdump( 'bar', [ 1, undef, 1 ], 'null' ) ),
  'var bar = new Array;bar[0] = 1;bar[1] = null;bar[2] = 1;',
  'Literal null';

#Test hashes
is
  join( q//, jsdump( 'qux', { color => 'monkey', age => 2, eyes => 'blue' } ) ),
  'var qux = new Object;qux["age"] = 2;'
  . 'qux["color"] = "monkey";qux["eyes"] = "blue";',
  'Simple hashref';

done_testing;
