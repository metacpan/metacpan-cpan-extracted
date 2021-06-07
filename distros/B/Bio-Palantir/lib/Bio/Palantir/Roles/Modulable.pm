package Bio::Palantir::Roles::Modulable;
# ABSTRACT: Modulable Moose role for Module object construction
$Bio::Palantir::Roles::Modulable::VERSION = '0.211420';
use Moose::Role;

use autodie;

use Const::Fast;
use feature qw(say); 

use aliased 'Bio::Palantir::Roles::Modulable::Module';
use aliased 'Bio::Palantir::Roles::Modulable::Component';

requires 'genes';


has 'cutting_mode' => (
    is       => 'ro',
    isa      => 'Str',
    writer   => '_set_cutting_mode',
);

const my $_modular_domains => qr/^A$ | ^AT | ^C$ | ^CAL$ | ^KS | ^E$ | ^H$
        | ^PCP$ | ^ACP$ | KR | DH | ER | cyc | ^TE$ | ^Red$
        | ^NAD | NRPS-COM/xms
;

const my %_init_domain_for =>(
    condensation          => qr{^C$ | ^KS$}xms,
    'substrate-selection' => qr{^A$ | ^AT$}xms,
);

const my %_term_domain_for =>(
    condensation          => qr/^PCP$ | ^ACP$/xmsi,
    'substrate-selection' => qr/^C$ | ^KS$/xmsi,
);

has 'modules' => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => 'ArrayRef[Bio::Palantir::Roles::Modulable::Module]',
#     init_arg => undef,    # due to antiSMASH 5.1's new Module delineation method
    lazy     => 1,
    default  => \&_build_modules, # builder not accepted by perlcritic, likely due to parallel way to fill modules "Private subroutine/method '_build_modules' declared but not used at line 35, column 1.  Eliminate dead code.  (Severity: 3)"
    handles  => {
         count_modules => 'count',
           all_modules => 'elements',
           get_module  => 'get',
          next_module  => 'shift',        
    },
);

