#!/usr/bin/perl

# This test program assumes that "t/config/10-simple.cfg" is 100% valid!
# And that each config file you compare against is an equivalant config file
# to this one.
 
# This program compares other config files against this one with different
# "Read Options" selected to verify that these other config files parse
# correctly.  So if any test cases fail, either the config file is bad or
# there is a bug in this module!

# Rather than modify this program each and every time I want to add a new config
# file to compare against, I use "t/config/30-alt_symbol_control.cfg" as a
# control file that tells how each of the config files it compares against is
# configured.  Done this way so I may use any of the "Read Options" I wish
# in setting up a new config file to test against.

# See the comments in this control config file for more details.

# This serves two purposes.  Ease of adding additional config files to test
# against.  As well as testing out this module.

# ------------------------------------------------------------------------------

# NOTE: To skip the 'shft3' warnings, add SKIP as an option to this script!
#       It's automatically skipped during "make test".

# ------------------------------------------------------------------------------

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

# For overriding the fish mask in parse_line ().
my $oTag = "DBUG_TEST_USE_CASE_PARSE_OVERRIDE";

BEGIN {
   $fish = turn_fish_on_off_for_advanced_config ();

   unlink ( $fish );

   DBUG_ENTER_FUNC ();

   # Always make it look like it's running via "make test"!
   $ENV{PERL_DL_NONLAZY} = 1;

   use_ok ("Advanced::Config");
   use_ok ("Advanced::Config::Options");

   DBUG_VOID_RETURN ();
}


END {
   DBUG_ENTER_FUNC ();
   # Don't do any tests in the END block ...
   DBUG_VOID_RETURN ();
}

# --------------------------------------
# Global Variables
# --------------------------------------
my $control_cfg;
my $default_ropts = Advanced::Config::Options::get_read_opts();
my $default_dopts = Advanced::Config::Options::get_date_opts();

# --------------------------------------
# Start of the main program!
# --------------------------------------
{
   # Turn fish on ...
   DBUG_PUSH ( $fish );

   DBUG_ENTER_FUNC (@ARGV);

   dbug_ok (1, "In the MAIN program ...");  # Test # 2 ...

   my %comment_tags = ( "cmt" => 1, "cmt2" => 1, "cmt3" => 1 );

   my $main_cfg = initialize_config ( "10-simple.cfg" );
   DBUG_PRINT ("====", "%s", "="x50);

   $control_cfg = initialize_config ( "30-alt_symbol_control.cfg" );
   DBUG_PRINT ("====", "%s", "="x50);

   my $total = $control_cfg->get_value ("number_test_files");
   dbug_like ($total, qr/^\d+$/, "Has a numeric value!");

   my @sections = $control_cfg->find_sections ('[.]cfg$');
   my $cnt = @sections;
   dbug_is ( $cnt, $total, "Found the correct number of config files to work with.  ($cnt vs $total)");

   foreach my $c ( sort @sections ) {
      dbug_ok (1, "-"x50);
      my ($cfg, @stags) = initialize_each_config ( $control_cfg, $c );

      next  unless ( defined $cfg );

      dbug_ok ($cfg->refresh_config (test_only=>1) ? 0 : 1,
           "No refresh needed for the config file: " . basename ($cfg->filename()));

      foreach my $r ( 0, 1, 2 ) {
         if ( $cfg->refresh_config (force => $r) ) {
            dbug_ok ($r, "This refresh was expeced!");
            fix_space_sep_issue ( $cfg );
         } else {
            dbug_ok (! $r, "Skipping the refresh was expeced!");
         }

         # Finish loading the special case tests # 71 & 72
         # so that they can emulate test # 70 ...
         if ( $c =~ m/_71_empty/ ) {
            local_merge_files ( $control_cfg, $cfg, 0 );
         } elsif ( $c =~ m/_72_empty/ ) {
            local_merge_files ( $control_cfg, $cfg, 1 );
         }

         if ( $#stags == -1 ) {
            # Do a compare against the main section only ...
            compare_config_files ( $main_cfg, $cfg, \%comment_tags );

         } else {
            # Do a compare against the specified section(s) in the new file ...
            $cnt = 0;
            foreach my $t ( sort @stags ) {
               dbug_ok (1, "="x50)  if ( $cnt > 0);
               ++$cnt;

               # Are we looking in another section?
               my $mode = ( $t =~ m/[.]/ ) ? 0 : 2;

               # Look up the name of the section to use ...
               my $sct = $cfg->get_value ($t, required => $mode);
               $sct = $cfg->rule_3_section_lookup ($t)  unless ($sct);
               $sct = $cfg->get_value ($t)  unless ($sct);

               compare_config_files ( $main_cfg, $cfg, \%comment_tags, $sct );
            }
         }
      }   # End foreach $r ...
   }      # End foreach $c ...

   dbug_ok (1, "-"x50);

   # Since I didn't count the test cases, must end my program
   # with a call to this method.  Can't do tests in END anymore!
   done_testing ();

   DBUG_LEAVE (0);
}

