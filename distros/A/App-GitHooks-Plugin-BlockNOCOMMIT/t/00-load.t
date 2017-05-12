#!perl

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;

BEGIN
{
    use_ok( 'App::GitHooks::Plugin::BlockNOCOMMIT' );
}

diag( "Testing App::GitHooks::Plugin::BlockNOCOMMIT $App::GitHooks::Plugin::BlockNOCOMMIT::VERSION, Perl $], $^X" );
