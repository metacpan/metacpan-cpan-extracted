#!/usr/bin/perl

use Test::More;
use Test::NoWarnings;
use warnings;
use strict;


plan tests => 8;


use_ok("Data::Lua");


{
    my $name = 'undef string';
    my $vars = eval { Data::Lua->parse(undef) };
    is($vars, undef,    "$name: vars is undef");
    ok((not length $@), "$name: no exception");
}
{
    my $name = 'empty string';
    my $vars = eval { Data::Lua->parse('') };
    is($vars, undef,    "$name: vars is undef");
    ok((not length $@), "$name: no exception");
}
{
    my $name = 'parse error';
    my $vars = eval { Data::Lua->parse("s = 'bad") };
    is($vars, undef, "$name: vars is undef");
    ok(length $@,    "$name: exception raised");
}
