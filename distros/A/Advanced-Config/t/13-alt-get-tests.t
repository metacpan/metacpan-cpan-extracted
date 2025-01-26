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

# This program validates all the various "get" methods.
# When we get to this test file we've already proved that
# the basic "get_value()" works so we're able to do a dynamic
# test instead of a static one here!

# This config file has both 4-digit year dates & 2-digit year dates in it.
# Test Config File: t/config/13-alt-get-tests.cfg

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
# Global Variables
# --------------------------------------
my $all_ok;    # Tells if any get_list_values() tests failed or not.

# --------------------------------------
# Start of the main program!
# --------------------------------------
{
   # Turn fish on ...
   DBUG_PUSH ( $fish );

   DBUG_ENTER_FUNC (@ARGV);

   dbug_ok (1, "In the MAIN program ...");  # Test # 2 ...

   my $file = File::Spec->catfile ("t", "config", "13-alt-get-tests.cfg");
   my $cfg;
   eval {
      my %gOpt = ( "required" => 2 );
      $cfg = Advanced::Config->new ($file, undef, \%gOpt);
      dbug_isa_ok ($cfg, 'Advanced::Config');
      my $ldr = $cfg->load_config ();
      dbug_ok (defined $ldr, "Advanced::Config object has been loaded into memory!");
   };
   if ( $@ ) {
      unless (defined $cfg) {
         dbug_ok (defined $cfg, "Advanced::Config object has been created!");
      }
      dbug_ok (0, "Advanced::Config object has been loaded into memory!");
      DBUG_LEAVE (3);
   }

   # So can tell when the config file finished loading in fish ...
   DBUG_PRINT ("====", "%s", "="x50);

   # --------------------------------------------------------------------------
   # If any of these initial "list" tests fail, the remaining test results are
   # unreliable.  They all assume there is a 100% pass rate here!
   # --------------------------------------------------------------------------
   dbug_ok (run_list_test ( $cfg ), "-"x24 . " All List Tests Passed " . "-"x24);

   # --------------------------------------------------------------------------
   # If the above "list" tests all pass, the tests below should be good!
   # Now let's hope they all pass!
   # --------------------------------------------------------------------------
   dbug_ok (run_hash_test ( $cfg ),     "-"x24 . " All Hash Tests Passed "           . "-"x24);
   dbug_ok (run_numeric_tests ( $cfg ), "-"x22 . " All Numeric Tests Passed "        . "-"x22);
   dbug_ok (run_boolean_tests ( $cfg ), "-"x22 . " All Boolean Tests Passed  "       . "-"x22);
   dbug_ok (run_date_tests ( $cfg ),    "-"x19 . " All Date Tests Passed (English) " . "-"x19);
   dbug_ok (run_file_tests ( $cfg ),    "-"x22 . " All Filename Tests Passed "       . "-"x22);
   dbug_ok (run_dir_tests ( $cfg ),     "-"x21 . " All Directory Tests Passed "      . "-"x22);

   # Keep last so we don't have to add a separator test.
   # Also must be kept after the file & dir tests!
   run_special_tests ( $cfg );

   # Since I didn't count the test cases, must end my program
   # with a call to this method.  Can't do tests in END anymore!
   done_testing ();

   DBUG_LEAVE (0);
}

