#!perl

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;

BEGIN
{
    use_ok( 'App::GitHooks::Plugin::ForceBranchNamePattern' );
}

diag( "Testing App::GitHooks::Plugin::ForceBranchNamePattern $App::GitHooks::Plugin::ForceBranchNamePattern::VERSION, Perl $], $^X" );
