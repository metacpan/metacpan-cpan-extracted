use strict;
use warnings;
use Test::More;

use App::Fasops::Common;

{
    print "#trim_pure_dash\n";

    my @data = (
        [   [   qw{ AAAATTTTTG
                    AAAATTTTTG
                    AAAATTTTTG }
            ],
            10,
        ],
        [   [   qw{ -AA--TTTGG
                    -AA--TTTGG
                    -AA--TTTTG }
            ],
            7,
        ],
        [   [   qw{ -AA--TTTGG
                    -AAA-TTTGG
                    AAA--TTTTG }
            ],
            9,
        ],
    );

    for my $i ( 0 .. $#data ) {
        my ( $seq_refs, $except ) = @{ $data[$i] };

        App::Fasops::Common::trim_pure_dash($seq_refs);
        my $result = length $seq_refs->[0];
        is( $result, $except, "trim_pure_dash $i" );
    }
}

{
    print "#trim_outgroup\n";

    my @data = (
        [   [   qw{ AAAATTTTTG
                    AAAATTTTTG
                    AAAATTTTTG }
            ],
            10,
        ],
        [   [   qw{ -AA--TTTGG
                    -AA--TTTGG
                    -AA--TTTTG }
            ],
            7,
        ],
        [   [   qw{ -AA--TTTGG
                    -AAA-TTTGG
                    AAA--TTTTG }
            ],
            9,
        ],
        [   [   qw{ AAA--TT-GG
                    AAAATTT-GG
                    AAA--TTTTG }
            ],
            9,
        ],
        [   [   qw{ -AA--TT-GG
                    -AAA-TT-GG
                    AAA--TTTTG }
            ],
            8,
        ],
    );

    for my $i ( 0 .. $#data ) {
        my ( $seq_refs, $except ) = @{ $data[$i] };

        App::Fasops::Common::trim_outgroup($seq_refs);
        my $result = length $seq_refs->[0];
        is( $result, $except, "trim_outgroup $i" );
    }
}

{
    print "#trim_complex_indel\n";

    my @data = (
        [   [   qw{ AAAATTTTTG
                    AAAATTTTTG
                    AAAATTTTTG }
            ],
            10, "-",
        ],
        [   [   qw{ -AA--TTTGG
                    -AA--TTTGG
                    -AA--TTTTG }
            ],
            7, "-",
        ],
        [   [   qw{ -AA--TTTGG
                    -AAA-TTTGG
                    AAA--TTTTG }
            ],
            8, "3",
        ],
        [   [   qw{ AAA--TT-GG
                    AAAATTT-GG
                    AAA--TTTTG }
            ],
            9, "-",
        ],
        [   [   qw{ -AA--TT-GG
                    -AAA-TT-GG
                    AAA--TTTTG }
            ],
            7, "3",
        ],
        [   [   qw{ -AA--TTTGG
                    -AAA-TT-GG
                    AAA--TTTTG }
            ],
            8, "3",
        ],
    );

    for my $i ( 0 .. $#data ) {
        my ( $seq_refs, $except, $except_complex ) = @{ $data[$i] };

        App::Fasops::Common::trim_outgroup($seq_refs);
        my $complex = App::Fasops::Common::trim_complex_indel($seq_refs);

        my $result = length $seq_refs->[0];
        is( $result, $except, "trim_complex_indel count $i" );
        is( $complex, $except_complex, "trim_complex_indel runlist $i" );
    }
}

done_testing();
