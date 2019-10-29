#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Fix::set_field;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::Condition::is_valid_orcid';
    use_ok $pkg;
}

my $cond = $pkg->new('isbn');
$cond->pass_fixes([Catmandu::Fix::set_field->new('test', 'pass')]);
$cond->fail_fixes([Catmandu::Fix::set_field->new('test', 'fail')]);

is_deeply $cond->fix({isbn => "0000-0001-8390-6171"}),
    {isbn => "0000-0001-8390-6171", test => 'pass'}, "is valid";

is_deeply $cond->fix({isbn => "0000-0001-8390-6171x"}),
    {isbn => "0000-0001-8390-6171x", test => 'fail'}, "is invalid";

is_deeply $cond->fix({isbn => ""}), {isbn => "", test => 'fail'},
    "is invalid";

is_deeply $cond->fix({}), {test => 'fail'}, "is invalid";

done_testing;
