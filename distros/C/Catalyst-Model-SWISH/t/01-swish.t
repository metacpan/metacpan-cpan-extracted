#!/usr/bin/env perl

use strict;
use warnings;
use lib 't/MySWISH/lib';
use Test::More tests => 3;
use Data::Dump qw( dump );

use HTTP::Request::Common;
use File::Spec;

SKIP: {

    eval { require SWISH::API::Object; };
    if ($@) {
        skip $@, 3;
    }

    require Catalyst::Test;
    Catalyst::Test->import('MySWISH');
    my $index = File::Spec->catfile( 't', 'MySWISH', 'index.swish-e' );
    my $files = File::Spec->catfile( 't', 'test.html' );
    my $cmd   = "swish-e -i $files -f $index";

    # create temp index
    # don't check system ret value since we just test for -s index below.
    diag($cmd);
    system($cmd);

    unless ( -s $index ) {
        skip 'no index found', 3;
    }

    my $res;

    ok( $res = request('/search?q=hello'), "get /search?q=hello" );

    is( $res->headers->{status}, 200, "200 response" );

    #diag( $res->content );

    like( $res->content, qr/"hits" : "?1"?,/, "1 hit" );

}
