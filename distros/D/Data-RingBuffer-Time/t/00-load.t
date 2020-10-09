#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Data::RingBuffer::Time' ) || print "Bail out!\n";
}

diag( "Testing Data::RingBuffer::Time $Data::RingBuffer::Time::VERSION, Perl $], $^X" );
