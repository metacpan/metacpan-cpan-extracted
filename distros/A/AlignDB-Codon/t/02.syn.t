use strict;
use warnings;

use Test::More;

use AlignDB::Codon;

{
    # all synonymous codons
    my @syn_codons = (
        [qw{ TTT TTC }],                    # Phe
        [qw{ TTA TTG CTT CTC CTA CTG }],    # Leu
        [qw{ TCT TCC TCA TCG AGT AGC }],    # Ser
        [qw{ TAT TAC }],                    # Tyr
        [qw{ TAA TAG TGA }],                # ***
        [qw{ TGT TGC }],                    # Cys
        [qw{ TGG }],                        # Trp
        [qw{ CCT CCC CCA CCG }],            # Pro
        [qw{ CAT CAC }],                    # His
        [qw{ CAA CAG }],                    # Gln
        [qw{ CGT CGC CGA CGG AGA AGG}],     # Arg
        [qw{ ATT ATC ATA }],                # Ile
        [qw{ ATG }],                        # Met
        [qw{ ACT ACC ACA ACG }],            # Thr
        [qw{ AAT AAC }],                    # Asn
        [qw{ AAA AAG }],                    # Lys
        [qw{ GTT GTC GTA GTG }],            # Val
        [qw{ GCT GCC GCA GCG }],            # Ala
        [qw{ GAT GAC }],                    # Asp
        [qw{ GAA GAG }],                    # Glu
        [qw{ GGT GGC GGA GGG }],            # Gly
    );

    my $codon_obj = AlignDB::Codon->new( table_id => 1 );
    my $syn_changes = $codon_obj->syn_changes;

    # check all synonymous changes
    for my $syn (@syn_codons) {
        my @codons = @$syn;
        for ( my $i = 0; $i <= $#codons; $i++ ) {
            my $cod1 = $codons[$i];
            for ( my $j = $i + 1; $j <= $#codons; $j++ ) {
                my $cod2 = $codons[$j];

                # check Syn[$cod1-$cod2]
                if ( exists $syn_changes->{$cod1}{$cod2} ) {
                    is( $syn_changes->{$cod1}{$cod2}, 1, "Syn[$cod1-$cod2]" );
                    delete $syn_changes->{$cod1}{$cod2};
                }

                # check Syn[$cod2-$cod1]
                if ( exists $syn_changes->{$cod2}{$cod1} ) {
                    is( $syn_changes->{$cod2}{$cod1}, 1, "Syn[$cod2-$cod1]" );
                    delete $syn_changes->{$cod2}{$cod1};
                }
            }
        }
    }

    # check all non-synonymous changes
    for my $cod1 ( keys %{$syn_changes} ) {
        for my $cod2 ( keys %{ $syn_changes->{$cod1} } ) {
            isnt( $syn_changes->{$cod1}{$cod2}, 1, "Non-Syn[$cod1-$cod2]" );
        }
    }
}

done_testing();
