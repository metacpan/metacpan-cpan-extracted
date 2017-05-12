# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

use Test::More qw(no_plan);

BEGIN { use_ok('Date::ICal') };

#======================================================================
# BASIC INITIALIZATION TESTS
#====================================================================== 

my $t1 = new Date::ICal( epoch => 0 );
is( $t1->epoch, 0, "Epoch time of 0" );

# Make sure epoch time is being handled sanely.
# FIXME: This will only work on unix systems.
is( $t1->ical, '19700101Z', "When does the epoch start?" );

is( $t1->year,  1970, "Year accessor, start of epoch" );
is( $t1->month, 1,    "Month accessor, start of epoch" );
is( $t1->day,   1,    "Day accessor, start of epoch" );

# like the tests above, but starting with ical instead of epoch
my $t2 = new Date::ICal( ical => '19700101Z' );
is( $t2->ical, '19700101Z', "Start of epoch in ICal notation" );

# NOTE: this will FAIL unless you are in a UTC timezone. 
is( $t2->epoch, 0, "Time should be stored in UTC anyway, right?" );

# Dates in December are giving a month of 0. Test for this
my $dec = Date::ICal->new( ical => '19961222Z' );
is( $dec->month, 12, 'Date should be in December' );
$dec->add( week => 4 );
is( $dec->month, 1, '4 weeks later, it is January' );

#======================================================================
# ACCESSOR READ TESTS
#====================================================================== 

my $t3 = new Date::ICal( ical => "20010203T183020Z" );

is( $t3->year,   2001, "Year accessor" );
is( $t3->month,  2,    "Month accessor" );
is( $t3->day,    3,    "Day accessor" );
is( $t3->hour,   18,   "Hour accessor" );
is( $t3->minute, 30,   "Minute accessor" );
is( $t3->second, 20 || $t3->second == 19, "Second accessor" );

# XXX Round-off error

# TODO: test the timezone accessor, when there is one

#======================================================================
# ACCESSOR WRITE TESTS
#====================================================================== 

my $t4 = new Date::ICal( ical => "18701021T121045Z" );
is( $t4->year,   '1870', "Year accessor, outside of the epoch" );
is( $t4->month,  '10',   "Month accessor, outside the epoch" );
is( $t4->day,    '21',   "Day accessor, outside the epoch" );
is( $t4->hour,   '12',   "Hour accessor, outside the epoch" );
is( $t4->minute, '10',   "Minute accessor, outside the epoch" );
is( $t4->second, '45',   "Second accessor, outside the epoch" );

# OTHER TESTS WE NEED, once the code supports them:
# - timezone testing
# - UTC <-> localtime
# - arithmetic, with and without unit rollovers