# ====================================================================
sub run_hash_test
{
   DBUG_ENTER_FUNC ( @_ );
   my $cfg = shift;

   my $ok = 1;    # Assume all tests pass ...

   my %merge;
   my $val = 0;
   my %expected;
   foreach my $tag ( "int_one", "int_two", "int_three", "int_four", "int_two" ) {
      my $ptrn = ($tag eq "int_three") ? qr /\s*[|]\s*/ : undef;

      # This tag's value is a list of integers ...
      my $lst  = $cfg->get_list_values ($tag, $ptrn, 1);
      my $hsh  = $cfg->get_hash_values ($tag, $ptrn, ++$val, \%merge);
      my @hlst = sort { $a <=> $b } keys %{$hsh};

      # Verify the returned hash referene has the correct key list ...
      my $r = dbug_ok ( compare_arrays ( 0, $lst, \@hlst ), "Tag ${tag}'s breakup into a hash was correct! (" . join (", ", @{$lst}) . ")" );
      unless ( $r ) {
         DBUG_PRINT ( "WARN", "get_hash_values() returned (%s) as it's keys.", join (", ", @hlst) );
         $ok = 0;
         next;
      }

      # Verify the returned hash referene has the correct values ...
      foreach my $k ( @hlst ) {
         my $v = $hsh->{$k};
         if ( $v != $val ) {
            dbug_ok (0, "Tag ${tag}'s hash key ($k) has the right value!  ($val)");
            DBUG_PRINT ( "WARN", 'HASH $%s->{%s} = %s', $tag, $k, $v);
            $ok = 0;
         }
      }

      # Build the hash to test the merged hash against later on ...
      foreach ( @{$lst} ) {
         $expected{$_} = $val   unless ( exists $expected{$_} );
      }

      # Verify the merge hash has all these new entries ...
      foreach my $k ( @hlst ) {
         unless ( exists $merge{$k} ) {
            dbug_ok (0, "Tag ${tag}'s hash contained key ${k}");
            $ok = 0;
            next;
         }
         unless ( 1 <= $merge{$k} && $merge{$k} <= $val ) {
            dbug_ok (0, "Tag ${tag}'s hash value for key ${k} is between 1 and ${val} as expected!  ($merge{$k})");
            $ok = 0;
            next;
         }
      }

      foreach my $k ( keys %merge ) {
         next  if ( exists $hsh->{$k} );
         next  if ( 1 <= $merge{$k} && $merge{$k} < $val );
         my $max = $val - 1;
         dbug_ok (0, "The merge hash's value for key ${k} is between 1 and ${max} as expected!  ($merge{$k})");
         $ok = 0;
      }
   }    # foreach $tag loop ...

   # Validate the merge hash contents ...
   my @lst1 = sort { $a <=> $b } keys %expected;
   my @lst2 = sort { $a <=> $b } keys %merge;
   my $r = dbug_ok ( compare_arrays ( 0, \@lst1, \@lst2 ), "The merge hash has the correct keys!  (" . join (", ", @lst1) . ")" );
   unless ( $r ) {
      DBUG_PRINT ( "WARN", "The merge hash had these keys (%s)", join (", ", @lst2) );
      $ok = 0;
   } else {
      foreach ( @lst1 ) {
         if ( $expected{$_} ne $merge{$_} ) {
            dbug_ok (0, "The merge hash had the expected values!");
            $ok = 0;
            last;
         }
      }
   }

   DBUG_RETURN ( $ok );
}

