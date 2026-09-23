#!/usr/bin/perl
##############################################################################
#
#  Data::Tools test suite -- Data::Tools::Time
#  Copyright (c) 2013-2026 Vladi Belperchinov-Shabanski "Cade"
#        <cade@noxrun.com> <cade@bis.bg> <cade@cpan.org>
#  http://cade.noxrun.com/
#
#  GPL
#
##############################################################################
use strict;
use lib 'lib', '../lib';
use Test::More;
use Data::Tools::Time;

ok( defined $Data::Tools::Time::VERSION, 'Data::Tools::Time loaded' );

##############################################################################
# unix time differences in words
##############################################################################

is( unix_time_diff_in_words(     0 ), 'now',                 'unix_time_diff_in_words() zero' );
is( unix_time_diff_in_words(     1 ), '1 second',            'unix_time_diff_in_words() one second' );
is( unix_time_diff_in_words(    59 ), '59 seconds',          'unix_time_diff_in_words() seconds' );
is( unix_time_diff_in_words(    60 ), '1 minute',            'unix_time_diff_in_words() one minute' );
is( unix_time_diff_in_words(  3600 ), '1 hour, 0 minutes',   'unix_time_diff_in_words() hours' );
is( unix_time_diff_in_words( 86400 * 3 ), '3 days, 0 hours', 'unix_time_diff_in_words() days' );

is( unix_time_diff_in_words( -3600 ), unix_time_diff_in_words( 3600 ),
    'unix_time_diff_in_words() uses absolute difference' );

is( unix_time_diff_in_words_short( 3600 ), '1 hour', 'unix_time_diff_in_words_short() drops minor unit' );

like( unix_time_diff_in_words_relative(  3600 ), qr/before/, 'unix_time_diff_in_words_relative() past' );
like( unix_time_diff_in_words_relative( -3600 ), qr/after/,  'unix_time_diff_in_words_relative() future' );
like( unix_time_diff_in_words_relative_short( 3600 ), qr/^before 1 hour$/,
      'unix_time_diff_in_words_relative_short()' );

##############################################################################
# julian date differences in words
##############################################################################

is( julian_date_diff_in_words(  0 ), '0 days',  'julian_date_diff_in_words() zero' );
is( julian_date_diff_in_words(  1 ), '1 day',   'julian_date_diff_in_words() one day' );
is( julian_date_diff_in_words( 40 ), '40 days', 'julian_date_diff_in_words() days' );
is( julian_date_diff_in_words( -40 ), julian_date_diff_in_words( 40 ),
    'julian_date_diff_in_words() uses absolute difference' );

is( julian_date_diff_in_words_relative( -40 ), 'in 40 days',     'julian_date_diff_in_words_relative() future' );
is( julian_date_diff_in_words_relative(  40 ), 'before 40 days', 'julian_date_diff_in_words_relative() past' );
is( julian_date_diff_in_words_relative(   0 ), 'today',          'julian_date_diff_in_words_relative() today' );
is( julian_date_diff_in_words_relative(  -1 ), 'tomorrow',       'julian_date_diff_in_words_relative() tomorrow' );
is( julian_date_diff_in_words_relative(  +1 ), 'yesterday',      'julian_date_diff_in_words_relative() yesterday' );

##############################################################################
# julian dates
##############################################################################

my $JD = julian_date_from_ymd( 2020, 2, 15 ); # a Saturday, leap year

cmp_ok( $JD, '>', 2400000, 'julian_date_from_ymd() returns a julian day number' );
is_deeply( [ julian_date_to_ymd( $JD ) ], [ 2020, 2, 15 ], 'julian_date_to_ymd()' );
is( julian_date_to_iso( $JD ), '2020-02-15', 'julian_date_to_iso() writes the zero padded extended form' );

# julian_date_from_iso() takes the same formats as utime_from_iso()/_ext()
is( julian_date_from_iso( '20200215' ),            $JD, 'julian_date_from_iso() basic format' );
is( julian_date_from_iso( '2020-02-15' ),          $JD, 'julian_date_from_iso() extended format' );
is( julian_date_from_iso( '20200215T103045' ),     $JD, 'julian_date_from_iso() basic format with time' );
is( julian_date_from_iso( '2020-02-15T10:30:45' ), $JD, 'julian_date_from_iso() extended format with time' );
is( julian_date_from_iso( '2020-02-15 10:30:45' ), $JD, 'julian_date_from_iso() accepts a space separator' );
is( julian_date_from_iso( ' 20200215 ' ),          $JD, 'julian_date_from_iso() tolerates surrounding space' );

