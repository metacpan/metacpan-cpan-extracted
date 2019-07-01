package Bio::Palantir::Roles::Fillable;
# ABSTRACT: Fillable Moose role for the construction of DomainPlus object arrays and Exploratory methods
$Bio::Palantir::Roles::Fillable::VERSION = '0.191800';
use Moose::Role;

use autodie;

use Const::Fast;
use File::ShareDir qw(dist_dir);
use File::Temp;

use aliased 'Bio::FastParsers::Hmmer::DomTable';
use aliased 'Bio::Palantir::Refiner::DomainPlus';


const my $DATA_PATH => dist_dir('Bio-Palantir') . '/';

# pHMM database sources:
#
# Weber T, Blin K, Duddela S, et al. antiSMASH 3.0-a comprehensive resource for
# the genome mining of biosynthetic gene clusters. Nucleic Acids Res. 
# 2015;43(W1):W237–W243. doi:10.1093/nar/gkv437
#
# Khayatt, B. I., Overmars, L., Siezen, R. J., & Francke, C. (2013). 
# Classification of the Adenylation and Acyl-Transferase Activity of NRPS and 
# PKS Systems Using Ensembles of Substrate Specific Hidden Markov Models. 
# PLoS ONE, 8(4). http://doi.org/10.1371/journal.pone.0062136
#
# Bushley, K. E., & Turgeon, B. G. (2010). Phylogenomics reveals subfamilies of
# fungal nonribosomal peptide synthetases and their evolutionary relationships.
# BMC Evolutionary Biology, 10(1), 26. http://doi.org/10.1186/1471-2148-10-26

# biological data
my %ADJUSTMENT_FOR = (      # length column useless: this information can be obtained by OO variable
    # for antismash activity
    A                    => { start => 20, end => 100, length => 418 },
    Red                  => { start => 0,  end => 0  , length => 242 }, # equivalent of TD
    # NRPS
    Condensation         => { start => 0,  end => 150, length => 300 },
    Condensation_LCL     => { start => 0,  end => 154, length => 296 },
    Condensation_DCL     => { start => 0,  end => 150, length => 300 },
    Condensation_Starter => { start => 0,  end => 150, length => 300 },
    Condensation_Dual    => { start => 0,  end => 157, length => 293 },
    Epimerization        => { start => 0,  end => 133, length => 317 },
    Heterocyclization    => { start => 0,  end => 150, length => 300 },
    X                    => { start => 0,  end => 147, length => 303 },
    Cglyc                => { start => 0,  end => 151, length => 299 },
    Condensation_fungi   => { start => 0,  end => 251, length => 209 }, # où faut-il ajuster ?
    'AMP-binding'        => { start => 27, end => 66,  length => 418 },
    'AMP-binding_fungi'  => { start => 4,  end => 0  , length => 507 },
    ACPS                 => { start => 0,  end => 0  , length => 78  },
    Aminotran_1_2        => { start => 0,  end => 0  , length => 363 },
    Aminotran_3          => { start => 0,  end => 0  , length => 339 },
    Aminotran_4          => { start => 0,  end => 0  , length => 232 },
    Aminotran_5          => { start => 0,  end => 0  , length => 371 },
    'A-OX'               => { start => 0,  end => -250,length => 780 }, # it overlaps following domains
    B                    => { start => 0,  end => 0  , length => 365 },
    cMT                  => { start => 0,  end => 0  , length => 230 },
    ECH                  => { start => 0,  end => 0  , length => 245 },
    Epimerization        => { start => 0,  end => 0  , length => 317 },
    F                    => { start => 0,  end => 0  , length => 127 },
    Fkbh                 => { start => 0,  end => 0  , length => 142 },
    GNAT                 => { start => 0,  end => 0  , length => 139 },
    Hal                  => { start => 0,  end => 0  , length => 222 },
    Heterocyclization    => { start => 0,  end => 0  , length => 300 },
    NAD_binding_4        => { start => 0,  end => 0  , length => 249 },
    nMT                  => { start => 0,  end => 0  , length => 244 },
    'NRPS-COM_Cterm'     => { start => 0,  end => 0  , length => 21  },
    'NRPS-COM_Nterm'     => { start => 0,  end => 0  , length => 33  },
    oMT                  => { start => 0,  end => 0  , length => 280 },
    PCP                  => { start => 0,  end => 0  , length => 70  },
    'PP-binding'         => { start => 0,  end => 0  , length => 70  },
    PCP_fungi            => { start => 0,  end => 0  , length => 86  },
    PS                   => { start => 0,  end => 0  , length => 214 },
    TD                   => { start => 0,  end => 0  , length => 242 },
    Thioesterase         => { start => 0,  end => 0  , length => 229 },
    # PKS
    PKS_KS               => { start => 8,  end => 0, length => 426 },
    PKS_KR               => { start => 0,  end => 0, length => 185 },
    PKS_ER               => { start => 0,  end => 0, length => 313 },
    PKS_DH               => { start => 0,  end => 0, length => 166 },
    PKS_DH2              => { start => 0,  end => 0, length => 233 },
    PKS_DHt              => { start => 0,  end => 0, length => 236 },
    PKS_AT               => { start => 114, end => 22, length => 298 },
    Polyketide_cyc       => { start => 0,  end => 0, length => 130 },
    Polyketide_cyc2      => { start => 0,  end => 0, length => 139 },
    PKS_Docking_Nterm    => { start => 0,  end => 0, length => 28 },
    PKS_Docking_Cterm    => { start => 0,  end => 0, length => 73 },
    CAL_domain           => { start => 0,  end => 0, length => 465 },
    'Trans-AT_docking'   => { start => 0,  end => 0, length => 155 },
    ACP                  => { start => 0,  end => 0, length => 73 },
    ACP_beta             => { start => 0,  end => 0, length => 67 },
);


