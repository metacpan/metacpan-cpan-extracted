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

# This test case validates that all variable modifiers work as expected.
# These modifiers only work if the left/right anchors are different.
# So using the default variable anchors in this test case.
# See:  http://wiki.bash-hackers.org/syntax/pe
# for more details on what these variables modifiers are and how they should
# work.

# This test progam provides hard coded expected answers for each tag defined
# in "40-validate-modifiers.cfg".

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

   # Set for one of the test cases!
   $ENV{yuck} = 1;
   $ENV{Yams} = 1;

   dbug_ok (1, "In the MAIN program ...");  # Test # 2 ...

   my $ropts = Advanced::Config::Options::get_read_opts ( { Croak => 1, dbug_test_use_case_parse_override => 1} );
   my $gopts = Advanced::Config::Options::get_get_opts ( { } );
   # print_opts_hash ( "The Read Options", $ropts );
   # print_opts_hash ( "The Get Options",  $gopts );

   my $file = File::Spec->catfile ("t", "config", "40-validate-modifiers.cfg");
   my $cfg;
   eval {
      $cfg = Advanced::Config->new ($file, $ropts, $gopts);
      dbug_isa_ok ($cfg, 'Advanced::Config');
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

   # So can tell when the config file was loaded in fish ...
   DBUG_PRINT ("====", "%s", "="x50);

   print_opts_hash ( "The Read Options", $ropts );
   print_opts_hash ( "The Get Options",  $gopts );

   # Builds the hash to validate the config file against ...
   my ($total, $validate) = init_validation_hash ();

   my $val = $cfg->get_value ( "msg" );
   dbug_cmp_ok ( $val, 'eq', $validate->{msg}, "The test phrases are the same!");

   DBUG_PRINT ("----", "%s", "-"x50);

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

   dbug_ok (1, "-"x60);

   foreach ( sort keys %{$validate} ) {
      my $val1 = $validate->{$_};
      my $val2 = $cfg->get_value ( $_ );
      my $val3 = (defined $val2) ? $val2 : "";
      my $chk  = (defined $val2) && $val1 eq $val2;
      dbug_ok ( $chk, "Validating tag \"$_\" matches config file.  ($val3)" );
      unless ( $chk ) {
         DBUG_PRINT ("ERROR", "Value should have been: %s", $val1);
      }
   }

   # Since I didn't count the test cases, must end my program
   # with a call to this method.  Can't do tests in END anymore!
   done_testing ();

   DBUG_LEAVE (0);
}

# ====================================================================
# All tags defined in the config file must be initialized below!
# The config file is: t/config/40-validate-modifiers.cfg

# NOTE: No tag may have undef as a value!
#       That can't happen in this module if a tag is defined!
#       Undef means the tag doesn't exist instead!

sub init_validation_hash
{
   DBUG_ENTER_FUNC (@_);

   my $Msg  = "Be liberal in what you accept, and conservative in what you send.";
   my $aMsg = "liberal in what you accept, and conservative in what you send.";
   my $bMsg = "send.";
   my $cMsg = "Be liberal in what you accept, and conservative in what you";
   my $dMsg = "Be";

   my $a2Msg = "in what you accept, and conservative in what you send.";
   my $c2Msg = "Be liberal in what you accept, and conservative in what";
   my $e2Msg = "liberal";

   my $sub1 = $Msg;   $sub1 =~ s/in/by/;
   my $sub2 = $Msg;   $sub2 =~ s/in/by/g;
   my $sub5 = $Msg;   $sub5 =~ s/in//;
   my $sub6 = $Msg;   $sub6 =~ s/in//g;

   # Get all variables starting with "y" ...
   # Need in case your environment contains unexpected ${y...} vars.
   my %l;
   foreach ( "yellow", "yesterday", keys %ENV ) {
      $l{$_} = 2  if ( $_ =~ m/^y/ );
   }
   my $lst = join (" ", sort keys %l);

   my %values = (  "msg"  => $Msg,
                   "a"    => $aMsg,
                   "b"    => $bMsg,
                   "c"    => $cMsg,
                   "d"    => $dMsg,
                   "a2"   => $a2Msg,
                   "c2"   => $c2Msg,
                   "e2"   => $e2Msg,
                   "len"  => length ($Msg),

                   "cd"   => "call die",
                   "abcd" => "",
                   "die2" => $Msg,
                   "die3" => "",
                   "die4" => $Msg,

                   "def0" => "The unknown soldier",
                   "def1" => "The unknown soldier.",
                   "def2" => $dMsg,
                   "def3" => "The unknown soldier 2.",
                   "def4" => "",
                   "def5" => $dMsg,

                   "awa"   => "Another",
                   "zebra"    => "A wild animal!",
                   "elephant" => "Another wild animal!",
                   "asgn1" => "A wild animal!",
                   "asgn2" => "A wild animal!",
                   "asgn3" => "Another wild animal!",
                   "asgn4" => "Another wild animal!",

                   "dnu"   => "Do not use",
                   "alt1"  => "",
                   "alt2"  => "Overriding a value is fun!",
                   "alt3"  => "",
                   "alt4"  => "",
                   "alt5"  => "",
                   "alt6"  => "Overriding a value is fun!",
                   "alt7"  => "Do not use!",
                   "alt8"  => "",

                   "yellow"    => "bass",
                   "list1"     => $lst,
                   "list2"     => $lst,
                   "bass"      => "is a fish",
                   "indirect1" => "is a fish",
                   "indirect2" => "",
                   "book"      => "Chapter123",
                   "all"       => "Chapter",

                   "sub_01"    => ${sub1},
                   "sub_02"    => ${sub2},
                   "sub_03"    => "",
                   "sub_04"    => "",
                   "sub_05"    => ${sub5},
                   "sub_06"    => ${sub6},
                   "sub_07"    => ${sub5},
                   "sub_08"    => ${sub6},
                   "sub_09"    => "xxx xxxxx",
                   "sub_10"    => "Yxx xxxxx",
                   "sub_11"    => "xxx xxxxY",
                   "sub_12"    => "xx xxxxx",
                   "sub_13"    => "xxx xxxx",
                   "sub_14"    => " conservative in what you send.",
                   "sub_15"    => " conservative",
                   "sub_16"    => "t you",
                   "sub_17"    => "t you",
                   "sub_18"    => "in what you accept, and conservative",
                   "sub_19"    => "d",
                   "sub_20"    => "",
                   "sub_21"    => "",

                   "xcase_00_opt" => "^^",
                   "xcase_00"  => "ThIs Is OnE fInE mEsS wE'rE iN!",
                   "xcase_01"  => "tHiS iS oNe FiNe MeSs We'Re In!",
                   "xcase_02"  => "thIs Is OnE fInE mEsS wE'rE iN!",
                   "xcase_03"  => "THIS IS ONE FINE MESS WE'RE IN!",
                   "xcase_04"  => "this is one fine mess we're in!",
                   "xcase_05"  => "This is one fine mess we're in!",
                   "xcase_06"  => "tHIS IS ONE FINE MESS WE'RE IN!",
                   "xcase_07"  => "THIS IS ONE FINE MESS WE'RE IN!"
                );

   my $cnt = 0;
   foreach (keys %values) {
      ++$cnt;
   }

   DBUG_RETURN ($cnt, \%values);
}

