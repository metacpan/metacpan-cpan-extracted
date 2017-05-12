#!/usr/bin/env perl

use strict;
use warnings;

# VERSION

use Test::More;

eval "use App::ZofCMS::Test::Plugin;";
plan skip_all
=> "App::ZofCMS::Test::Plugin required for testing plugin"
    if $@;

plugin_ok(
    'Cookies',
    { set_cookies => [ [foo => 'bar'] ], },
    { foo => 'bar' },
    { foo => 'bar' },
);