# public methods

sub detect_domains {                        ## no critic (RequireArgUnpacking)
    my $self = shift;

    my ($seq, $gene_pos, $gap_coords) = @_; #TODO switch to hash
    
    my %hit_for = %{ $self->_parse_generic_domains($seq) };
    
    # build DomainPlus objects
    my @domains;
    for my $hit (keys %hit_for) {
        push @domains, DomainPlus->new(
            map { $_ => $hit_for{$hit}{$_} } keys %{ $hit_for{$hit} }
        );
    }

    $_->_set_protein_sequence($seq) for @domains;
    
    $self->_use_hit_information($_, $gene_pos) for @domains;
    
    $self->_elongate_coordinates(\@domains, $gap_coords);
    @domains = $self->_handle_overlaps(@domains);
    $self->_refine_coordinates(@domains);

    # subtype the domains
    $self->_get_domain_subtype($_) for @domains;

    return (@domains);
}

# private methods

sub _elongate_coordinates {
    my $self = shift;

    my $domains = shift;
    my $gap_coords = shift;

    # adjustment of domain coordinates to get plausible domain sizes
    for my $domain (@{ $domains }) {

        # begin at profile start even if does not match the profile, and adjust the coords depending of the domain nature
        my $start    = $domain->begin - $domain->hmm_from; # complete the domain if the phmm didnt match entirely the sequence
        my $end      = $domain->end   + ($domain->tlen - $domain->hmm_to); 

        if ($ADJUSTMENT_FOR{$domain->target_name}) {
            $start -= $ADJUSTMENT_FOR{$domain->target_name}{start};
            $end   += $ADJUSTMENT_FOR{$domain->target_name}{end};
        }

        # handle truncated domains
       
        # check strain orientation
        my ($gene_begin, $gene_end);
        if ($self->gene_begin > $self->gene_end) {
           $gene_begin = $self->gene_end;
           $gene_end   = $self->gene_begin;
        }
        
        else { 
            $gene_begin = $self->gene_begin;
            $gene_end   = $self->gene_end;
        }

        # standard elongation checks
        unless ($gap_coords) {
            $start = 1 if $start <= 0;       # as we do not use -1 position before substr()
            $end = $gene_end if $end > $gene_end;
        }

        # gap filling elongation check
        else {

            $start = $gap_coords->[0] if $start <= $gap_coords->[0];
            $end   = ($gap_coords->[1] - 1) if $end > $gap_coords->[1];            
        }

        my $size = $end - $start + 1;

        $domain->_set_begin($start);
        $domain->_set_end($end);
        $domain->_set_size($size);
        $domain->_set_coordinates( [$start, $end] );
    }

    return;
}

