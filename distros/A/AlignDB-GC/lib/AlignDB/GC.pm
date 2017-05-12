package AlignDB::GC;
use Moose;
use List::Util;
use YAML::Syck;
use AlignDB::IntSpan;

our $VERSION = '1.1.0';

has 'wave_window_size' => ( is => 'rw', isa => 'Int',  default => 100, );
has 'wave_window_step' => ( is => 'rw', isa => 'Int',  default => 50, );
has 'vicinal_size'     => ( is => 'rw', isa => 'Int',  default => 500, );
has 'fall_range'       => ( is => 'rw', isa => 'Num',  default => 0.1, );
has 'gsw_size'         => ( is => 'rw', isa => 'Int',  default => 100, );
has 'stat_window_size' => ( is => 'rw', isa => 'Int',  default => 100, );
has 'stat_window_step' => ( is => 'rw', isa => 'Int',  default => 100, );
has 'skip_mdcw'        => ( is => 'rw', isa => 'Bool', default => 0, );

sub segment {
    my $self           = shift;
    my $comparable_set = shift;
    my $segment_size   = shift;
    my $segment_step   = shift;

    # if not given $segment_size, do a whole alignment analysis
    my @segment_windows;
    if ($segment_size) {
        @segment_windows = $self->sliding_window( $comparable_set, $segment_size, $segment_step );
    }
    else {
        push @segment_windows, $comparable_set;
    }

    return @segment_windows;
}

sub sliding_window {
    my $self = shift;
    my AlignDB::IntSpan $comparable_set = shift;

    my $window_size = shift || $self->wave_window_size;
    my $window_step = shift || $self->wave_window_step;

    my $comparable_number = $comparable_set->size;

    my @sliding_windows;
    my $sliding_start = 1;
    while (1) {
        my $sliding_end = $sliding_start + $window_size - 1;
        last if $sliding_end > $comparable_number;
        my $sliding_window = $comparable_set->slice( $sliding_start, $sliding_end );
        $sliding_start += $window_step;

        push @sliding_windows, $sliding_window;
    }

    return @sliding_windows;
}

sub _calc_gc_ratio {
    my @seqs = @_;

    my @ratios;
    for my $seq (@seqs) {

        # Count all four bases
        my $a_count = $seq =~ tr/Aa/Aa/;
        my $g_count = $seq =~ tr/Gg/Gg/;
        my $c_count = $seq =~ tr/Cc/Cc/;
        my $t_count = $seq =~ tr/Tt/Tt/;

        my $four_count = $a_count + $g_count + $c_count + $t_count;
        my $gc_count   = $g_count + $c_count;

        if ( $four_count == 0 ) {
            next;
        }
        else {
            my $gc_ratio = $gc_count / $four_count;
            push @ratios, $gc_ratio;
        }
    }

    return _mean(@ratios);
}

sub segment_gc_stat {
    my $self                         = shift;
    my $seqs_ref                     = shift;
    my AlignDB::IntSpan $segment_set = shift;

    my $window_size = shift || $self->stat_window_size;
    my $window_step = shift || $self->stat_window_step;

    my $segment_number = $segment_set->size;

    # There should be at least 2 sample, i.e., two sliding windows in the segment
    if ( $segment_number < $window_size + $window_step ) {
        return ( undef, undef, undef, undef );
    }

    my @seqs = @{$seqs_ref};

    my @sliding_windows = $self->sliding_window( $segment_set, $window_size, $window_step );
    my @sliding_gcs;

    foreach my $sliding_set (@sliding_windows) {
        my @sliding_seqs = map { $sliding_set->substr_span($_) } @seqs;
        my $sliding_gc = _calc_gc_ratio(@sliding_seqs);
        push @sliding_gcs, $sliding_gc;
    }

    my $gc_mean = _mean(@sliding_gcs);
    my $gc_std  = _stddev(@sliding_gcs);
    my $gc_cv
        = $gc_mean == 0 || $gc_mean == 1 ? undef
        : $gc_mean <= 0.5 ? $gc_std / $gc_mean
        :                   $gc_std / ( 1 - $gc_mean );
    my $gc_mdcw = $self->skip_mdcw ? undef : _mdcw(@sliding_gcs);

    return ( $gc_mean, $gc_std, $gc_cv, $gc_mdcw );
}

