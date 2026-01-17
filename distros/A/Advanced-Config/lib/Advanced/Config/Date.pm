###
###  Copyright (c) 2018 - 2026 Curtis Leach.  All rights reserved.
###
###  Module: Advanced::Config::Date

=head1 NAME

Advanced::Config::Date - Module for parsing dates for L<Advanced::Config>.

=head1 SYNOPSIS

 use Advanced::Config::Date;
 or 
 require Advanced::Config::Date;

=head1 DESCRIPTION

F<Advanced::Config::Date> is a helper module to L<Advanced::Config>.  So it
should be very rare to directly call any methods defined by this module.  But
it's perfectly OK to use this module directly if you wish.

It's main job is to handle parsing dates passed in various formats and languages
while returning it in the standardized format of: S<YYYY-MM-DD>.  Hiding all the
messy logic of how to interpret any given date string.

=head1 MULTI-LANGUAGE SUPPORT

By default this module only supports parsing B<English> language dates.

But if you have the I<Date::Language> and/or I<Date::Manip>  modules installed
you can ask for it to use another language supported by either of these modules
instead.

You have to explicitly allow languages that require the use of I<Wide Chars>.
Otherwise they are not supported.

If a language is defined in both modules, it will merge the data together.
Since both modules sometimes give extra information that can be useful in
parsing a date..

=head1 FOUR-DIGIT VS TWO-DIGIT YEARS IN A DATE

This module will accept both 4-digit and 2-digit years in the dates it parses.
But two-digit years are inherently ambiguous if you aren't given the expected
format up front.  So 2-digit years generate more unreliability in the parsing
of any dates by this module.

So when used by the L<Advanced::Config> module, that module gives you the
ability to turn two-digit years on or off.  This is done via the B<Get Option>
"B<date_enable_yy>" which defaults to 0, B<not> allowing two-digit years.

To help resolve ambiguity with numeric dates, there is an option "B<date_format>"
that tells the L<Advanced::Config> how to parse these dates.  See the order
argument for I<parse_6_digit_date()> and I<parse_8_digit_date()> for how this
is done.

Finally if you use "B<date_dl_conversion>" and module L<Date::Language> is
installed, it will enhance parse_date() with that module's str2time() parser.
So if this option was used, it doesn't make much sense to disable 2-digit years.
Since we can't turn off 2-digit year support for str2time().

See L<Advanced::Config::Options> for more options telling how that module
controls how L<Advanced::Config> uses this module for parsing dates.

Those options have no effect if you are calling these methods directly.

=head1 FUNCTIONS

=over 4

=cut 

package Advanced::Config::Date;

use strict;
use warnings;

use File::Spec;
use File::Glob qw (bsd_glob);

use vars qw( @ISA @EXPORT @EXPORT_OK $VERSION );
use Exporter;

use Fred::Fish::DBUG 2.09 qw / on_if_set  ADVANCED_CONFIG_FISH /;
$VERSION = "1.14";
@ISA = qw( Exporter );

@EXPORT = qw( get_languages
              swap_language
              parse_date
              adjust_future_cutoff
              make_it_a_4_digit_year
              parse_8_digit_date
              parse_6_digit_date
              init_special_date_arrays
              _date_language_installed
              _date_manip_installed
              _validate_date_str
              is_leap_year
              calc_hundred_year_date
              calc_day_of_week
              convert_hyd_to_date_str
              calc_day_of_year
              adjust_date_str
            );

@EXPORT_OK = qw( );

my $global_cutoff_date = 30;    # Defaults to 30 years in the future ...

# Thesee haahes tell which language modules are available ...
my %date_language_installed_languages;
my %date_manip_installed_languages;

# ========================================================================
# Detects if the optional Date::Language module is available ...
# If it's not installed, you'll be unable to swap languages using it!
BEGIN
{
   eval {
      local $SIG{__DIE__} = "";
      require Date::Language;

      # Find out where it's installed
      my $loc = $INC{"Date/Language.pm"};
      $loc =~ s/[.]pm$//;

      my $search = File::Spec->catfile ($loc, "*.pm");

      # Get's the list of languages supported.
      foreach my $f ( bsd_glob ($search) ) {
         my $module = (File::Spec->splitdir( $f ))[-1];
         $module =~ s/[.]pm$//;

         my %data = ( Language => $module,
                      Module   => "Date::Language::${module}" );
         $date_language_installed_languages{lc($module)} = \%data;
      }
   };
}

# ========================================================================
# Detects if the optional Date::Manip module is available ...
# If it's not installed, you'll be unable to swap languages using it!
BEGIN
{
   eval {
      local $SIG{__DIE__} = "";
      require Date::Manip::Lang::index;
      Date::Manip::Lang::index->import ();

      foreach my $k ( sort keys %Date::Manip::Lang::index::Lang ) {
         my $mod = $Date::Manip::Lang::index::Lang{$k};
         my $lang = ( $k eq $mod ) ? ucfirst ($mod) : $mod;
         my $module = "Date::Manip::Lang::${mod}";

         my %data = ( Language => $lang,    # A guess that's wrong sometimes
                      Module   => $module );
         $date_manip_installed_languages{lc ($k)} = \%data;
      }
   };

   # -------------------------------------------------------------
   # Proves sometimes the module name is different from the
   # real language name.
   # -------------------------------------------------------------
   # foreach my $k ( sort keys %date_manip_installed_languages ) {
   #    printf STDERR ("Key (%s)  Language (%s)\n", $k, $date_manip_installed_languages{$k}->{Language});
   # }
}

# ========================================================================
# Hashes used to help validate/parse dates with ...
# Always keep the keys in lower case.

# Using the values from Date::Language::English for initialization ...
# Hard coded here in case Date::Language wasn't installed ...

# These hashes get rebuilt each time swap_language() is
# successfully called!
# ========================================================================
# Used by parse_date ();

my %last_language_edit_flags;

# Variants for the month names & days of month ...
# We hard code the initialization in case neither
# language module is installed locally.
my %Months;
my %Days;

BEGIN {
   # Variants for the month names ...
   %Months = (
               # The USA Months spelled out ...
               # Built from the @Date::Language::English::MoY array ...
               "january" =>  1,  "february" =>  2,  "march"     =>  3,
               "april"   =>  4,  "may"      =>  5,  "june"      =>  6,
               "july"    =>  7,  "august"   =>  8,  "september" =>  9,
               "october" => 10,  "november" => 11,  "december"  => 12,

               # The USA Months using 3 char abreviations ("may" not repeated!)
               # Built from the @Date::Language::English::MoYs array ...
               "jan"  => 1,  "feb" =>  2,  "mar" =>  3, "apr" =>  4,
                             "jun" =>  6,  "jul" =>  7, "aug" =>  8,
               "sep"  => 9,  "oct" => 10,  "nov" => 11, "dec" => 12,

               # Months as a numeric value.  If all digits, leading zeros will
               # be removed before it's used as a key.
               "1" => 1, "2" => 2, "3" => 3, "4"  =>  4, "5"  =>  5, "6"  =>  6,
               "7" => 7, "8" => 8, "9" => 9, "10" => 10, "11" => 11, "12" => 12
             );

   # variants for days of the month ...
   %Days = (
           "1"  => 1,  "2"  => 2,  "3"  => 3,  "4"  => 4,  "5"  => 5,
           "6"  => 6,  "7"  => 7,  "8"  => 8,  "9"  => 9,  "10" => 10,
           "11" => 11, "12" => 12, "13" => 13, "14" => 14, "15" => 15,
           "16" => 16, "17" => 17, "18" => 18, "19" => 19, "20" => 20,
           "21" => 21, "22" => 22, "23" => 23, "24" => 24, "25" => 25,
           "26" => 26, "27" => 27, "28" => 28, "29" => 29, "30" => 30,
           "31" => 31,

           # Built from the optional @Date::Language::English::Dsuf array ...
           "1st"  =>  1, "2nd"  =>  2, "3rd"  =>  3, "4th"  =>  4, "5th"  => 5,
           "6th"  =>  6, "7th"  =>  7, "8th"  =>  8, "9th"  =>  9, "10th" => 10,
           "11th" => 11, "12th" => 12, "13th" => 13, "14th" => 14, "15th" => 15,
           "16th" => 16, "17th" => 17, "18th" => 18, "19th" => 19, "20th" => 20,
           "21st" => 21, "22nd" => 22, "23rd" => 23, "24th" => 24, "25th" => 25,
           "26th" => 26, "27th" => 27, "28th" => 28, "29th" => 29, "30th" => 30,
           "31st" => 31,

           # From Date::Manip::Lang::english::Language->{nth} arrays ...
           'first'         =>  -1, 'second'       =>  -2, 'third'          =>  -3,
           'fourth'        =>  -4, 'fifth'        =>  -5, 'sixth'          =>  -6,
           'seventh'       =>  -7, 'eighth'       =>  -8, 'ninth'          =>  -9,
           'tenth'         => -10, 'eleventh'     => -11, 'twelfth'        => -12,
           'thirteenth'    => -13, 'fourteenth'   => -14, 'fifteenth'      => -15,
           'sixteenth'     => -16, 'seventeenth'  => -17, 'eighteenth'     => -18,
           'nineteenth'    => -19, 'twentieth'    => -20, 'twenty-first'   => -21,
           'twenty-second' => -22, 'twenty-third' => -23, 'twenty-fourth'  => -24,
           'twenty-fifth'  => -25, 'twenty-sixth' => -26, 'twenty-seventh' => -27,
           'twenty-eighth' => -28, 'twenty-ninth' => -29, 'thirtieth'      => -30,
           'thirty-first'  => -31,

           # From Date::Manip::Lang::english::Language->{nth} arrays ...
           'one'          =>  -1,  'two'          =>  -2,  'three'        =>  -3,
           'four'         =>  -4,  'five'         =>  -5,  'six'          =>  -6,
           'seven'        =>  -7,  'eight'        =>  -8,  'nine'         =>  -9,
           'ten'          => -10,  'eleven'       => -11,  'twelve'       => -12,
           'thirteen'     => -13,  'fourteen'     => -14,  'fifteen'      => -15,
           'sixteen'      => -16,  'seventeen'    => -17,  'eighteen'     => -18,
           'nineteen'     => -19,  'twenty'       => -20,  'twenty-one'   => -21,
           'twenty-two'   => -22,  'twenty-three' => -23,  'twenty-four'  => -24,
           'twenty-five'  => -25,  'twenty-six'   => -26,  'twenty-seven' => -27,
           'twenty-eight' => -28,  'twenty-nine'  => -29,  'thirty'       => -30,
           'thirty-one'   => -31,
        );

   my $date_manip_installed_flag    = keys %date_manip_installed_languages;
   my $date_language_installed_flag = keys %date_language_installed_languages;

   # Tells what to do about the negative values in the hashes ...
   my $flip = $date_manip_installed_flag || (! $date_language_installed_flag);


   $last_language_edit_flags{language} = "English";

   $last_language_edit_flags{month_period} = 0;;
   $last_language_edit_flags{dsuf_period} = 0;
   $last_language_edit_flags{dow_period} = 0;;

   foreach ( keys %Months ) {
      next  if ( $Months{$_} > 0 );
      if ( $flip ) {
         $Months{$_} = abs ($Months{$_});
      } else {
         delete $Months{$_};
      }
   }

   foreach ( keys %Days ) {
      next  if ( $Days{$_} > 0 );
      if ( $flip ) {
         $Days{$_} = abs ($Days{$_});
      } else {
         delete $Days{$_};
      }
   }
}