is( julian_date_from_iso( '2020-2-15' ),           undef, 'julian_date_from_iso() requires zero padded fields' );
is( julian_date_from_iso( '2020-02-30' ),          undef, 'julian_date_from_iso() rejects a non-existent date' );
is( julian_date_from_iso( '2020-13-01' ),          undef, 'julian_date_from_iso() rejects an impossible month' );
is( julian_date_from_iso( '20200215T250000' ),     undef, 'julian_date_from_iso() rejects an impossible time' );
is( julian_date_from_iso( '2020-02' ),             undef, 'julian_date_from_iso() rejects a partial date' );
is( julian_date_from_iso( 'nonsense' ),            undef, 'julian_date_from_iso() rejects garbage' );

# every date string the utime parsers accept must parse here too, and no other
for my $iso ( '20200215T103045', '2020-02-15T10:30:45' )
  {
  is( julian_date_from_iso( $iso ), julian_date_from_utime( utime_from_iso( $iso ) // utime_from_iso_ext( $iso ) ),
      "julian_date_from_iso() agrees with the utime parsers on [$iso]" );
  }

is( julian_date_from_iso( julian_date_to_iso( $JD ) ), $JD,
    'julian_date_to_iso()/julian_date_from_iso() round trip' );

{
  my $bad = 0;
  my $j0  = julian_date_from_ymd( 2019, 1, 1 );
  for my $jd ( $j0 .. $j0 + 800 )
    {
    my ( $y, $m, $d ) = julian_date_to_ymd( $jd );
    $bad++ unless julian_date_from_iso( julian_date_to_iso( $jd ) ) == $jd;
    $bad++ unless julian_date_from_iso( sprintf( '%04d%02d%02d', $y, $m, $d ) ) == $jd;
    }
  is( $bad, 0, 'julian_date_from_iso() round trips exactly over a range of dates' );
}

is( julian_date_from_ymd( 2020 ),    julian_date_from_ymd( 2020, 1, 1 ), 'julian_date_from_ymd() defaults month/day to 1' );
is( julian_date_from_ymd( 2020, 3 ), julian_date_from_ymd( 2020, 3, 1 ), 'julian_date_from_ymd() defaults day to 1' );

is( julian_date_get_day(   $JD ), 15,   'julian_date_get_day()' );
is( julian_date_get_month( $JD ), 2,    'julian_date_get_month()' );
is( julian_date_get_year(  $JD ), 2020, 'julian_date_get_year()' );
is( julian_date_get_dow(   $JD ), 6,    'julian_date_get_dow() returns ISO8601 Mon=1..Sun=7' );
is( julian_date_get_dow( $JD + 1 ), 7,  'julian_date_get_dow() returns 7 for Sunday' );

is( julian_date_to_iso( julian_date_goto_first_dow( $JD ) ), '2020-02-10', 'julian_date_goto_first_dow() goes to Monday' );
is( julian_date_to_iso( julian_date_goto_last_dow(  $JD ) ), '2020-02-16', 'julian_date_goto_last_dow() goes to Sunday' );
is( julian_date_to_iso( julian_date_goto_first_dom( $JD ) ), '2020-02-01', 'julian_date_goto_first_dom()' );
is( julian_date_to_iso( julian_date_goto_last_dom(  $JD ) ), '2020-02-29', 'julian_date_goto_last_dom() handles leap year' );
is( julian_date_to_iso( julian_date_goto_first_doy( $JD ) ), '2020-01-01', 'julian_date_goto_first_doy()' );
is( julian_date_to_iso( julian_date_goto_last_doy(  $JD ) ), '2020-12-31','julian_date_goto_last_doy()' );

is( julian_date_month_days( $JD ), 29, 'julian_date_month_days() leap february' );
is( julian_date_month_days_ym( 2021, 2 ), 28, 'julian_date_month_days_ym() non-leap february' );
is( julian_date_month_days_ym( 2020, 1 ), 31, 'julian_date_month_days_ym() january' );

is( julian_date_to_iso( julian_date_add_ymd( $JD, 1, 1, 1 ) ), '2021-03-16', 'julian_date_add_ymd() positive delta' );
is( julian_date_to_iso( julian_date_add_ymd( $JD, -1, 0, 0 ) ), '2019-02-15', 'julian_date_add_ymd() negative delta' );
is( julian_date_add_ymd( $JD, 0, 0, 0 ), $JD, 'julian_date_add_ymd() zero delta' );

is( get_year_month_days( 2020, 2 ), 29, 'get_year_month_days()' );

##############################################################################
# julian_date_from_md() -- closest match, past or future
##############################################################################

my $NOW  = julian_date_from_utime( time() );
my $MD   = julian_date_from_md( 2, 15 );
my ( $md_y, $md_m, $md_d ) = julian_date_to_ymd( $MD );
is( $md_m, 2,  'julian_date_from_md() keeps requested month' );
is( $md_d, 15, 'julian_date_from_md() keeps requested day' );
cmp_ok( abs( $MD - $NOW ), '<=', 183, 'julian_date_from_md() picks the closest occurrence' );

##############################################################################
# unix time
##############################################################################

my $UT = utime_from_ymdhms( 2020, 2, 15, 10, 30, 45 );

cmp_ok( $UT, '>', 0, 'utime_from_ymdhms()' );
is_deeply( [ ( utime_to_ymdhms( $UT ) )[ 0 .. 5 ] ], [ 2020, 2, 15, 10, 30, 45 ], 'utime_to_ymdhms()' );

is( utime_from_ymdhms( 2020, 2, 15 ), utime_from_ymdhms( 2020, 2, 15, 0, 0, 0 ),
    'utime_from_ymdhms() defaults time to midnight' );

is( utime_to_iso(     $UT ), '20200215T103045',       'utime_to_iso() basic format' );
is( utime_to_iso_ext( $UT ), '2020-02-15T10:30:45',   'utime_to_iso_ext() extended format' );

is( utime_from_iso( '20200215T103045' ), $UT,         'utime_from_iso()' );
is( utime_from_iso( '20200215' ), utime_from_ymdhms( 2020, 2, 15, 0, 0, 0 ),
    'utime_from_iso() defaults a missing time to midnight' );
is( utime_from_iso( ' 20200215T103045 ' ), $UT,       'utime_from_iso() tolerates surrounding space' );

is( utime_from_iso_ext( '2020-02-15T10:30:45' ), $UT, 'utime_from_iso_ext()' );
is( utime_from_iso_ext( '2020-02-15 10:30:45' ), $UT, 'utime_from_iso_ext() accepts a space separator' );
is( utime_from_iso_ext( '2020-02-15' ), utime_from_ymdhms( 2020, 2, 15, 0, 0, 0 ),
    'utime_from_iso_ext() defaults a missing time to midnight' );

is( utime_from_iso( utime_to_iso( $UT ) ), $UT,             'utime_to_iso()/utime_from_iso() round trip' );
is( utime_from_iso_ext( utime_to_iso_ext( $UT ) ), $UT,     'utime_to_iso_ext()/utime_from_iso_ext() round trip' );

# the two formats are strict about each other
is( utime_from_iso( '2020-02-15T10:30:45' ), undef, 'utime_from_iso() rejects the extended format' );
is( utime_from_iso_ext( '20200215T103045' ), undef, 'utime_from_iso_ext() rejects the basic format' );

# malformed or impossible input yields undef rather than dying
is( utime_from_iso( 'nonsense' ),            undef, 'utime_from_iso() rejects garbage' );
is( utime_from_iso( '2020021' ),             undef, 'utime_from_iso() rejects a short date' );
is( utime_from_iso( '20200230T000000' ),     undef, 'utime_from_iso() rejects a non-existent date' );
is( utime_from_iso( '20200215T250000' ),     undef, 'utime_from_iso() rejects an impossible time' );
is( utime_from_iso_ext( '2020-2-15' ),       undef, 'utime_from_iso_ext() requires zero padded fields' );
is( utime_from_iso_ext( '2020-02-30' ),      undef, 'utime_from_iso_ext() rejects a non-existent date' );

# round trip a spread of instants, crossing DST in whichever zone we run in
{
  my $bad = 0;
  my $t0  = utime_from_ymdhms( 2021, 1, 1, 0, 0, 0 );
  for my $i ( 0 .. 200 )
    {
    my $t = $t0 + $i * 36000 + 997 * $i;
    $bad++ unless utime_from_iso(     utime_to_iso(     $t ) ) == $t;
    $bad++ unless utime_from_iso_ext( utime_to_iso_ext( $t ) ) == $t;
    }
  is( $bad, 0, 'iso round trip is exact across a spread of instants' );
}

is( julian_date_from_utime( $UT ), $JD, 'julian_date_from_utime()' );
is( utime_from_julian_date( $JD ), utime_from_ymdhms( 2020, 2, 15, 0, 0, 0 ),
    'utime_from_julian_date() returns midnight' );

##############################################################################
# splitting/joining unix time
##############################################################################

my ( $jd, $jtt ) = utime_split_to_jdt( $UT );
is( $jd,  $JD,                    'utime_split_to_jdt() julian day part' );
is( $jtt, 10*3600 + 30*60 + 45,   'utime_split_to_jdt() time part' );
is( utime_join_jdt( $jd, $jtt ), $UT, 'utime_join_jdt() round trip' );

my ( $ut, $utt ) = utime_split_to_utt( $UT );
is( $ut,  utime_from_ymdhms( 2020, 2, 15, 0, 0, 0 ), 'utime_split_to_utt() midnight part' );
is( $utt, 10*3600 + 30*60 + 45,                      'utime_split_to_utt() time part' );
is( utime_join_utt( $ut, $utt ), $UT, 'utime_join_utt() round trip' );

is( get_local_time_only( $UT ), 10*3600 + 30*60 + 45, 'get_local_time_only()' );

##############################################################################
# unix time arithmetic
##############################################################################

is( utime_to_iso_ext( utime_add_ymdhms( $UT, 1, 0, 0, 0, 0, 0 ) ), '2021-02-15T10:30:45', 'utime_add_ymdhms() year' );
is( utime_to_iso_ext( utime_add_ymdhms( $UT, 0, 0, 0, 0, 0, 15 ) ), '2020-02-15T10:31:00', 'utime_add_ymdhms() seconds carry' );
is( utime_to_iso_ext( utime_add_ymd( $UT, 0, 1, 0 ) ), '2020-03-15T10:30:45', 'utime_add_ymd() month' );
is( utime_to_iso_ext( utime_add_hms( $UT, 1, 0, 0 ) ), '2020-02-15T11:30:45', 'utime_add_hms() hour' );

is( utime_month_days( $UT ), 29, 'utime_month_days() leap february' );

##############################################################################
# unix time navigation
##############################################################################

is( utime_to_iso_ext( utime_goto_midnight(  $UT ) ), '2020-02-15T00:00:00', 'utime_goto_midnight()' );
is( utime_to_iso_ext( utime_goto_first_dow( $UT ) ), '2020-02-10T00:00:00', 'utime_goto_first_dow()' );
is( utime_to_iso_ext( utime_goto_last_dow(  $UT ) ), '2020-02-16T00:00:00', 'utime_goto_last_dow()' );
is( utime_to_iso_ext( utime_goto_first_dom( $UT ) ), '2020-02-01T00:00:00', 'utime_goto_first_dom()' );
is( utime_to_iso_ext( utime_goto_last_dom(  $UT ) ), '2020-02-29T00:00:00', 'utime_goto_last_dom()' );
is( utime_to_iso_ext( utime_goto_first_doy( $UT ) ), '2020-01-01T00:00:00', 'utime_goto_first_doy()' );
is( utime_to_iso_ext( utime_goto_last_doy(  $UT ) ), '2020-12-31T00:00:00', 'utime_goto_last_doy()' );

is( utime_get_dow( $UT ), 6, 'utime_get_dow() Saturday' );
is( utime_get_moy( $UT ), 2, 'utime_get_moy()' );

my $woy = utime_get_woy( $UT );
is( $woy, 7, 'utime_get_woy() in scalar context returns week' );
is_deeply( [ utime_get_woy( $UT ) ], [ 7, 2020 ], 'utime_get_woy() in list context returns week and year' );

##############################################################################
# local "now" helpers
##############################################################################

cmp_ok( get_local_julian_day(), '>', 2400000, 'get_local_julian_day()' );
is( get_local_julian_day(), julian_date_from_utime( time() ), 'get_local_julian_day() agrees with julian_date_from_utime()' );
is( get_local_year(), ( julian_date_to_ymd( get_local_julian_day() ) )[0], 'get_local_year()' );

##############################################################################

done_testing();
