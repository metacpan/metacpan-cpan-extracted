#! perl

use Test2::V0;

use CXC::Astro::Regions::DS9 -all;

subtest annulus => sub {

    is(
        annulus(
            center => [ 10, 20 ],
            inner  => 2,
            outer  => 3,
            n      => 20,
        )->render,
        'annulus 10 20 2 3 n=20',
        'n',
    );

    is(
        annulus(
            center => [ 10, 20 ],
            annuli => [ 2,  3, 4, 5 ],
        )->render,
        'annulus 10 20 2 3 4 5',
        'annuli',
    );

};


subtest box => sub {

    is(
        box(
            center => [ 10, 20 ],
            width  => '2p',
            height => '3d',
        )->render,
        'box 10 20 2p 3d',
        'default, no angle',
    );

    is(
        box(
            center => [ 10, 20 ],
            width  => '2p',
            height => '3d',
            fill   => 1,
        )->render,
        'box 10 20 2p 3d # fill=1',
        'default, no angle, fill',
    );

    is(
        box(
            center => [ 10, 20 ],
            width  => '2p',
            height => '3d',
            angle  => 33,
        )->render,
        'box 10 20 2p 3d 33',
        'plain, angle',
    );

    is(
        box(
            center => [ 10, 20 ],
            inner  => [ 2,  3 ],
            outer  => [ 4,  5 ],
            n      => 20,
        )->render,
        'box 10 20 2 3 4 5 n=20',
        'n, no angle',
    );

    is(
        box(
            center => [ 10, 20 ],
            inner  => [ 2,  3 ],
            outer  => [ 4,  5 ],
            n      => 20,
            angle  => 99,
        )->render,
        'box 10 20 2 3 4 5 n=20 99',
        'n, angle',
    );

    is(
        box(
            center => [ 10,       20 ],
            annuli => [ [ 2, 3 ], [ 4, 5 ] ],
        )->render,
        'box 10 20 2 3 4 5',
        'annuli, no angle',
    );

    is(
        box(
            center => [ 10,       20 ],
            annuli => [ [ 2, 3 ], [ 4, 5 ] ],
            angle  => 99,
        )->render,
        'box 10 20 2 3 4 5 99',
        'annuli, angle',
    );

};

subtest compass => sub {

    is(
        compass(
            center => [ 10, 20 ],
            length => 30,
        )->render,
        'compass 10 20 30 # compass=physical {N} {E} 1 1',
        'default',
    );

    subtest label => sub {
        is(
            compass(
                center => [ 10, 20 ],
                length => 30,
                north  => 'North',
            )->render,
            'compass 10 20 30 # compass=physical {North} {E} 1 1',
            'north',
        );

        is(
            compass(
                center => [ 10, 20 ],
                length => 30,
                east   => 'East',
            )->render,
            'compass 10 20 30 # compass=physical {N} {East} 1 1',
            'east',
        );

        is(
            compass(
                center => [ 10, 20 ],
                length => 30,
                north  => 'North',
                east   => 'East',
            )->render,
            'compass 10 20 30 # compass=physical {North} {East} 1 1',
            'both',
        );

    };

    subtest arrows => sub {
        is(
            compass(
                center => [ 10, 20 ],
                length => 30,
                arrows => [ split q{ }, $_ ],
            )->render,
            "compass 10 20 30 # compass=physical {N} {E} $_",
            $_,
        ) for '0 0', '0 1', '1 0', '1 1';
    };

};


subtest ellipse => sub {

    is(
        ellipse(
            center => [ 10, 20 ],
            rx     => '2p',
            ry     => '3d',
        )->render,
        'ellipse 10 20 2p 3d',
        'default',
    );

    is(
        ellipse(
            center => [ 10, 20 ],
            rx     => '2p',
            ry     => '3d',
            fill   => 1,
        )->render,
        'ellipse 10 20 2p 3d # fill=1',
        'default, fill',
    );

    is(
        ellipse(
            center => [ 10, 20 ],
            rx     => '2p',
            ry     => '3d',
            angle  => 33,
        )->render,
        'ellipse 10 20 2p 3d 33',
        'default, angle',
    );

    is(
        ellipse(
            center => [ 10, 20 ],
            inner  => [ 2,  3 ],
            outer  => [ 4,  5 ],
            n      => 20,
        )->render,
        'ellipse 10 20 2 3 4 5 n=20',
        'n, no angle',
    );

    is(
        ellipse(
            center => [ 10, 20 ],
            inner  => [ 2,  3 ],
            outer  => [ 4,  5 ],
            n      => 20,
            angle  => 99,
        )->render,
        'ellipse 10 20 2 3 4 5 n=20 99',
        'n, angle',
    );

    is(
        ellipse(
            center => [ 10,       20 ],
            annuli => [ [ 2, 3 ], [ 4, 5 ] ],
        )->render,
        'ellipse 10 20 2 3 4 5',
        'annuli, no angle',
    );

    is(
        ellipse(
            center => [ 10,       20 ],
            annuli => [ [ 2, 3 ], [ 4, 5 ] ],
            angle  => 99,
        )->render,
        'ellipse 10 20 2 3 4 5 99',
        'annuli, angle',
    );

};

