use Test::More qw(no_plan);

BEGIN {
    use_ok( 'Date::ICal' );
}

my $d = Date::ICal->new( year => 2001, month => 7, day => 5, offset => 0 );
is( $d->year,  2001, "Year, creation by components" );
is( $d->month, 7,    "Month, creation by components" );
is( $d->day,   5,    "Day, creation by components" );
is( $d->hour,  0,    "Hour, creation by components" );
is( $d->min,   0,    "Min, creation by components" );
is( $d->sec,   0,    "Sec, creation by components" );
is( $d->ical, '20010705Z', "ical, creation by components" );

