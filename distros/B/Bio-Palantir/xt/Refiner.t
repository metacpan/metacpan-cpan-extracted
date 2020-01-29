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
    
    ok my $report = Bio::Palantir::Refiner->new(
            file => $infile,
            module_delineation => 'condensation'
        ), 'Refiner constructor'
    ;

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
        'got expected elongated sizes for NRPS DomainPlus objects'
        . ' - Coordinates methods test';

    cmp_deeply \@domain_subtypes, @expected_domain_subtypes,
        'got expected subtypes for NRPS DomainPlus objects'
        . ' - Subtyping method test';

    cmp_deeply \@domain_evalues, @expected_domain_evalues,
        'got expected (appropriate) evalues for DomainPlus objects'
        . ' - Hmmer report parsing test';

    # Test for domain subtyping method
    cmp_deeply \@domain_bitscores, @expected_domain_bitscores,
        'got expected (appropriate) bitscores for DomainPlus objects'
        . ' - Hmmer report parsing test';


    my @expected_components = [
        'A-PCP', 'C-A-PCP-C',
    ];

    # test for Components building in Modulable role
    my @components;
    for my $component ($ClusterPlus1->all_components) {
        push @components, join '-', map { $_->function } $component->all_domains;
    }

    my @expected_modules = [
        'A-PCP', 'C-A-PCP-C',
    ];
    
    my @modules;
    for my $module($ClusterPlus1->all_modules) {
        push @modules, join '-', map {$_->function } $module->all_domains;
    }

    my $report2 = Bio::Palantir::Refiner->new( 
        file => $infile , 
        module_delineation => 'substrate-selection',
    );
    my @nrps_clusters2 = grep { $_->type eq 'nrps' } $report2->all_clusters;
    
    my @expected_components2 = [
        'A-PCP-C', 'A-PCP-C',
    ];
    
    my @components2;
    for my $module ($nrps_clusters2[2]->all_components) {
        push @components2, join '-', map { $_->function } $module->all_domains;
    }

    my @expected_modules2 = [
        'A-PCP-C', 'A-PCP-C',        
    ];
    my @modules2;
    for my $module($nrps_clusters2[2]->all_modules) {
        push @modules2, join '-', map {$_->function } $module->all_domains;
    }
    
    cmp_deeply \@components, @expected_components,
        'got expected domain architecture for NRPS Component objects'
        . ' - \'condensation\' component delineation (Modulable build method) test';
    
    cmp_deeply \@components2, @expected_components2,
        'got expected domain architecture for NRPS Component objects'
        . ' - \'selection\' component delineation (Modulable build method) test';
    
    cmp_deeply \@modules, @expected_modules,
        'got expected domain architecture for NRPS Module objects'
        . ' - \'condensation\' component delineation (Modulable build method) test';
    
    cmp_deeply \@modules2, @expected_modules2,
        'got expected domain architecture for NRPS Module objects'
        . ' - \'selection\' component delineation (Modulable build method) test';

    # TODO find a better example: here additional detection of a 900aa domain in the gene following the cluster...
    # Test additional domain detection
    my $ClusterPlus2 = $nrps_clusters[3];

    my @expected_domain_symbols = [
        'AT', 'PCP', 'C', 'A', 'PCP', 
        'C', 'A', 'A', 'PCP', 'C', 
        'A', 'C', 'A', 'PCP',
    ];

    my @expected_domain_classes = [
        'substrate-selection', 'carrier-protein', 'condensation', 
        'substrate-selection', 'carrier-protein', 'condensation',
        'substrate-selection', 'substrate-selection', 'carrier-protein',
        'condensation', 'substrate-selection', 'condensation', 
         'substrate-selection', 'carrier-protein',
    ];

    my @expected_domain_coordinates = [
        [1, 399], [396, 463], [490, 924], [929, 1415], [1427, 1494],
        [1525, 1957], [1951, 2437], [2355, 2843], [2855, 2922], [2954, 3391],
        [3399, 3768], [3770, 4201], [4202, 4685], [4697, 4766],
    ];

    my $domain_n;
    $domain_n += $_->count_domains for $ClusterPlus2->all_genes;

    my (@domain_symbols, @domain_classes, @domain_coordinates);
    for my $gene ($ClusterPlus2->all_genes) {
        push @domain_symbols, $_->symbol for $gene->all_domains;
        push @domain_classes, $_->class  for $gene->all_domains;
        push @domain_coordinates, $_->coordinates for $gene->all_domains;
    }

    cmp_ok $domain_n, '==', 14,
        'got expected number of predicted domains'
        . ' - Filling gaps method test';

    cmp_deeply \@domain_symbols, @expected_domain_symbols,
        'got expected domain symbols for NRPS DomainPlus objects'
        . ' - Domainable symbol method test';

    cmp_deeply \@domain_classes, @expected_domain_classes,
        'got expected domain classes for NRPS DomainPlus objects'
        . ' - GenePlus _get_class method test';
    
    cmp_deeply \@domain_coordinates, @expected_domain_coordinates,
        'got expected domain coordinates for NRPS DomainPlus objects'
        . ' - Fillable role method test';

}

