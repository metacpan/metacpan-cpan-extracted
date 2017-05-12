use strict;
use warnings;
use Test::More;

use App::Fasops::Common;
use Test::Number::Delta within => 1e-2;

{
    print "#calc_ld\n";

    my @data = (
        [   [   qw{ 111000
                    111000 }
            ],
            [ 1, 1 ],
        ],
        [   [   qw{ 111000
                    110100 }
            ],
            [ 0.333, 0.333 ],
        ],
        [   [   qw{ 011000
                    001100 }
            ],
            [ 0.25, 0.25 ],
        ],
        [   [   qw{ 11110000
                    11110000 }
            ],
            [ 1, 1 ],
        ],
        [   [   qw{ 11110000
                    00001111 }
            ],
            [ -1, -1 ],
        ],
        [   [   qw{ 11110000
                    11101000 }
            ],
            [ 0.5, 0.5 ],
        ],
        [   [   qw{ 11110000
                    11001100 }
            ],
            [ 0, 0 ],
        ],
        [   [   qw{ 1110000000
                    1111111110 }
            ],
            [ 0.218, 1 ],
        ],
        [   [   qw{ 1111101111
                    1111000001 }
            ],
            [ 0.333, 1 ],
        ],
    );

    for my $i ( 0 .. $#data ) {
        my ( $inputs, $except ) = @{ $data[$i] };

        my @results = App::Fasops::Common::calc_ld( @{$inputs} );
        Test::Number::Delta::delta_ok( $results[0], $except->[0], "calc_ld r $i" );
        Test::Number::Delta::delta_ok( $results[1], $except->[1], "calc_ld dprime $i" );
    }
}

done_testing();
