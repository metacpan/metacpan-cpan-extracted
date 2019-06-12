#!/usr/bin/env perl

use Test::Most;

use autodie;
use feature qw(say);

use List::AllUtils;
use Path::Class qw(file);

use Bio::Palantir;

my $class = 'Bio::Palantir::Parser';

{
    # open and parse biosynML report in XML format
    my $infile = file('test', 'Parser_biosynML.xml');
    ok my $report = $class->new( file => $infile ), 'Biosynml constructor';
    isa_ok $report, $class, $infile;

    # get main container
    my $root = $report->root;

    # Root tests
    cmp_ok $root->count_clusters, '==', 6,
        'got expected number of Cluster objects';
    cmp_ok $root->count_genes, '==', 79,
        'got expected number of Gene objects';
    cmp_ok $root->count_domains, '==', 15,
        'got expected number of Domain objects';
    cmp_ok $root->count_motifs, '==', 21,
        'got expected number of Motif objects';

    my @expected_cluster_sizes = [
        44351, 20979, 42254,
        43943, 10574, 44966
    ];

    my @expected_gene_sizes = [
        1149, 156,  1119, 5040,
        2211, 2253, 804,  4350,
        1578, 3594, 1899, 759,
        903,  753,  2670, 1524,
        1650, 2238, 366,  978,
        381,  1047, 750,  4230,
        7203, 483,  4821, 645,
        2445, 2253, 870,  1326,
        2364, 699,  180,  489,
        2505, 1077, 2430, 1032,
        984,  594,  651,  834,
        1044, 612,  1287, 1122,
        1428, 3942, 3210, 1797,
        2541, 5295, 801,  2430,
        2322, 1119, 798,  573,
        1425, 1548, 246,  2208,
        522,  1908, 2295, 3369,
        1722, 4965, 1665, 363,
        1113, 576,  432,  375,
        888,  2673, 4056
    ];

    my @cluster_sizes;
    my @gene_sizes;

    for my $cluster ($root->all_clusters) {
        push @cluster_sizes, $cluster->genomic_dna_size;
    }

    while (my $gene = $root->next_gene) {
        my $location = $gene->locations;
        push @gene_sizes, $gene->genomic_dna_size;
    }


    cmp_deeply \@gene_sizes, @expected_gene_sizes,
        'got expected sizes for the gene list of Root objects';

    cmp_deeply \@cluster_sizes, @expected_cluster_sizes,
        'got expected sizes for the clusters of Root objects';


    # Cluster tests
    my $cluster_types = [
        'nrps', 'terpene',
        'other', 'other',
        'ectoine', 'other'
    ];

    cmp_deeply [ map { $_->type } $root->all_clusters ], $cluster_types,
        'got expected types for Cluster objects';

    my $cluster = $root->next_cluster;

    cmp_ok $cluster->count_genes, '==', 15,
        'got expected gene count';


    # Gene/Domain/Motif tests
    my @expected_gene_coordinates = [
        2769787, 2770935, 2771936, 2772091,
        2773092, 2774210, 2775211, 2780250,
        2781251, 2783461, 2784462, 2786714,
        2787715, 2788518, 2789519, 2793868,
        2794869, 2796446, 2797447, 2801040,
        2802041, 2803939, 2804940, 2805698,
        2806699, 2807601, 2808602, 2809354,
        2810355, 2813024,
    ];

    my @expected_orphan_motif_types = ['BiosynML motif'];


    my @expected_gene_bgc_domains = [
        'Condensation_LCL (123-437). E-value: 3.1e-75. Score: 244.6;',
        'AMP-binding (636-1047). E-value: 1.1e-90. Score: 295.7; NRPS/PKS Domain: EPrPV000_810_A1; Substrate specificity predictions: phe,trp,phg,tyr,bht (NRPSPredictor2 SVM), asn (Stachelhaus code), arg (Minowa), nrp (consensus);',
        'PCP (1141-1209). E-value: 6.3e-11. Score: 34.0;',
        'Thioesterase (1254-1397). E-value: 3e-11. Score: 35.7;',
        'Aminotran_1_2 (13-367). E-value: 1.6e-45. Score: 147.3;'
    ];

    my @expected_gene_locus_tags = [map { 'EPrPV000_' . $_ } 803..817];

    my @expected_gene_bgc_monomers = ['nrp'];

    my @expected_domain_functions = [
        'C', 'A', 'PCP', 'TE', 'NA',
    ];

    my @expected_domain_monomers = [
        undef, 'nrp', undef, undef, undef,
    ];

    my @expected_domain_protein_sequences = [
        'RFPLSYAQQQMYALYQMQPESTAYNITRAVRISTSAFELSKLETACRALLSKHEALRSLFVVDDITGEPRQVVMSIGQCRQPIVQVLEWTREQGEYRDDEAMAAFLTATTSVPFDLVQDIPVRFIAVASPDGSSMMSWTLVVILHHIVTDGASSVIVWNDLLAMYASPHLELSPVSGTVVNYRDYAVWQRERVESGVIEPTIAYWCRQFAGEDSPTPVLSLPFDYPTTRSPHHEGQGDVITFTASSDALTRMTTLCGAQGCSLYMGLLSVFYMLLSRLSGSSDIVIGTPTSGRDRVELEHIVGYFVNTLALRIH',
        'SYQQLWDASGRVAHALHSLKRTGDGQLRVGLLTSRGFESAAAIIGALRARAVFVPLDAAFPAARLAYMVQDSAVHAIVSQRRHASIVQALLPPAGDVQVLLYEDLSAEPGDVLATLHADDMPVYILYTSGSTGKPKGVVVTHSNLLSTIQWTVRTYAVGPGSVFLQSTSTTLDGSLTQLLSPLMSGGAVVITKDGGLQDLAYIGGLLSTVSFCVFVPSYLSLLIEFLAVLPPAVRHVVVVGEAFSMELARKFYRKFESSSACLVNEYGPTEAAVTSTSFFLSRNRVLDLELDTVPIGTPIDDHYAVVLDTHKQLVPVNVPGELYVGGRGVATGYWRRPELSAAAFSHPEVEQLTGGATSKWYRTGDIVKWLPTGHLVFLGRADAQVKLNGLRVELNEVRNELMRHESVRDA',
        'ALVEIWTQVLELEDEQVDWKTQSFVALGGDSLAAIRAISLARTRGISLAVDTFFRCHSVDEMAILASS',
        'TSTTPESVEHLADKYWAAIQRWTATLPASPIVLGGFSFGCRVAHAIARLAVRAGRALYPLTLLDGVPFYLDDGSEGVDDADEVSDFADTFCISGANMGEDETALVAQVAAQFRAHCAIEGAYRPQQREDDVRIAATLFKTDRW',
        'EMINFKVGQPAPDMLPLDKIRASAALKFAESDPMFLQYGHLKGYPKFRESLAGFLTKGYGHEVDPEKLFITNGVTGGLALVCSLFLKSGDLVFMEEPTYFLALSIMKDFKINVRQVPMQEDGLDVDALEKLLAKGVVPKMLYTIPTCHNPTGRTLSPAKRAKLVDLSVKYNFTIVADEVYQLLSFPHVTPPPPMFTFDKHGTVLALGSFSKILAPALRLGWIQASPKLLKPITDCGQLDSSGGINPVVQGIVHAAISSGAQQEHLEWTTKTLWQRADALMKELKARLPEGVTFEVPDGGYFVLVRLPEHMNAADLLPIAQEHKVMFLPGSSFSESMKNYLRLSFSWYDYHELEL',
    ];

    my @expected_motif_counts = [
        4, 3, 0, 1, 0
    ];

    my @expected_motif_names = [
        'C2_LCL_024-062', 'C3_LCL_132-143',
        'C4_LCL_164-176', 'C5_LCL_267-296',
        'NRPS-A_a3', 'NRPS-A_a6',
        'NRPS-A_a8', 'NRPS-te1'
    ];

    my @expected_motif_begins = [
        '432',  '798',  '912',
        '1215', '2277', '2853',
        '3039', '3840'
    ];

    my @expected_motif_qualifiers = [
        [
        'note',
        'auto-annotation',
        'genbank',
        'hmmscan'
        ],
        [
        'note',
        'auto-annotation',
        'genbank',
        'hmmscan'
        ],
        [
        'note',
        'auto-annotation',
        'genbank',
        'hmmscan'
        ],
        [
        'note',
        'auto-annotation',
        'genbank',
        'hmmscan'
        ],
        [
        'note',
        'auto-annotation',
        'genbank',
        'hmmscan'
        ],
        [
        'note',
        'auto-annotation',
        'genbank',
        'hmmscan'
        ],
        [
        'note',
        'auto-annotation',
        'genbank',
        'hmmscan'
        ],
        [
        'note',
        'auto-annotation',
        'genbank',
        'hmmscan'
        ]
    ];

    my @expected_motif_details = [
        'C2_LCL_024-062 (e-value: 2e-06; bit-score: 20.2)', 
        'C3_LCL_132-143 (e-value: 6.8e-07; bit-score: 21.9)',
        'C4_LCL_164-176 (e-value: 5e-05; bit-score: 15.9)',
        'C5_LCL_267-296 (e-value: 3.9e-16; bit-score: 51.4)',
        'NRPS-A_a3 (e-value: 4.9e-10; bit-score: 31.3)',
        'NRPS-A_a6 (e-value: 1.4e-14; bit-score: 46.2)',
        'NRPS-A_a8 (e-value: 2.8e-08; bit-score: 26.1)',
        'NRPS-te1 (e-value: 1.2e-06; bit-score: 21.0)'
    ];


    my @gene_coordinates;
    my @orphan_motif_types;
    my @gene_bgc_domains;
    my @gene_locus_tags;
    my @gene_bgc_monomers;
    my @domain_functions;
    my @domain_monomers;
    my @domain_protein_sequences;
    my @motif_counts;
    my @motif_names;
    my @motif_begins;
    my @motif_qualifiers;
    my @motif_details;

    while (my $gene = $cluster->next_gene) {

        push @gene_coordinates, @{ $gene->genomic_dna_coordinates };

        push @gene_bgc_domains, $gene->bgc_domains;
        push @gene_locus_tags, $gene->locus_tag;
        push @gene_bgc_monomers, $gene->monomers;

        map { push @orphan_motif_types, $_->type } $gene->all_orphan_motifs;

        while (my $domain = $gene->next_domain) {

            push @domain_functions, $domain->function;
            push @domain_monomers, $domain->monomer;
            push @motif_counts, $domain->count_motifs;
            push @domain_protein_sequences, $domain->protein_sequence;

            while (my $motif = $domain->next_motif) {

                push @motif_names, $motif->name;

                push @motif_begins, $motif->genomic_dna_begin;

                my $qualifier = $motif->next_qualifier;

                push @motif_qualifiers, [
                    $qualifier->name,
                    $qualifier->ori,
                    $qualifier->style,
                    $qualifier->value
                ];

                push @motif_details, $motif->detail;

            }

        }

    }


    cmp_deeply \@gene_coordinates, @expected_gene_coordinates,
        'got expected coordinates for Gene objects';

    cmp_deeply \@orphan_motif_types, @expected_orphan_motif_types,
        'got expected orphan motif names for Gene objects';

    cmp_deeply \@gene_bgc_domains, @expected_gene_bgc_domains,
        'got expected bgc domains for Gene objects';

    cmp_deeply \@gene_locus_tags, @expected_gene_locus_tags,
        'got expected locus tags for Gene objects';

    cmp_deeply \@gene_bgc_monomers, @expected_gene_bgc_monomers,
        'got expected bgc monomers for Gene objects';

    cmp_deeply \@domain_functions, @expected_domain_functions,
        'got expected functions for Domain objects';
    
    cmp_deeply \@domain_monomers, @expected_domain_monomers,
        'got expected monomers for Domain objects';

    cmp_deeply \@domain_protein_sequences, @expected_domain_protein_sequences,
        'got expected protein sequences for Domain objects';

    cmp_deeply \@motif_counts, @expected_motif_counts,
        'got expected counts for Motif attr';

    cmp_deeply \@motif_names, @expected_motif_names,
        'got expected names for Motif objects';

    cmp_deeply \@motif_begins, @expected_motif_begins,
        'got expected begin locations for Motif objects';

    cmp_deeply \@motif_qualifiers, @expected_motif_qualifiers,
        'got expected qualifiers for Motif object';
    cmp_deeply \@motif_details, @expected_motif_details, 
        'got expected motif details for Motif object';

}

done_testing;

