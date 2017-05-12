package AlignDB::Codon;
use Moose;
use Carp;

use AlignDB::IntSpan;
use List::MoreUtils::PP;
use YAML::Syck;

our $VERSION = '1.1.1';

# codon tables
has 'table_id' => ( is => 'ro', isa => 'Int', default => sub {1}, );
has 'table_name'    => ( is => 'ro', isa => 'Str', );
has 'table_content' => ( is => 'ro', isa => 'Str', );
has 'table_starts'  => ( is => 'ro', isa => 'Str', );

# codons
has 'codons'    => ( is => 'ro', isa => 'ArrayRef', );
has 'codon_idx' => ( is => 'ro', isa => 'HashRef', );
has 'codon2aa'  => ( is => 'ro', isa => 'HashRef', );

# lookup hash for the number of synonymous changes per codon
has 'syn_sites' => ( is => 'ro', isa => 'HashRef', );

# lookup hash of all pairwise combinations of codons differing by 1
#    1 = synonymous, 0 = non-synonymous, -1 = stop
has 'syn_changes' => ( is => 'ro', isa => 'HashRef', );

# One <=> Three
has 'one2three' => ( is => 'ro', isa => 'HashRef', );
has 'three2one' => ( is => 'ro', isa => 'HashRef', );

sub BUILD {
    my $self = shift;

    $self->_make_codons;
    $self->change_codon_table( $self->{table_id} );
    $self->_load_aa_code;

    return;
}

sub _make_codons {
    my $self = shift;

    # makes all codon combinations
    my @nucs = qw(T C A G);
    my @codons;
    for my $i (@nucs) {
        for my $j (@nucs) {
            for my $k (@nucs) {
                push @codons, "$i$j$k";
            }
        }
    }
    $self->{codons} = \@codons;

    my %codon_idx;
    for my $i ( 0 .. $#codons ) {
        $codon_idx{ $codons[$i] } = $i;
    }
    $self->{codon_idx} = \%codon_idx;

    return;
}

sub change_codon_table {
    my $self = shift;
    my $id   = shift;

    my @NAMES = (    #id
        'Strict',                      # 0, special option for ATG-only start
        'Standard',                    # 1
        'Vertebrate Mitochondrial',    # 2
        'Yeast Mitochondrial',         # 3
        'Mold, Protozoan, and Coelenterate Mitochondrial and Mycoplasma/Spiroplasma',    # 4
        'Invertebrate Mitochondrial',                                                    # 5
        'Ciliate, Dasycladacean and Hexamita Nuclear',                                   # 6
        '', '',
        'Echinoderm and Flatworm Mitochondrial',                                         # 9
        'Euplotid Nuclear',                                                              # 10
        'Bacterial, Archaeal and Plant Plastid',                                         # 11
        'Alternative Yeast Nuclear',                                                     # 12
        'Ascidian Mitochondrial',                                                        # 13
        'Alternative Flatworm Mitochondrial',                                            # 14
        'Blepharisma Nuclear',                                                           # 15
        'Chlorophycean Mitochondrial',                                                   # 16
        '', '', '', '',
        'Trematode Mitochondrial',                                                       # 21
        'Scenedesmus obliquus Mitochondrial',                                            # 22
        'Thraustochytrium Mitochondrial',                                                # 23
        'Pterobranchia Mitochondrial',                                                   # 24
        'Candidate Division SR1 and Gracilibacteria',                                    # 25
    );

    my @TABLES = qw(
        FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG
        FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG
        FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSS**VVVVAAAADDEEGGGG
        FFLLSSSSYY**CCWWTTTTPPPPHHQQRRRRIIMMTTTTNNKKSSRRVVVVAAAADDEEGGGG
        FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG
        FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSSSSVVVVAAAADDEEGGGG
        FFLLSSSSYYQQCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG
        '' ''
        FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNNKSSSSVVVVAAAADDEEGGGG
        FFLLSSSSYY**CCCWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG
        FFLLSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG
        FFLLSSSSYY**CC*WLLLSPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG
        FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNKKSSGGVVVVAAAADDEEGGGG
        FFLLSSSSYYY*CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNNKSSSSVVVVAAAADDEEGGGG
        FFLLSSSSYY*QCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG
        FFLLSSSSYY*LCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG
        '' '' '' ''
        FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIMMTTTTNNNKSSSSVVVVAAAADDEEGGGG
        FFLLSS*SYY*LCC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG
        FF*LSSSSYY**CC*WLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG
        FFLLSSSSYY**CCWWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSSKVVVVAAAADDEEGGGG
        FFLLSSSSYY**CCGWLLLLPPPPHHQQRRRRIIIMTTTTNNKKSSRRVVVVAAAADDEEGGGG
    );

    my @STARTS = qw(
        -----------------------------------M----------------------------
        ---M---------------M---------------M----------------------------
        --------------------------------MMMM---------------M------------
        ----------------------------------MM----------------------------
        --MM---------------M------------MMMM---------------M------------
        ---M----------------------------MMMM---------------M------------
        -----------------------------------M----------------------------
        '' ''
        -----------------------------------M---------------M------------
        -----------------------------------M----------------------------
        ---M---------------M------------MMMM---------------M------------
        -------------------M---------------M----------------------------
        ---M------------------------------MM---------------M------------
        -----------------------------------M----------------------------
        -----------------------------------M----------------------------
        -----------------------------------M----------------------------
        '' ''  '' ''
        -----------------------------------M---------------M------------
        -----------------------------------M----------------------------
        --------------------------------M--M---------------M------------
        ---M---------------M---------------M---------------M------------
        ---M-------------------------------M---------------M------------
    );

    my $id_set = AlignDB::IntSpan->new("1-6,9-16,21");

    if ( not defined $id ) {
        Carp::confess "codon table id is not defined\n";
    }
    elsif ( $id_set->contains($id) ) {
        $self->{table_id} = $id;

        $self->{table_name}    = $NAMES[$id];
        $self->{table_content} = $TABLES[$id];
        $self->{table_starts}  = $STARTS[$id];

        $self->_make_codon2aa;
        $self->_make_syn_sites;
        $self->_make_syn_changes;
    }
    else {
        Carp::confess "codon table id should be in range of $id_set\n";
    }

    return;
}

