#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::template';
    use_ok $pkg;
}

is_deeply $pkg->new('message', 'Mr [%name%] is [%age%] years old')
    ->fix({name => "John", age => "44"}),
    {name => "John", age => "44", message => "Mr John is 44 years old"},
    "template";

done_testing 2;

