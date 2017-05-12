#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 14;
use lib 't/lib';
require 'do_request.pl';

# Tests to check that our plugin doesn't mange cookie as it reads them.
# Note that because required defaults to 1, these cookies are processed fully.

# no need for a die() here because Cat will do that for us
BEGIN { use_ok('Catalyst::Test', ('PluginTestApp')); }

use HTTP::Request::Common;

{
    my $request = HTTP::Request::Common::GET(
        '/testrequest',
        'Cookie' => 'Catalyst=Cool; Cool=Catalyst',
    );

    my $creq = &do_request( $request );
   
    # plugin has not mangled cookies in request object
    
    isa_ok( $creq->cookies->{Catalyst}, 'CGI::Simple::Cookie',
        'Cookie "Catalyst"' );
    is( $creq->cookies->{Catalyst}->name, 'Catalyst',
        'Cookie "Catalyst" name is set' );
    is( $creq->cookies->{Catalyst}->value, 'Cool',
        'Cookie "Catalyst" value is set to "Cool"' );

    isa_ok( $creq->cookies->{Cool}, 'CGI::Simple::Cookie',
        'Cookie "Cool"' );
    is( $creq->cookies->{Cool}->name, 'Cool',
        'Cookie "Cool" name is set' );
    is( $creq->cookies->{Cool}->value, 'Catalyst',
        'Cookie "Cool" value is set to "Catalyst"' );
}
