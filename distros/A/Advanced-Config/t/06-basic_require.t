#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use File::Basename;
use File::Spec;
use Fred::Fish::DBUG 2.09  qw / on /;
use Fred::Fish::DBUG::Test 2.09;

# How to find the helper module ...
BEGIN { push (@INC, File::Spec->catdir (".", "t", "test-helper")); }
use helper1234;

# A repeate of t/05-basic_use.t, except it uses "require" instead of "use".
# Just proving we can still create an Advanced::Config object using this
# alternate way.

BEGIN {
   my $fish = turn_fish_on_off_for_advanced_config ();

   unlink ( $fish );

   # Turn fish on ...
   DBUG_PUSH ( $fish );

   DBUG_ENTER_FUNC ();

   require Advanced::Config;

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

   dbug_ok (1, "In the MAIN program ...");  # Test # 2 ...

   my $cfg;

   eval {
      $cfg = Advanced::Config->new ();
   };

   dbug_isa_ok ( $cfg, "Advanced::Config" );
   # dbug_isa_ok ( $cfg, "Advanced::Config", "Advanced::Config->new ()" );

   DBUG_LEAVE (0);
}

# -----------------------------------------------

