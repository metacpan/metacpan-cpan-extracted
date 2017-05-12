#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'DBIx::Mojo::Template' ) || print "Bail out!\n";
}

diag( "Testing DBIx::Mojo::Template $DBIx::Mojo::Template::VERSION, Perl $], $^X" );
