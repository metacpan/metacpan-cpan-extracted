#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Ansible' ) || print "Bail out!\n";
}

diag( "Testing Ansible $Ansible::VERSION, Perl $], $^X" );
