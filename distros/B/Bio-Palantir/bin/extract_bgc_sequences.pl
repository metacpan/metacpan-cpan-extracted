#!/usr/bin/env perl
# PODNAME: extract_bgc_sequences.pl
# ABSTRACT: Extracts protein sequences for different BGC scales into a FASTA file
# CONTRIBUTOR: Denis BAURAIN <denis.baurain@uliege.be>

use Modern::Perl '2011';
use autodie;

use Smart::Comments;

use Carp;
use Getopt::Euclid qw(:vars);

use aliased 'Bio::Palantir::Parser';
use aliased 'Bio::Palantir::Refiner::ClusterPlus';

# check BGC type
if (@ARGV_types) {
    Parser->is_cluster_type_ok(@ARGV_types);
}

# report parsing
my $report = Parser->new( file => $ARGV_report_file );
my $root = $report->root;

my $prefix = $ARGV_prefix ? $ARGV_prefix . '@' : '';

my @clusters
    = $ARGV_annotation eq 'palantir'
    ? map { ClusterPlus->new( _cluster => $_ ) } $root->all_clusters
    : $root->all_clusters
;

open my $out, '>', $ARGV_outfile;

CLUSTER:
for my $cluster (@clusters) {

    if (@ARGV_types) {
        next CLUSTER unless 
            grep { $cluster->type =~ m/$_/xmsi } @ARGV_types;
    }

    if ($ARGV_scale eq 'cluster') {

        my @genes = sort { $a->rank <=> $b->rank } $cluster->all_genes;
    
        say {$out} '>' . $prefix . 'Cluster' . $cluster->rank;
        say {$out} join '', map { $_->protein_sequence } @genes;

    }

    elsif ($ARGV_scale eq 'gene' || $ARGV_scale eq 'domain') {

        for my $gene ( sort { $a->rank <=> $b->rank } $cluster->all_genes) {
            
            my @domains;
            for my $domain (sort { $a->rank <=> $b->rank } $gene->all_domains) {

                if ($ARGV_scale eq 'domain') {
            
                    say {$out} '>' . $prefix . 'Cluster' . $cluster->rank .
                        '_' . 'Gene' . $gene->rank . '_'. $gene->name .
                        '_' . 'Domain' . $domain->rank . '|' . $domain->begin . 
                        '-' . $domain->end . '|' . $domain->symbol;

                    say {$out} $domain->protein_sequence;
                }

                push @domains, $domain->function // 'undef';
            }

            my $domain_set = @domains ? join '-', @domains : 'no_domain';
     
            # write output
            if ($ARGV_scale eq 'gene') {

               say {$out} '>' . $prefix . 'Cluster' . $cluster->rank 
                    . '_' . 'Gene' . $gene->rank . '_' . $gene->name . '|' 
                    . $gene->genomic_prot_begin . '-' . $gene->genomic_prot_end
                    . '|' . $domain_set
                ;

                say {$out} $gene->protein_sequence;
            }
        }
    }

    elsif ($ARGV_scale eq 'module') {
   
        for my $module (sort { $a->rank <=> $b->rank } $cluster->all_modules) {
            
            my @domains;
            for my $domain 
                (sort { $a->rank <=> $b->rank } $module->all_domains) {

                push @domains, $domain->function // 'undef';
            }
            
            my $domain_set = @domains ? join '-', @domains : 'no_domain';

            say {$out} '>' . $prefix . 'Cluster' . $cluster->rank .
                '_' . 'Module' . $module->rank . '|' . $module->begin .
                '-' . $module->end . '|' . $domain_set;

            say {$out} $module->protein_sequence;
        }
    }
}

__END__

=pod

=head1 NAME

extract_bgc_sequences.pl - Extracts protein sequences for different BGC scales into a FASTA file

=head1 VERSION

version 0.191800

=head1 NAME

extract_bgc_sequences.pl - This tool extracts sequences from Palantir 
(or antiSMASH) annotations and returns a FASTA file. The sequences may be 
extracted at different levels: cluster, gene, module and domain.

=head1 USAGE

	$0 [options] --report-file [=] <infile>

=head1 REQUIRED ARGUMENTS

=over

=item --report[-file] [=] <infile>

Path to the output file of antismash, which can be either a 
biosynML.xml (antiSMASH 3-4) or a regions.js file (antiSMASH 5).

=for Euclid: infile.type: readable

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --annotation [=] <str>

BGC annotation to use for extracting sequences. Annotations allowed: palantir 
or antismash [default: palantir]

=for Euclid: str.type: /antismash|palantir/
    str.default: 'palantir'

=item --types [=] <str>...

Filter clusters on a/several specific type(s). 

Types allowed: acyl_amino_acids, amglyccycl, arylpolyene, bacteriocin, 
butyrolactone, cyanobactin, ectoine, hserlactone, indole, ladderane, 
lantipeptide, lassopeptide, microviridin, nrps, nucleoside, oligosaccharide, 
otherks, phenazine, phosphonate, proteusin, PUFA, resorcinol, siderophore, 
t1pks, t2pks, t3pks, terpene.

Any combination of these types, such as nrps-t1pks or t1pks-nrps, is also
allowed. The argument is repeatable.

=item --prefix [=] <str>

Prefix string to use in sequences ids (e.g., if Strain1: >Strain1@Cluster...)

=for Euclid: str.type: str

=item --outfile [=] <filename>

FASTA output filename.

=for Euclid: filename.type: writable
    filename.default: 'bgc_sequences.fasta'

=item --scale [=] <str>

BGC scale from which extracts sequences: cluster, gene, module and domain
[default: gene].

=for Euclid: str.type: /cluster|gene|module|domain/
    str.default: 'gene'

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
