use strict;
use warnings;

package Business::Hours;

require 5.006;
use Set::IntSpan;
use Time::Local qw/timelocal_nocheck/;

our $VERSION = '0.12';

=head1 NAME

Business::Hours - Calculate business hours in a time period

=head1 SYNOPSIS

  use Business::Hours;
  my $hours = Business::Hours->new();    

  # Get a Set::IntSpan of all the business hours in the next week.
  # use the default business hours of 9am to 6pm localtime.
  $hours->for_timespan( Start => time(), End => time()+(86400*7) );

=head1 DESCRIPTION

This module is a simple tool for calculating business hours in a time period. 
Over time, additional functionality will be added to make it easy to
calculate the number of business hours between arbitrary dates. 

=head1 USAGE

=cut

# Default business hours are weekdays from 9am to 6pm
our $BUSINESS_HOURS = (
    {   0 => {
            Name  => 'Sunday',
            Start => undef,
            End   => undef,
        },
        1 => {
            Name  => 'Monday',
            Start => '9:00',
            End   => '18:00',
        },
        2 => {
            Name  => 'Tuesday',
            Start => '9:00',
            End   => '18:00',
        },
        3 => {
            Name  => 'Wednesday',
            Start => '9:00',
            End   => '18:00',
        },
        4 => {
            Name  => 'Thursday',
            Start => '9:00',
            End   => '18:00',
        },
        5 => {
            Name  => 'Friday',
            Start => '9:00',
            End   => '18:00',
        },
        6 => {
            Name  => 'Saturday',
            Start => undef,
            End   => undef,
        }
    }
);
__PACKAGE__->preprocess_business_hours( $BUSINESS_HOURS );

=head2 new

Creates a new L<Business::Hours> object.  Takes no arguments.

=cut

sub new {
    my $class = shift;

    my $self = bless( {}, ref($class) || $class );

    return ($self);
}

=head2 business_hours HASH

Gets / sets the business hours for this object.
Takes a hash (NOT a hash reference) of the form:

    my %hours = (
        0 => { Name     => 'Sunday',
               Start    => 'HH:MM',
               End      => 'HH:MM' },

        1 => { Name     => 'Monday',
               Start    => 'HH:MM',
               End      => 'HH:MM' },
        ....

        6 => { Name     => 'Saturday',
               Start    => 'HH:MM',
               End      => 'HH:MM' },
    );

Start and End times are of the form HH:MM.  Valid times are
from 00:00 to 23:59.  If your hours are from 9am to 6pm, use
Start => '9:00', End => '18:00'.  A given day MUST have a start
and end time OR may declare both Start and End to be undef, if
there are no valid hours on that day.

