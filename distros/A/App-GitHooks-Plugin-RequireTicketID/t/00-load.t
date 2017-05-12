#!perl

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;

BEGIN
{
    use_ok( 'App::GitHooks::Plugin::RequireTicketID' );
}

diag( "Testing App::GitHooks::Plugin::RequireTicketID $App::GitHooks::Plugin::RequireTicketID::VERSION, Perl $], $^X" );
