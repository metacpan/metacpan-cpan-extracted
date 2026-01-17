#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use File::Basename;
use File::Spec;
use Fred::Fish::DBUG 2.09 qw / on /;
use Fred::Fish::DBUG::Test 2.09;

# How to find the helper module ...
BEGIN { push (@INC, File::Spec->catdir (".", "t", "test-helper")); }
use helper1234;

# Does valiation of Advanced::Config::Date ...
# Has Wide Char languages disabled during these tests!

BEGIN {
   my $fish = turn_fish_on_off_for_advanced_config ();

   unlink ( $fish );

   # Turn fish on ...
   DBUG_PUSH ( $fish );

   DBUG_ENTER_FUNC ();

   use_ok ( "Advanced::Config::Date" );      # Test # 2

   DBUG_VOID_RETURN ();
}

# Get the Days of Week in English.
my @englishDoW = qw( Sunday Monday Tuesday Wednesday Thursday Friday Saturday );

END {
   DBUG_ENTER_FUNC ();
   DBUG_VOID_RETURN ();
}

# --------------------------------------
# The date test cases to use ...
# Pattern ==> Expected results ...
# --------------------------------------
my %english_tests = (
        "1995:01:24T09:08:17.1823213"          => "1995-01-24",
        "1995-01-24T09:08:17.1823213"          => "1995-01-24",
        "1995.01.24T09:08:17.1823213"          => "1995-01-24",
        "1995 01 24T09:08:17.1823213"          => "1995-01-24",
        "95 01 24T09:08:17.1823213"            => "1995-01-24",
        "20171225"                             => "2017-12-25",
        "12252017"                             => "2017-12-25",
        "Hello 20171225 World!"                => "2017-12-25",
        "Wed, 16 Jun 94 07:29:35 CST"          => "1994-06-16",
        "Thu, 13 Oct 94 10:13:13 -0700"        => "1994-10-13",
        "Thu, 13 October 94 10:13:13 -0700"    => "1994-10-13",
        "Wed, 9 Nov 1994 09:50:32 -0500 (EST)" => "1994-11-09",
        "25 dec 2017 18:05"                    => "2017-12-25",
        "25/dec/2017 18:05"                    => "2017-12-25",
        "17/dec/25 18:05"                      => "2017-12-25",   # Ambiguous
        '17\dec\25 18:05'                      => "2017-12-25",   # Ambiguous
        "dec/25/17 18:05"                      => "2017-12-25",
        "dec/25/2017 18:05"                    => "2017-12-25",
        "Mon, 25/dec/2017 18:05"               => "2017-12-25",
        "mon Dec. 25th 17 18:05"               => "2017-12-25",
        "Mon December 25th 17 18:05"           => "2017-12-25",
        "Mon December 25th 03:45:08 2017"      => "2017-12-25",
        "Mon December 25 03:45:08 2017"        => "2017-12-25",
        "Mon December 25, 2017 at 03:45:08"    => "2017-12-25",
        "Monday December 25 2017 at 03:45:08"  => "2017-12-25",
        "Wed,    16   Jun  94 07:29:35 CST"    => "1994-06-16",
        "Wed,  16   Jun    1994 07:29:35 CST"  => "1994-06-16",
    );

# To use when Date::Language is installed.
my %dl_tests = (
        "wed Jun 16"                           => "%04d-06-16",
        "wed 16 Jun"                           => "%04d-06-16",
        # "wed 2016 Jun"                       => "2016-06-01",  # Doesn't work
    );

my %german_tests = (
        "1995:01:24T09:08:17.1823213"          => "1995-01-24",
        "1995-01-24T09:08:17.1823213"          => "1995-01-24",
        "Mit, 16 Jun 94 07:29:35 CST"          => "1994-06-16",
        "Don, 13 Okt 94 10:13:13 -0700"        => "1994-10-13",
        "Don, 13 Oktober 94 10:13:13 -0700"    => "1994-10-13",
        "Mit, 9 Nov 1994 09:50:32 -0500 (EST)" => "1994-11-09",
        "25 dez 2017 17:05"                    => "2017-12-25",
        "25/dez/2017 17:05"                    => "2017-12-25",
        "17/dez/25 17:05"                      => "2017-12-25",   # Ambiguous
        "Mon, 25/dez/2017 17:05"               => "2017-12-25",
        "mon Dez. 25th 17 17:05"               => "2017-12-25",
        "Mon Dezember 25th 17 17:05"           => "2017-12-25",
        "Mon Dezember 25th 03:45:08 2017"      => "2017-12-25",
        "Mon Dezember 25 03:45:08 2017"        => "2017-12-25",
        "Mon Dezember 25, 2017 03:45:08"       => "2017-12-25",
        "Mit,  16    Jun   94 07:29:35 CST"    => "1994-06-16",
        "März 23rd, 2019"                      => "2019-03-23",
        "MÄRZ 22nd, 2019"                      => "2019-03-22",
    );

