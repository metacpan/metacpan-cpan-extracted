#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Catalyst::Plugin::Profile::DBI::Log' ) || print "Bail out!\n";
}

diag( "Testing Catalyst::Plugin::Profile::DBI::Log $Catalyst::Plugin::Profile::DBI::Log::VERSION, Perl $], $^X" );
