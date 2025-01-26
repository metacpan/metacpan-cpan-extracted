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
# in the t/config/12-*.cfg files.
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

   my $cfg1 = init_object ();     # Normal mode ...
   DBUG_PRINT ("====", "%s", "="x50);
   my $cfg2 = init_object (1);    # Inherit mode ...
   DBUG_PRINT ("====", "%s", "="x50);


   # Builds the hash to validate the config file against ...
   my ($valid_normal_cfg, $valid_inherit_cfg) = init_validation_hashes ();


   foreach my $idx ( 1, 2 ) {
      dbug_ok (1, "-"x40);

      my ($cfg, $valid, $mode);
      if ( $idx == 1 ) {
         ($cfg, $valid, $mode ) = ( $cfg1, $valid_normal_cfg, "normal" );
      } elsif ( $idx == 2 ) {
         ($cfg, $valid, $mode ) = ( $cfg2, $valid_inherit_cfg, "inherit" );
      } else {
         dbug_ok (0, "Valid Iteration ... ($idx)");
         next;
      }
      dbug_ok (1, "Processing mode: ${mode}");

      my @sections = $cfg->find_sections ();

      my $total = keys %{$valid};
      my $cnt = @sections;
      dbug_is ($cnt, $total, "The config file defines the correct number of sections!  ($cnt vs $total)");

      my $s;
      foreach $s ( @sections ) {
         dbug_ok ( exists $valid->{$s}, "Found section '$s' in the validaton hash!" );
      }
      foreach $s ( sort keys %{$valid} ) {
         my $sect = $cfg->get_section ($s);
         unless ( $sect ) {
            dbug_ok (0, "Found section '$s' in the config file!");
            next;
         }

         # Now let's validate the section contents ...
         my @tag_list = $sect->find_tags ();
         my $cnt1 = @tag_list;
         my $cnt2 = keys %{$valid->{$s}};
         dbug_is ($cnt1, $cnt2, "Section '$s' has the correct number of tag/value pairs!  ($cnt1)");

         # Validating the list of tags in the config file match what's in my validation hash.
         $cnt = 0;
         foreach my $t ( @tag_list ) {
            unless ( exists $valid->{$s}->{$t} ) {
               dbug_ok (0, "Tag \"$_\" also exists in the validation hash!");
               ++$cnt;
            }
         }
         dbug_is ($cnt, 0, "All tags were accounted for in the validation hash for section '$s'!");

         # Validating that my hash matches what's in the config file ...
         foreach my $t ( sort keys %{$valid->{$s}} ) {
            my $val1 = $valid->{$s}->{$t};
            my $val2 = $sect->get_value ( $t );
            my $chk  = (defined $val2) && ($val1 eq $val2);
            $val2 = (defined $val2) ? $val2 : "";
            dbug_ok ( $chk, "Validating tag \"$t\" in section \"$s\" matches config file.  ($val2)" );
            unless ( $chk ) {
               DBUG_PRINT ("ERROR", "Value should have been: %s", $val1);
            }
         }
      }  # End foreach $s loop ...
   }     # End foreach $idx loop ...

   # Since I didn't count the test cases, must end my program
   # with a call to this method.  Can't do this in END anymore!
   done_testing ();

   DBUG_LEAVE (0);
}

# ==============================================------======================
# Initialize the requested configuration ...

sub init_object
{
   DBUG_ENTER_FUNC (@_);
   my $inherit = shift || 0;

   my %gOpts;
   $gOpts{inherit} = 1  if ( $inherit );

   my $file = File::Spec->catfile ("t", "config", "12-use_sections.cfg");

   my $cfg;
   eval {
      $cfg = Advanced::Config->new ($file, undef, \%gOpts);
      dbug_ok (defined $cfg, "Advanced::Config object has been created!  (inherit => $inherit)");
      my $ldr = $cfg->load_config ();
      dbug_ok (defined $ldr, "Advanced::Config object has been loaded into memory!");
   };
   if ( $@ ) {
      unless (defined $cfg) {
         dbug_ok (defined $cfg, "Advanced::Config object has been created!  (inherit => $inherit)");
      }
      dbug_ok (0, "Advanced::Config object has been loaded into memory!");
      DBUG_LEAVE (3);
   }

   DBUG_RETURN ($cfg);
}

# ==============================================------======================
# All tags & sections defined in the config files must be initialized below!
# The config file is: t/config/12-use_sections.cfg
# It's fairly complex based on how all it's sub-config files interact!

# NOTE: No tag may have undef as a value!
#       That it can't happen in this module if a tag is defined!
#       Undef means the tag doesn't exist instead!

sub init_validation_hashes
{
   DBUG_ENTER_FUNC (@_);

   # The name of the default section ...
   my $default_name = Advanced::Config::DEFAULT_SECTION;

   # ---------------------------------------------------
   # Setting up for normal mode ...
   # ---------------------------------------------------
   # Tags in the default main section ...
   my %main = (  "main_01" => "one",
                 "main_02" => "two",
                 "main_03" => "three",
                 "main_04" => "four",
                 "main_05" => "five",
                 "main_06" => "Crispy/Sweet",
                 "override_1" => "=ONE=",
                 "override_2" => "=TWO=",
                 "self"    => $default_name
              );

   # Tags in Sections 01, 02 & 03 in normal mode ...
   my %section_01n = ( "override_1" => "Help me One!",
                       "override_2" => "No help here One!",
                       "extra_1"    => "Extra Help",
                       "extra_2"    => "Extra Extra Help",
                       "self"       => "section 01"
                     );

   # Tags in Section 02 ...
   my %section_02n = ( "override_1" => "Two vs One no fair! (ONE)",
                       "override_2" => "Two vs Two isn't fair either! (TWO)",
                       "extra_1"    => "Crispy",
                       "self"       => "section 02"
                     );

   # Tags in Section 03 ...
   my %section_03n = ( "override_1" => "Three to One odds are great!",
                       "override_2" => "Three to Two odds not so great!",
                       "extra_2"    => "Sweet",
                       "self"       => "section 03"
                     );

   # ---------------------------------------------------
   # Setting up for inherit mode ...
   # ---------------------------------------------------
   # Tags in Sections 01, 02 & 03 in inherit mode ...
   my %section_01i = %section_01n;
   my %section_02i = %section_02n;
   my %section_03i = %section_03n;

   # Inherit from the main section ...
   foreach my $k ( keys %main ) {
      $section_01i{$k} = $main{$k}  unless ( exists $section_01i{$k} );
      $section_02i{$k} = $main{$k}  unless ( exists $section_02i{$k} );
      $section_03i{$k} = $main{$k}  unless ( exists $section_03i{$k} );
   }

   # Section => contents (tag/value pairs)
   my %normal_cfg = ( $main{self}        => \%main,
                      $section_01n{self} => \%section_01n,
                      $section_02n{self} => \%section_02n,
                      $section_03n{self} => \%section_03n
                    );

   # Section => contents (tag/value pairs)
   my %inherit_cfg = ( $main{self}        => \%main,
                       $section_01i{self} => \%section_01i,
                       $section_02i{self} => \%section_02i,
                       $section_03i{self} => \%section_03i
                     );

   DBUG_RETURN (\%normal_cfg, \%inherit_cfg);
}

