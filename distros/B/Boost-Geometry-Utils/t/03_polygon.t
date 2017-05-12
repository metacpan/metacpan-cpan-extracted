#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;
use Boost::Geometry::Utils qw(polygon multi_polygon);

{
    my $p = [
        [  # ccw
            [10,  10],
            [200, 10],
            [200, 200],
            [10,  200],
        ],
        [  # cw
            [14, 14],
            [14, 16],
            [16, 16],
            [16, 14],
        ],
        [  # cw
            [54, 54],
            [54, 56],
            [56, 56],
            [56, 54],
        ],
    ];
    is_deeply Boost::Geometry::Utils::_polygon_arrayref(polygon(@$p)), $p, 'polygon conversion roundtrip';
    is_deeply Boost::Geometry::Utils::_multi_polygon_arrayref(multi_polygon($p)), [$p], 'multi_polygon conversion roundtrip';
}

__END__
