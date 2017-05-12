#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 5;
use lib 't/lib';
use CleanEnv;

use BSON;

my $js = q[
    function a(b,c) {
        if (b) {
            alert(c)
        }
    }
];

my $scope = { a => 6, b => 'foo' };

my $code = BSON::Code->new( $js );
isa_ok( $code, 'BSON::Code' );
is($code->code, $js);

$code = BSON::Code->new( $js, $scope );
isa_ok( $code, 'BSON::Code' );
is($code->code, $js);
is_deeply( $code->scope, $scope );
