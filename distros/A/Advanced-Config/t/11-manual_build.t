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

my $fish;

# This test manually builds a config file in memory
# without actully reading one in via a config file.

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

# --------------------------------------
# Start of the main program!
# --------------------------------------
{
   # Turn fish on ...
   DBUG_PUSH ( $fish );

   DBUG_ENTER_FUNC (@ARGV);

   dbug_ok (1, "In the MAIN program ...");  # Test # 2 ...

   my $cfg = Advanced::Config->new();
   dbug_isa_ok ( $cfg, 'Advanced::Config' );

   # Create a separate section ...
   my $sn = "help";
   # my $sect = $cfg->get_section ( Advanced::Config::Reader::make_new_section ($cfg, $sn) );
   my $sect = $cfg->create_section ($sn);
   dbug_isa_ok ( $sect, 'Advanced::Config' );
   DBUG_PRINT ("FIND", "="x80);

   # Manually create some entries into the object ...
   $cfg->set_value ("main_tag_1", "Hello World!");
   $cfg->set_value ("main_tag_2", "Hello my old friend!");
   $cfg->get_section ()->set_value ("main_tag_3", "Hello my new friend!");
   $cfg->set_value ("main_tag_pwd", "It's a secret!");
   DBUG_PRINT ("FIND", "="x80);

   # Manually create some entries in the section ...
   $sect->set_value ("help_tag_1", "Help Me!");
   $cfg->get_section ($sn)->set_value ("help_tag_2", "Help You!");
   $sect->set_value ("main_tag_1", "What's up Doc?");

   # Putting in the main section again.
   $cfg->set_value ("help_tag_1", "I thought I saw a pussy cat!");

   DBUG_PRINT ("FIND", "="x80);

   my $jcfg = $cfg->create_section ("jinx pwd");
   my $v1 = "Just another secret.";
   $jcfg->set_value ("Hide It", $v1);
   my $v2 = $jcfg->get_value ("Hide It");
   dbug_is ( $v1, $v2, "Hide It tags match! ($v1)" );
   DBUG_PRINT ("FIND", "="x80);

   # Now let's see what's in the object ...
   # Uses 2 different ways per section.
   my @lst1 = $cfg->find_tags ();                    # Main section
   my @lst2 = $cfg->get_section ()->find_tags ();    # Main section
   my @lst3 = $sect->find_tags ();                   # Help Section
   my @lst4 = $cfg->get_section ($sn)->find_tags (); # Help Section

   my $cnt1 = @lst1;
   my $cnt2 = @lst2;
   my $cnt3 = @lst3;
   my $cnt4 = @lst4;

   my (%main, %help);   # Used to predict inherited test results.

   dbug_is ($cnt1, $cnt2, "Both main lists contain ${cnt1} entries.");
   foreach (0..($cnt1-1)) {
      my $v1 = $cfg->get_value ($lst1[$_]);
      my $v2 = $cfg->get_section ()->get_value ($lst2[$_]);
      dbug_ok ($lst1[$_] eq $lst2[$_] && $v1 eq $v2, "$lst1[$_] is in both lists with a value of \"$v1\"!");
      $main{$lst1[$_]} = $v1;
   }

   dbug_is ( $cnt3, $cnt4, "Both section lists contain ${cnt3} entries.");
   foreach (0..($cnt3-1)) {
      my $v3 = $sect->get_value ($lst3[$_]);
      my $v4 = $cfg->get_section ($sn)->get_value ($lst4[$_]);
      dbug_ok ($lst3[$_] eq $lst4[$_] && $v3 eq $v4, "$lst3[$_] is in both lists with a value of \"$v3\"!");
      $help{$lst3[$_]} = $v3;
   }

   # Lets do an "inheritence" test ...
   my (@lst5, %both);
   foreach ( @lst1, @lst3 )    { $both{$_} += 1; }
   foreach ( sort keys %both ) { push ( @lst5, $_ ); }

   my @lst6 = $sect->find_tags (undef, 1);
   my $cnt5 = @lst5;
   my $cnt6 = @lst5;

   dbug_is ( $cnt5, $cnt6, "Both inherited section lists contain ${cnt5} entries.");
   foreach (0..($cnt5-1)) {
      my $t = $lst5[$_];
      my $v5 = $sect->get_value ($lst5[$_], inherit => 1);
      my $v6 = (exists $help{$t}) ? $help{$t} : $main{$t};
      dbug_ok ($lst5[$_] eq $lst6[$_] && $v5 eq $v6, "$lst5[$_] is in both inherited lists with a value of \"$v5\"!");
   }

   # So we know we are done with the testing ...
   done_testing ();

   DBUG_LEAVE (0);
}

# ====================================================================