subtest line => sub {

    is(
        line(
            v1 => [ 0,  0 ],
            v2 => [ 10, 10 ],
        )->render,
        'line 0 0 10 10',
        'default',
    );

    is(
        line(
            v1     => [ 0,  0 ],
            v2     => [ 10, 10 ],
            arrows => [ 0,  0 ],
        )->render,
        'line 0 0 10 10 # line= 0 0',
        'no arrows',
    );

};

subtest polygon => sub {

    is(
        polygon(
            vertices => [ [ 0, 0 ], [ 10, 10 ], [ 10, 0 ], ],
        )->render,
        'polygon 0 0 10 10 10 0',
        'default',
    );

    is(
        polygon(
            vertices => [ [ 0, 0 ], [ 10, 10 ], [ 10, 0 ], ],
            fill     => 1,
        )->render,
        'polygon 0 0 10 10 10 0 # fill=1',
        'fill',
    );
};

subtest point => sub {

    is(
        point(
            position => [ 0, 1 ],
        )->render,
        'point 0 1',
        'default',
    );

    is(
        point(
            position => [ 0, 1 ],
            symbol   => $_,
            size     => 22,
        )->render,
        "point 0 1 # point=$_ 22",
        "type $_, size 22",
    ) for qw( circle box diamond cross x arrow boxcircle);
};

subtest projection => sub {

    is(
        projection(
            v1    => [ 0,  0 ],
            v2    => [ 10, 10 ],
            width => '22p',
        )->render,
        'projection 0 0 10 10 22p',
    );

};

subtest ruler => sub {

    is(
        ruler(
            v1 => [ 0,  0 ],
            v2 => [ 10, 10 ],
        )->render,
        'ruler 0 0 10 10',
        'default',
    );

    is(
        ruler(
            v1     => [ 0,  0 ],
            v2     => [ 10, 10 ],
            coords => $_,
        )->render,
        "ruler 0 0 10 10 # ruler=$_",
        "coords $_",
    ) for qw( pixels degrees arcmin arcsec );
};

subtest text => sub {

    is(
        text(
            position => [ 0, 0 ],
            text     => 'foo',
        )->render,
        'text 0 0 {foo}',
    );

};

subtest vector => sub {

    is(
        vector(
            base   => [ 10, 10 ],
            length => '22i',
            angle  => 33,
        )->render,
        'vector 10 10 22i 33',
        'default',
    );

    is(
        vector(
            base   => [ 10, 10 ],
            length => '22i',
            angle  => 33,
            arrow  => !!0,
        )->render,
        'vector 10 10 22i 33 # vector=0',
        'no arrow',
    );

};

subtest panda => sub {

    is(
        panda(
            center  => [ 12, 34 ],
            angles  => [ 10, 30 ],
            nangles => 10,
            inner   => 20,
            outer   => 30,
            nannuli => 5,
        )->render,
        'panda 12 34 10 30 10 20 30 5',
        'default',
    );
};

subtest epanda => sub {

    is(
        epanda(
            center  => [ 12, 34 ],
            angles  => [ 10, 30 ],
            nangles => 10,
            inner   => [ 20, 30 ],
            outer   => [ 40, 50 ],
            nannuli => 5,
        )->render,
        'epanda 12 34 10 30 10 20 30 40 50 5',
        'default',
    );

    is(
        epanda(
            center  => [ 12, 34 ],
            angles  => [ 10, 30 ],
            nangles => 10,
            inner   => [ 20, 30 ],
            outer   => [ 40, 50 ],
            nannuli => 5,
            angle   => 232,
        )->render,
        'epanda 12 34 10 30 10 20 30 40 50 5 232',
        'angle',
    );


};

subtest bpanda => sub {

    is(
        bpanda(
            center  => [ 12, 34 ],
            angles  => [ 10, 30 ],
            nangles => 10,
            inner   => [ 20, 30 ],
            outer   => [ 40, 50 ],
            nannuli => 5,
        )->render,
        'bpanda 12 34 10 30 10 20 30 40 50 5',
        'default',
    );

    is(
        bpanda(
            center  => [ 12, 34 ],
            angles  => [ 10, 30 ],
            nangles => 10,
            inner   => [ 20, 30 ],
            outer   => [ 40, 50 ],
            nannuli => 5,
            angle   => 232,
        )->render,
        'bpanda 12 34 10 30 10 20 30 40 50 5 232',
        'angle',
    );

};

subtest composite => sub {

    my $point = point( position => [ 0, 5 ] );

    is(
        composite( center => [ 4096, 4096 ], regions => [$point] )->render,
        array {
            item '# composite 4096 4096';
            item 'point 0 5';
            end;
        },
        'default',
    );
    is(
        composite( center => [ 4096, 4096 ], regions => [$point], angle => 320 )->render,
        array {
            item '# composite 4096 4096 320';
            item 'point 0 5';
            end;
        },
        'angle',
    );

};


done_testing;


