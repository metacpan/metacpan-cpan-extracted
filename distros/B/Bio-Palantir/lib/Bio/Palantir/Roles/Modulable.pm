package Bio::Palantir::Roles::Modulable;
# ABSTRACT: Modulable Moose role for Module object construction
$Bio::Palantir::Roles::Modulable::VERSION = '0.200290';
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

const my $_modular_domains => qr/^A$ | ^AT | ^C$ | ^KS | ^E$ | ^H$
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
    my (%module_for, $last_gene);

### ok: $self->cutting_mode

    GENE:
    for my $gene_n (0 .. @genes - 1) {

        my @domains = sort { $a->rank <=> $b->rank } 
            $genes[$gene_n]->all_domains;

        next GENE
            unless @domains;

        DOMAIN:
        for my $i (0 .. @domains - 1) {

#             next unless $domains[$i]->function; # avoid warnings when antismash domains are undef    

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
                $module_in = 1;
            }
            
            # initiate a new module if cutting domain
            elsif( $domains[$i]->class eq $self->cutting_mode ) {
                
#                 # allow starter condensation domains
#                 if ($module_n == 1 
#                     && scalar @{ $module_for{'1'}{domains} } == 1
#                     && @{ $module_for{'1'}{domains} }[0]->class 
#                         eq 'condensation'
#                     && $domains[$i]->class ne 'condensation'
#                     ) {
# 
#                     $module_for{$module_n}{end} = $gene_n;
#                     push @{ $module_for{$module_n}{domains} }, $domains[$i];
#                 }

                # initiate a new module
#                 else {
                    $module_for{++$module_n} = {
                        start   => $gene_n,
                        end     => $gene_n,
                        domains => [$domains[$i]],
                    };

                    $module_in = 1;
#                 }
            }

            # module elongation (if inside a module & a modular domain & but not cutting one)
            elsif( $domains[$i]->symbol =~ $_modular_domains
                && $module_in == 1) {

                $module_for{$module_n}{end} = $gene_n;
                push @{ $module_for{$module_n}{domains} }, $domains[$i];
            }
            
            # terminate a module if encounter a non modular domain or trans-acting
            elsif (! $domains[$i]->symbol =~ $_modular_domains
                  && $domains[$i - 1]->symbol =~ $_modular_domains
                  && ($gene_n - $last_gene) < 2
                  && $module_in == 1) {

                $module_for{$module_n}{end} = $last_gene;
                $module_in = 0;
            }
        }

        $last_gene = $gene_n;
    }


# first method try
#             # initiate first module (ignore C domains)
#             if ($domains[$i]->symbol =~ $_modular_domains
#                     && $module_n == 1 && ! %module_for) {
# 
#                 $module_for{$module_n} = {
#                     start => $gene_n,
#                     domains => [$domains[$i]],
#                 };
# 
#                 $last_gene = $gene_n;
#             }
# 
#             # module elongation or delineation of successive modules
#             elsif ($domains[$i - 1]->symbol =~ $_modular_domains
#                     && $domains[$i]->symbol =~ $_modular_domains
#                 ) { 
# 
#                 # begin a new module following cutting mode
#                 if ($domains[$i]->symbol 
#                     =~ $_cutting_regex_for{ $self->cutting_mode }) {
#                     
#                     $module_for{$module_n}{end} = $last_gene;
# 
#                     $module_for{++$module_n} = {
#                         start => $gene_n,
#                         domains => [$domains[$i]],
#                     };
#                 }
# 
#                 else {
#                     push @{ $module_for{$module_n}{domains} }, $domains[$i];
#                 }
#             }
# 
#             # end module if non-modular domain encountered
#             elsif (! $domains[$i]->symbol =~ $_modular_domains
#                     && $domains[$i - 1]->symbol =~ $_modular_domains
#                     ) {
#                 $module_for{$module_n}{end} = $last_gene;
#                 push @{ $module_for{$module_n}{domains} }, $domains[$i];
#             }
# 
#             # start over a new module after a break (even if truncated)
#             elsif (! $domains[$i -1 ]->symbol =~ $_modular_domains
#                    &&  $domains[$i]->symbol =~ $_modular_domains) {
# 
#                 $module_for{++$module_n} = {
#                     start => $gene_n,
#                     domains => [$domains[$i]],
#                 };
#             }
# 
#             $last_gene = $gene_n;
#         }   
#     }
    
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
    
#     # filter modules: considered incomplete if < 2 (min module is starter A-PCP)
#     delete $module_for{$_} for grep { 
#         scalar @{ $module_for{$_}{domains} } < 2 } keys %module_for;
#   stopped as it eliminates modular domains -> [C] [A-PCP-C] [A-PCP-C]... 
    
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

    my @elements;
    for my $element_n (sort { $a <=> $b } keys %{ $element_for }) {
        
        # create protein sequence of element by domain sequence contatenation
        my $seq;
        for my $domain (@{ $element_for->{ $element_n}{domains} }) {
            $seq .= $domain->protein_sequence;
        }

        my $size = length $seq;

        my $start_gene 
            = $genes->[ $element_for->{$element_n}{start} ]->genomic_prot_begin;

        my $end_gene 
            = $genes->[ $element_for->{$element_n}{end} ]->genomic_prot_begin;

        my $start_domain = @{ $element_for->{$element_n}{domains} }[0]->begin;
        my $end_domain = @{ $element_for->{$element_n}{domains} }[-1]->end;
        
        my $genomic_prot_begin = $start_gene + $start_domain;
        my $genomic_prot_end = $end_gene + $end_domain;

        my @gene_uuis 
            = map { $genes->[ $_ ]->uui } 
            $element_for->{$element_n}{start}..$element_for->{$element_n}{end}
        ;

        if ($str eq 'module') { 

            my $element = Module->new( 
                               rank      => $element_n,
                             domains     => $element_for->{$element_n}{domains}
                                            // [],
                          gene_uuis      => \@gene_uuis, 
                      genomic_prot_begin => $genomic_prot_begin,
                        genomic_prot_end => $genomic_prot_end,
                genomic_prot_coordinates => [$genomic_prot_begin, 
                                                $genomic_prot_end],
                   protein_sequence      => $seq,
            );
        
            push @elements, $element;
        }

        else { 

            my $element = Component->new( 
                               rank      => $element_n,
                             domains     => $element_for->{$element_n}{domains}
                                            // [],
                          gene_uuis      => \@gene_uuis, 
                      genomic_prot_begin => $genomic_prot_begin,
                        genomic_prot_end => $genomic_prot_end,
                genomic_prot_coordinates => [$genomic_prot_begin, 
                                                $genomic_prot_end],
                   protein_sequence      => $seq,
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

version 0.200290

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
