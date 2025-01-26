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

# This program does a detailed validation of what's found
# in the t/config/15-*.cfg files.
# The 01 file sources in the others so they can be examined
# as a single Object!

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

   my $ropts = Advanced::Config::Options::get_read_opts ( {} );
   my $gopts = Advanced::Config::Options::get_get_opts ( {} );
   # print_opts_hash ( "The Read Options", $ropts );
   # print_opts_hash ( "The Get Options",  $gopts );

   my $file = File::Spec->catfile ("t", "config", "15-multi_source_01_main.cfg");
   my $cfg;
   eval {
      $cfg = Advanced::Config->new ($file, $ropts, $gopts);
      dbug_isa_ok ($cfg, 'Advanced::Config');
      my $ldr = $cfg->load_config ();
      dbug_ok (defined $ldr, "Advanced::Config object has been loaded into memory!");
   };
   if ( $@ ) {
      unless (defined $cfg) {
         dbug_ok (defined $cfg, "Advanced::Config object has been created!");
      }
      dbug_ok (0, "Advanced::Config object has been loaded into memory!");
      DBUG_LEAVE (3);
   }

   # So can tell when the config file was loaded in fish ...
   DBUG_PRINT ("====", "%s", "="x50);

   print_opts_hash ( "The Read Options", $ropts );
   print_opts_hash ( "The Get Options",  $gopts );

   # Builds the hash to validate the config file against ...
   my ($total, $validate) = init_validation_hash ( $ropts );

   DBUG_PRINT ("----", "%s", "-"x50);

   my @sections = $cfg->find_sections ();
   my $cnt = @sections;
   dbug_is ($cnt, $total, "The config file defines the correct number of sections!  ($cnt)");

   my $s;
   foreach $s ( @sections ) {
      dbug_ok ( exists $validate->{$s}, "Found section '$s' in the validaton hash!" );
   }

   foreach $s ( sort keys %{$validate} ) {
      my $sect = $cfg->get_section ($s);

      dbug_ok (1, "-"x30);
      unless ( $sect ) {
         dbug_ok (0, "Found section '$s' in the config file!");
         next;
      }

      my @tag_list = $sect->find_tags ();
      my $cnt1 = @tag_list;
      my $cnt2 = keys %{$validate->{$s}};
      dbug_is ($cnt1, $cnt2, "Section '$s' has the correct number of tag/value pairs!  ($cnt1)");

      # Validating the list of tags in the config file match what's in my validation hash.
      $cnt = 0;
      foreach my $t ( @tag_list ) {
         unless ( exists $validate->{$s}->{$t} ) {
            dbug_ok (0, "Tag \"$_\" exists in the validation hash!");
            ++$cnt;
         }
      }
      dbug_is ($cnt, 0, "All tags were accounted for in the validation hash for section '$s'!");

      # Validating that my hash matches what's in the config file ...
      foreach my $t ( sort keys %{$validate->{$s}} ) {
         my $val1 = $validate->{$s}->{$t};
         my $val2 = $sect->get_value ( $t );
         my $chk  = (defined $val2) && ($val1 eq $val2);
         $val2 = (defined $val2) ? $val2 : "";
         dbug_ok ( $chk, "Validating tag \"$t\" in section \"$s\" matches config file.  ($val2)" );
         unless ( $chk ) {
            DBUG_PRINT ("ERROR", "Value should have been: %s", $val1);
         }
      }
   }

   # Since I didn't count the test cases, must end my program
   # with a call to this method.  Can't do this in END anymore!
   done_testing ();

   DBUG_LEAVE (0);
}

# ==============================================------======================
# All tags & sections defined in the config files must be initialized below!
# The config file is: t/config/15-multi_source_01_main.cfg
# It's fairly complex based on how all it's sub-config files interact!

# NOTE: No tag may have undef as a value!
#       That it can't happen in this module if a tag is defined!
#       Undef means the tag doesn't exist instead!

sub init_validation_hash
{
   DBUG_ENTER_FUNC (@_);
   my $opts = shift;

   # Tags in the main section ...
   my %main = (  "main_01" => "Hello World!",
                 "hello"   => "again!",
                 "main_02" => "What's up Doc?",
                 "main_03" => "I'm hunting wrabits!",
                 "main_04" => "Good bye cruel world!"
              );

   # Tags in the Common section ...
   my %common = (  "common_01" => "Humpty Dumpty!",
                   "common_02" => "Sat on a wall!",
                   "common_03" => "He had a great fall!",
                   "common_04" => "They couldn't put humpty together again!"
                );

   # Tags in the Overwrite section ...
   my %overwrite = ( "overwrite" => "From file 04!" );

   # Common tags between different sections ...
   my %first  = ( "hello" => "1st!" );
   my %second = ( "hello" => "2nd?" );
   my %third  = ( "hello" => "3rd." );
   my %fourth = ( "hello" => "4th!?!" );

   # Sedction names points to the tag/value pairs found in them.
   my %sections = ( "main"      => \%main,
                    "common"    => \%common,
                    "overwrite" => \%overwrite,
                    "first"     => \%first,
                    "second"    => \%second,
                    "third"     => \%third,
                    "fourth"    => \%fourth,
                  );

   my $total = keys %sections;

   DBUG_RETURN ($total, \%sections);
}