my %spanish_tests = (
        "1995:01:24T09:08:17.1823213"          => "1995-01-24",
        "1995-01-24T09:08:17.1823213"          => "1995-01-24",
        "Mié, 16 Jun 94 07:29:35 CST"          => "1994-06-16",
        "Jue, 13 Oct 94 10:13:13 -0700"        => "1994-10-13",
        "Jue, 13 Octubre 94 10:13:13 -0700"    => "1994-10-13",
        "Mié, 9 Nov 1994 09:50:32 -0500 (EST)" => "1994-11-09",
        "25 dic 2017 17:05"                    => "2017-12-25",
        "25/dic/2017 17:05"                    => "2017-12-25",
        "17/dic/25 17:05"                      => "2017-12-25",   # Ambiguous
        "Lun, 25/dic/2017 17:05"               => "2017-12-25",
        "Lun Dic. 25to 17 17:05"               => "2017-12-25",
        "Lun Diciembre 25to 17 17:05"          => "2017-12-25",
        "Lun Diciembre 25to 03:45:08 2017"     => "2017-12-25",
        "Lun Diciembre 25 03:45:08 2017"       => "2017-12-25",
        "Lun Diciembre 25, 2017 03:45:08"      => "2017-12-25",
        "Mié, 16    Jun    94 07:29:35 CST"    => "1994-06-16",
    );

my %no_tests;

