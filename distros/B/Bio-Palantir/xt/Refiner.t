#!/usr/bin/env perl
    
use Test::Most;

use autodie;
use feature qw(say);

use List::AllUtils;
use Path::Class qw(file);

use Bio::Palantir;

my $class = 'Bio::Palantir::Refiner::ClusterPlus';

{

    # open and parse antiSMASH report in XML format
    my $infile = file('xtest', 'Refiner_nrps_biosynML.xml');  # Aphanomyces astaci prot report
    
    ok my $report = Bio::Palantir::Refiner->new( file => $infile ), 'Refiner constructor';

    my @nrps_clusters = grep { $_->type eq 'nrps' } $report->all_clusters;
    
    # skip clusters 1, 3 and 5 because clusters 2 and 4 are more interesting and sufficient for testing
    my $ClusterPlus1 = $nrps_clusters[2];
    isa_ok $ClusterPlus1, $class;

    my @expected_domain_sizes = [
        483, 68, 415, 483, 68, 415,
    ];

    my @expected_domain_subtypes = [
        'Khayatt_ref_phe_1', 'NULL', 'Condensation_DCL',
        'Khayatt_ref_phe_1', 'NULL', 'Condensation_DCL',
    ];
    
    my @expected_domain_evalues = [
        5e-111, 3.2e-23, 1e-32,
        5e-111, 3.2e-23, 1.1e-32,
    ];

    my @expected_domain_bitscores = [
        363.1, 73.9, 105.1,
        363.1, 73.9, 105.1,
    ];
    
    my (@domain_sizes, @domain_subtypes, @domain_evalues, @domain_bitscores);
    for my $gene ($ClusterPlus1->all_genes) {
        push @domain_sizes,     $_->size     for $gene->all_domains;
        push @domain_subtypes,  $_->subtype  for $gene->all_domains;
        push @domain_evalues,   $_->evalue   for $gene->all_domains;
        push @domain_bitscores, $_->score    for $gene->all_domains;
    }

    # elongate coordinates - handle_overlaps - refine_coordinates
    cmp_deeply \@domain_sizes, @expected_domain_sizes,
        'got expected elongated sizes for NRPS DomainPlus objects - Coordinates methods test';

    cmp_deeply \@domain_subtypes, @expected_domain_subtypes,
        'got expected subtypes for NRPS DomainPlus objects - Subtyping method test';

    cmp_deeply \@domain_evalues, @expected_domain_evalues,
        'got expected (appropriate) evalues for DomainPlus objects - Hmmer report parsing test';

    # Test for domain subtyping method
    cmp_deeply \@domain_bitscores, @expected_domain_bitscores,
        'got expected (appropriate) bitscores for DomainPlus objects - Hmmer report parsing test';


    my @expected_modules = [
        'A-PCP', 'C-A-PCP-C',
    ];

    # test for Modules building in Modulable role
    my @modules;
    for my $module ($ClusterPlus1->all_modules) {
        push @modules, join '-', map { $_->function } $module->all_domains;
    }
    
    cmp_deeply \@modules, @expected_modules,
        'got expected domain architecture for NRPS Module objects - Modulable build method test';

    # TODO find a better example: here additional detection of a 900aa domain in the gene following the cluster...
    # Test additional domain detection
    my $ClusterPlus2 = $nrps_clusters[3];

    my @expected_domain_symbols = [
        'AT', 'PCP', 'C', 'A', 'PCP', 
        'C', 'A', 'A', 'PCP', 'C', 
        'C', 'A', 'PCP', 'A',
    ];

    my @expected_domain_classes = [
        'substrate-selection', 'carrier-protein', 'condensation', 
        'substrate-selection', 'carrier-protein', 'condensation',
        'substrate-selection', 'substrate-selection', 'carrier-protein',
        'condensation', 'condensation', 'substrate-selection',
        'carrier-protein', 'substrate-selection',
    ];

    my $domain_n;
    $domain_n += $_->count_domains for $ClusterPlus2->all_genes;

    my (@domain_symbols, @domain_classes);
    for my $gene ($ClusterPlus2->all_genes) {
        push @domain_symbols, $_->symbol for $gene->all_domains;
        push @domain_classes, $_->class  for $gene->all_domains;
    }

    cmp_ok $domain_n, '==', 14,
        'got expected number of predicted domains - Filling gaps method test';

    cmp_deeply \@domain_symbols, @expected_domain_symbols,
        'got expected domain symbols for NRPS DomainPlus objects - Domainable symbol method test';

    cmp_deeply \@domain_classes, @expected_domain_classes,
        'got expected domain classes for NRPS DomainPlus objects - GenePlus _get_class method test';

}