sub _make_codon2aa {
    my $self = shift;

    my $table_content = $self->table_content;
    my $codons        = $self->codons;
    my $codon_idx     = $self->codon_idx;

    my %codon2aa;
    for my $codon ( @{$codons} ) {
        my $aa = substr( $table_content, $codon_idx->{$codon}, 1 );
        $codon2aa{$codon} = $aa;
    }

    # gaps in cDNA
    $codon2aa{"---"} = "-";

    $self->{codon2aa} = \%codon2aa;

    return;
}

sub _make_syn_sites {
    my $self = shift;

    my $codons   = $self->codons;
    my $codon2aa = $self->codon2aa;

    my %raw_results;
    for my $cod (@$codons) {
        my $aa = $codon2aa->{$cod};

        # calculate number of synonymous mutations vs non-syn mutations
        for my $i ( 0 .. 2 ) {
            my $s = 0;
            my $n = 3;
            for my $nuc (qw(A T C G)) {
                next if substr( $cod, $i, 1 ) eq $nuc;
                my $test = $cod;
                substr( $test, $i, 1, $nuc );
                if ( $codon2aa->{$test} eq $aa ) {
                    $s++;
                }
                if ( $codon2aa->{$test} eq '*' ) {
                    $n--;
                }
            }
            $raw_results{$cod}[$i] = {
                's' => $s,
                'n' => $n
            };
        }
    }

    my %final_results;
    for my $cod ( sort keys %raw_results ) {
        my $t = 0;
        map { $t += ( $_->{'s'} / $_->{'n'} ) } @{ $raw_results{$cod} };
        $final_results{$cod} = { 's' => $t, 'n' => 3 - $t };
    }

    $self->{syn_sites} = \%final_results;
    return;
}

sub _make_syn_changes {
    my $self = shift;

    my $codons   = $self->codons;
    my $codon2aa = $self->codon2aa;

    my $arr_len = scalar @$codons;

    my %results;
    for ( my $i = 0; $i < $arr_len - 1; $i++ ) {
        my $cod1 = $codons->[$i];
        for ( my $j = $i + 1; $j < $arr_len; $j++ ) {
            my $cod2     = $codons->[$j];
            my $diff_cnt = 0;
            for my $pos ( 0 .. 2 ) {
                if ( substr( $cod1, $pos, 1 ) ne substr( $cod2, $pos, 1 ) ) {
                    $diff_cnt++;
                }
            }
            next if $diff_cnt != 1;

            # synonymous change
            if ( $codon2aa->{$cod1} eq $codon2aa->{$cod2} ) {
                $results{$cod1}{$cod2} = 1;
                $results{$cod2}{$cod1} = 1;
            }

            # stop codon
            elsif ( $codon2aa->{$cod1} eq '*' or $codon2aa->{$cod2} eq '*' ) {
                $results{$cod1}{$cod2} = -1;
                $results{$cod2}{$cod1} = -1;
            }

            # non-synonymous change
            else {
                $results{$cod1}{$cod2} = 0;
                $results{$cod2}{$cod1} = 0;
            }
        }
    }

    $self->{syn_changes} = \%results;
    return;
}

