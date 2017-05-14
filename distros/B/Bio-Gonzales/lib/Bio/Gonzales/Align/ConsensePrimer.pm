package Bio::Gonzales::Align::ConsensePrimer;

use Mouse;

use warnings;
use strict;

use 5.010;

use Bio::Gonzales::Seq::IO qw/faslurp faspew/;
use Bio::Gonzales::Seq::Util qw/pairwise_identities pairwise_identity_gaps_s pairwise_identity_s/;
use List::Util qw/sum/;
use List::MoreUtils qw/indexes any zip/;
use Data::Dumper;
$Data::Dumper::Terse = 1;

our $VERSION = '0.0546'; # VERSION

has cds_seqs            => ( is => 'rw', required => 1 );
has genomic_seqs        => ( is => 'rw', required => 1 );
has min_primer_distance => ( is => 'rw', default  => 800 );
has max_primer_distance => ( is => 'rw', default  => 2500 );
has num_mismatches      => ( is => 'rw', default  => 0 );
has min_primer_length   => ( is => 'rw', default  => 11 );
has name                => ( is => 'rw', default  => 'seq' );
has segment_filter      => ( is => 'rw', builder  => '_build__segment_filter' );

sub run {
    my ($self) = @_;

    my $queue = $self->cds_seqs;

    my @overall_result;

    my @done;
    my $cluster_id = 0;

    #run till all cds seqs are considered
    while ( @$queue > 0 ) {
        my $seqs = $queue;
        $queue = [];

        print STDERR "+";
        while ( @$seqs > 1 ) {
            #redo alignment
            print STDERR ".";
            $seqs = $self->realign($seqs);

            #create consensus sequence
            my $consensus = consensus_string( $seqs, $self->num_mismatches );
            #remove positions where all sequences have gaps
            $consensus =~ s/-//g;

            #find continous sequence patches
            my $segments = $self->_find_segments($consensus);

            #find the positions of the patches
            my $primer_positions = $self->primer_positions( $seqs, $segments );

            #calculate the distances of the postions
            my $primer_distances = $self->primer_distances($primer_positions);

            #and filter for them
            my $filtered_distances = $self->filter_minimum_distances($primer_distances);
            if ( $filtered_distances && @$filtered_distances > 0 ) {
                $cluster_id++;
                for my $d (@$filtered_distances) {
                    push @overall_result,
                        +{
                        file           => $self->name,
                        catched_count  => scalar(@$seqs),
                        cluster_count  => ( @$seqs + @$queue + @done ),
                        sequence_id    => $d->{id},
                        primer_a_id    => $d->{apid},
                        primer_b_id    => $d->{bpid},
                        primer_a_begin => $d->{abegin},
                        primer_a_end   => $d->{aend},
                        primer_b_begin => $d->{bbegin},
                        primer_b_end   => $d->{bend},
                        distance       => $d->{dist},
                        primer_a_seq   => $d->{aseq},
                        primer_b_seq   => $d->{bseq},
                        cluster_id     => $cluster_id,
                        };

                }
                push @done, @$seqs;
                print STDERR "c";
                last;
            }

            #find the most UNsimilar sequence and kick it out
            my $m = pairwise_identities( \&pi, @$seqs );
            my $idx = avg_minimum($m);
            unless ( defined($idx) ) {
                warn "DIST: " . Dumper $primer_distances;
                warn "PRIPOS: " . Dumper $primer_positions;
                warn "SEG: " . Dumper $segments;
                warn "M: " . Dumper $m;
                warn "SEQS: " . Dumper $seqs;
                die;
            }

            my @new_seqs;
            for ( my $i = 0; $i < @$seqs; $i++ ) {
                if ( $i == $idx ) {
                    push @$queue, $seqs->[$i];
                } else {
                    push @new_seqs, $seqs->[$i];
                }
            }

            $seqs = \@new_seqs;
        }
        if ( @$seqs == 1 ) {
            $cluster_id++;
            push @overall_result,
                {
                file           => $self->name,
                catched_count  => scalar(@$seqs),
                cluster_count  => ( @$seqs + @$queue + @done ),
                sequence_id    => $seqs->[0]->id,
                primer_a_id    => -1,
                primer_b_id    => -1,
                primer_a_begin => -1,
                primer_a_end   => -1,
                primer_b_begin => -1,
                primer_b_end   => -1,
                distance       => -1,
                primer_a_seq   => -1,
                primer_b_seq   => -1,
                cluster_id     => $cluster_id,
                };
            push @done, @$seqs;
            print STDERR "#";
        }
        say "/ " . scalar @$queue;
    }
    return \@overall_result;
}