# ====================================================================
sub run_numeric_tests
{
   DBUG_ENTER_FUNC ( @_ );
   my $cfg = shift;

   my ($guess, $real, $trunc, $round, $lbl);
   my $ans;
   my $ok = 1;

   ($guess, $real, $trunc, $round, $lbl) = get_all_numeric_values ( $cfg, "int_one" );
   $ans = 0;
   if ( $real && $trunc && $round && $guess ) {
      $ans = 1  if ( $real == $trunc && $trunc == $round && $trunc == $guess );
   }
   dbug_ok ( $ans, "${lbl} references a valid integer! ($guess)" );
   $ok = 0  unless ($ans);

   ($guess, $real, $trunc, $round, $lbl) = get_all_numeric_values ( $cfg, "int_two" );
   $ans = ( (! $real) && (! $trunc) && (! $round) && $guess ) ? 1 : 0;
   dbug_ok ( $ans, "${lbl} is not a single number! ($guess)" );
   $ok = 0  unless ($ans);

   ($guess, $real, $trunc, $round, $lbl) = get_all_numeric_values ( $cfg, "real_one" );
   $ans = ( $guess && $real && $guess == $real && $trunc && $round && $trunc == $round ) ? 1 : 0;
   dbug_ok ( $ans, "${lbl} is a floating point number, not an integer! ($guess)" );
   $ok = 0  unless ($ans);

   ($guess, $real, $trunc, $round, $lbl) = get_all_numeric_values ( $cfg, "bad_real_one" );
   $ans = ( $guess && (! $real) && (! $trunc) && (! $round) ) ? 1 : 0;
   dbug_ok ( $ans, "${lbl} is not numeric! ($guess)" );
   $ok = 0  unless ($ans);

   ($guess, $real, $trunc, $round, $lbl) = get_all_numeric_values ( $cfg, "real_1" );
   $ans = ( $guess && $real && $guess == $real && (defined $round && defined $trunc) && $round == $trunc ) ? 1 : 0;
   dbug_ok ( $ans, "${lbl} is a valid floating point number. ($guess) [$round]");
   $ok = 0  unless ($ans);

   ($guess, $real, $trunc, $round, $lbl) = get_all_numeric_values ( $cfg, "real_2");
   $ans = ( $guess && (defined $real) && (defined $round ) && (defined $trunc) ) ? 1 : 0;
   dbug_ok ( $ans, "${lbl} is a valid floating point number.  Now allows the leading digit to be missing. ($guess)" );
   $ok = 0  unless ($ans);

   ($guess, $real, $trunc, $round, $lbl) = get_all_numeric_values ( $cfg, "real_3" );
   $ans = ( $guess && (defined $real) && (defined $round ) && (defined $trunc) ) ? 1 : 0;
   dbug_ok ( $ans, "${lbl} is a valid floating point number.  Now allows the trailing digit to be missing. ($guess)" );
   $ok = 0  unless ($ans);

   ($guess, $real, $trunc, $round, $lbl) = get_all_numeric_values ( $cfg, "realb_4" );
   $ans = ( $guess && (! defined $real) && (! defined $round ) && (! defined $trunc) ) ? 1 : 0;
   dbug_ok ( $ans, "${lbl} is not a valid floating point number. ($guess)" );
   $ok = 0  unless ($ans);

   ($guess, $real, $trunc, $round, $lbl) = get_all_numeric_values ( $cfg, "realb_5" );
   $ans = ( $guess && (! defined $real) && (! defined $round ) && (! defined $trunc) ) ? 1 : 0;
   dbug_ok ( $ans, "${lbl} is not a valid floating point number. ($guess)" );
   $ok = 0  unless ($ans);

   ($guess, $real, $trunc, $round, $lbl) = get_all_numeric_values ( $cfg, "realb_6" );
   $ans = ( $guess && (! defined $real) && (! defined $round ) && (! defined $trunc) ) ? 1 : 0;
   dbug_ok ( $ans, "${lbl} is not a valid floating point number. ($guess)" );
   $ok = 0  unless ($ans);

# dbug_ok (0, "No get_list_numeric() tests ...");  return DBUG_RETURN (0);

   # The list tests ...
   $ok = 0  unless (run_numeric_list_tests ($cfg, "^int_",  "int_three"  => qr/\s*[|]\s*/));
   $ok = 0  unless (run_numeric_list_tests ($cfg, "^real_", "real_three" => qr/\s*[?]\s*/, "real_2" => "bad", "real_3" => "bad"));

   DBUG_RETURN ( $ok );
}

# ====================================================================
sub get_all_numeric_values
{
   DBUG_ENTER_FUNC ( @_ );
   my $cfg = shift;
   my $tag = shift;

   my ( $guess, $real, $trunc, $round );

   $guess = $cfg->get_value ($tag);                       # Always works!
   $real  = $cfg->get_numeric ($tag,    required => 0);   # Real number
   $trunc = $cfg->get_integer ($tag, 1, required => 0);   # Integer (truncating)
   $round = $cfg->get_integer ($tag, 0, required => 0);   # Integer (rounding)

   my $ok2_msg_prefix = "Tag ${tag}'s value";

   DBUG_RETURN ( $guess, $real, $trunc, $round, $ok2_msg_prefix );
}

# ====================================================================
sub truncate_or_round
{
   DBUG_ENTER_FUNC ( @_ );
   my $list_ref = shift;
   my $int_flag = shift;   # Always 1 (round) or -1 (truncate)

   my $cnt = @{$list_ref} - 1;

   foreach (0..${cnt}) {
      next  unless ( $list_ref->[$_] =~ m/^([-+]?\d+)[.]\d+$/ );
      if ( $int_flag < 0 ) {
         $list_ref->[$_] = $1 + 0;       # Truncated
      } else {
         $list_ref->[$_] = sprintf ("%.0f", $list_ref->[$_]);
      }
   }

   DBUG_VOID_RETURN ();
}

