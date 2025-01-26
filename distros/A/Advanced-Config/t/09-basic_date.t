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

