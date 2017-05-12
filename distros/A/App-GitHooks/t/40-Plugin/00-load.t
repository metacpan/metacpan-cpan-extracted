#!/usr/bin/env perl

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;

BEGIN
{
    use_ok( 'App::GitHooks::Plugin' );
}

diag( "Testing App::GitHooks::Plugin $App::GitHooks::Plugin::VERSION, Perl $], $^X" );
