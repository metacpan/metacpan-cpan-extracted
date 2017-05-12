use strict;
use warnings;
use Test::More;

use App::Fasops::Common;

{
    print "#chr_to_align\n";

    my @data = (
        [   [   qw{ AAAATTTTTG
                    AAAATTTTTG
                    AAAATTTTTG }
            ],
            {   pos        => 4,
                chr_start  => 1,
                chr_strand => "+",
            },
            4,
        ],
        [   [   qw{ AAAATTTTTG
                    AAAATTTTTG
                    AAAATTTTTG }
            ],
            {   pos        => 4,
                chr_start  => 1,
                chr_strand => "-",
            },
            7,
        ],
        [   [   qw{ -AA--TTTGG
                    -AA--TTTGG
                    -AA--TTTTG }
            ],
            {   pos        => 5,
                chr_start  => 1,
                chr_strand => "+",
            },
            8,
        ],
        [   [   qw{ -AA--TTTGG
                    -AA--TTTGG
                    -AA--TTTTG }
            ],
            {   pos        => 5,
                chr_start  => 1,
                chr_strand => "-",
            },
            6,
        ],
        [   [   qw{ -AA--TTTGG
                    -AA--TTTGG
                    -AA--TTTTG }
            ],
            {   pos        => 105,
                chr_start  => 101,
                chr_strand => "+",
            },
            8,
        ],
        [   [   qw{ -AA--TTTGG
                    -AA--TTTGG
                    -AA--TTTTG }
            ],
            {   pos        => 105,
                chr_start  => 101,
                chr_strand => "-",
            },
            6,
        ],
    );

    for my $i ( 0 .. $#data ) {
        my ( $seq_refs, $opt, $except ) = @{ $data[$i] };

        my $intspan = App::Fasops::Common::seq_intspan( $seq_refs->[0] );

        my $result
            = App::Fasops::Common::chr_to_align( $intspan, $opt->{pos}, $opt->{chr_start},
            $opt->{chr_strand} );
        is( $result, $except, "chr_to_align $i" );
    }
}

{
    print "#align_to_chr\n";

    my @data = (

        # 0
        [   [   qw{ AAAATTTTTG
                    AAAATTTTTG
                    AAAATTTTTG }
            ],
            {   pos        => 4,
                chr_start  => 1,
                chr_strand => "+",
            },
            4,
        ],
        [   [   qw{ AAAATTTTTG
                    AAAATTTTTG
                    AAAATTTTTG }
            ],
            {   pos        => 4,
                chr_start  => 1,
                chr_strand => "-",
            },
            7,
        ],

        # 2
        [   [   qw{ AAAATTTTTG
                    AAAATTTTTG
                    AAAATTTTTG }
            ],
            {   pos        => 4,
                chr_start  => 101,
                chr_strand => "+",
            },
            104,
        ],
        [   [   qw{ AAAATTTTTG
                    AAAATTTTTG
                    AAAATTTTTG }
            ],
            {   pos        => 4,
                chr_start  => 101,
                chr_strand => "-",
            },
            107,
        ],

        # 4
        [   [   qw{ -AA--TTTGG
                    -AA--TTTGG
                    -AA--TTTTG }
            ],
            {   pos        => 6,
                chr_start  => 1,
                chr_strand => "+",
            },
            3,
        ],
        [   [   qw{ -AA--TTTGG
                    -AA--TTTGG
                    -AA--TTTTG }
            ],
            {   pos        => 6,
                chr_start  => 1,
                chr_strand => "-",
            },
            5,
        ],

        # 6
        [   [   qw{ -AA--TTTGG
                    -AA--TTTGG
                    -AA--TTTTG }
            ],
            {   pos        => 6,
                chr_start  => 101,
                chr_strand => "+",
            },
            103,
        ],
        [   [   qw{ -AA--TTTGG
                    -AA--TTTGG
                    -AA--TTTTG }
            ],
            {   pos        => 6,
                chr_start  => 101,
                chr_strand => "-",
            },
            105,
        ],

        # 8
        [   [   qw{ -AA--TTTGG
                    -AA--TTTGG
                    -AA--TTTTG }
            ],
            {   pos        => 1,
                chr_start  => 1,
                chr_strand => "+",
            },
            1,
        ],
        [   [   qw{ -AA--TTTGG
                    -AA--TTTGG
                    -AA--TTTTG }
            ],
            {   pos        => 1,
                chr_start  => 1,
                chr_strand => "-",
            },
            7,
        ],

        # 10
        [   [   qw{ AA--TTTGG-
                    AA--TTTGG-
                    AA--TTTTG- }
            ],
            {   pos        => 10,
                chr_start  => 1,
                chr_strand => "+",
            },
            7,
        ],
        [   [   qw{ AA--TTTGG-
                    AA--TTTGG-
                    AA--TTTTG- }
            ],
            {   pos        => 10,
                chr_start  => 1,
                chr_strand => "-",
            },
            1,
        ],

        # 12
        [   [   qw{ -AA--TTTGG
                    -AA--TTTGG
                    -AA--TTTTG }
            ],
            {   pos        => 4,
                chr_start  => 101,
                chr_strand => "+",
            },
            102,
        ],
        [   [   qw{ -AA--TTTGG
                    -AA--TTTGG
                    -AA--TTTTG }
            ],
            {   pos        => 4,
                chr_start  => 101,
                chr_strand => "-",
            },
            106,
        ],
    );

    for my $i ( 0 .. $#data ) {
        my ( $seq_refs, $opt, $except ) = @{ $data[$i] };

        my $intspan = App::Fasops::Common::seq_intspan( $seq_refs->[0] );

        my $result
            = App::Fasops::Common::align_to_chr( $intspan, $opt->{pos}, $opt->{chr_start},
            $opt->{chr_strand} );
        is( $result, $except, "chr_to_align $i" );
    }
}

done_testing();
