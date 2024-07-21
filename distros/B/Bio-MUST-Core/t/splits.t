#!/usr/bin/env perl

use Test::Most;

use autodie;
use feature qw(say);

use List::AllUtils qw(pairkeys pairgrep pairmap partition_by sort_by);
use Path::Class qw(file);

use Bio::MUST::Core;

use Smart::Comments;

my $class = 'Bio::MUST::Core::Tree::Splits';

{
    my $infile = "test/lhc-prasino.splits.nex";
    my $splits = $class->load_splits($infile);
    isa_ok $splits, $class, $infile;
    cmp_ok $splits->rep_n, '==', 100, 'got expected rep_n from splits file';
}

{
    my $infile = "test/consense.out";
    my $splits = $class->load_consense($infile);
    isa_ok $splits, $class, $infile;
    cmp_ok $splits->rep_n, '==', 100, 'got expected rep_n from consense file';

    my @exp_supports = (
        [ [ qw(Brachionus Caenorhabd Trichinell Schmidtea)  ], 76 ],
        [ [ qw(Molgula_te Ciona_inte Xenopus_tr Branchiost) ], 62 ],

        # this one requires comp_bp_for
        [ [ qw(Strongyloc Amphimedon Acropora_m Nematostel) ], 61 ],
    );

    my @got_supports = map {
        0 + $splits->clan_support( $splits->ids2key($_->[0]) )
    } @exp_supports;                # 0 + to emulate ==
    is_deeply \@got_supports, [ map { $_->[1] } @exp_supports ],
        'got expected support for clans';
}

{
    my @infiles = (
        'mullidae-well-rooted.tre',
        'mullidae-unrooted.tre',
        'mullidae-unrooted.tpl',
    );

    for my $infile (@infiles) {
        explain $infile;
        clan_tests( file('test', $infile) );
    }
}

