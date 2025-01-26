#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 4;
use File::Basename;
use File::Spec;
use Fred::Fish::DBUG 2.09 qw / on /;
use Fred::Fish::DBUG::Test 2.09;

# How to find the helper module ...
BEGIN { push (@INC, File::Spec->catdir (".", "t", "test-helper")); }
use helper1234;

# Just proves we can successfully create an Advanced::Config object!
# This is the 1st time we attempted to do so.  Earlier tests just
# checked out internals and basic compile time tests.

BEGIN {
   my $fish = turn_fish_on_off_for_advanced_config ();

   unlink ( $fish );

   # Turn fish on ...
   DBUG_PUSH ( $fish );

   DBUG_ENTER_FUNC ();

   use_ok ( "Advanced::Config" );    # Test # 2

   DBUG_VOID_RETURN ();
}


END {
   DBUG_ENTER_FUNC ();
   dbug_ok (1, "In the END block!");        # Last test.
   DBUG_VOID_RETURN ();
}

# --------------------------------------
# Start of the main program!
# --------------------------------------
{
   DBUG_ENTER_FUNC (@ARGV);

   dbug_ok (1, "In the MAIN program ...");  # Test # 3 ...

   my $cfg;

   eval {
      $cfg = Advanced::Config->new ();
   };

   dbug_isa_ok ( $cfg, "Advanced::Config" );

   DBUG_LEAVE (0);
}

# -----------------------------------------------

