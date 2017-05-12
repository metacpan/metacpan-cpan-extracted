#!perl

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;

BEGIN
{
    use_ok( 'App::GitHooks::Plugin::ValidateChangelogFormat' );
}

diag( "Testing App::GitHooks::Plugin::ValidateChangelogFormat $App::GitHooks::Plugin::ValidateChangelogFormat::VERSION, Perl $], $^X" );
