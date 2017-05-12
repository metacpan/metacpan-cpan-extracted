#!/usr/bin/perl

use File::Spec::Functions qw(rel2abs splitpath catfile);
use Test::More;
use Test::NoWarnings;
use warnings;
use strict;


my $DIR      = rel2abs((splitpath __FILE__)[1]);
my $ERR_FILE = catfile($DIR, 'parse-file-err.lua');


plan tests => 8;


use_ok("Data::Lua");


{
    my $name = 'undef filename';
    my $vars = eval { Data::Lua->parse_file(undef) };
    is($vars, undef,    "$name: vars is undef");
    ok((not length $@), "$name: no exception");
}
{
    my $name = 'empty filename';
    my $vars = eval { Data::Lua->parse_file('') };
    is($vars, undef,    "$name: vars is undef");
    ok((not length $@), "$name: no exception");
}
{
    my $name = 'parse error';
    my $vars = eval { Data::Lua->parse_file($ERR_FILE) };
    is($vars, undef, "$name: vars is undef");
    ok(length $@,    "$name: exception raised");
}