# ====================================================================
# Assumes all passed tags only reference valid lists of numbers!
sub run_numeric_list_tests
{
   DBUG_ENTER_FUNC ( @_ );
   my $cfg       = shift;
   my $search    = shift;    # Which tags to search for.

   # Which tags use different separators ...
   my $exception = $cfg->_get_opt_args (@_);

   my @list = $cfg->find_tags ($search);

   my $ok = 1;
   foreach my $sort ( 0, 1, -1 ) {
      my $lbl = "unsorted";
      $lbl = "sorted"  if ( $sort == 1);
      $lbl = "reverse sorted"  if ( $sort == -1);

      foreach my $tag (@list) {
         my $split = $exception->{$tag};   # Usually undef ... (the split pattern)

         next  if ( defined $split && $split eq "bad" );

         my $test = $cfg->get_list_values ($tag, $split, $sort);
         my @round_test = @{$test};
         my @trunc_test = @{$test};
         truncate_or_round ( \@round_test,  1 );
         truncate_or_round ( \@trunc_test, -1 );

         my $nValue = $cfg->get_list_numeric ( $tag, $split, $sort );
         my $tValue = $cfg->get_list_integer ( $tag, 1, $split, $sort );
         my $rValue = $cfg->get_list_integer ( $tag, 0, $split, $sort );

         my $cnt = @{$test};
         my ($a, $b, $c);
         $a = dbug_ok ( compare_arrays ( 1, $test, $nValue ), "Tag ${tag}'s list of ${cnt} ${lbl} real numbers are the same!");
         $b = dbug_ok ( compare_arrays ( 1, \@round_test, $rValue ), "Tag ${tag}'s list of ${cnt} ${lbl} rounded integers are the same!");
         $c = dbug_ok ( compare_arrays ( 1, \@trunc_test, $tValue ), "Tag ${tag}'s list of ${cnt} ${lbl} truncated integers are the same!");
         $ok = 0  unless ($a && $b && $c);
      }
   }

   DBUG_RETURN ( $ok );
}

# ====================================================================
# Checks for special file/directory names to see if recognized!
# Behaviour may be different on different OS.

sub run_special_tests
{
   DBUG_ENTER_FUNC ( @_ );
   my $cfg = shift;

   my ( $dir, $file, $get, $res );
   my $ok = 1;

   my @list = $cfg->find_tags ("^special_");

   foreach my $tag ( @list ) {
      my ($msg1, $msg2);

      $get  = $cfg->get_value ($tag);
      $dir  = $cfg->get_directory ($tag, undef, required => 0);
      $file = $cfg->get_filename ($tag, undef, required => 0);

      # Check what perl has to say about these files/dirs ...
      $msg1 = "Special file test (${get}): ";
      if ( -f $get ) {
         $res = ($file && ! $dir) ? 1 : 0;
         $msg2 = "it's a file!";
      } elsif ( -d $get ) {
         $res = (! $file && $dir) ? 1 : 0;
         $msg2 = "it's a directory!";
      } else {
         $res = (! $file && ! $dir) ? 1 : 0;
         $msg2 = "not a file or directory!";
      }

      dbug_ok ($res, ${msg1} . ${msg2});
      $ok = 0  unless ($res);
   }

   DBUG_RETURN ( $ok );
}

# ====================================================================
sub run_dir_tests
{
   DBUG_ENTER_FUNC ( @_ );
   my $cfg = shift;

   my ($dir, $f, $bad, $ok, $r, $tag);

   # The individual directory tests ...
   $dir = $cfg->get_directory ("dir_1", "r");
   $r = dbug_ok ( $dir, "Found directory: ${dir}");
   $ok = $r;

   $dir = $cfg->get_directory ("dir_2", "rx");
   $r = dbug_ok ( $dir, "Found directory: ${dir}");
   $ok = 0  unless ( $r );

   $dir = $cfg->get_directory ("dir_3", "rwx");
   $r = dbug_ok ( $dir, "Found directory: ${dir}");
   $ok = 0  unless ( $r );

   $tag = "dir_bad_2";
   $dir = $cfg->get_directory ($tag, undef, required => 0);
   $f = $cfg->get_filename ($tag);
   $bad = $cfg->get_value ($tag);
   $r = dbug_ok ( ($f && ! $dir), "It's a file, not a directory: ${bad}" );
   $ok = 0  unless ( $r );

   # ---------------------------------------------------------
   # No-such dir, create dir, no-such dir tests ...
   # ---------------------------------------------------------
   $tag = "dir_bad_1";
   $dir = $cfg->get_directory ($tag, undef, required => 0);
   $f = $cfg->get_filename ($tag, undef, required => 0);
   $bad = $cfg->get_value ($tag);
   $r = dbug_ok ( (! $dir && ! $f), "No such file or directory: ${bad}" );
   $ok = 0  unless ( $r );

   mkdir ( $bad ) or die ("Can't create directory: ${bad}\n");
   $dir = $cfg->get_directory ($tag);
   $r = dbug_ok ( ($dir && ! $f), "The directory now exists! ${bad}" );
   $ok = 0  unless ( $r );

   rmdir ( $bad );
   $dir = $cfg->get_directory ($tag, undef, required => 0);
   $r = dbug_ok ( (! $dir && ! $f), "No such file or directory again: ${bad}" );
   $ok = 0  unless ( $r );
   # ---------------------------------------------------------

   # The list tests ...
   $tag = "dir_list_1";
   my $lst = $cfg->get_list_directory ($tag, "r");
   my $ref = $cfg->get_list_values ($tag);
   $r = dbug_ok ( compare_arrays ( 0, $ref, $lst ), "The directory arrays are the same!" );
   $ok = 0  unless ( $r );

   $tag = "dir_list_2";
   $lst = $cfg->get_list_directory ($tag, undef, undef, required => 0);
   $r = dbug_ok ( (! $lst), "The list of directories contains one or more bad entries!" );
   $ok = 0  unless ( $r );

   DBUG_RETURN ( $ok );
}

