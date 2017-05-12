#! /usr/bin/env perl

use strict;
use warnings;
no if $] >= 5.018, warnings => 'experimental::smartmatch';

use Test::More;
use Test::Deep;
use Data::DPath 'dpath';
use Data::Dumper;

# local $Data::DPath::DEBUG = 1;

BEGIN {
        if ($] < 5.010) {
                plan skip_all => "Perl 5.010 required for the smartmatch overloaded tests. This is ".$];
        }
}

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

$res = $data ~~ dpath '//goal[ value == 15]';
cmp_bag($res, [ 15 ], "leaf with value");

$res = $data ~~ dpath '//goal';
cmp_bag($res, [ 15, 0, undef ], "many leafs with value");

$res = $data ~~ dpath '//goal[value == 15]/../data_size';
cmp_bag($res, [ 254242 ], "data_size via leaf");

$res = $data ~~ dpath '//goal[ value eq 0 ]';
cmp_bag($res, [ 0 ], "leaf of value 0");

$res = $data ~~ dpath '//goal[value eq 0]/../count';
cmp_bag($res, [ "zero" ], "data_size via leaf of value 0");

$res = $data ~~ dpath '//goal[ value eq undef ]';
cmp_bag($res, [ undef ], "leaf of value undef");

$res = $data ~~ dpath '//goal[ value eq undef ]/../count';
cmp_bag($res, [ "UNDEF" ], "data_size via leaf of value undef");

$res = $data ~~ dpath '/normal/normal/goal';
cmp_bag($res, [ 15 ], "absolute path - leaf with value");

$res = $data ~~ dpath '/zero/goal';
cmp_bag($res, [ 0 ], "absolute path - leaf of value 0");

done_testing();
