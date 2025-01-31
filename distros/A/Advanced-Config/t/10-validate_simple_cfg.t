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

# Tests out a simple config file using default parsing rules.
# Verifing the config file returns the expected tag/value pairs.

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

   my $ropts = Advanced::Config::Options::get_read_opts ( {} );
   my $gopts = Advanced::Config::Options::get_get_opts ( {} );
   my $dopts = Advanced::Config::Options::get_date_opts ( {} );
   # print_opts_hash ( "The Read Options", $ropts );
   # print_opts_hash ( "The Get Options",  $gopts );
   # print_opts_hash ( "The Date Options", $dopts );

   my $file = File::Spec->catfile ("t", "config", "10-simple.cfg");
   my $cfg;
   eval {
      $cfg = Advanced::Config->new ($file, $ropts, $gopts);
      dbug_isa_ok ($cfg, "Advanced::Config");
      my $ldr = $cfg->load_config ();
      dbug_ok (defined $ldr, "Advanced::Config object has been loaded into memory!");
   };
   if ( $@ ) {
      unless (defined $cfg) {
         dbug_isa_ok ($cfg, "Advanced::Config");
      }   
      dbug_ok (0, "Advanced::Config object has been loaded into memory!");
      DBUG_LEAVE (3);
   }

   # So can tell when the config file was loaded in fish ...
   DBUG_PRINT ("====", "%s", "="x50);

   print_opts_hash ( "The Read Options", $ropts );
   print_opts_hash ( "The Get Options",  $gopts );
   print_opts_hash ( "The Date Options", $dopts );

   # Builds the hash to validate the config file against ...
   my ($total, $validate) = init_validation_hash ( $ropts, $dopts );

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

   DBUG_PRINT ("----", "%s", "-"x50);

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
# The config file is: t/config/10-simple.cfg
# And it's a very basic one without sections or sourcing in of other files!

# NOTE: No tag may have undef as a value!
#       This can't happen in this module if a tag is defined!
#       Undef means the tag doesn't exist instead!

sub init_validation_hash
{
   DBUG_ENTER_FUNC (@_);
   my $opts  = shift;
   my $dopts = shift;

   my $sep = "";
   my ($a, $b) = ("one", "two");
   my $p = File::Spec->catfile ($a, $b);
   if ( $p =~ m/^${a}(.+)${b}$/ ) {
      $sep = $1;
   }

   my %dates;
   Advanced::Config::Options::set_special_date_vars ($dopts, \%dates);

   my %values = (  "a" => "A is for Apple!",
                   "b" => "B is for Bat!",
                   "c" => "C is for Cat!",
                   "d" => "D is for Dog!",
                   "e" => "E is for Elephant!",
                   "f" => "'F is for Frog!" . '"',
                   "g" => '$fooled you',
                   "h_pwd" => 'Hello World!',
                   "one" => "ONE", "two" => "TWO", "three" => "THREE",
                   "number 1"  => "ONE TWO THREE",
                   "rule5_pid" => $$, "rule5_prog" => $0, "rule5_os" => $^O,
                   "rule6_host" => hostname(),
		 # "rule6_user" => getlogin () || getpwuid ($<) || "??",
		   "rule6_user" => Advanced::Config::Options::_get_user_id (),
                   "rule6_pid"  => $$,
                   "rule6_p"    => basename ($0, ".t"),
                   "rule6_sep"  => $sep,
                   "cmt"        => $opts->{comment},
                   "empty_1"    => '',
                   "empty_2"    => '',
                   "empty_3"    => 'abc  xyz',
                   "empty_4"    => 'abc  xyz',
                   "rule8 missing" => ""
                );

   $values{"number 2"} = $values{"number 1"};
   $values{"number 3"} = $values{"number 1"};
   $values{"number 4"} = $values{"number 1"};
   $values{"number 5"} = $values{"number 1"};
   $values{"number 6"} = $values{"number 1"};
   $values{"number 8"} = $values{"number 1"};

   $values{cmt2} = $values{cmt} . $values{cmt};
   $values{cmt3} = $values{cmt} . $values{cmt} . $values{cmt};

   # Handles rules 6 & 7 combined ...
   $values{log1} = File::Spec->catfile ("t", "logs", $values{rule6_p} . ".");
   $values{log3} = $values{log1} . $dates{tomorrow} . ".txt";
   $values{log2} = $values{log1} . $dates{yesterday} . ".txt";
   $values{log1} .= $dates{today} . ".txt";

   eval {
      $values{rule6_ppid} = getppid ();
   };
   if ( $@ ) {
      $values{rule6_ppid} = "-1";
   }

   my $total = keys %values;

   DBUG_RETURN ($total, \%values);
}

