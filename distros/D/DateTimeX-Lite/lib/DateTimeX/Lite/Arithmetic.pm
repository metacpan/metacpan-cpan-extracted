
package DateTimeX::Lite;
use strict;
use warnings;
use Carp ();
use Scalar::Util qw(blessed);
use overload ( 'fallback' => 1,
               '-'   => '_subtract_overload',
               '+'   => '_add_overload',
             );


sub subtract_datetime
{
    my $dt1 = shift;
    my $dt2 = shift;

    $dt2 = $dt2->clone->set_time_zone( $dt1->time_zone )
        unless $dt1->time_zone->name eq $dt2->time_zone->name;

    # We only want a negative duration if $dt2 > $dt1 ($self)
    my ( $bigger, $smaller, $negative ) =
        ( $dt1 >= $dt2 ?
          ( $dt1, $dt2, 0 ) :
          ( $dt2, $dt1, 1 )
        );

    my $is_floating = $dt1->time_zone->is_floating &&
                      $dt2->time_zone->is_floating;


    my $minute_length = 60;
    unless ($is_floating)
    {
        my ( $utc_rd_days, $utc_rd_secs ) = $smaller->utc_rd_values;

        if ( $utc_rd_secs >= 86340 && ! $is_floating )
        {
            # If the smaller of the two datetimes occurs in the last
            # UTC minute of the UTC day, then that minute may not be
            # 60 seconds long.  If we need to subtract a minute from
            # the larger datetime's minutes count in order to adjust
            # the seconds difference to be positive, we need to know
            # how long that minute was.  If one of the datetimes is
            # floating, we just assume a minute is 60 seconds.

            $minute_length = DateTimeX::Lite::LeapSecond::day_length($utc_rd_days) - 86340;
        }
    }

    # This is a gross hack that basically figures out if the bigger of
    # the two datetimes is the day of a DST change.  If it's a 23 hour
    # day (switching _to_ DST) then we subtract 60 minutes from the
    # local time.  If it's a 25 hour day then we add 60 minutes to the
    # local time.
    #
    # This produces the most "intuitive" results, though there are
    # still reversibility problems with the resultant duration.
    #
    # However, if the two objects are on the same (local) date, and we
    # are not crossing a DST change, we don't want to invoke the hack
    # - see 38local-subtract.t
    my $bigger_min = $bigger->hour * 60 + $bigger->minute;
    if ( $bigger->time_zone->has_dst_changes
         && ( $bigger->ymd ne $smaller->ymd
              || $bigger->is_dst != $smaller->is_dst )
       )
    {

        $bigger_min -= 60
            # it's a 23 hour (local) day
            if ( $bigger->is_dst
                 &&
                 do { local $@;
                      my $prev_day = eval { $bigger->clone->subtract( days => 1 ) };
                      $prev_day && ! $prev_day->is_dst ? 1 : 0 }
               );

        $bigger_min += 60
            # it's a 25 hour (local) day
            if ( ! $bigger->is_dst
                 &&
                 do { local $@;
                      my $prev_day = eval { $bigger->clone->subtract( days => 1 ) };
                      $prev_day && $prev_day->is_dst ? 1 : 0 }
               );
    }

    my ( $months, $days, $minutes, $seconds, $nanoseconds ) =
        $dt1->_adjust_for_positive_difference
            ( $bigger->year * 12 + $bigger->month, $smaller->year * 12 + $smaller->month,

              $bigger->day, $smaller->day,

              $bigger_min, $smaller->hour * 60 + $smaller->minute,

	      $bigger->second, $smaller->second,

	      $bigger->nanosecond, $smaller->nanosecond,

	      $minute_length,

              # XXX - using the smaller as the month length is
              # somewhat arbitrary, we could also use the bigger -
              # either way we have reversibility problems
	      DateTimeX::Lite::Util::month_length( $smaller->year, $smaller->month ),
            );

    if ($negative)
    {
        for ( $months, $days, $minutes, $seconds, $nanoseconds )
        {
	    # Some versions of Perl can end up with -0 if we do "0 * -1"!!
            $_ *= -1 if $_;
        }
    }

    return
        DateTimeX::Lite::Duration->new
            ( months      => $months,
	      days        => $days,
	      minutes     => $minutes,
              seconds     => $seconds,
              nanoseconds => $nanoseconds,
            );
}

