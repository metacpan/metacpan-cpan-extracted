#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use File::Basename;
use File::Spec;
use File::Glob qw (bsd_glob);
use Fred::Fish::DBUG 2.09 qw ( on );
use Fred::Fish::DBUG::Test 2.09;

# How to find the helper module ...
BEGIN { push (@INC, File::Spec->catdir (".", "t", "test-helper")); }
use helper1234;

# ---------------------------------------------------------------------
# Automatically creates a config file with all Date::Languages in use.
# It doesn't use the tools Advanced::Config has to give me more
# direct control on how the config file is created.  Also when originally
# created those tools hadn't been created yet.
# ---------------------------------------------------------------------
# After the config file has been created it attempts to use the
# Config object to validate everything works.
# ---------------------------------------------------------------------

my $fish;
my $config_file_normal;
my $config_file_wide;
my @global_languages;
my @global_lang_use_utf8;
my $run_as_developer = 0;

BEGIN {
   # The config file this program is to create!
   $config_file_normal = File::Spec->catfile (dirname ($0), "config", "75-all_languages_normal.cfg");
   $config_file_wide   = File::Spec->catfile (dirname ($0), "config", "75-all_languages_wide.cfg");
   unlink ( $config_file_normal, $config_file_wide );

   $fish = turn_fish_on_off_for_advanced_config ();

   unlink ( $fish );

   DBUG_ENTER_FUNC ();

   use_ok ("Advanced::Config");

   DBUG_VOID_RETURN ();

   # Turn fish on ...
   DBUG_PUSH ( $fish, allow_utf8 => 1 );

   $run_as_developer = $ENV{FULL_75_TEST} ? 1 : 0;
}

# Just proving it's a red herring.
sub uses_utf8_module
{
   my $file  = shift;

   my $found = 0;
   unless ( open (FH, "<", $file) ) {
      dbug_ok (0, "Can't open the language file for reading: " . $file);
      done_testing ();
      DBUG_LEAVE (0);
   }

   while (<FH>) {
      if ( $_ =~ m/^\s*use\s+utf8\s*;/ ) {
         $found = 1;
         last;
      }
   }

   close (FH);

   return ($found);
}

BEGIN
{
   DBUG_ENTER_FUNC ();

   eval {
      require Date::Language;
      Date::Language->import ();
   };
   if ($@) {
      dbug_ok (1, "Date::Language is not installed.  Skipping this test!");
      done_testing ();
      DBUG_LEAVE (0);
   }

   # Lookup where to find the Language modules ...
   my $key = File::Spec->catfile ("Date", "Language") . ".pm";
   my $lang_dir = $INC{$key};
   $lang_dir = $INC{'Date/Language.pm'}   unless ($lang_dir);
   $lang_dir =~ s/[.]pm$//;
   my $search = File::Spec->catdir ($lang_dir, "*.pm");

   # Get's the list of languages supported.
   foreach my $f ( bsd_glob ($search) ) {
      my @dirs = File::Spec->splitdir ($f);
      $dirs[-1] =~ s/[.]pm//;
      push (@global_languages, $dirs[-1]);
      push (@global_lang_use_utf8, uses_utf8_module ($f));
   }

   if ( $#global_languages == -1 ) {
      dbug_ok (1, "No Date::Language::<lang> modules are installed.  Skipping this test!");
      done_testing ();
      DBUG_LEAVE (0);
   }

   # Now load all those modules ...
   foreach my $l ( @global_languages ) {
      my $module = "Date::Language::${l}";
      use_ok ($module);
   }

   DBUG_VOID_RETURN ();
}

END {
   DBUG_ENTER_FUNC ();
   # Don't do any tests in the END block ...
   DBUG_VOID_RETURN ();
}

sub my_warn
{
   my $msg = shift;
   chomp ($msg);
   unless ( $msg =~ m/^Wide character in print/ ) {
      dbug_ok (0, "Warning encountered - $msg");
   }
}

