use strict;
use warnings;
use Test::More;

use App::Fasops::Common;
use Test::Number::Delta within => 1e-2;

SKIP: {
    skip "poa not installed", 6
        unless IPC::Cmd::can_run('poa');

    print "#poa_consensus\n";

    my @data = (

        #                   *
        [   [   qw{ AAATTTTGG
                    AAAATTTTT }
            ],
            "AAAATTTTGG",
        ],

        #                   *
        [   [   qw{ AAAATTTTGG
                    }
            ],
            "AAAATTTTGG",
        ],

        #                   *
        [   [   qw{ AAAATTTTGG
                    AAAATTTTTG }
            ],
            "AAAATTTTGG",
        ],

        #                      *
        [   [   qw{ TTAGCCGCTGAGAAGC
                    TTAGCCGCTGA-AAGC }
            ],
            "TTAGCCGCTGAGAAGC",
        ],

        #
        [   [   qw{ CCGCTGAGAAGC
                    TTAGCCGCTGAG }
            ],
            "TTAGCCGCTGAGAAGC",
        ],

        #                   *
        [   [   qw{ AAAATTTTGG
                    AAAATTTTTG
                    AAAATTTTTG }
            ],
            "AAAATTTTTG",
        ],
    );

    for my $i ( 0 .. $#data ) {
        my ( $seq_refs, $expect ) = @{ $data[$i] };

        my $result = App::Fasops::Common::poa_consensus($seq_refs);
        is( $result, $expect, "poa $i" );
    }
}

done_testing();
