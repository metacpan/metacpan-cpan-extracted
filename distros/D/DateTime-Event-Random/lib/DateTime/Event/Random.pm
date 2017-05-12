
package DateTime::Event::Random;

use strict;
use DateTime::Set;
use vars qw( $VERSION @ISA );
use Carp;

BEGIN {
    $VERSION = 0.03;
}

sub new_cached {
    my $class = shift;
    my %args = @_;   # the parameters are validated by DT::Set

    my $density = $class->_random_init( \%args );

    my $cache_set = DateTime::Set->empty_set;
    my $cache_last;
    my $cache_first;

    my $get_cached = 
                sub {
                    my $dt = $_[0];
                    my $prev = $cache_set->previous( $dt );
                    my $next = $cache_set->next( $dt );
                    return ( $prev, $next ) if defined $prev && defined $next;

                    # initialize the cache
                    unless ( defined $cache_last )
                    {
                        $cache_last = $dt - $class->_random_duration( $density );
                        $cache_first = $cache_last->clone;
                        $cache_set = $cache_set->union( $cache_last );
                    };

                    while ( $cache_last <= $dt ) {
                        $cache_last += $class->_random_duration( $density );
                        $cache_set = $cache_set->union( $cache_last );
                    };

                    while ( $cache_first >= $dt ) {
                        $cache_first -= $class->_random_duration( $density );
                        $cache_set = $cache_set->union( $cache_first );
                    };

                    $prev = $cache_set->previous( $dt );
                    $next = $cache_set->next( $dt );
                    return ( $prev, $next );
                };

    my $cached_set = DateTime::Set->from_recurrence(
        next =>  sub {
                    return $_[0] if $_[0]->is_infinite;
                    my ( undef, $next ) = &$get_cached( $_[0] );
                    return $next;
                 },
        previous => sub {
                    return $_[0] if $_[0]->is_infinite;
                    my ( $previous, undef ) = &$get_cached( $_[0] );
                    return $previous;
                 },
        %args,
    );
    return $cached_set;

}

sub new {
    my $class = shift;
    my %args = @_;   # the parameters will be validated by DT::Set
    my $density = $class->_random_init( \%args );
    return DateTime::Set->from_recurrence(
        next =>     sub {
                        return $_[0] if $_[0]->is_infinite;
                        $_[0] + $class->_random_duration( $density );
                    },
        previous => sub {
                        return $_[0] if $_[0]->is_infinite;
                        $_[0] - $class->_random_duration( $density );
                    },
        %args,
    );
}

sub _random_init {
    my $class = shift;
    my $args = shift;  

    my $density = 0;

    if ( exists $args->{duration} )
    {
        my %dur = $args->{duration}->deltas;
        $args->{ $_ } = $dur{ $_ } for ( keys %dur );
        delete $args->{duration};
    }

    $density += ( delete $args->{nanoseconds} ) / 1E9 if exists $args->{nanoseconds};
    $density += ( delete $args->{seconds} ) if exists $args->{seconds};
    $density += ( delete $args->{minutes} ) * 60 if exists $args->{minutes};
    $density += ( delete $args->{hours} )  * 60*60 if exists $args->{hours};
    $density += ( delete $args->{days} )   * 24*60*60 if exists $args->{days};
    $density += ( delete $args->{weeks} )  * 7*24*60*60 if exists $args->{weeks};
    $density += ( delete $args->{months} ) * 365.24/12*24*60*60 if exists $args->{months};
    $density += ( delete $args->{years} )  * 365.24*24*60*60 if exists $args->{years};

    $density = 24*60*60 unless $density;  # default = 1 day

    return {
        density => $density,
        starting => 1,
    };
}

sub _random_duration {
    my $class = shift;
    my $param = shift;

    my $tmp;
    if ( $param->{starting} )
    {
        $param->{starting} = 0;

        # this is a density function that approximates to 
        # the "duration" in seconds between a random and
        # a non-random date.
        $tmp = log( 1 - rand ) * ( - $param->{density} / 2 );
    }
    else
    {
        # this is a density function that approximates to 
        # the "duration" in seconds between two random dates.
        $tmp = log( 1 - rand ) * ( - $param->{density} );
    }


    # split into "days", "seconds" and "nanoseconds"

    my $days = int( $tmp / ( 24*60*60 ) );
    if ( $days > 1000 ) 
    {
        return DateTime::Duration->new(
               days =>        $days,
               seconds =>     int( rand( 61 ) ),
               nanoseconds => int( rand( 1E9 ) ) );
    }

    my $seconds = int( $tmp );
    return DateTime::Duration->new( 
               seconds =>     $seconds, 
               nanoseconds => int( 1E9 * ( $tmp - $seconds ) ) ); 
}


sub datetime {
    my $class = shift;
    carp "Missing class name in call to ".__PACKAGE__."->datetime()"
        unless defined $class;
    my %args = @_;

    my $locale    = delete $args{locale};
    my $time_zone = delete $args{time_zone};

    my $dt = $class->_random_datetime_no_locale( %args );

    $dt->set( locale => $locale ) if defined $locale;
    $dt->set( time_zone => $time_zone ) if defined $time_zone;
    return $dt;
}

