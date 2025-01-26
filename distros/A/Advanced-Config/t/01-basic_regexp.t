#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 11;
use File::Basename;
use File::Spec;
use Fred::Fish::DBUG 2.09 qw / on /;
use Fred::Fish::DBUG::Test 2.09;

# Tests a core regularly used low level function from Options.pm

BEGIN {
   # How to find the helper module ...
   push (@INC, File::Spec->catdir (".", "t", "test-helper"));

   # Must include after updating @INC ...
   # doing: "use helper1234;" doesn't work!
   my $res = use_ok ("helper1234");     # Test # 1
   unless ( $res ) {
      dbug_BAIL_OUT ("Can't load the test helper module ...\n");
   }

   my $fish = turn_fish_on_off_for_advanced_config ();

   unlink ( $fish );

   # Turn fish on ...
   DBUG_PUSH ( $fish );

   DBUG_ENTER_FUNC ();

   DBUG_PRINT ("TEST", "\n%s\n ",
     "Performing Advanced::Config::Options::convert_to_regexp_string() tests!");

   use_ok ( "Advanced::Config::Options" )  or
       dbug_BAIL_OUT ("Can't load Advanced::Config::Options");

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
   DBUG_PRINT ("----", "%s", "-"x60);

   # Tests without any special RegExp chars in it ...
   regexp_test (1, "Hello Bob!");
   DBUG_PRINT ("----", "%s", "-"x60);
   regexp_test (1, "@ ## !");
   DBUG_PRINT ("----", "%s", "-"x60);

   # Tests with special RegExp chars in it ...
   regexp_test (0, "Hello Bob[s]!");
   DBUG_PRINT ("----", "%s", "-"x60);

   regexp_test (0, 'Hello.World? Have you any Money $$?');
   DBUG_PRINT ("----", "%s", "-"x60);

   regexp_test (0, '(one) [${fine}] day.  Carrots(^) + Stars{*} 4 all?');
   DBUG_PRINT ("----", "%s", "-"x60);

   regexp_test (0, 'Here is a list of special chars: *, ., +, ?, ^, |, $, \\, (), {}, []\n');
   DBUG_PRINT ("----", "%s", "-"x60);

   regexp_test (0, "Pretty in Pink/Blue\\Green#Yellow!");
   DBUG_PRINT ("----", "%s", "-"x60);

   DBUG_LEAVE (0);
}

# -----------------------------------------------
# Does only 1 test each time called!
# The special chars are: * . + ? ^ | $ \
# The special brackets are: (), {}, []
# The above list may be incomplete.

# The "#" char is not special to RegEx, but it is special
# to Test::More::ok.
#   ok(1, "abc#xyz") ==> prints it as ==> "abc\#xyz".

sub regexp_test
{
   my $no_flg = shift;   # 1 - No regexp chars, 0 - Had regexp chars.
   my $test   = shift;

   my $reg = convert_to_regexp_string ( $test );

   if ( $reg eq $test ) {
      dbug_ok ($no_flg, "String had no special RegExp chars inside of it! (${test})");
      return;
   }

   my $match = "-- ${test} --";

   my $msg = "Regular expression test passed! (${test}) vs (${reg})";
   if ( $match =~ m/^-- ${reg} --$/ ) {
      dbug_ok ( 1, $msg );
   } else {
      dbug_ok ( 0, $msg );
   }

   return;
}

# -----------------------------------------------