sub _center_resize {
    my AlignDB::IntSpan $old_set    = shift;
    my AlignDB::IntSpan $parent_set = shift;
    my $resize                      = shift;

    # find the middles of old_set
    my $half_size           = int( $old_set->size / 2 );
    my $midleft             = $old_set->at($half_size);
    my $midright            = $old_set->at( $half_size + 1 );
    my $midleft_parent_idx  = $parent_set->index($midleft);
    my $midright_parent_idx = $parent_set->index($midright);

    return unless $midleft_parent_idx and $midright_parent_idx;

    # map to parent
    my $parent_size  = $parent_set->size;
    my $half_resize  = int( $resize / 2 );
    my $new_left_idx = $midleft_parent_idx - $half_resize + 1;
    $new_left_idx = 1 if $new_left_idx < 1;
    my $new_right_idx = $midright_parent_idx + $half_resize - 1;
    $new_right_idx = $parent_size if $new_right_idx > $parent_size;

    my $new_set = $parent_set->slice( $new_left_idx, $new_right_idx );

    return $new_set;
}

sub segment_gc_stat_one {
    my $self           = shift;
    my $seqs_ref       = shift;
    my $comparable_set = shift;
    my $segment_set    = shift;

    my $stat_segment_size = 500;

    my $resize_set = _center_resize( $segment_set, $comparable_set, $stat_segment_size );
    next unless $resize_set;

    my @segment_seqs = map { $segment_set->substr_span($_) } @{$seqs_ref};

    my $gc_mean = _calc_gc_ratio(@segment_seqs);
    my ( $gc_std, $gc_mdcw ) = ( undef, undef );

    my ( undef, undef, $gc_cv, undef ) = $self->segment_gc_stat( $seqs_ref, $resize_set, 100, 100 );

    return ( $gc_mean, $gc_std, $gc_cv, $gc_mdcw );
}

sub _mean {
    @_ = grep { defined $_ } @_;
    return unless @_;
    return $_[0] unless @_ > 1;
    return List::Util::sum(@_) / scalar(@_);
}

sub _variance {
    @_ = grep { defined $_ } @_;
    return   unless @_;
    return 0 unless @_ > 1;
    my $mean = _mean(@_);
    return List::Util::sum( map { ( $_ - $mean )**2 } @_ ) / $#_;
}

sub _stddev {
    @_ = grep { defined $_ } @_;
    return   unless @_;
    return 0 unless @_ > 1;
    return sqrt( _variance(@_) );
}

sub _mdcw {
    my @array = @_;

    if ( @array <= 1 ) {
        warn "There should be more than 1 elements in the array.\n";
        return;
    }

    my @dcws;
    for ( 1 .. $#array ) {
        my $dcw = $array[$_] - $array[ $_ - 1 ];
        push @dcws, abs($dcw);
    }

    return _mean(@dcws);
}

# find local maxima, minima
sub find_extreme_step1 {
    my $self    = shift;
    my $windows = shift;

    my $count = scalar @$windows;

    my $wave_window_size = $self->wave_window_size;
    my $wave_window_step = $self->wave_window_step;
    my $vicinal_size     = $self->vicinal_size;
    my $vicinal_number   = int( $vicinal_size / $wave_window_step );

    for my $i ( 0 .. $count - 1 ) {

        #----------------------------#
        # right vicinal window
        #----------------------------#
        my @right_vicinal_windows;
        my ( $right_low, $right_high, $right_flag );
        foreach ( $i + 1 .. $i + $vicinal_number ) {
            next unless $_ < $count;
            push @right_vicinal_windows, $windows->[$_]->{sw_gc};
        }

        if ( scalar @right_vicinal_windows == 0 ) {
            $right_low  = 0;
            $right_high = 0;
        }
        else {
            if ( $windows->[$i]->{sw_gc} >= List::Util::max(@right_vicinal_windows) ) {
                $right_low = 1;
            }
            if ( $windows->[$i]->{sw_gc} <= List::Util::min(@right_vicinal_windows) ) {
                $right_high = 1;
            }
        }

        if ( $right_low and $right_high ) {
            print " " x 4, "Can't determine right vicinity.\n";
            $right_flag = 'N';    # non
        }
        elsif ($right_low) {
            $right_flag = 'L';    # low
        }
        elsif ($right_high) {
            $right_flag = 'H';    # high
        }
        else {
            $right_flag = 'N';
        }

        $windows->[$i]->{right_flag} = $right_flag;

        #----------------------------#
        # left vicinal window
        #----------------------------#
        my @left_vicinal_windows;
        my ( $left_low, $left_high, $left_flag );
        foreach ( $i - $vicinal_number .. $i - 1 ) {
            next if $_ < 0;
            push @left_vicinal_windows, $windows->[$_]->{sw_gc};
        }

        if ( scalar @left_vicinal_windows == 0 ) {
            $left_low  = 0;
            $left_high = 0;
        }
        else {
            if ( $windows->[$i]->{sw_gc} >= List::Util::max(@left_vicinal_windows) ) {
                $left_low = 1;
            }
            if ( $windows->[$i]->{sw_gc} <= List::Util::min(@left_vicinal_windows) ) {
                $left_high = 1;
            }
        }

        if ( $left_low and $left_high ) {
            print " " x 4, "Can't determine left vicinity.\n";
            $left_flag = 'N';
        }
        elsif ($left_low) {
            $left_flag = 'L';
        }
        elsif ($left_high) {
            $left_flag = 'H';
        }
        else {
            $left_flag = 'N';
        }

        $windows->[$i]->{left_flag} = $left_flag;

        # high or low window
        my ($high_low_flag);

        if ( $left_flag eq 'H' and $right_flag eq 'H' ) {
            $high_low_flag = 'T';    # trough
        }
        elsif ( $left_flag eq 'L' and $right_flag eq 'L' ) {
            $high_low_flag = 'C';    # crest
        }
        else {
            $high_low_flag = 'N';
        }
        $windows->[$i]->{high_low_flag} = $high_low_flag;
    }

    return;
}

