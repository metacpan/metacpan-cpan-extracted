#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Fix::set_field;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::Condition::is_valid_issn';
    use_ok $pkg;
}

my $cond = $pkg->new('issn');
$cond->pass_fixes([Catmandu::Fix::set_field->new('test', 'pass')]);
$cond->fail_fixes([Catmandu::Fix::set_field->new('test', 'fail')]);

is_deeply
    $cond->fix({issn => "1550-7998"}),
    {issn => "1550-7998", test => 'pass'},
    "is valid";

is_deeply
    $cond->fix({issn => "1550-799X"}),
    {issn => "1550-799X" , test => 'fail' },
    "is invalid";

is_deeply
    $cond->fix({issn => ""}),
    {issn => "" , test => 'fail' },
    "is invalid";

is_deeply
    $cond->fix({}),
    {test => 'fail' },
    "is invalid";

done_testing;
