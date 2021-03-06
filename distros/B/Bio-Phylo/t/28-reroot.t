#!/usr/bin/perl
use Test::More 'no_plan';
use Bio::Phylo::IO 'parse';
{

    # rooting below the oldroot shouldn't change the topology
    my $observed = parse(
        '-format' => 'newick',
        '-string' => '((A,B),C)oldroot;',
    )->first;
    my $expected = parse(
        '-format' => 'newick',
        '-string' => '((A,B),C)oldroot;',
    )->first;
    my $new = $observed->get_by_name('oldroot')->set_root_below;
    ok( $expected->calc_symdiff($observed) == 0 );
    ok( not $new );
}
{

    # rooting below node C should not change the topology:
    # the root already is below C.
    my $observed = parse(
        '-format' => 'newick',
        '-string' => '((A,B),C)oldroot;',
    )->first;
    my $expected = parse(
        '-format' => 'newick',
        '-string' => '((A,B),C)oldroot;',
    )->first;
    $observed->get_by_name('C')->set_root_below;
    ok( $expected->calc_symdiff($observed) == 0 );
}
{

    # rooting below A should yield an ingroup of B and C
    my $observed = parse(
        '-format' => 'newick',
        '-string' => '((A,B),C)oldroot;',
    )->first;
    my $expected = parse(
        '-format' => 'newick',
        '-string' => '((B,C),A)root;',
    )->first;
    $observed->get_by_name('A')->set_root_below;
    ok( $expected->calc_symdiff($observed) == 0 );
}
{

    # rooting below the cherry should yield a balanced tree
    my $observed = parse(
        '-format' => 'newick',
        '-string' => '(((A,B)cherry,C),D);',
    )->first;
    my $expected = parse(
        '-format' => 'newick',
        '-string' => '((A,B),(C,D));',
    )->first;
    $observed->get_by_name('cherry')->set_root_below;
    ok( $expected->calc_symdiff($observed) == 0 );
}
{

    # rooting below the cherry should yield a (C,(D,E)) sister clade
    my $observed = parse(
        '-format' => 'newick',
        '-string' => '((((A,B)cherry,C),D),E);',
    )->first;
    my $expected = parse(
        '-format' => 'newick',
        '-string' => '((A,B),(C,(D,E)));',
    )->first;
    $observed->get_by_name('cherry')->set_root_below;
    ok( $expected->calc_symdiff($observed) == 0 );
}
{

    # rooting below the cherry should yield a (C,(D,E)) sister clade
    my $observed = parse(
        '-format' => 'newick',
        '-string' => '((((A,B),C)trichotomy,D),E);',
    )->first;
    my $expected = parse(
        '-format' => 'newick',
        '-string' => '(((A,B),C),(E,D));',
    )->first;
    $observed->get_by_name('trichotomy')->set_root_below;
    ok( $expected->calc_symdiff($observed) == 0 );
}
{
    my $alcids_original_newick =
'(((((((Spheniscus_demersus:0.0122386,Spheniscus_magellanicus:0.0281514):0.00992998,(Spheniscus_mendiculus:0.0044856,Spheniscus_humboldti:0.00513392):0.000918476):0.0758674,((Aptenodytes_patagonicus:0.0395229,Aptenodytes_forsteri:0.0413367):0.0525039,(((Pygoscelis_papua:0.053328,Pygoscelis_antarctica:0.0670684):0.111567,((((Ptychoramphus_aleuticus:0.0598055,((Cyclorrhynchus_psittacula:0.0368713,Aethia_pusilla:0.0303596):0.021893,(Aethia_cristatella:0.107016,Aethia_pygmaea:0.0379153):0.00171834):0.0160819):0.0770928,((Fratercula_cirrhata:0.0239352,(Fratercula_arctica:0.0154299,Fratercula_corniculata:0.0115156):0.0131237):0.00321722,Cerorhinca_monocerata:0.0275042):0.0641515):0.0157952,(((((Synthliboramphus_hypoleucus:0.0121099,Synthliboramphus_craveri:0.000454428):0.0466025,Synthliboramphus_wumizusume:0.0335216):0.0199924,Synthliboramphus_antiquus:0.0142608):0.102925,(Alca_torda:0.0814025,(Alle_alle:0.064224,(Uria_aalge:0.0417948,Uria_lomvia:0.0659216):0.0714624):0.00595617):0.0470138):0.0327099,((Cepphus_grylle:0.0401043,(Cepphus_carbo:0.00891038,Cepphus_columba:0.00603396):0.0445742):0.0410329,(Brachyramphus_marmoratus_perdix:0.106001,(Brachyramphus_marmoratus_marmoratus:0.0601134,Brachyramphus_brevirostris:0.0214747):0.0162047):0.0376546):0.0136459):0.0105428):0.218898,Podiceps_cristatus:0.230433):0.0483009):0.0282993,Pygoscelis_adeliae:0.0893923):0.00728143):0.0178206):0.0098835,Eudyptula_minor:0.108256):0.0522527,Megadyptes_antipodes:0.0382941):0.0384507,((Eudyptes_pachyrhynchus:0.0269359,Eudyptes_chrysocome:0.0250299):0.0099497,Eudyptes_chrysolophus:0.0181502):0.00406632):0.0134722,Eudyptes_sclateri:0.0242986):0; ';
    my $alcids_rerooted_newick =
'(((((Ptychoramphus_aleuticus:0.0598055,((Cyclorrhynchus_psittacula:0.0368713,Aethia_pusilla:0.0303596):0.021893,(Aethia_cristatella:0.107016,Aethia_pygmaea:0.0379153):0.00171834):0.0160819):0.0770928,((Fratercula_cirrhata:0.0239352,(Fratercula_arctica:0.0154299,Fratercula_corniculata:0.0115156):0.0131237):0.00321722,Cerorhinca_monocerata:0.0275042):0.0641515):0.0157952,(((((Synthliboramphus_hypoleucus:0.0121099,Synthliboramphus_craveri:0.000454428):0.0466025,Synthliboramphus_wumizusume:0.0335216):0.0199924,Synthliboramphus_antiquus:0.0142608):0.102925,(Alca_torda:0.0814025,(Alle_alle:0.064224,(Uria_aalge:0.0417948,Uria_lomvia:0.0659216):0.0714624):0.00595617):0.0470138):0.0327099,((Cepphus_grylle:0.0401043,(Cepphus_carbo:0.00891038,Cepphus_columba:0.00603396):0.0445742):0.0410329,(Brachyramphus_marmoratus_perdix:0.106001,(Brachyramphus_marmoratus_marmoratus:0.0601134,Brachyramphus_brevirostris:0.0214747):0.0162047):0.0376546):0.0136459):0.0105428):0.218898,((Pygoscelis_papua:0.053328,Pygoscelis_antarctica:0.0670684):0.111567,(Pygoscelis_adeliae:0.0893923,((Aptenodytes_patagonicus:0.0395229,Aptenodytes_forsteri:0.0413367):0.0525039,(((Spheniscus_demersus:0.0122386,Spheniscus_magellanicus:0.0281514):0.00992998,(Spheniscus_mendiculus:0.0044856,Spheniscus_humboldti:0.00513392):0.000918476):0.0758674,(Eudyptula_minor:0.108256,(Megadyptes_antipodes:0.0382941,(((Eudyptes_pachyrhynchus:0.0269359,Eudyptes_chrysocome:0.0250299):0.0099497,Eudyptes_chrysolophus:0.0181502):0.00406632,Eudyptes_sclateri:0.0377708):0.0384507):0.0522527):0.0098835):0.0178206):0.00728143):0.0282993):0.0483009):0.115216,Podiceps_cristatus:0.115216):0; ';
    my $observed = parse(
        '-format' => 'newick',
        '-string' => $alcids_original_newick,
    )->first;
    my $expected = parse(
        '-format' => 'newick',
        '-string' => $alcids_rerooted_newick,
    )->first;
    $observed->get_by_name('Podiceps_cristatus')->set_root_below;
    ok( $expected->calc_symdiff($observed) == 0 );
}
{
	my $observed = parse(
		'-format' => 'newick',
		'-string' => '((((A:1,B:2)X:3,C:4):5,D:6):7,E:8);',
	)->first;
	my $expected = parse(
		'-format' => 'newick',
		'-string' => '((A:1,B:2):1.5,(C:4,(D:6,E:15):5):1.5)root;',
	)->first;
	$observed->get_by_name('X')->set_root_below('1.5');
	ok( $expected->calc_branch_length_distance($observed) == 0 );
	ok( $expected->calc_symdiff($observed) == 0 );
}
