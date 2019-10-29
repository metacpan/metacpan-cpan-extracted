#!/usr/bin/env perl

use strict;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::issn';
    use_ok $pkg;
}
require_ok $pkg;

dies_ok {$pkg->new()->fix({issn => '1553667x'})} "path required";

lives_ok {$pkg->new('issn')->fix({issn => '1553667x'})} "path required";

is_deeply $pkg->new('issn')->fix({issn => '1553667x'}),
    {issn => '1553-667X'}, "normalize issn";

is_deeply $pkg->new('identifier.*.issn')
    ->fix({identifier => [{issn => '1553667X'}, {issn => '0355-4325'}]}),
    {identifier => [{issn => '1553-667X'}, {issn => '0355-4325'}]},
    "normalize issn with complex path";

is_deeply $pkg->new('issn_path')->fix({issn_path => ''}), {issn_path => ''},
    "empty issn";

is_deeply $pkg->new('issn_path')->fix({}), {}, "missing issn";

done_testing;