sub find_extreme_step2 {
    my $self    = shift;
    my $windows = shift;

    my $count = scalar @$windows;

    my $fall_range       = $self->fall_range;
    my $vicinal_size     = $self->vicinal_size;
    my $wave_window_step = $self->wave_window_step;
    my $vicinal_number   = int( $vicinal_size / $wave_window_step );

REDO: while (1) {
        my @extreme;
        for my $i ( 0 .. $count - 1 ) {
            my $flag = $windows->[$i]->{high_low_flag};
            if ( $flag eq 'T' or $flag eq 'C' ) {
                push @extreme, $i;
            }
        }

        # Ensure there are no crest--crest or trough--trough
        for my $i ( 0 .. scalar @extreme - 1 ) {
            my $wave = $windows->[ $extreme[$i] ]->{high_low_flag};
            my $gc   = $windows->[ $extreme[$i] ]->{sw_gc};
            my ( $left_wave, $right_wave ) = ( ' ', ' ' );
            my ( $left_gc,   $right_gc )   = ( 0,   0 );

            if ( $i - 1 >= 0 ) {
                $left_gc   = $windows->[ $extreme[ $i - 1 ] ]->{sw_gc};
                $left_wave = $windows->[ $extreme[ $i - 1 ] ]->{high_low_flag};
            }
            if ( $i + 1 < scalar @extreme ) {
                $right_gc   = $windows->[ $extreme[ $i + 1 ] ]->{sw_gc};
                $right_wave = $windows->[ $extreme[ $i + 1 ] ]->{high_low_flag};
            }

            if ( $wave eq 'T' ) {
                if ( $wave eq $left_wave ) {
                    if ( $gc <= $left_gc ) {
                        $windows->[ $extreme[ $i - 1 ] ]->{high_low_flag} = 'N';
                        next REDO;
                    }
                }
                if ( $wave eq $right_wave ) {
                    if ( $gc < $right_gc ) {
                        $windows->[ $extreme[ $i + 1 ] ]->{high_low_flag} = 'N';
                        next REDO;
                    }
                }
            }
            elsif ( $wave eq 'C' ) {
                if ( $wave eq $left_wave ) {
                    if ( $gc >= $left_gc ) {
                        $windows->[ $extreme[ $i - 1 ] ]->{high_low_flag} = 'N';
                        next REDO;
                    }
                }
                if ( $wave eq $right_wave ) {
                    if ( $gc > $right_gc ) {
                        $windows->[ $extreme[ $i + 1 ] ]->{high_low_flag} = 'N';
                        next REDO;
                    }
                }
            }
            else {
                warn "high_low_flag signal errors\n";
            }
        }

        # delete nesting crest--trough
        for my $i ( 0 .. scalar @extreme - 1 ) {
            my $wave = $windows->[ $extreme[$i] ]->{high_low_flag};
            my $gc   = $windows->[ $extreme[$i] ]->{sw_gc};
            my ( $wave1, $wave2, $wave3 ) = ( ' ', ' ', ' ' );
            my ( $gc1,   $gc2,   $gc3 )   = ( 0,   0,   0 );

            if ( $i + 3 < scalar @extreme ) {

                # next 1
                $wave1 = $windows->[ $extreme[ $i + 1 ] ]->{high_low_flag};
                $gc1   = $windows->[ $extreme[ $i + 1 ] ]->{sw_gc};

                # next 2
                $wave2 = $windows->[ $extreme[ $i + 2 ] ]->{high_low_flag};
                $gc2   = $windows->[ $extreme[ $i + 2 ] ]->{sw_gc};

                # next 3
                $wave3 = $windows->[ $extreme[ $i + 3 ] ]->{high_low_flag};
                $gc3   = $windows->[ $extreme[ $i + 3 ] ]->{sw_gc};
            }
            else {
                next;
            }

            if ( abs( $gc1 - $gc2 ) < $fall_range ) {
                if (    List::Util::max( $gc1, $gc2 ) < List::Util::max( $gc, $gc3 )
                    and List::Util::min( $gc1, $gc2 ) > List::Util::min( $gc, $gc3 ) )
                {
                    $windows->[ $extreme[ $i + 1 ] ]->{high_low_flag} = 'N';
                    $windows->[ $extreme[ $i + 2 ] ]->{high_low_flag} = 'N';
                    next REDO;
                }
            }
        }

        # delete small fall-range crest--trough
        for my $i ( 0 .. scalar @extreme - 1 ) {
            my $wave = $windows->[ $extreme[$i] ]->{high_low_flag};
            my $gc   = $windows->[ $extreme[$i] ]->{sw_gc};
            my ( $wave1, $wave2 ) = ( ' ', ' ' );
            my ( $gc1,   $gc2 )   = ( 0,   0 );

            if ( $i + 2 < scalar @extreme ) {

                # next 1
                $wave1 = $windows->[ $extreme[ $i + 1 ] ]->{high_low_flag};
                $gc1   = $windows->[ $extreme[ $i + 1 ] ]->{sw_gc};

                # next 2
                $wave2 = $windows->[ $extreme[ $i + 2 ] ]->{high_low_flag};
                $gc2   = $windows->[ $extreme[ $i + 2 ] ]->{sw_gc};
            }
            else {
                next;
            }

            if (    abs( $gc1 - $gc ) < $fall_range
                and abs( $gc2 - $gc1 ) < $fall_range )
            {
                $windows->[ $extreme[ $i + 1 ] ]->{high_low_flag} = 'N';
                next REDO;
            }
        }

        # delete vicinal crest--trough
        for my $i ( 0 .. scalar @extreme - 1 ) {
            my $wave = $windows->[ $extreme[$i] ]->{high_low_flag};
            my $gc   = $windows->[ $extreme[$i] ]->{sw_gc};

            if ( $i + 1 < scalar @extreme ) {
                if ( $extreme[ $i + 1 ] - $extreme[$i] < $vicinal_number ) {
                    $windows->[ $extreme[ $i + 1 ] ]->{high_low_flag} = 'N';
                    next REDO;
                }
            }
        }

        my @extreme2;
        for my $i ( 0 .. $count - 1 ) {
            my $flag = $windows->[$i]->{high_low_flag};
            if ( $flag eq 'T' or $flag eq 'C' ) {
                push @extreme2, $i;
            }
        }

        if ( scalar @extreme == scalar @extreme2 ) {
            last;
        }
    }

    return;
}

