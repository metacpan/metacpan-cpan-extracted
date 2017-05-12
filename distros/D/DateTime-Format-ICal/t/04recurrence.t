#!/usr/bin/perl -w

use strict;

use Test::More tests => 15;

use DateTime::Format::ICal;
use DateTime::Span;

my $ical = 'DateTime::Format::ICal';

{
    # this is an example from rfc2445 
    my $recur =
        $ical->parse_recurrence( recurrence => 'freq=monthly;count=10;byday=1fr',
                                 dtstart    => $ical->parse_datetime( '19970905T090000' )
                               );
    my @r;
    while ( my $dt = $recur->next )
    {
        push @r, $ical->format_datetime( $dt );
    }

    my $s1 = join ',', @r;

    my $s2 = join ',', qw( 1997-09-05T09:00:00
                           1997-10-03T09:00:00
                           1997-11-07T09:00:00
                           1997-12-05T09:00:00
                           1998-01-02T09:00:00
                           1998-02-06T09:00:00
                           1998-03-06T09:00:00
                           1998-04-03T09:00:00
                           1998-05-01T09:00:00
                           1998-06-05T09:00:00
                         );

    $s2 =~ s/[-:]//g;

    is( $s1, $s2, "recurrence parser is ok" );
}

{
    # DTSTART;TZID=US-Eastern:19980101T090000
    # RRULE:FREQ=YEARLY;BYMONTH=1;BYDAY=SU,MO,TU,WE,TH,FR,SA
    my $recur =
        $ical->parse_recurrence
            ( recurrence => 'FREQ=YEARLY;BYMONTH=1;BYDAY=SU,MO,TU,WE,TH,FR,SA',
              dtstart    => $ical->parse_datetime( '19980101T090000' )
            );

    my @str = $ical->format_recurrence( $recur );
    is( "@str", 'RRULE:FREQ=YEARLY;BYMONTH=1;BYDAY=SU,MO,TU,WE,TH,FR,SA',
        'unbounded recurrence formats ok' );

    my $union = $recur->union( 
                           $ical->parse_datetime( '19980303T030303' )
                        );
    @str = $ical->format_recurrence( $union );
    is( "@str", 'RRULE:FREQ=YEARLY;BYMONTH=1;BYDAY=SU,MO,TU,WE,TH,FR,SA '.
                'RDATE:19980303T030303',
        'unbounded recurrence union formats ok' );

    my $recur2 =
        $ical->parse_recurrence
            ( recurrence => 'FREQ=YEARLY;BYMONTH=2;BYDAY=SU,MO,TU,WE,TH,FR,SA',
              dtstart    => $ical->parse_datetime( '19980101T090000' )
            );

    my $union2 = $recur->union( $recur2 );
    @str = $ical->format_recurrence( $union2 );
    is( "@str", 'RRULE:FREQ=YEARLY;BYMONTH=1;BYDAY=SU,MO,TU,WE,TH,FR,SA '.
                'RRULE:FREQ=YEARLY;BYMONTH=2;BYDAY=SU,MO,TU,WE,TH,FR,SA',
        'union of unbounded recurrences formats ok' );

    my $union3 = $union2->union(
                           $ical->parse_datetime( '19980303T030303' )
                        );
    @str = $ical->format_recurrence( $union3 );
    is( "@str", 'RRULE:FREQ=YEARLY;BYMONTH=1;BYDAY=SU,MO,TU,WE,TH,FR,SA '.
                'RRULE:FREQ=YEARLY;BYMONTH=2;BYDAY=SU,MO,TU,WE,TH,FR,SA '.
                'RDATE:19980303T030303',
        'deep union of unbounded recurrences formats ok' );

    # exclude date

    my $exclude = $union2->union(
                           $ical->parse_datetime( '19980303T030303' )
                        )->complement(
                           $ical->parse_datetime( '19980404T040404' )
                        );
    @str = $ical->format_recurrence( $exclude );
    is( "@str", 'RRULE:FREQ=YEARLY;BYMONTH=1;BYDAY=SU,MO,TU,WE,TH,FR,SA '.
                'RRULE:FREQ=YEARLY;BYMONTH=2;BYDAY=SU,MO,TU,WE,TH,FR,SA '.
                'RDATE:19980303T030303 '.
                'EXDATE:19980404T040404',
        'complement of date formats ok' );

    # clone keeps formatting

    @str = $ical->format_recurrence( $exclude->clone );
    is( "@str", 'RRULE:FREQ=YEARLY;BYMONTH=1;BYDAY=SU,MO,TU,WE,TH,FR,SA '.
                'RRULE:FREQ=YEARLY;BYMONTH=2;BYDAY=SU,MO,TU,WE,TH,FR,SA '.
                'RDATE:19980303T030303 '.
                'EXDATE:19980404T040404',
        'clone formats ok' );

    # exclude rule
    # exclude date + exclude rule

    my $exclude2 = $exclude->complement( $recur );
    @str = $ical->format_recurrence( $exclude2 );
    is( "@str", 'RRULE:FREQ=YEARLY;BYMONTH=1;BYDAY=SU,MO,TU,WE,TH,FR,SA '.
                'RRULE:FREQ=YEARLY;BYMONTH=2;BYDAY=SU,MO,TU,WE,TH,FR,SA '.
                'RDATE:19980303T030303 '.
                'EXDATE:19980404T040404 '.
                'EXRULE:FREQ=YEARLY;BYMONTH=1;BYDAY=SU,MO,TU,WE,TH,FR,SA',
        'complement of rule formats ok' );

    # exclude date + add date should die
    # exclude rule + add date should die

    my $mixed = $exclude->union( 
                           $ical->parse_datetime( '19980303T030303' )
                        );
    @str = ('Error');
    eval { @str = $ical->format_recurrence( $mixed ); };  # should die!
    is( "@str", 'Error',
        'exclude + complement of date cannot format' );


    # date + exclude rule -- should fail

    my $mixed2 = DateTime::Set->from_datetimes( 
                     dates => [ 
                         $ical->parse_datetime( '19980303T030303') 
                     ] )
                 ->union ( $recur );
    @str = ('Error');
    eval { @str = $ical->format_recurrence( $mixed2 ); };  # should die!
    is( "@str", 'Error',
        'unblessed date + recurrence cannot format' );


    # blessed date + rule

    my $mixed3 = DateTime::Set::ICal->from_datetimes(
                     dates => [
                         $ical->parse_datetime( '19980303T030303')
                     ] )
                 ->union ( $recur );
    @str = ('Error');
    eval { @str = $ical->format_recurrence( $mixed3 ); };  # should not die!
    is( "@str", 'RDATE:19980303T030303 '.
                'RRULE:FREQ=YEARLY;BYMONTH=1;BYDAY=SU,MO,TU,WE,TH,FR,SA',
        'blessed date + recurrence formats ok' );

    # blessed date + exclude rule
    # NOTE: this test was removed because the result of
    #  complement is not unbounded!
    #
    # my $mixed4 = DateTime::Set::ICal->from_datetimes(
    #                 dates => [
    #                     $ical->parse_datetime( '19980303T030303')
    #                 ] )
    #             ->complement ( $recur );
    # @str = ('Error');
    # eval { @str = $ical->format_recurrence( $mixed4 ); };  # should not die!
    # is( "@str", 'RDATE:19980303T030303 '.
    #            'EXRULE:FREQ=YEARLY;BYMONTH=1;BYDAY=SU,MO,TU,WE,TH,FR,SA',
    #     'blessed date + exclude recurrence formats ok' );


}

