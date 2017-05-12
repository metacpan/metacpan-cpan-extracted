#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
use lib 't/lib';
require 'do_request.pl';

# Check our plugin has successfully added methods to the Catalyst request
# object, and that the request dispatch isn't broken by our hooks.

# no need for a die() here because Cat will do that for us
BEGIN { use_ok('Catalyst::Test', ('PluginTestApp')); }

{
    my $creq = &do_request;

    # has installed two methods into $c->request
    can_ok( $creq, 'valid_cookie')
        or diag( 'Catalyst request objects have a new valid_cookie() method' );
    can_ok( $creq, 'invalid_cookie')
        or diag( 'Catalyst request objects have a new invalid_cookie() method' );
}
