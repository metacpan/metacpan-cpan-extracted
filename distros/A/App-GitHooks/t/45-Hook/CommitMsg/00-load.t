#!/usr/bin/env perl

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;

BEGIN
{
    use_ok( 'App::GitHooks::Hook::CommitMsg' );
}

diag( "Testing App::GitHooks::Hook::CommitMsg $App::GitHooks::Hook::CommitMsg::VERSION, Perl $], $^X" );