# date => [hyd, DoW, DoY]
my %hyd_tests = (
	"1899-12-31"    => [     0,  0, 365 ],         # Special case.

	# Start of -hyd tests
	"1899-12-30"    => [    -1,  6, 364 ],
	"1899-11-30"    => [   -31,  4, 334 ],

	# Leap Year tests -hyd
	"1820-02-28"    => [ -29161, 1,  59 ],
	"1820-02-29"    => [ -29160, 2,  60 ],
	"1820-03-01"    => [ -29159, 3,  61 ],
	# "1821-02-29"  => [ undef, undef, undef ],    # Bad Leap Year

	# A year's worth of edge cases: -hyd
	"1822-12-31"    => [ -28124, 2, 365 ],
	"1823-01-01"    => [ -28123, 3,   1 ],
	"1823-01-31"    => [ -28093, 5,  31 ],
	"1823-02-01"    => [ -28092, 6,  32 ],
	"1823-02-28"    => [ -28065, 5,  59 ],
	"1823-03-01"    => [ -28064, 6,  60 ],
	"1823-03-31"    => [ -28034, 1,  90 ],
	"1823-04-01"    => [ -28033, 2,  91 ],
	"1823-04-30"    => [ -28004, 3, 120 ],
	"1823-05-01"    => [ -28003, 4, 121 ],
	"1823-05-31"    => [ -27973, 6, 151 ],
	"1823-06-01"    => [ -27972, 0, 152 ],
	"1823-06-30"    => [ -27943, 1, 181 ],
	"1823-07-01"    => [ -27942, 2, 182 ],
	"1823-07-31"    => [ -27912, 4, 212 ],
	"1823-08-01"    => [ -27911, 5, 213 ],
	"1823-08-31"    => [ -27881, 0, 243 ],
	"1823-09-01"    => [ -27880, 1, 244 ],
	"1823-09-30"    => [ -27851, 2, 273 ],
	"1823-10-01"    => [ -27850, 3, 274 ],
	"1823-10-31"    => [ -27820, 5, 304 ],
	"1823-11-01"    => [ -27819, 6, 305 ],
	"1823-11-30"    => [ -27790, 0, 334 ],
	"1823-12-01"    => [ -27789, 1, 335 ],
	"1823-12-31"    => [ -27759, 3, 365 ],
	"1824-01-01"    => [ -27758, 4,   1 ],

	# A year's worth of middle of the road test cases: -hyd
	"1824-01-15"    => [ -27744, 4,  15 ],
	"1824-02-15"    => [ -27713, 0,  46 ],
	"1824-03-15"    => [ -27684, 1,  75 ],
	"1824-04-15"    => [ -27653, 4, 106 ],
	"1824-05-15"    => [ -27623, 6, 136 ],
	"1824-06-15"    => [ -27592, 2, 167 ],
	"1824-07-15"    => [ -27562, 4, 197 ],
	"1824-08-15"    => [ -27531, 0, 228 ],
	"1824-09-15"    => [ -27500, 3, 259 ],
	"1824-10-15"    => [ -27470, 5, 289 ],
	"1824-11-15"    => [ -27439, 1, 320 ],
	"1824-12-15"    => [ -27409, 3, 350 ],

	# Start of +hyd tests
	"1900-01-01"    => [      1, 1,   1 ],
	"1900-12-31"    => [    365, 1, 365 ],
	"2013-06-04"    => [  41428, 2, 155 ],

	# Leap Year tests +hyd
	"2020-02-28"    => [  43888, 5,  59 ],
	"2020-02-29"    => [  43889, 6,  60 ],
	"2020-03-01"    => [  43890, 0,  61 ],
	# "2021-02-29"  => [ undef, undef, undef ],    # Bad Leap Year

	# A year's worth of edge cases: +hyd
	"2022-12-31"    => [  44925, 6, 365 ],
	"2023-01-01"    => [  44926, 0,   1 ],
	"2023-01-31"    => [  44956, 2,  31 ],
	"2023-02-01"    => [  44957, 3,  32 ],
	"2023-02-28"    => [  44984, 2,  59 ],
	"2023-03-01"    => [  44985, 3,  60 ],
	"2023-03-31"    => [  45015, 5,  90 ],
	"2023-04-01"    => [  45016, 6,  91 ],
	"2023-04-30"    => [  45045, 0, 120 ],
	"2023-05-01"    => [  45046, 1, 121 ],
	"2023-05-31"    => [  45076, 3, 151 ],
	"2023-06-01"    => [  45077, 4, 152 ],
	"2023-06-30"    => [  45106, 5, 181 ],
	"2023-07-01"    => [  45107, 6, 182 ],
	"2023-07-31"    => [  45137, 1, 212 ],
	"2023-08-01"    => [  45138, 2, 213 ],
	"2023-08-31"    => [  45168, 4, 243 ],
	"2023-09-01"    => [  45169, 5, 244 ],
	"2023-09-30"    => [  45198, 6, 273 ],
	"2023-10-01"    => [  45199, 0, 274 ],
	"2023-10-31"    => [  45229, 2, 304 ],
	"2023-11-01"    => [  45230, 3, 305 ],
	"2023-11-30"    => [  45259, 4, 334 ],
	"2023-12-01"    => [  45260, 5, 335 ],
	"2023-12-31"    => [  45290, 0, 365 ],
	"2024-01-01"    => [  45291, 1,   1 ],

	# A year's worth of middle of the road test cases: +hyd
	"2024-01-15"    => [  45305, 1,  15 ],
	"2024-02-15"    => [  45336, 4,  46 ],
	"2024-03-15"    => [  45365, 5,  75 ],
	"2024-04-15"    => [  45396, 1, 106 ],
	"2024-05-15"    => [  45426, 3, 136 ],
	"2024-06-15"    => [  45457, 6, 167 ],
	"2024-07-15"    => [  45487, 1, 197 ],
	"2024-08-15"    => [  45518, 4, 228 ],
	"2024-09-15"    => [  45549, 0, 259 ],
	"2024-10-15"    => [  45579, 2, 289 ],
	"2024-11-15"    => [  45610, 5, 320 ],
	"2024-12-15"    => [  45640, 0, 350 ],
    );

   # idx => [date, years, months, answer]
   my %adj_tests = (
	# Middle of month tests
	"a08"    => [ "1999-12-15", 0, -46, "1996-02-15" ],
	"a09"    => [ "1999-12-15", 0, -36, "1996-12-15" ],
	"a10"    => [ "1999-12-15", 0, -13, "1998-11-15" ],
	"a11"    => [ "1999-12-15", 0, -12, "1998-12-15" ],
	"a12"    => [ "1999-12-15", 0, -11, "1999-01-15" ],
	"a13"    => [ "1999-12-15", 0, -10, "1999-02-15" ],
	"a14"    => [ "1999-12-15", 0,  -9, "1999-03-15" ],
	"a15"    => [ "1999-12-15", 0,  -8, "1999-04-15" ],
	"a16"    => [ "1999-12-15", 0,  -7, "1999-05-15" ],
	"a17"    => [ "1999-12-15", 0,  -6, "1999-06-15" ],
	"a18"    => [ "1999-12-15", 0,  -5, "1999-07-15" ],
	"a19"    => [ "1999-12-15", 0,  -4, "1999-08-15" ],
	"a20"    => [ "1999-12-15", 0,  -3, "1999-09-15" ],
	"a21"    => [ "1999-12-15", 0,  -2, "1999-10-15" ],
	"a22"    => [ "1999-12-15", 0,  -1, "1999-11-15" ],
	"a23"    => [ "1999-12-15", 0,   0, "1999-12-15" ],
	"a24"    => [ "1999-12-15", 0,   1, "2000-01-15" ],
	"a25"    => [ "1999-12-15", 0,   2, "2000-02-15" ],
	"a26"    => [ "1999-12-15", 0,   3, "2000-03-15" ],
	"a27"    => [ "1999-12-15", 0,   4, "2000-04-15" ],
	"a28"    => [ "1999-12-15", 0,   5, "2000-05-15" ],
	"a29"    => [ "1999-12-15", 0,   6, "2000-06-15" ],
	"a30"    => [ "1999-12-15", 0,   7, "2000-07-15" ],
	"a31"    => [ "1999-12-15", 0,   8, "2000-08-15" ],
	"a32"    => [ "1999-12-15", 0,   9, "2000-09-15" ],
	"a33"    => [ "1999-12-15", 0,  10, "2000-10-15" ],
	"a34"    => [ "1999-12-15", 0,  11, "2000-11-15" ],
	"a35"    => [ "1999-12-15", 0,  12, "2000-12-15" ],
	"a36"    => [ "1999-12-15", 0,  13, "2001-01-15" ],
	"a37"    => [ "1999-12-15", 0,  14, "2001-02-15" ],
	"a38"    => [ "1999-12-15", 0,  15, "2001-03-15" ],

	# End of month tests
	"b08"    => [ "1999-12-31", 0, -46, "1996-02-29" ],
	"b09"    => [ "1999-12-31", 0, -36, "1996-12-31" ],
	"b10"    => [ "1999-12-31", 0, -13, "1998-11-30" ],
	"b11"    => [ "1999-12-31", 0, -12, "1998-12-31" ],
	"b12"    => [ "1999-12-31", 0, -11, "1999-01-31" ],
	"b13"    => [ "1999-12-31", 0, -10, "1999-02-28" ],
	"b14"    => [ "1999-12-31", 0,  -9, "1999-03-31" ],
	"b15"    => [ "1999-12-31", 0,  -8, "1999-04-30" ],
	"b16"    => [ "1999-12-31", 0,  -7, "1999-05-31" ],
	"b17"    => [ "1999-12-31", 0,  -6, "1999-06-30" ],
	"b18"    => [ "1999-12-31", 0,  -5, "1999-07-31" ],
	"b19"    => [ "1999-12-31", 0,  -4, "1999-08-31" ],
	"b20"    => [ "1999-12-31", 0,  -3, "1999-09-30" ],
	"b21"    => [ "1999-12-31", 0,  -2, "1999-10-31" ],
	"b22"    => [ "1999-12-31", 0,  -1, "1999-11-30" ],
	"b23"    => [ "1999-12-31", 0,   0, "1999-12-31" ],
	"b24"    => [ "1999-12-31", 0,   1, "2000-01-31" ],
	"b25"    => [ "1999-12-31", 0,   2, "2000-02-29" ],
	"b26"    => [ "1999-12-31", 0,   3, "2000-03-31" ],
	"b27"    => [ "1999-12-31", 0,   4, "2000-04-30" ],
	"b28"    => [ "1999-12-31", 0,   5, "2000-05-31" ],
	"b29"    => [ "1999-12-31", 0,   6, "2000-06-30" ],
	"b30"    => [ "1999-12-31", 0,   7, "2000-07-31" ],
	"b31"    => [ "1999-12-31", 0,   8, "2000-08-31" ],
	"b32"    => [ "1999-12-31", 0,   9, "2000-09-30" ],
	"b33"    => [ "1999-12-31", 0,  10, "2000-10-31" ],
	"b34"    => [ "1999-12-31", 0,  11, "2000-11-30" ],
	"b35"    => [ "1999-12-31", 0,  12, "2000-12-31" ],
	"b36"    => [ "1999-12-31", 0,  13, "2001-01-31" ],
	"b37"    => [ "1999-12-31", 0,  14, "2001-02-28" ],
	"b38"    => [ "1999-12-31", 0,  15, "2001-03-31" ],

	# Year tests
	"c00"    => [ "2000-01-01", -10,   0, "1990-01-01" ],
	"c03"    => [ "2000-01-01", -10,   3, "1990-04-01" ],
	"c10"    => [ "2000-01-01",  -5,   0, "1995-01-01" ],
	"c13"    => [ "2000-01-01",  -5,   3, "1995-04-01" ],
	"c20"    => [ "2000-01-01",  -1,  12, "2000-01-01" ],
	"c23"    => [ "2000-01-01",   1, -12, "2000-01-01" ],
	"c30"    => [ "2000-01-01",   5,   0, "2005-01-01" ],
	"c33"    => [ "2000-01-01",   5,   3, "2005-04-01" ],
	"c40"    => [ "2000-01-01",  10,   0, "2010-01-01" ],
	"c43"    => [ "2000-01-01",  10,   3, "2010-04-01" ],
	
	# Leap Year tests
	"d50"    => [ "2020-02-29", -5, 0, "2015-02-28" ],
	"d51"    => [ "2020-02-29", -4, 0, "2016-02-29" ],
	"d52"    => [ "2020-02-29", -3, 0, "2017-02-28" ],
	"d53"    => [ "2020-02-29", -2, 0, "2018-02-28" ],
	"d54"    => [ "2020-02-29", -1, 0, "2019-02-28" ],
	"d55"    => [ "2020-02-29",  0, 0, "2020-02-29" ],
	"d56"    => [ "2020-02-29",  1, 0, "2021-02-28" ],
	"d57"    => [ "2020-02-29",  2, 0, "2022-02-28" ],
	"d58"    => [ "2020-02-29",  3, 0, "2023-02-28" ],
	"d59"    => [ "2020-02-29",  4, 0, "2024-02-29" ],
	"d60"    => [ "2020-02-29",  5, 0, "2025-02-28" ],

	# Misc tests
	"e10"    => [ "2024-01-30",  0, 0, "2024-01-30" ],
	"e11"    => [ "2024-01-30",  0, 1, "2024-02-29" ],
	"e12"    => [ "2024-01-30",  0, 2, "2024-03-30" ],
	"e13"    => [ "2024-01-30",  0, 3, "2024-04-30" ],
	"e21"    => [ "2024-01-30",  1, 1, "2025-02-28" ],
	"e22"    => [ "2024-01-30",  2, 1, "2026-02-28" ],
	"e23"    => [ "2024-01-30",  3, 1, "2027-02-28" ],
	"e24"    => [ "2024-01-30",  4, 1, "2028-02-29" ],
   );