# ====================================================================
sub run_file_tests
{
   DBUG_ENTER_FUNC ( @_ );
   my $cfg = shift;

   my ($file, $d, $bad, $ok, $r, $tag);

   # The individual file tests ...
   $file = $cfg->get_filename ("file_1");
   $r = dbug_ok ( $file, "Found file: ${file}");
   $ok = $r;

   $file = $cfg->get_filename ("file_2");
   $r = dbug_ok ( $file, "Found file: ${file}");
   $ok = 0  unless ( $r );

   $tag = "file_bad_2";
   $file = $cfg->get_filename ($tag, undef, required => 0);
   $bad = $cfg->get_value ($tag);
   $d = $cfg->get_directory ($tag);
   $r = dbug_ok ( ($d && ! $file), "It's a directory, not a file: ${bad}");
   $ok = 0  unless ( $r );

   # ---------------------------------------------------------
   # No-such file, create file, no-such file tests ...
   # ---------------------------------------------------------
   $tag = "file_bad_1";
   $file = $cfg->get_filename ($tag, undef, required => 0);
   $bad = $cfg->get_value ($tag);
   $d = $cfg->get_directory ($tag, undef, required => 0);
   $r = dbug_ok ( (! $file && ! $d), "No such file or directory: ${bad}");
   $ok = 0  unless ( $r );

   open (FILE, ">", $bad) or die ("Can't create file: $bad\n");
   close (FILE);
   $file = $cfg->get_filename ($tag);
   $r = dbug_ok ( ($file && ! $d), "The file now exists! ${bad}");
   $ok = 0  unless ( $r );

   unlink ( $bad );
   $file = $cfg->get_filename ($tag, undef, required => 0);
   $r = dbug_ok ( (! $file && ! $d), "No such file or directory again: ${bad}");
   $ok = 0  unless ( $r );
   # ---------------------------------------------------------

   # The list tests ...
   $tag = "file_list_1";
   my $ref = $cfg->get_list_values ($tag);
   my $lst = $cfg->get_list_filename ($tag);
   $r = dbug_ok ( compare_arrays ( 0, $ref, $lst ), "The file list arrays are the same!" );
   $ok = 0  unless ( $r );

   $tag = "file_list_2";
   $lst = $cfg->get_list_filename ($tag, undef, undef, required => 0);
   $r = dbug_ok ( (! $lst), "The list of files contains one or more bad entries!" );
   $ok = 0  unless ( $r );

   DBUG_RETURN ( $ok );
}

# ====================================================================
# Builds the boolean array to validate against!

