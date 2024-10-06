#! perl

use Test2::V0 '!field';

use CXC::Astro::Regions::CIAO -all;

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
        'default',
    );

};


subtest box => sub {

    is(
        box(
            center => [ 10, 20 ],
            width  => q{2'},
            height => '3d',
        )->render,
        q{box(10,20,2',3d)},
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
        'circle',
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

subtest field => sub {

    is( field()->render, 'field()', 'default', );
};

subtest pie => sub {

    is(
        pie(
            center => [ 10, 20 ],
            radii  => [ 30, 40 ],
            angles => [ 50, 60 ],
        )->render,
        'pie(10,20,30,40,50,60)',
        'default',
    );
};


subtest point => sub {

    is(
        point(
            center => [ '0:0:0', '-80:0:0' ],
        )->render,
        q{point(0:0:0,-80:0:0)},
        'default',
    );

};

subtest polygon => sub {

    is(
        polygon(
            vertices => [ [ 0, 0 ], [ 10, 10 ], [ 10, 0 ], ],
        )->render,
        'polygon(0,0,10,10,10,0)',
        'default',
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
        'rectangle(10,11,20,21)',
        'default'
    );
};


subtest region => sub {
    is(
        region(
            file => 'filename',
        )->render,
        'region(filename)',
        'default',
    );
};

subtest rotbox => sub {

    is(
        rotbox(
            center => [ 10, 20 ],
            width  => q{2'},
            height => '3d',
            angle  => 33,
        )->render,
        q{rotbox(10,20,2',3d,33)},
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
        'default',
    );
};

done_testing;