sub my_die
{
   my $msg = $_[0];
   chomp ($msg);
   dbug_ok (0, "Die encountered - $msg");
   done_testing ();
   die ( $_[0] );
}

# ====================================================================
# Start of the main program!
# ====================================================================
{
   DBUG_ENTER_FUNC (@ARGV);

   $SIG{__WARN__} = \&my_warn;
   $SIG{__DIE__}  = \&my_die;

   dbug_ok (1, "In the MAIN program ...");  # Test # 2 ...

   my $language_data = load_all_language_data ();
   my $cnt = keys %{$language_data};
   dbug_ok (1, "Loaded ${cnt} languages ...");

   dbug_ok (1, "----------------- Building the cfg files ------------------");

   unless ( dbug_ok ( build_config_file ( $language_data, 0 ),
                     "The normal config file was successfully built!" ) ) {
      done_testing ();
      DBUG_LEAVE (3);
   }

   unless ( dbug_ok ( build_config_file ( $language_data, 1 ),
                     "The UTF8 config file was successfully built!" ) ) {
      done_testing ();
      DBUG_LEAVE (3);
   }

   dbug_ok (1, "----------------- Loading into memory ---------------------");

   my $cfg1 = build_new_object ( 0, "Initial", 1, $config_file_normal );
   my $cfg2 = build_new_object ( 1, "Initial", 1, $config_file_wide );

   my $status = $cfg1->encrypt_config_file ();
   dbug_is ( $status, 1, "The normal encryption status was ${status}" );

   $status = $cfg2->encrypt_config_file ();
   dbug_is ( $status, 1, "The UTF-8 encryption status was ${status}" );

   my $cfg3 = build_new_object ( 0, "Encrypted", 1, $config_file_normal );
   my $cfg4 = build_new_object ( 1, "Encrypted", 1, $config_file_wide );

   $status = $cfg1->decrypt_config_file ();
   dbug_is ( $status, 1, "The normal decryption status was ${status}" );

   $status = $cfg2->decrypt_config_file ();
   dbug_is ( $status, 1, "The UTF-8 decryption status was ${status}" );

   my $cfg5 = build_new_object ( 0, "Decrypted", 1, $config_file_normal );
   my $cfg6 = build_new_object ( 1, "Decrypted", 1, $config_file_wide );

   dbug_ok (1, "----------------- Regular ---------------------------------");
   validate_MoY_MoYs ( $cfg1 );
   validate_dates ( $cfg1, 0 );
   dbug_ok (1, "----------------- UTF-8 -----------------------------------");
   validate_MoY_MoYs ( $cfg2 );
   validate_dates ( $cfg2, 1 );

   dbug_ok (1, "----------------- Regular Encrypted -----------------------");
   dbug_ok ( compare_objects ( $cfg1, $cfg3 ),
             "Both normal objects are the same!" );
   dbug_ok (1, "----------------- UTF-8 Encrypted -------------------------");
   dbug_ok ( compare_objects ( $cfg2, $cfg4 ),
             "Both UTF-8 objects are the same!" );

   dbug_ok (1, "----------------- Regular Decrypted -----------------------");
   dbug_ok ( compare_objects ( $cfg1, $cfg5 ),
             "Both normal objects are the same!" );
   dbug_ok (1, "----------------- UTF-8 Decrypted -------------------------");
   dbug_ok ( compare_objects ( $cfg2, $cfg6 ),
             "Both UTF-8 objects are the same!" );
   dbug_ok (1, "---------------------- Done! ------------------------------");

   # Since I didn't count the test cases, must end my program
   # with a call to this method.  Can't do tests in END anymore!
   done_testing ();

   DBUG_LEAVE (0);
}