# --------------------------------------
# Start of the main program!
# --------------------------------------
{
   DBUG_ENTER_FUNC (@ARGV);

   dbug_ok (1, "In the MAIN program ...");   # Test # 3 ...

   my $opt = 1;
   my $tst1 = run_date_parse_tests ( "English", $opt, \%english_tests, 1 );
   my $tst2 = run_date_parse_tests ( "German",  $opt, \%german_tests, 1 );
   my $tst3 = run_date_parse_tests ( "german",  $opt, \%no_tests, 0 );
   my $tst4 = run_date_parse_tests ( "Spanish", $opt, \%spanish_tests, 1 );
   my $tst5 = run_date_parse_tests ( "Greek",   $opt, \%no_tests, 0 );
   my $tst6 = run_date_parse_tests ( "Klingon", $opt, \%no_tests, 0 );

   if ( _date_language_installed () ) {
      run_dl_dates ( 1, "English", $opt, \%dl_tests );
   }
   run_dl_dates ( 0, "English", $opt, \%dl_tests );

   # Rerun the good test ...
   $tst1 = run_date_parse_tests ( "English", $opt, \%english_tests, 1 );

   foreach my $lang ("English", "German", "german", "Spanish", "Greek", "Klingon") {
      run_special_dates ( $lang, $opt );
   }

   run_hyd_tests ();

   test_leap_years ();

   test_adjustments ();

   # Since I didn't count the test cases, must end my program
   # with a call to this method.  Can't do tests in END anymore!
   done_testing ();

   DBUG_LEAVE (0);
}

