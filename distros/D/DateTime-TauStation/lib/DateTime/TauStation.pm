package DateTime::TauStation;

use strict;
use vars qw ( $VERSION $SECS_2_UNITS );

use Carp;
use POSIX 'floor';
use parent 'DateTime';

require DateTime::Duration;

$VERSION = '0.1';
$VERSION = eval $VERSION;

$SECS_2_UNITS = 0.864;

=head1 NAME

DateTime::TauStation - Handle TauStation GCT datetimes

=head1 SYNOPSIS

  use DateTime::TauStation;
  
  my $dt = DateTime::TauStation->new(
    cycle   => '001',
    day     => '02',
    segment => '03',
    unit    => '004',
  );
  
  print $dt->gct_cycle;
  print $dt->gct_day;
  print $dt->gct_segment;
  print $dt->gct_unit;

Alternatively, combine with L<DateTime::Duration::TauStation> and
L<DateTime::Format::TauStation>.

  use DateTime::TauStation;
  use DateTime::Format::TauStation;
  
  my $dur = DateTime::Format::TauStation->parse_duration( 'D/20:000 GCT' );
  
  my $dt = DateTime::TauStation->now->add_duration( $dur );
  
  print DateTime::Format::TauStation->format_datetime($dt);

=head1 DESCRIPTION

L<DateTime> subclass for GCT (Galactic Coordinated Time) datetimes for the
online game L<TauStation|https://taustation.space>.

=head1 METHODS

=head2 new

Accepts arguments:

=over

=item gct_cycle

=item gct_day

=item gct_segment

=item gct_unit

=back

=cut

my @gct_fields = qw( gct_cycle gct_day gct_segment gct_unit );

sub new {
    my ( $class, %args ) = @_;
    my $self;

    if ( grep { exists $args{$_} } @gct_fields ) {
        $self = $class->catastrophe;

        my $cycle   = $args{gct_cycle}   || 0;
        my $day     = $args{gct_day}     || 0;
        my $segment = $args{gct_segment} || 0;
        my $unit    = $args{gct_unit}    || 0;

        my $total_units = $unit;
        $total_units += $segment * 1_000;
        $total_units += $day * 100 * 1_000;
        $total_units += $cycle * 100 * 100 * 1_000;

        my $add_secs = $total_units * $SECS_2_UNITS;
        # round
        $add_secs = int( $add_secs + 0.5 );

        $self->add( seconds => $add_secs );
    }
    elsif ( %args ) {
        $self = $class->SUPER::new(
            time_zone => 'UTC',
            %args
        );
    }
    else {
        $self = $class->catastrophe;
    }

    $self->duration_class('DateTime::Duration::TauStation');

    return $self;
}

=head2 catastrophe

Returns the datetime C<000.00/00:000 GCT>, a.k.a.
C<1964-01-22T00:00:27.689615> UTC.

=cut

sub catastrophe {
    my ( $self ) = @_;

    my @args = (
        year       => 1964,
        month      => 1,
        day        => 22,
        hour       => 0,
        minute     => 0,
        second     => 27,
        nanosecond => 689615,
        time_zone  => 'UTC',
    );

    return ref $self ? ref($self)->new(@args)
                     : $self->SUPER::new(@args);
}

=head2 gct_cycle

Returns the C<cycle> part of the datetime.

=cut

sub gct_cycle {
    my ( $self ) = @_;

    return $self->_return_gct('cycle');
}

=head2 gct_day

Returns the C<day> part of the datetime.

=cut

sub gct_day {
    my ( $self ) = @_;

    return $self->_return_gct('day');
}

=head2 gct_segment

Returns the C<segment> part of the datetime.

=cut

sub gct_segment {
    my ( $self ) = @_;

    return $self->_return_gct('segment');
}

=head2 gct_unit

Returns the C<unit> part of the datetime.

=cut

sub gct_unit {
    my ( $self ) = @_;

    return $self->_return_gct('unit');
}

sub _return_gct {
    my ( $self, $type, $seconds ) = @_;

    if ( !defined $seconds ) {
        my $dt1 = $self->catastrophe;
        $dt1->set_time_zone('UTC');

        my $self_tz = $self->time_zone;
        $self->set_time_zone('UTC');

        my $dur     = $self->subtract_datetime_absolute( $dt1 );
        $seconds = $dur->seconds;

        $self->set_time_zone($self_tz);
    }

    my $delta_units = $seconds / $SECS_2_UNITS;

    my $cycles = floor( $delta_units / 100 / 100 / 1_000 );

    return $cycles if 'cycle' eq $type;

    $delta_units -= ( $cycles * 100 * 100 * 1_000 );

    my $days = floor( $delta_units / 100 / 1_000 );

    return $days if 'day' eq $type;

    $delta_units -= ( $days * 100 * 1_000 );

    my $segments = floor( $delta_units / 1_000 );

    return $segments if 'segment' eq $type;

    $delta_units -= ( $segments * 1_000 );

    my $units = floor( $delta_units );

    return $units if 'unit' eq $type;

    return [ $cycles, $days, $segments, $units ];
}

=head2 subtract_datetime

Returns a L<DateTime::Duration::TauStation> object.

=cut

sub subtract_datetime {
    my ( $dt1, $dt2 ) = @_;

    my $dt1_tz = $dt1->time_zone;
    my $dt2_tz = $dt2->time_zone;

    $dt1->set_time_zone('UTC');
    $dt2->set_time_zone('UTC');

    my $dur     = $dt1->subtract_datetime_absolute($dt2);
    my $seconds = $dur->seconds;

    $dt1->set_time_zone($dt1_tz);
    $dt2->set_time_zone($dt2_tz);

    return DateTime::Duration::TauStation->new(
        gct_units => ( $seconds / $SECS_2_UNITS ),
    );
}

=head1 Limitations

Currently does not support negative GCT (pre-catastrophe) dates or negative
durations.

=head1 AUTHOR

Carl Franks

=head1 COPYRIGHT

Copyright (c) 2018 Carl Franks.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included with
this module.

=head1 SEE ALSO

L<DateTime::Duration::TauStation>, L<DateTime::Format::TauStation>

=cut
