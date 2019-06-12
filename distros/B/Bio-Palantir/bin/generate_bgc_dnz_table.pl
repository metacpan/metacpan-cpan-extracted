#!/usr/bin/env perl
# PODNAME: generate_bgc_dnz_table.pl
# ABSTRACT: Generates a denormalized table from BGC architectures
# CONTRIBUTOR: Denis BAURAIN <denis.baurain@uliege.be>

use Modern::Perl '2011';
use autodie;

use Smart::Comments;

use File::Basename qw(fileparse);
use Getopt::Euclid qw(:vars);
use Path::Class qw(dir file);

use aliased 'Bio::Palantir::Parser';
use aliased 'Bio::Palantir::Refiner::ClusterPlus';


# report parsing
my $report = Parser->new( file => $ARGV_report_file );
my $root = $report->root;

my @clusters
    = $ARGV_annotation eq 'palantir'
    ? map { ClusterPlus->new( _cluster => $_ ) } $root->all_clusters
    : $root->all_clusters
;

my @lines;
for my $cluster (@clusters) {

    unless ($ARGV_type eq 'none' || lc $cluster->type eq $ARGV_type) {
        next;
    }

    for my $gene ($cluster->all_genes) {

        for my $domain ($gene->all_domains) {

            my $prot_coordinates = $domain->coordinates;
            my $prot_size = $domain->size;

            my $gene_coordinates = $gene->genomic_dna_coordinates;
            my $gene_size = $gene->genomic_dna_size;
            
            my $cluster_coordinates = $cluster->genomic_dna_coordinates;
            my $cluster_size = $cluster->genomic_dna_size;

            push @lines, 
                [ 
                    $ARGV_id // $ARGV_report_file,
                    $root->count_clusters, $root->count_genes,
                    $root->count_domains, $root->count_motifs,
                    $cluster->rank, $cluster->type, @$cluster_coordinates, 
                    $cluster_size, $cluster->count_genes, $gene->count_domains,
                    $gene->rank, $gene->name, @$gene_coordinates, $gene_size,
                    $gene->count_domains, 
                    $domain->rank, $domain->function, $domain->subtype, 
                    @$prot_coordinates, $prot_size, 
                ]
            ;
            
        }
        
    }

}

# Tabular format (denormalized table)
my $tab_outfile = $ARGV_out // 'bgc_output.tsv';

open my $out, '>', $tab_outfile;

say {$out} join "\t", 
    qw( filename
        clusters_tot genes_tot domains_tot motifs_tot
        cluster_rank cluster_type cluster_begin cluster_end 
        cluster_size cluster_genes_count cluster_domains_count 
        gene_rank gene_name gene_begin gene_end gene_size 
        gene_domains_count 
        domain_rank domain_function domain_subtype 
        domain_prot_begin domain_prot_end domain_prot_size
    )
;

for my $line (@lines) {

    say {$out} join "\t", map { $_ eq '' ? 'NA' : $_ } @$line;

}

__END__

=pod

=head1 NAME

generate_bgc_dnz_table.pl - Generates a denormalized table from BGC architectures

=head1 VERSION

version 0.191620

=head1 NAME

generate_bgc_dnz_table.pl - This tool parses and filters biosynthetic gene cluster information from antiSMASH results and resume it in a denormalized table.

=head1 VERSION

This documentation refers to the version 0.0.1

=head1 USAGE

	$0 [options] --path <biosynml_path> --taxdir <dir>

=head1 REQUIRED ARGUMENTS

=over

=item --report[-file] [=] <infile>

Path to the output file of antismash, which can be either the 
biosynML.xml file (antiSMASH 3-4) or the regions.js (antiSMASH 5).

=for Euclid: infile.type: readable

=back

=head1 OPTIONS

=over

=item --annotation [=] <str>

BGC annotation to use for extracting sequences. Annotations allowed: palantir 
or antismash [default: palantir]

=for Euclid: str.type: /antismash|palantir/
    str.default: 'palantir'

=item --out <outfile>

TSV output filename. [default: bgc_output.tsv]

=item --type <str> ...

Filter the report for only a selection of biosynthetic gene cluster types. [default: none]

=for Euclid: str.type: str
    str.default: 'none'

=item --id <str>

ID corresponding to the first column of the table. [default: directory/filename]

=item --version

=item --usage

=item --help

=item --man

print the usual program information

=back

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
