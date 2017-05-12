use strict;
use warnings;

use Test::More;
use Test::Number::Delta within => 1e-2;

use App::Fasops::Common;

{
    print "#get_snps\n";

    my @data = (

        #                   *
        [   [   qw{ AAAATTTTGG
                    AAAATTTTTG }
            ],
            [   {   snp_all_bases   => "GT",
                    snp_mutant_to   => "G<->T",
                    snp_query_base  => "T",
                    snp_freq        => 1,
                    snp_occured     => 10,
                    snp_pos         => 9,
                    snp_target_base => "G",
                },
            ],
        ],

        #           *   **     * *
        [   [   qw{ TTAG--GCTGAGAAGC
                    GTAGCCGCTGA-AGGC }
            ],
            [   {   snp_all_bases   => "TG",
                    snp_mutant_to   => "T<->G",
                    snp_query_base  => "G",
                    snp_freq        => 1,
                    snp_occured     => 10,
                    snp_pos         => 1,
                    snp_target_base => "T",
                },
                {   snp_all_bases   => "AG",
                    snp_mutant_to   => "A<->G",
                    snp_query_base  => "G",
                    snp_freq        => 1,
                    snp_occured     => 10,
                    snp_pos         => 14,
                    snp_target_base => "A",
                },
            ],
        ],
    );

    for my $i ( 0 .. $#data ) {
        my ( $seq_refs, $except_ref ) = @{ $data[$i] };

        my $result_ref = App::Fasops::Common::get_snps($seq_refs);
        is_deeply( $result_ref, $except_ref, "get_snps $i" );
    }
}

{
    print "#polarize_snp\n";

    my @data = (

        #                   *
        [   [   qw{ AAAATTTTGG
                    AAAATTTTAG }
            ],
            "AAAATTTTAG",
            [   {   snp_all_bases     => "GA",
                    snp_mutant_to     => "A->G",
                    snp_outgroup_base => "A",
                    snp_query_base    => "A",
                    snp_freq          => 1,
                    snp_occured       => 10,
                    snp_pos           => 9,
                    snp_target_base   => "G",
                },
            ],
        ],

        #           *   **     * *
        [   [   qw{ TTAG--GCTGAGAAGC
                    GTAGCCGCTGA-AGGC }
            ],
            "TTAGCCGCTGAGAGGC",
            [   {   snp_all_bases     => "TG",
                    snp_mutant_to     => "T->G",
                    snp_outgroup_base => "T",
                    snp_query_base    => "G",
                    snp_freq          => 1,
                    snp_occured       => "01",
                    snp_pos           => 1,
                    snp_target_base   => "T",
                },
                {   snp_all_bases     => "AG",
                    snp_mutant_to     => "G->A",
                    snp_outgroup_base => "G",
                    snp_query_base    => "G",
                    snp_freq          => 1,
                    snp_occured       => 10,
                    snp_pos           => 14,
                    snp_target_base   => "A",
                },
            ],
        ],
    );

    for my $i ( 0 .. $#data ) {
        my ( $seq_refs, $outgroup_seq, $except_ref ) = @{ $data[$i] };

        my $result_ref = App::Fasops::Common::get_snps($seq_refs);
        App::Fasops::Common::polarize_snp( $result_ref, $outgroup_seq );
        is_deeply( $result_ref, $except_ref, "polarize_snp $i" );
    }
}

{
    print "#get_indels\n";

    my @data = (

        #           *   **     * *
        [   [   qw{ TTAG--GCTGAGAAGC
                    GTAGCCGCTGA-AGGC }
            ],
            [   {   indel_all_seqs => "--|CC",
                    indel_end      => 6,
                    indel_freq     => 1,
                    indel_length   => 2,
                    indel_occured  => "10",
                    indel_seq      => "CC",
                    indel_start    => 5,
                    indel_type     => "D",
                },
                {   indel_all_seqs => "G|-",
                    indel_end      => 12,
                    indel_freq     => 1,
                    indel_length   => 1,
                    indel_occured  => "10",
                    indel_seq      => "G",
                    indel_start    => 12,
                    indel_type     => "I",
                },
            ],
        ],
    );

    for my $i ( 0 .. $#data ) {
        my ( $seq_refs, $except_ref ) = @{ $data[$i] };

        my $result_ref = App::Fasops::Common::get_indels($seq_refs);
        is_deeply( $result_ref, $except_ref, "get_indels $i" );
    }
}

#use App::Fasops::Common;
#
#my $seq_refs = ["TTAG--GCTGAGAAGC", "GTAGCCGCTGA-AGGC"];
#my $outgroup_seq = "GTAGCCGCTGA--GGC";
#
#my $sites = App::Fasops::Common::get_indels($seq_refs);
#App::Fasops::Common::polarize_indel( $sites, $outgroup_seq );

{
    print "#polarize_indel\n";

    my @data = (

        #           *   **     * *
        [   [   qw{ TTAG--GCTGAGAAGC
                    GTAGCCGCTGA-AGGC }
            ],
            "GTAGCCGCTGA--GGC",
            [   {   indel_all_seqs     => "--|CC",
                    indel_end          => 6,
                    indel_freq         => 1,
                    indel_length       => 2,
                    indel_occured      => 10,
                    indel_outgroup_seq => "CC",
                    indel_seq          => "CC",
                    indel_start        => 5,
                    indel_type         => "D",
                },
                {   indel_all_seqs     => "G|-",
                    indel_end          => 12,
                    indel_freq         => -1,
                    indel_length       => 1,
                    indel_occured      => "unknown",
                    indel_outgroup_seq => "-",
                    indel_seq          => "G",
                    indel_start        => 12,
                    indel_type         => "C",
                },
            ],
        ],
    );

    for my $i ( 0 .. $#data ) {
        my ( $seq_refs, $outgroup_seq, $except_ref ) = @{ $data[$i] };

        my $result_ref = App::Fasops::Common::get_indels($seq_refs);
        $result_ref = App::Fasops::Common::polarize_indel( $result_ref, $outgroup_seq );
        is_deeply( $result_ref, $except_ref, "polarize_indel $i" );
    }
}

done_testing();
