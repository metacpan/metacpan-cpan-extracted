package AlignDB::Window;
use Moose;
use Carp;

use List::Util;
use YAML::Syck;
use AlignDB::IntSpan;

our $VERSION = '1.1.0';

has 'sw_size'          => ( is => 'rw', isa => 'Int', default => sub {100}, );
has 'min_interval'     => ( is => 'rw', isa => 'Int', default => sub {11}, );
has 'max_out_distance' => ( is => 'rw', isa => 'Int', default => sub {10}, );
has 'max_in_distance'  => ( is => 'rw', isa => 'Int', default => sub {5}, );

sub interval_window {
    my $self = shift;
    my AlignDB::IntSpan $comparable_set = shift;
    my ( $interval_start, $interval_end, $sw_size, $min_interval ) = @_;

    # if undefined, set to default values
    $sw_size      ||= $self->sw_size;
    $min_interval ||= $self->min_interval;

    my $interval_set = AlignDB::IntSpan->new->add_pair( $interval_start, $interval_end );
    $interval_set = $interval_set->intersect($comparable_set);
    my $interval_length = $interval_set->size;

    my $density = int( $interval_length / $sw_size ) - 1;

    # used for mark windows
    my ( $tmp_start, $tmp_end ) = ( 1, $interval_length );

    my @interval_windows;

    # More windows will be submitted in the following for-loop
    #   and if section
    if ( $interval_length < $min_interval ) {
        return @interval_windows;
    }
    elsif ( $interval_length < $sw_size ) {

        # $interval_length between $min_interval and 99 bp
        my %window_info;
        $window_info{set}      = $interval_set;
        $window_info{distance} = -1;
        $window_info{density}  = $density;
        $window_info{type}     = 'S';
        push @interval_windows, \%window_info;

        return @interval_windows;
    }
    elsif ( $interval_length < $sw_size * 2 ) {

        # $interval_length between 100 and 199 bp
        # LO between 50 and 100 bp
        # R0 between 50 and 99 bp
        # left windows
        my %l_window_info;
        my $l_start = $tmp_start;
        my $l_end   = $l_start + int( $interval_length / 2 ) - 1;
        if ( $interval_length % 2 ) {
            $l_end++;
        }
        $l_window_info{set}      = $interval_set->slice( $l_start, $l_end );
        $l_window_info{distance} = 0;
        $l_window_info{density}  = $density;
        $l_window_info{type}     = 'L';
        push @interval_windows, \%l_window_info;

        # right windows
        my %r_window_info;
        my $r_end   = $tmp_end;
        my $r_start = $r_end - int( $interval_length / 2 ) + 1;
        $r_window_info{set}      = $interval_set->slice( $r_start, $r_end );
        $r_window_info{distance} = 0;
        $r_window_info{density}  = $density;
        $r_window_info{type}     = 'R';
        push @interval_windows, \%r_window_info;

        return @interval_windows;
    }
    else {

        # LO => 50 bp, R0 => 50 bp
        # left windows
        my %l_window_info;
        my $l_start = $tmp_start;
        my $l_end   = $l_start + $sw_size / 2 - 1;
        $l_window_info{set}      = $interval_set->slice( $l_start, $l_end );
        $l_window_info{distance} = 0;
        $l_window_info{density}  = $density;
        $l_window_info{type}     = 'L';
        push @interval_windows, \%l_window_info;
        $tmp_start = $l_end + 1;

        # right windows
        my %r_window_info;
        my $r_end   = $tmp_end;
        my $r_start = $r_end - $sw_size / 2 + 1;
        $r_window_info{set}      = $interval_set->slice( $r_start, $r_end );
        $r_window_info{distance} = 0;
        $r_window_info{density}  = $density;
        $r_window_info{type}     = 'R';
        push @interval_windows, \%r_window_info;
        $tmp_end = $r_start - 1;
    }

    # regular 100 bp windows
    # When density IN (1, 2), this loop will be bypassed.
    my $half_windows_number = int( ( $density - 1 ) / 2 );
    for ( my $i = 1; $i <= $half_windows_number; $i++ ) {

        # left windows
        my %l_window_info;
        my $l_start = $tmp_start;
        my $l_end   = $l_start + $sw_size - 1;
        $l_window_info{set}      = $interval_set->slice( $l_start, $l_end );
        $l_window_info{distance} = $i;
        $l_window_info{density}  = $density;
        $l_window_info{type}     = 'L';
        push @interval_windows, \%l_window_info;
        $tmp_start = $l_end + 1;

        # right windows
        my %r_window_info;
        my $r_end   = $tmp_end;
        my $r_start = $r_end - $sw_size + 1;
        $r_window_info{set}      = $interval_set->slice( $r_start, $r_end );
        $r_window_info{distance} = $i;
        $r_window_info{density}  = $density;
        $r_window_info{type}     = 'R';
        push @interval_windows, \%r_window_info;
        $tmp_end = $r_start - 1;
    }

    # Three special windwos:
    #   1. Ln, range from 100 to 150 bp when even density number
    #   2. Rn, range from 100 to 149 bp when even density number
    #   3. Ln or Rn, range from 100 to 199 bp when odd density number
    if ( $density % 2 ) {

        # middle windows
        my %window_info;
        $window_info{set}      = $interval_set->slice( $tmp_start, $tmp_end );
        $window_info{distance} = $half_windows_number + 1;
        $window_info{density}  = $density;
        $window_info{type} = "L";    # rand > 0.5 ? "L" : "R";
        push @interval_windows, \%window_info;
    }
    else {
        my $remain_length = $tmp_end - $tmp_start + 1;

        # left windows
        my %l_window_info;
        my $l_start = $tmp_start;
        my $l_end   = $l_start + int( $remain_length / 2 ) - 1;
        if ( $remain_length % 2 ) {
            $l_end++;
        }
        $l_window_info{set}      = $interval_set->slice( $l_start, $l_end );
        $l_window_info{distance} = $half_windows_number + 1;
        $l_window_info{density}  = $density;
        $l_window_info{type}     = 'L';
        push @interval_windows, \%l_window_info;

        # right windows
        my %r_window_info;
        my $r_end   = $tmp_end;
        my $r_start = $r_end - int( $remain_length / 2 ) + 1;
        $r_window_info{set}      = $interval_set->slice( $r_start, $r_end );
        $r_window_info{distance} = $half_windows_number + 1;
        $r_window_info{density}  = $density;
        $r_window_info{type}     = 'R';
        push @interval_windows, \%r_window_info;
    }

    return @interval_windows;
}

