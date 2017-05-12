#!/usr/bin/env perl

use strict;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
  $pkg = 'Catmandu::Fix::isbn13';
  use_ok $pkg;
}
require_ok $pkg;

dies_ok { $pkg->new() } "required argument";
lives_ok { $pkg->new('isbn') } "path required";

is_deeply
  $pkg->new('isbn_path')->fix({isbn_path => '1565922573'}),
  { isbn_path => '978-1-56592-257-0'},
  "normalize isbn 13";

is_deeply
  $pkg->new('isbn_path')->fix({isbn_path => '9780596527242'}),
  { isbn_path => '978-0-596-52724-2'},
  "normalize isbn 13 again";

is_deeply
    $pkg->new('identifier.*.isbn')->fix(
    {identifier => [{isbn => '1565922573'}, {isbn => '9780596527242'}]}),
    {identifier => [
      {isbn => '978-1-56592-257-0'},
      {isbn => '978-0-596-52724-2'},
    ]},
    "normalize isbn with complex path";

is_deeply
  $pkg->new('isbn_path')->fix({isbn_path => ''}),
  { isbn_path => ''},
  "empty isbn 13";

is_deeply
  $pkg->new('isbn_path')->fix({}),
  {},
  "missing isbn 13";

done_testing;
