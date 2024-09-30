#! /usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Data::DPath 'dpath';
use Data::Dumper;

# local $Data::DPath::DEBUG = 1;

use_ok( 'Data::DPath' );

my $data = {
            'zero' => {
                       'goal' => 0,
                       'count' => "zero",
                      },
            'undef' => {
                        'goal' => undef,
                        'count' => "UNDEF",
                       },
            'normal' => {
                        'normal' => {
                                     'goal' => 15,
                                     'data_size' => 254242,
                                    }
                       }
           };

# ==================================================

my $res;

$res = [ dpath('//goal[ value == 15]')->match($data) ];
cmp_bag($res, [ 15 ], "leaf with value");

$res = [ dpath('//goal')->match($data) ];
cmp_bag($res, [ 15, 0, undef ], "many leafs with value");

$res = [ dpath('//goal[value == 15]/../data_size')->match($data) ];
cmp_bag($res, [ 254242 ], "data_size via leaf");

$res = [ dpath('//goal[ value eq 0 ]')->match($data) ];
cmp_bag($res, [ 0 ], "leaf of value 0");

$res = [ dpath('//goal[value eq 0]/../count')->match($data) ];
cmp_bag($res, [ "zero" ], "data_size via leaf of value 0");

$res = [ dpath('//goal[ value eq undef ]')->match($data) ];
cmp_bag($res, [ undef ], "leaf of value undef");

$res = [ dpath('//goal[ value eq undef ]/../count')->match($data) ];
cmp_bag($res, [ "UNDEF" ], "data_size via leaf of value undef");

$res = [ dpath('/normal/normal/goal')->match($data) ];
cmp_bag($res, [ 15 ], "absolute path - leaf with value");

$res = [ dpath('/zero/goal')->match($data) ];
cmp_bag($res, [ 0 ], "absolute path - leaf of value 0");

done_testing();
