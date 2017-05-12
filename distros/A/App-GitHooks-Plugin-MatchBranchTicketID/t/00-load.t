#!perl

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;

BEGIN
{
    use_ok( 'App::GitHooks::Plugin::MatchBranchTicketID' );
}

diag( "Testing App::GitHooks::Plugin::MatchBranchTicketID $App::GitHooks::Plugin::MatchBranchTicketID::VERSION, Perl $], $^X" );
