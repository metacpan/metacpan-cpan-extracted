#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Backup::Duplicity::YADW' ) || print "Bail out!\n";
}

diag( "Testing Backup::Duplicity::YADW $Backup::Duplicity::YADW::VERSION, Perl $], $^X" );