sub outside_window {
    my $self = shift;
    my AlignDB::IntSpan $comparable_set = shift;
    my ( $internal_start, $internal_end, $sw_size, $maximal_distance ) = @_;

    # if undefined, set to default values
    $sw_size          ||= $self->sw_size;
    $maximal_distance ||= $self->max_out_distance;

    my $comparable_number = $comparable_set->size;

    my @outside_windows;

    for my $sw_type (qw{L R}) {

        # $sw_start and $sw_end are both index of $comparable_set
        my ( $sw_start, $sw_end );

        if ( $sw_type eq 'R' ) {
            $sw_start = $comparable_set->index($internal_end) + 1;
            $sw_end   = $sw_start + $sw_size - 1;
        }
        elsif ( $sw_type eq 'L' ) {
            $sw_end   = $comparable_set->index($internal_start) - 1;
            $sw_start = $sw_end - $sw_size + 1;
        }

        # $sw_distance is from 1 to $sw_max_distance
    OSW: for my $sw_distance ( 1 .. $maximal_distance ) {
            last if $sw_start < 1;
            last if $sw_end > $comparable_number;
            my $sw_set = $comparable_set->slice( $sw_start, $sw_end );
            my $sw_set_member_number = $sw_set->size;
            if ( $sw_set_member_number < $sw_size ) {
                last OSW;
            }

            my %window_info;
            $window_info{type}     = $sw_type;
            $window_info{set}      = $sw_set;
            $window_info{distance} = $sw_distance;

            push @outside_windows, \%window_info;

            if ( $sw_type eq 'R' ) {
                $sw_start = $sw_end + 1;
                $sw_end   = $sw_start + $sw_size - 1;
            }
            elsif ( $sw_type eq 'L' ) {
                $sw_end   = $sw_start - 1;
                $sw_start = $sw_end - $sw_size + 1;
            }
        }
    }

    return @outside_windows;
}