sub _random_datetime_no_locale {
    my $class = shift;
    my %args = @_;
    my %span_args;
    my $span;
    if ( exists $args{span} )
    {
        $span = delete $args{span};
    }
    else
    {
        for ( qw( start end before after ) )
        {
            $span_args{ $_ } = delete $args{ $_ } if exists $args{ $_ };
        }
        $span = DateTime::Span->from_datetimes( %span_args )
            if ( keys %span_args );
    } 

    if ( ! defined $span ||
         ( $span->start->is_infinite && 
           $span->end->is_infinite ) )
    {
        my $dt = DateTime->now( %args );
        $dt->add( months =>      ( 0.5 - rand ) * 1E6 );
        $dt->add( days =>        ( 0.5 - rand ) * 31 );
        $dt->add( seconds =>     ( 0.5 - rand ) * 24*60*60 );
        $dt->add( nanoseconds => ( 0.5 - rand ) * 1E9 );
        return $dt;
    }

    return undef unless defined $span->start;

    if ( $span->start->is_infinite )
    {
        my $dt = $span->end;
        $dt->add( months =>      ( - rand ) * 1E6 );
        $dt->add( days =>        ( - rand ) * 31 );
        $dt->add( seconds =>     ( - rand ) * 24*60*60 );
        $dt->add( nanoseconds => ( - rand ) * 1E9 );
        return $dt;
    }

    if ( $span->end->is_infinite )
    {
        my $dt = $span->start;
        $dt->add( months =>      ( rand ) * 1E6 );
        $dt->add( days =>        ( rand ) * 31 );
        $dt->add( seconds =>     ( rand ) * 24*60*60 );
        $dt->add( nanoseconds => ( rand ) * 1E9 );
        return $dt;
    }

    my $dt1 = $span->start;
    my $dt2 = $span->end;
    my %deltas = $dt2->subtract_datetime( $dt1 )->deltas;
    # find out the most significant delta
    if ( $deltas{months} ) {
        $deltas{months}++;
        $deltas{days} = 31;
        $deltas{minutes} = 24*60;
        $deltas{seconds} = 60;
        $deltas{nanoseconds} = 1E9;
    }
    elsif ( $deltas{days} ) {
        $deltas{days}++;
        $deltas{minutes} = 24*60;
        $deltas{seconds} = 60;
        $deltas{nanoseconds} = 1E9;
    }
    elsif ( $deltas{minutes} ) {
        $deltas{minutes}++;
        $deltas{seconds} = 60;
        $deltas{nanoseconds} = 1E9;
    }
    elsif ( $deltas{seconds} ) {
        $deltas{seconds}++;
        $deltas{nanoseconds} = 1E9;
    }
    else {
        $deltas{nanoseconds}++;
    }

    my %duration;
    my $dt;
    while (1) 
    {
        %duration = ();
        for ( keys %deltas ) 
        {
            $duration{ $_ } = int( rand() * $deltas{ $_ } ) 
                if $deltas{ $_ };
        }
        $dt = $dt1->clone->add( %duration );
        return $dt if $span->contains( $dt );

        %duration = ();
        for ( keys %deltas ) 
        {
            $duration{ $_ } = int( rand() * $deltas{ $_ } )
                if $deltas{ $_ };
        }
        $dt = $dt2->clone->subtract( %duration );
        return $dt if $span->contains( $dt );
    }
}

sub duration {
    my $class = shift;
    carp "Missing class name in call to ".__PACKAGE__."->duration()"
        unless defined $class;
    my $dur;
    if ( @_ ) 
    {
        if ( $_[0] eq 'duration' ) 
        {
            $dur = $_[1];
        }
        else
        {
            $dur = DateTime::Duration->new( @_ );
        }
    }
    if ( $dur ) {
        my $dt1 = DateTime->now();
        my $dt2 = $dt1 + $dur;
        my $dt3 = $class->datetime( start => $dt1, before => $dt2 );
        return $dt3 - $dt1;
    }
    return DateTime->now() - $class->datetime();
}

1;

__END__


=head1 NAME

DateTime::Event::Random - DateTime extension for creating random datetimes.


=head1 SYNOPSIS

 use DateTime::Event::Random;

 # Creates a random DateTime
 $dt = DateTime::Event::Random->datetime;

 # Creates a random DateTime in the future
 $dt = DateTime::Event::Random->datetime( after => DateTime->now );

 # Creates a random DateTime::Duration between 0 and 15 days
 $dur = DateTime::Event::Random->duration( days => 15 );

 # Creates a DateTime::Set of random dates 
 # with an average density of 4 months, 
 # that is, 3 events per year, with a span 
 # of 2 years
 my $dt_set = DateTime::Event::Random->new(
                  months => 4,   # events occur about 3 times a year
                  start =>  DateTime->new( year => 2003 ),
                  end =>    DateTime->new( year => 2005 ) ); 

 print "next is ", $dt_set->next( DateTime->today )->datetime, "\n";
 # output: next is 2004-02-29T22:00:51

 my @days = $dt_set->as_list;
 print join('; ', map{ $_->datetime } @days ) . "\n";
 # output: 2003-02-16T21:08:58; 2003-02-18T01:24:13; ...


