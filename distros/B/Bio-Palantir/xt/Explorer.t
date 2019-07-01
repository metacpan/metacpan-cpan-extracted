#!/usr/bin/env perl
    
use Test::Most;

use autodie;
use feature qw(say);

use List::AllUtils;
use Path::Class qw(file);

use Bio::Palantir;

my $class = 'Bio::Palantir::Explorer::ClusterFasta';

{

    # open and parse FASTA formatted BGC
    my $infile = file('xtest', 'Explorer.fasta');
    
    ok my $report = $class->new( file => $infile ), 'Explorer constructor';

    my @expected_symbols = [
        'A', 'C', 'PCP',
        'Te', 'Te', 'Amt'
    ];

    my @expected_evalues = [
        '3e-103', '1.7e-59', '1.5e-14', 
        '3.5e-11', '2.8', '1.9e-45'
    ];
   
    my @expected_coordinates = [
        [608, 1112], [120, 589], [1140, 1208],
        [1214, 1445], [85, 312], [12, 372]
    ];

    my (@symbols, @evalues, @coordinates);
    for my $gene ($report->all_genes) {

        next unless $gene->all_domains;
        
        push @symbols, $_->symbol for $gene->all_domains;
        push @evalues, $_->evalue for $gene->all_domains;
        push @coordinates, $_->coordinates for $gene->all_domains;
    }

    cmp_deeply \@symbols, @expected_symbols,
        'got expected exploratory domain symbols for NRPS DomainPlus objects - Fillable _detect_domains hmmscan + Domainable symbol method';

    cmp_deeply \@evalues, @expected_evalues,
        'got expected exploratory domain evalues for NRPS DomainPlus objects - Fillable _detect_domains hmmscan method';
    
    cmp_deeply \@coordinates, @expected_coordinates,
        'got expected exploratory domain coordinates for NRPS DomainPlus objects - Fillable _detect_domains coordinates method';

}

done_testing;

