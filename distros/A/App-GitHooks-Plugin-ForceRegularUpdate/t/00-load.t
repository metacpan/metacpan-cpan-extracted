#!perl

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;

BEGIN
{
    use_ok( 'App::GitHooks::Plugin::ForceRegularUpdate' );
}

diag( "Testing App::GitHooks::Plugin::ForceRegularUpdate $App::GitHooks::Plugin::ForceRegularUpdate::VERSION, Perl $], $^X" );
