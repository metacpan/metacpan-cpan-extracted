#!perl

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;

BEGIN
{
    use_ok( 'App::GitHooks::Plugin::PerlInterpreter' );
}

diag( "Testing App::GitHooks::Plugin::PerlInterpreter $App::GitHooks::Plugin::PerlInterpreter::VERSION, Perl $], $^X" );
