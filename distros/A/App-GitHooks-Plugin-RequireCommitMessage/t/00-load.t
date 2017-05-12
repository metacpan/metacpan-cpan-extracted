#!perl

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;

BEGIN
{
    use_ok( 'App::GitHooks::Plugin::RequireCommitMessage' );
}

diag( "Testing App::GitHooks::Plugin::RequireCommitMessage $App::GitHooks::Plugin::RequireCommitMessage::VERSION, Perl $], $^X" );