sub comp_codons {
    my $self = shift;
    my $cod1 = shift;
    my $cod2 = shift;
    my $pos  = shift;

    my $syn_changes = $self->syn_changes;
    my $codon2aa    = $self->codon2aa;

    my $syn_cnt = 0;    # total synonymous changes
    my $nsy_cnt = 0;    # total non-synonymous changes

    # ignore codon if beeing compared with gaps!
    if ( $cod1 =~ /\-/ or $cod2 =~ /\-/ ) {
        return ( $syn_cnt, $nsy_cnt );
    }

    # check codons
    for ( $cod1, $cod2 ) {
        if ( !exists $codon2aa->{$_} ) {
            Carp::confess YAML::Syck::Dump( { cod1 => $cod1, cod2 => $cod2 } ), "Wrong codon\n";
            return ( 0, 0 );
        }
    }

    # check codon position
    if ( defined $pos ) {
        if ( List::MoreUtils::PP::none { $_ == $pos } ( 0 .. 2 ) ) {
            Carp::confess YAML::Syck::Dump( { pos => $pos } ), "Wrong codon position\n";
            return ( 0, 0 );
        }
    }

    my %mutator = (
        2 =>    # codon positions to be altered
                # depend on which is the same
            {
            0 => [ [ 1, 2 ], [ 2, 1 ] ],
            1 => [ [ 0, 2 ], [ 2, 0 ] ],
            2 => [ [ 0, 1 ], [ 1, 0 ] ],
            },
        3 =>    # all need to be altered
            [ [ 0, 1, 2 ], [ 1, 0, 2 ], [ 0, 2, 1 ], [ 1, 2, 0 ], [ 2, 0, 1 ], [ 2, 1, 0 ], ],
    );

    my ( $diff_cnt, $codon_pos ) = $self->count_diffs( $cod1, $cod2 );

    if ( $diff_cnt == 0 ) {    # ignore if codons are identical
    }
    elsif ( $diff_cnt == 1 ) {    # In $codon_pos where bases are different
        if ( !defined $pos or $codon_pos == $pos ) {
            $syn_cnt = $syn_changes->{$cod1}{$cod2};
            $nsy_cnt = 1 - $syn_changes->{$cod1}{$cod2};
        }
    }
    elsif ( $diff_cnt == 2 ) {    # In $codon_pos where bases are the same
        my ( $s_cnt, $n_cnt ) = ( 0, 0 );
        my $pathway = 2;          # will stay 2 unless there are stop codons
                                  #   at intervening point
    PATH: for my $perm ( @{ $mutator{2}{$codon_pos} } ) {
            my $altered = $cod1;
            my $prev    = $cod1;
            my ( $sub_s_cnt, $sub_n_cnt ) = ( 0, 0 );

            for my $mut_i (@$perm) {    # index of codon mutated
                my $mut_base = substr( $cod2, $mut_i, 1 );
                substr( $altered, $mut_i, 1, $mut_base );
                if ( $codon2aa->{$altered} eq '*' ) {
                    $pathway--;
                    next PATH;          # abadon this pathway
                }
                else {
                    if ( !defined $pos or $mut_i == $pos ) {
                        $sub_s_cnt += $syn_changes->{$prev}{$altered};
                        $sub_n_cnt += 1 - $syn_changes->{$prev}{$altered};
                    }
                }
                $prev = $altered;
            }

            $s_cnt += $sub_s_cnt;
            $n_cnt += $sub_n_cnt;
        }
        if ( $pathway != 0 ) {
            $syn_cnt = ( $s_cnt / $pathway );
            $nsy_cnt = ( $n_cnt / $pathway );
        }
    }
    elsif ( $diff_cnt == 3 ) {
        my ( $s_cnt, $n_cnt ) = ( 0, 0 );
        my $pathway = 6;    # will stay 6 unless there are stop codons
                            #   at intervening point
    PATH: for my $perm ( @{ $mutator{'3'} } ) {
            my $altered = $cod1;
            my $prev    = $cod1;
            my ( $sub_s_cnt, $sub_n_cnt ) = ( 0, 0 );

            for my $mut_i (@$perm) {    #index of codon mutated
                my $mut_base = substr( $cod2, $mut_i, 1 );
                substr( $altered, $mut_i, 1, $mut_base );
                if ( $codon2aa->{$altered} eq '*' ) {
                    $pathway--;
                    next PATH;          # abadon this pathway
                }
                else {
                    if ( !defined $pos or $mut_i == $pos ) {
                        $sub_s_cnt += $syn_changes->{$prev}{$altered};
                        $sub_n_cnt += 1 - $syn_changes->{$prev}{$altered};
                    }
                }
                $prev = $altered;
            }

            $s_cnt += $sub_s_cnt;
            $n_cnt += $sub_n_cnt;
        }

        # calculate number of synonymous/non synonymous mutations for that
        # codon and add to total
        if ( $pathway != 0 ) {
            $syn_cnt = ( $s_cnt / $pathway );
            $nsy_cnt = ( $n_cnt / $pathway );
        }
    }    # endif $diffcnt = 3

    return ( $syn_cnt, $nsy_cnt );
}

