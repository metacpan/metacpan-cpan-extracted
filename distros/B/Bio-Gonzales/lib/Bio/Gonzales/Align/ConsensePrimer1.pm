package Bio::Gonzales::Align::ConsensePrimer1;

use Mouse;

use warnings;
use strict;

use 5.010;

use Bio::Gonzales::Seq::IO qw/faslurp faspew/;
use Bio::Gonzales::Seq::Util qw/pairwise_identities pairwise_identity_gaps_s pairwise_identity_s/;
use List::Util qw/sum/;
use List::MoreUtils qw/indexes any zip/;
use Data::Dumper;


our $VERSION = '0.0546'; # VERSION

has cds_seqs            => ( is => 'rw', required => 1 );
has genomic_seqs        => ( is => 'rw', required => 1 );
has min_primer_distance => ( is => 'rw', default  => 800 );
has max_primer_distance => ( is => 'rw', default  => 2500 );
has mismatch            => ( is => 'rw', default  => 0 );
has min_primer_length   => ( is => 'rw', default  => 11 );
has name                => ( is => 'rw', default  => 'seq' );
has primer_filter       => ( is => 'rw', );

sub run {
    my ($self) = @_;

    my $queue = $self->cds_seqs;

    my @overall_result;

    my @done;

    #run till all cds seqs are considered
    while ( @$queue > 0 ) {
        my $seqs = $queue;
        $queue = [];

        while ( @$seqs > 1 ) {
            #redo alignment
            $seqs = $self->realign($seqs);

            #create consensus sequence
            my $consensus = consensus_string( $seqs, $self->mismatch );
            #remove positions where all sequences have gaps
            $consensus =~ s/-//g;

            #find continous sequence patches
            my $pieces = $self->_find_pieces($consensus);

            #find the positions of the patches
            my $primer_positions = $self->primer_positions( $seqs, $pieces );

            #calculate the distances of the postions
            my $primer_distances = $self->primer_distances($primer_positions);


            #and filter for them
            my $filtered_distances = $self->filter_minimum_distances($primer_distances);
            if ( $filtered_distances && @$filtered_distances > 0 ) {
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
                        };

                }
                push @done, @$seqs;
                last;
            }

            #find the most UNsimilar sequence and kick it out
            my $m = pairwise_identities( \&pi, @$seqs );
            my $idx = avg_minimum($m);

            $self->log->info("SEQ\n" . Dumper(map { $_->id} @$seqs));
            $self->log->info("QUE\n" . Dumper(map { $_->id} @$queue));
            $self->log->info("DON\n" . Dumper(map { $_->id} @done));

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
                };
            push @done, @$seqs;
        }
            $self->log->info("SEQ\n" . Dumper(map { $_->id} @$seqs));
            $self->log->info("QUE\n" . Dumper(map { $_->id} @$queue));
            $self->log->info("DON\n" . Dumper(map { $_->id} @done));
    }
    return \@overall_result;
}

sub realign {
    my ( $self, $seqs ) = @_;

    my $tmp_in  = 'seqtmp.fa';
    my $tmp_out = 'seqtmp.aln.fa';
    faspew $tmp_in, $seqs;

    system "mafft --maxiterate 1000 --globalpair $tmp_in 2>/dev/null >$tmp_out";

    my $realigned_seqs = faslurp $tmp_out;
    unlink $tmp_out;

    return $realigned_seqs;
}

sub primer_positions {
    my ( $self, $seqs, $pieces ) = @_;

    my %primer_positions;
    my $genomic_seqs = $self->genomic_seqs;

    for my $gseq (@$genomic_seqs) {
        next unless ( any { my $id = $_->id; $gseq->id =~ /$id/ } @$seqs );
        $primer_positions{ $gseq->id } //= [];
        my $i = 0;
        for my $piece (@$pieces) {
            if ( $gseq->seq =~ /$piece/i ) {
                push @{ $primer_positions{ $gseq->id } },
                    { seq => $piece, range => [ $-[0] + 1, $+[0] ], primer_id => "p" . $i++ };
            }
        }
    }
    return \%primer_positions;
}

sub _find_pieces {
    my ( $self, $consensus ) = @_;
    my $min_length = $self->min_primer_length;
    #split into continuous pieces
    my @pieces = split /(\?+)/, $consensus;
    my @found;
    for my $p (@pieces) {
        next if ( $p =~ /^\?/ );
        #check length
        ( my $pl = $p ) =~ s/\[\w{2}\]/./g;
        next if ( length($pl) < $min_length );
        #check continuous piece with one mismatch
        my $forward_regex_gc  = qr/\w*(\[\w{2}\])?\w{11,}[GC]{2}/;
        my $backward_regex_gc = qr/[GC]{2}\w{11,}(\[\w{2}\])?\w*/;

        my $forward_regex  = qr/\w*(\[\w{2}\])?\w{13,}/;
        my $backward_regex = qr/\w{13,}(\[\w{2}\])?\w*/;
        print STDERR ".";

        while ( $p =~ /$forward_regex_gc/g ) {
            print STDERR "+";
            my $match = substr( $p, $-[0], $+[0] - $-[0] );
            my $extra_len = 0;
            $extra_len = 3 if ($1);
            push @found, $match if ( length($match) - $extra_len >= $min_length );
        }
        while ( $p =~ /$backward_regex_gc/g ) {
            print STDERR "*";
            my $match = substr( $p, $-[0], $+[0] - $-[0] );
            my $extra_len = 0;
            $extra_len = 3 if ($1);
            push @found, $match if ( length($match) - $extra_len >= $min_length );
        }

    }

    #my @p_idx = indexes {
    #length($_) >= $min_length
    #&& ( substr( $_, -2, 2 ) =~ /^[GC]{2}$/ || substr( $_, 0, 2 ) =~ /^[GC]{2}$/ );
    #}

    #}
    return \@found;
}

sub filter_minimum_distances {
    my ( $self, $dist ) = @_;

    my $min = $self->min_primer_distance;
    my $max = $self->max_primer_distance;

    my %freq;
    my %seq_ids;
    for my $d (@$dist) {
        $seq_ids{ $d->{id} } = 1;
        if ( $d->{dist} >= $min && $d->{dist} <= $max ) {
            $freq{ $d->{apid} . "#" . $d->{bpid} }++;
        }
    }

    my @res;
    while ( my ( $pids, $freq ) = each %freq ) {
        #add to results if exists in every sequence
        if ( $freq == keys %seq_ids ) {
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
        return
            if ( @$locs < 2 );

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
                    ( my $paseq = $pa->{seq} ) =~ s/\[\w{2}\]/./g;
                    ( my $pbseq = $pb->{seq} ) =~ s/\[\w{2}\]/./g;
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
                        alength => length($paseq),
                        blength => length($pbseq),
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

        # point become -
        $c = '-' if ( $c eq '.' );

        #all uppercase
        $c = uc($c);
        $c = '?' if ( $c !~ /^[-AGCTN]$/ );

        $cfreq{$c}++;
    }

    my $num_different_chars = keys %cfreq;
    if ( $num_different_chars > 1 ) {
        #not all characters are the same

        #one mismatch allowed, but not with a gap in one of the sequences
        if ( $mismatch && $num_different_chars == 2 && !( exists( $cfreq{'-'} ) || exists( $cfreq{'?'} ) ) ) {
            return "[" . join( "", keys %cfreq ) . "]";
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

    return unless ( defined($idx) );
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