sub run_boolean_tests
{
   DBUG_ENTER_FUNC ( @_ );
   my $cfg = shift;

   my @list = $cfg->find_tags ("^boolean_");

   my @answers;
   my ($bools, $sep, $ok, $r) = ("", "", 1, 0);
   foreach my $tag (@list) {
      my $prediction = 0;    # False
      if ( $tag =~ m/_([^_]+)$/ ) {
         $prediction = $1;   # 1 or 0 (True/False)
      }

      my $other = $cfg->get_value ( $tag );
      my $ans = $cfg->get_boolean ( $tag );
      $r = dbug_cmp_ok ($ans, '==', $prediction, "Tag ${tag} correctly evaluated '${other}' to ${prediction}");
      $ok = 0  unless ( $r );

      # Save the test results. (except the problem one!)
      if ( $other ne "" ) {
         push ( @answers, $prediction );
         $bools .= ${sep} . $other;
         $sep = " ";
      }
   }

   # Build a list of boolean values we can split and evaluate ...
   my $tag = "test_bool_list";
   $cfg->set_value ( $tag, $bools );
   my $lst = $cfg->get_list_boolean ($tag);
   my $res = join (", ", @answers);
   $r = dbug_ok ( compare_arrays ( 0, \@answers, $lst ), "The boolean arrays are the same! ($res)" );
   $ok = 0  unless ( $r );

   # Add a junk value to end of boolean list ...
   $cfg->set_value ( $tag, $bools . " An-unknown-value-is-false" );
   push ( @answers, 0 );
   $lst = $cfg->get_list_boolean ($tag);
   $res = join (", ", @answers);
   $r = dbug_ok ( compare_arrays ( 0, \@answers, $lst ), "Second boolean array test works out! ($res)");
   $ok = 0  unless ( $r );

   DBUG_RETURN ( $ok );
}

# ====================================================================
# Builds the date array to validate against!
sub run_date_tests
{
   DBUG_ENTER_FUNC ( @_ );
   my $cfg = shift;

   my @list = $cfg->find_tags ("^date_");

   # Allow 2-digit years in the test dates!
   my %opt = ( "required" => 0, "date_enable_yy" => 1, "date_format" => 3 );

   my @answers;
   my ($dates, $sep, $ok, $r) = ("", "", 1, 0);
   foreach my $tag (@list) {
      my $prediction;
      if ( $tag =~ m/^date_\d+_(\d{4}-\d{2}-\d{2})$/ ) {
         $prediction = $1;      # The resulting date ...
      } elsif ( $tag =~ m/^date_\d+_bad$/ ) {
         $prediction = "";      # Invalid Date ...
      } else {
         die ("Improperly formatted date tag: $tag  (<name>_<test-number>_<YYYY-MM-DD>) or (<name>_<test-number>_bad)\n");
      }

      my $raw = $cfg->get_value ( $tag );
      my $ans = $cfg->get_date ( $tag, undef, \%opt );

      my $chk;
      if ( $prediction ) {
         $chk = ($prediction eq $ans);
      } else {
         $chk = (! defined $ans);
      }
      $r = dbug_ok ( $chk, "Tag ${tag} correctly evaluated '${raw}' to '${prediction}'");

      unless ( $r ) {
         $ok = 0;
         next;
      }

      next  unless ( $prediction );

      push ( @answers, $prediction );   # In YYYY-MM-DD format ...
      $dates .= ${sep} . ${raw};
      $sep = " | ";
   }

   # Build a list of date values we can split and evaluate ...
   my $tag = "test_date_list";
   $cfg->set_value ( $tag, $dates );
   my $lst = $cfg->get_list_date ( $tag, qr/\s*[|]\s*/, undef, \%opt );
   my $res = join (", ", @answers);
   $res = substr ($res, 0, 40) . "...";
   $r = dbug_ok ( defined $lst && compare_arrays ( 0, \@answers, $lst ), "The date arrays are the same! ($res)" );
   $ok = 0  unless ( $r );

   $cfg->set_value ( $tag, $dates . ${sep} . "Bad-Date" );
   $lst = $cfg->get_list_date ( $tag, qr/\s*[|]\s*/, undef, \%opt );
   $res = $cfg->get_value ( $tag );
   $r = dbug_ok ( (! defined $lst), "The date array had a bad date in it! (... | Bad-Date)" );
   $ok = 0  unless ( $r );

   DBUG_RETURN ( $ok );
}

# ====================================================================
# Checks if two arrays are identical!

sub compare_arrays
{
   DBUG_ENTER_FUNC ( @_ );
   my $nbr_flg = shift;
   my $src     = shift;
   my $tst     = shift;

   my $src_cnt = @{$src};
   my $tst_cnt = @{$tst};

   my $res = ( $src_cnt == $tst_cnt ) ? 1 : 0;

   unless ( $res ) {
      DBUG_PRINT ("ERROR", "Array 1 has %d entries & Array 2 has %d entries!", $src_cnt, $tst_cnt);
   } else {
      foreach my $i (0 .. ($src_cnt - 1)) {
         my $ok = 1;

         if ( $nbr_flg ) {
            $ok = 0  if ( $src->[$i] != $tst->[$i] );

         } elsif ( $src->[$i] ne $tst->[$i] ) {
            $ok = 0;
         }

         unless ( $ok ) {
            $res = 0;
            DBUG_PRINT ("ERROR", "Index [%d] is '%s' vs '%s'.", $i, $src->[$i], $tst->[$i]);
         }
      }
   }

   DBUG_RETURN ( $res );
}

