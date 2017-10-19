#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use App::Anchr::Common;

{
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

        my $result = App::Anchr::Common::poa_consensus($seq_refs);
        is( $result, $expect, "poa $i" );
    }
}

{
    print "#lcss\n";

    my @data = (

        [   [   qw{ ab
                    b }
            ],
            undef,
        ],

        [   [   qw{ abc
                    bc }
            ],
            "bc",
        ],

        [   [   qw{ xyzzx
                    abcxyzefg }
            ],
            "xyz",
        ],

        [   [   qw{ abcxyzzx
                    abcxyzefg }
            ],
            "abcxyz",
        ],

        [   [   qw{ foobar
                    abcxyzefg }
            ],
            undef,
        ],

    );

    for my $i ( 0 .. $#data ) {
        my ( $refs, $expect ) = @{ $data[$i] };

        my $result = App::Anchr::Common::lcss( @{$refs} );
        is( $result, $expect, "lcss $i" );
    }
}

{
    print "#lcss array\n";

    my @data = (

        [   [   qw{ xyzzx
                    abcxyzefg }
            ],
            [qw{xyz 0 3}],
        ],

        [   [   qw{ AbCdefg
                    AbCDef }
            ],
            [qw{AbC 0 0}],
        ],

    );

    for my $i ( 0 .. $#data ) {
        my ( $refs, $expect ) = @{ $data[$i] };

        my @results = App::Anchr::Common::lcss( @{$refs} );
        is_deeply( \@results, $expect, "lcss array $i" );
    }
}

done_testing();