You can use the array Breaks to mark interruptions between Start/End (for instance lunch hour). It's an array of periods, each with a Start and End time:

    my %hours = (
        0 => { Name     => 'Sunday',
               Start    => 'HH:MM',
               End      => 'HH:MM',
               Breaks  => [ 
                             { Start    => 'HH:MM',
                             End      => 'HH:MM' },
                             { Start    => 'HH:MM',
                             End      => 'HH:MM' },
                           ],

        1 => { Name     => 'Monday',
               Start    => 'HH:MM',
               End      => 'HH:MM' },
        ....

        6 => { Name     => 'Saturday',
               Start    => 'HH:MM',
               End      => 'HH:MM' },
    );

Note that the ending time is really "what is the first minute we're closed.
If you specifiy an "End" of 18:00, that means that at 6pm, you are closed.
The last business second was 17:59:59.

As well, you can pass information about holidays using key 'holidays' and
an array reference value, for example:

    $hours->business_hours(
        0 => { Name     => 'Sunday',
               Start    => 'HH:MM',
               End      => 'HH:MM' },
        ....
        6 => { Name     => 'Saturday',
               Start    => 'HH:MM',
               End      => 'HH:MM' },

        holidays => [qw(01-01 12-25 2009-05-08)],
    );

Read more about holidays specification below in L<holidays|/"holidays ARRAY">.

=cut

sub business_hours {
    my $self = shift;
    if ( @_ ) {
        %{ $self->{'business_hours'} } = (@_);
        $self->{'holidays'} = delete $self->{'business_hours'}{'holidays'};
        $self->preprocess_business_hours( $self->{'business_hours'} );
    }
    return %{ $self->{'business_hours'} };
}

=head2 preprocess_business_hours

Checks and transforms business hours data. No need to call it.

=cut

sub preprocess_business_hours {
    my $self = shift;
    my $bizdays = shift;

    my $process_start_end = sub {
        my $span = shift;
        foreach my $which (qw(Start End)) {
            return 0 unless $span->{ $which } && $span->{ $which } =~ /^(\d+)\D(\d+)$/;

            $span->{ $which . 'Hour' }   = $1;
            $span->{ $which . 'Minute' } = $2;
        }
        $span->{'EndHour'} += 24
            if $span->{'EndHour'}*60+$span->{'EndMinute'}
            <= $span->{'StartHour'}*60+$span->{'StartMinute'};
        return 1;
    };

    # Split the Start and End times into hour/minute specifications
    foreach my $dow ( keys %$bizdays ) {
        unless (
            $bizdays->{ $dow } && ref($bizdays->{ $dow }) eq 'HASH'
            && $process_start_end->( $bizdays->{ $dow } )
        ) {
            delete $bizdays->{ $dow };
            next;
        }

        foreach my $break ( splice @{ $bizdays->{ $dow }{'Breaks'} || [] } ) {
            next unless $break && ref($break) eq 'HASH';
            push @{ $bizdays->{ $dow }{'Breaks'} }, $break
                if $process_start_end->( $break );
        }
    }
}

=head2 holidays ARRAY

Gets / sets holidays for this object. Takes an array
where each element is ether 'MM-DD' or 'YYYY-MM-DD'.

Specification with year defined may be required when a holiday
matches Sunday or Saturday. In many countries days are shifted
in such case.

Holidays can be set via L<business_hours|/"business_hours HASH"> method
as well, so you can use this feature without changing your code.

=cut

sub holidays {
    my $self = shift;
    if ( @_ ) {
        @{ $self->{'holidays'} } = (@_);
    }
    return @{ $self->{'holidays'} || [] };
}

=head2 for_timespan HASH

Takes a hash with the following parameters:

=over

=item Start

The start of the period in question in seconds since the epoch

=item End

The end of the period in question in seconds since the epoch

=back

Returns a L<Set::IntSpan> of business hours for this period of time.

=cut

sub for_timespan {
    my $self = shift;
    my %args = (
        Start => undef,
        End   => undef,
        @_
    );
    my $bizdays = $self->{'business_hours'} || $BUSINESS_HOURS;

    # now that we know what the business hours are for each day in a week,
    # we need to find all the business hours in the period in question.

    # Create an intspan of the period in total.
    my $business_period
        = Set::IntSpan->new( $args{'Start'} . "-" . $args{'End'} );

    # jump back to the first day (Sunday) of the last week before the period
    # began.
    my @start        = localtime( $args{'Start'} );
    my $month        = $start[4];
    my $year         = $start[5];
    my $first_sunday = $start[3] - $start[6];

    # period_start is time_t at midnight local time on the first sunday
    my $period_start
        = timelocal_nocheck( 0, 0, 0, $first_sunday, $month, $year );

    # for each week until the end of the week in seconds since the epoch
    # is outside the business period in question
    my $week_start = $period_start;

    # @run_list is a run list of the period's business hours
    # its form is (<int>-<int2>,<int3>-<int4>)
    # For documentation about its format, have a look at Set::IntSpan.
    # (This is fed into Set::IntSpan to use to compute our actual run.
    my @run_list;

    # @break_list is a run list of the period's breaks between business hours
    # its form is (<int>-<int2>,<int3>-<int4>)
    # For documentation about its format, have a look at Set::IntSpan.
    # (This is fed into Set::IntSpan to use to compute our actual run.
    my @break_list;

    my $convert_start_end = sub {
        my ($hours, @today) = @_;

        # add the business seconds in that week to the runlist we'll use to
        # figure out business hours
        # (Be careful to use timelocal to convert times in the week into actual
        # seconds, so we don't lose at DST transition)
        my $start = timelocal_nocheck(
            0, $hours->{'StartMinute'}, $hours->{'StartHour'}, @today
        );

        # We subtract 1 from the ending time, because the ending time
        # really specifies what hour we end up closed at
        my $end = timelocal_nocheck(
            0, $hours->{'EndMinute'}, $hours->{'EndHour'}, @today
        ) - 1;

        return "$start-$end";
    };

    while ( $week_start <= $args{'End'} ) {

        my @today = (localtime($week_start))[3, 4, 5];
        $today[0]--; # compensate next increment

        # foreach day in the week, find that day's business hours in
        # seconds since the epoch.
        for ( my $dow = 0; $dow <= 6; $dow++ ) {
            $today[0]++; # next day comes
            next unless my $day_hours = $bizdays->{$dow};

            push @run_list, $convert_start_end->( $day_hours, @today );

            foreach my $break ( @{ $bizdays->{$dow}{'Breaks'} || [] } ) {
                push @break_list, $convert_start_end->( $break, @today );
            }
        }

    # now that we're done with this week, calculate the start of the next week
    # the next week starts at midnight on the sunday following the previous
    # sunday
        $week_start = timelocal_nocheck( 0, 0, 0, $today[0]+1, $today[1], $today[2] );

    }

    my $business_hours = Set::IntSpan->new( join( ',', @run_list ) ) - Set::IntSpan->new( join( ',', @break_list ) );
    my $business_hours_in_period
        = $business_hours->intersect($business_period);

    # find the intersection of the business period intspan and the  business
    # hours intspan. (Because we want to trim any business hours that fall
    # outside the business period)

    if ( my @holidays = $self->holidays ) {
        my $start_year = $year;
        my $end_year = (localtime $args{'End'})[5];
        foreach my $holiday (@holidays) {
            my ($year, $month, $date) = ($holiday =~ /^(?:(\d\d\d\d)\D)?(\d\d)\D(\d\d)$/);
            $month--;
            my @range;
            if ( $year ) {
                push @range, [
                    timelocal_nocheck( 0, 0, 0, $date, $month, $year ),
                ];
            }
            else {
                push @range, [
                    timelocal_nocheck( 0, 0, 0, $date, $month, $start_year ),
                ];
                push @range, [
                    timelocal_nocheck( 0, 0, 0, $date, $month, $end_year ),
                ] if $start_year != $end_year;
            }
            $_->[1] = $_->[0] + 24*60*60 foreach @range;
            $business_hours_in_period -= \@range;
        }
    }

    # TODO: Add any special times to the business hours

    # cache the calculated business hours in the object
    $self->{'calculated'} = $business_hours_in_period;
    $self->{'start'}      = $args{'Start'};
    $self->{'end'}        = $args{'End'};

    # Return the intspan of business hours.

    return ($business_hours_in_period);

}

=head2 between START, END

Returns the number of business seconds between START and END
Both START and END should be specified in seconds since the epoch.

Returns -1 if START or END are outside the calculated business hours.

=cut

sub between {
    my $self  = shift;
    my $start = shift;
    my $end   = shift;

    if ( not defined $self->{'start'} or not defined $self->{'end'} ) {
        # We haven't calculated our sets yet, so let's do that for the
        # user now, assuming they want to use the same start and end
        # times
        $self->for_timespan( Start => $start, End => $end );
    }

    if ( $start < $self->{'start'} ) {
        return (-1);
    }
    if ( $end > $self->{'end'} ) {
        return (-1);
    }

    my $period       = Set::IntSpan->new( $start . "-" . $end );
    my $intersection = intersect $period $self->{'calculated'};

    return cardinality $intersection;
}

=head2 first_after START

Returns START if START is within business hours.
Otherwise, returns the next business second after START.
START should be specified in seconds since the epoch.

Returns -1 if it can't find any business hours within thirty days.

=cut

sub first_after {
    my $self  = shift;
    my $start = shift;

    # the maximum time after which we stop searching for business hours
    my $MAXTIME = $start + ( 30 * 24 * 60 * 60 );    # 30 days

    my $period = ( 24 * 60 * 60 );
    my $end    = $start + $period;
    my $hours  = new Set::IntSpan;

    while ( $hours->empty ) {
        if ( $end >= $MAXTIME ) {
            return -1;
        }
        $hours = $self->for_timespan( Start => $start, End => $end );
        $start = $end;
        $end   = $start + $period;
    }

    return $hours->first;
}

=head2 add_seconds START, SECONDS

Returns a time SECONDS business seconds after START.
START should be specified in seconds since the epoch.

Returns -1 if it can't find any business hours within thirty days.

=cut

sub add_seconds {
    my $self    = shift;
    my $start   = shift;
    my $seconds = shift;

    # the maximum time after which we stop searching for business hours
    my $MAXTIME = ( 30 * 24 * 60 * 60 );    # 30 days

    my $last;

    my $period = ( 24 * 60 * 60 );
    my $end    = $start + $period;

    my $hours = new Set::IntSpan;
    while ($hours->empty
        or $self->between( $start, $hours->last ) <= $seconds )
    {
        if ( $end >= $start + $MAXTIME ) {
            return -1;
        }
        $hours = $self->for_timespan( Start => $start, End => $end );

        $end += $period;
    }

    my @elements = elements $hours;
    $last = $elements[$seconds];

    return $last;
}

=head1 BUGS

Yes, most likely.  Please report them to L<bug-business-hours@rt.cpan.org>.

=head1 AUTHOR

Jesse Vincent, L<jesse@cpan.org>

=head1 COPYRIGHT

Copyright 2003-2008 Best Practical Solutions, LLC.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the LICENSE
file included with this module.

=cut

1;

