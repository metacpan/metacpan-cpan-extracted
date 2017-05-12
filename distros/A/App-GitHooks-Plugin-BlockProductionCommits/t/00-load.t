#!perl

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;

BEGIN
{
    use_ok( 'App::GitHooks::Plugin::BlockProductionCommits' );
}

diag( "Testing App::GitHooks::Plugin::BlockProductionCommits $App::GitHooks::Plugin::BlockProductionCommits::VERSION, Perl $], $^X" );
