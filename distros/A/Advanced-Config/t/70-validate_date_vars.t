#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use File::Basename;
use File::Spec;
use Sys::Hostname;
use Fred::Fish::DBUG 2.09 qw / on /;
use Fred::Fish::DBUG::Test 2.09;

# How to find the helper module ...
BEGIN { push (@INC, File::Spec->catdir (".", "t", "test-helper")); }
use helper1234;

# ---------------------------------------------------------------------
# Shows what happens when you start monkeying arround with the special
# date variables ...
# ---------------------------------------------------------------------
# Warning: Some tests will fail if this program starts before midnight
#          and finishes after midnight.  So all tests are disabled
#          starting at 11:58 PM.
# ---------------------------------------------------------------------

my $fish;

BEGIN {
   $fish = turn_fish_on_off_for_advanced_config ();

   unlink ( $fish );

   DBUG_ENTER_FUNC ();

   use_ok ("Advanced::Config");

   DBUG_VOID_RETURN ();
}


END {
   DBUG_ENTER_FUNC ();
   # Don't do any tests in the END block ...
   DBUG_VOID_RETURN ();
}

# ====================================================================
# Start of the main program!
# ====================================================================
{
   # Turn fish on ...
   DBUG_PUSH ( $fish );

   DBUG_ENTER_FUNC (@ARGV);

   dbug_ok (1, "In the MAIN program ...");  # Test # 2 ...

   my $now = time ();
   my ($hr1, $min1, $sec1) = (localtime ($now))[2,1,0];
   my ($hr2, $min2, $sec2) = (localtime ($now + 240))[2,1,0];

   # If 4 minutes in the future is tomorrow ...
   # Skip all tests so that the smoke testers won't complain!
   if ( $hr1 > $hr2 ) {
      dbug_ok (1, "Skipping all date tests.  The current time is too close to midnight!  ($hr1:$min1:$sec1, $hr2:$min2:$sec2)");
      done_testing ();
      DBUG_LEAVE (0);
   }

   my @cfgs;
   DBUG_PRINT ("====", "%s", "="x50);
   foreach my $opt ( {}, { date_sep => "/", date_order => 1 },
                         { date_sep => ".", date_order => 2, month_type => 2 },
                         { date_sep => "",  date_order => 0, month_type => 0 },
                         { date_sep => " ", date_order => 1, month_type => 1 }
                   ) {
      my $cfg = my_load_config ( 1, "70-date-validation.cfg", undef, undef, $opt );
      push (@cfgs, $cfg);
   }

   # Sourcing in files with same/different date formats for the special date vars ...
   my $cfg = my_load_config ( 1, "70-date-validation_2.cfg" );
   push (@cfgs, $cfg);

   # So I can dynamically change the date format used ...
   my $my_cb = \&ALTER_SOURCE_CALLBACK_OPTIONS;
   $cfg = my_load_config ( 0, "70-date-validation_2.cfg",
                           { source_cb => $my_cb },
                           undef, { date_sep => "~", date_order => 2, month_type => 2 } );
   push (@cfgs, $cfg);

   DBUG_PRINT ("====", "%s", "="x50);

   foreach my $cfg (@cfgs) {
      my $dopts = ($cfg->get_cfg_settings ())[2];    # The Date options ...
      dbug_ok (1, "--------- sep = '$dopts->{date_sep}' ------------------------------");

      my (%dates, %date2, $alt_date);
      print_opts_hash ( "The Date Options", $dopts );
      my $res = Advanced::Config::Options::set_special_date_vars ( $dopts, \%dates);

      # Is it the 2nd config file ???
      my $extra_tests = 0;
      if ( $cfg->filename () =~ m/_2[.]cfg$/ ) {
         my $ropts = ($cfg->get_cfg_settings ())[0];    # The Read options ...
         $extra_tests = 1;

         %date2 = %dates;
         $alt_date = \%date2;

         # Did we change the date format for the "1_" variables?
         if ( exists $ropts->{source_cb} && $ropts->{source_cb} == $my_cb ) {
            DBUG_PRINT ("SPECIAL", "Custom callback detected.  Using new date formats ...");
            my $dop = Advanced::Config::Options::get_date_opts ();
            $res = Advanced::Config::Options::set_special_date_vars ( $dop, \%dates);
         }
      }

      # Builds the hash to validate the config file against ...
      my ($total, $validate) = init_validation_hash ( \%dates, $alt_date );

      my_validation ( $cfg, $total, $validate );

      # These 2 tag's values must match if proper config file.
      if ( $extra_tests ) {
         my $tst = ( $cfg->get_value ("1_timestamp") eq $cfg->get_value ("2_timestamp") );
         dbug_ok ($tst, "Both the 1_timestamp & 2_timestamp tags have the same value!");
      }
   }

   # Since I didn't count the test cases, must end my program
   # with a call to this method.  Can't do tests in END anymore!
   done_testing ();

   DBUG_LEAVE (0);
}