# ====================================================================
# This is the source_cb callback function named in: 30-alt_symbol_control.cfg
# All it does is lookup the options to use from the
# appropriate section in the conig file.  (global var)
sub ALTER_SOURCE_CALLBACK_OPTIONS
{
   DBUG_ENTER_FUNC (@_);
   my $file   = shift;
   my $custom = shift;

   my $f = basename ($file);

   DBUG_ENTER_BLOCK ("GRAB");
   DBUG_PAUSE();
   my ($ropts, $dopts, @section_tags) = grab_options ( $control_cfg, $f );
   DBUG_VOID_RETURN ();

   $ropts = print_opts_hash ( "Read Options for: $f", $ropts );
   $dopts = print_opts_hash ( "Date Options for: $f", $dopts );

   DBUG_RETURN ( $ropts, $dopts ); 
}

# ====================================================================
sub compare_config_files
{
   DBUG_ENTER_FUNC (@_);
   my $src_cfg  = shift;    # The original validated config file to compare against.
   my $dst_cfg  = shift;    # The new config file to validate.
   my $cmts     = shift;    # The tags with comment chars in their values!
   my $sect     = shift;    # The section to change to.

   my ( $cnt1, $cnt2 );

   my @sections = $dst_cfg->find_sections ();
   $cnt1 = @sections;
   dbug_cmp_ok ($cnt1, '>', 0, "The config file has ${cnt1} section(s)!");

   if ( $sect ) {
      $dst_cfg = $dst_cfg->get_section ( $sect );
      dbug_ok (defined $dst_cfg, "Validating against section \"${sect}\" in the config file ...");
      return DBUG_VOID_RETURN ()  unless ( defined $dst_cfg );
   } else {
      dbug_ok (1, "Validating the config file ...");
   }

   my @src_list = $src_cfg->find_tags ();
   my @dst_list = $dst_cfg->find_tags ();
   $cnt1 = @src_list;
   $cnt2 = @dst_list;
   if ( $sect ) {
      dbug_is ( $cnt1, $cnt2, "The source config file & section '$sect' have the same number of tags in them.  ($cnt1 vs $cnt2)");
   } else {
      dbug_is ( $cnt1, $cnt2, "Both config files have the same number of tags in them.  ($cnt1 vs $cnt2)");
   }

   my %list;
   foreach my $tg ( @src_list ) {
      $list{$tg} = 1;
      my $src = $src_cfg->get_value ( $tg );
      my $dst = $dst_cfg->get_value ( $tg );
      my $same = ( $src eq $dst ) ? 1 : 0;
      if ( $cmts->{$tg} ) {
         dbug_ok ( 1, "Tag '$tg' in both files may have different comment values!");
      } else {
         dbug_ok ( $same, "Tag '$tg' in both files have the same value!");
      }
      unless ( $same ) {
         DBUG_PRINT ("DIFF", "%s <-vs-> %s", $src, $dst);
      }
   }

   # Should never find anything!
   foreach ( @dst_list ) {
      next  if ( $list{$_} );
      dbug_ok (0, "Found unexpected tag '$_' in new config file.");
   }

   DBUG_VOID_RETURN ();
}

# ====================================================================
# Common initialization logic for each config file loaded into memory!

sub initialize_config
{
   DBUG_ENTER_FUNC (@_);
   my $file  = shift;
   my $ropts = shift;
   my $gopts = shift;
   my $dopts = shift;

   my $space_sep = is_assign_spaces ( $ropts );
   $ropts->{$oTag} = 1   if ( $space_sep );

   my $f1 = File::Spec->catfile ("t", "config", $file);
   my $iCfg;
   eval {
      $iCfg = Advanced::Config->new ($f1, $ropts, $gopts, $dopts);
      dbug_isa_ok ($iCfg, 'Advanced::Config');
      my $ldr = $iCfg->load_config ();
      dbug_ok (defined $ldr, "Advanced::Config object has been loaded into memory!");
   };
   if ( $@ ) {
      unless (defined $iCfg) {
         dbug_isa_ok ($iCfg, 'Advanced::Config');
      }
      dbug_ok (0, "Advanced::Config object has been loaded into memory!");
      DBUG_LEAVE (3);
   }

   if ( $space_sep ) {
      DBUG_PRINT ("SPECIAL CASE", "Need to rename all tags with '=' in their names!");
      fix_space_sep_issue ( $iCfg );
   }

   DBUG_RETURN ( $iCfg );
}

