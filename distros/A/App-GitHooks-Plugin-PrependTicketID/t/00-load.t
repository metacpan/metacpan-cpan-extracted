#!perl

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;

BEGIN
{
    use_ok( 'App::GitHooks::Plugin::PrependTicketID' );
}

diag( "Testing App::GitHooks::Plugin::PrependTicketID $App::GitHooks::Plugin::PrependTicketID::VERSION, Perl $], $^X" );
