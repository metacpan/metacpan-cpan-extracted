#!/usr/bin/env perl

use strict;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::isbn10';
    use_ok $pkg;
}
require_ok $pkg;

dies_ok {$pkg->new()} "required argument";
lives_ok {$pkg->new('isbn')} "path required";

is_deeply $pkg->new('isbn_path')->fix({isbn_path => '1565922573'}),
    {isbn_path => '1-56592-257-3'}, "normalize isbn 10";

is_deeply $pkg->new('isbn_path')->fix({isbn_path => '1565922573'}),
    {isbn_path => '1-56592-257-3'}, "normalize isbn 10";

is_deeply $pkg->new('identifier.*.isbn')
    ->fix(
    {identifier => [{isbn => '9781565922570'}, {isbn => '0596527241'}]}),
    {identifier => [{isbn => '1-56592-257-3'}, {isbn => '0-596-52724-1'}]},
    "normalize isbn 10 with complex path";

is_deeply $pkg->new('isbn_path')->fix({isbn_path => ''}), {isbn_path => ''},
    "empty isbn 10";

is_deeply $pkg->new('isbn_path')->fix({}), {}, "missing isbn 10";

is_deeply $pkg->new('isbn_path')->fix({isbn_path => '979-10-90636-07-1'}),
    {isbn_path => ''}, "non-convertible isbn 13";

done_testing;
