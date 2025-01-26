#!/usr/bin/perl

use strict;
use warnings;

use Config;
use Config qw(config_sh);

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

# This program tests the parsing of strings as config files.
# Uses Perl's Config class to test things out since it already
# does this.

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

   my $miss = find_missing_entries ();

   my $cfg = init_config ();

   test_results ($cfg, $miss);

   # Section "fix" ...
   my $sect = "[ fix ]\n" . config_sh ();
   my $res = $cfg->merge_string ( $sect );
   dbug_ok ( $res, "The 'fix' string merge worked!");
   my $sCfg = $cfg->get_section ( "fix" );
   dbug_ok ( ref($sCfg) eq "Advanced::Config", "Section 'fix' exists!");

   # Section "break" ...
   $sect = "[ break ]\n" . config_sh ();
   $res = $cfg->merge_string ( $sect );
   dbug_ok ( $res, "The 'break' string merge worked!");
   my $bCfg = $cfg->get_section ( "break" );
   dbug_ok ( ref($bCfg) eq "Advanced::Config", "Section 'break' exists!");

   # Modifying to prove modifying the string doesn't break refresh_config()!
   $sect =~ s/ break / broken /;
   dbug_ok (1, "Break changed to: " . substr ($sect,0,10));

   test_results ($cfg, $miss);
   test_results ($sCfg, $miss);
   test_results ($bCfg, $miss);

   DBUG_PRINT ("====", "%s", "="x50);
   $res = $cfg->refresh_config ();
   dbug_ok (! $res, "Refresh was skipped over.");

   $res = $cfg->refresh_config ( "force" => 1 );
   dbug_ok ($res, "Refresh was forced!");

   $sCfg = $cfg->get_section ( "fix" );
   dbug_ok ( ref($sCfg) eq "Advanced::Config", "Section 'fix' exists!");
   $bCfg = $cfg->get_section ( "break" );
   dbug_ok ( ref($bCfg) eq "Advanced::Config", "Section 'break' exists!");

   test_results ($cfg, $miss);
   test_results ($sCfg, $miss);
   test_results ($bCfg, $miss);

   # ----------------------------------------------------------
   # Now lets test encrypting then decrypting a string ...
   # ----------------------------------------------------------
   dbug_ok ( 1, "-"x50 );
   $sect = "section";
   my $original = "abc = 'Help me!'  # ENCRYPT you\n"
                . "xyz = 'No way!'  # ENCRYPT me\n"
                . "[${sect}]\n"
                . "lmn = 'no one'  # ENCRYPT us\n"
                . "no = never encrypt!\n"
                ;
   my $alias = "STRING-IS-A-GO-go!";

   # Defere the dbug_ok() calls until after they've been loaded!
   my $str1 = $cfg->encrypt_string ($original, $alias);
   my $str2 = $cfg->decrypt_string ($str1, $alias);

   # ----------------------------------------------------------
   # Now some more detailed comparisons of the results ...
   # ----------------------------------------------------------
   my $xCfg1 = init_config ( $original );
   my $xCfg2 = init_config ( $str1, $alias );   # Decryption works ...
   my $xCfg3 = init_config ( $str1 );           # Decryption fails ...
   my $xCfg4 = init_config ( $str2 );

   dbug_ok ((defined $str1 && $str1 ne $original), "Encrypting a string looks good!");
   dbug_ok ((defined $str2 && $str2 ne $str1), "Decrypting a string looks good!");

   my $sxCfg1 = $xCfg1->get_section ($sect);
   my $sxCfg2 = $xCfg2->get_section ($sect);
   my $sxCfg3 = $xCfg3->get_section ($sect);
   my $sxCfg4 = $xCfg4->get_section ($sect);
   dbug_ok ( defined $sxCfg1, "Section exists" );
   dbug_ok ( defined $sxCfg2, "Section exists" );
   dbug_ok ( defined $sxCfg3, "Section exists" );
   dbug_ok ( defined $sxCfg4, "Section exists" );

   # This is a lousy test ... Remove & update $original when detailed test available!
   dbug_cmp_ok ( $str2, 'eq', $original, "Encrypting then decrypting produced the correct string!" );

   dbug_ok ( test_obj ($xCfg1, $xCfg2, [ "abc", "xyz" ], [] ), "Compares main OK" );
   dbug_ok ( test_obj ($sxCfg1, $sxCfg2, [ "lmn", "no" ], [] ),  "Compares section OK" );

   dbug_ok ( test_obj ($xCfg1, $xCfg3, [], [ "abc", "xyz" ] ), "Decrypts main Failed as expected" );
   dbug_ok ( test_obj ($sxCfg1, $sxCfg3, [ "no" ], [ "lmn" ] ),  "Decrypts section Failed as expected" );

   dbug_ok ( test_obj ($xCfg1, $xCfg4, [ "abc", "xyz" ], [] ), "Decrypts main OK" );
   dbug_ok ( test_obj ($sxCfg1, $sxCfg4, [ "lmn", "no" ], [] ),  "Decrypts section OK" );

   # ----------------------------------------------------------
   # Does the toString () test cases ...
   # ----------------------------------------------------------
   dbug_ok ( 1, "-"x50 );

   # Makes sure having comments in a tag's value doesn't cause us problems!
   $xCfg1->set_value ("cmt1", '### Comments ###');
   $xCfg1->set_value ("cmt2", '### "Comments" ###');
   $xCfg1->set_value ("cmt3", "### 'Comments' ###");
   $xCfg1->set_value ("cmt4", "### 'Comments" . '" ###');

   my $str = $xCfg1->toString ();

   my $zCfg1 = init_config ( $str );

   my $szCfg1 = $zCfg1->get_section ($sect);
   dbug_ok ( defined $szCfg1, "Section exists" );

   dbug_ok ( defined $str, "toString() returned something!" );

   dbug_ok ( test_obj ($xCfg1, $zCfg1,  [ "abc", "xyz", "cmt1", "cmt2", "cmt3", "cmt4" ], [] ), "Compares main OK" );
   dbug_ok ( test_obj ($sxCfg1, $szCfg1, [ "lmn", "no" ], [] ),  "Compares section OK" );

   # Mark all tags to be encrypted ...
   $str = $xCfg1->toString (1);
   dbug_ok ( defined $str, "toString(1) returned something!" );
   $str2 = $xCfg1->encrypt_string ($str, $alias);
   dbug_ok ( defined $str2, "encrypt_string() returned something!" );

   my $flag = (defined $str && defined $str2) && $str ne $str2;
   dbug_ok ( $flag, "The toString(1) results have been encrypted!");

   my $zCfg2 = init_config ( $str2 );
   my $szCfg2 = $zCfg2->get_section ($sect);
   dbug_ok ( defined $szCfg2, "Section exists" );

   my $zCfg3 = init_config ( $str2, $alias );
   my $szCfg3 = $zCfg3->get_section ($sect);
   dbug_ok ( defined $szCfg3, "Section exists" );

   dbug_ok ( test_obj ($xCfg1, $zCfg2,  [], [ "abc", "xyz", "cmt1", "cmt2", "cmt3", "cmt4" ] ), "Decrypts main Failed as expected" );
   dbug_ok ( test_obj ($sxCfg1, $szCfg2, [], [ "lmn", "no" ] ),  "Decrypts section Failed as expected" );

   dbug_ok ( test_obj ($xCfg1, $zCfg3,  [ "abc", "xyz", "cmt1", "cmt2", "cmt3", "cmt4" ], [] ), "Decrypts main OK" );
   dbug_ok ( test_obj ($sxCfg1, $szCfg3, [ "lmn", "no" ], [] ),  "Decrypts section OK" );

   # ----------------------------------------------------------
   # Does the toString () test using alternate symbols ...
   # ----------------------------------------------------------
   dbug_ok ( 1, "-"x50 );
   $xCfg1->set_value ("cmt1", '//// Comments ///');
   $xCfg1->set_value ("cmt2", '//// "Comments" ///');
   $xCfg1->set_value ("cmt3", "//// 'Comments' ///");
   $xCfg1->set_value ("cmt4", "//// 'Comments" . '" ///');

   $str = $xCfg1->toString (1, "comment" => "//", "assign" => ":=:", "encrypt_lbl" => "Some Comments ...");
   dbug_ok ( defined $str, "toString(2) returned something!" );

   my $zCfg5 = init_config ( $str, $alias, 1);
   my $szCfg5 = $zCfg5->get_section ($sect);
   dbug_ok ( defined $szCfg5, "Section exists" );

   dbug_ok ( test_obj ($xCfg1, $zCfg5,  [ "abc", "xyz", "cmt1", "cmt2", "cmt3", "cmt4" ], [] ), "Compares alternate main OK" );
   dbug_ok ( test_obj ($sxCfg1, $szCfg5, [ "lmn", "no" ], [] ),  "Compares alternate section OK" );

   # Since I didn't count the test cases, must end my program
   # with a call to this method.  Can't do tests in END anymore!
   done_testing ();

   DBUG_LEAVE (0);
}


