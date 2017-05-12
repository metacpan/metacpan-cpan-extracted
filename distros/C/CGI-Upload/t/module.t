#!/usr/bin/perl
use strict;
use warnings;

use Test::More 'tests' => 3;

BEGIN {

    #   Test 1 - Ensure that the CGI::Upload module can be loaded

    use_ok( 'CGI::Upload' );
}

#   Test 2 - Create a new object and confirm its inheritance as CGI::Upload
#   object

my $object = CGI::Upload->new;
isa_ok( $object, 'CGI::Upload' );

eval {
    CGI::Upload->new(query => "CGI");
};
like($@, qr{Argument to new should be a HASH reference}, "Carp when new called with bad parameters");
