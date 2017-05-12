use strict;
use warnings;
use Test::More;

use AlignDB::DeltaG;
use Test::Number::Delta within => 1e-2;

{
    print "#calc\n";

    my @data = (
        [   [   qw{ 37
                    1
                    TAACAAGCAATGAGATAGAGAAAGAAATATATCCA }
            ],
            -39.2702,
        ],
        [   [   qw{ 30
                    0.1
                    TAACAAGCAATGAGATAGAGAAAGAAATATATCCA }
            ],
            -35.6605,
        ],
        [   [   qw{ 37
                    1
                    GAATTC }
            ],
            -1.1399,
        ],
    );

    for my $i ( 0 .. $#data ) {
        my ( $inputs, $except ) = @{ $data[$i] };

        my $deltaG = AlignDB::DeltaG->new(
            temperature => $inputs->[0],
            salt_conc   => $inputs->[1],
        );
        my $result = $deltaG->polymer_deltaG( $inputs->[2] );
        Test::Number::Delta::delta_ok( $result, $except, "calc $i" );
    }

}

done_testing();