{

    # open and parse antiSMASH report in XML format
    my $infile = file('xtest', 'Refiner_pks_biosynML.xml');  # Aphanomyces astaci prot report
    ok my $report = Bio::Palantir::Parser->new( file => $infile ), 'Biosynml constructor';
    
    # get main container
    my $root = $report->root;

    my $ClusterPlus = $class->new( _cluster => $root->all_clusters);
    isa_ok $ClusterPlus, $class;
    
    my @expected_domain_sizes = [
        437, 417, 179, 226, 309, 173,
    ];

    my @expected_domain_subtypes = [
        'Iterative-KS', 'MOMC_1', 'NULL',
        'cMT', 'NULL', 'NULL',
    ];
    
    my (@domain_sizes, @domain_subtypes, @domain_evalues, @domain_bitscores);
    for my $gene ($ClusterPlus->all_genes) {
        push @domain_sizes,     $_->size     for $gene->all_domains;
        push @domain_subtypes,  $_->subtype  for $gene->all_domains;
    }

    # elongate coordinates - handle_overlaps - refine_coordinates
    cmp_deeply \@domain_sizes, @expected_domain_sizes,
        'got expected elongated sizes for PKS DomainPlus objects - Coordinates methods test';

    cmp_deeply \@domain_subtypes, @expected_domain_subtypes,
        'got expected subtypes for PKS DomainPlus objects - Subtyping method test';


    my @expected_modules = ['KS-AT-DH-MT-ER-KR'];

    my @expected_module_coordinates = [2, 2246];

    # test for Modules building in Modulable role
    my (@modules, @module_coordinates);
    for my $module ($ClusterPlus->all_modules) {
        push @modules, join '-',  @{ $module->get_domain_functions };
        push @module_coordinates, @{ $module->genomic_prot_coordinates };
    }

    cmp_deeply \@modules, @expected_modules,
        'got expected domain architecture for PKS Module objects - Modulable build and get_domain_functions methods test';

    cmp_deeply \@module_coordinates, @expected_module_coordinates,
        'got expected module coordinates for PKS Module objects - Modulable build method test';

    my @expected_domain_symbols = [
        'KS', 'AT', 'DH', 'MT', 'ER', 'KR',
    ];

    my @expected_domain_classes = [
        'condensation', 'substrate-selection', 
        'tailoring/other', 'tailoring/other', 'tailoring/other', 
        'tailoring/other',
    ];

    my (@domain_symbols, @domain_classes);
    for my $gene ($ClusterPlus->all_genes) {
        push @domain_symbols, $_->symbol for $gene->all_domains;
        push @domain_classes, $_->class  for $gene->all_domains;
    }

    cmp_deeply \@domain_symbols, @expected_domain_symbols,
        'got expected domain symbols for PKS DomainPlus objects - Domainable symbol method test';

    cmp_deeply \@domain_classes, @expected_domain_classes,
        'got expected domain classes for PKS DomainPlus objects - GenePlus _get_class method test';

}

{

    # open and parse antiSMASH report in JS format
    my $infile = file('xtest', 'Refiner_pks_regions.js');  # cyano GCF_000317025.1
    
    # get main container
    ok my $report = Bio::Palantir::Parser->new( file => $infile ), 'JS constructor';
    my $root = $report->root;
    my $ClusterPlus = $class->new( _cluster => $root->all_clusters ); 

    my @expected_exploratory_domain_symbols = [
        'CAL_domain', 'ACP', 'KS', 'AT',
        'KR', 'KR', 'ACP', 'Te'
    ];

    my @expected_exploratory_domain_coordinates = [
        '38-485', '605-677', '704-1120', '1130-1570',
        '1629-1813', '1866-2045', '2143-2216', '2585-2842'
    ];
   
    my (@exploratory_domain_symbols, @exploratory_domain_coordinates);
    for my $gene ($ClusterPlus->all_genes) {

        next unless $gene->all_domains;

        push @exploratory_domain_symbols, $_->symbol for $gene->all_exp_domains;
        push @exploratory_domain_coordinates, $_->begin . '-' . $_->end for $gene->all_exp_domains;
    }

    cmp_deeply \@exploratory_domain_symbols, @expected_exploratory_domain_symbols,
        'got expected exploratory domain symbols for PKS DomainPlus objects - Fillable _detect_domains filter & Domainable symbol method test';

    cmp_deeply \@exploratory_domain_coordinates, @expected_exploratory_domain_coordinates,
        'got expected exploratory domain coordinates for PKS DomainPlus objects - Fillable _detect_domains coordinates method';

}

done_testing;