# -----------------------------------------------
# Do my testing by language ...
# Returns: 1 if it can do the tests.
#          0 if it can't change the langage used.
# -----------------------------------------------

sub run_date_parse_tests
{
   DBUG_ENTER_FUNC (@_);
   my $lang  = shift;
   my $fwarn = shift;
   my $tests = shift;
   my $valid_language = shift;

   dbug_ok (1, "-"x50);

   # Set language for later call to parse_date () ...
   my $ans = swap_language ( $lang, $fwarn, 0 );
   if ( $ans eq $lang ) {
      dbug_ok ( $valid_language, "Language successfully swapped to '${lang}'." );
   } elsif ( _date_language_installed () ) {
      dbug_is ( $valid_language, 0, "${lang} is NOT supported.  Still using '${ans}'.");
      return DBUG_RETURN (0);
   } else {
      dbug_ok ( 1, "${lang} is NOT installed.  Still using '${ans}'.");
      return DBUG_RETURN (0);
   }

   # ISO(1), American(2), European(3) ... YMD,MDY,DMY
   my $test_order = "1,2,3";

   # Doesn't use Date::Langauge::str2time().
   # But do allow 2-digit years for dates!
   foreach my $k ( sort keys %{$tests} ) {
      my $date = parse_date ( $k, $test_order, 0, 1 );
      $date = "???"  unless ( defined $date );
      dbug_is ( $date, $tests->{$k}, "$k ==> ${date}" );
   }

   DBUG_RETURN (1);
}

