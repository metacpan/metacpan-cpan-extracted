#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu::Fix::set_field;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::Condition::is_uri';
    use_ok $pkg;
}

my $cond = $pkg->new('uri');
$cond->pass_fixes([Catmandu::Fix::set_field->new('test', 'pass')]);
$cond->fail_fixes([Catmandu::Fix::set_field->new('test', 'fail')]);

is_deeply
    $cond->fix({uri => "ftp://foo.bar/file.txt"}),
    {uri => "ftp://foo.bar/file.txt", test => 'pass'},
    "is valid";

is_deeply
    $cond->fix({uri => "  http://oops.be/spaces ?!"}),
    {uri => "  http://oops.be/spaces ?!" , test => 'fail' },
    "is invalid";

is_deeply
    $cond->fix({uri => ""}),
    {uri => "" , test => 'fail' },
    "is invalid";

is_deeply
    $cond->fix({}),
    {test => 'fail' },
    "is invalid";

done_testing;
