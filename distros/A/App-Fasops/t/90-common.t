use strict;
use warnings;

use Test::More;
use Test::Number::Delta within => 1e-2;

use App::Fasops::Common;

{
    print "#seq_length\n";

    my @data = (
        [qw{ AAAA 4 }], [qw{ CCCC 4 }],
        [qw{ TAGGGATAACAGGGTAAT 18 }],
        [qw{ GCAN--NN--NNTGC 11 }],
    );

    for my $i ( 0 .. @data - 1 ) {
        my ( $ori, $expected ) = @{ $data[$i] };
        my $result = App::Fasops::Common::seq_length($ori);
        is( $result, $expected, "seq_length $i" );
    }
}

{
    print "#revcom\n";

    my @data = (
        [qw{ AAaa ttTT }],
        [qw{ CCCC GGGG }],
        [qw{ TAGGGATAACAGGGTAAT ATTACCCTGTTATCCCTA }],    # I-Sce I endonuclease
        [qw{ GCANNNNNTGC GCANNNNNTGC }],                  # BstAP I
    );

    for my $i ( 0 .. @data - 1 ) {
        my ( $ori, $expected ) = @{ $data[$i] };
        my $result = App::Fasops::Common::revcom($ori);
        is( $result, $expected, "revcom $i" );
    }
}

{
    print "#indel_intspan\n";

    my @data = (
        [ "ATAA",            "-" ],
        [ "CcGc",            "-" ],
        [ "TAGggATaaC",      "-" ],
        [ "C-Gc",            "2" ],
        [ "C--c",            "2-3" ],
        [ "---c",            "1-3" ],
        [ "C---",            "2-4" ],
        [ "GCaN--NN--NNNaC", "5-6,9-10" ],
    );

    for my $i ( 0 .. $#data ) {
        my ( $ori, $expected ) = @{ $data[$i] };
        my $result = App::Fasops::Common::indel_intspan($ori);
        is( $result->runlist, $expected, "indel_intspan $i" );
    }
}

{
    print "#read_fasta\n";

    my $result = App::Fasops::Common::read_fasta("t/example.fa");

    is( scalar keys %{$result}, 4, "seq_count" );
    is( length $result->{ ( keys %{$result} )[0] }, 21, "seq_length" );
    is( length $result->{ ( keys %{$result} )[3] }, 18, "seq_length" );
}

{
    print "#calc_gc_ratio\n";

    my @data = (
        [ "ATAA",            0 ],
        [ "AtaA",            0 ],
        [ "CCGC",            1 ],
        [ "CcGc",            1 ],
        [ "TAGggATaaC",      0.4 ],
        [ "GCaN--NN--NNNaC", 0.6 ],
        [ [ "ATAA", "CCGC" ], 0.5 ],
        [ "AAAATTTTGG",               0.2 ],
        [ "TTAGCCGCTGAGAAGC",         0.5625 ],
        [ "GATTATCATCACCCCAGCCACATW", 0.4783 ],
        [ [qw{ AAAATTTTGG AAAATTTTTG }],                             0.15 ],
        [ [qw{ TTAGCCGCTGAGAAGC GTAGCCGCTGA-AGGC }],                 0.6146 ],
        [ [qw{ GATTATCATCACCCCAGCCACATW GATTTT--TCACTCCATTCGCATA }], 0.4209 ],
    );

    for my $i ( 0 .. $#data ) {
        my ( $ori, $expected ) = @{ $data[$i] };
        my $result = App::Fasops::Common::calc_gc_ratio( ref $ori eq "ARRAY" ? $ori : [$ori] );
        Test::Number::Delta::delta_ok( $result, $expected, "calc_gc_ratio $i" );
    }
}

{
    print "#multi_seq_stat\n";

    #$seq_legnth,            $number_of_comparable_bases,
    #$number_of_identities,  $number_of_differences,
    #$number_of_gaps,        $number_of_n,
    #$number_of_align_error, $D,
    my @data = (

        #                   *
        [   [   qw{ AAAATTTTGG
                    AAAATTTTTG }
            ],
            [ 10, 10, 9, 1, 0, 0, 0, 0.1, ],
        ],

        #           *          * *
        [   [   qw{ TTAGCCGCTGAGAAGC
                    GTAGCCGCTGA-AGGC }
            ],
            [ 16, 15, 13, 2, 1, 0, 0, 0.1333, ],
        ],

        #               * **    *   ** *   *
        [   [   qw{ GATTATCATCACCCCAGCCACATW
                    GATTTT--TCACTCCATTCGCATA }
            ],
            [ 24, 21, 16, 5, 2, 1, 0, 0.2381, ],
        ],
    );

    for my $i ( 0 .. $#data ) {
        my ( $seq_refs, $except_ref ) = @{ $data[$i] };

        my $result_ref = App::Fasops::Common::multi_seq_stat($seq_refs);
        Test::Number::Delta::delta_ok( $result_ref, $except_ref, "stat $i" );
    }
}

{
    print "#ref_pair_D\n";

    my @data = (

        #
        [   [   qw{ AAAATTTTTG
                    AAAATTTTTG
                    AAAATTTTTG }
            ],
            [ 0, 0, 0, ],
        ],

        #
        [   [   qw{ AAAATTTTGG
                    AAAATTTTGG
                    AAAATTTTTG }
            ],
            [ 0, 0, 0, ],
        ],

        #                   *
        [   [   qw{ AAAATTTTGG
                    AAAATTTTTG
                    AAAATTTTTG }
            ],
            [ 0.1, 0, 0, ],
        ],

        #                   *
        [   [   qw{ AAAATTTTTG
                    AAAATTTTGG
                    AAAATTTTTG }
            ],
            [ 0, 0.1, 0, ],
        ],

        #                   *
        [   [   qw{ AAAATTTTGG
                    AAAATTTTAG
                    AAAATTTTTG }
            ],
            [ 0, 0, 0.1, ],
        ],

        #               *   *
        [   [   qw{ AAAATTTTGG
                    AAAAGTTTTG
                    AAAATTTTTG }
            ],
            [ 0.1, 0.1, 0, ],
        ],

        #            *  *   *
        [   [   qw{ AAAATTTTGG
                    ATAAGTTTTG
                    A-AATT-TTG }
            ],
            [ 0.1, 0.1, 0.1, ],
        ],
    );

    for my $i ( 0 .. $#data ) {
        my ( $seq_refs, $except_ref ) = @{ $data[$i] };

        my $result_ref = [ App::Fasops::Common::ref_pair_D($seq_refs) ];
        Test::Number::Delta::delta_ok( $result_ref, $except_ref, "stat $i" );
    }
}

done_testing();
