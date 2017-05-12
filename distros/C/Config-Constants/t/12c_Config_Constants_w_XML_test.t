#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use File::Spec;

use t::lib::Foo::Bar2;
use t::lib::Bar::Baz2;

use Config::Constants xml => File::Spec->catdir('t', 'confs', 'conf2.xml');

is_deeply(
    Foo::Bar2::test_BAZ(), 
    [ 1, 2, 3 ], 
    '... got the right config');

is_deeply(
    Bar::Baz2::test_FOO(), 
    { test => 'this', out => 10 }, 
    '... got the right config variable');
    
isa_ok(Bar::Baz2::test_BAR(), 'My::Object');