=head1 DESCRIPTION

This module provides convenience methods that let you easily create
C<DateTime::Set>, C<DateTime>, or C<DateTime::Duration>
objects with random values.


=head1 USAGE

=over 4

=item * new

Creates a C<DateTime::Set> object that contains random events.

  my $random_set = DateTime::Event::Random->new;

The events occur at an average of once a day, forever.

You may give I<density> parameters to change this.
The density is specified as a duration:

  my $two_daily_set = DateTime::Event::Random->new( days => 2 );

  my $three_weekly_set = DateTime::Event::Random->new( weeks => 3 );

  my $random_set = DateTime::Event::Random->new( duration => $dur );

If I<span> parameters are given, then the set is bounded:

  my $rand = DateTime::Event::Random->new(
                 months => 4,   # events occur about 3 times a year
                 start =>  DateTime->new( year => 2003 ),
                 end =>    DateTime->new( year => 2005 ) );

Note that the random values are generated on demand, 
which means that the values may not be repeateable between iterations.
See the C<new_cached> constructor for a solution.

A C<DateTime::Set> object does not allow for the repetition of values.
Each element in a set is different.

The C<DateTime::Set> accessors (C<as_list>, C<iterator/next/previous>)
always return I<sorted> datetimes.


=item * new_cached

Creates a C<DateTime::Set> object representing the
set of random events.

    my $random_set = DateTime::Event::Random->new_cached;

If a set is created with C<new_cached>, then once an value is I<seen>,
it is cached, such that all sequences extracted from the set are equal.

Cached sets are slower and take more memory than sets generated
with the plain C<new> constructor. They should only be used if
you need unbounded sets that would be accessed many times and
when you need repeatable results.

This method accepts the same parameters as the C<new> method.


=item * datetime

Returns a random C<DateTime> object. 

    $dt = DateTime::Event::Random->datetime;

If a C<span> is specified, then the returned value will be within the span:

    $dt = DateTime::Event::Random->datetime( span => $span );

    $dt = DateTime::Event::Random->datetime( after => DateTime->now );

You can also specify C<locale> and C<time_zone> parameters,
just like in C<< DateTime->new() >>.


=item * duration

Returns a random C<DateTime::Duration> object.

    $dur = DateTime::Event::Random->duration;

If a C<duration> is specified, then the returned value will be within the
duration:

    $dur = DateTime::Event::Random->duration( duration => $dur );

    $dur = DateTime::Event::Random->duration( days => 15 );

=back

=head1 INTERNALS

=over 4

=item * _random_init

=item * _random_duration

These methods are called by C<DateTime::Set> to generate
the random datetime sequence.

You can override these methods in order to make different 
random distributions. The default random distribution is "uniform".

The I<internals> API is not stable.

=back

=head1 COOKBOOK

=over 4

=item * Make a random datetime

  use DateTime::Event::Random;

  my $dt = DateTime::Event::Random->datetime;

  print "datetime " .  $dt->datetime . "\n";


=item * Make a random datetime, today

  use DateTime::Event::Random;

  my $dt = DateTime->today + DateTime::Event::Random->duration( days => 1 );

  print "datetime " .  $dt->datetime . "\n";

This is another way to do it. It takes care of 
length of day problems, such as DST changes and leap seconds:

  use DateTime::Event::Random;

  my $dt_today = DateTime->today;
  my $dt_tomorrow = $dt_today + DateTime::Duration->new( days => 1 );

  my $dt = DateTime::Event::Random->datetime( 
               start =>  $dt_today, 
               before => $dt_tomorrow );

  print "datetime " .  $dt->datetime . "\n";


=item * Make a random sunday

  use DateTime::Event::Random;

  my $dt = DateTime::Event::Random->datetime;
  $dt->truncate( to => week );
  $dt->add( days => 6 );

  print "datetime " . $dt->datetime . "\n";
  print "weekday " .  $dt->day_of_week . "\n";


=item * Make a random friday-13th

  use DateTime::Event::Random;
  use DateTime::Event::Recurrence;

  my $day_13 = DateTime::Event::Recurrence->monthly( days => 13 );
  my $friday = DateTime::Event::Recurrence->weekly( days => 6 ); 
  my $friday_13 = $friday->intersection( $day_13 );

  my $dt = $friday_13->next( DateTime::Event::Random->datetime );

  print "datetime " .  $dt->datetime . "\n";
  print "weekday " .   $dt->day_of_week . "\n";
  print "month day " . $dt->day . "\n";

=back

=head1 AUTHOR

Flavio Soibelmann Glock
fglock@pucrs.br


=head1 COPYRIGHT

Copyright (c) 2004 Flavio Soibelmann Glock.  
All rights reserved.  This program is free software; 
you can redistribute it and/or modify it under the
same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.


=head1 SEE ALSO

datetime@perl.org mailing list

DateTime Web page at http://datetime.perl.org/

DateTime and DateTime::Duration - date and time.

DateTime::Set - "sets"

=cut