sub _adjust_for_positive_difference
{
    my ( $self,
	 $month1, $month2,
	 $day1, $day2,
	 $min1, $min2,
	 $sec1, $sec2,
	 $nano1, $nano2,
	 $minute_length,
	 $month_length,
       ) = @_;

    if ( $nano1 < $nano2 )
    {
        $sec1--;
        $nano1 += &DateTimeX::Lite::MAX_NANOSECONDS;
    }

    if ( $sec1 < $sec2 )
    {
        $min1--;
        $sec1 += $minute_length;
    }

    # A day always has 24 * 60 minutes, though the minutes may vary in
    # length.
    if ( $min1 < $min2 )
    {
	$day1--;
	$min1 += 24 * 60;
    }

    if ( $day1 < $day2 )
    {
	$month1--;
	$day1 += $month_length;
    }

    return ( $month1 - $month2,
	     $day1 - $day2,
	     $min1 - $min2,
             $sec1 - $sec2,
             $nano1 - $nano2,
           );
}

sub subtract_datetime_absolute
{
    my $self = shift;
    my $dt = shift;

    my $utc_rd_secs1 = $self->utc_rd_as_seconds;
    $utc_rd_secs1 += DateTimeX::Lite::LeapSecond::leap_seconds( $self->{utc_rd_days} )
	if ! $self->time_zone->is_floating;

    my $utc_rd_secs2 = $dt->utc_rd_as_seconds;
    $utc_rd_secs2 += DateTimeX::Lite::LeapSecond::leap_seconds( $dt->{utc_rd_days} )
	if ! $dt->time_zone->is_floating;

    my $seconds = $utc_rd_secs1 - $utc_rd_secs2;
    my $nanoseconds = $self->nanosecond - $dt->nanosecond;

    if ( $nanoseconds < 0 )
    {
	$seconds--;
	$nanoseconds += &DateTimeX::Lite::MAX_NANOSECONDS;
    }

    return
        DateTimeX::Lite::Duration->new
            ( seconds     => $seconds,
              nanoseconds => $nanoseconds,
            );
}

sub delta_md
{
    my $self = shift;
    my $dt = shift;

    my ( $smaller, $bigger ) = sort $self, $dt;

    my ( $months, $days, undef, undef, undef ) =
        $dt->_adjust_for_positive_difference
            ( $bigger->year * 12 + $bigger->month, $smaller->year * 12 + $smaller->month,

              $bigger->day, $smaller->day,

              0, 0,

              0, 0,

              0, 0,

	      60,

	      DateTimeX::Lite::Util::month_length( $smaller->year, $smaller->month ),
            );

    return DateTimeX::Lite::Duration->new( months => $months,
                                    days   => $days );
}

sub delta_days
{
    my $self = shift;
    my $dt = shift;

    my ( $smaller, $bigger ) = sort( ($self->local_rd_values)[0], ($dt->local_rd_values)[0] );

    DateTimeX::Lite::Duration->new( days => $bigger - $smaller );
}

sub delta_ms
{
    my $self = shift;
    my $dt = shift;

    my ( $smaller, $greater ) = sort $self, $dt;

    my $days = int( $greater->jd - $smaller->jd );

    my $dur = $greater->subtract_datetime($smaller);

    my %p;
    $p{hours}   = $dur->hours + ( $days * 24 );
    $p{minutes} = $dur->minutes;
    $p{seconds} = $dur->seconds;

    return DateTimeX::Lite::Duration->new(%p);
}

sub _add_overload
{
    my ( $dt, $dur, $reversed ) = @_;

    if ($reversed)
    {
        ( $dur, $dt ) = ( $dt, $dur );
    }

    unless ( blessed $dur && $dur->isa( 'DateTimeX::Lite::Duration' ) )
    {
        my $class = ref $dt;
        my $dt_string = overload::StrVal($dt);

        Carp::croak( "Cannot add $dur to a $class object ($dt_string).\n"
                     . " Only a DateTimeX::Lite::Duration object can "
                     . " be added to a $class object." );
    }

    return $dt->clone->add_duration($dur);
}

sub _subtract_overload
{
    my ( $date1, $date2, $reversed ) = @_;

    if ($reversed)
    {
        ( $date2, $date1 ) = ( $date1, $date2 );
    }

    if ( blessed $date2 && $date2->isa( 'DateTimeX::Lite::Duration' ) )
    {
        my $new = $date1->clone;
        $new->add_duration( $date2->inverse );
        return $new;
    }
    elsif ( blessed $date2 && $date2->isa( 'DateTimeX::Lite' ) )
    {
        return $date1->subtract_datetime($date2);
    }
    else
    {
        my $class = ref $date1;
        my $dt_string = overload::StrVal($date1);

        Carp::croak( "Cannot subtract $date2 from a $class object ($dt_string).\n"
                     . " Only a DateTimeX::Lite::Duration or DateTimeX::Lite object can "
                     . " be subtracted from a $class object." );
    }
}

