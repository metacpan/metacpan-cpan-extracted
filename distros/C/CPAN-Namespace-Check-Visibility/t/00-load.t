#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'CPAN::Namespace::Check::Visibility' ) || print "Bail out!\n";
}

diag( "Testing CPAN::Namespace::Check::Visibility $CPAN::Namespace::Check::Visibility::VERSION, Perl $], $^X" );