# --------------------------------------------------------------------
# Create a new Advanced::Config objact ...
# --------------------------------------------------------------------
sub build_new_object
{
   DBUG_ENTER_FUNC (@_);
   my $mode_utf8 = shift;     # 0 or 1.
   my $lbl       = shift;     # Initial, Encrypted or Decrypted
   my $pause     = shift;     # 0 or 1.
   my $file      = shift;

   my $cfg = Advanced::Config->new ( $file,
                                     { croak => 1,    use_utf8 => $mode_utf8,
                                       dbug_test_use_case_parse_override  => 1,
                                       dbug_test_use_case_hide_override   => 1,
                                       disable_variable_modifiers => 1 },
                                     { required => 0, date_enable_yy => 1 },
                                     { }
                                   );

   my $type = $mode_utf8 ? "UTF-8" : "normal";
   dbug_isa_ok ( $cfg, "Advanced::Config" );
   dbug_isa_ok ( pause_load ($cfg, $pause), "Advanced::Config" );

   DBUG_RETURN ( $cfg );
}

# --------------------------------------------------------------------
sub pause_load
{
   DBUG_ENTER_FUNC (@_);
   my $cfg   = shift;
   my $pause = shift;

   DBUG_PAUSE ()  if ( $pause );

   DBUG_RETURN ( $cfg->load_config () );
}

