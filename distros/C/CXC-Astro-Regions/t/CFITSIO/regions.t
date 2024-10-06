#! perl

use Test2::V0 '!field';

use CXC::Astro::Regions::CFITSIO -all;

subtest mkregion => sub {

    is(
        mkregion(
            annulus => center => [ 10, 20 ],
            radii   => [ 2, 3 ],
        )->render,
        'annulus(10,20,2,3)',
    );

};

subtest annulus => sub {

    is(
        annulus(
            center => [ 10, 20 ],
            radii  => [ 2,  3 ],
        )->render,
        'annulus(10,20,2,3)',
    );

};

# Rectangle     ( X1, Y1, X2, Y2, A )       | boundaries considered
# Sector        ( Xc, Yc, Amin, Amax )

subtest box => sub {

    is(
        box(
            center => [ 10, 20 ],
            width  => q{2'},
            height => '3d',
        )->render,
        q{box(10,20,2',3d,0)},
        'no angle',
    );

    is(
        box(
            center => [ 10, 20 ],
            width  => q{2'},
            height => '3d',
            angle  => 33,
        )->render,
        q{box(10,20,2',3d,33)},
        'angle',
    );

};

subtest circle => sub {

    is(
        circle(
            center => [ 10, 20 ],
            radius => 2,
        )->render,
        'circle(10,20,2)',
    );

};

subtest diamond => sub {

    is(
        diamond(
            center => [ 10, 20 ],
            width  => 2,
            height => 3,
        )->render,
        'diamond(10,20,2,3,0)',
        'no angle',
    );

    is(
        diamond(
            center => [ 10, 20 ],
            width  => 2,
            height => 3,
            angle  => 90,
        )->render,
        'diamond(10,20,2,3,90)',
        'no angle',
    );

};

subtest ellipse => sub {

    is(
        ellipse(
            center => [ 10,    20 ],
            radii  => [ q{2'}, '3d' ],
        )->render,
        q{ellipse(10,20,2',3d,0)},
        'no angle',
    );

    is(
        ellipse(
            center => [ 10,    20 ],
            radii  => [ q{2'}, '3d' ],
            angle  => 33,
        )->render,
        q{ellipse(10,20,2',3d,33)},
        'angle',
    );
};

subtest elliptannulus => sub {

    is(
        elliptannulus(
            center => [ 10,    20 ],
            inner  => [ q{2'}, '3d' ],
            outer  => [ q{4'}, '6d' ],
            angles => [ 10,    20 ],
        )->render,
        q{elliptannulus(10,20,2',3d,4',6d,10,20)},
    );
};

subtest line => sub {

    is(
        line(
            'v1' => [ 0,  1 ],
            'v2' => [ 10, 11 ],
        )->render,
        'line(0,1,10,11)',
    );

};

subtest point => sub {

    is(
        point(
            center => [ '0:0:0', '-80:0:0' ],
        )->render,
        q{point(0:0:0,-80:0:0)},
    );

};

subtest polygon => sub {

    is(
        polygon(
            vertices => [ [ 0, 0 ], [ 10, 10 ], [ 10, 0 ], ],
        )->render,
        'polygon(0,0,10,10,10,0)',
    );

};

subtest rectangle => sub {
    is(
        rectangle(
            xmin => 10,
            ymin => 11,
            xmax => 20,
            ymax => 21
        )->render,
        'rectangle(10,11,20,21,0)',
        'no angle',
    );

    is(
        rectangle(
            xmin  => 10,
            ymin  => 11,
            xmax  => 20,
            ymax  => 21,
            angle => 30,
        )->render,
        'rectangle(10,11,20,21,30)',
        'angle',
    );
};

subtest sector => sub {

    is(
        sector(
            center => [ 12, 34 ],
            angles => [ 10, 30 ],
        )->render,
        'sector(12,34,10,30)',
    );
};

done_testing;