sub realign {
    my ( $self, $seqs ) = @_;

    my $tmp_in  = 'seqtmp.fa';
    my $tmp_out = 'seqtmp.aln.fa';
    faspew $tmp_in, $seqs;

    #system "mafft --maxiterate 1000 --globalpair $tmp_in 2>/dev/null >$tmp_out";
    system "mafft $tmp_in 2>/dev/null >$tmp_out";

    my $realigned_seqs = faslurp $tmp_out;
    unlink $tmp_out;
    unlink $tmp_in;

    return $realigned_seqs;
}

sub primer_positions {
    my ( $self, $seqs, $segments ) = @_;

    my %primer_positions;
    my $genomic_seqs = $self->genomic_seqs;

    for my $gseq (@$genomic_seqs) {
        next unless ( any { my $id = $_->id; $gseq->id =~ /$id/ } @$seqs );
        $primer_positions{ $gseq->id } //= [];
        my $i = 0;
        for my $segment (@$segments) {
            if ( $gseq->seq =~ /$segment/i ) {
                push @{ $primer_positions{ $gseq->id } },
                    { seq => $segment, range => [ $-[0] + 1, $+[0] ], primer_id => "p" . $i++ };
            }
        }
    }
    return \%primer_positions;
}

sub _find_segments {
    my ( $self, $consensus ) = @_;

    $consensus =~ s/^[?.]*//;
    $consensus =~ s/[?.]*$//;

    my @segments = split /([?.]+)/, $consensus;
    my @idcs = indexes { !/^[?.]+$/ } @segments;

    my @super_segments;
    for my $idx (@idcs) {
        my $mismatches = 0;
        my $segment    = $segments[$idx];
        for ( my $i = $idx; $i < @segments - 2; $i += 2 ) {
            #length of mismatch patch
            last if ( length( $segments[ $i + 1 ] ) + $mismatches > $self->num_mismatches );
            last if ( $segments[ $i + 1 ] =~ /\?/ );
            $segment .= $segments[ $i + 1 ] . $segments[ $i + 2 ];
            $mismatches += length( $segments[ $i + 1 ] );
        }
        push @super_segments, $segment;
    }
    return [ grep { $self->segment_filter->($_) } @super_segments ];
}

sub _build__segment_filter {
    my ($self) = @_;

    return sub {
        my ($segment) = @_;

        $segment = uc($segment);
        return if ( length($segment) < $self->min_primer_length );
        my $min = $self->min_primer_length - 2;
        return unless ( $segment =~ /[GC]{2}.{$min}/ || $segment =~ /.{$min}[GC]{2}/ );

        return 1;
    };
}

sub filter_minimum_distances {
    my ( $self, $dist ) = @_;

    my $min = $self->min_primer_distance;
    my $max = $self->max_primer_distance;

    my %freq;
    my %seen_seq_ids;
    for my $d (@$dist) {
        $seen_seq_ids{ $d->{id} } = 1;
        if ( $d->{dist} >= $min && $d->{dist} <= $max ) {
            $freq{ $d->{apid} . "#" . $d->{bpid} }++;
        }
    }

    my @res;
    while ( my ( $pids, $freq ) = each %freq ) {
        #add to results if exists in every sequence
        if ( $freq == keys %seen_seq_ids ) {
            my ( $p1, $p2 ) = split /#/, $pids, 2;
            push @res,
                grep { ( $p1 eq $_->{apid} && $p2 eq $_->{bpid} ) || ( $p1 eq $_->{bpid} && $p2 eq $_->{apid} ) }
                @$dist;
        }
    }
    return \@res if ( @res > 0 );

    return;
}