sub add { return shift->add_duration( DateTimeX::Lite::Duration->new(@_) ) }

sub subtract { return shift->subtract_duration( DateTimeX::Lite::Duration->new(@_) ) }

sub subtract_duration { return $_[0]->add_duration( $_[1]->inverse ) }

    sub add_duration
    {
        my ($self, $dur) = @_;
        if (! blessed $dur || !$dur->isa('DateTimeX::Lite::Duration')) {
            Carp::croak("Duration is not a DateTimeX::Lite::Duration object");
        }

        # simple optimization
        return $self if $dur->is_zero;

        my %deltas = $dur->deltas;

        # This bit isn't quite right since DateTimeX::Lite::Infinite::Future -
        # infinite duration should NaN
        foreach my $val ( values %deltas )
        {
            my $inf;
            if ( $val == &DateTimeX::Lite::INFINITY )
            {
                $inf = DateTimeX::Lite::Infinite::Future->new;
            }
            elsif ( $val == &DateTimeX::Lite::NEG_INFINITY )
            {
                $inf = DateTimeX::Lite::Infinite::Past->new;
            }

            if ($inf)
            {
                %$self = %$inf;
                bless $self, blessed $inf;

                return $self;
            }
        }

        return $self if $self->is_infinite;

        if ( $deltas{days} )
        {
            $self->{local_rd_days} += $deltas{days};

            $self->{utc_year} += int( $deltas{days} / 365 ) + 1;
        }

        if ( $deltas{months} )
        {
            # For preserve mode, if it is the last day of the month, make
            # it the 0th day of the following month (which then will
            # normalize back to the last day of the new month).
            my ($y, $m, $d) = ( $dur->is_preserve_mode ?
                                DateTimeX::Lite::Util::rd2ymd( $self->{local_rd_days} + 1 ) :
                                DateTimeX::Lite::Util::rd2ymd( $self->{local_rd_days} )
                              );

            $d -= 1 if $dur->is_preserve_mode;

            if ( ! $dur->is_wrap_mode && $d > 28 )
            {
                # find the rd for the last day of our target month
                $self->{local_rd_days} = DateTimeX::Lite::Util::ymd2rd( $y, $m + $deltas{months} + 1, 0 );

                # what day of the month is it? (discard year and month)
                my $last_day = (DateTimeX::Lite::Util::rd2ymd( $self->{local_rd_days} ))[2];

                # if our original day was less than the last day,
                # use that instead
                $self->{local_rd_days} -= $last_day - $d if $last_day > $d;
            }
            else
            {
                $self->{local_rd_days} = DateTimeX::Lite::Util::ymd2rd( $y, $m + $deltas{months}, $d );
            }

            $self->{utc_year} += int( $deltas{months} / 12 ) + 1;
        }

        if ( $deltas{days} || $deltas{months} )
        {
            $self->_calc_utc_rd;

            $self->_handle_offset_modifier( $self->second );
        }

        if ( $deltas{minutes} )
        {
            $self->{utc_rd_secs} += $deltas{minutes} * 60;

            # This intentionally ignores leap seconds
            DateTimeX::Lite::Util::normalize_tai_seconds( $self->{utc_rd_days}, $self->{utc_rd_secs} );
        }

        if ( $deltas{seconds} || $deltas{nanoseconds} )
        {
            $self->{utc_rd_secs} += $deltas{seconds};

            if ( $deltas{nanoseconds} )
            {
                $self->{rd_nanosecs} += $deltas{nanoseconds};
                DateTimeX::Lite::Util::normalize_nanoseconds( $self->{utc_rd_secs}, $self->{rd_nanosecs} );
            }

            DateTimeX::Lite::Util::normalize_seconds($self);

            # This might be some big number much bigger than 60, but
            # that's ok (there are tests in 19leap_second.t to confirm
            # that)
            $self->_handle_offset_modifier( $self->second + $deltas{seconds} );
        }

        my $new =
            (ref $self)->from_object
                ( object => $self,
                  locale => $self->{locale},
                  ( $self->{formatter} ? ( formatter => $self->{formatter} ) : () ),
                 );

        %$self = %$new;

        return $self;
    }

1;