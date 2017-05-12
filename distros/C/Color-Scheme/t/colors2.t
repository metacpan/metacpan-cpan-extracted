#!perl
use strict;
use warnings;

use Test::More tests => 15;
use Color::Scheme;

use t::lib::ColorTest;

{
    my $scheme = Color::Scheme->new;

    color_test( [ $scheme->colors ],
        [ 'ff9900', 'b36b00', 'ffe6bf', 'ffcc80' ], 'simple' );

    $scheme->from_hex('ff0000');
    color_test(
        [ $scheme->colors ],
        [ 'ff0000', 'b30000', 'ffbfbf', 'ff8080' ],
        'red hex'
    );

    $scheme->from_hue(230);
    color_test(
        [ $scheme->colors ],
        [ '0074ff', '0051b3', 'bfdcff', '80b9ff' ],
        'set hue to 230'
    );

    $scheme->scheme('analogic');
    color_test(
        [ $scheme->colors ],
        [   '0074ff', '0051b3', 'bfdcff', '80b9ff', '331aff', '2412b3',
            'ccc6ff', '998cff', '00ffb3', '00b37d', 'bfffec', '80ffd9'
        ],
        'analog scheme'
    );

    $scheme->distance(0.3);
    color_test(
        [ $scheme->colors ],
        [   '0074ff', '0051b3', 'bfdcff', '80b9ff', '1132ff', '0c23b3',
            'c4ccff', '8898ff', '00efff', '00a7b3', 'bffbff', '80f7ff'
        ],
        'tweak distance'
    );

    $scheme->add_complement(1);
    color_test(
        [ $scheme->colors ],
        [   '0074ff', '0051b3', 'bfdcff', '80b9ff', '1132ff', '0c23b3',
            'c4ccff', '8898ff', '00efff', '00a7b3', 'bffbff', '80f7ff',
            'ff8800', 'b35f00', 'ffe1bf', 'ffc480'
        ],
        'add complement'
    );

    $scheme->variation('pale');
    color_test(
        [ $scheme->colors ],
        [   '8e969e', '737980', 'e6f1ff', 'acb5bf', '9395a3', '747580',
            'e7eaff', 'adb0bf', '778384', '737f80', 'e6fdff', 'acbebf',
            'd9cfc3', '807a73', 'fff3e6', 'bfb6ac'
        ],
        'pale variation'
    );

    $scheme->web_safe(1);
    color_test(
        [ $scheme->colors ],
        [   '999999', '666699', 'ffffff', '99cccc', '999999', '666699',
            'ffffff', '9999cc', '669999', '666699', 'ffffff', '99cccc',
            'cccccc', '996666', 'ffffff', 'cccc99'
        ],
        'web safe'
    );
}

{
    my $scheme = Color::Scheme->new;
    $scheme->from_hue(15);

    $scheme->scheme('contrast');
    color_test(
        [ $scheme->colors ],
        [   'ff3300', 'b32400', 'ffccbf', 'ff9980',
            '00b366', '007d48', 'bfffe4', '80ffc9'
        ],
        'compl'
    );

    $scheme->scheme('triade');
    color_test(
        [ $scheme->colors ],
        [   'ff3300', 'b32400', 'ffccbf', 'ff9980', '33ff00', '24b300',
            'ccffbf', '99ff80', '0066b3', '00487d', 'bfe4ff', '80c9ff'
        ],
        'triad'
    );

    $scheme->scheme('tetrade');
    color_test(
        [ $scheme->colors ],
        [   'ff3300', 'b32400', 'ffccbf', 'ff9980', '00b366', '007d48',
            'bfffe4', '80ffc9', '0033cc', '00248f', 'bfcfff', '809fff',
            'ff9900', 'b36b00', 'ffe6bf', 'ffcc80'
        ],
        'tetrad'
    );

    $scheme->variation('pastel');
    color_test(
        [ $scheme->colors ],
        [   'e68a73', '804d40', 'e6d3cf', 'bf4d30', '50a17e', '408064',
            'cfe6dc', '30bf82', '5c73b8', '405080', 'cfd4e6', '3054bf',
            'e6b873', '806640', 'e6dccf', 'bf8630'
        ],
        'pastel'
    );

    $scheme->variation('soft');
    color_test(
        [ $scheme->colors ],
        [   'cc9b8f', '806159', 'e6d3cf', 'bf7360', '648f7d', '59806f',
            'cfe6dc', '60bf96', '727ea3', '596380', 'cfd4e6', '6078bf',
            'ccb48f', '807059', 'e6dccf', 'bf9960'
        ],
        'soft'
    );

    $scheme->variation('light');
    color_test(
        [ $scheme->colors ],
        [   'ffccbf', 'bf7360', 'ffebe6', 'ff9980', 'bfffe4', '60bf96',
            'e6fff4', '80ffc9', 'bfcfff', '6078bf', 'e6ecff', '809fff',
            'ffe6bf', 'bf9960', 'fff5e6', 'ffcc80'
        ],
        'light'
    );

    $scheme->variation('hard');
    color_test(
        [ $scheme->colors ],
        [   'ff3300', '991f00', 'ffebe6', 'ff8566', '00b366', '006b3d',
            'e6fff4', '66ffbe', '0033cc', '001f7a', 'e6ecff', '668cff',
            'ff9900', '995c00', 'fff5e6', 'ffc266'
        ],
        'hard'
    );
}

