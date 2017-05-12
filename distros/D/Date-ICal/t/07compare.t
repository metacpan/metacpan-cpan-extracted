use Test::More qw(no_plan);

BEGIN { use_ok ('Date::ICal'); }

my $date1 = Date::ICal->new( ical => '19971024T120000');
my $date2 = Date::ICal->new( ical => '19971024T120000');


# make sure that comparing to itself eq 0
my $identity = $date1->compare($date2);
is( $identity, 0, "Identity comparison" );

$date2 = Date::ICal->new( ical => '19971024T120001' );
is( $date1->compare($date2), -1, 'Comparison $a < $b, 1 second diff' );

$date2 = Date::ICal->new( ical => '19971024T120100' );
is( $date1->compare($date2), -1, 'Comparison $a < $b, 1 minute diff' );

$date2 = Date::ICal->new( ical => '19971024T130000' );
is( $date1->compare($date2), -1, 'Comparison $a < $b, 1 hour diff' );

$date2 = Date::ICal->new( ical => '19971025T120000' );
is( $date1->compare($date2), -1, 'Comparison $a < $b, 1 day diff' );

$date2 = Date::ICal->new( ical => '19971124T120000' );
is( $date1->compare($date2), -1, 'Comparison $a < $b, 1 month diff' );

$date2 = Date::ICal->new( ical => '19981024T120000' );
is( $date1->compare($date2), -1, 'Comparison $a < $b, 1 year diff' );

# $a > $b tests

$date2 = Date::ICal->new( ical => '19971024T115959' );
is( $date1->compare($date2), 1, 'Comparison $a > $b, 1 second diff' );

$date2 = Date::ICal->new( ical => '19971024T115900' );
is( $date1->compare($date2), 1, 'Comparison $a > $b, 1 minute diff' );

$date2 = Date::ICal->new( ical => '19971024T110000' );
is( $date1->compare($date2), 1, 'Comparison $a > $b, 1 hour diff' );

$date2 = Date::ICal->new( ical => '19971023T120000' );
is( $date1->compare($date2), 1, 'Comparison $a > $b, 1 day diff' );

$date2 = Date::ICal->new( ical => '19970924T120000' );
is( $date1->compare($date2), 1, 'Comparison $a > $b, 1 month diff' );

$date2 = Date::ICal->new( ical => '19961024T120000' );
is( $date1->compare($date2), 1, 'Comparison $a > $b, 1 year diff' );