# -----------------------------------------------

sub run_special_dates
{
   DBUG_ENTER_FUNC (@_);
   my $lang  = shift;
   my $opt   = shift;

   dbug_ok (1, "-"x50);

   # Set language for later call to parse_date () ...
   my $ans = swap_language ( $lang, 0, 0 );
   if ( $ans eq $lang ) {
      dbug_ok ( 1, "Language successfully swapped to '${lang}'." );
   } else {
      dbug_ok ( 1, "${lang} is NOT supported.  Still using '${ans}'.");
      return DBUG_RETURN (0);
   }

   # Get the numeric months ...
   my ($month_ref, $week_ref) = init_special_date_arrays ($lang, 0, $opt, 0);

   my @answers;
   foreach (0..11) {
      push (@answers, sprintf ("2018-%02d-01", $month_ref->[$_]));
   }

   foreach my $mode ( 1, 2, 3 ) {
      ($month_ref, $week_ref) = init_special_date_arrays ($lang, $mode, $opt, 0);
      foreach my $i ( 0..11 ) {
         my $sample = sprintf ("%s 1 2018", $month_ref->[$i]);
         my $date = parse_date ( $sample, "1,2,3", 0, 1 );
         $date = "???"  unless ( defined $date );
         dbug_is ( $date, $answers[$i], "${sample} ==> ${date}" );
      }
   }

   DBUG_RETURN (1);
}

# -----------------------------------------------
# For parsing dates using Date::Languate::str2time().

sub run_dl_dates
{
   DBUG_ENTER_FUNC (@_);
   my $dl_installed = shift;
   my $lang         = shift;
   my $fwarn        = shift;
   my $tests        = shift;

   dbug_ok (1, "-"x50);

   # Set language for later call to parse_date () ...
   my $ans = swap_language ( $lang, $fwarn, 0 );
   if ( $ans eq $lang ) {
      dbug_ok ( 1, "Language successfully swapped to '${lang}'." );
   } else {
      dbug_ok ( 1, "${lang} is NOT supported.  Still using '${ans}'.");
      return DBUG_RETURN (0);
   }

   my $year = (localtime (time ()))[5] + 1900;

   foreach my $k ( sort keys %{$tests} ) {
      my $date = parse_date ( $k, "1,2,3", $dl_installed, 1 );
      $date = "???"  unless ( defined $date );
      if ( $dl_installed ) {
         my $dt1 = sprintf ( $tests->{$k}, $year );
         my $dt2 = sprintf ( $tests->{$k}, $year - 1 );
         unless (dbug_ok ( $date eq $dt1 || $date eq $dt2, "$k ==> ${date}" )) {
            DBUG_PRINT ("INFO", "Should have been %s or %s", $dt1, $dt2);
         }
      } else {
         dbug_is ( $date, "???", "$k ==> ${date}, Date::Languge::str2time not used." );
      }
   }

   DBUG_RETURN (1);
}

