use strict;
use warnings;
use utf8;
use Test::More 0.96;
use lib 't/lib';
use C2STests;

test_import('cp1252', {
  csvs => [qw( cp1252.csv )],
  args => [
    -l => 'file_encoding=cp1252',
    -l => 'file_open_layers=:crlf',
  ],
  attr => {
    encoding => 'cp1252',
    loader_options => {
      file_encoding => 'cp1252',
      file_open_layers => ':crlf',
    },
  },
  rs   => {
    'SELECT * FROM cp1252' => [
      ["\x{2022}", "bullet"],
    ],
  },
});

test_import('utf8', {
  csvs => [qw( utf8.csv )],
  args => [
    -e => 'UTF-8',
  ],
  attr => {
    encoding => 'UTF-8',
    loader_options => {
      file_encoding => 'UTF-8',
    },
  },
  rs   => {
    'SELECT * FROM utf8' => [
      ["\x{29bf}", "circled bullet"],
      ["🚅", "train"],
    ],
  },
});

done_testing;
