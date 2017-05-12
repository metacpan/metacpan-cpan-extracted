#!perl

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;

BEGIN
{
    use_ok( 'App::GitHooks::Plugin::DetectCommitNoVerify' );
}

diag( "Testing App::GitHooks::Plugin::DetectCommitNoVerify $App::GitHooks::Plugin::DetectCommitNoVerify::VERSION, Perl $], $^X" );