sub _handle_overlaps {                      ## no critic (RequireArgUnpacking)
    my $self = shift; 

    my @domains = @_;
    my @sorted_domains 
        = sort { $b->score <=> $a->{score} || $a->begin <=> $b->begin }
        @domains
    ;

    my %deja_vu;
    my @non_overlapping_domains;
    
    REF:
    for my $ref_hit ( 0..(@sorted_domains - 1) ) {
        
        next REF if $deja_vu{$ref_hit}; 
       
        my ($x1, $y1) = map { $sorted_domains[$ref_hit]->$_ } qw(begin end);
        $deja_vu{$ref_hit} = 1;
        
        my @overlaps = $ref_hit; 
       
        CMP:
        for my $cmp_hit ( 0..(@sorted_domains - 1) ) {
        
            next CMP if $deja_vu{$cmp_hit}; 

            my ($x2, $y2) = map { $sorted_domains[$cmp_hit]->$_ } qw(begin end);
            
            unless ($x2 > $y1 || $y2 < $x1) {   ## no critic (ProhibitNegativeExpressionsInUnlessAndUntilConditions)

                push @overlaps, $cmp_hit;

                if ($self->from_seq == 1) {
                    $deja_vu{$cmp_hit} = 1
                        if $sorted_domains[$cmp_hit]->class 
                        eq $sorted_domains[$ref_hit]->class
                    ;     # avoid superposition of domain of the same class
                }

                else { 
                    $deja_vu{$cmp_hit} = 1;
                }
            }
        }
    
        push @non_overlapping_domains, $sorted_domains[ $overlaps[0]  ];
    }

    return(@non_overlapping_domains);
}

sub _refine_coordinates {                   ## no critic (RequireArgUnpacking)
    my $self = shift; 

    my @domains = @_;
   
    # final refinment of coordinates
    my @sorted_domains = sort { $a->begin <=> $b->begin } @domains;

    for my $i (0..(scalar @sorted_domains - 2)) {
        
        if ($sorted_domains[$i]->end >= $sorted_domains[$i + 1]->begin) {        # si le hit recouvre la fin du hit précént

            my $adjust_start 
                = $ADJUSTMENT_FOR{ $sorted_domains[$i + 1]->target_name }{start};
            if ($adjust_start > 0) { # si ajustement start domaine suivant

                if ( ($sorted_domains[$i + 1]->begin + $adjust_start) 
                        > $sorted_domains[$i]->end) { # si conserver une partie de l'ajustement est possible
                # et si la partie qui empiète le hit précédent est uen région ajoutée artificiellement --> réduire la taille de la région ajoutée (jusqu'au pHMM tout au plus
                # il vaut mieux commencer par éliminer les parties ajoutées en N-ter d'abord, car elles sont assez limitées.
                    $sorted_domains[$i + 1]->_set_begin(
                        $sorted_domains[$i]->end + 1); 
                }

                else { # sinon déduire ajustement start sans endommager les coordonées initiales du domaine
                    $sorted_domains[$i + 1]->_set_begin(
                        $sorted_domains[$i + 1]->begin + $adjust_start); 
                }
            }
        }
        
        if ($sorted_domains[$i]->end >= $sorted_domains[$i + 1]->begin) {  # si cela ne résoud pas le problème, on peut réduire la taille de la région ajoutée C-ter du domaine précédent (jusqu'au pHMM tout au plus
            
            my $adjust_end 
                = $ADJUSTMENT_FOR{ $sorted_domains[$i]->target_name }{end};

            if ($adjust_end > 0) {  # si ajustement end

                    if ( ($sorted_domains[$i]->end - $adjust_end) 
                            < $sorted_domains[$i + 1]->begin) { # si conserver une partie de l'ajustement est possible

                    $sorted_domains[$i]->_set_end(
                        $sorted_domains[$i + 1]->begin - 1);
                }

                else { # sinon déduire ajustement end sans endommager les coordonées initiales du domaine

                    $sorted_domains[$i]->_set_end($sorted_domains[$i]->end - $adjust_end);
                }   
            }
            # ne rien faire si les parties qui s'empiètent font partie du pHMM --> comment pourrait-on les distinguer ?
        }
    }

    # attribute refined sequence
    for my $domain (@domains) {
        $domain->_set_size($domain->end - $domain->begin + 1);
        
        my ($seq) = $self->protein_sequence;   # list context
        $domain->_set_protein_sequence( 
            substr($seq, $domain->begin - 1, $domain->size) );
    }

    return;
}

