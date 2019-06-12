#!/usr/bin/env perl
# PODNAME: explore_bgc_domains.pl
# ABSTRACT: This script reports all detected domain signatures for a NRPS/PKS gene cluster without any predefined consensus architecture
# CONTRIBUTOR: Denis BAURAIN <denis.baurain@uliege.be>

use Modern::Perl '2011';
use autodie;

use Smart::Comments;

use Getopt::Euclid qw(:vars);
use JSON::Create qw(create_json);

use aliased 'Bio::Palantir::Explorer::ClusterFasta';

my (%json_for, $i);
for my $file (@ARGV_fasta_files) {

    ### Reading of: $file

    my $cluster = ClusterFasta->new( file => $file );
    
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

            $json_for{'no-taxonomy'}{Clusters}{$i}{GenesPlus}{$gene->rank}{'Do'
            . 'mainsPlus'}{$domain->rank} = {
                rank           => $domain->rank, 
                function       => $domain->symbol, 
                size           => $domain->size, 
                coordinates    => (join '-', @{ $domain->coordinates }), 
                begin          => $domain->begin,
                end            => $domain->end, 
            };
        }
    }
}

print create_json(\%json_for);

__END__

=pod

=head1 NAME

explore_bgc_domains.pl - This script reports all detected domain signatures for a NRPS/PKS gene cluster without any predefined consensus architecture

=head1 VERSION

version 0.191620

=head1 NAME

TODO

=head1 VERSION

This documentation refers to  version 0.0.1

=head1 USAGE

	$0 [options] --fasta [=] <files>...

=head1 REQUIRED ARGUMENTS

=over

=item --fasta[-files] [=] <files>...

Absolute Paths to the fasta files (multiple entries allowed).

=back

=head1 OPTIONS

=over

=item --more

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
