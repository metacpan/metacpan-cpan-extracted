#!/usr/bin/perl

use strict;
use warnings;

# No precount of the number of tests performed!
use Test::More;
use File::Basename;
use File::Spec;
use Fred::Fish::DBUG 2.09 qw / on /;
use Fred::Fish::DBUG::Test 2.09;

# How to find the helper module ...
BEGIN { push (@INC, File::Spec->catdir (".", "t", "test-helper")); }
use helper1234;


# Does a test of the parse routines used to parse the config file.  (overriding some defaults)
# Test focuses on tests where the sart/stop anchor char strings are the same!
# Uses hand crafted test cases against predicted restults to prove they work!

BEGIN {
   my $fish = turn_fish_on_off_for_advanced_config ();

   unlink ( $fish );

   # Turn fish on ...
   DBUG_PUSH ( $fish );

   DBUG_ENTER_FUNC ();

   DBUG_PRINT ("TEST", "\n%s\n ",
              'Performing Advanced::Config::Reader::parse_line() %var% tests!');

   use_ok ( "Advanced::Config::Reader" );
   use_ok ( "Advanced::Config::Options" );

   DBUG_VOID_RETURN ();
}


END {
   DBUG_ENTER_FUNC ();

   # Don't do this test per done_testing() logic!
   # dbug_ok (1, "In the END block!");        # Last test.

   DBUG_VOID_RETURN ();
}

# For overriding the fish mask in parse_line().
my $oTag = "DBUG_TEST_USE_CASE_PARSE_OVERRIDE";

my $opts;
my $assign;
my $anchor;

# --------------------------------------
# Start of the main program!
# --------------------------------------
{
   DBUG_ENTER_FUNC (@ARGV);

   dbug_ok (1, "In the MAIN program ...");  # Test # 3 ...

   $opts = get_read_opts ( { assign        => '==', comment        => ':',
                             variable_left => '%',  variable_right => '%',
                             quote_left    => '|',  quote_right    => '|',
                             ${oTag}       => 1
                           } );

   $assign = convert_to_regexp_string ($opts->{assign});
   $anchor = convert_to_regexp_string ($opts->{variable_left});

   dbug_ok (1, "-"x60);

   parse_tv ("Simple", "There are no comments!", "");
   parse_tv ("Simple-2", "Comments are all spaces!", "   ");

   parse_tv ("Reglar", "Value with Comment", "This is a comment");
   parse_tv ("Reglar-2", "I|m going to the park!", "I|ll go with you!");
   parse_tv ("Reglar-3", "I|m going to the park!", 'I|ll go %with% you!');

   # The Balanced Quote Tests ...
   parse_tv ("Quote-1", "|In the heat of the night|", "I|m at the park!");
   parse_tv ("Quote-2", '"In the chill of the day"', '"Killroy" was here!');

   # The Unbalanced Quote Tests ...
   parse_tv ("Unbalanced-1", "|In the heat of the night", "I|m at the park!");
   parse_tv ("Unbalanced-3", "In the heat of the night|", "I|m at the park!");

   parse_tv ("Messy-1", "|One|, |fine|, |day|", "|Sitting| |in| |a| |tree|");

   parse_tv ("Odd-1", "|Once upon a time| Hello!", "Go on!");

   # The Variable Replacement Tests ...
   parse_tv ("Var-1", 'Help me with %var1% resolve!', "");
   parse_tv ("Var-2", 'Help me with %var2% resolve!', "A constant");
   parse_tv ("Var-3", 'Help me with %var3% resolve!', 'A %variable%');
   parse_tv ("Var-4", 'Help me with %var4% & %var5% resolve!', 'A %var1% %var2%');

   # Using the wrong anchors for Variable replacements ...
   parse_tv ("Old-1", 'Help me with ${var3} resolve!', 'A ${variable}');

   # NOTE: These variable substitution tests are drastically differnt than
   #       the other 2 test scripts since when the start/stop anchors are
   #       the same, the available functionality is drastically reduced!
   #       Such as no more nested variable substitutions.
   #       And no support for variable modifiers since many of them would
   #       corrupt the variable definition!

   # NOTE: Errors only occur in these tests if there are comments with variables
   #       defined in them!

   # Corrupted Variable definitions ...
   parse_tv ("Var-Unbal-0", 'Want % %help%  %with%  %this%  %mess%?', 'Static Comment');
   parse_tv ("Var-Unbal-0", 'Want % %help%  %with%  %this%  %mess%?', "");
   parse_tv_error ("Var-Unbal-1", 'Want % %help%  %with%  %this%  %mess%?', '%Dynamic% %Comment%');
   parse_tv_error ("Var-Unbal-2", 'Want %help%  %with%  %this%  %mess% %?', '%Dynamic% %Comment%');
   parse_tv_error ("Var-Unbal-3", 'Want %help%  %with% %  %this%  %mess%?', '%Dynamic% %Comment%');

   # Corrupted Variable definitions between balanced quotes ...
   # This will parse correctly!
   parse_tv ("Var-Quotes-0", '|Want % %help%  %with%  %this%  %mess%?|', '%Dynamic% %Comment');
   parse_tv ("Var-Quotes-1", '|Want %help%  %with% % %this%  %mess%?|', '%Dynamic% %Comment');
   parse_tv ("Var-Quotes-2", '|Want %help%  %with%  %this%  %mess%? %|', '%Dynamic% %Comment');

   # Missing Variable definitions ...
   parse_tv ("Missing-1", 'Help %% me', 'Please! %%.');
   parse_tv ("Missing-2", 'Help %   % again', 'Or Not! %   %.');
   parse_tv ("Missing-3", 'Help %% again and % :-again%', 'Or Not! %   %.');

   # Since I didn't count the test cases, must end my program
   # with a call to this method.  After this we can't put any
   # tests in the END block!
   done_testing ();

   DBUG_LEAVE (0);
}