sub _get_domain_subtype {
    my $self = shift;

    my $domain = shift;

    # search for A & AT substrate specificity and C & KS subtypes
    my %hmmdb_for = (
        A  => $DATA_PATH . 'A_specificity.hmm', 
        AT => $DATA_PATH . 'AT_specificity.hmm',
        C  => $DATA_PATH . 'C_subtypes.hmm',
        KS => $DATA_PATH . 'KS_subtypes.hmm',
    );

    unless ($hmmdb_for{$domain->symbol}) {

        if ($domain->function =~ m/MT | ^Amt$ | Aminotran/xms) {
            $domain->_set_subtype($domain->target_name);
        }

        else { 
            $domain->_set_subtype('NULL');
        }

        $domain->_set_subtype_evalue('NULL');
        $domain->_set_subtype_score('NULL');
        return;
    }

    my $seq   = $domain->protein_sequence;

    my $hmmdb = $hmmdb_for{$domain->symbol};
    my $tbout = $self->_do_hmmscan($seq, $hmmdb);

    # parse domtblout hmmer report 
    my $report = DomTable->new( file => $tbout->filename );

    my %subtype_for;
    my $i;
    
    while (my $hit = $report->next_hit) {
        
        $i++;

        $subtype_for{$hit->target_name} = {     # avoid doublons
            map { $_ => $hit->$_ } 
            qw(target_name ali_from ali_to hmm_from hmm_to tlen)
        };

        $subtype_for{$hit->target_name}{evalue} = $hit->i_evalue;
        $subtype_for{$hit->target_name}{score}  = $hit->dom_score;
    }
        
    unless (values %subtype_for) {
        $domain->_set_subtype('na');
        $domain->_set_subtype_evalue('na');
        $domain->_set_subtype_score('na');
        return;
    }

    #TODO handle multiple hits for the same pHMM -> give many times the same value
    my @sorted_hits 
        = sort { $subtype_for{$b}{score} <=> $subtype_for{$a}{score} } 
        keys %subtype_for
    ;
    
    # get best scoring subtype but also the closest ones (>= 95% than the best score)
    my $score_ref = $subtype_for{$sorted_hits[0]}{score}; 
    my @keys 
        = grep { $subtype_for{$_}{score} >= ($score_ref / 100) * 95 } 
        @sorted_hits
    ;

    my @values  = map { $subtype_for{$_}{target_name} } @keys;
    my @evalues = map { $subtype_for{$_}{evalue} } @keys;
    my @scores  = map { $subtype_for{$_}{score} } @keys;

    $domain->_set_subtype( (join '/', @values));  
    $domain->_set_subtype_evalue( (join '/', @evalues));  
    $domain->_set_subtype_score( (join '/', @scores));  

    return;
}

