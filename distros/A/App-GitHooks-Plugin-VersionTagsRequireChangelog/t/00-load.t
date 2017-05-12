#!perl

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;

BEGIN
{
    use_ok( 'App::GitHooks::Plugin::VersionTagsRequireChangelog' );
}

diag( "Testing App::GitHooks::Plugin::VersionTagsRequireChangelog $App::GitHooks::Plugin::VersionTagsRequireChangelog::VERSION, Perl $], $^X" );
