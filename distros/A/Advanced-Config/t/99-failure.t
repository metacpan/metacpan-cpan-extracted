#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;
use File::Basename;
use File::Spec;
use Fred::Fish::DBUG 2.09 qw / on /;
use Fred::Fish::DBUG::Test 2.09;

# How to find the helper module ...
BEGIN { push (@INC, File::Spec->catdir (".", "t", "test-helper")); }
use helper1234;

# Only present to fully test out  full_developer_test.pl.src ...
# Used by that program to test out error reporting in various combinations.

BEGIN {
   my $fish = turn_fish_on_off_for_advanced_config ();

   unlink ( $fish );

   # Turn fish on ...
   DBUG_PUSH ( $fish );

   DBUG_ENTER_FUNC ();

   use_ok ( "Advanced::Config" );       # Test # 2

   DBUG_VOID_RETURN ();
}


END {
   DBUG_ENTER_FUNC ();
   dbug_ok (1, "In the END block!");        # Test # 4
   DBUG_VOID_RETURN ();
}

# --------------------------------------
# Start of the main program!
# --------------------------------------
{
   DBUG_ENTER_FUNC (@ARGV);

   # Only set via:   full_developer_test.pl.src
   my $pass = ( $ENV{FAIL_TEST_99} ) ? 0 : 1;

   dbug_ok ($pass, "In the MAIN program ...");  # Test # 3 ...

   DBUG_LEAVE (0);
}

