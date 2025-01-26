#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Fred::Fish::DBUG;
use File::Spec;
use File::Basename;

# This test case basically just loads all the various modules that
# make up this release!

my $fish;

# Check versions of external dependancies ...
BEGIN {
   my $ver = 2.09;
   eval {
      Fred::Fish::DBUG->VERSION ( $ver );
   };
   if ( $@ ) {
      BAIL_OUT ("Advanced::Config requires Fred::Fish::DBUG to be at version ${ver} or later.");
      exit (0);
   }

   $ver = 0.88;
   eval {
      Test::More->VERSION ( $ver );
   };
   if ( $@ ) {
      BAIL_OUT ("The Advanced::Config test suite requires Test::More to be at version ${ver} or later.");
      exit (0);
   }
}

# Check if we can load each of the modules that make up this package!
BEGIN {
   # Done this way due to the version check above,
   unless (use_ok ("Fred::Fish::DBUG::Test")) {
      done_testing ();
      BAIL_OUT ("Can't load the Fred::Fish::DBUG::Test module.");
      exit (0);
   }

   # The stuff we really want to test.
   push (@INC, File::Spec->catdir (".", "t", "test-helper"));

   unless (use_ok ("helper1234")) {
      sbug_BAIL_OUT ("Can't load the test helper module.");
   }

   $fish = turn_fish_on_off_for_advanced_config ();

   use_ok ( "Advanced::Config::Examples" ) or
                   dbug_BAIL_OUT ("Can't load Advanced::Config::Examples");
   use_ok ( "Advanced::Config::Date" )     or
                   dbug_BAIL_OUT ("Can't load Advanced::Config::Date");
   use_ok ( "Advanced::Config::Options" )  or
                   dbug_BAIL_OUT ("Can't load Advanced::Config::Options");
   use_ok ( "Advanced::Config::Reader" )   or
                   dbug_BAIL_OUT ("Can't load Advanced::Config::Reader");
   use_ok ( "Advanced::Config" )           or
                   dbug_BAIL_OUT ("Can't load Advanced::Config");
}


# Start of main program.  Doesn't really test anything.
# Just dumps all %ENV values to fish.

DBUG_PUSH ($fish);

DBUG_ENTER_FUNC (@ARGV);

# Dumps all environment variables to the screen & fish ...
foreach ( sort keys %ENV ) {
   my $txt = sprintf ("%-10s = \"%s\"", $_, $ENV{$_});
   dbug_ok (1, $txt);
}

done_testing();

DBUG_LEAVE (0);

