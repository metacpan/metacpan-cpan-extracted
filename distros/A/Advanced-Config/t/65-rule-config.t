#!/usr/bin/perl

# This test program tests the functionality added in v1.15 where we can use rule
# config files to tell how to manage our regular config files,

# Its main purpose is to support complex sourcing rules where the main config
# file souces in other config files with radically different parsing rules.
# The existing callback solution got very messy very quickly.

# The rule configuration file contains entries for all the options you want
# to modify in the 3 hash options in the call to new().  With a section for
# each config file you later source in.

# The rule configuration is created by calling newDefineConfigRules().
# And call set_config_rules () to tell your configuration files to tell
# your config file to use these rules before you load it into memory.

# ------------------------------------------------------------------------------

use strict;
use warnings;

use Test::More;
use File::Basename;
use File::Spec;
use Sys::Hostname;
use Fred::Fish::DBUG 2.09 qw / on /;
use Fred::Fish::DBUG::Test 2.09;
use Fred::Fish::DBUG::TIE;

# How to find the helper module ...
BEGIN { push (@INC, File::Spec->catdir (".", "t", "test-helper")); }
use helper1234;

my $fish;

BEGIN 
{
   $fish = turn_fish_on_off_for_advanced_config ();

   unlink ( $fish );

   DBUG_ENTER_FUNC ();

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
# Start of the main program!
# --------------------------------------
{
   DBUG_TIE_STDERR ();

   # Turn fish on ...
   DBUG_PUSH ( $fish );

   DBUG_ENTER_FUNC (@ARGV);

   dbug_ok (1, "In the MAIN program ...");

   bad_test_rules ( build_filename ("65-bad-rule-config.cfg") );

   my $rCfg = test_rules ( build_filename ("65-good-rule-config.cfg") );

   dump_section_rules ( $rCfg, "tom*.cfg" );

   my $f = build_filename ( "65-my-config-file.cfg" );
   my $cfg1 = Advanced::Config->new ($f)->set_config_rules ($rCfg);
   dbug_ok ( (defined $cfg1), "Config Object created using rules." );
   test_using_rules ( $cfg1 );

   my $cfg2 = Advanced::Config->new ($f)->copy_opts_from_cfg ( $cfg1 );
   dbug_ok ( (defined $cfg2), "Config Object created using copy cfg logic." );
   test_using_rules ( $cfg2 );

   DBUG_UNTIE_STDERR ();
   verify_ruleCfg_is_ReadOnly ( $rCfg );
   
   # Since I didn't count the test cases, must end my program
   # with a call to this method.  Can't do tests in END anymore!
   done_testing ();

   DBUG_LEAVE (0);
}

sub test_using_rules
{
   DBUG_ENTER_FUNC (@_);
   my $cfg  = shift;

   # DBUG_SET_FILTER_COLOR ( DBUG_FILTER_LEVEL_OTHER, "red" );

   DBUG_PRINT ("DBUG", '+'x60);
   $cfg->load_config ();
   DBUG_PRINT ("DBUG", '@'x60);

   # DBUG_SET_FILTER_COLOR ( DBUG_FILTER_LEVEL_OTHER, "black" );

   my $total = 0;
   foreach my $tag ( $cfg->find_tags () ) {
      if ( $tag =~ m/^tag_(.*)$/ ) {
	  my $expected = $1;
	  my $val = $cfg->get_value ( $tag );
	  dbug_cmp_ok ($val, "eq", $expected, "Tag '$tag' has correct value.");
	  ++$total;
      } else {
	  dbug_ok ( 0, "Expected tag '$tag'." );
      }
   }
   dbug_cmp_ok ( $total, "==", 5, "Got the expected number of tags!" );

   DBUG_VOID_RETURN ();
}

sub build_filename
{
   DBUG_ENTER_FUNC (@_);
   my $file  = shift;
   $file = File::Spec->catfile ("t", "config", $file);
   DBUG_RETURN ($file);
}

sub test_rules
{
   DBUG_ENTER_FUNC (@_);
   my $file = shift;

   my $ruleCfg = Advanced::Config->newDefineConfigRules ( $file );
   dbug_ok ( (defined $ruleCfg), "Rule Config Object created" );

   DBUG_PRINT ("DBUG", '='x60);

   # Testing rule config internals ...
   test_section_lookup ($ruleCfg, "65-my-config-file.cfg",
				  "65-my-config-file.cfg",
				  "assign", ":=");

   test_section_lookup ($ruleCfg, "Mary.conf", "*", "comment", "//");

   test_section_lookup ($ruleCfg, "Sample.cfg",  "*.cfg", "Assign", "=");
   test_section_lookup ($ruleCfg, "Example.CFG", "*.cfg", "ASSIGN", "=");

   test_section_lookup ($ruleCfg, "TomData.CFG", "tom*.cfg", "quote_left", ">");
   test_section_lookup ($ruleCfg, "Tom.cfg",     "tom*.cfg", "quote_left", ">");
   test_section_lookup ($ruleCfg, "xTomData.CFG", "*.cfg",   "assign",  "=");
   test_section_lookup ($ruleCfg, "Tom",          "*",       "Comment", "//");

   test_section_lookup ($ruleCfg, "BOBData.CFG",  "*bob*", "quote_left", "(");
   test_section_lookup ($ruleCfg, "XbobData.cfg", "*bob*", "quote_left", "(");
   test_section_lookup ($ruleCfg, "bob.cfg",      "*bob*", "quote_left", "(");
   test_section_lookup ($ruleCfg, "bob",          "*bob*", "Quote_Left", "(");

   test_section_lookup ($ruleCfg, "bob_issue",    "*bob*", "source_cb", "abc::xyz");

   # Error case, hit muliple section matches.
   test_section_lookup ($ruleCfg, "tom & bob.cfg");
   test_section_lookup ($ruleCfg, "Tomas & Bobby.cfg");

   DBUG_RETURN ($ruleCfg);
}

sub test_section_lookup
{
   DBUG_ENTER_FUNC (@_);
   my $ruleCfg  = shift;
   my $file     = shift;
   my $expected = shift;
   my $tag      = shift;
   my $value    = shift;

   my $cfg;
   my $ok;
   eval {
      $cfg = $ruleCfg->_get_rule_section ( $file );
      $ok = dbug_ok ( (defined $cfg), "rule section found");
   };
   if ( $@ ) {
      chomp ($@);
      if (defined $expected ) {
	 dbug_ok (0, "Die caught, expected '$expected' for '$file'.  $@");
      } else {
	 dbug_ok (1, "Die caught as expected for '$file'.  $@");
      }
      return DBUG_VOID_RETURN ();
   }

   unless ( $ok ) {
      return DBUG_VOID_RETURN ();
   }

   my $name = $cfg->section_name ();
   dbug_cmp_ok ($name, "eq", $expected, "Found the expected rule section for '$file'!");

   my $order = $cfg->get_integer ( "__order__", 1 );
   dbug_cmp_ok ( $order, ">", 1, "Found the expected order tag '$order'.");

   my $found = $cfg->get_value ( $tag );
   dbug_cmp_ok ( $found, "eq", $value, "Lookup $tag worked." );

   DBUG_VOID_RETURN ();
}


sub bad_test_rules
{
   DBUG_ENTER_FUNC (@_);
   my $file = shift;

   eval {
      my $ruleCfg = Advanced::Config->newDefineConfigRules ( $file );
      if (defined $ruleCfg) {
	 dbug_ok (0, "Bad rule config object created by mistake.");
      } else {
	 dbug_ok (0, "Bad rule config object failed instead of throwing exception");
      }
   };

   if ($@) {
      chomp ($@);
      dbug_ok (1, "Error trapped:  $@");
   }

   DBUG_PRINT ("DBUG", '='x60);

   DBUG_VOID_RETURN ();
}


sub dump_section_rules
{
   DBUG_ENTER_FUNC (@_);
   my $rCfg    = shift;
   my $section = shift;

   my %data;

   DBUG_ENTER_BLOCK ("silent");
   DBUG_PAUSE ();

   my $rule = $rCfg->get_section ( $section );
   my $list = $rule->get_value ( "___list_read___" );

   foreach (@{$list} )  {
   # $data{$_} = $rule->get_value ( $_ );
      $data{$_} = ( $rule->_base_get2 ( $_ ) )[0];;
   }

   DBUG_VOID_RETURN ();
   
   foreach ( sort keys %data ) {
      DBUG_PRINT ("DUMP", "%-33s = %s", $_, $data{$_});
   }

   DBUG_VOID_RETURN ();
}

sub my_die
{
   my $msg = shift;
   DBUG_PRINT ("MY_DIE", $msg);
   die (" \n");
}

sub my_warn
{
   my $msg = shift;
   DBUG_PRINT ("MY_WARN", $msg);
   # diag ($msg);
   # warn "\n";
   return;
}


sub verify_ruleCfg_is_ReadOnly
{
   DBUG_ENTER_FUNC (@_);
   my $ruleCfg = shift;

   local $SIG{__DIE__} = \&my_die;
   local $SIG{__WARN__} = \&my_warn;

   dbug_ok (1, '+'x40);

   my $f = build_filename ( "65-my-config-file.cfg" );
   eval {
      $ruleCfg->load_config ($f);
      dbug_ok (0, "Loading a new file is disallowed.");
   };
   if ($@) {
      dbug_ok (1, "Loading a new file is disallowed.");
   }

   eval {
      $ruleCfg->load_string ( "a = b" );
      dbug_ok (0, "Loading a new string is disallowed.");
   };
   if ($@) {
      dbug_ok (1, "Loading a new string is disallowed.");
   }

   eval {
      $ruleCfg->merge_config ($f);
      dbug_ok (0, "Merging another file is disallowed.");
   };
   if ($@) {
      dbug_ok (1, "Merging another file is disallowed.");
   }

   eval {
      $ruleCfg->merge_string ( "a = b" );
      dbug_ok (0, "Merging another string is disallowed.");
   };
   if ($@) {
      dbug_ok (1, "Merging another string is disallowed.");
   }

   eval {
      $ruleCfg->set_value ( "croak", 2 );
      dbug_ok (0, "Changing a tag's value is disallowed.");
   };
   if ($@) {
      dbug_ok (1, "Changing a tag's value is disallowed.");
   }

   eval {
      $ruleCfg->rename_tag ( "croak", "die" );
      dbug_ok (0, "Renaming a tag's name is disallowed.");
   };
   if ($@) {
      dbug_ok (1, "Renaming a tag's name is disallowed.");
   }

   eval {
      $ruleCfg->move_tag ( "inherit", "*" );
      dbug_ok (0, "Moving a tag to another section is disallowed.");
   };
   if ($@) {
      dbug_ok (1, "Moving a tag to another section is disallowed.");
   }

   eval {
      $ruleCfg->delete_tag ( "assign" );
      dbug_ok (0, "Deleting a tag is disallowed.");
   };
   if ($@) {
      dbug_ok (1, "Deleting a tag is disallowed.");
   }

   eval {
      $ruleCfg->create_section ( "Bad Section" );
      dbug_ok (0, "Creating a new section is disallowed.");
   };
   if ($@) {
      dbug_ok (1, "Creating a new section is disallowed.");
   }

   # This one should actually work!
   my $status = $ruleCfg->refresh_config ( force => 1 );
   dbug_ok ($status, "The refresh of the rule config file worked.");

   DBUG_VOID_RETURN ();
}

