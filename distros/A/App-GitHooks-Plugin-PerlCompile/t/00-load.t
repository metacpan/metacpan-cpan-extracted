#!perl

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;

BEGIN
{
    use_ok( 'App::GitHooks::Plugin::PerlCompile' );
}

diag( "Testing App::GitHooks::Plugin::PerlCompile $App::GitHooks::Plugin::PerlCompile::VERSION, Perl $], $^X" );
