package Bio::Palantir::Roles::Modulable;
# ABSTRACT: Modulable Moose role for Module object construction
$Bio::Palantir::Roles::Modulable::VERSION = '0.191800';
use Moose::Role;

use autodie;
use feature qw(say); 

use aliased 'Bio::Palantir::Roles::Modulable::Module';

requires 'genes';


has 'modules' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Bio::Palantir::Roles::Modulable::Module]',
    init_arg => undef,
    lazy => 1,
    builder   => '_build_modules',
    handles  => {
         count_modules => 'count',
           all_modules => 'elements',
           get_module  => 'get',
          next_module  => 'shift',        
    },
);

## no critic (ProhibitUnusedPrivateSubroutines)

sub _build_modules {
    my $self = shift;
 
    # process other cluster types
    unless ($self->type =~ m/nrps | pks/xmsi) {
        return [];
    }


    my @genes;
    for my $gene ($self->all_genes) {
        push @genes, $gene
            if $gene->all_domains > 0;
    }

    my $module_n = 0; #TODO move in Cluster.pm
    my %module_for;

    GENE:
    for my $gene_n (0 .. @genes - 1) {

        my @domains = $genes[$gene_n]->all_domains;
        @domains = sort { $a->rank <=> $b->rank } @domains;

        for my $i (0 .. @domains - 1) {

#             next unless $domains[$i]->function; # avoid warnings when antismash domains are undef    

            # initiate first module (ignore C domains)
            if ($module_n == 0 && $i == 0 && $gene_n == 0) {
                $module_n++;
                $module_for{$module_n}{start} = $gene_n;
            }

           
            # define elongation modules
            elsif ( 
                # define modules anchors on C domains (biological sense with communication domains and condensation steps)
                ($domains[$i]->function =~ m/^C$ | ^KS$/xmsi)
                # do not allow modules to be separated by an intermediate gene
                || ( ($genes[$gene_n]->rank
                      - $genes[ $module_for{$module_n}{start} ]->rank) > 1)                
                # avoid auxilliary domains in modules, for instance: if C-A-PCP-TE | AT | A | ACL | ECH assign a different module for last domains
                || (@domains == 1
                    && $domains[$i]->function !~ m/^A$ | ^AT | ^C$ | ^KS | ^PCP$ 
                |      ^ACP$ | KR | DH | ER | cyc | ^TE$ | ^Red$ | ^NAD 
                |       NRPS-COM/xms)
                ) {
                    $module_n++;
                    $module_for{$module_n}{start} = $gene_n;
            }
            
            else {
                # do nothing
            }

            push @{ $module_for{$module_n}{domains} }, $domains[$i];
            $module_for{$module_n}{end} = $gene_n;
        }   
    }

    return [] unless %module_for;

    # put C terminal domain in the termination module
    if ( $module_for{ $module_n }{domains}[0]->function 
        =~ m/^C$ | ^TE$ | ^TD$ | ^Red$ | ^NAD$/xmsi 
        && @{ $module_for{ $module_n}{domains} } 
        == 1 && keys %module_for > 1 ) {

       push @{ $module_for{ $module_n - 1 }{domains} },
           @{ $module_for{ $module_n }{domains} };

       delete $module_for{ $module_n };
    }

    my @modules;
    for my $module_n (sort { $a <=> $b } keys %module_for) {
        
        # create protein sequence of module by domain sequence contatenation
        my $seq;
        for my $domain (@{ $module_for{ $module_n}{domains} }) {
            $seq .= $domain->protein_sequence;
        }

        my $size = length $seq;

        my $start_gene 
            = $genes[ $module_for{$module_n}{start} ]->genomic_prot_begin;

        my $end_gene 
            = $genes[ $module_for{$module_n}{end} ]->genomic_prot_begin;

        my $start_domain = @{ $module_for{$module_n}{domains} }[0]->begin;
        my $end_domain = @{ $module_for{$module_n}{domains} }[-1]->end;

        
        my $genomic_prot_begin = $start_gene + $start_domain;
        my $genomic_prot_end = $end_gene + $end_domain;

        my @gene_uuis 
            = map { $genes[ $_ ]->uui } 
            $module_for{$module_n}{start}..$module_for{$module_n}{end}
        ;

        my $module = Module->new( 
                           rank      => $module_n,
                         domains     => $module_for{$module_n}{domains} // [],
                      gene_uuis      => \@gene_uuis, 
                  genomic_prot_begin => $genomic_prot_begin,
                    genomic_prot_end => $genomic_prot_end,
            genomic_prot_coordinates => [$genomic_prot_begin, 
                                            $genomic_prot_end],
               protein_sequence      => $seq,
        );
    
        push @modules, $module;
    }

    return \@modules;
}

## use critic


no Moose::Role;
1;

__END__

=pod

=head1 NAME

Bio::Palantir::Roles::Modulable - Modulable Moose role for Module object construction

=head1 VERSION

version 0.191800

=head1 SYNOPSIS

    # TODO

=head1 DESCRIPTION

    # TODO

=head1 AUTHOR

Loic MEUNIER <lmeunier@uliege.be>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by University of Liege / Unit of Eukaryotic Phylogenomics / Loic MEUNIER and Denis BAURAIN.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