# ====================================================================
sub ALTER_SOURCE_CALLBACK_OPTIONS
{
   DBUG_ENTER_FUNC (@_);
   my $file   = shift;    # The file to source in.
   my $custom = shift;    # The private work area hash.

   # Get the default options ...
   my $dop = Advanced::Config::Options::get_date_opts ();

   # Sleeping will cause failures, but was temporarily
   # needed to prove comparing 1_timestamp & 2_timestamp worked!
   # dbug_ok (1, "Sleeping for 4 seconds!");
   # sleep (4);

   DBUG_RETURN ( undef, $dop );
}

# ====================================================================
sub my_validation
{
   DBUG_ENTER_FUNC (@_);
   my $cfg      = shift;     # The config file to validate ...
   my $total    = shift;     # The number of keys in $validate.
   my $validate = shift;     # The hash to validate against ...

   my @sections = $cfg->find_sections ();
   my $cnt = @sections;
   dbug_is ($cnt, 1, "The config file doesn't define any sections!");

   my @tag_list = $cfg->find_tags ();
   $cnt = @tag_list;
   dbug_is ($cnt, $total, "Found the expected number of tags in config file ($total)");

   DBUG_PRINT ("----", "%s", "-"x50);

   $cnt = 0;
   foreach ( @tag_list ) {
      unless ( exists $validate->{$_} ) {
         dbug_ok (0, "Tag \"$_\" exists in the validation hash!");
         ++$cnt;
      }
   }
   dbug_is ($cnt, 0, "All tags were accounted for in the validation hash!");

   DBUG_PRINT ("----", "%s", "-"x50);

   foreach ( sort keys %{$validate} ) {
      my $val1 = $validate->{$_};
      my $val2 = $cfg->get_value ( $_ );
      my $val3 = (defined $val2) ? $val2 : "";
      my $chk  = (defined $val2) && $val1 eq $val2;

      # If we're unlucky, the timestamps can be dozens of seconds off ...
      my $ts   = ( $_ =~ m/^[12]_timestamp$/ ) ? 1 : 0;
      # if ($ts) { sleep(1); }

      if ( $ts && $val2 && ! $chk ) {
         my $diff = $val1 - $val3;
         $chk = 1  if ( $diff <= 120 );
         dbug_ok ( $chk, "Validating tag \"$_\" in config file is close enough.  ($val3) [Diff: $diff sec(s)]" );
      }
      else {
        dbug_ok ( $chk, "Validating tag \"$_\" matches config file.  ($val3)" );
      }

      unless ( $chk ) {
         DBUG_PRINT ("ERROR", "Value should have been: %s", $val1);
      }
   }

   DBUG_VOID_RETURN ();
}

# ====================================================================
sub my_load_config
{
   DBUG_ENTER_FUNC (@_);
   my $pause = shift;
   my $name  = shift;
   my $ropts = shift;
   my $gopts = shift;
   my $dopts = shift;

   my $file = File::Spec->catfile ("t", "config", $name);

   DBUG_PAUSE ()   if ( $pause );

   my $sep = (defined $dopts && exists $dopts->{date_sep}) ? $dopts->{date_sep} : "default";

   my $cfg;
   eval {
      $cfg = Advanced::Config->new ($file, $ropts, $gopts, $dopts);
      dbug_isa_ok ($cfg, 'Advanced::Config');
      my $ldr = $cfg->load_config ();
      dbug_ok (defined $ldr, "Advanced::Config object has been loaded into memory!  [sep: ($sep)]");
   };
   if ( $@ ) {
      unless (defined $cfg) {
         dbug_isa_ok ($cfg, 'Advanced::Config');
      }
      dbug_ok (0, "Advanced::Config object has been loaded into memory!  [sep: ($sep)]");
      DBUG_LEAVE (3);
   }

   DBUG_RETURN ( $cfg );
}

# ====================================================================
# All tags defined in the config file must be initialized below!
# The config file is: t/config/70-date-validation.cfg
#                 or: t/config/70-date-validation_2.cfg

sub init_validation_hash
{
   DBUG_ENTER_FUNC (@_);
   my $dates_1 = shift;    # A hash reference ...
   my $dates_2 = shift;    # An optional hash reference ...

   my $total = 0;
   my %vars;
   foreach ( sort keys %{$dates_1} ) {
      ++$total;
      $vars{"1_" . $_} = $dates_1->{$_};
   }

   if ( $dates_2 ) {
      foreach ( sort keys %{$dates_2} ) {
         ++$total;
         $vars{"2_" . $_} = $dates_2->{$_};
      }

      DBUG_PRINT ("DATE", "1st: %s,  2nd: %s", $vars{"1_today"}, $vars{"2_today"});
   }

   DBUG_RETURN ( $total, \%vars );
}