# How many days per month ... (non-leap year)
# --------------------->   J   F   M   A   M   J   J   A   S   O   N   D
my @days_in_months = ( 0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );


# Updated by:  init_special_date_arrays() ...
# May be for a different language than the above hashes ...
my $prev_array_lang = "English";
my @gMoY = qw ( January February March April May June
                July August September October November December );
my @gMoYs =  map { uc (substr($_,0,3)) } @gMoY;
my @gDsuf = sort { my ($x,$y) = ($a,$b); $x=~s/\D+$//; $y=~s/\D+$//; $x<=>$y } grep (/^\d+\D+$/, keys %Days, "0th");
my @gDoW  = qw( Sunday Monday Tuesday Wednesday Thursday Friday Saturday );
my @gDoWs = map { uc (substr($_,0,3)) } @gDoW;


# ==============================================================
# Not in pod on purpose.  Only added to simplify test cases.
sub _date_language_installed
{
   return ( scalar (keys %date_language_installed_languages) );
}

# ==============================================================
# Not in pod on purpose.  Only added to simplify test cases.
sub _date_manip_installed
{
   return ( scalar (keys %date_manip_installed_languages) );
}

# ==============================================================

=item @languages = get_languages ( );

This module returns a sorted list of languages supported by this module
for the parsing of date strings.

If neither L<Date::Language> and/or L<Date::Manip> are installed, only
I<English> is supported and you'll be unable to swap languages.

Both modules are used since each language module supports a different
set of languages with a lot of overlap between them.

Also L<Date::Manip> supports common aliases for some languages.  These
aliases appear in lower case.  When these aliases are used by
swap_language, it returns the real underlying language instead of
the alias.

=cut

sub get_languages
{
   DBUG_ENTER_FUNC ( @_ );

   my %languages;

   # For Date::Language ... (straight forward)
   foreach my $k1 ( keys %date_language_installed_languages ) {
      my $lang = $date_language_installed_languages{$k1}->{Language};
      $languages{$lang} = 1;
   }

   # For Date::Manip ... (a bit messy)
   # Messy since we can't verify the language without 1st loading it!
   foreach my $k1 ( keys %date_manip_installed_languages ) {
      my $lang = $date_manip_installed_languages{$k1}->{Language};
      my $k2 = ($k1 eq lc($lang)) ? $lang : $k1;
      $languages{$k2} = 1;
   }

   if ( scalar ( keys %languages ) == 0 ) {
      $languages{English} = 1;
   }

   DBUG_RETURN ( sort keys %languages );
}

# ==============================================================
# Done this way to the warning goes to fish no matter what.
sub _warn_msg
{
   DBUG_ENTER_FUNC ( @_ );
   my $ok = shift;
   my $msg = shift;
   if ( $ok ) {
      warn "==> ${msg}\n";
   }
   DBUG_VOID_RETURN ();
}

# ==============================================================
# No POD on purpose ...
# Does some common logic for swap_language() & init_special_date_arrays().
# Requires knowledge of the internals to Date::Language::<language>
# in order to work.
# This method should avoid referencing any global variables!
# Returns:  undef or the references to the 5 arrays!

sub _swap_lang_common
{
   DBUG_ENTER_FUNC ( @_ );
   my $lang_ref   = shift;
   my $warn_ok    = shift;
   my $allow_wide = shift || 0;

   my $base   = "Date::Language";
   my $lang   = $lang_ref->{Language};
   my $module = $lang_ref->{Module};

   my %issues;

   # Check if the requested language module exists ...
   {
      local $SIG{__DIE__} = "";
      my $sts = eval "require ${module}";
      unless ( $sts ) {
         _warn_msg ( $warn_ok, "${base} doesn't recognize '${lang}' as valid!" );
         return DBUG_RETURN ( undef, undef, undef, undef, undef, \%issues );
      }
   }

   # @Dsuf isn't always available for some modules & buggy for others.
   my @lMoY  = eval "\@${module}::MoY";     # The fully spelled out Months.
   my @lMoYs = eval "\@${module}::MoYs";    # The legal Abbreviations.
   my @lDsuf = eval "\@${module}::Dsuf";    # The suffix for the Day of Month.
   my @lDoW  = eval "\@${module}::DoW";     # The Day of Week.
   my @lDoWs = eval "\@${module}::DoWs";    # The Day of Week Abbreviations.

   # Detects Windows bug caused by case insensitive OS.
   # Where the OS says the file exists, but it doesn't match the package name.
   #   Ex:  Date::Language::Greek vs Date::Language::greek
   if ( $#lMoY == -1 && $#lMoYs == -1 && $#lDsuf == -1 && $#lDoW == -1 && $#lDoWs == -1 ) {
      _warn_msg ( $warn_ok, "${base} doesn't recognize '${lang}' as valid due to case!" );
      return DBUG_RETURN ( undef, undef, undef, undef, undef, \%issues );
   }

   # Add the missing end of the month for quite a few Dsuf!
   # Uses the suffixes from the 20's.
   my $num = @lDsuf;
   if ( $num > 29 ) {
       my $fix = $num % 10;
       foreach ( $num..31 ) {
          my $idx = $_ - $num + 20 + $fix;
          $lDsuf[$_] = $lDsuf[$idx];
          DBUG_PRINT ("FIX", "lDsuf[%d] = lDsuf[%d] = %s  (%s)",
                       $_, $idx, $lDsuf[$_], $lang);
       }
   }

   # -------------------------------------------------- 
   # Check if Unicode/Wide Chars were used ...
   my $wide_flag = 0;
   foreach ( @lMoY, @lMoYs, @lDsuf, @lDoW, @lDoWs ) {
      # my $wide = utf8::is_utf8 ($_) || 0;
      my $wide = ( $_ =~ m/[^\x00-\xff]/ ) || 0;   # m/[^\x00-\x7f]/ doesn't completely work!
      if ( $wide ) {
         $wide_flag = 1;      # Multi-byte chars detected!
      } else {
         # Fix so uc()/lc() work for languages like German.
         utf8::encode ($_);
         utf8::decode ($_);   # Sets utf8 flag ...

         # Are any of these common variants wide chars?
         if ( $_      =~  m/[^\x00-\xff]/ ||
              uc ($_) =~  m/[^\x00-\xff]/ ||
              lc ($_) =~  m/[^\x00-\xff]/ ) {
            $wide_flag = -1;
         }
      }
   }

   $lang_ref->{Wide} = $wide_flag;

   if ( $wide_flag && ! $allow_wide ) {
      _warn_msg ( $warn_ok, "'${lang}' uses Wide Chars.  It's not currently enabled!" );
      return DBUG_RETURN ( undef, undef, undef, undef, undef, \%issues );
   }

   # Put in the number before the suffix ... (ie: nd => 2nd, rd => 3rd)
   # Many langages built this array incorrectly & shorted it.
   foreach ( 0..31 ) {
      last  unless ( defined $lDsuf[$_] );
      $lDsuf[$_] = $_ . $lDsuf[$_];
      $issues{dsuf_period} = 1   if ($lDsuf[$_] =~ m/[.]/ );
   }

   # Now check if any RegExp wild cards in the value ...
   foreach ( @lMoY, @lMoYs ) {
      $issues{month_period} = 1  if ( $_ =~ m/[.]/ );
   }

   foreach ( @lDoW, @lDoWs ) {
      $issues{dow_period} = 1  if ( $_ =~ m/[.]/ );
   }

   DBUG_RETURN ( \@lMoY, \@lMoYs, \@lDsuf, \@lDoW, \@lDoWs, \%issues );
}


# ==============================================================
# No POD on purpose ...
# Does some common logic for swap_language() & init_special_date_arrays().
# Requires knowledge of the internals to Date::Manip::Lang::<language>
# in order to work.
# This method should avoid referencing any global variables!
# Returns:  undef or the references to the 5 arrays!
# I would have broken it up ino multiple functions if not for the wide test!

sub _swap_manip_language_common
{
   DBUG_ENTER_FUNC ( @_ );
   my $lang_ref   = shift;
   my $warn_ok    = shift;
   my $allow_wide = shift || 0;

   my $base   = "Date::Manip";
   my $lang   = $lang_ref->{Language};
   my $module = $lang_ref->{Module};

   # Check if the requested language module exists ...
   {
      local $SIG{__DIE__} = "";
      my $sts = eval "require ${module}";
      unless ( $sts ) {
         _warn_msg ( $warn_ok, "${base} doesn't recognize '${lang}' as valid!" );
         return ( DBUG_RETURN ( undef, undef, undef, undef, undef, undef, undef, undef ) );
      }
   }

   # Get the proper name of this language fom the module.
   $lang_ref->{Language} = $lang = eval "\$${module}::LangName";

   # Get the language data from the module.
   my $langData = eval "\$${module}::Language";    # A hash reference with the data!

   # The 3 return values used by swap_language () ...
   my (%months, %days, %issues);

   # The 5 return values used by init_special_date_arrays()
   my ( @MoY, @MoYs, @Dsuf, @DoW, @DoWs);

   my $wide = 0;
   my $has_period = 0;
   foreach my $month_idx (1..12) {
      foreach my $name ( @{$langData->{month_name}->[$month_idx-1]} ) {
         my ($w, $k, $pi, $pe, $alt) = _fix_key ( $name );
         $wide = 1  if ($w);
         next  if ( $pe && exists $months{$alt} && $months{$alt} == $month_idx );
         $has_period = 1  if ( $pi || $pe );
         $months{$k} = $month_idx;
      }
      foreach my $abb ( @{$langData->{month_abb}->[$month_idx-1]} ) {
         my ($w, $k, $pi, $pe, $alt) = _fix_key ( $abb );
         $wide = 1  if ($w);
         next  if ( $pe && exists $months{$alt} && $months{$alt} == $month_idx );
         $has_period = 1  if ( $pi || $pe );
         $months{$k} = $month_idx;
      }

      my $first_name = $langData->{month_name}->[$month_idx-1]->[0];
      my $first_abb  = $langData->{month_abb}->[$month_idx-1]->[0];
      push ( @MoY,  (_fix_key ($first_name, 1))[1] );
      push ( @MoYs, (_fix_key ($first_abb, 1))[1] );
   }
   $issues{month_period} = $has_period;

   $has_period = 0;
   foreach my $day_idx (1..31) {
      foreach my $day ( @{$langData->{nth}->[$day_idx-1]} ) {
         my ($w, $k, $pi, $pe, $alt) = _fix_key ( $day );
         $wide = 1  if ($w);
         next  if ( $pe && exists $days{$alt} && $days{$alt} == $day_idx );
         $has_period = 1  if ( $pi || $pe );
         $days{$k} = $day_idx;
      }

      my $first = $langData->{nth}->[$day_idx-1]->[0];
      push ( @Dsuf, (_fix_key ($first, 1))[1] );
   }
   $issues{dsuf_period} = $has_period;

   # Need Sunday to Saturday to be consistent with localime() & Date::Language.
   # But this array is Monday to Sunday!
   # So take advantage of -1 being last element in array to fix!
   $has_period = 0;
   foreach my $wd_idx (1..7) {
      my $wd = $langData->{day_name}->[$wd_idx - 2]->[0];
      my ($w, $k, $pi, $pe, $alt) = _fix_key ( $wd, 1 );
      $wide = 1  if ($w);
      push (@DoW, $k);

      $wd = $langData->{day_abb}->[$wd_idx - 2]->[0];
      ($w, $k, $pi, $pe, $alt) = _fix_key ( $wd, 1 );
      $wide = 1  if ($w);
      push (@DoWs, $k);
   }
   $issues{dow_period} = $has_period;

   $lang_ref->{Wide} = $wide;

   if ( $wide && ! $allow_wide ) {
      _warn_msg ( $warn_ok, "'${lang}' uses Wide Chars.  It's not currently enabled!" );
      return ( DBUG_RETURN ( undef, undef, undef, undef, undef, undef, undef, undef ) );
   }

   DBUG_RETURN ( \%months, \%days, \%issues, \@MoY, \@MoYs, \@Dsuf, \@DoW, \@DoWs);
}

# ==============================================================
# So uc() & lc() works against all language values ...
sub _fix_key
{
   my $value     = shift;
   my $keep_case = shift || 0;

   my $wide = ( $value =~ m/[^\x00-\xff]/ ) ? 1 : 0;  # Before ...

   unless ( $wide ) {
      utf8::encode ($value);
      utf8::decode ($value);

      # Now verify if any of the following makes it wide ...
      if ( $value      =~  m/[^\x00-\xff]/  ||
           lc ($value) =~  m/[^\x00-\xff]/  ||
           uc ($value) =~  m/[^\x00-\xff]/ ) {
         $wide = 1;
      }
   }

   $value = lc ($value)   unless ( $keep_case );
   my $alt = $value;

   my ($has_internal_period, $has_ending_period) = (0, 0);
   if ( $value =~ m/([.]?)[^.]*(.)$/ ) {
      $has_internal_period = 1  if ($1 eq '.');
      if ($2 eq '.') {
         $has_ending_period = 1;
         $alt =~ s/[.]$//;
      }
   }

   return ($wide, lc $value, $has_internal_period, $has_ending_period, $alt);
}

# ==============================================================
# It's a mess since Date::Manip allows for aliases.

sub _select_language
{
   DBUG_ENTER_FUNC ( @_ );
   my $lang       = shift;
   my $warn_ok    = shift;
   my $allow_wide = shift;

   my $k = lc ($lang);
   my $manip_ref = $date_manip_installed_languages{$k};
   my $lang_ref  = $date_language_installed_languages{$k};

   if ( $manip_ref && ! $lang_ref ) {
      $k = lc ($manip_ref->{Language});
      $lang_ref  = $date_language_installed_languages{$k};
   }

   unless ( $lang_ref || $manip_ref ) {
      _warn_msg ( $warn_ok, "Language '$lang' does not exist!  So can't swap to it!" );
      return DBUG_RETURN ( undef, undef );
   } 

   unless ( $allow_wide ) {
      $manip_ref = undef  if ( $manip_ref && $manip_ref->{Wide} );
      $lang_ref  = undef  if ( $lang_ref  && $lang_ref->{Wide} );

      unless ( $lang_ref || $manip_ref ) {
         _warn_msg ( $warn_ok, "Language '$lang' uses Wide Chars.  It's not currently enabled!" );
         return DBUG_RETURN ( undef, undef );
      }
   }

   DBUG_RETURN ( $manip_ref, $lang_ref );
}

# ==============================================================

=item $lang = swap_language ( $language[, $give_warning[, $wide]] );

This method allows you to change the I<$language> used when this module parses
a date string if you have modules L<Date::Language> and/or L<Date::Manip>
installed.  But if neither are installed, only dates in B<English> are
supported.  If a language is defined in both places the results are merged.

It always returns the active language.  So if I<$language> is B<undef> or
invalid, it will return the current language from before the call.  But if the
language was successfully changed, it will return the new I<$language> instead.

Should the change fail and I<$give_warning> is set to a non-zero value, it will
write a warning to your screen telling you why it failed.

So assuming one of the language modules are installed, it asks it for the list
of months in the requested language.  And once that list is retrieved only
months in that language are supported when parsing a date string.

Languages like 'Greek' that rely on I<Wide Chars> require the I<$wide> flag set
to true.   Otherwise that language is disabled.  Using the I<use_ut8> option
when creating the Advanced::Config object causes the I<$wide> flag to be set to
B<1>.

=cut

# NOTE: Sets the following global variables for use by parse_date() ...
#       %last_language_edit_flags
#       %Months
#       %Days

sub swap_language
{
   DBUG_ENTER_FUNC ( @_ );
   my $lang       = shift;
   my $warn_ok    = shift;
   my $allow_wide = shift || 0;

   if ( (! defined $lang) || lc($lang) eq lc($last_language_edit_flags{language}) ) {
      return DBUG_RETURN ( $last_language_edit_flags{language} );
   }

   my ($manip_ref, $lang_ref) = _select_language ($lang, $warn_ok, $allow_wide);

   unless ( $lang_ref || $manip_ref ) {
      return DBUG_RETURN ( $last_language_edit_flags{language} );
   }

   my ($month_ref, $day_ref, $issue1_ref);
   if ( $manip_ref ) {
      my $old = $manip_ref->{Language};
      ($month_ref, $day_ref, $issue1_ref) =
                  _swap_manip_language_common ($manip_ref, $warn_ok, $allow_wide );
      $lang = $manip_ref->{Language};

      if ( $old ne $lang && ! $lang_ref ) {
         $lang_ref = $date_language_installed_languages{lc($lang)};
         $lang_ref = undef if ($lang_ref && $lang_ref->{Wide} && ! $allow_wide);
      }
   }

   my ($MoY_ref, $MoYs_ref, $Dsuf_ref, $issue2_ref);
   if ( $lang_ref ) {
      my ($unused_DoW_ref, $unused_DoWs_ref);
      ($MoY_ref, $MoYs_ref, $Dsuf_ref, $unused_DoW_ref, $unused_DoWs_ref, $issue2_ref) =
                  _swap_lang_common ( $lang_ref, $warn_ok, $allow_wide );
      $lang = $lang_ref->{Language};
   }

   unless ( $MoY_ref || $month_ref ) {
      return DBUG_RETURN ( $last_language_edit_flags{language} );
   }

   DBUG_PRINT ("SWAP", "Swapping from '%s' to '%s'.",
                       $last_language_edit_flags{language}, $lang);

   # ---------------------------------------------------------
   foreach my $k ( keys %last_language_edit_flags ) {
      $last_language_edit_flags{$k} = $issue1_ref->{$k} || $issue2_ref->{$k} || 0;
   }
   $last_language_edit_flags{language} = $lang;

   # ---------------------------------------------------------
   # Bug Alert:  For some languges the following isn't true!
   #     lc(MoY) != lc(uc(lc(MoY)))
   # So we have multiple lower case letters mapping to the
   # same upper case letters#.
   # ---------------------------------------------------------
   # This happens for 3 languages for Date::Language.
   #     Chinese_GB, Greek & Russian_cp1251
   # And one language for Date::Manip
   #     Turkish
   # ---------------------------------------------------------

   my %empty;
   %Months = %Days = %empty;

   # ---------------------------------------------------------
   # Put in the common numeric values into the hashes ...
   my $cnt;
   foreach $cnt ( 1..12 ) {
      $Months{$cnt} = $cnt;
   }

   foreach my $day ( 1..31 ) {
      $Days{$day} = $day;
   }

   # ---------------------------------------------------------
   # Merge in the Date::Manip::Lang::<language> values ...

   foreach my $mon ( keys %{$month_ref} ) {
      $Months{$mon} = $month_ref->{$mon};
      $Months{lc (uc (lc ($mon)))} = $Months{$mon};   # Bug fix, but usually same.
   }

   foreach my $day ( keys %{$day_ref} ) {
      $Days{$day} = $day_ref->{$day};
      $Days{lc (uc (lc ($day)))} = $Days{$day};       # Bug fix, but usually same.
   }

   # ---------------------------------------------------------
   # Merge in the Date::Language::<language> values ...

   $cnt = 1;
   foreach my $mon ( @{$MoY_ref} ) {
      $Months{lc ($mon)} = $cnt;
      $Months{lc (uc (lc ($mon)))} = $cnt;    # Bug fix, but usually same.
      ++$cnt;
   }

   $cnt = 1;
   foreach my $mon ( @{$MoYs_ref} ) {
      $Months{lc ($mon)} = $cnt;
      $Months{lc (uc (lc ($mon)))} = $cnt;    # Bug fix, but usually same.
      ++$cnt;
   }

   foreach my $day ( 1..31 ) {
      if ( $Dsuf_ref && defined $Dsuf_ref->[$day] ) {
         my $key = $Dsuf_ref->[$day];
         $Days{lc ($key)} = $day;
         $Days{lc (uc (lc ($key)))} = $day;   # Bug fix, but usually same.
      }
   }

   # ---------------------------------------------------------
   # Report the results ...

   DBUG_PRINT ( "LANGUAGE", "%s\n%s\n%s",
                join (", ", sort { $Months{$a} <=> $Months{$b} || $a cmp $b } keys %Months),
                join (", ", sort { my ($x,$y) = ($a,$b); $x=~s/\D+//g; $y=~s/\D+//g; $x=0 if ($x eq ""); $y=0 if ($y eq ""); ($x<=>$y || $a cmp $b) } keys %Days),
                join (", ", %last_language_edit_flags) );

   DBUG_RETURN ( $lang );
}


# ==============================================================

=item $date = parse_date ( $date_str, $order[, $allow_dl[, $enable_2_digit_years]] );

Passed a date in some unknown format, it does it's best to parse it and return
the date in S<YYYY-MM-DD> format if it's a valid date.  It returns B<undef> if
it can't find a valid date within I<$date_str>.

The date can be surrounded by other information in the string that will be
ignored.  So it will strip out just the date info in something like:

=over 4

Tues B<January 3rd, 2017> at 6:00 PM.

=back

There are too many valid date formats to list them all, especially when other
languages are added to the mix.  But if you have one it doesn't support, open
a CPAN ticket and I'll see if I can quickly add it.

I<$order> tells the order to use for interpreting dates that are all digits.
It's forwarded to all internal calls to L<parse_6_digit_date> and
L<parse_8_digit_date>.  So see those methods POD for more info on its meaning.

I<$allow_dl> is non-zero and L<Date::Language> is installed use it's method
B<str2time ()> to attempt the conversion only if nothing else worked.

If I<$enable_2_digit_years> is set to zero, it will not recognize any 2-digit
year date formats as valid.  Set to a non-zero value to enable them.

=cut

# Check out Date::Parse for date examples to use to test this function out.

sub lcx
{
   my $str = shift;

   unless ( utf8::is_utf8 ($str) ) {
      utf8::encode ($str);
      utf8::decode ($str);
   }

   return (lc ($str));
}

sub _tst
{
   my $s  = shift;
   my $nm = shift;
   my $dm = shift;
   DBUG_PRINT ("TST", "Matched Pattern (%s) Sep: %s Name: %s  Dom: %s", join (",",@_), $s, $nm, $dm);
   return (1);
}

# DEPRECIATED VERSION ...
sub parse_date_old
{
   DBUG_ENTER_FUNC ( @_ );
   my $in_date = shift;         # A potential date in an unknown format ...
   my $date_format_options      = shift;     # A comma separated list of ids ...
   my $use_date_language_module = shift || 0;
   my $allow_2_digit_years      = shift || 0;

   # The Month name pattern, ... [a-zA-Z] doesn't work for other languages.
   my $name = "[^-\$\\s\\d.,|\\[\\]\\\\/{}()]";

   # The Day of Month pattern ... (when not all digits are expected)
   my $dom = "\\d{0,2}${name}*";

   # Remove the requesed character from the month pattern ...
   $name =~ s/\\s//g   if ( $last_language_edit_flags{month_spaces} );
   $name =~ s/[.]//g   if ( $last_language_edit_flags{month_period} );
   $name =~ s/-//g     if ( $last_language_edit_flags{month_hyphin} );

   $name .= '+';     # Terminate the name pattern.

   # Remove the requesed character from the day of month pattern ...
   $dom =~ s/\\s//g    if ( $last_language_edit_flags{dsuf_spaces} );
   $dom =~ s/[.]//g    if ( $last_language_edit_flags{dsuf_period} );
   $dom =~ s/-//g      if ( $last_language_edit_flags{dsuf_hyphin} );

   my ( $year, $month, $day );
   my ( $s1, $s2 ) = ( "", "" );
   my $fmt = "n/a";

   # The 7 separators to cycle through to parse things correctly ...
   my @seps = ( "-", "/", "[.]", ",", "\\s+", '\\\\', ":" );

   # -------------------------------------------------------
   # Let's start with the 4-digit year formats ...
   # -------------------------------------------------------
   foreach my $sep ( @seps ) {
      if ( $in_date =~ m/(^|\D)(\d{4})(${sep})(\d{1,2})(${sep})(\d{1,2})(\D|$)/ ) {
         ( $year, $s1, $month, $s2, $day ) = ( $2, $3, $4, $5, $6 );
         $fmt = "YYYY${s1}MM${s2}DD";    # ISO format

      } elsif ( $in_date =~ m/(^|\D)(\d{1,2})(${sep})(\d{1,2})(${sep})(\d{4})(\D|$)/ ) {
         ( $month, $s1, $day, $s2, $year ) = ( $2, $3, $4, $5, $6 );
         ( $year, $month, $day ) = parse_8_digit_date ( sprintf ("%02d%02d%04d", $month, $day, $year),
	$date_format_options, 1 );
         $fmt = "MM${s1}DD${s2}YYYY";    # European or American format (ambiguous?)

      # ------------------------------------------------------------------------------------------
      } elsif ( $in_date =~ m/(^|\D)(\d{1,2})(${sep})(${name})[.]?(${sep})(\d{4})(\D|$)/ &&
                exists $Months{lcx($4)} ) {
         ( $day, $s1, $month, $s2, $year ) = ( $2, $3, $4, $5, $6 );
         $fmt = "DD${s1}Month${s2}YYYY";

      } elsif ( $in_date =~ m/(^|\D)(\d{4})(${sep})(${name})[.]?(${sep})(\d{1,2})(\D|$)/ &&
                exists $Months{lcx($4)} ) {
         ( $year, $s1, $month, $s2, $day ) = ( $2, $3, $4, $5, $6 );
         $fmt = "YYYY${s1}Month${s2}DD";

      } elsif ( $in_date =~ m/(^|\s)(${name})(${sep})(\d{1,2})(${sep})(\d{4})(\D|$)/ &&
                exists $Months{lcx($2)} ) {
         ( $month, $s1, $day, $s2, $year ) = ( $2, $3, $4, $5, $6 );
         $fmt = "Month${s1}DD${s2}YYYY";

      # ------------------------------------------------------------------------------------------
      } elsif ( $in_date =~ m/(^|\s)(${dom})(${sep})(${name})[.]?(${sep})(\d{4})(\D|$)/ &&
                exists $Months{lcx($4)} &&
                exists $Days{lcx($2)} ) {
         ( $day, $s1, $month, $s2, $year ) = ( $2, $3, $4, $5, $6 );
         $fmt = "Day${s1}Month${s2}YYYY";    # European format

      } elsif ( $in_date =~ m/(^|\D)(\d{4})(${sep})(${name})[.]?(${sep})(${dom})(\s|$)/ &&
                exists $Months{lcx($4)} &&
                exists $Days{lcx($6)} ) {
         ( $year, $s1, $month, $s2, $day ) = ( $2, $3, $4, $5, $6 );
         $fmt = "YYYY${s1}Month${s2}Day";    # ISO format

      } elsif ( $in_date =~ m/(^|\s)(${name})(${sep})(${dom})(${sep})(\d{4})(\D|$)/ &&
                exists $Months{lcx($2)} &&
                exists $Days{lcx($4)} ) {
         ( $month, $s1, $day, $s2, $year ) = ( $2, $3, $4, $5, $6 );
         $fmt = "Month${s1}Day${s2}YYYY";    # American format
      }

      last  if ( defined $year );
   }

   if ( defined $year ) {
       ;   # No more formatting tests needed ...

   # "Month Day, YYYY" or "Month Day YYYY"
   } elsif ( $in_date =~ m/(${name})[.\s]\s*(${dom})[,\s]\s*(\d{4})(\D|$)/ &&
             exists $Months{lcx($1)} ) {
      ( $month, $day, $year ) = ( $1, $2, $3 );
      $fmt = "Month Day, YYYY";

  # "Month Day, HH:MM:SS YYYY" or "Month Day HH:MM:SS YYYY"
  # Added because:  "$dt = localtime(time())" generates this format.
  } elsif ( $in_date =~ m/(${name})[.]?\s+(${dom})[,\s]\s*(\d{1,2}:\d{1,2}(:\d{1,2})?)\s+(\d{4})(\D|$)/ &&
            exists $Months{lcx($1)} ) {
      my $time;
      ( $month, $day, $time, $year ) = ( $1, $2, $3, $5 );
      $fmt = "Month Day HH:MM[:SS] YYYY";

   # As a string of 8 digits.
   } elsif ( $in_date =~ m/(^|\D)(\d{8})(\D|$)/ ) {
      ($year, $month, $day) = parse_8_digit_date ( $2, $date_format_options, 0 );
      $fmt = "YYYYMMDD";

   # -------------------------------------------------------
   # Finally, assume it's using a 2-digit year format ...
   # Only if they are allowed ...
   # -------------------------------------------------------
   } elsif ( $allow_2_digit_years ) {
      foreach my $sep ( @seps ) {
         next  if ( $sep eq ":" );    # Skip, if used it looks like a time of day ...

         if ( $in_date =~ m/(^|[^:\d])(\d{1,2})(${sep})(\d{1,2})(${sep})(\d{1,2})([^:\d]|$)/ ) {
            ($s1, $s2) = ($3, $5);
            my $yymmdd = sprintf ("%02d%02d%02d", $2, $4, $6);
            ($year, $month, $day) = parse_6_digit_date ( $yymmdd, $date_format_options );
            $fmt = "YY${s1}MM${s2}DD ???";

         # ------------------------------------------------------------------------------------------
         } elsif ( $in_date =~ m/(^|\D)(\d{1,2})(${sep})(${name})[.]?(${sep})(\d{1,2})([^:\d]|$)/ &&
              exists $Months{lcx($4)} ) {
            ( $year, $s1, $month, $s2, $day ) = ( $2, $3, $4, $5, $6 );
            my $yymmdd = sprintf ("%02d%02d%02d", $year, $Months{lcx($month)}, $day);
            my @order;
            foreach ( split (/\s*,\s*/, $date_format_options) ) {
               push (@order, $_)  if ( $_ != 2 );   # If not American format ...
            }
            ($year, $month, $day) = parse_6_digit_date ( $yymmdd, join(",", @order) );
            $fmt = "DD${s1}Month${s2}YY or YY${s1}Month${s2}DD";

         } elsif ( $in_date =~ m/(^|\s)(${name})(${sep})(\d{1,2})(${sep})(\d{1,2})([^:\d]|$)/ &&
                   exists $Months{lcx($2)} ) {
            ( $month, $s1, $day, $s2, $year ) = ( $2, $3, $4, $5, $6 );
            $year = make_it_a_4_digit_year ( $year );
            $fmt = "Month${s1}DD${s2}YY";

         # ------------------------------------------------------------------------------------------
         } elsif ( $in_date =~ m/(^|\s)(${name})[.]?(${sep})(${dom})(${sep})(\d{1,2})([^:\d]|$)/ &&
                   _tst( $sep, $name, $dom, $2, $4, $6 ) &&
                   exists $Months{lcx($2)} &&
                   exists $Days{lcx($4)} ) {
            ( $month, $s1, $day, $s2, $year ) = ( $2, $3, $4, $5, $6 );
            $year = make_it_a_4_digit_year ( $year );
            $fmt = "Month${s1}Day${s2}YY";          # American format

         } elsif ( $in_date =~ m/(^|\s)(${dom})(${sep})(${name})[.]?(${sep})(\d{1,2})([^:\d]|$)/ &&
                   _tst( $sep, $name, $dom, $2, $4, $6 ) &&
                   exists $Months{lcx($4)} &&
                   exists $Days{lcx($2)} ) {
            ( $day, $s1, $month, $s2, $year ) = ( $2, $3, $4, $5, $6 );
            $year = make_it_a_4_digit_year ( $year );
            $fmt = "Day${s1}Month${s2}YY";          # European format

         } elsif ( $in_date =~ m/(^|\D)(\d{1,2})(${sep})(${name})[.]?(${sep})(${dom})(\s|$)/ &&
                   _tst( $sep, $name, $dom, $2, $4, $6 ) &&
                   exists $Months{lcx($4)} &&
                   exists $Days{lcx($6)} ) {
            ( $year, $s1, $month, $s2, $day ) = ( $2, $3, $4, $5, $6 );
            $year = make_it_a_4_digit_year ( $year );
            $fmt = "YY${s1}Month${s2}Day";          # ISO format
         }

         last  if ( defined $year );
      }

      if ( defined $year ) {
          ;   # No more formatting tests needed ...

      # "Month Day, YY" or "Month Day YY"
      } elsif ( $in_date =~ m/(${name})[.\s]\s*(${dom})[,\s]\s*(\d{2})(\D|$)/ &&
                _tst( "\\s", $name, $dom, $1, $2, $3 ) &&
                exists $Months{lcx($1)} ) {
         ( $month, $day ) = ( $1, $2 );
         $year = make_it_a_4_digit_year ( $3 );
         $fmt = "Month Day, YY";

      # As a string of 6 digits.
      } elsif ( $in_date =~ m/(^|\D)(\d{6})(\D|$)/ ) {
         ($year, $month, $day) = parse_6_digit_date ( $2, $date_format_options );
         $fmt = "YYMMDD";
      }
   }   # End if its a 2-digit year ...


   # --------------------------------------------------------------------
   # If my parsing didn't work try using Date::Language if it's installed.
   # Keep after my checks so that things are consistent when this module
   # isn't installed.  (No way to disable 2-digit year format here.)
   # --------------------------------------------------------------------

   if ( $use_date_language_module && ! defined $year ) {
      unless ( _date_language_installed () ) { 
         DBUG_PRINT ("INFO", "Using Date::Language::str2time was requested, but it's not installed!");
      } else {
         DBUG_PRINT ("INFO", "Using Date::Language::str2time to attempt the parse!");
         eval {
            my $dl = Date::Language->new ( $last_language_edit_flags{language} );
            my $t = $dl->str2time ( $in_date );
            if ( defined $t ) {
               ($year, $month, $day) = (localtime ($t))[5,4,3];
               $year += 1900;
               $month += 1;
            }
         };
      }
   }

   # --------------------------------------------------------------------
   # We're done with parsing things.  Now let's validate the results!
   # --------------------------------------------------------------------

   if ( ! defined $year ) {
      DBUG_PRINT ("ERROR", "No such date format is supported: %s", $in_date);

   # Else we're using a known date format ...
   } else {
      DBUG_PRINT ("FORMAT", "%s ==> %s ==> (Y:%s, M:%s, D:%s, Sep:%s)",
                  $fmt, $in_date, $year, $month, $day, $s1);

      # It's not a valid date if the separaters are different ...
      # Shouldn't be possible any more unless it's spaces.
      # (Hence we die if it happens)
      if ( $s1 ne $s2 ) {
         unless ( $s1 =~ m/^\s*$/ && $s2 =~ m/^\s*$/ ) {
            die ("BUG: Separators are different ($s1 vs $s2)\n");
         }
      }

      # Now let's validate the results ...
      # Trim leading/trailing spaces ...
      $day = $1   if ( $day =~ m/^\s*(.*)\s*$/ );

      return DBUG_RETURN ( _check_if_good_date ($in_date, $year, $month, $day) );
   }

   DBUG_RETURN ( undef );   # Invalid date ...
}


sub parse_date
{
   DBUG_ENTER_FUNC ( @_ );
   my $in_date = shift;         # A potential date in an unknown format ...
   my $date_format_options      = shift;     # A comma separated list of fmt ids ...
   my $use_date_language_module = shift || 0;
   my $allow_2_digit_years      = shift || 0;

   $in_date = lcx ($in_date);    # Make sure always in lower case ...

   my ($month, $month_digits) = _find_month_in_string ( $in_date );
   my ($dom, $dom_digits)     = _find_day_of_month_in_string ( $in_date, $month_digits,
                                          $month_digits ? undef : $month );

   my $out_str;

   if ( $month_digits && $dom_digits ) {
      $out_str = _month_num_day_num ( $in_date, $month, $dom, $allow_2_digit_years, $date_format_options );
   } elsif ( $month_digits ) {
      $out_str = _month_num_day_str ( $in_date, $month, $dom, $allow_2_digit_years );
   } elsif ( $dom_digits ) {
      $out_str = _month_str_day_num ( $in_date, $month, $dom, $allow_2_digit_years, $date_format_options );
   } else {
      $out_str = _month_str_day_str ( $in_date, $month, $dom, $allow_2_digit_years );
   }

   # --------------------------------------------------------------------
   # If my parsing didn't work try using Date::Language if it's installed.
   # Keep after my checks so that things are consistent when this module
   # isn't installed.  (No way to disable 2-digit year format here.)
   # --------------------------------------------------------------------
   if ( $use_date_language_module && (! $out_str) &&
        _date_language_installed () ) {
      DBUG_PRINT ("INFO", "Using Date::Language::str2time to attempt parsing!");
      eval {
         my $dl = Date::Language->new ( $last_language_edit_flags{language} );
         my $t = $dl->str2time ( $in_date );
         if ( defined $t ) {
            my ($year, $month, $day) = (localtime ($t))[5,4,3];
            $year += 1900;
            $month += 1;

            $out_str = _check_if_good_date ($in_date, $year, $month, $day);
         }
      };
   }

   DBUG_RETURN ($out_str);    # undef or the date in YYYY-MM-DD format.
}

# --------------------------------------------------------------
# No ambiguity here ... we have multiple text anchors ...

sub _month_str_day_str
{
   DBUG_ENTER_FUNC ( @_ );
   my $in_date   = shift;
   my $month_str = shift;
   my $dom_str   = shift;
   my $allow_2_digit_years = shift;

   my ($year, $s1, $month, $s2, $day );

   if ( $in_date =~ m/(^|\D)(${month_str})[.]?(.*?\D)(${dom_str})(.*?\D)(\d{4})($|\D)/ ) {
      ($month, $s1, $day, $s2, $year ) = ( $2, $3, $4, $5, $6 );  # American format ...

   } elsif ($in_date =~ m/(^|\D)(${dom_str})(.+?)(${month_str})[.]?(.*?\D)(\d{4})($|\D)/ ) {
      ($day, $s1, $month, $s2, $year ) = ( $2, $3, $4, $5, $6 );  # European format ...

   } elsif ( $in_date =~ m/(^|\D)(\d{4})(\D.*?)(${month_str})[.]?(.*?\D)(${dom_str})($|\D)/ ) {
      ($year, $s1, $month, $s2, $day ) = ( $2, $3, $4, $5, $6 );  # ISO format ...
   }

   if ( $allow_2_digit_years && ! defined $year ) {
      if ( $in_date =~ m/(^|\D)(${month_str})[.]?(.*?\D)(${dom_str})(.*?[^:\d])(\d{2})($|[^:\d])/ ) {
         ($month, $s1, $day, $s2, $year ) = ( $2, $3, $4, $5, $6 );  # American format ...

      } elsif ($in_date =~ m/(^|\D)(${dom_str})(.+?)(${month_str})[.]?(.*?[^:\d])(\d{2})($|[^:\d])/ ) {
         ($day, $s1, $month, $s2, $year ) = ( $2, $3, $4, $5, $6 );  # European format ...

      } elsif ( $in_date =~ m/(^|[^:\d])(\d{2})([^:\d].*?)(${month_str})[.]?(.*?\D)(${dom_str})($|\D)/ ) {
         ($year, $s1, $month, $s2, $day ) = ( $2, $3, $4, $5, $6 );  # ISO format ...
      }

      $year = make_it_a_4_digit_year ( $year )  if (defined $year);
   }   # End if allowing 2-digit years ...

   if ( defined $year ) {
      return DBUG_RETURN ( _check_if_good_date ($in_date, $year, $month, $day) );
   }

   DBUG_RETURN ( undef );
}

# --------------------------------------------------------------
# With a month anchor still not too ambiguous.

sub _tst_4_YY
{
   my $sep = shift;
   my $res = ( $sep =~ m/\s\d{1,2}\s/ ) ? 0 : 1;
   return ($res);
}

sub _month_str_day_num
{
   DBUG_ENTER_FUNC ( @_ );
   my $in_date   = shift;
   my $month_str = shift;
   my $dom_num   = shift;
   my $allow_2_digit_years = shift;
   my $date_format_options = shift;

   my ($year, $s1, $month, $s2, $day );

   # American format ...
   if ( $in_date =~ m/(^|\D)(${month_str})[.]?([^\d]*?\D)(${dom_num})(\D)(\d{4})($|\D)/ ) {
      ($month, $s1, $day, $s2, $year ) = ( $2, $3, $4, $5, $6 );
      DBUG_PRINT ("AMERICAN-1", "${month}/${day}/${year} -- ($s1)   ($s2)");

   # American format ...
   } elsif ( $in_date =~ m/(^|\D)(${month_str})[.]?([^\d]*?\D)(${dom_num})(\D.*?\D)(\d{4})($|\D)/ &&
             _tst_4_YY ( $5 ) ) {
      ($month, $s1, $day, $s2, $year ) = ( $2, $3, $4, $5, $6 );
      DBUG_PRINT ("AMERICAN-2", "${month}/${day}/${year} -- ($s1)   ($s2)");

   # European format ...
   } elsif ($in_date =~ m/(^|\D)(${dom_num})(\D*?)(${month_str})[.]?(.*?\D)(\d{4})($|\D)/ &&
             _tst_4_YY ( $5 ) ) {
      ($day, $s1, $month, $s2, $year ) = ( $2, $3, $4, $5, $6 );
      DBUG_PRINT ("EUROPEAN", "${day}/${month}/${year} -- ($s1)   ($s2)");

   # ISO format ...
   } elsif ( $in_date =~ m/(^|\D)(\d{4})(\D*?)(${month_str})[.]?(.*?\D)(${dom_num})($|\D)/ ) {
      ($year, $s1, $month, $s2, $day ) = ( $2, $3, $4, $5, $6 );
      DBUG_PRINT ("ISO", "${year}/${month}/${day} -- ($s1)   ($s2)");
   }

   if ( $allow_2_digit_years && ! defined $year ) {
      # American format ...
      if ( $in_date =~ m/(^|\D)(${month_str})[.]?(.*?[^:\d])(${dom_num})([^:\d])(\d{2})($|[^:\d])/    ||
           $in_date =~ m/(^|\D)(${month_str})[.]?(.*?[^:\d])(${dom_num})([^:\d].*?[^:\d])(\d{2})($|[^:\d])/ ) {
         ($month, $s1, $day, $s2, $year ) = ( $2, $3, $4, $5, $6 );
         $year = make_it_a_4_digit_year ( $year );

      # Ambiguous ... Either ISO or European, so must use hint ...
      } elsif ($in_date =~ m/(^|\D)(${dom_num})([^:\d].*?)(${month_str})[.]?(.*?[^:\d])(${dom_num})($|[^:\d])/ ) {
         ($year, $s1, $month, $s2, $day ) = ( $2, $3, $4, $5, $6 );
         my $yymmdd = sprintf ("%02d%02d%02d", $year, $Months{lcx($month)}, $day);
         my @order;
         foreach ( split (/\s*,\s*/, $date_format_options) ) {
            push (@order, $_)  if ( $_ != 2 );   # Drop American format ...
         }
         ($year, $month, $day) = parse_6_digit_date ( $yymmdd, join(",", @order) );

      # European format ...
      } elsif ($in_date =~ m/(^|\D)(${dom_num})([^:\d].*?)(${month_str})[.]?(.*?[^:\d])(\d{2})($|[^:\d])/ ) {
         ($day, $s1, $month, $s2, $year ) = ( $2, $3, $4, $5, $6 );
         $year = make_it_a_4_digit_year ( $year );

      # ISO format ...
      } elsif ( $in_date =~ m/(^|[^:\d])(\d{2})([^:\d].*?)(${month_str})[.]?(.*?[^:\d])(${dom_num})($|[^:\d])/ ) {
         ($year, $s1, $month, $s2, $day ) = ( $2, $3, $4, $5, $6 );
         $year = make_it_a_4_digit_year ( $year );
      }
   }   # End if allowing 2-digit years ...

   if ( defined $year ) {
      return DBUG_RETURN ( _check_if_good_date ($in_date, $year, $month, $day) );
   }

   DBUG_RETURN ( undef );
}

# --------------------------------------------------------------
# Getting a bit more problematic ...

sub _month_num_day_str
{
   DBUG_ENTER_FUNC ( @_ );
   my $in_date   = shift;
   my $month_num = shift;
   my $dom_str   = shift;
   my $allow_2_digit_years = shift;

   my ($year, $s1, $month, $s2, $day );

   if ( $in_date =~ m/(^|[^:\d])(${month_num})(\D)(${dom_str})(.*?\D)(\d{4})($|\D)/     ||
        $in_date =~ m/(^|[^:\d])(${month_num})(\D.*?\D)(${dom_str})(.*?\D)(\d{4})($|\D)/ ) {
      ($month, $s1, $day, $s2, $year ) = ( $2, $3, $4, $5, $6 );  # American format ...

   } elsif ($in_date =~ m/(^|\D)(${dom_str})(.*?\D)(${month_num})(\D)(\d{4})($|\D)/     ||
            $in_date =~ m/(^|\D)(${dom_str})(.*?\D)(${month_num})(\D.*?\D)(\d{4})($|\D)/ ) {
      ($day, $s1, $month, $s2, $year ) = ( $2, $3, $4, $5, $6 );  # European format ...

   } elsif ( $in_date =~ m/(^|\D)(\d{4})(\D)(${month_num})(\D)(${dom_str})($|\D)/       ||
             $in_date =~ m/(^|\D)(\d{4})(\D)(${month_num})(\D.*?\D)(${dom_str})($|\D)/       ||
             $in_date =~ m/(^|\D)(\d{4})(\D.*?\D)(${month_num})(\D)(${dom_str})($|\D)/       ||
             $in_date =~ m/(^|\D)(\d{4})(\D.*?\D)(${month_num})(\D.*?\D)(${dom_str})($|\D)/ ) {
      ($year, $s1, $month, $s2, $day ) = ( $2, $3, $4, $5, $6 );  # ISO format ...
   }

   if ( $allow_2_digit_years && ! defined $year ) {
      if ( $in_date =~ m/(^|\D)(${month_num})([^:\d])(${dom_str})(.*?[^:\d])(\d{2})($|[^:\d])/   ||
           $in_date =~ m/(^|\D)(${month_num})([^:\d].*?[^:\d])(${dom_str})(.*?[^:\d])(\d{2})($|[^:\d])/ ) {
         ($month, $s1, $day, $s2, $year ) = ( $2, $3, $4, $5, $6 );  # American format ...

      } elsif ($in_date =~ m/(^|\D)(${dom_str})(.*?[^:\d])(${month_num})([^:\d])(\d{2})($|[^:\d])/  ||
               $in_date =~ m/(^|\D)(${dom_str})(.*?[^:\d])(${month_num})([^:\d].*?[^:\d])(\d{2})($|[^:\d])/ ) {
         ($day, $s1, $month, $s2, $year ) = ( $2, $3, $4, $5, $6 );  # European format ...

      } elsif ( $in_date =~ m/(^|[^:\d])(\d{2})([^:\d])(${month_num})([^:\d])(${dom_str})($|\D)/  ||
                $in_date =~ m/(^|[^:\d])(\d{2})([^:\d])(${month_num})([^:\d].*?[^:\d])(${dom_str})($|\D)/  ||
                $in_date =~ m/(^|[^:\d])(\d{2})([^:\d].*?[^:\d])(${month_num})([^:\d])(${dom_str})($|\D)/  ||
                $in_date =~ m/(^|[^:\d])(\d{2})([^:\d].*?[^:\d])(${month_num})([^:\d].*?[^:\d])(${dom_str})($|\D)/ ) {
         ($year, $s1, $month, $s2, $day ) = ( $2, $3, $4, $5, $6 );  # ISO format ...
      }

      $year = make_it_a_4_digit_year ( $year )  if (defined $year);
   }   # End if allowing 2-digit years ...

   if ( defined $year ) {
      return DBUG_RETURN ( _check_if_good_date ($in_date, $year, $month, $day) );
   }

   DBUG_RETURN ( undef );
}

# --------------------------------------------------------------
# A very ambiguous format ... and much, much messier!

sub _month_num_day_num
{
   DBUG_ENTER_FUNC ( @_ );
   my $in_date   = shift;
   my $month_num = shift;
   my $dom_num   = shift;
   my $allow_2_digit_years = shift;
   my $date_format_options = shift;

   my ($year, $s1, $month, $s2, $day );

   # Unknown format, use hint to decide ...
   if ( $in_date =~ m/(^|\D)(\d{8})($|\D)/ ) {
      ( $year, $month, $day ) = parse_8_digit_date ( $2, $date_format_options, 0 );
      $s1 = $s2 = "";

   # American or European Format, use hint to decide ...
   } elsif ( $in_date =~ m/(^|\D)(\d{1,2})(\D+)(\d{1,2})(\D+)(\d{4})(\D|$)/ ) {
      ( $s1, $s2 ) = ( $3, $5 );
      my $date = sprintf ("%02d%02d%04d", $2, $4, $6);
      ( $year, $month, $day ) = parse_8_digit_date ( $date, $date_format_options, 1 );

   # ISO Format ...
   } elsif ( $in_date =~ m/(^|\D)(\d{4})(\D+)(${month_num})(\D+)(${dom_num})(\D|$)/ ) {
      ( $year, $s1, $month, $s2, $day ) = ( $2, $3, $4, $5, $6 );
   }


   if ( $allow_2_digit_years && ! defined $year ) {
      # Unknown format, use hint to decide ...
      if ( $in_date =~ m/(^|\D)(\d{6})($|\D)/ ) {
         ( $year, $month, $day ) = parse_6_digit_date ( $2, $date_format_options );
         $s1 = $s2 = "";

      # Unknown format, use hint to decide ...
      } elsif ( $in_date =~ m/(^|[^:\d])(\d{1,2})([^:\d]+)(\d{1,2})([^:\d]+)(\d{1,2})([^:\d]|$)/ ) {
         ( $s1, $s2 ) = ( $3, $5 );
         my $date = sprintf ("%02d%02d%02d", $2, $4, $6);
         ( $year, $month, $day ) = parse_6_digit_date ( $date, $date_format_options );
      }
   }   # End if allowing 2-digit years ...

   if ( defined $year ) {
      return DBUG_RETURN ( _check_if_good_date ($in_date, $year, $month, $day) );
   }

   DBUG_RETURN ( undef );
}


# --------------------------------------------------------------
# Always returns date in ISO format if it's good!
# Or undef if a bad date!

sub _check_if_good_date
{
   DBUG_ENTER_FUNC ( @_ );
   my $in_str = shift;
   my $year   = shift;
   my $month  = shift;
   my $day    = shift;

   # Strip off any leading zeros so we can use the hashes for validation ...
   $month =~ s/^0+//;
   $day   =~ s/^0+//;

   # Standardize it ... (with digits only!)
   $month = $Months{lcx($month)};
   $day   = $Days{lcx($day)};

   # Helpfull when dealing with foreign languages.
   my $err_msg;
   if ( defined $month && defined $day ) {
      ;      # Good date!
   } elsif ( defined $month ) {
      $err_msg = "Just the day of month is bad.";
   } elsif ( defined $day ) {
      $err_msg = "Just the month is bad.";
   } else {
      $err_msg = "Both the month and day are bad.";
   }

   unless ( $err_msg ) {
      if ( 1 <= $day && $day <= $days_in_months[$month] ) {
         ;  # It's a good date ...
      } elsif ( $month == 2 && $day == 29 ) {
         my $leap = _is_leap_year ($year);
         $year = undef  unless ( $leap );
      } else {
         $year = undef;
      }
      unless ( defined $year ) {
         $err_msg = "The day of month is out of range.";
      }
   }

   if ( $err_msg ) {
      DBUG_PRINT ("ERROR", "'%s' was an invalid date!\n%s", $in_str, $err_msg);
      DBUG_PRINT ("BAD", "%s-%s-%s", $year, $month, $day);
      return ( DBUG_RETURN (undef) );
   }

   DBUG_RETURN ( sprintf ("%04d-%02d-%02d", $year, $month, $day) );
}

# --------------------------------------------------------------
sub _find_month_in_string
{
   DBUG_ENTER_FUNC (@_);
   my $date_str = shift;

   my $month;
   my $digits = 0;

   my @lst = sort { length($b) <=> length($a) || $a cmp $b } keys %Months;

   foreach my $m ( @lst ) {
      # Ignore numeric keys, can't get the correct one from string ...
      next  if ( $m =~ m/^\d+$/ );

      my $flag1 = ( $last_language_edit_flags{month_period} &&
                    $m =~ s/[.]/\\./g );

      if ( $date_str =~ m/(${m})/ ) {
         $month = $1;
         $month =~ s/[.]/\\./g  if ( $flag1 );
         last;
      }
   }

   # Allow any number between 1 and 12 ...
   unless ( $month ) {
      $month = "[1-9]|0[1-9]|1[0-2]";
      $digits = 1;
   }

   DBUG_RETURN ( $month, $digits );   # Suitable for use in a RegExpr.
}

# --------------------------------------------------------------
sub _find_day_of_month_in_string
{
   DBUG_ENTER_FUNC (@_);
   my $date_str    = shift;
   my $skip_period = shift;        # Skip entries ending in '.' like 17.!
   my $month_str   = shift;        # Will be undef if skip_period is true!

   my $day;
   my $digits = 0;

   my @lst = sort { length($b) <=> length($a) || $a cmp $b } keys %Days;

   my $all_digits = $skip_period ? "^\\d+[.]?\$" : "^\\d+\$";

   foreach my $dom ( @lst ) {
      # Ignore numeric keys, can't get the correct one from string ...
      next  if ( $dom =~ m/${all_digits}/ );

      my $flag1 = ( $last_language_edit_flags{dsuf_period} &&
                    $dom =~ s/[.]/\\./g );

      if ( $month_str ) {
         # Makes sure dom doesn't match month name ...
         $month_str =~ s/[.]/\\./g;
         if ( $date_str =~ m/${month_str}.*(${dom})/ ||
              $date_str =~ m/(${dom}).*${month_str}/ ) {
            $day = $1;
            $day =~ s/[.]/\\./g  if ( $flag1 );
            last;
         }

      # There is no month name to worry about ...
      } elsif ( $date_str =~ m/(${dom})/ ) {
         $day = $1;
         $day =~ s/[.]/\\./g  if ( $flag1 );
         last;
      }
   }

   # Allow any number between 1 and 31 ...
   unless ( $day ) {
      $day = "[1-9]|0[1-9]|[12][0-9]|3[01]";
      $digits = 1;
   }

   DBUG_RETURN ( $day, $digits );   # Suitable for use in a RegExpr.
}

# ==============================================================

=item adjust_future_cutoff ( $num_years );

Changes the cutoff future date from B<30> years to I<$num_years>.

Set to B<0> to disable years in the future!

This affects all L<Advanced::Config> objects, not just the current one.

=cut

sub adjust_future_cutoff
{
   DBUG_ENTER_FUNC ( @_ );
   my $years = shift;

   if ( defined $years && $years =~ m/^\d+$/ ) {
      $global_cutoff_date = shift;
   }

   DBUG_VOID_RETURN ();
}


# ==============================================================

=item $year = make_it_a_4_digit_year ( $two_digit_year );

Used whenever this module needs to convert a two-digit year into a four-digit
year.

When it converts YY into YYYY, it will assume 20YY unless the
resulting date is more than B<30> years in the future.  Then it's 19YY.

If you don't like this rule, use B<adjust_future_cutoff> to change
this limit!

=cut

sub make_it_a_4_digit_year
{
   DBUG_ENTER_FUNC ( @_ );
   my $year = shift || 0;    # Passed as a 2-digit year ...

   $year += 2000;   # Convert it to a 4-digit year ...

   # Get the current 4-digit year ...
   my $this_yr = (localtime (time()))[5];
   $this_yr += 1900;

   if ( $this_yr < $year && ($year - $this_yr) >= $global_cutoff_date ) {
      $year -= 100;   # Make it last century instead.
   }

   DBUG_RETURN ( $year );
}


# ==============================================================

=item ($year, $month, $day) = parse_8_digit_date ( $date_str, $order[, $skip] );

Looks for a valid date in an 8 digit string.  It checks each of the formats below
in the order specified by I<$order> until it hits something that looks like a
valid date.

   (1) YYYYMMDD - ISO
   (2) MMDDYYYY - American
   (3) DDMMYYYY - European

The I<$order> argument helps deal with ambiguities in the date.  Its a comma
separated list of numbers specifying to order to try out.  Ex: 3,2,1 means
try out the European date format 1st, then the American date format 2nd, and
finally the ISO format 3rd.  You could also just say I<$order> is B<3> and
only accept European dates.

It assumes its using the correct format when the date looks valid.  It does this
by validating the B<MM> is between 1 and 12 and that the B<DD> is between 1 and
31.  (Using the correct max for that month).  And then assumes the year is
always valid.

If I<$skip> is a non-zero value it will skip over the B<ISO> format if it's
listed in I<$order>.

Returns 3 B<undef>'s if nothing looks good.

=cut

sub parse_8_digit_date
{
   DBUG_ENTER_FUNC ( @_ );
   my $date_str = shift;
   my $order    = shift;
   my $skip_iso = shift || 0;

   my @order = split (/\s*,\s*/, $order);
   my @lbls = ( "", "YYYYMMDD - ISO", "MMDDYYYY - American", "DDMMYYYY - European" );

   my ( $year, $month, $day );
   foreach my $id ( @order ) {
      next  unless ( defined $id && $id =~ m/^[123]$/ );

      my ( $y, $m, $d ) = ( 0, 0, 0 );

      if ( $id == 1 && (! $skip_iso) &&    # YYYYMMDD - ISO
           $date_str =~ m/^(\d{4})(\d{2})(\d{2})$/ ) {
         ( $y, $m, $d ) = ( $1, $2, $3 );
      }
      if ( $id == 2 &&                     # MMDDYYYY - American
           $date_str =~ m/^(\d{2})(\d{2})(\d{4})$/ ) {
         ( $m, $d, $y ) = ( $1, $2, $3 );
      }
      if ( $id == 3 &&                     # DDMMYYYY - European
           $date_str =~ m/^(\d{2})(\d{2})(\d{4})$/ ) {
         ( $d, $m, $y ) = ( $1, $2, $3 );
      }

      if ( 1 <= $m && $m <= 12 && 1 <= $d && $d <= 31 ) {
         DBUG_PRINT ("INFO", "Validating if using %s format.", $lbls[$id]);
          my $max = $days_in_months[$m];
          if ( $m == 2 ) {
             my $leap = _is_leap_year ($y);
             ++$max  if ( $leap );
          }

          if ( $d <= $max ) {
             ( $year, $month, $day ) = ( $y, $m, $d );
             last;
          }
      }
   }

   DBUG_RETURN ( $year, $month, $day );
}


# ==============================================================

=item ($year, $month, $day) = parse_6_digit_date ( $date_str, $order );

Looks for a valid date in an 6 digit string.  It checks each of the formats below
in the order specified by I<$order> until it hits something that looks like a
valid date.

   (1) YYMMDD - ISO
   (2) MMDDYY - American
   (3) DDMMYY - European

The I<$order> argument helps deal with ambiguities in the date.  Its a comma
separated list of numbers specifying to order to try out.  Ex: 2,3,1 means
try out the American date format 1st, then the European date format 2nd, and
finally the ISO format 3rd.  You could also just say I<$order> is B<2> and
only accept European dates.

So if you use the wrong order, more than likely you'll get the wrong date!

It assumes its using the correct format when the date looks valid.  It does this
by validating the B<MM> is between 1 and 12 and that the B<DD> is between 1 and
31.  (Using the correct max for that month).  And then assumes the year is
always valid.

Returns 3 B<undef>'s if nothing looks good.

It always returns the year as a 4-digit year!

=cut

sub parse_6_digit_date
{
   DBUG_ENTER_FUNC ( @_ );
   my $date_str = shift;
   my $order    = shift;

   my @order = split (/\s*,\s*/, $order);
   my @lbls = ( "", "YYMMDD - ISO", "MMDDYY - American", "DDMMYY - European" );

   my ( $year, $month, $day );
   if ( $date_str =~ m/^(\d{2})(\d{2})(\d{2})$/ ) {
      my @part = ( $1, $2, $3 );
      foreach my $id ( @order ) {
         next  unless ( defined $id && $id =~ m/^[123]$/ );

         my ( $y, $m, $d ) = ( 0, 0, 0 );

         if ( $id == 1 &&    # YYMMDD - ISO
              1 <= $part[1] && $part[1] <= 12 &&
              1 <= $part[2] && $part[2] <= 31 )  {
            ( $m, $d, $y ) = ( $part[1], $part[2], $part[0] );
         }
         if ( $id == 2 &&    # MMDDYY - American
              1 <= $part[0] && $part[0] <= 12 &&
              1 <= $part[1] && $part[1] <= 31 ) {
            ( $m, $d, $y ) = ( $part[0], $part[1], $part[2] );
         }
         if ( $id == 3 &&    # DDMMYY - European
              1 <= $part[1] && $part[1] <= 12 &&
              1 <= $part[0] && $part[0] <= 31 ) {
            ( $m, $d, $y ) = ( $part[1], $part[0], $part[2] );
         }

         # Now validate the day of month ...
         if ( $m > 0 ) {
            DBUG_PRINT ("INFO", "Validating if using %s format.", $lbls[$id]);
            $y = make_it_a_4_digit_year ( $y );

            my $max = $days_in_months[$m];
            if ( $m == 2 ) {
               my $leap = _is_leap_year ($y);
               ++$max  if ( $leap );
            }

            if ( $d <= $max ) {
               ( $year, $month, $day ) = ( $y, $m, $d );
               last;
            }
         }
      }
   }

   DBUG_RETURN ( $year, $month, $day );
}


# ==============================================================

=item (\@months, \@weekdays) = init_special_date_arrays ( $lang[, $mode[, $wok[, $wide]]] );

Prefers getting the date names from I<Date::Manip::Lang::${lang}> for the
I<Advanced::Config> special date variables.  But if the language isn't supported
by that module it tries I<Date::Language::${lang}> instead.  This is because
the 1st module is more consistent.

If the I<$lang> doesn't exist, then it returns the arrays for the last valid
language.

If I<$wok> is set to a non-zero value, it will print warnings to your screen if
there were issues in changing the language used.

I<$mode> tells how to return the various arrays:

   1 - Abbreviated month/weekday names in the requested language.
   2 - Full month/weekday names in the requested language.
   Any other value and it will return the numeric values. (default)

For @months, indexes are 0..11, with 0 representing January.

For @weekdays, indexes are 0..6, with 0 representing Sunday.

Languages like 'Greek' that rely on I<Wide Chars> require the I<$wide> flag set to
true.   Otherwise that language is disabled.

=cut

sub init_special_date_arrays
{
   DBUG_ENTER_FUNC ( @_ );
   my $lang       = shift;
   my $mode       = shift || 0;    # Default to numeric arrays ...
   my $warn_ok    = shift || 0;
   my $allow_wide = shift || 0;

   my @months = ( "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12" );
   my @week_days = ( "1", "2", "3", "4", "5", "6", "7" );

   my $numbers = ($mode != 1 && $mode != 2 );

   my ( $lang_ref, $manip_ref );

   if ( defined $lang ) {
      ($manip_ref, $lang_ref) = _select_language ($lang, $warn_ok, $allow_wide);

      unless ( $lang_ref || $manip_ref ) {
         $lang = undef;    # So it will enter the early out if block ...
      }
   }

   if ( (! defined $lang) || lc($lang) eq lc($prev_array_lang) || $numbers ) {
      if ( $mode == 1 ) {
         @months    = @gMoYs;      # Abrevited month names ...
         @week_days = @gDoWs;      # Abrevited week names ...
      } elsif ( $mode == 2 ) {
         @months    = @gMoY;       # Full month names ...
         @week_days = @gDoW;       # Full week names ...
      }
      return DBUG_RETURN ( \@months, \@week_days );
   }

   my ($MoY_ref, $MoYs_ref, $Dsuf_ref, $DoW_ref, $DoWs_ref);

   DBUG_PRINT ("INFO", "Manip: %s,  Lang: %s", $manip_ref, $lang_ref);
   if ( $manip_ref ) {
      my ( $u1, $u2, $u3 );    # Unused placeholders.
      ($u1, $u2, $u3, $MoY_ref, $MoYs_ref, $Dsuf_ref, $DoW_ref, $DoWs_ref) =
                   _swap_manip_language_common ($manip_ref, $warn_ok, $allow_wide );
      $lang = $manip_ref->{Language};

      if ( $u1 ) {
         $lang_ref = undef;    # Skip lang_ref lookup if successsful ...
      } else {
         $lang_ref = $date_language_installed_languages{lc($lang)};
      }
   }

   if ( $lang_ref ) {
      ($MoY_ref, $MoYs_ref, $Dsuf_ref, $DoW_ref, $DoWs_ref) =
                     _swap_lang_common ( $lang_ref, $warn_ok, $allow_wide );
      $lang = $lang_ref->{Language};
   }


   # If the new language was valid, update the global variables ...
   if ( $MoY_ref ) {
      $prev_array_lang = $lang;
      @gMoY  = @{$MoY_ref};
      @gMoYs = map { uc($_) } @{$MoYs_ref};
      @gDoW  = @{$DoW_ref};
      @gDoWs = map { uc($_) } @{$DoWs_ref};
      @gDsuf = @{$Dsuf_ref};

      DBUG_PRINT ( "LANGUAGE", "%s\n%s\n%s\n%s\n%s",
                   join (", ", @gMoY), join (", ", @gMoYs),
                   join (", ", @gDoW), join (", ", @gDoWs),
                   join (", ", @gDsuf)
                 );
   }

   # Numeric handled earlier ...
   if ( $mode == 1 ) {
      @months    = @gMoYs;      # Abrevited month names ...
      @week_days = @gDoWs;      # Abrevited week names ...
   } elsif ( $mode == 2 ) {
      @months    = @gMoY;       # Full month names ...
      @week_days = @gDoW;       # Full week names ...
   }

   DBUG_RETURN ( \@months, \@week_days );
}

# ==============================================================

sub _is_leap_year
{
   my $year = shift;
   my $leap = ($year % 4 == 0) && ($year % 100 != 0 || $year % 400 == 0);
   return ($leap ? 1 : 0);
}

# ==============================================================

# Validate the input date.
sub _validate_date_str
{
   DBUG_ENTER_FUNC ( @_ );
   my $date_str = shift;

   my ($year, $mon, $day);
   if ( defined $date_str && $date_str =~ m/^(\d+)-(\d+)-(\d+)$/ ) {
      ($year, $mon, $day) = ($1, $2, $3);
      my $leap = _is_leap_year ($year);
      local $days_in_months[2] = $leap ? 29 : 28;
      unless ( 1 <= $mon && $mon <= 12 &&
	       1 <= $day && $day <= $days_in_months[$mon] ) {
         return DBUG_RETURN ( undef, undef, undef );
      }
   } else {
      return DBUG_RETURN ( undef, undef, undef );
   }

   DBUG_RETURN ( $year, $mon, $day );
}

# ==============================================================

=item $bool = is_leap_year ( $year );

Returns B<1> if I<$year> is a Leap Year, else B<0> if it isn't.

=cut

sub is_leap_year
{
   DBUG_ENTER_FUNC ( @_ );
   DBUG_RETURN ( _is_leap_year (@_) );
}

# ==============================================================

=item $hyd = calc_hundred_year_date ( $date_str );

Takes a date string in B<YYYY-MM-DD> format and returns the number of days since
B<1899-12-31>.  (Which is HYD B<0>.)   It should be compatible with DB2's data
type of the same name.  Something like this function is needed if you wish to be
able to do date math.

For example:

   1 : 2026-01-01 - 2025-12-30 = 2 days.
   2 : 2025-12-31 + 10 = 2026-01-10.
   2 : 2025-12-31 - 2 = 2025-12-29.

If the given date string is invalid it will return B<undef>.

=cut

sub calc_hundred_year_date
{
   DBUG_ENTER_FUNC ( @_ );
   my $date_str = shift;

   # Validate the input date.
   my ($end_year, $month, $day) = _validate_date_str ($date_str);
   unless (defined $end_year) {
      return DBUG_RETURN ( undef );
   }

   my $hyd = 0;
   my $start_year = 1899;

   if ( $end_year >  $start_year ) {
      for (my $year = $start_year + 1; $year < $end_year; ++$year) {
         my $leap = _is_leap_year ($year);
	 $hyd += $leap ? 366 : 365;
      }
      $hyd += calc_day_of_year ($date_str, 0);

   } else {        # $hyd <= 0 ...
      for (my $year = $start_year; $year > $end_year; --$year) {
         my $leap = _is_leap_year ($year);
	 $hyd -= $leap ? 366 : 365;
      }
      $hyd -= calc_day_of_year ($date_str, 1);
   }

   DBUG_RETURN ($hyd);
}

# ==============================================================

=item $dow = calc_day_of_week ( $date_str );

Takes a date string in B<YYYY-MM-DD> format and returns the day of the week it
falls on.  It returns a value between B<0> and B<6> for Sunday to Saturday.

If the given date is invalid it will return B<undef>.

=item $dow = calc_day_of_week ( $hyd );

It takes an integer as a Hundred Year Date and returns the day of the week it
falls on.  It returns a value between B<0> and B<6> for Sunday to Saturday.

If the given hyd is not an integer it will return B<undef>.

=cut

sub calc_day_of_week
{
   DBUG_ENTER_FUNC ( @_ );
   my $date_str = shift;     # or a HYD ...

   my $hyd;
   if ( defined $date_str && $date_str =~ m/^[-]?\d+$/ ) {
      $hyd = $date_str;
   } else {
      $hyd = calc_hundred_year_date ( $date_str );
   }

   unless (defined $hyd) {
      return DBUG_RETURN ( undef );
   }

   my $start_dow = 0;    # $hyd 0, 1899-12-31, falls on a Sunday.

   my $dow = ($hyd + $start_dow) % 7;

   DBUG_RETURN ($dow);
}

# ==============================================================

=item $date_str = convert_hyd_to_date_str ( $hyd );

It takes an integer as a Hundred Year Date and converts it into a date string
in the format of B<YYYY-MM-DD> and returns it.

If the given hyd is not an integer it will return B<undef>.

=cut

sub convert_hyd_to_date_str
{
   DBUG_ENTER_FUNC ( @_ );
   my $target_hyd = shift;

   unless ( defined $target_hyd && $target_hyd =~ m/^[-]?\d+$/ ) {
      return DBUG_RETURN ( undef );
   }

   my $date_str;
   my $start_year = 1899;          # HYD of 0 is 1899-12-31
   my $hyd_total = 0;
   my $days = 0;
   my ($leap, $year);

   if ( $target_hyd > 0 ) {
      for ($year = $start_year + 1; 1==1; ++$year) {
         $leap = _is_leap_year ($year);
	 $days = $leap ? 366 : 365;
	 if ( ($hyd_total + $days) >= $target_hyd ) {
	    last;
	 }
	 $hyd_total += $days;
      }
      local $days_in_months[2] = $leap ? 29 : 28;
      for (1..12) {
	 $days = $days_in_months[$_];
	 if ( ($hyd_total + $days) >= $target_hyd ) {
	    my $diff = $target_hyd - $hyd_total;
	    $date_str = sprintf ("%04d-%02d-%02d", $year, $_, $diff);
	    last;
	 }
	 $hyd_total += $days;
      }

   } else {        # $target_hyd <= 0.
      for ($year = $start_year; 1==1; --$year) {
         $leap = _is_leap_year ($year);
	 $days = $leap ? 366 : 365;
	 if ( ($hyd_total - $days) <= $target_hyd ) {
	    last;
	 }
	 $hyd_total -= $days;
      }
      local $days_in_months[2] = $leap ? 29 : 28;
      for (reverse 1..12) {
	 $days = $days_in_months[$_];
	 if ( ($hyd_total - $days) <= $target_hyd ) {
	    my $diff = $target_hyd - $hyd_total;
	    my $ans = $diff +  $days;

DBUG_PRINT("-FINAL-", "Target: %d, Current: %d, Diff: %d, Year: %d/%02d, Day: %02d", $target_hyd, $hyd_total, $diff, $year, $_,  $ans);

	    if ($ans) {
	       $date_str = sprintf ("%04d-%02d-%02d", $year, $_, $ans);
	    } elsif ( $_ == 1 ) {
	       $ans = $days_in_months[12];
	       $date_str = sprintf ("%04d-%02d-%02d", $year - 1, 12, $ans);
	    } else {
	       $ans = $days_in_months[$_ - 1];
	       $date_str = sprintf ("%04d-%02d-%02d", $year, $_ - 1, $ans);
	    }
	    last;
	 }
	 $hyd_total -= $days;

DBUG_PRINT("MONTHLY", "Target: %d, Current: %d, Year: %d/%02d", $target_hyd, $hyd_total, $year, $_);
      }
   }

   DBUG_RETURN ($date_str);
}

# ==============================================================

=item $doy = calc_day_of_year ( $date_str[, $remainder_flag] );

Takes a date string in B<YYYY-MM-DD> format and returns the number of days since
the begining of the year.  With January 1st being day B<1>.

If the remainder_flag is set to a no-zero value, it returns the number of days
left in the year.  With December 31st being B<0>.

If the given date is invalid it will return B<undef>.

=cut

sub calc_day_of_year
{
   DBUG_ENTER_FUNC ( @_ );
   my $date_str       = shift;
   my $remainder_flag = shift || 0;

   # Validate the input date.
   my ($year, $month, $day) = _validate_date_str ($date_str);
   unless (defined $year) {
      return DBUG_RETURN ( undef );
   }

   my $leap = _is_leap_year ($year);
   local $days_in_months[2] = $leap ? 29 : 28;

   my $doy = 0;
   for (my $m = 0; $m < $month; ++$m) {
      $doy += $days_in_months[$m];
   }
   $doy += $day;

   if ($remainder_flag) {
      my $total_days_in_year = $leap ? 366 : 365;
      $doy = $total_days_in_year - $doy;
   }

   DBUG_RETURN ($doy);
}

# ==============================================================

=item $date_str = adjust_date_str ( $date_str, $years, $months );

Takes a date string in B<YYYY-MM-DD> format and adjusts it by the given number
of months and years.  It returns the new date in B<YYYY-MM-Dd> format.

It does its best to preserve the day of month, but if it would exceed the number
of days in a month, it will truncate to the end of month.  Not round to the next
month.

Returns I<undef> if passed bad arguments.

=cut

sub adjust_date_str
{
   DBUG_ENTER_FUNC ( @_ );
   my $date_str   = shift;
   my $adj_years  = shift || 0;
   my $adj_months = shift || 0;

   # Validate the input date.
   my ($year, $month, $day) = _validate_date_str ($date_str);
   unless (defined $year &&
	   $adj_years =~ m/^[-]?\d+$/ && $adj_months =~ m/^[-]?\d+$/) {
      return DBUG_RETURN ( undef );
   }

   # Adjust by month ...
   if ( $adj_months >= 0 ) {
      foreach (1..${adj_months}) {
         if ( $month == 12 ) {
            $month = 1;
	    ++$adj_years;
	 } else {
            ++$month;
	 }
      }
   } else {
      foreach (1..-${adj_months}) {
         if ( $month == 1 ) {
            $month = 12;
	    --$adj_years;
	 } else {
            --$month;
	 }
      }
   }

   # Adjust the years ...
   $year += $adj_years;

   # Build the returned date ...
   my $leap = _is_leap_year ($year);
   local $days_in_months[2] = $leap ? 29 : 28;
   my $d = $days_in_months[$month];

   $date_str = sprintf ("%04d-%02d-%02d", $year, $month,
                                          ($day <= $d) ? $day : $d);

   DBUG_RETURN ($date_str);
}

# ==============================================================

=back

=head1 SOME EXAMPLE DATES

Here are some sample date strings in B<English> that this module can parse.
All for Christmas 2017.  This is not a complete list of available date formats
supported.  But should hopefully give you a starting point of what is possible.
Remember that if a date string contains extra info around the date part of it,
that extra information is thrown away.

S<12/25/2017>, B<S<Mon Dec 25th 2017 at 09:00>>, S<Mon 2017/12/25>, B<S<2017-12-25>>,
S<Monday December 25th, 2017 at 09:00>, B<S<12.25.2017>>, S<25-DEC-2017>,
B<S<25-DECEMBER-2017>>, S<20171225>, B<S<12252017>>,
S<Mon dec. 25th 00:00:00 2017>, B<S<2017 12 25 mon>>.

Most of the above examples will also work with 2-digit years as well.

And just to remind you that other languages are supported if L<Date::Language>
is installed, here's a date in Spanish that would be legal after
S<swap_language("Spanish")> was called.

=over 4

B<S<Lun Diciembre 25to 2017 18:05>>.

=back

=head1 COPYRIGHT

Copyright (c) 2018 - 2026 Curtis Leach.  All rights reserved.

This program is free software.  You can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 SEE ALSO

L<Advanced::Config> - The main user of this module.  It defines the Config object.

L<Advanced::Config::Options> - Handles the configuration of the Config module.

L<Advanced::Config::Reader> - Handles the parsing of the config file.

L<Advanced::Config::Examples> - Provides some sample config files and commentary.

L<Date::Language> - Provides foreign language support.

L<Date::Manip> - Provides additional foreign language support.

=cut

# ==============================================================
#required if module is included w/ require command;
1;