sub outside_window_2 {
    my $self = shift;
    my AlignDB::IntSpan $comparable_set = shift;
    my ( $internal_start, $internal_end, $sw_size, $maximal_distance ) = @_;

    # if undefined, set to default values
    $sw_size          ||= $self->sw_size;
    $maximal_distance ||= $self->max_out_distance;

    my $window0_size = int( $sw_size / 2 );

    my $comparable_number = $comparable_set->size;

    my @outside_windows;

    for my $sw_type (qw{L R}) {

        # $sw_start and $sw_end are both index of $comparable_set
        my ( $sw_start, $sw_end );

        if ( $sw_type eq 'R' ) {
            $sw_start = $comparable_set->index($internal_end) + 1;
            $sw_end   = $sw_start + $window0_size - 1;
        }
        elsif ( $sw_type eq 'L' ) {
            $sw_end   = $comparable_set->index($internal_start) - 1;
            $sw_start = $sw_end - $window0_size + 1;
        }

        # distance is from 0 to $maximal_distance
    OSW2: for my $sw_distance ( 0 .. $maximal_distance ) {
            last if $sw_start < 1;
            last if $sw_end > $comparable_number;
            my $sw_set = $comparable_set->slice( $sw_start, $sw_end );
            my $sw_set_member_number = $sw_set->size;
            if ( $sw_set_member_number < $window0_size ) {

                #                warn YAML::Syck::Dump {
                #                    sw_type  => $sw_type,
                #                    sw_start => $sw_start,
                #                    sw_end   => $sw_end,
                #                };
                last OSW2;
            }

            my %window_info;
            $window_info{type}     = $sw_type;
            $window_info{set}      = $sw_set;
            $window_info{distance} = $sw_distance;

            push @outside_windows, \%window_info;

            if ( $sw_type eq 'R' ) {
                $sw_start = $sw_end + 1;
                $sw_end   = $sw_start + $sw_size - 1;
            }
            elsif ( $sw_type eq 'L' ) {
                $sw_end   = $sw_start - 1;
                $sw_start = $sw_end - $sw_size + 1;
            }
        }
    }

    return @outside_windows;
}

sub inside_window {
    my $self = shift;
    my AlignDB::IntSpan $comparable_set = shift;
    my ( $internal_start, $internal_end, $sw_size, $maximal_distance ) = @_;

    # if undefined, set to default values
    $sw_size          ||= $self->sw_size;
    $maximal_distance ||= $self->max_in_distance;

    my @inside_windows;

    for my $sw_type (qw{l r}) {

        # $sw_start and $sw_end are both index of $comparable_set
        my ( $sw_start, $sw_end );

        my $working_set    = $comparable_set->intersect("$internal_start-$internal_end");
        my $working_length = $working_set->size;
        last if $working_length < $sw_size;

        # the 'r' and 'l' windows may overlap each other
        if ( $sw_type eq 'r' ) {
            $sw_end   = $working_set->size;
            $sw_start = $sw_end - $sw_size + 1;
        }
        elsif ( $sw_type eq 'l' ) {
            $sw_start = 1;
            $sw_end   = $sw_start + $sw_size - 1;
        }

        my $available_distance = int( $working_length / ( $sw_size * 2 ) );
        my $max_distance = List::Util::min( $available_distance, $maximal_distance );

        # sw_distance is from -1 to -max_distance
    ISW: for my $i ( 1 .. $max_distance ) {
            my $sw_set = $working_set->slice( $sw_start, $sw_end );
            my $sw_set_member_number = $sw_set->size;
            if ( $sw_set_member_number < $sw_size ) {
                last ISW;
            }
            my $sw_distance = -$i;

            my %window_info;
            $window_info{type}     = $sw_type;
            $window_info{set}      = $sw_set;
            $window_info{distance} = $sw_distance;

            push @inside_windows, \%window_info;

            if ( $sw_type eq 'r' ) {
                $sw_end   = $sw_start - 1;
                $sw_start = $sw_end - $sw_size + 1;
            }
            elsif ( $sw_type eq 'l' ) {
                $sw_start = $sw_end + 1;
                $sw_end   = $sw_start + $sw_size - 1;
            }
        }
    }

    return @inside_windows;
}

