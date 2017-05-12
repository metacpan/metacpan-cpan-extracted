use Test::More;
use lib '../lib';

BEGIN {
    use_ok( 'DateTime::Format::Human::Duration' );
}

diag( "Testing DateTime::Format::Human::Duration $DateTime::Format::Human::Duration::VERSION" );

SKIP: {
    eval 'use DateTime';
    skip 'DateTime required for creating DateTime object and durations', 22 if $@;

   #    Do setup
    my $time = time;
    my $dua = DateTime->from_epoch( 'epoch' => $time );
    my $dub = DateTime->from_epoch( 'epoch' => $time, 'locale' => 'fr' )->add(seconds => 2);
    my $duc = $dua->clone->add( minutes => 1, seconds => 3 );
    my $dud = $dua->clone->add(hours => 1, seconds => 25, nanoseconds => 445499897);
    my $due = $dua->clone->add(months => 9, days => 1, hours => 4, minutes => 17, seconds => 33, nanoseconds => 345000028);
    my $duf = $dua->clone->add( minutes => 1, seconds => 1 );
    

    my $dura = $dua - $dua;
    my $durc = $dua - $dub;
    my $durd = $dub - $dua;
    my $dure = $dua - $duc;
    my $durf = $dua - $dud;
    my $durg = $dua - $due;

   #    Start testing
   my $span = DateTime::Format::Human::Duration->new();
    isa_ok($span, 'DateTime::Format::Human::Duration');

    is( $span->format_duration($dura), 'no time', 'No difference w/ default no_time');
    is( $span->format_duration($dura,  'no_time' => 'absolutely no time' ), 'absolutely no time', 'No difference w/ no_time');
    is( $span->format_duration($dura,  'no_time' => '' ), '', 'No difference w/ empty no_time');
    is( $span->format_duration($durc), '2 seconds', '1 value');
    is( $span->format_duration_between($dub, $dua), '2 seconds', 'Reverse/Negative is still positive (not "no time")');
    is( $span->format_duration_between($dua, $duf), '1 minute and 1 second', '2 (singular values)');
    is( $span->format_duration($dure), '1 minute and 3 seconds', '2 values (mixed)' );
    is( $span->format_duration($durf), '1 hour, 25 seconds, and 445499897 nanoseconds', '> 2 values (3)');

    TODO: {
        local $TODO = "This doesn't work at 1343679514. Gives '2 days' instead of 1";
        # Note: it works with 8 months, or 10 months. So perhaps it's somehow
        #       related to rounding issues over multi-month durations?
        is( $span->format_duration($durg), '9 months, 1 day, 4 hours, 17 minutes, 33 seconds, and 345000028 nanoseconds', '> 2 values (5)');
    };

    is( $span->format_duration($durc, 'future' => 'Hello, You have %s left'), 'Hello, You have 2 seconds left', 'string with %s');
    is( $span->format_duration($durc, 'future' => 'You have'), 'You have 2 seconds', 'string w/ out %s');
    is( $span->format_duration_between($dua, $dub), '2 seconds', 'DateTime object method format_duration_between()');

    is( $span->format_duration_between($dua, $duc, 'past'=>'Was done %s ago.','future' => 'Will be done in %s.'), 'Will be done in 1 minute and 3 seconds.','$a->format_duration_between($b): $a < $b = future');
    is( $span->format_duration_between($duc, $dua, 'past'=>'Was done %s ago.','future' => 'Will be done in %s.'), 'Was done 1 minute and 3 seconds ago.','$a->format_duration_between($b): $a > $b = past');

    is( $span->format_duration_between( $duc, $duc->clone()->add('seconds'=> 62) ), '1 minute and 2 seconds', 'clone exmple');
    is( $span->format_duration( DateTime::Duration->new('seconds'=> 62) ), '62 seconds', 'Ambiguous duration (baseless)');

    # test 'locale' key
    is( $span->format_duration($dure, 'locale' => 'fr'), '1 minute et 3 seconds', 'locale key as string format_duration()');
    is( $span->format_duration($dure, 'locale' => $dub), '1 minute et 3 seconds', 'locale key as $DateTime obj format_duration()');
    is( $span->format_duration($dure, 'locale' => $dub->{'locale'}), '1 minute et 3 seconds', 'locale key as $DateTime->{\'locale\'} format_duration()');
    is( $span->format_duration_between($dub, $duc), '1 minute et 1 seconde', 'Object\'s locale used in format_duration_between()');

    # test 'significant_units'
    is( $span->format_duration($dure, significant_units => 1), '1 minute', 'only show one significant unit' );
    is( $span->format_duration($dure, significant_units => 99), '1 minute and 3 seconds', 'show up to 99 significant unit' );
    is( $span->format_duration($dure, significant_units => 99, units => ['minutes']), '1 minute', 'show up to 99 significant units, with specific units' );
    is( $span->format_duration($durf, significant_units => 1), '1 hour', 'show 1 unit of 3' );
    is( $span->format_duration($durf, significant_units => 2), '1 hour and 25 seconds', 'show 2 units of 3' );
    is( $span->format_duration($durf, significant_units => 3), '1 hour, 25 seconds, and 445499897 nanoseconds', 'show 3 units of 3' );
    is( $span->format_duration($durf, significant_units => 3, units => ['hours','minutes']), '1 hour', '3 significant_units with specified units of hours and minutes' );
    is( $span->format_duration($durf, significant_units => 3, units => ['hours','seconds']), '1 hour and 25 seconds', '3 significant_units with specified units of hours and seconds' );
};

done_testing();