# -----------------------------------------------
sub dow_names
{
   my $iDOW = shift;
   unless (defined $iDOW && 0 <= $iDOW && $iDOW <= 6) {
      return ("Unknown DOW");
   }
   return ( $englishDoW[$iDOW] );
}

# -----------------------------------------------
# Run the HYD related tests ..

sub run_hyd_tests
{
   DBUG_ENTER_FUNC (@_);

   my ($expected_hyd, $expected_DoW, $expected_DoY, $dowName, $numDays);

   my ($key, $array_ref);
   my $dash = '=' x 20;

   # date => [hyd, DoW, DoY]
   foreach $key (sort keys %hyd_tests) {
      $array_ref = $hyd_tests{$key};
      $expected_hyd = $array_ref->[0];
      $expected_DoW = $array_ref->[1];
      $expected_DoY = $array_ref->[2];

      $dowName = dow_names ($expected_DoW);

      dbug_ok (1, "${dash} ${key} ${dash}");

      my $ok = 0;  # Assume failure
      if ($key =~ m/^(\d+)/) {
         my $eoy = "${1}-12-31";
	 $numDays = calc_day_of_year ( $eoy, 0 );
	 my $zero = calc_day_of_year ( $eoy, 1 );

	 $ok = ($zero == 0) && ($numDays == 365 || $numDays == 366);
      }
      dbug_ok ($ok, "Found correct number of days in year.");
      unless ($ok) {
         next;
      }

      my $hyd = calc_hundred_year_date ( $key );
      my $sts = dbug_cmp_ok ($hyd, '==', $expected_hyd, "Testing HYD for $key");
      unless ($sts) {
         next;
      }

      my $dow1 = calc_day_of_week ( $key );
      $sts = dbug_cmp_ok ($dow1, '==', $expected_DoW, "Testing DoW for $key ($dowName)");
      my $dow2 = calc_day_of_week ( $expected_hyd );
      $sts = dbug_cmp_ok ($dow2, '==', $expected_DoW, "Testing DoW for HYD $expected_hyd ($dowName)");

      my $doy = calc_day_of_year ( $key );
      $sts = dbug_cmp_ok ($doy, '==', $expected_DoY, "Testing DoY for $key");

      my $remainder = calc_day_of_year ( $key, 1 );
      my $ans = $numDays - $doy;
      $sts = dbug_cmp_ok ($remainder, '==', $ans, "Testing DoY remainder for $key");

      my $str = convert_hyd_to_date_str ( $expected_hyd );
      $sts = dbug_cmp_ok ($str, 'eq', $key, "Testing date_str for HYD $expected_hyd");

      # unless ($sts) { last; }
   }

   DBUG_RETURN (1);
}

# -----------------------------------------------

sub test_leap_years
{
   DBUG_ENTER_FUNC (@_);

   my %leap_years;

   # Hard code all the leap years to test against.
   for (my $i = 1896; $i <= 2027; $i = $i + 4) {
      $leap_years{$i} = 1;
   }
   delete $leap_years{1900};

   foreach my $yr ( 1894..2027 ) {
      my $expected = $leap_years{$yr} || 0;

      my $got = is_leap_year ($yr);

      if ( $expected != $got ) {
         dbug_ok ( 0, $expected
                       ? "${yr} is a leap year."
                       : "${yr} is not a leap year." );
      }
   }

   DBUG_RETURN (1);
}

# -----------------------------------------------

sub test_adjustments
{
   DBUG_ENTER_FUNC (@_);
 
   # idx => [date, years, months, answer]
   foreach my $k (sort keys %adj_tests) {
      my $src_date      = $adj_tests{$k}->[0];
      my $adj_years     = $adj_tests{$k}->[1];
      my $adj_months    = $adj_tests{$k}->[2];
      my $expected_date = $adj_tests{$k}->[3];

      my $got_date = adjust_date_str ($src_date, $adj_years, $adj_months);

      dbug_cmp_ok ( $got_date, "eq", $expected_date,
                    "Test ${k}: ${src_date} + ${adj_years} year(s) + ${adj_months} month(s) = ${expected_date}" );
   }

   DBUG_RETURN (1);
}

# -----------------------------------------------

