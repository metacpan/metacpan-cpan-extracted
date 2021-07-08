#!perl
use 5.006;
use strict;
use warnings;
use Test::More;



BEGIN {
    use_ok( 'Book::Collate' ) || print "Bail out!\n";
    #use_ok( 'Book::Collate::Book' ) || print "Bail out!\n";
    #use_ok( 'Book::Collate::Report' ) || print "Bail out!\n";
    #use_ok( 'Book::Collate::Section' ) || print "Bail out!\n";
}

diag( "Testing Book::Collate $Book::Collate::VERSION, Perl $], $^X" );

done_testing();
