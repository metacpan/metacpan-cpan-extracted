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

# This program tests out the toHash() functionality.
# It assumes that the "string" functions have already been tested out as working!

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

   dbug_ok (1, "------------------------------------------------");
   my $cfg1 = init_config ("a = low level\nb=high level");
   test_all_sections ( $cfg1, 0 );

   dbug_ok (1, "------------------------------------------------");
   my $cfg2 = init_config ("a = low level\nb=high level\npwd = Help!!!");
   test_all_sections ( $cfg2, 0 );
   test_all_sections ( $cfg2, 1 );

   dbug_ok (1, "------------------------------------------------");
   my $cfg3 = init_config ("[hello]\n a = low level\n b=high level\n pwd = Help!!!");
   test_all_sections ( $cfg3, 0 );
   test_all_sections ( $cfg3, 1 );

   dbug_ok (1, "------------------------------------------------");
   my $cfg4 = init_config ( "[alpha]\n 01 = low level\n 02=high level\n pwd03 = Help!!!\n" .
                            "[beta]\n 11 = low one\n 12=high two\n pwd13 = ???\n" .
                            "[omega]\n pwd23 = Ha! Ha! Ha!\n" .
                            "[zeta]\n"
                          );
   test_all_sections ( $cfg4, 0 );
   test_all_sections ( $cfg4, 1 );

   # Since I didn't count the test cases, must end my program
   # with a call to this method.  Can't do tests in END anymore!
   done_testing ();

   DBUG_LEAVE (0);
}


# ====================================================================
sub test_all_sections
{
   DBUG_ENTER_FUNC ( @_ );
   my $cfg       = shift;
   my $sensitive = shift;

   my $hashRef = $cfg->toHash ( $sensitive );

   foreach my $s ( $cfg->find_sections (undef, 0) ) {
      my $sect = $cfg->get_section ( $s, 1 );
      dbug_ok ( 1, "Section '$s' exists in the Advanced::Config object!" );
      my @tags = trim_if_sensitive ( $sect, $sensitive );

      my $data = $hashRef->{$s};   # Get the proper sub-hash ...

      if ( $#tags == -1 ) {
         dbug_ok ( ! defined $data, "Section '$s' has no data in it!" );
      } else {
         dbug_ok ( defined $data, "Section '$s' has data in it!" );
         test_section ( $sect, $data, @tags );
      }
   }

   DBUG_VOID_RETURN ();
}

# ====================================================================
sub trim_if_sensitive
{
   DBUG_ENTER_FUNC ( @_ );
   my $cfg = shift;
   my $sensitive = shift;

   my @tags = $cfg->find_tags ( undef, 0 );
   my @keep;

   if ( $sensitive ) {
      foreach ( @tags ) {
        push (@keep, $_)  unless ( $cfg->chk_if_sensitive ($_, 0) );
      }
   } else {
      @keep = @tags;
   }

   DBUG_RETURN ( @keep );
}

# ====================================================================
sub test_section
{
   DBUG_ENTER_FUNC ( @_ );
   my $sect    = shift;
   my $data    = shift;
   my @tags    = @_;

   my %found;
   foreach my $tag ( sort @tags ) {
      my $val = $sect->get_value ($tag) || "";
      dbug_ok ( exists $data->{$tag} && $data->{$tag} eq $val,
            "Tag '${tag}' exists in the hash with the correct value ($val)");

      $found{$tag} = 1;
   }

   # Make sure there are no extra keys ...
   foreach my $tag ( sort keys %{$data} ) {
      unless ( exists $found{$tag} ) {
         dbug_ok ( 0, "Tag '$tag' exists in the Advanced::Config object!" );
      }
   }

   DBUG_VOID_RETURN ();
}

# ====================================================================
sub init_config
{
   DBUG_ENTER_FUNC ( @_ );
   my $in_string = shift;

   my $cfg;
   my ( %rOpts, %gOpts, %dOpts );

   $rOpts{Croak} = 1;      # Call die on error.
   $gOpts{Required} = 1;   # Call die if the tag doesn't exist.

   # Did we override the read options to use with the string?
   my %oOpts;

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