# ====================================================================
# Exhaustively tests out get_list_values()!

sub run_list_test
{
   DBUG_ENTER_FUNC ( @_ );
   my $cfg = shift;

   $all_ok = 1;     # Assume all list tests will succeed ...
                    # Only gets reset in run_one_test()!

   run_mult_tests ($cfg, 0, "one_value");
   run_mult_tests ($cfg, 0, "two_values");
   run_mult_tests ($cfg, 0, "three_values", qr /\s*,\s*/);    # Comma separated test.
   run_mult_tests ($cfg, 0, "four_values");

   run_mult_tests ($cfg, 1, "int_one");
   run_mult_tests ($cfg, 1, "int_two");
   run_mult_tests ($cfg, 1, "int_three", qr /\s*[|]\s*/);     # A pipe separated test.
   run_mult_tests ($cfg, 1, "int_four");

   run_mult_tests ($cfg, 1, "real_one");
   run_mult_tests ($cfg, 1, "real_two");
   run_mult_tests ($cfg, 1, "real_three", qr /\s*[?]\s*/);    # A question mark separated test.
   run_mult_tests ($cfg, 1, "real_four");

   run_mult_tests ($cfg, 0, "bad_real_one");
   run_mult_tests ($cfg, 0, "bad_real_two");
   run_mult_tests ($cfg, 0, "bad_real_three", qr /\s*,\s*/);  # Comma separated test.
   run_mult_tests ($cfg, 0, "bad_real_four");

   # These 4 tests now use the wrong separator ...
   run_mult_tests ($cfg, 0, "three_values");
   run_mult_tests ($cfg, 0, "int_three");
   run_mult_tests ($cfg, 0, "real_three");
   run_mult_tests ($cfg, 0, "bad_real_three");

   # More valid tests ...
   run_mult_tests ($cfg, 0, "dir_list_1");
   run_mult_tests ($cfg, 0, "dir_list_2");
   run_mult_tests ($cfg, 0, "file_list_1");
   run_mult_tests ($cfg, 0, "file_list_2");

   DBUG_RETURN ( $all_ok );
}

sub run_mult_tests
{
   DBUG_ENTER_FUNC ( @_ );
   my $cfg     = shift;
   my $num_flg = shift;
   my $tag     = shift;
   my $ptrn    = shift || qr /\s+/;

   run_one_test ( $cfg, $tag, $ptrn, 0,  $num_flg );   # No sort test ...
   run_one_test ( $cfg, $tag, $ptrn, 1,  $num_flg );   # Sorted test ...
   run_one_test ( $cfg, $tag, $ptrn, -1, $num_flg );   # Reverse sorted test ...

   DBUG_VOID_RETURN ();
}

sub run_one_test
{
   DBUG_ENTER_FUNC ( @_ );
   my $cfg  = shift;
   my $tag  = shift;
   my $ptrn = shift || qr /\s+/;
   my $srt  = shift || 0;
   my $nflg = shift || 0;   # 1 if the entire list is numbers, else 0!

   # Getting the value to test against never fails!
   my $value = $cfg->get_value ($tag);
   my @gList = split ( $ptrn, $value );
   my $lbl = "unsorted";

   if ( $srt ) {
      if ( $nflg ) {
         @gList = sort { $a <=> $b } @gList;
      } else {
         @gList = sort ( @gList );
      }
      $lbl = "sorted";
      if ( $srt < 0 ) {
         @gList = reverse ( @gList );
         $lbl = "descending sort";
      }
   }

   # This one should never fail either ...
   my $lValRef = $cfg->get_list_values ($tag, $ptrn, $srt);

   my $r = dbug_ok ( compare_arrays ( 0, \@gList, $lValRef ), "Tag ${tag}'s breakup into a ${lbl} array was correct! (" . join (", ", @gList) . ")" );
   unless ( $r ) {
      DBUG_PRINT ( "WARN", "get_list_values() returned (%s)", join (", ", @{$lValRef}) );
      $all_ok = 0;    # We have a failure!
   }

   DBUG_VOID_RETURN ();
}