sub inside_window_2 {
    my $self = shift;
    my AlignDB::IntSpan $comparable_set = shift;
    my ( $internal_start, $internal_end, $sw_size, $maximal_distance ) = @_;

    # if undefined, set to default values
    $sw_size          ||= $self->sw_size;
    $maximal_distance ||= $self->max_in_distance;

    my @inside_windows;

    for my $sw_type (qw{l r}) {

        # $sw_start and $sw_end are both index of $comparable_set
        my ( $sw_start, $sw_end );

        my $working_set    = $comparable_set->intersect("$internal_start-$internal_end");
        my $working_length = $working_set->size;
        last if $working_length < $sw_size;

        # the windows start from the center
        if ( $sw_type eq 'r' ) {
            $sw_start = int( $working_length / 2 ) + 1;
            $sw_end   = $sw_start + $sw_size - 1;
        }
        elsif ( $sw_type eq 'l' ) {
            $sw_end   = int( $working_length / 2 );
            $sw_start = $sw_end - $sw_size + 1;
        }

        my $available_distance = int( $working_length / ( $sw_size * 2 ) );
        my $max_distance = List::Util::min( $available_distance, $maximal_distance );

        # sw_distance is from -90 to -90 + max_distance - 1
    ISW2: for my $i ( -90 .. ( -90 + $max_distance - 1 ) ) {
            my $sw_set = $working_set->slice( $sw_start, $sw_end );
            my $sw_set_member_number = $sw_set->size;
            if ( $sw_set_member_number < $sw_size ) {
                last ISW2;
            }
            my $sw_distance = $i;

            my %window_info;
            $window_info{type}     = $sw_type;
            $window_info{set}      = $sw_set;
            $window_info{distance} = $sw_distance;

            push @inside_windows, \%window_info;

            if ( $sw_type eq 'r' ) {
                $sw_start = $sw_end + 1;
                $sw_end   = $sw_start + $sw_size - 1;
            }
            elsif ( $sw_type eq 'l' ) {
                $sw_end   = $sw_start - 1;
                $sw_start = $sw_end - $sw_size + 1;
            }
        }
    }

    return @inside_windows;
}

sub center_window {
    my $self = shift;
    my AlignDB::IntSpan $comparable_set = shift;
    my ( $internal_start, $internal_end, $sw_size, $maximal_distance ) = @_;

    # if undefined, set to default values
    $sw_size          ||= $self->sw_size;
    $maximal_distance ||= $self->max_out_distance;

    my $comparable_number = $comparable_set->size;

    my @center_windows;

    my $original_set;
    if ( $internal_start < $internal_end ) {
        $original_set = AlignDB::IntSpan->new("$internal_start-$internal_end");
    }
    elsif ( $internal_start == $internal_end ) {
        $original_set = AlignDB::IntSpan->new($internal_start);
    }
    else {
        return;
    }

    my AlignDB::IntSpan $window0_set = _center_resize( $original_set, $comparable_set, $sw_size );
    return unless $window0_set;

    my $window0_start = $window0_set->min;
    my $window0_end   = $window0_set->max;
    push @center_windows,
        {
        type     => 'M',
        set      => $window0_set,
        distance => 0,
        };

    for my $sw_type (qw{L R}) {

        # $sw_start and $sw_end are both index of $comparable_set
        my ( $sw_start, $sw_end );

        if ( $sw_type eq 'R' ) {
            $sw_start = $comparable_set->index($window0_end) + 1;
            $sw_end   = $sw_start + $sw_size - 1;
        }
        elsif ( $sw_type eq 'L' ) {
            $sw_end   = $comparable_set->index($window0_start) - 1;
            $sw_start = $sw_end - $sw_size + 1;
        }

        # $sw_distance is from 1 to $maximal_distance
    CSW: for my $sw_distance ( 1 .. $maximal_distance ) {
            last if $sw_start < 1;
            last if $sw_end > $comparable_number;
            my $sw_set = $comparable_set->slice( $sw_start, $sw_end );
            my $sw_set_member_number = $sw_set->size;
            if ( $sw_set_member_number < $sw_size ) {
                last CSW;
            }

            push @center_windows,
                {
                type     => $sw_type,
                set      => $sw_set,
                distance => $sw_distance,
                };

            if ( $sw_type eq 'R' ) {
                $sw_start = $sw_end + 1;
                $sw_end   = $sw_start + $sw_size - 1;
            }
            elsif ( $sw_type eq 'L' ) {
                $sw_end   = $sw_start - 1;
                $sw_start = $sw_end - $sw_size + 1;
            }
        }
    }

    return @center_windows;
}