sub gc_wave {
    my $self           = shift;
    my $seqs_ref       = shift;
    my $comparable_set = shift;

    my @seqs = @{$seqs_ref};

    my @sliding_windows = $self->sliding_window($comparable_set);

    my @sliding_attrs;
    for my $i ( 0 .. $#sliding_windows ) {
        my $sliding_window = $sliding_windows[$i];

        my @sw_seqs = map { $sliding_window->substr_span($_) } @seqs;
        my $sw_gc = _calc_gc_ratio(@sw_seqs);

        my $sw_length = $sliding_window->size;
        my $sw_span   = scalar $sliding_window->spans;
        my $sw_indel  = $sw_span - 1;

        $sliding_attrs[$i] = {
            sw_set    => $sliding_window,
            sw_length => $sw_length,
            sw_gc     => $sw_gc,
            sw_indel  => $sw_indel,
        };
    }

    $self->find_extreme_step1( \@sliding_attrs );
    $self->find_extreme_step2( \@sliding_attrs );

    my @slidings;
    for (@sliding_attrs) {
        push @slidings,
            {
            set           => $_->{sw_set},
            high_low_flag => $_->{high_low_flag},
            gc            => $_->{sw_gc},
            };
    }

    return @slidings;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

AlignDB::GC - GC-related analysises

=head1 ATTRIBUTES

    extreme sliding window size
    extreme sliding window step
    vicinal size
    minimal fall range
    gsw window size
    extreme sliding window size
    extreme sliding window step
    skip calc mdcw

=head1 METHODS

    segment
    sliding_window
    gc_wave

=head1 AUTHOR

Qiang Wang <wang-q@outlook.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Qiang Wang.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
