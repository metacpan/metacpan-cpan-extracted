#!/usr/bin/env perl
#
use strict;
use warnings FATAL => 'all';
use utf8;

use Test::More;

BEGIN {
    use_ok( 'DateTime::Format::Human::Duration::Simple' ) || print "Bail out!\n";
}

use DateTime;

# Define tests
my $time = time;
my $now  = DateTime->from_epoch( epoch => $time );

my @tests = (
    # Tests from DateTime::Format::Human::Duration.
    {
        name   => 'A test from DateTime::Format::Human::Duration (1)',
        from   => $now,
        to     => $now,
        result => '',
    },

    {
        name   => 'A test from DateTime::Format::Human::Duration (2)',
        from   => $now,
        to     => DateTime->from_epoch( epoch => $time )->add( seconds => 2 ),
        result => '2 seconds',
    },

    {
        name   => 'A test from DateTime::Format::Human::Duration (3)',
        from   => $now,
        to     => $now->clone->add( minutes => 1, seconds => 3 ),
        result => '1 minute and 3 seconds',
    },

    {
        name   => 'A test from DateTime::Format::Human::Duration (4)',
        from   => $now->clone->add( minutes => 1, seconds => 3 ),
        to     => $now,
        result => '1 minute and 3 seconds',
    },

    {
        name   => 'A test from DateTime::Format::Human::Duration (5)',
        from   => $now,
        to     => $now->clone->add( hours => 1, seconds => 25, nanoseconds => 445_499_897 ),
        result => '1 hour, 25 seconds, 445 milliseconds, and 499897 nanoseconds',
    },

    # Own tests.
    {
        name   => 'Test 1',
        from   => $now,
        to     => $now->clone->add( years => 1, months => 2, days => 3, hours => 4, minutes => 5, seconds => 61 ),
        result => '1 year, 2 months, 3 days, 4 hours, 6 minutes, and 1 second',
    },

    {
        # Language tests
        name   => 'Test 1',
        from   => $now,
        to     => $now->clone->add( years => 1, months => 2, days => 3, hours => 4, minutes => 5, seconds => 6 ),
        result => '1 year, 2 months, 3 days, 4 hours, 5 minutes, and 6 seconds',
    },

    {
        name   => 'Test 2',
        args   => { locale => 'fr' },
        from   => $now,
        to     => $now->clone->add( years => 1, months => 2, days => 3, hours => 4, minutes => 5, seconds => 6 ),
        result => '1 an, 2 mois, 3 jours, 4 heures, 5 minutes et 6 secondes',
    },

    {
        name   => 'Test 3',
        args   => { locale => 'de' },
        from   => $now,
        to     => $now->clone->add( years => 1, months => 2, days => 3, hours => 4, minutes => 5, seconds => 6 ),
        result => '1 Jahr, 2 Monate, 3 Tage, 4 Stunden, 5 Minuten und 6 Sekunden',
    },

    {
        name   => 'Test 4',
        args   => { locale => 'es' },
        from   => $now,
        to     => $now->clone->add( years => 1, months => 2, days => 3, hours => 4, minutes => 5, seconds => 6 ),
        result => '1 año, 2 meses, 3 días, 4 horas, 5 minutos y 6 segundos',
    },

    # Override 'serial_comma' tests.
    {
        # Language tests
        name   => 'Test 5',
        args   => { serial_comma => 0 },
        from   => $now,
        to     => $now->clone->add( years => 1, months => 2, days => 3, hours => 4, minutes => 5, seconds => 6 ),
        result => '1 year, 2 months, 3 days, 4 hours, 5 minutes and 6 seconds',
    },

    {
        name   => 'Test 6',
        args   => { locale => 'de', serial_comma => 1 },
        from   => $now,
        to     => $now->clone->add( years => 1, months => 2, days => 3, hours => 4, minutes => 5, seconds => 6 ),
        result => '1 Jahr, 2 Monate, 3 Tage, 4 Stunden, 5 Minuten, und 6 Sekunden',
    },

    {
        name   => 'Test 7',
        args   => { serial_comma => 0 },
        from   => $now,
        to     => $now->clone->add( hours => 1, seconds => 25, nanoseconds => 445_499_897 ),
        result => '1 hour, 25 seconds, 445 milliseconds and 499897 nanoseconds',
    },

    # Misc tests.
    {
        name   => 'Test 8',
        args   => { serial_comma => 0, locale => 'no' },
        from   => $now,
        to     => $now->clone->add( hours => 1, seconds => 25, nanoseconds => 445_499_897 ),
        result => '1 time, 25 sekunder, 445 millisekunder og 499897 nanosekunder',
    },

    {
        name   => 'Test 9',
        args   => { locale => 'no' },
        from   => $now,
        to     => $now->clone->add( hours => 1, seconds => 25, nanoseconds => 445_499_897 ),
        result => '1 time, 25 sekunder, 445 millisekunder, og 499897 nanosekunder',
    },

    {
        name   => 'Test 10',
        from   => $now,
        to     => $now->clone->add( days => 14 ),
        result => '2 weeks',
    },
);

# Do the tests
foreach ( @tests ) {
    my $args   = $_->{args}      || {};
    my $locale = $args->{locale} || 'en';

    my $df = DateTime::Format::Human::Duration::Simple->new(
        from   => $_->{from},
        to     => $_->{to},
        locale => $locale,
        %{$args},
    );

    is( $df->formatted, $_->{result}, $_->{name} );
}

# The End
done_testing;
