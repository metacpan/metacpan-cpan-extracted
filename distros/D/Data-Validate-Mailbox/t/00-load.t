#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Data::Validate::Mailbox' ) || print "Bail out!\n";
}

diag( "Testing Data::Validate::Mailbox $Data::Validate::Mailbox::VERSION, Perl $], $^X" );