sub _center_resize {
    my AlignDB::IntSpan $old_set    = shift;
    my AlignDB::IntSpan $parent_set = shift;
    my $resize                      = shift;

    # find the middles of old_set
    my ( $midleft_parent_idx, $midright_parent_idx );
    {
        if ( $old_set->size == 1 ) {
            my $mid = $old_set->at(1);
            $midleft_parent_idx  = $parent_set->index($mid);
            $midright_parent_idx = $parent_set->index($mid);
        }
        else {
            my $half_size = int( $old_set->size / 2 );
            my $midleft   = $old_set->at($half_size);
            my $midright  = $old_set->at( $half_size + 1 );
            $midleft_parent_idx  = $parent_set->index($midleft);
            $midright_parent_idx = $parent_set->index($midright);
        }
    }
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

sub center_intact_window {
    my $self = shift;
    my AlignDB::IntSpan $comparable_set = shift;
    my ( $internal_start, $internal_end, $sw_size, $maximal_distance ) = @_;

    # if undefined, set to default values
    $sw_size          ||= $self->sw_size;
    $maximal_distance ||= $self->max_out_distance;

    my $comparable_number = $comparable_set->size;

    my @center_windows;

    my $original_set;
    if ( $internal_start < $internal_end ) {
        $original_set = AlignDB::IntSpan->new("$internal_start-$internal_end");
    }
    elsif ( $internal_start == $internal_end ) {
        $original_set = AlignDB::IntSpan->new($internal_start);
    }
    else {
        return;
    }

    my $window0_set;
    if ( $original_set->size < $sw_size ) {
        $window0_set = _center_resize( $original_set, $comparable_set, $sw_size );
    }
    else {
        $window0_set = $original_set->intersect($comparable_set);
    }

    return unless $window0_set;
    return unless $window0_set->size;

    my $window0_start = $window0_set->min;
    my $window0_end   = $window0_set->max;
    push @center_windows,
        {
        type     => 'M',
        set      => $window0_set,
        distance => 0,
        };

    for my $sw_type (qw{L R}) {

        # $sw_start and $sw_end are both index of $comparable_set
        my ( $sw_start, $sw_end );

        if ( $sw_type eq 'R' ) {
            $sw_start = $comparable_set->index($window0_end) + 1;
            $sw_end   = $sw_start + $sw_size - 1;
        }
        elsif ( $sw_type eq 'L' ) {
            $sw_end   = $comparable_set->index($window0_start) - 1;
            $sw_start = $sw_end - $sw_size + 1;
        }

        # $sw_distance is from 1 to $maximal_distance
    CISW: for my $sw_distance ( 1 .. $maximal_distance ) {
            last if $sw_start < 1;
            last if $sw_end > $comparable_number;
            my $sw_set = $comparable_set->slice( $sw_start, $sw_end );
            my $sw_set_member_number = $sw_set->size;
            if ( $sw_set_member_number < $sw_size ) {
                last CISW;
            }

            push @center_windows,
                {
                type     => $sw_type,
                set      => $sw_set,
                distance => $sw_distance,
                };

            if ( $sw_type eq 'R' ) {
                $sw_start = $sw_end + 1;
                $sw_end   = $sw_start + $sw_size - 1;
            }
            elsif ( $sw_type eq 'L' ) {
                $sw_end   = $sw_start - 1;
                $sw_start = $sw_end - $sw_size + 1;
            }
        }
    }

    return @center_windows;
}

sub strand_window {
    my $self = shift;
    my AlignDB::IntSpan $comparable_set = shift;
    my ( $internal_start, $internal_end, $sw_size, $strand ) = @_;

    # if undefined, set to default values
    $sw_size ||= $self->sw_size;
    $strand  ||= '+';

    my @windows;

    my $working_set;
    if ( $internal_start < $internal_end ) {
        $working_set = $comparable_set->intersect("$internal_start-$internal_end");
    }
    else {
        return @windows;
    }

    my $working_length = $working_set->size;
    return @windows if $working_length < $sw_size;

    # $sw_start and $sw_end are both index of $comparable_set
    my ( $sw_start, $sw_end );

    if ( $strand eq '+' ) {
        $sw_start = 1;
        $sw_end   = $sw_start + $sw_size - 1;
    }
    elsif ( $strand eq '-' ) {
        $sw_end   = $working_set->size;
        $sw_start = $sw_end - $sw_size + 1;
    }
    else {
        return @windows;
    }

    my $available_distance = int( $working_length / ($sw_size) );

    # sw_distance is from 1 to max_distance
SSW: for my $i ( 1 .. $available_distance ) {
        my $sw_set = $working_set->slice( $sw_start, $sw_end );
        my $sw_set_member_number = $sw_set->size;
        if ( $sw_set_member_number < $sw_size ) {
            last SSW;
        }
        my $sw_distance = $i;

        my %window_info;
        $window_info{type}     = $strand;
        $window_info{set}      = $sw_set;
        $window_info{distance} = $sw_distance;

        push @windows, \%window_info;

        if ( $strand eq '+' ) {
            $sw_start = $sw_end + 1;
            $sw_end   = $sw_start + $sw_size - 1;
        }
        elsif ( $strand eq '-' ) {
            $sw_end   = $sw_start - 1;
            $sw_start = $sw_end - $sw_size + 1;
        }
    }

    return @windows;
}

1;    # Magic true value required at end of module

__END__

=pod

=encoding UTF-8

=head1 NAME

AlignDB::Window - Split integer spans into a series of windows

=head1 DESCRIPTION

AlignDB::Window provides methods to split integer spans, including interval, inside area and
outside area, into a series of windows.

=head1 ATTRIBUTES

C<sw_size>          - sliding windows' size, default is 100

C<min_interval>     - mininal indel interval length, default is 11

C<max_out_distance> - maximal outside distance, default is 10

C<max_in_distance>  - maximal inside distance, default is 5

=head1 METHODS

=head2 common parameters

C<$comparable_set>      - AlignDB::IntSpan object

C<$interval_start>      - start point of the interval

C<$interval_end>        - end point in the interval

C<$internal_start>      - start position in the internal region

C<$internal_end>        - end position in the internal region

C<$sw_size>             - size of windows

C<$min_interval>        - minimal size of intervals

C<$maximal_distance>    - maximal distance

C<$strand>              - '+' or '-'

=head2 interval_window

    my @interval_windows = $self->interval_window(
        $comparable_set, $interval_start, $interval_end,
        $sw_size, $min_interval,
    );

Split an interval to windows.

Length of windows are variable, but all positions of the interval are counted.

=head2 outside_window

    my @outside_windows = $self->outside_window(
        $comparable_set, $internal_start, $internal_end,
        $sw_size, $maximal_distance,
    );

Draw outside windows from a internal region.

All windows are 100 bp length. Start from 1 and end to $maximal_distance.

=head2 outside_window_2

    my @outside_windows = $self->outside_window_2(
        $comparable_set, $internal_start, $internal_end,
        $sw_size, $maximal_distance,
    );

Draw outside windows from a internal region.

The first window is 50 bp and all others are 100 bp length.
Start from 0 and end to $maximal_distance.

=head2 inside_window

    my @inside_windows = $self->inside_window(
        $comparable_set, $interval_start, $interval_end,
        $sw_size, $maximal_distance,
    );

Draw inside windows from a internal region.

All windows are 100 bp length. Start counting from the edges.

=head2 inside_window_2

    my @inside_windows = $self->inside_window_2(
        $comparable_set, $interval_start, $interval_end,
        $sw_size, $maximal_distance,
    );

Draw inside windows from a internal region.

All windows are 100 bp length. Start counting from the center.

=head2 center_window

    my @center_windows = $self->center_window(
        $comparable_set, $internal_start, $internal_end,
        $sw_size, $maximal_distance,
    );

Draw windows for a certain region.

Center is 0, and the first window is 50 bp and all others are 100 bp length.
Start from 0 and end to $maximal_distance.

=head2 center_intact_window

    my @center_intact_windows = $self->center_intact_window(
        $comparable_set, $internal_start, $internal_end,
        $sw_size, $maximal_distance,
    );

Draw windows for a certain region.

Center is 0, and the first window is 50 bp and all others are 100 bp length.
Start from 0 and end to $maximal_distance.

=head2 strand_window

    my @windows = $self->strand_window(
        $comparable_set, $interval_start, $interval_end,
        $sw_size, $strand,
    );

Draw windows for a certain region

=head1 AUTHOR

Qiang Wang <wang-q@outlook.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Qiang Wang.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
