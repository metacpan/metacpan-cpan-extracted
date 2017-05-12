#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN {
    $ENV{CATALYST_CONFIG} = 't/var/bracket.yml';
    use_ok( 'Catalyst::Test', 'Bracket' );
}

my ($response, $c) = ctx_request('/');
isa_ok( $c, 'Bracket');

done_testing();
