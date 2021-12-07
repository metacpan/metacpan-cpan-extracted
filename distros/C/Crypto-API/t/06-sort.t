use strict;
use warnings;
use Test::More;
use Crypto::API;

is_deeply [
    Crypto::API::_sort_rows(
        [ { asc => 'f' } ],
        { f => 'c' },
        { f => 'a' },
        { f => 'd' },
    )
  ],
  [ { f => 'a' }, { f => 'c' }, { f => 'd' }, ];

is_deeply [
    Crypto::API::_sort_rows(
        [ { desc => 'c' }, { nasc => 'p' } ],
        { c => 'X', p => 2 },
        { c => 'S', p => 3 },
        { c => 'X', p => 1 },
        { c => 'S', p => 2 },
    )
  ],
  [
    { c => 'X', p => 1 },
    { c => 'X', p => 2 },
    { c => 'S', p => 2 },
    { c => 'S', p => 3 },
  ];

is_deeply [
    Crypto::API::_sort_rows(
        [ { asc => "f'g" } ],
        { "f'g" => 'c' },
        { "f'g" => 'd' },
    )
  ],
  [ { "f'g" => 'c' }, { "f'g" => 'd' }, ];

done_testing;
