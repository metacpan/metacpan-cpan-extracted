#!perl

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;

BEGIN
{
    use_ok( 'App::GitHooks::Plugin::PerlCritic' );
}

diag( "Testing App::GitHooks::Plugin::PerlCritic $App::GitHooks::Plugin::PerlCritic::VERSION, Perl $], $^X" );