# --------------------------------------------------
# Compares two Advanced::Config objects ...
# --------------------------------------------------
sub test_obj
{
   DBUG_ENTER_FUNC ( @_ );
   my $src  = shift;
   my $dst  = shift;
   my $good = shift;   # Array of tags that should match
   my $bad  = shift;   # Array of tags that shouldn't match

   unless ( defined $src && defined $dst ) {
      return DBUG_RETURN (0);
   }

   DBUG_PAUSE ();

   # It's a fatal error if any tag in the "good" array doesn't exist!
   my $ok = 1;
   foreach ( @{$good} ) {
      my $s = $src->get_value ($_);
      my $d = $dst->get_value ($_);
      if ( $s ne $d ) {
         $ok = 0;
         dbug_ok (0, "Tags $_ doesn't match!  (${s} vs ${d})");
      }
   }

   # It's a fatal error if any tag in the "bad" array doesn't exist!
   foreach ( @{$bad} ) {
      my $s = $src->get_value ($_);
      my $d = $dst->get_value ($_);
      if ( $s eq $d ) {
         $ok = 0;
         dbug_ok (0, "Tags $_ match when they shouldn't!  (${s})");
      }
   }

   DBUG_RETURN ( $ok );
}

# ====================================================================
# Tests the results.
# Only prints out failures when testing the contents.
# There are just too many tests otherwise to debug things!
# ====================================================================
sub test_results
{
   DBUG_ENTER_FUNC ( @_ );
   my $cfg = shift;
   my $mis = shift;   # The list of tags not in the string config.

   my @lst1 = sort keys %Config;
   my @lst2 = sort $cfg->find_tags ();

   my $cnt1 = @lst1;
   my $cnt2 = @lst2;

   # Convert the "string" config file into a hash to simplify testing ...
   my %val2;
   foreach ( @lst2 ) {
      my $val = $cfg->get_value ( $_ );
      $val2{$_} = $val;
   }

   # Now add in the missing entries ... (no overrides)
   foreach ( sort keys %{$mis} ) {
      next  if ( exists $val2{$_} );
      $val2{$_} = $mis->{$_};
      ++$cnt2;
   }

   dbug_is ($cnt1, $cnt2, "The object has the correct number of tags in it!  ($cnt1 vs $cnt2)");

   # Checks to see if there were any tags in the string that wasn't in %Config.
   foreach ( @lst2 ) {
      unless ( exists $Config{$_} ) {
         dbug_ok (0, "Found tag $_ in the %Config hash!");
      }
   }

   # Only prints out errors.  Otherwise over 1,000 tests printed out.
   foreach ( @lst1 ) {
      unless ( exists $val2{$_} ) {
         dbug_ok ( 0, "Tag $_ exists in the string config file!");
         next;
      }

      # Some Config values are undefined ...
      unless ( defined $Config{$_} ) {
         if ( $val2{$_} ne "undef" ) {
            dbug_ok ( 0, "Tag $_ is set to 'undef'.  ($val2{$_})");
         }
         next;
      }

      if ( $Config{$_} ne $val2{$_} ) {
         dbug_ok ( 0, "Tag $_ is set to the proper value ($Config{$_} vs $val2{$_})" );
         next;
      }
   }

   DBUG_VOID_RETURN ();
}

