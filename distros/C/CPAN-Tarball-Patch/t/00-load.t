#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'CPAN::Tarball::Patch' ) || print "Bail out!\n";
}

diag( "Testing CPAN::Tarball::Patch $CPAN::Tarball::Patch::VERSION, Perl $], $^X" );