# -----------------------------------------------
sub trim
{
   my $val = shift;

   $val =~ s/^\s+//;
   $val =~ s/\s+$//;

   return ($val);
}

# -----------------------------------------------
# Does 6 tests each time called!
# (The 1st & last tests are FYI only & are always OK.)
sub parse_tv
{
   DBUG_ENTER_FUNC (@_);
   my $tag     = shift;
   my $value   = shift;
   my $comment = shift;

   # Build the line from it's parts.  So can compare against later.
   # Simulates reading a line from a config file ...
   my $line = ${tag} . " " . $opts->{assign} . " " . $value;
   if ( $comment ) {
       $line .= "      " . $opts->{comment} . " " . $comment;
   }

   # Trim so we can use these values to predict the results ...
   $tag = trim ($tag);
   $value = trim ($value);
   $comment = trim ($comment);

   dbug_ok (1, "Test: " . $line);

   my ($tv, $data, $cmt, $lq, $rq) = parse_line ( $line, $opts );

   dbug_ok ( $tv, "It's a tag/value pair!" );

   my $tag_msg = "The tag was split out correctly!";
   my $val_msg = "The value was split out correctly!";

   if ( $tv ) {
      my ( $tg, $val ) = split (/\s*${assign}\s*/, $data, 2);
      dbug_is ( $tg, $tag, "${tag_msg} ($tg)" );

      # The quote return values ($lq & $rq) are only returned if balanced quotes
      # are detected and can be removed from the value.
      if ( $lq ne "" && $val =~ m/^${lq}(.*)${rq}$/ ) {
         $val = $1;
         $value =~ s/^${lq}//;    # Removes the balanced quotes from the value!
         $value =~ s/${rq}$//;
         $val_msg .= "  Balanced Quotes are Removed.";
      }

      dbug_is ( $value, $val, "${val_msg} (${val})" );

   } else {
      dbug_ok ( 0, $tag_msg );
      dbug_ok ( 0, $val_msg );
   }

   dbug_is ( $comment, $cmt, "The comment was stripped out OK!  ($cmt)" );

   dbug_ok (1, "-"x60);

   # Returns the number of tests executed ...
   DBUG_RETURN (6);
}

# -----------------------------------------------
# Does between 1 & 6 tests.
# These are failure tests for when the start/stop variable anchors are
# the same string.  The parsing fails only when there are variable anchors
# in the comment itself.  Just no way to get arround that issue!

sub parse_tv_error
{
   DBUG_ENTER_FUNC (@_);
   my $tag     = shift;
   my $value   = shift;
   my $comment = shift;

   # Build the line from it's parts.  So can compare against later.
   # Simulates reading a line from a config file ...
   my $line = ${tag} . " " . $opts->{assign} . " " . $value;
   if ( $comment ) {
       $line .= "      " . $opts->{comment} . " " . $comment;
   } else {
      dbug_ok (0, "Programming error: Test requires a comment!");
      return DBUG_RETURN (1);
   }

   unless ( $comment =~ m/${anchor}/ ) {
      dbug_ok (0, "Programming error: Test requires a variable anchor in the comment!");
   }

   # Trim so we can use these values to predict the results ...
   $tag = trim ($tag);
   $value = trim ($value);
   $comment = trim ($comment);

   dbug_ok (1, "Test: " . $line);

   my ($tv, $data, $cmt, $lq, $rq) = parse_line ( $line, $opts );

   unless ( $lq eq "" && $rq eq "" ) {
      dbug_ok (0, "Programming error: Unexpected  balanced quotes!");
      return DBUG_RETURN (1);
   }

   dbug_ok ( $tv, "It's a tag/value pair!" );

   my $tag_msg = "The tag was split out correctly!";
   my $val_msg = "As expected, the value didn't parse out correctly!";

   if ( $tv ) {
      my ( $tg, $val ) = split (/\s*${assign}\s*/, $data, 2);
      dbug_is ( $tg, $tag, "${tag_msg} ($tg)" );
      dbug_isnt ( $value, $val, "${val_msg} (${val})" );

   } else {
      dbug_ok ( 0, $tag_msg );
      dbug_ok ( 0, $val_msg );
   }

   dbug_is ( $cmt, "", "Hit the expected issue stripping out the comment! ($cmt)" );

   dbug_ok (1, "-"x60);

   # Returns the number of tests executed ...
   DBUG_RETURN (6);
}

# -----------------------------------------------

