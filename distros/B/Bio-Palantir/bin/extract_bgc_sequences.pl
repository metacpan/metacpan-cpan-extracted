#!/usr/bin/env perl
# PODNAME: extract_bgc_sequences.pl
# ABSTRACT: This script extracts protein sequences at several gene cluster levels and generates a FASTA file in output
# COAUTHOR: Denis BAURAIN <denis.baurain@uliege.be>

use Modern::Perl '2011';
use autodie;

use Smart::Comments;

use Getopt::Euclid qw(:vars);

use aliased 'Bio::Palantir::Parser';
use aliased 'Bio::Palantir::Refiner::ClusterPlus';


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

    next CLUSTER unless lc $cluster->type eq $ARGV_type;

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

extract_bgc_sequences.pl - This script extracts protein sequences at several gene cluster levels and generates a FASTA file in output

=head1 VERSION

version 0.191620

=head1 NAME

extract_bgc_sequences.pl - This tool extracts sequences from Palantir (or antiSMASH) annotations and returns a FASTA file. The sequences may be extracted at different levels: 

=head1 VERSION

This documentation refers to  version 0.0.1

=head1 USAGE

	$0 [options] --paths <biosynml_path> --taxdir <dir> 	

=head1 REQUIRED ARGUMENTS

=over

=item --report[-file] [=] <infile>

Path to the output file of antismash, which can be either the 
biosynML.xml file (antiSMASH 3-4) or the regions.js (antiSMASH 5).

=for Euclid: infile.type: readable

=item --type [=] <str>

Filter cluster on a specific type. For instance: nrps, t1pks, t2pks, t3pks, nrps-t1pks, t1pks-nrps,...

=for Euclid: str.type: str

=back

=head1 OPTIONS

=over

=item --annotation [=] <str>

BGC annotation to use for extracting sequences. Annotations allowed: palantir 
or antismash [default: palantir]

=for Euclid: str.type: /antismash|palantir/
    str.default: 'palantir'

=item --prefix [=] <str>

Prefix string to use in sequences ids (e.g., if Strain1: >Strain1@Cluster...)

=for Euclid: str.type: str

=item --outfile [=] <outfile>

FASTA output filename.

=for Euclid: outfile.default: 'bgc_sequences.fasta'

=item --scale [=] <str>

Sequence scale to write in fasta: cluster, gene. 

=for Euclid: str.type: /cluster|gene|module|domain/
    str.default: 'gene'

=item --more

=item --version

=item --usage

=item --help

=item --man

print the usual program information

=back

=head1 AUTHOR

=head1 COPYRIGHT

=head1 AUTHOR

Loic MEUNIER <lmeunier@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by University of Liege / Unit of Eukaryotic Phylogenomics / Loic MEUNIER and Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
