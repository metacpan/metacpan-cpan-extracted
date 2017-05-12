#!/usr/bin/env perl

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;

BEGIN
{
    use_ok( 'App::GitHooks::Plugin::Test::PrintSTDERR' );
}

diag( "Testing App::GitHooks::Plugin::Test::PrintSTDERR $App::GitHooks::Plugin::Test::PrintSTDERR::VERSION, Perl $], $^X" );
