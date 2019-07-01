package Bio::Palantir;
# ABSTRACT: core classes and utilities for Bio::Palantir 
# CONTRIBUTOR: Denis BAURAIN <denis.baurain@uliege.be>
$Bio::Palantir::VERSION = '0.191800';
use strict; use warnings;

use Bio::Palantir::Parser; use Bio::Palantir::Refiner; use
Bio::Palantir::Explorer;

1;

__END__

=pod

=head1 NAME

Bio::Palantir - core classes and utilities for Bio::Palantir 

=head1 VERSION

version 0.191800

=head1 SYNOPSIS

    use Bio::Palantir;

    # open and parse biosynML.xml or regions.js antiSMASH report
    my $infile = 'biosynML.xml'; 
    my $report = Bio::Palantir::Parser->new( file => $infile );

    # get main container
    my $root = $report->root;

    # explore Biosynthetic Gene Clusters (BGCs) content
    
    # Bio::Palantir::Parser
    for my $cluster ($root->all_clusters) {     # returns all clusters say
        $cluster->type;                         # returns the cluster type (e.g., nrps)
        
        for my $gene ($cluster->all_genes) {        # returns all genes say
            $gene->name;                            # for instance, returns the gene name say $gene->genomic_coordinates;     # returns DNA gene coordinates (relative to the genome) 
            say $gene->coordinates;                 # returns protein gene coordinates (also relative to the genome) 
            say $gene->protein_sequence;              # returns the gene protein sequence 
    
            # if the BGC possess domains (i.e., NRPS/PKS)
            for my $domain ($gene->all_domains) {   # returns all domains
            
                say $domain->rank;                  # for instance, returns the domain in the gene 
                say $domain->function;              # returns the domain function (e.g., condensation) 
                say join '-', $domain->coordinates; # returns the coordinates (which are relative to the gene ones)
                say $domain->protein_sequence;      # returns the domain protein sequence

                # lowest level is Motifs (for antiSMASH 3 and 4)
                for my $motif ($domain->all_motifs) {
                    #...
                } 
            }

        # same way for looping into Module objects 
        for my $module ($cluster->all_modules) {
            # ...
        }
    }


    # Bio::Palantir::Refiner
    use aliased 'Bio::Palantir::Refiner';
    use aliased 'Bio::Palantir::Refiner::ClusterPus';
    
    # it is possible to create Bio::Palantir::Refiner objects from already existing Bio::Palantir::Parser ones
    my @cluster_plus;
    
    for my $cluster ($root->all_clusters) { 
        push @cluster_plus, ClusterPlus->new( _cluster => $cluster ); 
    }

    # but if you intend to use the Refiner part, it is more convenient to create the Refiner object directly from a file
    my $report = Refiner->new( file => biosynML.xml);

    for my $cluster_plus ($report->all_clusters) {
        
        say $cluster_plus->type;

        for my $gene_plus ($cluster_plus->all_genes) {

            say $gene_plus->name;

            for my $domain_plus ($gene_plus->all_domains) {
                
                say 'Palantir version:'; 
                say $domain_plus->function; 
                say $domain_plus->coordinates; 
                say $domain_plus->evalue;
                
                # compare with antiSMASH results
                say 'antiSMASH version:'; say $domain_plus->_domain->function;
                say $domain_plus->_domain->coordinates;
                # say $domain_plus->evalue; # only available for Palantir part

            } 

        }

    }


    # Bio::Palantir::Explorer
    use aliased 'Bio::Palantir::Explorer::ClusterFasta';
    
    # from a Bio::Palantir::Refiner object
    for my $cluster_plus ($report->all_clusters) {
        
        for my $gene_plus ($report->all_genes) {

            for my $domain_exp ($gene_plus->all_exp_domains) {

                say $domain_exp->function; 
                say $domain_exp->coordinates; 
                say $domain_exp->evalue;

            }

        }

    }

    # from a FASTA file (containing ONLY one BGC, each sequence being interpreted as a gene from the cluster)
    my $cluster_exp = ClusterFasta->new( fasta => nrps_bgc.fasta );

    for my $gene_exp ($cluster_exp->all_genes) {

        for my $domain_exp ($gene_exp->all_domains) {
                
                say $domain_exp->function; 
                say $domain_exp->coordinates; 
                say $domain_exp->evalue;

        }

    }

=head1 DESCRIPTION

This distribution is the base of the C<Bio::Palantir> module collection designed
as a toolbox for handling the  post-processing of antiSMASH report data
(L<https://antismash.secondarymetabolites.org>) and improving in some aspects
its annotation of NRPS/PKS Biosynthetic Gene Clusters (BGCs), aiming then to
support small and large-scale genome mining projects.

The B<Palantir libraries> are organized as follows: 

C<Bio::Palantir::Parser> contains classes for hierarchically storing the
information of antiSMASH gene clusters.

C<Bio::Palantir::Refiner> consists in classes (parallel to Parser) dedicated to
the improvement of NRPS/PKS gene clusters parallel classes to
Bio::Palantir::Parser.

C<Bio::Palantir::Explorer> contains classes (also parallel to Parser) giving
access to an exploratory version of detected domains

More information on their internal structure can be found in their respective
file.

Here is the list of functionalities offered by Palantir libraries and bins:

Refinement of NRPS/PKS BGC annotations

- B<Dynamic elongation of the coordinates of  core domains>: enrich the
information contained in the sequences (application examples: improved
similarity searches and evolutionary approaches)

- B<Filling the gaps in BGC annotation>: retrieve missed domains from exceptions
in the rules detection (application example: resolution of ambiguous or
incoherent BGC annotation)

- B<Module delimitation>: apply biological rules to group domains in modules
(application example: analyses at module scale)

- B<BGC visualization>: visualize and compare antismash and Palantir annotations
[bin/draw_clusters.pl]

- B<Exploratory mode visualization>: visualize and design the domain
architecture consensus from a raw view of all detected signatures (application
example: manual curation of the domaine architecture consensus)

BGC data manipulation

- B<Generation of PDF/Word reports>: export customizable reports of refined BGC
data (application example: manual reading of numerous (filtered) BGC data)

- B<Extraction of sequences>: export Fasta files from BGC data at different
scales: cluster, gene, module, domain (application example: data formatting for
downstream analyses)

- B<Generation of SQL tables>: export SQL tables containing  BGC data details
(application example: large-scale queries and statistics)

=head1 AUTHOR

Loic MEUNIER <lmeunier@uliege.be>

=head1 CONTRIBUTOR

=for stopwords Denis BAURAIN

Denis BAURAIN <denis.baurain@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by University of Liege / Unit of Eukaryotic Phylogenomics / Loic MEUNIER and Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