sub primer_distances {
    my ( $self, $res ) = @_;

    my @distances;
    while ( my ( $id, $locs ) = each %$res ) {
        if ( @$locs < 2 ) {
            if ( @$locs == 1 && length( $locs->[0]->{seq} ) > 2 * $self->min_primer_length ) {
                my $p = $locs->[0];
                push @distances,
                    {
                    id      => $id,
                    apid    => $p->{primer_id},
                    bpid    => $p->{primer_id},
                    abegin  => $p->{range}[0],
                    aend    => $p->{range}[1],
                    bbegin  => $p->{range}[0],
                    bend    => $p->{range}[1],
                    dist    => 0, #( length( $p->{seq} ) - 2 * $self->min_primer_length ),
                    aseq    => $p->{seq},
                    bseq    => $p->{seq},
                    alength => length( $p->{seq} ),
                    blength => length( $p->{seq} ),
                    };
                    next;
            } else {
                return;
            }
        }

        for ( my $i = 0; $i < @$locs - 1; $i++ ) {
            for ( my $j = $i + 1; $j < @$locs; $j++ ) {
                #by definition overlap not possible ;) TODO
                #if $i primer start > $j primer end
                my $dist;
                my $pa = $locs->[$i];
                my $pb = $locs->[$j];

                if ( not( $pa->{range}[0] > $pb->{range}[1] || $pa->{range}[1] < $pb->{range}[0] ) ) {
                    #overlap
                    $dist = -1;
                } elsif ( $pa->{range}[0] > $pb->{range}[1] ) {
                    #$i lies after $j
                    $dist = $pa->{range}[0] - $pb->{range}[1];
                } else {
                    #$i lies before $j
                    $dist = $pb->{range}[0] - $pa->{range}[1];
                }
                if ( $dist > 0 ) {
                    push @distances,
                        {
                        id      => $id,
                        apid    => $pa->{primer_id},
                        bpid    => $pb->{primer_id},
                        abegin  => $pa->{range}[0],
                        aend    => $pa->{range}[1],
                        bbegin  => $pb->{range}[0],
                        bend    => $pb->{range}[1],
                        dist    => $dist,
                        aseq    => $pa->{seq},
                        bseq    => $pb->{seq},
                        alength => length($pa->{seq}),
                        blength => length($pb->{seq}),
                        };
                }
            }
        }
    }
    return \@distances;
}

sub consensus_string {
    my ( $seqs, $mismatch ) = @_;

    my $consensus = '';

    for ( my $i = 0; $i < length( $seqs->[0]->seq ); $i++ ) {
        $consensus .= consensus_point( $seqs, $i, $mismatch );
    }

    return $consensus;
}

sub consensus_point {
    my ( $seqs, $point, $mismatch ) = @_;

    my %cfreq;
    for my $s (@$seqs) {
        my $c = substr $s->seq, $point, 1;

        # point becomes -
        $c = '-' if ( $c eq '.' );

        #all uppercase
        $c = uc($c);
        $c = '?' if ( $c !~ /^[-AGCTN]$/ );

        $cfreq{$c}++;
    }

    my $num_different_chars = keys %cfreq;
    if ( $num_different_chars > 1 ) {
        #not all characters are the same

        #mismatch allowed, but not with a gap in one of the sequences
        if ( $mismatch && !( exists( $cfreq{'-'} ) || exists( $cfreq{'?'} ) ) ) {
            return ".";
        } else {
            return '?';
        }
    } elsif ( $num_different_chars == 1 ) {
        #all characters are the same
        return ( keys %cfreq )[0];
    } else {
        confess "ERROR";
    }

    return;
}

sub avg_minimum {
    my $m   = shift;
    my $min = 1;
    my $idx;

    for ( my $i = 0; $i < @$m; $i++ ) {
        my @row = @{ $m->[$i] };
        #get rid of the '1'
        pop @row;
        for ( my $j = $i + 1; $j < @$m; $j++ ) {
            push @row, $m->[$j][$i];
        }
        my $avg = sum(@row) / scalar @row;
        if ( $avg < $min ) {
            $min = $avg;
            $idx = $i;
        }
    }
    unless ( defined($idx) ) {
        print STDERR Dumper $m;
        return;
    }
    return $idx;
}

sub minimum {
    my $m   = shift;
    my $min = 1;
    my $row_idx;
    my $col_idx;

    for ( my $i = 0; $i < @$m; $i++ ) {
        for ( my $j = 0; $j < @{ $m->[$i] }; $j++ ) {
            if ( $m->[$i][$j] < $min ) {
                $min     = $m->[$i][$j];
                $row_idx = $i;
                $col_idx = $j;
            }
        }
    }

    return unless ( defined($row_idx) && defined($col_idx) );
    return ( $row_idx, $col_idx );
}

sub pi {
    return pairwise_identity_s(@_) * pairwise_identity_gaps_s(@_);
}

sub to_csv {
    my ( $class, $result ) = @_;

    my @header = qw/
        file
        cluster_id
        catched_count
        cluster_count
        sequence_id
        primer_a_id
        primer_b_id
        primer_a_begin
        primer_a_end
        primer_b_begin
        primer_b_end
        distance
        primer_a_seq
        primer_b_seq
        /;
    my @csv = ( join( "\t", @header ) );

    for my $r (@$result) {
        push @csv, join "\t", @{$r}{@header};
    }

    return join( "\n", @csv ) . "\n";
}

1;