# sub _get_docking_domains {
#     my $self = shift;
# 
#     my $seq = shift;
#     my $hmmdb = $DATA_PATH . 'docking.hmm';
# 
#     my $tbout = $self->_do_hmmscan($seq, $hmmdb);
#     
#     # parse domtblout hmmer report 
#     my $report = DomTable->new( file => $tbout->filename );
# 
#     my %hit_for;
#     my $i;
#     
#     while (my $hit = $report->next_hit) {
#         
#         if ($ARGV{'--evalue-threshold'}) {
#             next if $hit->evalue > $ARGV{'--evalue-threshold'};
#         }                  
#         $i++;
# 
#         $hit_for{ 'hit_' . $i } = {
#             map { $_ => $hit->$_ } qw(target_name ali_from ali_to hmm_from hmm_to tlen score evalue )
#         };
#     }
# 
#     return \%hit_for;
# }


## no critic (ProhibitUnusedPrivateSubroutines)

sub _get_domain_features {
    my $self = shift;

    my $domain = shift;
    my $gene_pos = shift // 0;

    my $query = $domain->protein_sequence;

    my %domain_for = %{ $self->_parse_generic_domains($query) };


    unless (%domain_for) {
        $domain->_set_function('to_remove');
        return;
    }

    my $best_hit 
        = (sort { $domain_for{$b}{score} <=> $domain_for{$a}{score} } 
        keys %domain_for)[0]
    ;
   
    for my $feature (keys %{ $domain_for{$best_hit} }) {
        my $_set_attr = '_set_' . $feature;
        $domain->$_set_attr( $domain_for{$best_hit}{$feature} );
    }
   
    $self->_use_hit_information($domain, $gene_pos);
    
    return;
}

## use critic


sub _use_hit_information {
    my $self     = shift;
    my $domain   = shift;
    my $gene_pos = shift;

    $domain->_set_begin($gene_pos + $domain->ali_from);
    $domain->_set_end($gene_pos + $domain->ali_to);
    
    $domain->_set_phmm_name($domain->target_name);
    $domain->_set_function($domain->target_name) 
        unless $domain->function;
    
    return;
}


sub _parse_generic_domains {
    my $self = shift;

    my $seq = shift;
    
    my $hmmdb = $DATA_PATH . 'generic_domains.hmm';

    my $tbout = $self->_do_hmmscan($seq, $hmmdb);

    # parsing of  domtblout hmmscan report 
    my $report = DomTable->new( file => $tbout->filename );

    my $ug = Data::UUID->new;
    my %hit_for;
    my $evalue_threshold = 10e-3;
    my $i = 1;

    HIT:
    while (my $hit = $report->next_hit) { 
        
        next HIT if $hit->evalue > $evalue_threshold;

        my $ui = $ug->create_str;

        $hit_for{$ui} = {
            map { $_ => $hit->$_ } 
            qw(query_name target_name ali_from ali_to hmm_from hmm_to tlen qlen)
        };
        
        $hit_for{$ui}{score}  = $hit->dom_score;
        $hit_for{$ui}{evalue} = $hit->i_evalue;     # i-value = independent evalue ('evalue' return cumulative evalues for the sequence, and c-evalue may be deleted because potentially e-value)
        $i++;
    }

    return \%hit_for;
}

sub _do_hmmscan {
    my $self  = shift;
    my $seq   = shift;
    my $hmmdb = shift; 
    
    my $query = File::Temp->new( 
        template => 'tempfile_XXXXXXXXXXXXXXX', 
        suffix => '.faa', 
        unlock => 1
    ); 

    print $query '>query' . "\n" . $seq;

    my $pgm = 'hmmscan';

    my $cpu_n = 1;
    my $tbout = File::Temp->new(suffix => '_domtblout.tsv'); 
    my $opt = ' --domtblout ' . $tbout . ' --cpu ' . $cpu_n;
    my $log = File::Temp->new(suffix => '_hmmscan.log', unlock => 1);

    my $cmd = "$pgm $opt $hmmdb $query > $log"; 
    system $cmd;
   
    return $tbout;
}

no Moose::Role;
1;

__END__

=pod

=head1 NAME

Bio::Palantir::Roles::Fillable - Fillable Moose role for the construction of DomainPlus object arrays and Exploratory methods

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