# --------------------------------------------------------------------
# Compares 2 Advanced::Config objects and verify they are the same!
# Stops on any error encountered.
# --------------------------------------------------------------------
sub compare_objects
{
   DBUG_ENTER_FUNC (@_);
   my $cfg_src = shift;
   my $cfg_dst = shift;

   DBUG_PAUSE ()  unless ( $run_as_developer );

   my @src = $cfg_src->find_sections ();
   my @dst = $cfg_src->find_sections ();
   unless (dbug_is ( $#src, $#dst, "Both objects have the same number of sections in them!" )) {
      return DBUG_RETURN (0);
   }

    my $stop = 0;
   foreach (@src) {
      my $sCfg1 = $cfg_src->get_section ( $_ );
      my $sCfg2 = $cfg_dst->get_section ( $_ );

      my $sts = ( $sCfg1 && $sCfg2 ) ? 1 : 0;
      unless (dbug_ok ($sts, "Section '$_' exists in both objects!")) {
         $stop = 1;
         last;
      }

      my @tags1 = $sCfg1->find_tags ();
      my @tags2 = $sCfg2->find_tags ();
      unless (dbug_is ( $#tags1, $#tags2, "Both copies of section '$_' have the same number of tags in them!")) {
         $stop = 1;
         last;
      }

      foreach my $t (@tags1) {
         my $val1 = $sCfg1->get_value ($t);
         my $val2 = $sCfg2->get_value ($t);
         $sts = ( defined $val2 && $val1 eq $val2 ) ? 1 : 0;
         unless ( dbug_ok ($sts, "Tag '$t' in both objects have the same value ($val1) ($val2)" ) ) {
            $stop = 1;
         }
      }
      last  if ( $stop );
   }

   DBUG_RETURN ( $stop ? 0 : 1 );
}

# --------------------------------------------------------------------
# Now onto validating we can read the config file we created ...
# --------------------------------------------------------------------
sub test_array
{
   my $cfg    = shift;
   my $lbl    = shift;
   my $lang   = shift;
   my $tag    = shift;
   my $months = shift;   # Ref to MoY or MoYs ...

   my ($bad, $good) = (0, 0);
   if ( $tag =~ m/^(.?)MoY.*_(\d+)$/ ) {
      my ($special, $idx) = ($1, $2);
      my ($val1, $val2);

      $val1 = $cfg->get_value ($tag);
      if ( $special eq "l" ) {
         $val2 = lc ($months->[$idx]);
      } elsif ( $special eq "u" ) {
         $val2 = uc ($months->[$idx]);
      } else {
         $val2 = $months->[$idx];
      }

      if ( $val1 ne $val2 ) {
         my ($u1, $u2) = (utf8::is_utf8($val1)||0, utf8::is_utf8($val2)||0);
         dbug_ok (0, "Loaded ${lbl} [${idx}] ok! ($val1) vs ($val2) - utf8($u1 vs $u2)");
         ++$bad;
      }
      ++$good;
   } else {
      ++$bad
   }

   return ( $bad );
}

# --------------------------------------------------------------------
# Validates that reading/writing to the config file doesn't introduce issues.
sub validate_MoY_MoYs
{
   DBUG_ENTER_FUNC (@_);
   my $cfg = shift;

   my $fatal = 0;

   DBUG_PAUSE ()  unless ( $run_as_developer );

   foreach ( $cfg->find_sections () ) {
      my $sCfg = $cfg->get_section ( $_, 1 );
      my $lang = $sCfg->get_value ("Language", {required => 0});
      unless ( defined $lang ) {
         dbug_ok (1, "Skipping section '${_}' due to no Language tag!");
         next;
      }

      my %data = ( Language => $lang, Module => "Date::Language::${lang}" );
      my ($MoY_ref, $MoYs_ref) = Advanced::Config::Date::_swap_lang_common ( \%data, 0, 1 );

      foreach my $tag ( $sCfg->find_tags (qr /^MoY_/, 0) ) {
         $fatal += test_array ($sCfg, "MoY", $lang, $tag, $MoY_ref );
      }

      foreach my $tag ( $sCfg->find_tags (qr /^MoYs_/, 0) ) {
         $fatal += test_array ($sCfg, "MoYs", $lang, $tag, $MoYs_ref );
      }

      foreach my $tag ( $sCfg->find_tags (qr /^uMoY_/, 0) ) {
         $fatal += test_array ($sCfg, "MoY-u", $lang, $tag, $MoY_ref );
      }

      foreach my $tag ( $sCfg->find_tags (qr /^uMoYs_/, 0) ) {
         $fatal += test_array ($sCfg, "MoYs-u", $lang, $tag, $MoYs_ref );
      }

      foreach my $tag ( $sCfg->find_tags (qr /^lMoY_/, 0) ) {
         $fatal += test_array ($sCfg, "MoY-l", $lang, $tag, $MoY_ref );
      }

      foreach my $tag ( $sCfg->find_tags (qr /^lMoYs_/, 0) ) {
         $fatal += test_array ($sCfg, "MoYs-l", $lang, $tag, $MoYs_ref );
      }
   }

   if ($fatal) {
      done_testing ();
      DBUG_LEAVE (11);
   }

   DBUG_VOID_RETURN ();
}

# --------------------------------------------------------------------
sub validate_dates
{
   DBUG_ENTER_FUNC (@_);
   my $cfg           = shift;
   my $utf8_expected = shift;

   DBUG_PAUSE ()  unless ( $run_as_developer );

   foreach my $s ( $cfg->find_sections () ) {
      my $sCfg = $cfg->get_section ( $s, 1 );
      my $lang = $sCfg->get_value ("Language", {required => 0});
      unless ( defined $lang ) {
         dbug_ok (1, "Skipping section '$s' due to no Language tag!");
         next;
      }

      my $tmp = $lang;
      # $tmp = Advanced::Config::Date::swap_language ($lang);
      if ( $tmp ne $lang ) {
         dbug_ok (0, "Language was changed to ${lang}");
         next;
      }
      dbug_ok (1, "Validating dates for language ${lang} ...");

      # Validate the weekdays ...
      my $wd = $sCfg->get_list_values ("WeekDays", qr/\s*,\s*/,  undef, {required => 1});
      my $cnt = @{$wd};
      $cnt = 7  if ( $cnt == 8 && $wd->[0] eq $wd->[-1] );
      dbug_is ( $cnt, 7, "Found 7 weekdays defined by tag 'WeekDays' ($cnt)" );

      foreach my $tag ( @{$wd} ) {
         my $val = $sCfg->get_value ($tag) || "";
         DBUG_PRINT ("UTF8", "utf8 flag (%d)", utf8::is_utf8($val));

         my $ok = ($val =~ m/^Found /) ? 1 : 0;
         dbug_ok ($ok, "Found Weekday Tag ($tag): ${val}");
      }

      # Validate the date itself ...
      foreach my $tag ( $sCfg->find_tags (qr /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/, 0) ) {
         my $val1 = $sCfg->get_value ($tag);
         DBUG_PRINT ("UTF8", "utf8 flag (%d)", utf8::is_utf8($val1));
         my $val2 = $sCfg->get_date ($tag, $lang, date_language_warn => 0);
         if ( $val2 && $val2 eq $tag ) {
            dbug_ok (1, "Found tag: ${tag} in section '${s}' for ${lang} --> ${val2} -- ${val1}");
         } else {
            dbug_ok (0, "Tag ${tag} in section '${s}' for ${lang} points to a valid date: ${val1}");
         }
      }
      DBUG_PRINT ("----", "-------------------------------------------------");
   }

   DBUG_VOID_RETURN ();
}

# ====================================================================
# From here on down deals with creating the config file.
# ====================================================================
sub build_config_file
{
   DBUG_ENTER_FUNC (@_);
   my $all_languages = shift;
   my $wide_flag     = shift;

   my $file = $wide_flag ? $config_file_wide : $config_file_normal;

   unless ( open (CONFIG, ">", $file) ) {
      dbug_ok (0, "Creating the UTF-8 config file: $file");
      return DBUG_RETURN (0);
   }

   my $msg;
   if ( $wide_flag ) {
      dbug_ok (1, "Creating the UTF-8 config file: $file");
      binmode (CONFIG, "encoding(UTF-8)");   # Converts to wide-char / Unicode output.
      $msg = "This file was created using UTF-8 Encoding";
   } else {
      dbug_ok (1, "Creating the normal config file: $file");
      $msg = "This file was created without any special Encoding";
   }

   print CONFIG "\n";
   print CONFIG "# This is an auto-genearted config file.\n";
   print CONFIG "# Do not modify it by hand!\n\n";
   print CONFIG "# ${msg}\n\n";

   my $englishDoW = $all_languages->{English}->{DoW};

   foreach my $lang ( sort keys %{$all_languages} ) {
      my $l = $all_languages->{$lang};

      next  if ( $l->{wide} && ! $wide_flag );

      print CONFIG "[ $lang ]\n";
      print CONFIG "    Language = $lang\n";     # To preserve the case...
      print CONFIG "    Wide = $l->{wide}\n";
      print CONFIG "    WeekDays = ", join (",  ", @{$l->{DoW}}), "\n\n";

      foreach ( 0..6 ) {
         print CONFIG "    $l->{DoW}->[$_] = Found $englishDoW->[$_] in ${lang}  ($l->{DoW}->[$_])\n";
      }
      print CONFIG "\n";

      # ---------------------------
      # The 4 digit years ....
      # ---------------------------
      foreach ( 1..12 ) {
         print CONFIG build_date (0, 2018,  $_,  $_ + 1, $l, $lang);
      }
      print CONFIG "\n";

      foreach ( 1..12 ) {
         print CONFIG build_date (1, 2019,  $_,  $_ + 14, $l, $lang);
      }
      print CONFIG "\n";

      # ----------------------------------------------------------
      # The 2 digit years .... Use 199x years to avoid ambiguity
      # ----------------------------------------------------------
      foreach ( 1..12 ) {
         print CONFIG build_date (2, 1998,  $_,  $_ + 2, $l, $lang);
      }
      print CONFIG "\n";

      foreach ( 1..12 ) {
         print CONFIG build_date (3, 1999,  $_,  $_ + 15, $l, $lang);
      }
      print CONFIG "\n";
   }

   print CONFIG "----------------------------------------------------------\n\n";

   # These extra sections are for advanced checks ...
   # Using variables and Encryption ...
   my $cntr = 0;
   foreach my $lang ( "Chinese", "Greek", "Russian" ) {
      my $l = $all_languages->{$lang};

      next  unless ( defined $l );
      next  if ( $l->{wide} && ! $wide_flag );

      ++$cntr;
      print CONFIG "[ ZZ Extra ${cntr} ]\n";
      print CONFIG "    Language = \${$lang.Language}\n";
      print CONFIG "    Wide = \${$lang.Wide}\n";
      print CONFIG "    WeekDays = \${$lang.WeekDays}\n\n";

      foreach ( 0..6 ) {
         my $wd = $l->{DoW}->[$_];
         print CONFIG "    $wd = \${$lang.$wd}      # ENCRYPT\n";
      }
      print CONFIG "\n";

      foreach ( 1..12 ) {
         my $dt = sprintf ("%04d-%02d-%02d", 2018, $_, $_ + 1);
         print CONFIG "    ${dt} = \${$lang.$dt}      # ENCRYPT\n";
      }
      print CONFIG "\n";
      foreach ( 1..12 ) {
         my $dt = sprintf ("%04d-%02d-%02d", 2019, $_, $_ + 14);
         print CONFIG "    ${dt} = \${$lang.$dt}      # ENCRYPT\n";
      }
      print CONFIG "\n";
      foreach ( 1..12 ) {
         my $dt = sprintf ("%04d-%02d-%02d", 1998, $_, $_ + 2);
         print CONFIG "    ${dt} = \${$lang.$dt}      # ENCRYPT\n";
      }
      print CONFIG "\n";
      foreach ( 1..12 ) {
         my $dt = sprintf ("%04d-%02d-%02d", 1999, $_, $_ + 15);
         print CONFIG "    ${dt} = \${$lang.$dt}      # ENCRYPT\n";
      }
      print CONFIG "\n";
   }

   print CONFIG "----------------------------------------------------------\n\n";

   # So can validate we have no issues writing foreign languages to a
   # file and reading them back out again!
   foreach my $lang ( sort keys %{$all_languages} ) {
      my $l = $all_languages->{$lang};

      next  if ( $l->{wide} && ! $wide_flag );

      print CONFIG "[ $lang ]\n";
      foreach ( 0..11 ) {
         print CONFIG "MoY_${_} = $l->{MoY}->[$_]    # ENCRYPT\n";
      }
      print CONFIG "\n";
      foreach ( 0..11 ) {
         print CONFIG "MoYs_${_} = $l->{MoYs}->[$_]    # ENCRYPT\n";
      }
      print CONFIG "\n";

      # The status to use for the dbug_ok() tests in the following loop ...
      # Done this way so I can easily flip the switch to cause failed
      # tests during debugging this lc(uc(month)) issue!
      my $ok_tst = 1;
      my $ok_msg = $ok_tst ? "failed" : "worked";

      foreach ( 0..11 ) {
         my $uc1 = uc ($l->{MoY}->[$_]);
         my $uc2 = uc ($l->{MoYs}->[$_]);
         my $lc1 = lc ($l->{MoY}->[$_]);
         my $lc2 = lc ($l->{MoYs}->[$_]);

         # Search for upper case issues ...
         my ($p1, $p2, $p3, $p4) = ("", "", "", "");
         if ( uc($lc1) ne $uc1 ) {
            my $t = uc($lc1);
            my ($u1, $u2) = (utf8::is_utf8($uc1)||0, utf8::is_utf8($t)||0);
            dbug_ok ($ok_tst, "${lang}: Force uppercase on MoY[$_] ${ok_msg}.  ($uc1, $t) utf8($u1,$u2)");
            $p1 = " - Has problem? ($lang)";
            if ( $uc1 ne lc ($uc1) ) {
               dbug_ok ($ok_tst, "${lang}: Force uppercase on uc(uc(MoY[$_])) ${ok_msg}.\n");
            }
         }

         if ( uc($lc2) ne $uc2 ) {
            my $t = uc($lc2);
            my ($u1, $u2) = (utf8::is_utf8($uc2)||0, utf8::is_utf8($t)||0);
            dbug_ok ($ok_tst, "${lang}: Force uppercase on MoYs[$_] ${ok_msg}.  ($uc2, $t) utf8($u1,$u2)");
            $p2 = " - Has problem? ($lang)";
            if ( $uc2 ne lc ($uc2) ) {
               dbug_ok ($ok_tst, "${lang}: Force uppercase on uc(uc(MoYs[$_])) ${ok_msg}.\n");
            }
         }

         # Search for lower case issues ...
         if ( lc($uc1) ne $lc1 ) {
            my $t = lc($uc1);
            my ($u1, $u2) = (utf8::is_utf8($lc1)||0, utf8::is_utf8($t)||0);
            dbug_ok ($ok_tst, "${lang}: Force lowercase on MoY[$_] ${ok_msg}.  ($lc1, $t) utf8($u1,$u2)");
            $p3 = " - Has problem? ($lang)";
            if ( $lc1 ne lc ($lc1) ) {
               dbug_ok ($ok_tst, "${lang}: Force lowercase on lc(lc(MoY[$_])) ${ok_msg}.\n");
            }
         }

         if ( lc($uc2) ne $lc2 ) {
            my $t = lc($uc2);
            my ($u1, $u2) = (utf8::is_utf8($lc2)||0, utf8::is_utf8($t)||0);
            dbug_ok ($ok_tst, "${lang}: Force lowercase on MoYs[$_] ${ok_msg}.  ($lc2, $t) utf8($u1,$u2)");
            $p4 = " - Has problem? ($lang)";
            if ( $lc2 ne lc ($lc2) ) {
               dbug_ok ($ok_tst, "${lang}: Force lowercase on lc(lc(MoYs[$_])) ${ok_msg}.\n");
            }
         }

         # Write to the config file ...
         print CONFIG sprintf ("uMoY_%d  = %s     # utf8 (%d)%s  %s\n",
                               $_, $uc1, utf8::is_utf8($uc1) || 0, $p1, "ENCRYPT");
         print CONFIG sprintf ("uMoYs_%d = %s     # utf8 (%d)%s  %s\n",
                               $_, $uc2, utf8::is_utf8($uc2) || 0, $p2, "ENCRYPT");
         print CONFIG sprintf ("lMoY_%d  = %s     # utf8 (%d)%s  %s\n",
                               $_, $lc1, utf8::is_utf8($lc1) || 0, $p3, "ENCRYPT");
         print CONFIG sprintf ("lMoYs_%d = %s     # utf8 (%d)%s  %s\n",
                               $_, $lc2, utf8::is_utf8($lc2) || 0, $p4, "ENCRYPT");
      }
      print CONFIG "\n";
   }

   close (CONFIG);

   DBUG_RETURN ( 1 );
}

# ====================================================================
sub build_date
{
   my $mode  = shift;    # 0, 1, 2, 3
   my $year  = shift;    # YYYY
   my $month = shift;    # 1..12
   my $day   = shift;    # 1..31
   my $def   = shift;
   my $lang  = shift;

   my ( $MoY, $DoM, $str );

   # The 4 digit years ...
   if ( $mode == 0 ) {
      $MoY = $def->{MoY}->[$month - 1];
      $DoM = $day . ( $def->{Dsuf}->[$day] || "" );
      $str = sprintf ("    %04d-%02d-%02d = %s %s, %04d      # ENCRYPT\n",
                      $year, $month, $day, $MoY, $DoM, $year);

   } elsif ( $mode == 1 ) {
      $MoY = $def->{MoYs}->[$month - 1];
      $str = sprintf ("    %04d-%02d-%02d = %04d-%s-%02d      # ENCRYPT -- %s   %s\n",
                      $year, $month, $day, $year, uc($MoY), $day, lc(uc($MoY)), $MoY);

   # The 2 digit years ... (be careful, don't use ambiguous dates!)
   } elsif ( $mode == 2 ) {
      $MoY = uc ($def->{MoY}->[$month - 1]);
      $DoM = $day . uc ( $def->{Dsuf}->[$day] || "" );
      $str = sprintf ("    %04d-%02d-%02d = %s %s, %02d      # ENCRYPT\n",
                      $year, $month, $day, $MoY, $DoM, $year % 100);

   } elsif ( $mode == 3 ) {
      $MoY = lc (uc ($def->{MoYs}->[$month - 1]));
      $str = sprintf ("    %04d-%02d-%02d = %02d-%s-%02d      # ENCRYPT\n",
                      $year, $month, $day, $day, $MoY, $year % 100);

   # The error case that should never happen ....
   } else {
      $str = sprintf ("    %04d-%02d-%02d = Programming errror!",
                      $year, $month, $day,);
   }

   # Only happens with bad language definitions ...
   unless ( $MoY ) {
      DBUG_PRINT ("ERROR", "MoY is null for '%s'.  mode: %d\n%s", $lang, $mode, $str);
   }

   return ( $str );
}

# ====================================================================
sub load_all_language_data
{
   DBUG_ENTER_FUNC (@_);

   my %lang_data;

   my $lidx = 0;
   foreach my $lang ( @global_languages ) {
      my $uses_utf8_mod = $global_lang_use_utf8[$lidx++];

      my $module = "Date::Language::${lang}";
      my ( $lang_wide, $lang_utf8 ) = ( 0, 0 );

      # @Dsuf isn't always available for some modules.
      my @lMoY  = eval "\@${module}::MoY";     # The fully spelled out Months.
      my @lMoYs = eval "\@${module}::MoYs";    # The legal Abbreviations.
      my @lDsuf = eval "\@${module}::Dsuf";    # The suffix for the Day of Month. (buggy)
      my @lDoW  = eval "\@${module}::DoW";     # The Day of Week.
      my @lDoWs = eval "\@${module}::DoWs";    # The Day of Week Abbreviations.
      my $has_spaces = 0;

      # Fix so that uc() & lc() will always work on these 5 arrays ...
      foreach (@lMoY, @lMoYs, @lDsuf, @lDoW, @lDoWs ) {
         my $wide = utf8::is_utf8 ($_) || 0;   # Before ...
         unless ( $wide ) {
            utf8::encode ($_);
            utf8::decode ($_);

            # Now determine if a common variant makes it wide ...
            if ( $_ =~  m/[^\x00-\xff]/ ) {
               $wide -= 1;     # Now: -1
            }
            if ( lc ($_) =~  m/[^\x00-\xff]/ ) {
               $wide -= 2;     # Now: -2 or -3
            }
            if ( uc ($_) =~  m/[^\x00-\xff]/ ) {
               $wide -= 4;     # Now: -4, -5, -6 or -7 ...
            }
         }
         my $utf8 = utf8::is_utf8 ($_) || 0;   # After ...

         $lang_wide = $lang_wide || $wide;
         $lang_utf8 = $lang_utf8 || $utf8;
         ++$has_spaces   if ( $_ =~ m/\s/ );
      }

      # So I can log my results ...
      # And prove my assumptions are good!
      my $test_ok = ( scalar (@lMoY) == 12 && scalar (@lMoYs) == 12 );

      DBUG_PRINT ($test_ok ? "INFO" : "BAD",
                  "MoY: %d, MoYs: %d, Dsuf: %02d, DoW: %d, DoWs: %d, wide(%2d), utf8(%d), uses_utf8_mod(%s), spaces(%2d), Language: %s",
                  scalar (@lMoY), scalar (@lMoYs), scalar (@lDsuf), scalar (@lDoW), scalar (@lDoWs),
                  $lang_wide, $lang_utf8, $uses_utf8_mod ? "YES" : "no", $has_spaces, $lang);

      if ( $test_ok ) {
         my %data = ( MoY  => \@lMoY,      MoYs   => \@lMoYs,
                      Dsuf => \@lDsuf,
                      DoW  => \@lDoW,      DoWs   => \@lDoWs,
                      wide => $lang_wide,  utf8   => $lang_utf8,
                      lang => $lang,       spaces => $has_spaces,
                      used_utf8_mod => $uses_utf8_mod );

         $lang_data{$lang} = \%data;
      }
   }

   DBUG_RETURN (\%lang_data);
}

