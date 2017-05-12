#!/usr/bin/env perl

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;

BEGIN
{
    use_ok( 'App::GitWorkspaceScanner' );
}

diag( "Testing App::GitWorkspaceScanner $App::GitWorkspaceScanner::VERSION, Perl $], $^X" );
