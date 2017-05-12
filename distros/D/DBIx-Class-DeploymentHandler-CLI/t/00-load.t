#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'DBIx::Class::DeploymentHandler::CLI' ) || print "Bail out!\n";
}

diag( "Testing DBIx::Class::DeploymentHandler::CLI $DBIx::Class::DeploymentHandler::CLI::VERSION, Perl $], $^X" );