# counts the number of nucleotide differences between 2 codons
# when 1 nucleotide is different, returns this value plus the codon index
#   of which nucleotide is different
# when 2 nucleotides are different, returns this value plus the codon index
#   of which nucleotide is the same
# So comp_codons() knows which nucleotides to change or not to change
sub count_diffs {
    my $self = shift;
    my $cod1 = shift;
    my $cod2 = shift;

    my $cnt = 0;
    my $return_pos;
    my @sames;    # store same base position
    my @diffs;    # store diff base position

    if ( length $cod1 != 3 or length $cod2 != 3 ) {
        Carp::confess YAML::Syck::Dump( { cod1 => $cod1, cod2 => $cod2 } ), "Codon length error\n";
        return ( $cnt, $return_pos );
    }

    # just for 2 differences
    for ( 0 .. 2 ) {
        if ( substr( $cod1, $_, 1 ) ne substr( $cod2, $_, 1 ) ) {
            $cnt++;
            push @diffs, $_;
        }
        else {
            push @sames, $_;
        }
    }

    if ( $cnt == 1 ) {
        $return_pos = $diffs[0];
    }
    elsif ( $cnt == 2 ) {
        $return_pos = $sames[0];
    }

    return ( $cnt, $return_pos );
}

sub translate {
    my $self  = shift;
    my $seq   = shift;
    my $frame = shift;

    # check $frame
    if ( defined $frame ) {
        if ( List::MoreUtils::PP::none { $_ == $frame } ( 0 .. 2 ) ) {
            confess Dump( { frame => $frame } ), "Wrong frame\n";
        }
    }
    else {
        $frame = 0;
    }

    if ( $frame != 0 ) {
        $seq = substr( $seq, $frame );    # delete first $frame bases from $seq
    }
    my $offset = length($seq) - ( length($seq) % 3 );
    substr( $seq, $offset, length($seq), '' );    # now $seq is 3n bp

    my $peptide    = "";
    my $codon2aa   = $self->codon2aa;
    my $codon_size = 3;
    for ( my $i = 0; $i < ( length($seq) - ( $codon_size - 1 ) ); $i += $codon_size ) {
        my $triplet = substr( $seq, $i, $codon_size );
        if ( exists $codon2aa->{$triplet} ) {
            $peptide .= $codon2aa->{$triplet};
        }
        else {
            $peptide .= 'X';
        }
    }
    return $peptide;
}

sub is_start_codon {
    my $self = shift;
    my $cod  = shift;

    $cod = uc $cod;
    $cod =~ tr/U/T/;

    my $table_starts = $self->table_starts;
    my $codon_idx    = $self->codon_idx;

    if ( exists $codon_idx->{$cod} ) {
        my $aa = substr( $table_starts, $codon_idx->{$cod}, 1 );
        return $aa eq "M" ? 1 : 0;
    }
    else {
        return 0;
    }
}