{

    # open and parse antiSMASH report in XML format
    my $infile = file('xtest', 'Refiner_pks_biosynML.xml');  # Aphanomyces astaci prot report
    ok my $report = Bio::Palantir::Parser->new( file => $infile ),
        'Biosynml constructor';
    
    # get main container
    my $root = $report->root;

    my $ClusterPlus = $class->new( 
        _cluster => $root->all_clusters,
        module_delineation => 'condensation',
    );

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
        'got expected elongated sizes for PKS DomainPlus objects' 
        . ' - Coordinates methods test';

    cmp_deeply \@domain_subtypes, @expected_domain_subtypes,
        'got expected subtypes for PKS DomainPlus objects'
        . ' - Subtyping method test';


    my @expected_components = ['KS-AT-DH-MT-ER-KR'];

    my @expected_component_coordinates = [2, 2246];

    # test for Modules building in Modulable role
    my (@components, @component_coordinates);
    for my $component ($ClusterPlus->all_components) {
        push @components, join '-',  @{ $component->get_domain_functions };
        push @component_coordinates, @{ $component->genomic_prot_coordinates };
    }

    cmp_deeply \@components, @expected_components,
        'got expected domain architecture for PKS Component objects'
        . ' - Modulable build and get_domain_functions methods test';

    cmp_deeply \@component_coordinates, @expected_component_coordinates,
        'got expected module coordinates for PKS Component objects'
        . ' - Modulable build method test';

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
        'got expected domain symbols for PKS DomainPlus objects'
        . ' - Domainable symbol method test';

    cmp_deeply \@domain_classes, @expected_domain_classes,
        'got expected domain classes for PKS DomainPlus objects'
        . ' - GenePlus _get_class method test';

}

{

    # open and parse antiSMASH report in JS format
    my $infile = file('xtest', 'Refiner_pks_regions.js');  # cyano GCF_000317025.1
    
    # get main container
    ok my $report = Bio::Palantir::Parser->new( file => $infile ),
        'JS constructor';

    my $root = $report->root;
    my $ClusterPlus = $class->new( _cluster => $root->all_clusters ); 

    my @expected_exploratory_domain_symbols = [
        'CAL_domain', 'ACP', 'KS', 'PCP', 'AT', 'DHt',
        'TE', 'DHt', 'TE', 'KR', 'ACP', 'AT', 'TE', 'PCP',
    ];

    my @expected_exploratory_domain_coordinates = [
        '38-485', '605-677', '704-1120', '825-911', '1130-1548',
        '1168-1405', '1261-1490', '1491-1730', '1799-2027', '1866-2045',
        '2143-2216', '2454-2821', '2585-2842', '2629-2699'
    ];
   
    my (@exploratory_domain_symbols, @exploratory_domain_coordinates);
    for my $gene ($ClusterPlus->all_genes) {

        next unless $gene->all_domains;

        push @exploratory_domain_symbols, $_->symbol for $gene->all_exp_domains;
        push @exploratory_domain_coordinates, $_->begin . '-' . $_->end for $gene->all_exp_domains;
    }

    cmp_deeply \@exploratory_domain_symbols, @expected_exploratory_domain_symbols,
        'got expected exploratory domain symbols for PKS DomainPlus objects'
        . ' - Fillable _detect_domains filter & Domainable symbol method test';

    cmp_deeply \@exploratory_domain_coordinates, @expected_exploratory_domain_coordinates,
        'got expected exploratory domain coordinates for PKS DomainPlus objects'
        . ' - Fillable _detect_domains coordinates method';

}

done_testing;

