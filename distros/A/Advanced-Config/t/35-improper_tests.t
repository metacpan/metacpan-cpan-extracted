#!/usr/bin/perl

# -----------------------------------------------------
# This test case tells what happens if you don't
# call load_config() & instead calls merge_config.
#
# Otherwise it's a repeat of: t/28-sensitive_tests.t
# -----------------------------------------------------

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

   # Make this extra pattern sensitive!
   Advanced::Config::Options::make_it_sensitive ("1111", "zork", "22222");

   my $file = File::Spec->catfile ("t", "config", "28-sensitive.cfg");
   my $cfg0 = make_object ( $file, "croak" => 1 );
   my $cfg1 = make_object ( $file );
   my $cfg2 = make_object ( $file, "disable_variables" => 1 );
   my $cfg3 = make_object ( $file, "disable_decryption" => 1 );
   my $cfg9 = make_object ( $file, "croak" => 1 );

   eval {
      my $r0 = $cfg0->refresh_config ( "force" => 1 );
      dbug_ok (0, "Refresh Failed!  ($r0)");
   };
   if ($@) {
      dbug_ok (1, "Refresh Failed!");
   }
   DBUG_PRINT ("????", "?"x40);
   my $r1 = $cfg1->refresh_config ( "force" => 1 );
   DBUG_PRINT ("????", "?"x40);
   my $r2 = $cfg2->refresh_config ( "force" => 1 );
   DBUG_PRINT ("????", "?"x40);
   my $r3 = $cfg3->refresh_config ( "force" => 1 );
   DBUG_PRINT ("????", "?"x40);
   dbug_ok ( ! $r1, "Refresh #1 Failed!");
   dbug_ok ( ! $r2, "Refresh #2 Failed!");
   dbug_ok ( ! $r3, "Refresh #3 Failed!");

   # Doesn't work after the config files are loaded ..
   # If you change before the refresh it then say's "pork" is sensitive!
   Advanced::Config::Options::make_it_sensitive ("pork");

   # Verify that the refresh detects the change and dies!
   eval {
      my $r9 = $cfg9->refresh_config ();
      dbug_ok (0, "Refresh Failed on 'pork'!  ($r9)");
   };
   if ($@) {
      dbug_ok (1, "Refresh Failed on 'pork'!");
   }
   DBUG_PRINT ("????", "?"x40);

   my @sections = $cfg1->find_sections ();
   my $cnt = @sections;
   dbug_is ($cnt, 3, "All 3 sections were accounted for!");

   my @tag_list = $cfg1->find_tags ();
   $cnt = @tag_list;

   foreach my $s ( @sections ) {
      dbug_ok (1, "-"x50);
      my $lCfg = $cfg1->get_section ( $s );
      my @tags = $lCfg->find_tags ();
      my $tlt = @tags;

      my $sens = Advanced::Config::Options::should_we_hide_sensitive_data ( $s );
      if ( $sens ) {
         dbug_ok ( 1, "Processing sensitive section '$s'.");
      } else {
         dbug_ok ( 1, "Processing normal section '$s'.");
      }
      dbug_is ( $tlt, $cnt, "Found ${cnt} tags in this section.");

      foreach my $t (@tags) {
         my $ans = $sens || ( $t =~ m/_y$/i ) ? 1 : 0;
         my $chk = $lCfg->chk_if_sensitive ( $t );
         my $v = $lCfg->get_value ($t);

         if ( $ans ) {
            dbug_is ( $chk, 1, "Tag '$t' is considered sensitive!  ($v)" );
         } else {
            dbug_is ( $chk, 0, "Tag '$t' is NOT considered sensitive!  ($v)" );
         }
      }
      last;   # So only reports on the 1st section ... (so don't have to modify much code)
   }

   # --------------------------------------------------------------
   # Section # 2: Now testing which tags have unexpanded variables ...
   # --------------------------------------------------------------
   foreach my $s ( @sections ) {
      dbug_ok (1, "-"x50);
      my $lCfg = $cfg2->get_section ( $s );
      dbug_ok (1, "Disabled Variable test for section: " . $s);
      my $hash_ref2 = $cfg2->get_hash_values ( "00_has_variables" );

      foreach my $t ( $lCfg->find_tags () ) {
         my $v = $lCfg->get_value ($t);
         my $bool = $lCfg->chk_if_still_uses_variables ($t);
         my $ans = ( $v =~ m/[$][{][^}]+[}]/ ) ? 1 : 0;  # Check for a variable definition.
         my $agree = ($bool == $ans) ? 1 : 0;

         if ( exists $hash_ref2->{$t} ) {
            dbug_ok ( $agree && $bool, "Tag '$t' has unresolved variables in it!  ($v)" );
         } elsif ( $ans || $bool ) {
            dbug_ok ( 0, "Tag '$t' has NO variables in it!  ($v)  [$ans, $bool]" );
         }
      }
   }

   # --------------------------------------------------------------
   # Section # 3: Now testing which tags failed to decrypt!
   # --------------------------------------------------------------
   foreach my $s ( @sections ) {
      dbug_ok (1, "-"x50);
      my $lCfg = $cfg3->get_section ( $s );
      dbug_ok (1, "Disabled Decryption test for section: " . $s);
      my $hash_ref3 = $cfg3->get_hash_values ( "00_has_decryption" );

      foreach my $t ( $lCfg->find_tags () ) {
         my $v = $lCfg->get_value ($t);
         my $chk = $lCfg->chk_if_still_encrypted ($t);

         my $bool = $lCfg->chk_if_still_uses_variables ($t);
         my $ans = ( $v =~ m/[$][{][^}]+[}]/ ) ? 1 : 0;  # Check for a variable definition.
         my $agree = ($bool == $ans) ? 1 : 0;

         if ( exists $hash_ref3->{$t} ) {
            if ( $bool || $ans ) {
               dbug_ok ( 0, "Tag '$t' references an encrypted value ($v)" );
            } else {
               dbug_ok ( $chk, "Tag '$t' references an encrypted value ($v)" );
            }
         } elsif ( $chk ) {
            dbug_ok ( 0, "Tag '$t' is correctly marked as encrypted ($v)" );
         }
      }
   }

   # Since I didn't count the test cases, must end my program
   # with a call to this method.  Can't do tests in END anymore!
   done_testing ();

   DBUG_LEAVE (0);
}

sub make_object
{
   DBUG_ENTER_FUNC ( @_ );
   my $file  = shift;
   my %rOpts = @_;

   my $cfg;
   eval {
      $cfg = Advanced::Config->new ( undef, \%rOpts, { required => 1 } );
      dbug_isa_ok ($cfg, 'Advanced::Config');
      my $ldr = $cfg->merge_config ( $file );
      dbug_ok (defined $ldr, "Advanced::Config object has been loaded into memory via merge!");
   };
   if ( $@ ) {
      unless (defined $cfg) {
         dbug_isa_ok ($cfg, 'Advanced::Config');
      }
      dbug_ok (0, "Advanced::Config object has been loaded into memory via merge!");
      DBUG_LEAVE (3);
   }

   # So can tell when the config file finished loading in fish ...
   DBUG_PRINT ("====", "%s", "="x50);

   DBUG_RETURN ( $cfg );
}

