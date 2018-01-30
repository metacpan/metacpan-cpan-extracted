#!/usr/bin/env perl

use strict;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
  $pkg = 'Catmandu::Fix::isbn_versions';
  use_ok $pkg;
}
require_ok $pkg;

dies_ok { $pkg->new() } "required argument";
lives_ok { $pkg->new('isbn') } "path required";

is_deeply
  $pkg->new('isbn_path')->fix({isbn_path => '1565922573'}),
  { isbn_path => ['1-56592-257-3', '1565922573', '978-1-56592-257-0', '9781565922570']},
  "isbn 10 versions";

is_deeply
  $pkg->new('identifier.*.isbn')->fix( {identifier => [{isbn => '9781565922570'},{isbn => '0596527241'}]} ),
  {identifier => [
    {isbn => ['1-56592-257-3', '1565922573', '978-1-56592-257-0', '9781565922570']},
    {isbn => ['0-596-52724-1', '0596527241', '978-0-596-52724-2', '9780596527242']}
  ]},
  "isbn 13 and 10 versions with complex path";

is_deeply
  $pkg->new('isbn_path')->fix({isbn_path => '9791090636071'}),
  { isbn_path => ['979-1-09-063607-1', '9791090636071']},
  "non-convertible isbn 13 versions";


done_testing;