# ====================================================================
# Determines which keys in the %Config hash are not in the string!
sub find_missing_entries
{
   DBUG_ENTER_FUNC ( @_ );

   # Get a complete list of what's in the Config string returned.
   my $str = config_sh ();
   my @lst = split ("\n", $str);

   # Build a hash out of the string ... (tag='value')
   my %found;
   foreach (@lst) {
      my ($tag, $value) = split ("=", $_, 2);
      $value = $1  if ( $value =~ m/^'(.*)'$/ );
      $found{$tag} = $value;   # Without quotes!
   }

   # Now determine which are missing from the string ...
   my $cnt = 0;
   my %missing;
   foreach ( sort keys %Config ) {
      next  if ( exists $found{$_} );
      $missing{$_} = (defined $Config{$_}) ? $Config{$_} : "undef"; 
      DBUG_PRINT ("MISSING", "Found missing tag: %s\n<%s>", $_, $missing{$_});
      ++$cnt;
   }

   dbug_ok ( 1, "There were $cnt missing entries in the Config String.");

   DBUG_RETURN ( \%missing );
}

# ====================================================================
sub init_config
{
   DBUG_ENTER_FUNC ( @_ );
   my $in_string = shift || config_sh ();
   my $alias     = shift;
   my $extra     = shift;

   my $cfg;
   my ( %rOpts, %gOpts, %dOpts );

   $rOpts{Croak} = 1;      # Call die on error.
   $gOpts{Required} = 1;   # Call die if the tag doesn't exist.

   # Did we ask to change some defauls?
   if ( $extra ) {
      $rOpts{Comment} = "//";
      $rOpts{Assign} = ":=:";

      # Commented out on purpose ...
      # $rOpts{encrypt_lbl} = "Some Comments ...";
   }

   # Did we override the read options to use with the string?
   my %oOpts;
   $oOpts{alias} = $alias   if ( $alias );

   eval {
      $cfg = Advanced::Config->new (undef, \%rOpts, \%gOpts, \%dOpts);
      dbug_isa_ok ($cfg, 'Advanced::Config');
      my $ldr = $cfg->load_string ( $in_string, \%oOpts );
      dbug_ok (defined $ldr, "Advanced::Config contents have been loaded into memory!");
   };
   if ( $@ ) {
      unless (defined $cfg) {
         dbug_isa_ok ($cfg, 'Advanced::Config');
      }
      dbug_ok (0, "Advanced::Config contents have been loaded into memory!");
      DBUG_LEAVE (3);
   }

   # So can tell when the config files were loaded in fish ...
   DBUG_PRINT ("====", "%s", "-"x50);

   DBUG_RETURN ( $cfg );
}