sub clan_tests {
    my $infile = shift;

    my $tpl = $infile =~ m/\.tpl\z/xms;
    my $max = $tpl ? 1 : 100;

    my $splits = $class->load_newick($infile);
    isa_ok $splits, $class, $infile;
    cmp_ok $splits->rep_n, '==', $max, 'got expected rep_n from newick file';

    my @exp_clans = map { tr/_/ /r; } qw(
        Mulloidichthys_dentatus
        Mulloidichthys_flavolineatus
        Mullus_auratus
        Parupeneus_barberinoides
        Parupeneus_barberinus
        Parupeneus_chrysopleuron
        Parupeneus_crassilabris
        Parupeneus_cyclostomus
        Parupeneus_forsskali
        Parupeneus_indicus
        Parupeneus_insularis
        Parupeneus_rubescens
        Pseudupeneus_maculatus
        Pseudupeneus_prayensis
        Upeneichthys_lineatus
        Upeneus_japonicus
        Upeneus_oligospilus
        Upeneus_suahelicus
        Upeneus_sundaicus
        Upeneus_tragula
        Upeneus_vittatus
    );

    my $tree = Bio::MUST::Core::Tree->load($infile);
    my %ids_for
        = pairmap { $a => [ sort_by { $_->full_id } @$b ] }
          partition_by { $_->org } $tree->all_seq_ids
    ;
    my @got_clans = pairkeys
        pairgrep { $splits->is_a_clan( $splits->ids2key($b) ) } %ids_for;
    cmp_bag \@got_clans, \@exp_clans, 'got expected org lists being clans';

    my @exp_bp_vals = (
        [ [ qw(Parupeneus_bifasciatus_longo@283070
            Parupeneus_multifasciatus_longo@251257
            Parupeneus_multifasciatus_stiller@384139
            Parupeneus_williamsi_stiller@377438
            Parupeneus_margaritatus_stiller@377536
            Parupeneus_macronemus_nash@343997
            Parupeneus_crassilabris_santa@382724
            Parupeneus_crassilabris_stiller@381739
            Parupeneus_insularis_santa@382832
            Parupeneus_insularis_stiller@380509
            Parupeneus_trifasciatus_stiller@383431
            Parupeneus_rubescens_longo@311644
            Parupeneus_rubescens_stiller@379460
            Parupeneus_spilurus_nash@269596
            Parupeneus_ciliatus_arbor@359765
            Parupeneus_biaculeatus_stiller@383203
            Parupeneus_biaculeatus_arbor@304503
            Parupeneus_forsskali_santa@345830
            Parupeneus_forsskali_stiller@384155
            Parupeneus_margaritatus_nash@317842
            Parupeneus_cyclostomus_longo@144532
            Parupeneus_cyclostomus_1_stiller@381299
            Parupeneus_cyclostomus_2_stiller@379819
            Parupeneus_chrysopleuron_nash@365245
            Parupeneus_chrysopleuron_stiller@378413
            Parupeneus_chrysopleuron_2_arbor@362139
            Parupeneus_chrysopleuron_1_arbor@272471) ], ($tpl ? 1 : 78) ],
        [ [ qw(Upeneus_oligospilus_nash@260328
            Upeneus_oligospilus_2_arbor@353819
            Upeneus_oligospilus_1_arbor@318514
            Upeneus_heemstra_arbor@265512)           ], ($tpl ? 1 : 45) ],
        [ [ qw(Mullus_auratus_1_stiller@381434
            Mullus_auratus_2_stiller@380902)         ], ($tpl ? 1 : 98) ],
    );

    for my $exp_row (@exp_bp_vals) {
        my $key = $splits->ids2key($exp_row->[0]);
        my $val = $splits->clan_support($key);
        cmp_ok $val, '==', $exp_row->[1],
            "got expected clan support from ids: $val";
    }

    my $genus = 'Mulloidichthys';
    my @needle = grep { $_->full_id =~ m/$genus/xms } $tree->all_seq_ids;
    my $key = $splits->ids2key(\@needle);
    ok $splits->is_a_clan($key),
        "got expected clan status for $genus";
    cmp_ok $splits->clan_support($key), '==', $max,
        "got expected BP support for $genus";

    my %exp_bp_val_for = (
        'Mulloidichthys ayliffe_nash@215468,Mulloidichthys dentatus_longo@321198,Mulloidichthys dentatus_nash@368645,Mulloidichthys flavolineatus_santa@382170,Mulloidichthys flavolineatus_stiller@374330,Mulloidichthys martinicus_longo@312721,Mulloidichthys martinicus_stiller@380523,Mulloidichthys vanicolensis_longo@282366,Mulloidichthys vanicolensis_stiller@385444'
            => [ $max, 'Mulloidichthys pfluegeri_arbor@366817' ],
        'Mulloidichthys ayliffe_nash@215468,Mulloidichthys dentatus_longo@321198,Mulloidichthys dentatus_nash@368645,Mulloidichthys martinicus_longo@312721,Mulloidichthys martinicus_stiller@380523,Mulloidichthys vanicolensis_longo@282366'
            => [ $max, 'Mulloidichthys flavolineatus_santa@382170,Mulloidichthys flavolineatus_stiller@374330,Mulloidichthys pfluegeri_arbor@366817,Mulloidichthys vanicolensis_stiller@385444' ],
        'Mulloidichthys dentatus_longo@321198,Mulloidichthys dentatus_nash@368645'
            => [ $max, 'Mulloidichthys ayliffe_nash@215468,Mulloidichthys flavolineatus_santa@382170,Mulloidichthys flavolineatus_stiller@374330,Mulloidichthys martinicus_longo@312721,Mulloidichthys martinicus_stiller@380523,Mulloidichthys pfluegeri_arbor@366817,Mulloidichthys vanicolensis_longo@282366,Mulloidichthys vanicolensis_stiller@385444' ],
        'Mulloidichthys dentatus_longo@321198,Mulloidichthys dentatus_nash@368645,Mulloidichthys martinicus_longo@312721,Mulloidichthys martinicus_stiller@380523,Mulloidichthys vanicolensis_longo@282366'
            => [ $max, 'Mulloidichthys ayliffe_nash@215468,Mulloidichthys flavolineatus_santa@382170,Mulloidichthys flavolineatus_stiller@374330,Mulloidichthys pfluegeri_arbor@366817,Mulloidichthys vanicolensis_stiller@385444' ],
        'Mulloidichthys flavolineatus_santa@382170,Mulloidichthys flavolineatus_stiller@374330'
            => [ $max, 'Mulloidichthys ayliffe_nash@215468,Mulloidichthys dentatus_longo@321198,Mulloidichthys dentatus_nash@368645,Mulloidichthys martinicus_longo@312721,Mulloidichthys martinicus_stiller@380523,Mulloidichthys pfluegeri_arbor@366817,Mulloidichthys vanicolensis_longo@282366,Mulloidichthys vanicolensis_stiller@385444' ],
        'Mulloidichthys flavolineatus_santa@382170,Mulloidichthys flavolineatus_stiller@374330,Mulloidichthys vanicolensis_stiller@385444'
            => [ $max, 'Mulloidichthys ayliffe_nash@215468,Mulloidichthys dentatus_longo@321198,Mulloidichthys dentatus_nash@368645,Mulloidichthys martinicus_longo@312721,Mulloidichthys martinicus_stiller@380523,Mulloidichthys pfluegeri_arbor@366817,Mulloidichthys vanicolensis_longo@282366' ],
        'Mulloidichthys martinicus_longo@312721,Mulloidichthys martinicus_stiller@380523,Mulloidichthys vanicolensis_longo@282366'
            => [ $max, 'Mulloidichthys ayliffe_nash@215468,Mulloidichthys dentatus_longo@321198,Mulloidichthys dentatus_nash@368645,Mulloidichthys flavolineatus_santa@382170,Mulloidichthys flavolineatus_stiller@374330,Mulloidichthys pfluegeri_arbor@366817,Mulloidichthys vanicolensis_stiller@385444' ],
        'Mulloidichthys martinicus_longo@312721,Mulloidichthys vanicolensis_longo@282366'
            => [ ($tpl ? 1 : 89), 'Mulloidichthys ayliffe_nash@215468,Mulloidichthys dentatus_longo@321198,Mulloidichthys dentatus_nash@368645,Mulloidichthys flavolineatus_santa@382170,Mulloidichthys flavolineatus_stiller@374330,Mulloidichthys martinicus_stiller@380523,Mulloidichthys pfluegeri_arbor@366817,Mulloidichthys vanicolensis_stiller@385444' ],
    );

    my %got_bp_val_for = map {
        ( join ',', sort map { $_->full_id } @{ $splits->key2ids($_) } )
            => [ $splits->clan_support($_), join ',', sort map { $_->full_id }
                @{ $splits->key2ids( $splits->xor_clans($key, $_) ) } ]
    } $splits->sub_clans($key);

    is_deeply \%got_bp_val_for, \%exp_bp_val_for,
        "got expected sub-clans, xor-clans and BP support values for $genus";
}

done_testing;