sub _build_modules {
    
    my $self = shift;

    # process other cluster types
    unless ($self->type =~ m/nrps | t1pks/xmsi) {
        return [];
    }

    my @genes = sort { $a->rank <=> $b->rank } $self->all_genes;

    my $module_n = 1; #TODO move in Cluster.pm
    my $module_in = 0; # to know if the algo is inside a module or not

    # avoid redondant condensation or selection domains in a module
    my %nr_domain_for = (
        condensation          => 0,
        'substrate-selection' => 0,
        'tailoring/other'     => 0,
        'carrier-protein'     => 0,
        termination           => 0,
        NA                    => 0,
    );

    my %module_for;
    my $last_gene = 1;

    GENE:
    for my $gene_n (0 .. @genes - 1) {

        my @domains = sort { $a->rank <=> $b->rank } 
            $genes[$gene_n]->all_domains;

        next GENE
            unless @domains;

        DOMAIN:
        for my $i (0 .. @domains - 1) {

            # initiate first module based on cutting mode
            if ( ($domains[$i]->class eq 'condensation'
                    || $domains[$i]->class eq 'substrate-selection')
               && ! %module_for) {

                $module_for{$module_n} = {
                    start => $gene_n,
                    end   => $gene_n,
                    domains => [$domains[$i]],
                };

                $last_gene = $gene_n;   # for avoiding empty values
                $nr_domain_for{ $domains[$i]->class } = 1;
                $module_in = 1;
            }
            
            # initiate a new module if cutting domain
            elsif( $domains[$i]->class eq $self->cutting_mode ) {

                $module_for{++$module_n} = {
                    start   => $gene_n,
                    end     => $gene_n,
                    domains => [$domains[$i]],
                };

                # reset non redundant counter
                $nr_domain_for{$_} = 0
                    for qw(condensation substrate-selection);

                $nr_domain_for{ $domains[$i]->class } = 1;
                $module_in = 1;
            }

            # terminate a module if:
                # encounter a non modular domain or trans-acting
                # OR domains are separated by more than one gene
                # OR two consecutive selection or condensation domains
            elsif ( ( ($gene_n - $last_gene) >= 2
                    || ! $domains[$i]->symbol =~ $_modular_domains
                    || $nr_domain_for{ $domains[$i]->class } == 1 )
                && $module_in == 1) {

                $module_for{$module_n}{end} = $last_gene;

                $nr_domain_for{$_} = 0
                    for qw(condensation 'substrate-selection');
                $module_in = 0;
            }

            # module elongation (if inside a module & a modular domain & but not cutting one)
            elsif( $domains[$i]->symbol =~ $_modular_domains
                && $module_in == 1) {

                if ($domains[$i]->class eq 'condensation'
                    || $domains[$i]->class eq 'substrate-selection') {
                    $nr_domain_for{ $domains[$i]->class } = 1
                }
                
                $module_for{$module_n}{end} = $gene_n;

                push @{ $module_for{$module_n}{domains} }, $domains[$i];
            }

            $last_gene = $gene_n;   # positionned here to directly update transitions between genes
        }
    }
    
    return [] unless %module_for;

    # define last module end coordinate
    $module_for{$module_n}{end} = $last_gene
        unless $module_for{$module_n}{end};

    # put C terminal domain in the termination module
    if ( $module_for{ $module_n }{domains}[0]->symbol 
        =~ m/^C$ | ^TE$ | ^TD$ | ^Red$ | ^NAD$/xmsi 
        && @{ $module_for{ $module_n}{domains} } 
        == 1 && keys %module_for > 1 ) {

       push @{ $module_for{ $module_n - 1 }{domains} },
           @{ $module_for{ $module_n }{domains} };

       delete $module_for{ $module_n };
    }
    
    # filter modules: considered incomplete if < 2 (min module is starter A-PCP)
    delete $module_for{$_} for grep { 
        scalar @{ $module_for{$_}{domains} } < 2 } keys %module_for;

    my @modules = _create_elmt_array(\%module_for, \@genes, 'module');
    return \@modules;
}

# Cluster components attribute: ranked modules and trans-acting enzymes
has 'components' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[Bio::Palantir::Roles::Modulable::Component]',
    init_arg => undef,
    lazy     => 1,
    default  => \&_build_components, # builder not accepted by perlcritic, likely due to parallel way to fill modules "Private subroutine/method '_build_components' declared but not used at line 241, column 1.  Eliminate dead code.  (Severity: 3)"
#     builder  => '_build_components',
    handles  => {
        count_components => 'count',
        all_components   => 'elements',
        get_component    => 'get',
        next_component   => 'shift',
    },
);

sub _build_components {

    my $self = shift;

    my @genes = sort { $a->rank <=> $b->rank } $self->all_genes;

    my $component_n = 1; #TODO move in Cluster.pm
    my $launched = 0;
    my (%component_for);

    GENE:
    for my $gene_n (0 .. @genes - 1) {

        my @domains = sort { $a->rank <=> $b->rank } 
            $genes[$gene_n]->all_domains;

        next GENE
            unless @domains;

        DOMAIN:
        for my $i (0 .. @domains - 1) {

            # initiate the components
            if ($component_n == 1 && $i == 0 && $launched == 0) {
                $component_for{$component_n}{start} = $gene_n;
                $launched = 1;
            }
            
            elsif ( 
                # define components anchors on C domains (biological sense with communication domains and condensation steps)
                ($domains[$i]->symbol
                    =~ $_init_domain_for{ $self->cutting_mode })
                # do not allow components to be separated by an intermediate gene
                || ( ($genes[$gene_n]->rank
                      - $genes[ $component_for{$component_n}{start} ]->rank) > 1)                
                # avoid auxilliary domains in components, for instance: if C-A-PCP-TE | AT | A | ACL | ECH assign a different component for last domains
                || (@domains == 1
                    && $domains[$i]->symbol !~ $_modular_domains)
                ) {
                    $component_for{++$component_n}{start} = $gene_n;
            }
              
            push @{ $component_for{$component_n}{domains} }, $domains[$i];
            $component_for{$component_n}{end} = $gene_n;
        }
    }

    return [] unless %component_for;

    # put C terminal domain in the termination component
    if ($component_for{ $component_n }{domains}[0]->symbol 
            =~ m/^C$ | ^TE$ | ^TD$ | ^Red$ | ^NAD$/xmsi 
        && @{ $component_for{ $component_n}{domains} } 
            == 1 
        && keys %component_for > 1) {

       push @{ $component_for{ $component_n - 1 }{domains} },
           @{ $component_for{ $component_n }{domains} };

       delete $component_for{ $component_n };
    }

    my @components = _create_elmt_array(\%component_for, \@genes, 'component');
    return \@components;
}

