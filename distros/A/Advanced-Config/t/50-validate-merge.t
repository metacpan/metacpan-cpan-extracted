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

# This program tests the default section override when merging multiple
# config files together.

# Only tests the expected counts of tags present.  Not which ones or their values.

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

   my $file = File::Spec->catfile ("t", "config", "50-merge_a.cfg");
   my %ropts;

   # Load the same config file 3 different ways ...
   $ropts{Croak} = -1;
   my $cfg0 = init_config ( $file, \%ropts );

   $ropts{source_file_section_lbl} = "ONE";
   my $cfg1 = init_config ( $file, \%ropts );

   $ropts{source_file_section_lbl} = "TWO";
   my $cfg2 = init_config ( $file, \%ropts );

   $ropts{source_file_section_lbl} = "THREE";
   my $cfg3 = init_config ( $file, \%ropts );

   # So can tell when the config files were loaded in fish ...
   DBUG_PRINT ("====", "%s", "="x50);

   foreach my $cfg ( $cfg0, $cfg1, $cfg2, $cfg3 ) {
      my %expect;
      my $lbl;
      if ( $cfg == $cfg0 ) {
         $expect{main} = 4;
         $lbl = "default";
      } elsif ( $cfg == $cfg1 ) {
         $expect{'section a'} = 4;
         $lbl = "one";
      } elsif ( $cfg == $cfg2 ) {
         $expect{'section a'} = 2;
         $expect{'section b'} = 2;
         $expect{'section c'} = 2;
         $lbl = "two";
      } else {
         $expect{main} = 2;
         $expect{'section b'} = 3;
         $lbl = "three";
      }

      DBUG_PRINT ("FILE", "------ %s -------", $lbl);
      my @sections = $cfg->find_sections ();
      my $cnt = @sections;
      dbug_is ($cnt, 5, "The config file defines 5 sections!");

      foreach my $s ( @sections ) {
         my @tag_list = $cfg->get_section($s)->find_tags ();
         $cnt = @tag_list;
         my $expect = $expect{$s} || 1;

         my $lst = join ("', '", @tag_list);

         dbug_is ($cnt, $expect, "Found $cnt tags in section \"$s\" ==> '$lst'.");
      }
   }

   # Since I didn't count the test cases, must end my program
   # with a call to this method.  Can't do tests in END anymore!
   done_testing ();

   DBUG_LEAVE (0);
}

# ====================================================================

sub init_config
{
   DBUG_ENTER_FUNC ( @_ );
   my $file  = shift;
   my $ropts = shift;
   my $gopts = shift;
   my $dopts = shift;

   print_opts_hash ( "The Read Options", $ropts )  if ( $ropts );
   print_opts_hash ( "The Get  Options", $gopts )  if ( $gopts );
   print_opts_hash ( "The Date Options", $dopts )  if ( $dopts );

   my $cfg;
   eval {
      $cfg = Advanced::Config->new ($file, $ropts, $gopts, $dopts);
      dbug_isa_ok ($cfg, 'Advanced::Config');
      dbug_ok (defined $cfg, "Advanced::Config object has been created!");
      my $ldr = $cfg->load_config ();
      dbug_ok (defined $ldr, "Advanced::Config contents have been loaded into memory!");
   };
   if ( $@ ) {
      unless (defined $cfg) {
         dbug_isa_ok ($cfg, 'Advanced::Config');
      }
      dbug_ok (0, "Advanced::Config contents have been loaded into memory!");
      DBUG_LEAVE (3);
   }

   DBUG_RETURN ( $cfg );
}

