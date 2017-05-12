#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use boolean;

use Data::MessagePack;
use Data::Dumper::MessagePack qw( mp_unpack );

is_deeply(
  mp_unpack(
    Data::MessagePack->pack({ a => 1 })
  ),
  [ fixmap => [ [ fixstr => "a" ], [ "positive fixint", 1 ] ] ],
  "Simple map"
);

is_deeply(
  mp_unpack(
    Data::MessagePack->pack([ a => b => c => "d" ])
  ),
  [ fixarray => [
    [ fixstr => "a" ],
    [ fixstr => "b" ],
    [ fixstr => "c" ],
    [ fixstr => "d" ],
  ] ],
  "Simple array"
);

is_deeply(
  mp_unpack(
    Data::MessagePack->pack(undef)
  ),
  [ nil => undef ],
  "nil"
);

is_deeply(
  mp_unpack(
    Data::MessagePack->pack(Data::MessagePack::true)
  ),
  [ true => true ],
  "true"
);

is_deeply(
  mp_unpack(
    Data::MessagePack->pack(Data::MessagePack::false)
  ),
  [ false => false ],
  "false"
);

is_deeply(
  mp_unpack(
    Data::MessagePack->pack(0.25)
  ),
  [ float64 => 0.25 ],
  "float64"
);

is_deeply(
  mp_unpack(
    Data::MessagePack->pack(-200)
  ),
  [ int16 => -200 ],
  "int16"
);

done_testing;