# ====================================================================
# This function is a hack!!!
# There must normally never be an "=" in a tag's name for this to work!
# ====================================================================
# If using the special case of spaces separating the tag/value pair,
# will need to replace all "=" in the tag names to make them equivilant
# to the other config files.

sub fix_space_sep_issue
{
   DBUG_ENTER_FUNC (@_);
   my $cfg = shift;    # The config file to fix ...

   foreach my $name ( $cfg->find_sections () ) {
      my $s = $cfg->get_section ($name);
      foreach my $t ( $s->find_tags ("=") ) {
         my $new = $t;
         $new =~ s/=/ /g;
         $s->rename_tag ($t, $new);
      }
   }

   DBUG_VOID_RETURN ();
}

# ====================================================================
# Simulates the normal initialize_config () call ...
# By merging in the expected files ...

sub local_merge_files
{
   DBUG_ENTER_FUNC (@_);
   my $ctl_cfg  = shift;
   my $new_cfg  = shift;
   my $multiple = shift;

   my $f1 = File::Spec->catfile ("t", "config", "30-alt_symbols_03.cfg");
   my $f2 = File::Spec->catfile ("t", "config", "30-alt_symbols_04 multi section test.cfg");

   my ($ropt1, $dopt1) = grab_options ($ctl_cfg, basename ($f1));
   my ($ropt2, $dopt2) = grab_options ($ctl_cfg, basename ($f2));

   # What to do with $dopt???

   dbug_ok ($new_cfg->merge_config ($f1, $ropt1), "1st Merge is OK");
   dbug_ok ($new_cfg->merge_config ($f2, $ropt2), "2nd Merge is OK");

   if ( $multiple ) {
      dbug_ok ($new_cfg->merge_config ($f1, $ropt1), "3rd Merge is OK");
      dbug_ok ($new_cfg->merge_config ($f2, $ropt2), "4th Merge is OK");
   }

   DBUG_VOID_RETURN ();
}

# ====================================================================
# The generic config file loader ...
# ====================================================================
sub initialize_each_config
{
   DBUG_ENTER_FUNC (@_);
   my $ctrl_cfg = shift;
   my $file     = shift;

   my @section_tags;   # List of sections to compare against ...
   my $ropts;
   my $dopts;

   ($ropts, $dopts, @section_tags) = grab_options ( $ctrl_cfg, $file );

   # Always die if we can't locate tags in this config file.
   my %gopts = ( required => 2 );

   my $cfg = initialize_config ( $file, $ropts, \%gopts, $dopts );

   DBUG_RETURN ( $cfg, @section_tags );
}

# ====================================================================
# Grab the needed options ...
# ====================================================================
sub grab_options
{
   DBUG_ENTER_FUNC (@_);
   my $ctrl_cfg = shift;
   my $file     = shift;

   my @section_tags;

   $ctrl_cfg = $ctrl_cfg->get_section ($file);

   dbug_ok ( defined $ctrl_cfg, "Processing config file: $file" );

   unless ( defined $ctrl_cfg ) {
      return DBUG_RETURN ( undef, undef, @section_tags );
   }

   # Get the "Read" & "Date" Options to use ...
   my (%ropts, %dopts);
   foreach my $tg ( $ctrl_cfg->find_tags () ) {
      if ( $tg =~ m/^section_test_/i ) {
         my $val = $ctrl_cfg->get_value ( $tg );
         push ( @section_tags, $val );
      } else {
         my $ltg = lc ($tg);

         if ( exists $default_ropts->{$ltg} ) {
            $ropts{$ltg} = $ctrl_cfg->get_value ( $tg )  # Read
         } elsif ( exists $default_dopts->{$ltg} ) {
            $dopts{$ltg} = $ctrl_cfg->get_value ( $tg )  # Date
         } else {
            DBUG_PRINT ("INFO", "Skipping unknown tag (%s)", $tg);
         }
      }
   }

   DBUG_RETURN ( \%ropts, \%dopts, @section_tags );
}

