#!/usr/bin/perl

# -----------------------------------------------------
# This test does a full test of the disable_decryption option.
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
   my $file = File::Spec->catfile ("t", "config", "27-disable_decrypt_test.cfg");
   my $cfg2 = make_object ( $file, disable_decryption => 0 );
   my $cfg3 = make_object ( $file, disable_variables  => 1 );

   # Turn fish on ...
   DBUG_PUSH ( $fish );

   DBUG_ENTER_FUNC (@ARGV);

   dbug_ok (1, "In the MAIN program ...");  # Test # 2 ...

   my $cfg1 = make_object ( $file, disable_decryption => 1 );

   # Normal variable expansion ...
   test_tag ($cfg2, "test0", 0, 0, 1);
   test_tag ($cfg2, "test1", 0, 0, 0);
   test_tag ($cfg2, "test2", 0, 0, 1);
   test_tag ($cfg2, "test3", 0, 0, 1);
   test_tag ($cfg2, "test4", 0, 0, 1);
   test_tag ($cfg2, "test5", 0, 0, 1);    # The problem test ...
   test_tag ($cfg2, "test6", 0, 0, 1);
   test_tag ($cfg2, "test7", 0, 0, 1);

   test_tag ($cfg2, "test999", 0, 0, 1);

   dbug_ok (1, "===========================================");

   # Disabled decrypion expansion ...
   test_tag ($cfg1, "test0", 0, 1, 1);    # An encrypted value.
   test_tag ($cfg1, "test1", 0, 0, 0);
   test_tag ($cfg1, "test2", 0, 1, 1);    # An encrypted value.
   test_tag ($cfg1, "test3", 1, 0, 1);
   test_tag ($cfg1, "test4", 1, 0, 1);
   test_tag ($cfg1, "test5", 0, 0, 1);    # The problem test ...
   test_tag ($cfg1, "test6", 1, 0, 1);
   test_tag ($cfg1, "test7", 1, 0, 1);

   my $lbl = "test999";
   my $val = test_tag ($cfg1, $lbl, 1, 0, 1);
   my @parts = split (qr/\$[{]/, $val);
   # foreach ( @parts ) { print STDERR "----> $_\n"; }
   my $cnt = @parts;   --$cnt;
   my $total_vars = 6;
   dbug_is ($total_vars, $cnt, "Tag ${lbl} has ${cnt} variables in it! (Expect ${total_vars})");

   dbug_ok (1, "===========================================");

   $val = test_tag ($cfg3, $lbl, 1, 0, 0);
   @parts = split (qr/\$[{]/, $val);
   $cnt = @parts;   --$cnt;
   $total_vars = 13;
   dbug_is ($cnt, $total_vars, "Tag ${lbl} has ${cnt} variables in it! (Expect ${total_vars})");

   done_testing ();

   DBUG_LEAVE (0);
}


sub test_tag
{
   DBUG_ENTER_FUNC ( @_ );
   my $cfg    = shift;
   my $tag    = shift;
   my $var    = shift;
   my $decrpt = shift;
   my $sens   = shift;

   my $val = $cfg->get_value ($tag);

   my $sens_flg = $cfg->chk_if_sensitive ($tag);
   my $var_flg  = $cfg->chk_if_still_uses_variables ($tag);
   my $d_flg    = $cfg->chk_if_still_encrypted ($tag);

   dbug_ok ( 1, "------------------------------------------------------");
   dbug_ok ( 1, "Tag: $tag,  value is: $val" );
   dbug_cmp_ok ( $var_flg, '==', $var,   "Correct Variable Setting for Tag: $tag (Expected: $var,  Found: $var_flg)" );
   dbug_cmp_ok ( $d_flg, '==', $decrpt,  "Correct Encryption Setting for Tag: $tag (Expected: $decrpt,  Found: $d_flg)" );
   dbug_cmp_ok ( $sens_flg, '==', $sens, "Correct Sensitivity for Tag: $tag (Expected: $sens,  Found: $sens_flg)" );

   DBUG_RETURN ( $val );
}

sub make_object
{
   DBUG_ENTER_FUNC ( @_ );
   my $file  = shift;
   my %rOpts = @_;

   my $cfg;
   eval {
      $cfg = Advanced::Config->new ( $file, \%rOpts, { required => 1 } );
      dbug_isa_ok ($cfg, 'Advanced::Config');
      my $ldr = $cfg->load_config ();
      dbug_ok (defined $ldr, "Advanced::Config object has been loaded into memory!");
   };
   if ( $@ ) {
      unless (defined $cfg) {
         dbug_isa_ok ($cfg, 'Advanced::Config');
      }
      dbug_ok (0, "Advanced::Config object has been loaded into memory!");
      DBUG_LEAVE (3);
   }

   # So can tell when the config file finished loading in fish ...
   DBUG_PRINT ("====", "%s", "="x50);

   DBUG_RETURN ( $cfg );
}

