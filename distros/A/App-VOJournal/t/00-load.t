#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'App::VOJournal' ) || print "Bail out!\n";
}

diag( "Testing App::VOJournal $App::VOJournal::VERSION, Perl $], $^X" );
