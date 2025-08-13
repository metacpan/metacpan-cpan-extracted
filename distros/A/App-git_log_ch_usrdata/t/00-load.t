#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::git_log_ch_usrdata' ) || print "Bail out!\n";
}

diag( "Testing App::git_log_ch_usrdata $App::git_log_ch_usrdata::VERSION, Perl $], $^X" );
