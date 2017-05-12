#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::SCM::Digest' ) || print "Bail out!\n";
}

diag( "Testing App::SCM::Digest $App::SCM::Digest::VERSION, Perl $], $^X" );
