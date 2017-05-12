#!perl

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;

BEGIN
{
    use_ok( 'App::GitHooks::Plugin::PgBouncerAuthSyntax' );
}

diag( "Testing App::GitHooks::Plugin::PgBouncerAuthSyntax $App::GitHooks::Plugin::PgBouncerAuthSyntax::VERSION, Perl $], $^X" );