{
    # another example from rfc2445
    # DTSTART;TZID=US-Eastern:19980101T090000
    # RRULE:FREQ=YEARLY;UNTIL=2000-01-31T09:00:00;BYMONTH=1;BYDAY=SU,MO,TU,WE,TH,FR,SA
    my $recur =
        $ical->parse_recurrence
            ( recurrence => 'FREQ=YEARLY;UNTIL=20000131T090000Z;BYMONTH=1;BYDAY=SU,MO,TU,WE,TH,FR,SA',
              dtstart    => $ical->parse_datetime( '19980101T090000' )
            );

    my @r;
    my @dt;
    for ( 1 .. 2 )
    {
        my $dt = $recur->next;
        push @dt, $dt;
        push @r, $ical->format_datetime( $dt );
    }

    my $s1 = join ',', @r;

    my $s2 = join ',', ( '1998-01-01T09:00:00',
                         '1998-01-02T09:00:00'
                       );

    $s2 =~ s/[-:]//g;

    is( $s1, $s2, "recurrence parser with 'until' is ok" );

    # recurrence formatter

    my @str = $ical->format_recurrence( @dt );
    is( "@str", 'RDATE:19980101T090000,19980102T090000',
        'datetime recurrence formats ok' );

    # recurrence formatter - with mixed timezones

    $dt[0]->set_time_zone( 'UTC' );
    $dt[1]->set_time_zone( 'America/Chicago' );
    @str = $ical->format_recurrence( @dt );
    is( "@str", 'RDATE:19980101T090000Z '.
                'RDATE;TZID=America/Chicago:19980102T090000',
        'datetime with time zones recurrence formats ok' );

    # recurrence formatter - with spans

    push @dt, $recur->next;
    # the end time zone will be translated to 
    # the start time zone (America/Chicago)
    $dt[2]->set_time_zone( 'America/New-York' );
    my $spanset = DateTime::SpanSet->from_spans(
        spans => [
            DateTime::Span->from_datetimes( start => $dt[0], end => $dt[0] ),
            DateTime::Span->from_datetimes( start => $dt[1], before => $dt[2]),
        ]
    );
    @str = $ical->format_recurrence( $spanset );
    is( "@str", 
        'RDATE:19980101T090000Z '.
        'RDATE;VALUE=PERIOD;TZID=America/Chicago:19980102T090000/19980103T080000',
        'datetime spans with time zones recurrence formats ok' );
}

1;

