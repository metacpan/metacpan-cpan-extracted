#!/usr/bin/env perl
# PODNAME: explore_bgc_domains.pl
# ABSTRACT: Reports all detected domain signatures for a NRPS/PKS gene cluster
# CONTRIBUTOR: Denis BAURAIN <denis.baurain@uliege.be>

use Modern::Perl '2011';
use autodie;

use Getopt::Euclid qw(:vars);
use JSON::Create qw(create_json);

use aliased 'Bio::Palantir::Explorer::ClusterFasta';

my (%json_for, $i);

my $cluster = ClusterFasta->new( file => $ARGV_fasta_file );
my @lines;

GENE:
for my $gene (sort { $a->rank <=> $b->rank } $cluster->all_genes) {
        
    $json_for{'no-taxonomy'}{Clusters}{++$i}{GenesPlus}{$gene->rank} = {
#                    uui =>  $gene->uui,
       rank => $gene->rank,
       name => $gene->name, 
       size => $gene->size, 
       coordinates => (join '-', @{ $gene->coordinates }), 
       begin => $gene->gene_begin, 
       end => $gene->gene_end, 
    };

    DOMAIN:
    for my $domain (sort { $a->rank <=> $b->rank } $gene->all_domains) {

        my $subtype = $domain->subtype // 'NULL';
        my $subtype_evalue = $domain->subtype_evalue // 'NULL';
        my $subtype_score  = $domain->subtype_score // 'NULL';

        $json_for{'no-taxonomy'}{Clusters}{$i}{GenesPlus}{$gene->rank}{'Do'
        . 'mainsPlus'}{$domain->rank} = {
            rank              => $domain->rank, 
            function          => $domain->symbol, 
            size              => $domain->size, 
            coordinates       => (join '-', @{ $domain->coordinates }), 
            begin             => $domain->begin,
            end               => $domain->end, 
            evalue            => $domain->evalue,
            bit_score         => $domain->score,
            subtype           => $subtype,
            subtype_evalue    => $subtype_evalue,
            subtype_bit_score => $subtype_score,
        };
    
        push @lines, [
            'gene' . $gene->rank, $gene->name, 
            (join '-', @{  $gene->coordinates }), 
            'domain' . $domain->rank, $domain->symbol, 
            (join '-', @{ $domain->coordinates }), $domain->size,
            $domain->evalue, $domain->score, $subtype,
            $subtype_evalue, $subtype_score,
        ];
    }
}

open my $out, '>', $ARGV_outfile . '.json';
say {$out} create_json(\%json_for);

open $out, '>', $ARGV_outfile . '.tsv';
say {$out} join "\t", qw(gene_rank gene_name gene_coordinates domain_rank 
    domain_function domain_coordinates domain size evalue bit_score
    subtype subtype_evalue subtype_bit_score)
;

say {$out} join "\t", @{ $_ } for @lines;

__END__

=pod

=head1 NAME

explore_bgc_domains.pl - Reports all detected domain signatures for a NRPS/PKS gene cluster

=head1 VERSION

version 0.191800

=head1 NAME

explore_bgc_domains.pl - Reports all detected domain signatures for a NRPS/PKS
gene cluster without any predefined consensus architecture. The domain
predictions are reported in TSV and JSON formats.

=head1 USAGE

	$0 [options] --fasta-file [=] <infile>

=head1 REQUIRED ARGUMENTS

=over

=item --fasta[-file] [=] <infile>

Absolute path to a fasta file.

=back

=head1 OPTIONAL ARGUMENTS

=over

=item --outfile <filename>

Output filename to generate TSV and JSON files [default: exploratory_domains].

=for Euclid: filename.type: writable
    filename.default: 'exploratory_domains'

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