sub is_ter_codon {
    my $self = shift;
    my $cod  = shift;

    $cod = uc $cod;
    $cod =~ tr/U/T/;

    my $table_content = $self->table_content;
    my $codon_idx     = $self->codon_idx;

    if ( exists $codon_idx->{$cod} ) {
        my $aa = substr( $table_content, $codon_idx->{$cod}, 1 );
        return $aa eq "*" ? 1 : 0;
    }
    else {
        return 0;
    }
}

sub _load_aa_code {
    my $self = shift;

    my %one2three = (
        A   => 'Ala',    # Alanine
        R   => 'Arg',    # Arginine
        N   => 'Asn',    # Asparagine
        D   => 'Asp',    # Aspartic acid
        C   => 'Cys',    # Cysteine
        Q   => 'Gln',    # Glutamine
        E   => 'Glu',    # Glutamic acid
        G   => 'Gly',    # Glycine
        H   => 'His',    # Histidine
        I   => 'Ile',    # Isoleucine
        L   => 'Leu',    # Leucine
        K   => 'Lys',    # Lysine
        M   => 'Met',    # Methionine
        F   => 'Phe',    # Phenylalanine
        P   => 'Pro',    # Proline
        S   => 'Ser',    # Serine
        T   => 'Thr',    # Threonine
        W   => 'Trp',    # Tryptophan
        Y   => 'Tyr',    # Tyrosine
        V   => 'Val',    # Valine
        B   => 'Asx',    # Aspartic acid or Asparagine
        Z   => 'Glx',    # Glutamine or Glutamic acid
        X   => 'Xaa',    # Any or unknown amino acid
        '*' => '***',    # Stop codon
    );
    my %three2one = reverse(%one2three);

    $self->{one2three} = \%one2three;
    $self->{three2one} = \%three2one;

    return;
}

sub convert_123 {
    my $self    = shift;
    my $peptide = shift;

    $peptide = uc $peptide;
    my $three_of = $self->one2three;

    my $converted;
    for my $pos ( 0 .. length($peptide) - 1 ) {
        my $aa_code = substr( $peptide, $pos, 1 );
        if ( $three_of->{$aa_code} ) {
            $converted .= $three_of->{$aa_code};
        }
        else {
            Carp::confess "Wrong single-letter amino acid code [$aa_code]!\n";
            $converted .= ' ' x 3;
        }
    }
    return $converted;
}

sub convert_321 {
    my $self    = shift;
    my $peptide = shift;

    $peptide = lc $peptide;
    my $one_of = $self->three2one;

    my $converted;
    for ( my $pos = 0; $pos < length($peptide); $pos += 3 ) {
        my $aa_code = substr( $peptide, $pos, 3 );
        $aa_code = ucfirst $aa_code;
        if ( $one_of->{$aa_code} ) {
            $converted .= $one_of->{$aa_code};
        }
        else {
            warn "Wrong three-letter amino acid code [$aa_code]!\n";
            $converted .= ' ' x 3;
        }

    }

    return $converted;
}

1;    # Magic true value required at end of module

__END__

=pod

=encoding UTF-8

=head1 NAME

AlignDB::Codon - translate sequences and calculate Dn/Ds

=head1 DESCRIPTION

AlignDB::Codon provides methods to translate sequences and calculate Dn/Ds with different codon
tables.

Some parts of this module are extracted from BioPerl to avoid the huge number of its dependencies.

=head1 METHODS

=head2 change_codon_table

    $obj->change_codon_table(2);

Change used codon table and recalc all attributes.

Codon table id should be in range of 1-6,9-16,21.

=head2 comp_codons

    my ($syn, $nsy) = $obj->comp_codons('TTT', 'GTA');

    my ($syn, $nsy) = $obj->comp_codons('TTT', 'GTA', 1);

Compares 2 codons to find the number of synonymous and non-synonymous mutations between them.

If the third parameter (in 0 .. 2) is given, this method will return syn&nsy at this position.

=head2 is_start_codon

    my $bool = $obj->is_start_codon('ATG')

Returns true for codons that can be used as a translation start, false for others.

=head2 is_ter_codon

    my $bool = $obj->is_ter_codon('GAA')

Returns true for codons that can be used as a translation terminator, false for others.

=head2 convert_123

    my $three_format = $obj->convert_123('ARN');

Convert aa code from one-letter to three-letter

=head2 convert_321

    my $one_format = $obj->convert_321('AlaArgAsn');

Convert aa code from three-letter to one-letter

=head1 AUTHOR

Qiang Wang <wang-q@outlook.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Qiang Wang.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