sub _create_elmt_array {

    my ($element_for, $genes, $str) = @_;

    my (@elements, $rank);
    for my $element_n (sort { $a <=> $b } keys %{ $element_for }) {
        
        my $start_gene = $genes->[ $element_for->{$element_n}{start} ];

        my $end_gene = $genes->[ $element_for->{$element_n}{end} ];

        my $start_domain = @{ $element_for->{$element_n}{domains} }[0];
        my $end_domain = @{ $element_for->{$element_n}{domains} }[-1];
        
        my $genomic_prot_begin = $start_gene->genomic_prot_begin
            + $start_domain->begin;
        my $genomic_prot_end = $end_gene->genomic_prot_begin
            + $end_domain->end;

        my $size = $genomic_prot_end - $genomic_prot_begin + 1;

        # create protein sequence of element by domain sequence contatenation
        my $cumulative_seq;
        for my $domain (@{ $element_for->{ $element_n}{domains} }) {
            $cumulative_seq .= $domain->protein_sequence;
        }

        my $full_seq;       
        if ($start_gene->name eq $end_gene->name) {
            my ($seq) = $start_gene->protein_sequence;
            $full_seq = substr( $seq, ($start_domain->begin - 1),
                ($end_domain->end - $start_domain->begin + 1) );
        }

        else {
            my ($seq1) = $start_gene->protein_sequence;
            my $start_seq = substr ( $seq1, ($start_domain->begin - 1) );

            my ($seq2) = $end_gene->protein_sequence;
            my $end_seq = substr ( $seq2, 0, ($end_domain->end) );

            $full_seq = $start_seq . $end_seq;
        }

        my @gene_uuis 
            = map { $genes->[ $_ ]->uui } 
            $element_for->{$element_n}{start}..$element_for->{$element_n}{end}
        ;

        if ($str eq 'module') { 

            my $element = Module->new( 
                                    rank => ++$rank,
                                 domains => $element_for->{$element_n}{domains}
                                            // [],
                               gene_uuis => \@gene_uuis, 
                      genomic_prot_begin => $genomic_prot_begin,
                        genomic_prot_end => $genomic_prot_end,
                genomic_prot_coordinates => [$genomic_prot_begin, 
                                                $genomic_prot_end],
                                    size => $size,
                        protein_sequence => $full_seq,
             cumulative_protein_sequence => $cumulative_seq,
            );
        
            push @elements, $element;
        }

        else { 

            my $element = Component->new( 
                                    rank => $element_n,
                                 domains => $element_for->{$element_n}{domains}
                                            // [],
                               gene_uuis => \@gene_uuis, 
                      genomic_prot_begin => $genomic_prot_begin,
                        genomic_prot_end => $genomic_prot_end,
                genomic_prot_coordinates => [$genomic_prot_begin,
                                                $genomic_prot_end],
                                    size => $size,
                        protein_sequence => $full_seq,
             cumulative_protein_sequence => $cumulative_seq,
            );
        
            push @elements, $element;
        }
    }

    return @elements;
}

no Moose::Role;
1;

__END__

=pod

=head1 NAME

Bio::Palantir::Roles::Modulable - Modulable Moose role for Module object construction

=head1 VERSION

version 0.211420

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
