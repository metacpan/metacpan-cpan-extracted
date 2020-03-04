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
