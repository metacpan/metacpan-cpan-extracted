{
package Date::Components;

use 5.008008;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

eval {use Carp   qw(croak)};
eval {use Readonly};

our @EXPORT = qw();

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
our @EXPORT_OK = ( qw(
                      date_only_parse
                      is_valid_date
                      format_date
                      is_leap_year
                      is_valid_month
                      is_valid_day_of_month
                      is_valid_day_of_week
                      is_valid_year
                      is_valid_400_year_cycle
                      get_year_phase
                      number_of_day_within_year
                      day_number_within_year_to_date
                      day_number_within_400_year_cycle_to_date
                      get_number_of_day_within_400yr_cycle
                      get_days_remaining_in_400yr_cycle
                      day_name_to_day_number
                      day_number_to_day_name
                      get_num_days_in_year
                      get_days_remaining_in_year
                      get_numeric_day_of_week
                      get_month_from_string
                      get_dayofmonth_from_string
                      get_year_from_string
                      get_number_of_days_in_month
                      get_days_remaining_in_month
                      get_first_of_month_day_of_week
                      month_name_to_month_number
                      month_number_to_month_name
                      set_day_to_day_name_abbrev
                      set_day_to_day_name_full
                      set_day_to_day_number
                      set_month_to_month_name_abbrev
                      set_month_to_month_name_full
                      set_month_to_month_number
                      date1_to_date2_delta
                      number_of_weekdays_in_range
                      compare_date1_and_date2
                      year1_to_year2_delta
                      compare_year1_and_year2
                      date_offset_in_days
                      date_offset_in_weekdays
                      date_offset_in_years
                      calculate_day_of_week_for_first_of_month_in_next_year
                      get_global_year_cycle
                     ),
                 );

# This allows declaration use Date::Components ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = (
                    'all' => [ @EXPORT_OK, @EXPORT ],
                   );

use version; our $VERSION = qv('0.2.1');


# According to the Royal Greenwich Observatory, the calendar year is 365 days
# long, unless the year is exactly divisible by four, then an extra day is
# added to February so the year is 366 days long. If the year is the last year
# of a century, e.g., 2000, 2100, 2200, 2300, 2400, then it is only a leap
# year if it is exactly divisible by 400. So, 2100 won't be a leap year but
# 2000 is. The next century year, exactly divisible by 400, won't occur until
# 2400--400 years away.







Readonly my $DATE_BASELINE_YEAR_2000       => '2000';
#Readonly my $DATE_BASELINE_MONTHNUM        => '1';
#Readonly my $DATE_BASELINE_MONTHNAME       => 'January';
#Readonly my $DATE_BASELINE_DAYNUM          => '6';
#Readonly my $DATE_BASELINE_DAYNAME         => 'Saturday';
Readonly my $NUMBER_OF_YEAR_PHASES         => 400;
#Readonly my $MIN_NUMBER_OF_DAYS_IN_YEAR    => 365;
#Readonly my $MAX_NUMBER_OF_DAYS_IN_YEAR    => 366;
#Readonly my $MIN_NUMBER_OF_DAYS_IN_A_MONTH => 28;
#Readonly my $NUMBER_OF_MONTHS_IN_YEAR      => 12;

Readonly my $NUMBER_OF_DAYS_IN_400_YEAR_CYCLE => (300 * 365) + (100 * 366) - 3; # three is subtracted for the three of the four century years which are NOT leap years
Readonly my $BASELINE_DAY_OF_WEEK_ON_JAN_1_2000 => 6;



# Create READ ONLY hash to hold day of week on Jan 1 for each year phase
my %hash_intermediate_00;
$hash_intermediate_00{'0'} = $BASELINE_DAY_OF_WEEK_ON_JAN_1_2000;
for ( my $iii_003=1; $iii_003<$NUMBER_OF_YEAR_PHASES; $iii_003++ )
   {
   my $num_days_in_year_05 = get_num_days_in_year($iii_003 - 1);
   $hash_intermediate_00{$iii_003} = calculate_day_of_week_for_first_of_month_in_next_year( $num_days_in_year_05, $hash_intermediate_00{$iii_003 - 1} );
   }
Readonly my %DAY_OF_WEEK_ON_FIRST_OF_YEAR => %hash_intermediate_00;


# Create READ ONLY hash to hold day of week on each first of month for each year phase
my %hash_intermediate_01;
for ( my $iii_007=0; $iii_007<$NUMBER_OF_YEAR_PHASES; $iii_007++ )
   {
   $hash_intermediate_01{$iii_007}{1}  = get_first_of_month_day_of_week(  1, $iii_007 );
   $hash_intermediate_01{$iii_007}{2}  = get_first_of_month_day_of_week(  2, $iii_007 );
   $hash_intermediate_01{$iii_007}{3}  = get_first_of_month_day_of_week(  3, $iii_007 );
   $hash_intermediate_01{$iii_007}{4}  = get_first_of_month_day_of_week(  4, $iii_007 );
   $hash_intermediate_01{$iii_007}{5}  = get_first_of_month_day_of_week(  5, $iii_007 );
   $hash_intermediate_01{$iii_007}{6}  = get_first_of_month_day_of_week(  6, $iii_007 );
   $hash_intermediate_01{$iii_007}{7}  = get_first_of_month_day_of_week(  7, $iii_007 );
   $hash_intermediate_01{$iii_007}{8}  = get_first_of_month_day_of_week(  8, $iii_007 );
   $hash_intermediate_01{$iii_007}{9}  = get_first_of_month_day_of_week(  9, $iii_007 );
   $hash_intermediate_01{$iii_007}{10} = get_first_of_month_day_of_week( 10, $iii_007 );
   $hash_intermediate_01{$iii_007}{11} = get_first_of_month_day_of_week( 11, $iii_007 );
   $hash_intermediate_01{$iii_007}{12} = get_first_of_month_day_of_week( 12, $iii_007 );
   }

Readonly my %NUMERIC_DAY_OF_WEEK_ON_FIRST_OF_MONTH => %hash_intermediate_01;


# Preloaded methods go here.

###############################################################################
# Usage      : date_only_parse( SCALAR )
# Purpose    : converts variety of date strings into components for processing
# Returns    : - if parse is successful it returns a list:
#            :         (
#            :           month_integer<1-12>,
#            :           day_of_month_integer<1-N>,
#            :           year_integer,
#            :           numeric_day_of_week<1 for Mon ... 7 for Sun>
#            :         )
#            : - '' otherwise
# Parameters : text string containing date in various formats
# Throws     : Throws exception for any invalid input
# Comments   : Handles all years, even negative years (aka BC)
#            : Formats Parsed
#            :   - 'month_num/day_num/year'
#            :   - 'Mon Sep 17 08:50:51 2007'
#            :   - 'September 17, 2007'
#            :   - '17 September, 2007'
#            :   - 'YYYY-MM-DD' (ex: 2007-09-01 <Sep 1, 2007>)
# See Also   : N/A
###############################################################################
sub date_only_parse
   {
   my (
       $date_string_in_00,
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_03 = 1;
   ( @_ ==  $num_input_params_03 ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly $num_input_params_03 parameter(s), a date string in any format.   '@_'.\n\n\n";
   ( ref(\$_[0]) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the date string    '$_[0]'.\n\n\n";
   ( $_[0]  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the date string    '$_[0]'.\n\n\n";


   foreach ($date_string_in_00)
      {
      SWITCH:
         {
         if ( ( /^(\d{1,2})\/(\d{1,2})\/(\-{0,1}\d{1,})$/ )                                        &&  ( is_valid_date( $1, $2, $3 ) ) )        { return ( int($1), int($2), $3, get_numeric_day_of_week( $1, $2, $3 ) );                   last SWITCH; } # 'month_num/day_num/year'
         if ( ( /^([a-z]{3,3})\s+([a-z]{3,3})\s+(\d{1,2})\s+\d\d:\d\d:\d\d\s+(\-{0,1}\d{1,})$/i )  &&  ( is_valid_date( $2, $3, $4, $1 ) ) )    { return ( set_month_to_month_number($2), $3, $4, get_numeric_day_of_week( $2, $3, $4 ) );  last SWITCH; } # 'Mon Sep 17 08:50:51 2007'
         if ( ( /^([a-z]{3,})\s+(\d{1,2}),\s+(\-{0,1}\d{1,})$/i )                                  &&  ( is_valid_date( $1, $2, $3 ) ) )        { return ( set_month_to_month_number($1), $2, $3, get_numeric_day_of_week( $1, $2, $3 ) );  last SWITCH; } # 'September 17, 2007'
         if ( ( /^(\d{1,2})\s+([a-z]{3,}),\s+(\-{0,1}\d{1,})$/i )                                  &&  ( is_valid_date( $2, $1, $3 ) ) )        { return ( set_month_to_month_number($2), $1, $3, get_numeric_day_of_week( $2, $1, $3 ) );  last SWITCH; } # '17 September, 2007'
         if ( ( /^(\-{0,1}\d{1,})\-(\d{2,2})\-(\d{2,2})$/ )                                        &&  ( is_valid_date( $2, $3, $1 ) ) )        { return ( int($2), int($3), $1, get_numeric_day_of_week( $2, $3, $1 ) );                   last SWITCH; } # YYYY-MM-DD (ex: 2007-09-01 <Sep 1, 2007>)
#         if (  )    { $whatever = 1; last SWITCH; }
         return ( '' );
         }
      }


# TBD possibly add more formats
#   Dates parsed by Date::Parse
#    1995:01:24T09:08:17.1823213           ISO-8601
#    1995-01-24T09:08:17.1823213
#    Wed, 16 Jun 94 07:29:35 CST           Comma and day name are optional 
#    Thu, 13 Oct 94 10:13:13 -0700
#    Wed, 9 Nov 1994 09:50:32 -0500 (EST)  Text in ()'s will be ignored.
#    21/dec/93 17:05
   }




###############################################################################
# Usage      : Function is overloaded to accept one of three date input types
#            :    1) Date string
#            :       is_valid_date( SCALAR )
#            :    2) Month, dayofmonth, year
#            :       is_valid_date( SCALAR, SCALAR, SCALAR )
#            :    3) Month, dayofmonth, year, dayofweek
#            :       is_valid_date( SCALAR, SCALAR, SCALAR, SCALAR )
# Purpose    : checks if date is valid
# Returns    : - '1' if date is valid
#            : - ''  otherwise
# Parameters : 1) ( date string in any format )
#            :           OR
#            : 2) ( month, day of month, year )
#            :           OR
#            : 3) ( month, day of month, year, dayofweek )
# Throws     : No Exceptions
# Comments   : - Handles all years, even negative years (aka BC)
#            : - Month can be any of numeric, three character abbreviation or
#            :   full
#            : - Day of week can be any of numeric, three character
#            :   abbreviation or full
#            : - <1 for Jan ... 12 for Dec>
#            : - <1 for Mon ... 7 for Sun>
# See Also   : N/A
###############################################################################
sub is_valid_date
   {


   # Incoming Inspection
   if ( ( @_  !=  1 )  &&  ( @_  !=  3 )  &&  ( @_  !=  4 ) )
      {
      return ( '' );
      }


   my ( $month_input_00, $day_of_month_in_00, $year_in_00, $day_of_week_in_00 );
   my $month_num_00;
   if ( @_ ==  1 ) # recursive and back into 'is_valid_date' one time just to get date string parsed
      {
      my $date_in_04 = $_[0];
      if ( ref(\$date_in_04)  ne 'SCALAR' )
         {
         return ( '' );
         }

      if ( $date_in_04  eq  '' )
         {
         return ( '' );
         }

      if ( date_only_parse($date_in_04)  eq  '' )
         {
         return ( '' );
         }
      else
         {
         return ( '1' );
         }
      }
   elsif ( @_ ==  3 ) # day of week is NOT given by user
      {
      ( $month_input_00, $day_of_month_in_00, $year_in_00 ) = @_;
      if ( !(is_valid_month($month_input_00)) )
         {
         return ( '' );
         }

      if ( !(is_valid_year($year_in_00)) )
         {
         return ( '' );
         }

      if ( !(is_valid_day_of_month($month_input_00, $day_of_month_in_00, $year_in_00)) )
         {
         return ( '' );
         }
      }
   else # day of week IS given by user
      {
      ( $month_input_00, $day_of_month_in_00, $year_in_00, $day_of_week_in_00 ) = @_;
      if ( !(is_valid_month($month_input_00)) )
         {
         return ( '' );
         }

      if ( !(is_valid_year($year_in_00)) )
         {
         return ( '' );
         }

      if ( !(is_valid_day_of_month($month_input_00, $day_of_month_in_00, $year_in_00)) )
         {
         return ( '' );
         }

      if ( !(is_valid_day_of_week($day_of_week_in_00)) )
         {
         return ( '' );
         }
      }


   # Set to numeric forms
   $month_num_00 = set_month_to_month_number($month_input_00);

   my $day_of_week_on_day_n_00 = get_numeric_day_of_week(
                                                         $month_num_00,       # month in digits or alpha
                                                         $day_of_month_in_00, # day of month in digits
                                                         $year_in_00,         # year in digits
                                                        );

   # Check calculated day of week matches the input from user
   if ( $day_of_week_in_00 )
      {
      if ( set_day_to_day_number($day_of_week_in_00) != $day_of_week_on_day_n_00 )
         {
         return ( '' );
         }
      }

   return ( '1' );
   }




###############################################################################
# Usage      : calculate_day_of_week_for_first_of_month_in_next_year( SCALAR, SCALAR )
# Purpose    : calculates the day of the week on the first of the month twelve months from the current month
# Returns    : numeric day of week if successful
# Parameters : (
#            :  number of days between the first of the current month and the first of the month twelve months later,
#            :  alpha or numeric_day_of_week for first of current month <1 for Mon ... 7 for Sun>
#            : )
# Throws     : Throws exception for any invalid input
# Comments   : N/A
# See Also   : N/A
###############################################################################
sub calculate_day_of_week_for_first_of_month_in_next_year
   {
   my (
       $num_days_in_year_02,
       $day_of_week_on_first_of_month_00,
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_15 = 2;
   ( @_ ==  $num_input_params_15) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly $num_input_params_15 parameter(s), the number of days in a calender year (either 365 or 366).   '@_'.\n\n\n";
   ( ref(\$num_days_in_year_02) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the number of days in a calender year (either 365 or 366)    '$num_days_in_year_02'.\n\n\n";
   ( $num_days_in_year_02  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the number of days in a calender year (either 365 or 366)    '$num_days_in_year_02'.\n\n\n";
   ( ( $num_days_in_year_02  eq '365' )  ||  ( $num_days_in_year_02  eq '366' ) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a number (1-7) for the number of days in a calender year (either 365 or 366)    '$num_days_in_year_02'.\n\n\n";

   ( ref(\$day_of_week_on_first_of_month_00) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the day of the week for the first of a month    '$day_of_week_on_first_of_month_00'.\n\n\n";
   ( $day_of_week_on_first_of_month_00  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the day of the week for the first of a month    '$day_of_week_on_first_of_month_00'.\n\n\n";
   ( is_valid_day_of_week($day_of_week_on_first_of_month_00)  =~ m/^\d$/ ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a number (1-7) for the day of the week for the first of a month    '$day_of_week_on_first_of_month_00'.\n\n\n";

   $day_of_week_on_first_of_month_00 = set_day_to_day_number($day_of_week_on_first_of_month_00);


   $day_of_week_on_first_of_month_00 += ($num_days_in_year_02) % 7;
   if ( $day_of_week_on_first_of_month_00 > 7 )
      {
      $day_of_week_on_first_of_month_00 -=  7;
      }

   return ( $day_of_week_on_first_of_month_00 );
   }




###############################################################################
# Usage      : is_leap_year( SCALAR )
# Purpose    : determine if year is a leap year or not
# Returns    : - 'yes' if the input is a leap year
#            : - '' if the input is a NON leap year
# Parameters : (
#            :  year in integer form
#            : )
# Throws     : Throws exception for any invalid input
# Comments   : Handles all years, even negative years (aka BC)
# See Also   : N/A
###############################################################################
sub is_leap_year
   {
   my (
       $year_in_01,
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_01 = 1;
   ( @_ ==  $num_input_params_01) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly one parameter, a year number.   '@_'.\n\n\n";
   ( ref(\$year_in_01) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the year    '$year_in_01'.\n\n\n";
   ( $year_in_01  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the year    '$year_in_01'.\n\n\n";
   ( $year_in_01  =~ m/^\-{0,1}\d+$/ ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a number for the year    '$year_in_01'.\n\n\n";


   my $leap_year_status_01 = 'yes';
   if ( $year_in_01 % 4 > 0 )
      {
      $leap_year_status_01 = '';
      }
   if ( ( $year_in_01 % 100 == 0 )  &&  ( $year_in_01 % 400 > 0 ) )
      {
      $leap_year_status_01 = '';
      }

   return ( $leap_year_status_01 );
   }




###############################################################################
# Usage      : get_year_phase( SCALAR )
# Purpose    : determine the phase of the current year within the standard 400 year cycle
# Returns    : - year phase (0-399) for the given year if input is valid
# Parameters : (
#            :  year in integer form
#            : )
# Throws     : Throws exception for any invalid input
# Comments   : - Handles all years, even negative years (aka BC)
#            : - years repeat in a standard 400 year cycle where year 2000 is defined by this program to be phase '0' and year 2399 is then phase '399'
#            : - examples:  years -1, 399 and 1999 are all phase 399
#            :              years -400, 0, 1600 and 2000 are all phase 0
#            :              year  1946 is phase 346
# See Also   : N/A
###############################################################################
sub get_year_phase
   {
   my (
       $year_in_02,
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_02 = 1;
   ( @_ ==  $num_input_params_02) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly one parameter, a year number.   '@_'.\n\n\n";
   ( ref(\$year_in_02) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the year    '$year_in_02'.\n\n\n";
   ( $year_in_02  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the year    '$year_in_02'.\n\n\n";
   ( $year_in_02  =~ m/^\-{0,1}\d+$/ ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a number for the year    '$year_in_02'.\n\n\n";

   my $year_offset_00 = $year_in_02 - $DATE_BASELINE_YEAR_2000;
   my $year_phase_00;

   if ( $year_offset_00 > 0 )
      {
      $year_phase_00 = $year_offset_00 % $NUMBER_OF_YEAR_PHASES;
      }
   elsif ( $year_offset_00 < 0 )
      {
      $year_phase_00 = $NUMBER_OF_YEAR_PHASES - ( (-$year_offset_00) % $NUMBER_OF_YEAR_PHASES);
      if ( $year_phase_00  ==  400 )
         {
         $year_phase_00 = '0';
         }
      }
   else
      {
      $year_phase_00 = '';
      }

   if ( $year_phase_00 eq '')
      {
      $year_phase_00 = '0';
      }

   return ( $year_phase_00 );
   }




###############################################################################
# Usage      : number_of_day_within_year( SCALAR )
# Purpose    : get the day number within the year
# Returns    : integer day number if successful
# Parameters : (
#            :  text string containing date in various formats which are parsed
#            : )
# Throws     : Throws exception for any invalid input
# Comments   : Jan 31 ALWAYS returns '31' and Dec 31 returns either '365' or '366' depending upon leap year
# See Also   : N/A
###############################################################################
sub number_of_day_within_year
   {
   my (
       $date_in_00,
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_00 = 1;
   ( @_ ==  $num_input_params_00) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly one parameter, a date string.   '@_'.\n\n\n";
   ( ref(\$date_in_00) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the date string    '$date_in_00'.\n\n\n";
   ( $date_in_00  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the date string    '$date_in_00'.\n\n\n";
   ( date_only_parse($date_in_00) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Cannot extract the date from the input date string    '$date_in_00'.\n\n\n";

   my ( $month_num_01, $day_of_month_01, $year_num_01, $day_of_week_01 ) = date_only_parse($date_in_00);

   my $month_num_05 = set_month_to_month_number($month_num_01);


   my $number_of_day_in_year = $day_of_month_01;
   for ( my $iii_001=0; $iii_001<($month_num_05-1); $iii_001++ )
      {
      if ( $iii_001  ==  1 )
         {
         if ( is_leap_year($year_num_01) )
            {
            $number_of_day_in_year += get_number_of_days_in_month($iii_001+1, $year_num_01);
            }
         else
            {
            $number_of_day_in_year += get_number_of_days_in_month($iii_001+1, $year_num_01);
            }
         }
      else
         {
         $number_of_day_in_year += get_number_of_days_in_month($iii_001+1, $year_num_01);
         }
      }

   return ( $number_of_day_in_year ) ;
   }




###############################################################################
# Usage      : month_name_to_month_number( SCALAR )
# Purpose    : convert alpha month name to month number
# Returns    : integer month number (1-12) if successful
# Parameters : full or three character abbreviated month name
# Throws     : Throws exception for any invalid input
# Comments   : N/A
# See Also   : N/A
###############################################################################
sub month_name_to_month_number
   {
   my (
       $month_in_02,
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_14 = 1;
   ( @_ ==  $num_input_params_14) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly $num_input_params_14 parameter(s), a month string.   '@_'.\n\n\n";
   ( ref(\$month_in_02) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the month string    '$month_in_02'.\n\n\n";
   ( $month_in_02  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the month string    '$month_in_02'.\n\n\n";


   # Check for expected strings
   ( is_valid_month($month_in_02) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Cannot extract the month from the input month string    '$month_in_02'.\n\n\n";
   $month_in_02  =~  m/^(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec|January|February|March|April|May|June|July|August|September|October|November|December)$/i;


   foreach ( uc($1) )
      {
      SWITCH:
         {
         if ( /^(JAN|JANUARY)$/   )    { return (  1 ); last SWITCH; }
         if ( /^(FEB|FEBRUARY)$/  )    { return (  2 ); last SWITCH; }
         if ( /^(MAR|MARCH)$/     )    { return (  3 ); last SWITCH; }
         if ( /^(APR|APRIL)$/     )    { return (  4 ); last SWITCH; }
         if ( /^(MAY|MAY)$/       )    { return (  5 ); last SWITCH; }
         if ( /^(JUN|JUNE)$/      )    { return (  6 ); last SWITCH; }
         if ( /^(JUL|JULY)$/      )    { return (  7 ); last SWITCH; }
         if ( /^(AUG|AUGUST)$/    )    { return (  8 ); last SWITCH; }
         if ( /^(SEP|SEPTEMBER)$/ )    { return (  9 ); last SWITCH; }
         if ( /^(OCT|OCTOBER)$/   )    { return ( 10 ); last SWITCH; }
         if ( /^(NOV|NOVEMBER)$/  )    { return ( 11 ); last SWITCH; }
         if ( /^(DEC|DECEMBER)$/  )    { return ( 12 ); last SWITCH; }
         croak "\n\n   ($0)   '${\(caller(0))[3]}' This month of year condition, '$month_in_02', must be in alpha form.  Something is amiss.\n\n\n";
         }
      }
   }




###############################################################################
# Usage      : day_name_to_day_number( SCALAR )
# Purpose    : convert alpha day of week name to day of week number
# Returns    : integer day of week number (1-7) if successful
# Parameters : full or three character abbreviated day of week name
# Throws     : Throws exception for any invalid input
# Comments   : <1 for Mon ... 7 for Sun>
# See Also   : N/A
###############################################################################
sub day_name_to_day_number
   {
   my (
       $day_in_02,
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_05 = 1;
   ( @_ ==  $num_input_params_05) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly one parameter, a day string.   '@_'.\n\n\n";
   ( ref(\$day_in_02) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the day string    '$day_in_02'.\n\n\n";
   ( $day_in_02  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the day string    '$day_in_02'.\n\n\n";


   # Check for expected strings
   ( is_valid_day_of_week($day_in_02)  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Cannot extract the day from the input day string    '$day_in_02'.\n\n\n";
   $day_in_02  =~  m/^(\d|Mon|Tue|Wed|Thu|Fri|Sat|Sun|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)$/i;

   foreach ( uc($1) )
      {
      SWITCH:
         {
         if ( /^(MON|MONDAY)$/    )    { return (  1 ); last SWITCH; }
         if ( /^(TUE|TUESDAY)$/   )    { return (  2 ); last SWITCH; }
         if ( /^(WED|WEDNESDAY)$/ )    { return (  3 ); last SWITCH; }
         if ( /^(THU|THURSDAY)$/  )    { return (  4 ); last SWITCH; }
         if ( /^(FRI|FRIDAY)$/    )    { return (  5 ); last SWITCH; }
         if ( /^(SAT|SATURDAY)$/  )    { return (  6 ); last SWITCH; }
         if ( /^(SUN|SUNDAY)$/    )    { return (  7 ); last SWITCH; }
         croak "\n\n   ($0)   '${\(caller(0))[3]}' This day of week value, '$day_in_02', should not occur.  Something is amiss.\n\n\n";
         }
      }
   }




###############################################################################
# Usage      : month_number_to_month_name( SCALAR )
# Purpose    : convert month number to month alpha
# Returns    : three character abbreviated month name if successful
# Parameters : month number (1-12)
# Throws     : Throws exception for any invalid input
# Comments   : N/A
# See Also   : N/A
###############################################################################
sub month_number_to_month_name
   {
   my (
       $month_in_03,
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_06 = 1;
   ( @_ ==  $num_input_params_06) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly one parameter, a month number.   '@_'.\n\n\n";
   ( ref(\$month_in_03) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the month number    '$month_in_03'.\n\n\n";
   ( $month_in_03  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the month number    '$month_in_03'.\n\n\n";

   # Check for expected strings
   ( $month_in_03  =~  m/^(\d{1,2})$/i ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Cannot extract the month from the input month number    '$month_in_03'.\n\n\n";


   foreach ($1)
      {
      SWITCH:
         {
         if ( $_ ==  1 )    { return ( 'Jan' ); last SWITCH; }
         if ( $_ ==  2 )    { return ( 'Feb' ); last SWITCH; }
         if ( $_ ==  3 )    { return ( 'Mar' ); last SWITCH; }
         if ( $_ ==  4 )    { return ( 'Apr' ); last SWITCH; }
         if ( $_ ==  5 )    { return ( 'May' ); last SWITCH; }
         if ( $_ ==  6 )    { return ( 'Jun' ); last SWITCH; }
         if ( $_ ==  7 )    { return ( 'Jul' ); last SWITCH; }
         if ( $_ ==  8 )    { return ( 'Aug' ); last SWITCH; }
         if ( $_ ==  9 )    { return ( 'Sep' ); last SWITCH; }
         if ( $_ == 10 )    { return ( 'Oct' ); last SWITCH; }
         if ( $_ == 11 )    { return ( 'Nov' ); last SWITCH; }
         if ( $_ == 12 )    { return ( 'Dec' ); last SWITCH; }
         croak "\n\n   ($0)   '${\(caller(0))[3]}' This month of year value, '$month_in_03', should not occur.  Something is amiss.\n\n\n";
         }
      }
   }




###############################################################################
# Usage      : day_number_to_day_name( SCALAR )
# Purpose    : convert day of week number to day of week alpha
# Returns    : three character abbreviated day of week name if successful
# Parameters : day of week number (1-7) 
# Throws     : Throws exception for any invalid input
# Comments   : <1 for Mon ... 7 for Sun>
# See Also   : N/A
###############################################################################
sub day_number_to_day_name
   {
   my (
       $day_in_03,
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_07 = 1;
   ( @_ ==  $num_input_params_07) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly one parameter, a day number.   '@_'.\n\n\n";
   ( ref(\$day_in_03) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the day number    '$day_in_03'.\n\n\n";
   ( $day_in_03  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the day number    '$day_in_03'.\n\n\n";


   # Check for expected strings
   ( $day_in_03  =~  m/^(\d{1,2})$/i ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Cannot extract the day from the input day number    '$day_in_03'.\n\n\n";


   foreach ($1)
      {
      SWITCH:
         {
         if ( $_ ==  1 )    { return ( 'Mon' ); last SWITCH; }
         if ( $_ ==  2 )    { return ( 'Tue' ); last SWITCH; }
         if ( $_ ==  3 )    { return ( 'Wed' ); last SWITCH; }
         if ( $_ ==  4 )    { return ( 'Thu' ); last SWITCH; }
         if ( $_ ==  5 )    { return ( 'Fri' ); last SWITCH; }
         if ( $_ ==  6 )    { return ( 'Sat' ); last SWITCH; }
         if ( $_ ==  7 )    { return ( 'Sun' ); last SWITCH; }
         croak "\n\n   ($0)   '${\(caller(0))[3]}' This day of week value, '$day_in_03', should not occur.  Something is amiss.\n\n\n";
         }
      }
   }




###############################################################################
# Usage      : set_day_to_day_name_abbrev( SCALAR )
# Purpose    : set the incoming day of week to three letter abbreviation
# Returns    : three character abbreviated day of week name if successful
# Parameters : day of week in one of three formats ( numeric<1-7>, full name or three character abbreviated )
# Throws     : Throws exception for any invalid input
# Comments   : <1 for Mon ... 7 for Sun>
# See Also   : N/A
###############################################################################
sub set_day_to_day_name_abbrev
   {
   my (
       $day_in_04,
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_08 = 1;
   ( @_ ==  $num_input_params_08) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly one parameter, a day number or day alpha.   '@_'.\n\n\n";
   ( ref(\$day_in_04) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the day number or day alpha    '$day_in_04'.\n\n\n";
   ( $day_in_04  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the day number or day alpha    '$day_in_04'.\n\n\n";

   if ( $day_in_04  =~  m/^(\d{1,2})$/i )
      {
      return ( day_number_to_day_name($day_in_04) );
      }
   else
      {
      return ( day_number_to_day_name(day_name_to_day_number($day_in_04)) );
      }
   }




###############################################################################
# Usage      : set_day_to_day_name_full( SCALAR )
# Purpose    : set the incoming day of week to full name
# Returns    : day of week FULL name if successful
# Parameters : day of week in one of three formats ( numeric<1-7>, full name or three character abbreviated )
# Throws     : Throws exception for any invalid input
# Comments   : <1 for Monday ... 7 for Sunday>
# See Also   : N/A
###############################################################################
sub set_day_to_day_name_full
   {
   my (
       $day_in_06,
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_35 = 1;
   ( @_ ==  $num_input_params_35) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly ${num_input_params_35} parameter, a day number or day alpha.   '@_'.\n\n\n";
   ( ref(\$day_in_06) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the day number or day alpha    '$day_in_06'.\n\n\n";
   ( $day_in_06  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the day number or day alpha    '$day_in_06'.\n\n\n";
   ( is_valid_day_of_week($day_in_06) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a valid the day of the week in either alpha or numeric format    '$day_in_06'.\n\n\n";


   my $day_of_week_10 = set_day_to_day_number($day_in_06);
   foreach ($day_of_week_10)
      {
      SWITCH:
         {
         if ( $_ ==  1 )    { return ( 'Monday'    ); last SWITCH; }
         if ( $_ ==  2 )    { return ( 'Tuesday'   ); last SWITCH; }
         if ( $_ ==  3 )    { return ( 'Wednesday' ); last SWITCH; }
         if ( $_ ==  4 )    { return ( 'Thursday'  ); last SWITCH; }
         if ( $_ ==  5 )    { return ( 'Friday'    ); last SWITCH; }
         if ( $_ ==  6 )    { return ( 'Saturday'  ); last SWITCH; }
                              return ( 'Sunday'    );
         }
      }
   }




###############################################################################
# Usage      : set_month_to_month_name_abbrev( SCALAR )
# Purpose    : set the incoming month to three letter abbreviation
# Returns    : three character abbreviated month name if successful
# Parameters : month in one of three formats ( numeric<1-12>, full name or three character abbreviated )
# Throws     : Throws exception for any invalid input
# Comments   : N/A
# See Also   : N/A
###############################################################################
sub set_month_to_month_name_abbrev
   {
   my (
       $month_in_04,
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_09 = 1;
   ( @_ ==  $num_input_params_09) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly one parameter, a month number or month alpha.   '@_'.\n\n\n";
   ( ref(\$month_in_04) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the month number or month alpha    '$month_in_04'.\n\n\n";
   ( $month_in_04  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the month number or month alpha    '$month_in_04'.\n\n\n";

   if ( $month_in_04  =~  m/^(\d{1,2})$/i )
      {
      return ( month_number_to_month_name($month_in_04) );
      }
   else
      {
      return ( month_number_to_month_name(month_name_to_month_number($month_in_04)) );
      }
   }




###############################################################################
# Usage      : set_month_to_month_name_full( SCALAR )
# Purpose    : set the incoming month to full name
# Returns    : month FULL name if successful
# Parameters : month in one of three formats ( numeric<1-12>, full name or three character abbreviated )
# Throws     : Throws exception for any invalid input
# Comments   : N/A
# See Also   : N/A
###############################################################################
sub set_month_to_month_name_full
   {
   my (
       $month_in_07,
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_34 = 1;
   ( @_ ==  $num_input_params_34) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly ${num_input_params_34} parameter, a month number or month alpha.   '@_'.\n\n\n";
   ( ref(\$month_in_07) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the month number or month alpha    '$month_in_07'.\n\n\n";
   ( $month_in_07  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the month number or month alpha    '$month_in_07'.\n\n\n";
   ( is_valid_month($month_in_07) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Cannot extract the month from the input month string    '$month_in_07'.\n\n\n";


   my $month_num_15 = set_month_to_month_number($month_in_07);
   foreach ($month_num_15)
      {
      SWITCH:
         {
         if ( $_ ==  1 )    { return ( 'January'   ); last SWITCH; }
         if ( $_ ==  2 )    { return ( 'February'  ); last SWITCH; }
         if ( $_ ==  3 )    { return ( 'March'     ); last SWITCH; }
         if ( $_ ==  4 )    { return ( 'April'     ); last SWITCH; }
         if ( $_ ==  5 )    { return ( 'May'       ); last SWITCH; }
         if ( $_ ==  6 )    { return ( 'June'      ); last SWITCH; }
         if ( $_ ==  7 )    { return ( 'July'      ); last SWITCH; }
         if ( $_ ==  8 )    { return ( 'August'    ); last SWITCH; }
         if ( $_ ==  9 )    { return ( 'September' ); last SWITCH; }
         if ( $_ == 10 )    { return ( 'October'   ); last SWITCH; }
         if ( $_ == 11 )    { return ( 'November'  ); last SWITCH; }
                              return ( 'December'  );
         }
      }
   }




###############################################################################
# Usage      : set_day_to_day_number( SCALAR )
# Purpose    : set the incoming day of week to day of week number
# Returns    : numeric<1-7> if successful
# Parameters : day of week in one of three formats ( numeric<1-7>, full name or three character abbreviated )
# Throws     : Throws exception for any invalid input
# Comments   : <1 for Mon ... 7 for Sun>
# See Also   : N/A
###############################################################################
sub set_day_to_day_number
   {
   my (
       $day_in_05,
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_10 = 1;
   ( @_ ==  $num_input_params_10) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly one parameter, a day number or day alpha.   '@_'.\n\n\n";
   ( ref(\$day_in_05) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the day number or day alpha    '$day_in_05'.\n\n\n";
   ( $day_in_05  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the day number or day alpha    '$day_in_05'.\n\n\n";

   if ( !( $day_in_05  =~  m/^(\d{1,2})$/i ) )
      {
      return ( day_name_to_day_number($day_in_05) );
      }
   else
      {
      return ( day_name_to_day_number(day_number_to_day_name($day_in_05)) );
      }
   }




###############################################################################
# Usage      : set_month_to_month_number( SCALAR )
# Purpose    : set the incoming month to month number
# Returns    : numeric month <1-12> if successful
# Parameters : month in one of three formats ( numeric<1-12>, full name or three character abbreviated )
# Throws     : Throws exception for any invalid input
# Comments   : N/A
# See Also   : N/A
###############################################################################
sub set_month_to_month_number
   {
   my (
       $month_in_06,
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_11 = 1;
   ( @_ ==  $num_input_params_11) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly one parameter, a month number or month alpha.   '@_'.\n\n\n";
   ( ref(\$month_in_06) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the month number or month alpha    '$month_in_06'.\n\n\n";
   ( $month_in_06  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the month number or month alpha    '$month_in_06'.\n\n\n";

   if ( !( $month_in_06  =~  m/^(\d{1,2})$/i ) )
      {
      return ( month_name_to_month_number($month_in_06) );
      }
   else
      {
      return ( month_name_to_month_number(month_number_to_month_name($month_in_06)) );
      }
   }




###############################################################################
# Usage      : get_num_days_in_year( SCALAR )
# Purpose    : determine number of days in given year
# Returns    : - '366' if the input is a leap year
#            : - '365' if the input is a NON leap year
# Parameters : (
#            :  year in integer form
#            : )
# Throws     : Throws exception for any invalid input
# Comments   : Handles all years, even negative years (aka BC)
# See Also   : N/A
###############################################################################
sub get_num_days_in_year
   {
   my (
       $year_in_03,
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_04 = 1;
   ( @_ ==  $num_input_params_04) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly one parameter, a year number.   '@_'.\n\n\n";
   ( ref(\$year_in_03) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the year    '$year_in_03'.\n\n\n";
   ( $year_in_03  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the year    '$year_in_03'.\n\n\n";
   ( $year_in_03  =~ m/^\-{0,1}\d+$/ ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a number for the year    '$year_in_03'.\n\n\n";

   if ( is_leap_year($year_in_03) ne '' )
      {
      return ( 366 );
      }
   else
      {
      return ( 365 );
      }
   }




###############################################################################
# Usage      : date1_to_date2_delta( SCALAR, SCALAR )
# Purpose    : finds the difference in days between the two dates by subtracting the second from the first
# Returns    : integer day count if successful
# Parameters : (
#            :   date ONE in any format,
#            :   date TWO in any format
#            : )
# Throws     : Throws exception for any invalid input
# Comments   : if day ONE is EARLIER than date TWO, a negative number is returned
# See Also   : N/A
###############################################################################
sub date1_to_date2_delta
   {
   my (
       $date_one_00,
       $date_two_00
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_12 = 2;
   ( @_ ==  $num_input_params_12) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly $num_input_params_12 parameters ('date1' and date2).   '@_'.\n\n\n";

   ( ref(\$date_one_00) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR first parameter for the first date    '$date_one_00'.\n\n\n";
   ( ref(\$date_two_00) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR second parameter for the second date    '$date_two_00'.\n\n\n";

   ( $date_one_00  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the first date    '$date_one_00'.\n\n\n";
   ( $date_two_00  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the second date    '$date_two_00'.\n\n\n";

   ( date_only_parse($date_one_00) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Cannot extract the date from the input date1 string    '$date_one_00'.\n\n\n";
   ( date_only_parse($date_two_00) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Cannot extract the date from the input date2 string    '$date_two_00'.\n\n\n";

   my $date_one_02;
   my $date_two_02;
   my $date_compare_00 = compare_date1_and_date2($date_one_00, $date_two_00);

   if ( ( $date_compare_00  ne  '0' )  &&  ( $date_compare_00  ne  '-1' )  &&  ( $date_compare_00  ne  '1' ) )
      {
      croak "\n\n   ($0)   '${\(caller(0))[3]}' This condition should NOT occur.  date_compare_00 has a value of '$date_compare_00' and only one of '1', '-1' or '0' is expected.\n\n\n";
      }


   if ( $date_compare_00  eq  '0' )
      {
      return ('0');
      }
   if ( $date_compare_00  eq  '-1' )
      {
      $date_one_02 = $date_two_00;
      $date_two_02 = $date_one_00;
      }
   if ( $date_compare_00  eq  '1' )
      {
      $date_one_02 = $date_one_00;
      $date_two_02 = $date_two_00;
      }


   my ( $date1_month_num_02, $date1_day_of_month_02, $date1_year_num_02, $date1_day_of_week_02 ) = date_only_parse($date_one_02);
   my ( $date2_month_num_02, $date2_day_of_month_02, $date2_year_num_02, $date2_day_of_week_02 ) = date_only_parse($date_two_02);


   my $year_phase_date_one_00;
   my $which_400yr_cycle_occurrence_for_date_one_02;
   if ( $date1_year_num_02 >= 0 )
      {
      $which_400yr_cycle_occurrence_for_date_one_02 = int( $date1_year_num_02  /  $NUMBER_OF_YEAR_PHASES );
      $year_phase_date_one_00 = get_year_phase( $date1_year_num_02 );
      }
   else
      {
      $which_400yr_cycle_occurrence_for_date_one_02 = int( ($date1_year_num_02+1)  /  $NUMBER_OF_YEAR_PHASES ) - 1;
      $year_phase_date_one_00 =  $NUMBER_OF_YEAR_PHASES - ( -$date1_year_num_02 % $NUMBER_OF_YEAR_PHASES );
      if ( $year_phase_date_one_00  >=  $NUMBER_OF_YEAR_PHASES )
         {
         $year_phase_date_one_00  -=  $NUMBER_OF_YEAR_PHASES;
         }
      }

   my $year_phase_date_two;
   my $which_400yr_cycle_occurrence_for_date_two_02;
   if ( $date2_year_num_02 >= 0 )
      {
      $which_400yr_cycle_occurrence_for_date_two_02 = int( $date2_year_num_02  /  $NUMBER_OF_YEAR_PHASES );
      $year_phase_date_two = get_year_phase( $date2_year_num_02 );
      }
   else
      {
      $which_400yr_cycle_occurrence_for_date_two_02 = int( ($date2_year_num_02+1)  /  $NUMBER_OF_YEAR_PHASES ) - 1;
      $year_phase_date_two =  $NUMBER_OF_YEAR_PHASES - ( -$date2_year_num_02 % $NUMBER_OF_YEAR_PHASES );
      if ( $year_phase_date_two  >=  $NUMBER_OF_YEAR_PHASES )
         {
         $year_phase_date_two  -=  $NUMBER_OF_YEAR_PHASES;
         }
      }


   my $num_days_in_year1_phases_00 = 0;
   for ( my $iii_005=0; $iii_005<$year_phase_date_one_00; $iii_005++ )
      {
      $num_days_in_year1_phases_00 += get_num_days_in_year( 2000 + $iii_005 );  # sum the days of whole years
      }
   $num_days_in_year1_phases_00 += number_of_day_within_year( $date_one_02 );  # sum the days of the year up to the given day


   my $num_days_in_year2_phases = 0;
   for ( my $iii_006=0; $iii_006<$year_phase_date_two; $iii_006++ )
      {
      $num_days_in_year2_phases += get_num_days_in_year( 2000 + $iii_006 );  # sum the days of whole years
      }
   $num_days_in_year2_phases += number_of_day_within_year( $date_two_02 );  # sum the days of the year up to the given day


   my $date_diff_00 = '';
   if ( $which_400yr_cycle_occurrence_for_date_one_02  ==  $which_400yr_cycle_occurrence_for_date_two_02 )
      {
      $date_diff_00 = $num_days_in_year1_phases_00 - $num_days_in_year2_phases;
      }
   elsif ( $which_400yr_cycle_occurrence_for_date_one_02  ==  ( $which_400yr_cycle_occurrence_for_date_two_02 + 1 ) )
      {
      $date_diff_00 = $num_days_in_year1_phases_00 + ( $NUMBER_OF_DAYS_IN_400_YEAR_CYCLE - $num_days_in_year2_phases );
      }
#   elsif ( $which_400yr_cycle_occurrence_for_date_one_02  >  ( $which_400yr_cycle_occurrence_for_date_two_02 + 1 ) )
   else
      {
      $date_diff_00  = ($which_400yr_cycle_occurrence_for_date_one_02  - ($which_400yr_cycle_occurrence_for_date_two_02 + 1 )) * ( $NUMBER_OF_DAYS_IN_400_YEAR_CYCLE);
      $date_diff_00 += $num_days_in_year1_phases_00 + ( $NUMBER_OF_DAYS_IN_400_YEAR_CYCLE - $num_days_in_year2_phases );
      }


   if ( $date_compare_00  ==  1 )
      {
      return ( $date_diff_00 );
      }
   else
      {
      return ( -$date_diff_00 );
      }
   }




###############################################################################
# Usage      : is_valid_month( SCALAR )
# Purpose    : checks if month is valid
# Returns    : - '1' if month is valid
#            : - ''  otherwise
# Parameters : (
#            :  alpha or month integer<1-12>,
#            : )
# Throws     : No Exceptions
# Comments   : N/A
# See Also   : N/A
###############################################################################
sub is_valid_month
   {
   my (
       $month_input_01,
      )
       = @_;


   # Incoming Inspection
   if ( @_  !=  1 )
      {
      return ( '' );
      }

   if ( ref(\$month_input_01)  ne 'SCALAR' )
      {
      return ( '' );
      }

   if ( $month_input_01  eq  '' )
      {
      return ( '' );
      }


   # Check for expected strings
   if ( !( $month_input_01  =~  m/^(\d{1,2}|Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec|January|February|March|April|May|June|July|August|September|October|November|December)$/i ) )
      {
      return ( '' );
      }


   # Check numeric form of Month of Year for acceptable value
   if ( $month_input_01 =~ m/^(\d{1,2})$/ )
      {
      if ( ( $1 < 1 )  ||  ( $1 > 12 ) )
         {
         return ( '' );
         }
      }

   return ( 1 );
   }




###############################################################################
# Usage      : is_valid_day_of_month( SCALAR, SCALAR, SCALAR )
# Purpose    : checks if day of month is valid
# Returns    : - '1' if day of month is valid
#            : - ''  otherwise
# Parameters : (
#            :  alpha or month integer<1-12>,
#            :  day of month integer<1-N>,
#            :  year integer,
#            : )
# Throws     : No Exceptions
# Comments   : Handles all years, even negative years (aka BC)
# See Also   : N/A
###############################################################################
sub is_valid_day_of_month
   {
   my (
       $month_input_02,
       $day_of_month_input_00,
       $year_input_01,
      )
       = @_;


   # Incoming Inspection
   if ( @_  !=  3 )
      {
      return ( '' );
      }

   if ( ref(\$day_of_month_input_00)  ne 'SCALAR' )
      {
      return ( '' );
      }

   if ( $day_of_month_input_00  eq  '' )
      {
      return ( '' );
      }

   if ( !(is_valid_month($month_input_02)) )
      {
      return ( '' );
      }
   my $month_num_03 = set_month_to_month_number($month_input_02);

   if ( !(is_valid_year($year_input_01)) )
      {
      return ( '' );
      }


   if ( !( ( $day_of_month_input_00 =~ m/^(\d{1,2})$/ )  &&  ( $1 > 0 )  &&  ( $1 < 32 ) ) )
      {
      return ( '' );
      }


   # Check for out of range day_of_month numbers
   # Months with 30 days ( April June September November )
   if ( ( ( $month_num_03 == 4 )  ||  ( $month_num_03 == 6 )  ||  ( $month_num_03 == 9 )  ||  ( $month_num_03 == 11 ) )  &&  ( $day_of_month_input_00 > 30 ) )
      {
      return ( '' );
      }
   # February (NON leap year)
#   elsif ( ( $month_num_03 == 2 )  &&  (!( is_leap_year($year_input_01) ))  &&  ( $day_of_month_input_00  >  28 ) )
   if ( ( $month_num_03 == 2 )  &&  (!( is_leap_year($year_input_01) ))  &&  ( $day_of_month_input_00  >  28 ) )
      {
      return ( '' );
      }
   # February (leap year)
#   elsif ( ( $month_num_03 == 2 )  &&    ( is_leap_year($year_input_01) )   &&  ( $day_of_month_input_00  >  29 ) )
   if ( ( $month_num_03 == 2 )  &&  ( is_leap_year($year_input_01) )   &&  ( $day_of_month_input_00  >  29 ) )
      {
      return ( '' );
      }
   # Months with 31 days
#   elsif ( ( $month_num_03 > 0 )  &&  ( $month_num_03 < 13 )  &&  ( $day_of_month_input_00 > 31 ) )
#      {
#      return ( '' );
#      }


   return ( 1 );
   }




###############################################################################
# Usage      : is_valid_day_of_week( SCALAR )
# Purpose    : checks if day of week is valid
# Returns    : - '1' if day of week is valid
#            : - ''  otherwise
# Parameters : (
#            :  day of week in one of three formats ( numeric<1-7>, full name or three character abbreviated )
#            : )
# Throws     : No Exceptions
# Comments   : <1 for Mon ... 7 for Sun>
# See Also   : N/A
###############################################################################
sub is_valid_day_of_week
   {
   my (
       $day_of_week_input_00,
      )
       = @_;


   # Incoming Inspection
   if ( @_  !=  1 )
      {
      return ( '' );
      }

   if ( ref(\$day_of_week_input_00)  ne 'SCALAR' )
      {
      return ( '' );
      }

   if ( $day_of_week_input_00  eq  '' )
      {
      return ( '' );
      }


   if ( !( $day_of_week_input_00  =~  m/^(\d|Mon|Tue|Wed|Thu|Fri|Sat|Sun|Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)$/i ) )
      {
      return ( '' );
      }


   # Check numeric form of day of week for valid value
   if ( $day_of_week_input_00 =~ m/^(\d)$/ )
      {
      if (  ( $1 < 1 )  ||  ( $1 > 7 )  )
         {
         return ( '' );
         }
      }

   return ( 1 );
   }




###############################################################################
# Usage      : is_valid_year( SCALAR )
# Purpose    : checks if year is valid
# Returns    : - '1' if year is valid
#            : - ''  otherwise
# Parameters : (
#            :  year in integer format
#            : )
# Throws     : No Exceptions
# Comments   : Handles all years, even negative years (aka BC)
# See Also   : N/A
###############################################################################
sub is_valid_year
   {
   my (
       $year_input_00,
      )
       = @_;


   # Incoming Inspection
   if ( @_  !=  1 )
      {
      return ( '' );
      }

   if ( ref(\$year_input_00)  ne 'SCALAR' )
      {
      return ( '' );
      }

   if ( $year_input_00  eq  '' )
      {
      return ( '' );
      }

   if ( !( $year_input_00  =~  m/^\-{0,1}\d{1,}$/ ) )
      {
      return ( '' );
      }

   return ( 1 );
   }




###############################################################################
# Usage      : is_valid_400_year_cycle( SCALAR )
# Purpose    : checks if year is valid 400 year cycle phase number
# Returns    : - '1' if year is valid 400 year cycle phase number
#            : - ''  otherwise
# Parameters : (
#            :  year in integer format
#            : )
# Throws     : No Exceptions
# Comments   : valid years are multiples of 400 (i.e.  ... -400, 0, 400, ... 1600, 2000, 2400, ...)
# See Also   : N/A
###############################################################################
sub is_valid_400_year_cycle
   {
   my (
       $four_hundred_year_cycle_01,
      )
       = @_;


   # Incoming Inspection
   if ( @_  !=  1 )
      {
      return ( '' );
      }

   if ( ref(\$four_hundred_year_cycle_01)  ne 'SCALAR' )
      {
      return ( '' );
      }

   if ( $four_hundred_year_cycle_01  eq  '' )
      {
      return ( '' );
      }

   if ( !( ( $four_hundred_year_cycle_01  =~  m/^\-{0,1}(\d+)$/ )  &&  ( ( $1 % $NUMBER_OF_YEAR_PHASES )  ==  0 ) ) )
      {
      return ( '' );
      }

   return ( 1 );
   }




###############################################################################
# Usage      : compare_date1_and_date2( SCALAR, SCALAR )
# Purpose    : compares two dates to find which one is later
# Returns    : -  '1' if the FIRST date is LATER   than the second
#            : - '-1' if the FIRST date is EARLIER than the second
#            : -  '0' if both dates are the same
# Parameters : (
#            :   date ONE in any format,
#            :   date TWO in any format
#            : )
# Throws     : Throws exception for any invalid input
# Comments   : N/A
# See Also   : N/A
###############################################################################
sub compare_date1_and_date2
   {
   my (
       $date_one_01,
       $date_two_01
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_18 = 2;
   ( @_ ==  $num_input_params_18) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly $num_input_params_18 parameter(s), two date strings.   '@_'.\n\n\n";

   ( ref(\$date_one_01) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the first date string    '$date_one_01'.\n\n\n";
   ( $date_one_01  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the first date string    '$date_one_01'.\n\n\n";
   ( date_only_parse($date_one_01) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Cannot parse the date from the first input date string    '$date_one_01'.\n\n\n";

   ( ref(\$date_two_01) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the second date string    '$date_two_01'.\n\n\n";
   ( $date_two_01  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the second date string    '$date_two_01'.\n\n\n";
   ( date_only_parse($date_two_01) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Cannot parse the date from the second input date string    '$date_two_01'.\n\n\n";



   my ( $date1_month_num_03, $date1_day_of_month_03, $date1_year_num_03, $date1_day_of_week_03 ) = date_only_parse($date_one_01);
   my ( $date2_month_num_03, $date2_day_of_month_03, $date2_year_num_03, $date2_day_of_week_03 ) = date_only_parse($date_two_01);


   my $date1_month_num_04 = set_month_to_month_number($date1_month_num_03);
   my $date2_month_num_04 = set_month_to_month_number($date2_month_num_03);

   my $compare_date_1_and_date_2_00 = '';
   if ( $date1_year_num_03  >  $date2_year_num_03 )
      {
      $compare_date_1_and_date_2_00 = '1';
      }
   elsif ( ( $date1_year_num_03  ==  $date2_year_num_03 )  &&  ( $date1_month_num_04  >  $date2_month_num_04 ) )
      {
      $compare_date_1_and_date_2_00 = '1';
      }
   elsif ( ( $date1_year_num_03  ==  $date2_year_num_03 )  &&  ( $date1_month_num_04  ==  $date2_month_num_04 )  &&  ( $date1_day_of_month_03  >  $date2_day_of_month_03 ) )
      {
      $compare_date_1_and_date_2_00 = '1';
      }
   elsif ( ( $date1_year_num_03  ==  $date2_year_num_03 )  &&  ( $date1_month_num_04  ==  $date2_month_num_04 )  &&  ( $date1_day_of_month_03  ==  $date2_day_of_month_03 ) )
      {
      $compare_date_1_and_date_2_00 = '0';
      }
   else
      {
      $compare_date_1_and_date_2_00 = '-1';
      }

   return ( $compare_date_1_and_date_2_00 );
   }




###############################################################################
# Usage      : date_offset_in_days( SCALAR, SCALAR )
# Purpose    : find a date in the future or past offset by the number of days from the given date
# Returns    : - date of the day offset from the given date if successful
# Parameters : (
#            :   date in any format,
#            :   number of days offset, positive is future date, negative is past date, zero is current date (no offset)
#            : )
# Throws     : Throws exception for any invalid input
# Comments   : N/A
# See Also   : N/A
###############################################################################
sub date_offset_in_days
   {
   my (
       $date_in_01,
       $date_delta_00
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_19 = 2;
   ( @_ ==  $num_input_params_19) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly $num_input_params_19 parameter(s), a date string followed by the number of offset days.   '@_'.\n\n\n";

   ( ref(\$date_in_01) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the date string    '$date_in_01'.\n\n\n";
   ( $date_in_01  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the date string    '$date_in_01'.\n\n\n";
   ( date_only_parse($date_in_01) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Cannot parse the date from the input date string    '$date_in_01'.\n\n\n";

   ( ref(\$date_delta_00) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the number of offset days    '$date_delta_00'.\n\n\n";
   ( $date_delta_00  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty value for the number of offset days    '$date_delta_00'.\n\n\n";
   ( $date_delta_00  =~ m/^\-{0,1}\d+$/ ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects an integer value, positive, negative or zero, for the number of offset days    '$date_delta_00'.\n\n\n";


   if ( $date_delta_00  ==  0 )
      {
      return ( format_date( $date_in_01 ) );
      }


   my ( $date1_month_num_05, $date1_day_of_month_05, $date1_year_num_05, $date1_day_of_week_05 ) = date_only_parse($date_in_01);

   # Total the number of 400 year cycles included in the offset day count
   my $number_of_complete_year_cycles_00 = int( abs($date_delta_00) / $NUMBER_OF_DAYS_IN_400_YEAR_CYCLE );

   # Day offset by multiples of COMPLETE four hundred year cycles
   my $offset_year_00;
   if (  $date_delta_00  >=  0  )
      {
      $offset_year_00 = $date1_year_num_05 + ( $number_of_complete_year_cycles_00 * $NUMBER_OF_YEAR_PHASES );
      }
   else
      {
      $offset_year_00 = $date1_year_num_05 - ( $number_of_complete_year_cycles_00 * $NUMBER_OF_YEAR_PHASES );
      }
   my $offset_month_00        = $date1_month_num_05;
   my $offset_day_of_month_00 = $date1_day_of_month_05;

   my $days_left_00;
   my $days_left_in_offset_400_year_cycle = get_days_remaining_in_400yr_cycle( $date1_month_num_05, $date1_day_of_month_05, $offset_year_00 );
   my $days_used_in_offset_400_year_cycle = get_number_of_day_within_400yr_cycle( $date1_month_num_05, $date1_day_of_month_05, $offset_year_00 );
   my $day_num_in_400_year_cycle_01;
   if (  $date_delta_00  >=  0  )
      {
      $days_left_00 = int( $date_delta_00 % $NUMBER_OF_DAYS_IN_400_YEAR_CYCLE );


      if ( $days_left_in_offset_400_year_cycle  >=  $days_left_00 )
         {
         $day_num_in_400_year_cycle_01 = $days_used_in_offset_400_year_cycle + $days_left_00;
         }
      else
         {
         $day_num_in_400_year_cycle_01 = $days_left_00 - $days_left_in_offset_400_year_cycle;
         $offset_year_00 += $NUMBER_OF_YEAR_PHASES;
         }
      }
   else
      {
      $days_left_00 = int( abs($date_delta_00) % $NUMBER_OF_DAYS_IN_400_YEAR_CYCLE );


      if ( $days_used_in_offset_400_year_cycle  >  $days_left_00 )
         {
         $day_num_in_400_year_cycle_01 = $days_used_in_offset_400_year_cycle - $days_left_00;
         }
      else
         {
         $day_num_in_400_year_cycle_01 = $NUMBER_OF_DAYS_IN_400_YEAR_CYCLE - ($days_left_00 - $days_used_in_offset_400_year_cycle);
         $offset_year_00 -= $NUMBER_OF_YEAR_PHASES;
         }
      }

   my $which_400_year_cycle_00 = get_global_year_cycle($offset_year_00);

   $day_num_in_400_year_cycle_01 = day_number_within_400_year_cycle_to_date( $which_400_year_cycle_00, $day_num_in_400_year_cycle_01 );

   return ( format_date( $day_num_in_400_year_cycle_01 ) );
   }




###############################################################################
# Usage      : get_global_year_cycle( SCALAR )
# Purpose    : get the phase zero year for the given year
# Returns    : - the phase zero year containing the given year if input is valid
# Parameters : (
#            :  year in integer format
#            : )
# Throws     : Throws exception for any invalid input
# Comments   : - Handles all years, even negative years (aka BC)
#            : - years repeat in a standard 400 year cycle where year 2000 is defined by this program to be phase '0' and year 2399 is then phase '399'
#            : - Examples
#            :        years 1600 through 1999 return the phase zero year 1600 
#            :        year 2007  returns the phase zero year 2000 
# See Also   : N/A
###############################################################################
sub get_global_year_cycle
   {
   my (
       $year_input_08
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_20 = 1;
   ( @_ ==  $num_input_params_20) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly $num_input_params_20 parameter(s), a date string followed by the number of offset days.   '@_'.\n\n\n";

   ( ref(\$year_input_08) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the year number    '$year_input_08'.\n\n\n";
   ( $year_input_08  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty value for the year number    '$year_input_08'.\n\n\n";
   ( is_valid_year($year_input_08) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects an integer value, positive, negative or zero, for the year number    '$year_input_08'.\n\n\n";


  my $which_400_year_cycle_01;
  if (  $year_input_08  >=  0  )
     {
     $which_400_year_cycle_01 = int( $year_input_08 / $NUMBER_OF_YEAR_PHASES ) * $NUMBER_OF_YEAR_PHASES;
     }
  else
     {
     if ( ( abs($year_input_08) % $NUMBER_OF_YEAR_PHASES )  ==  0 )
        {
        $which_400_year_cycle_01 = int( $year_input_08 / $NUMBER_OF_YEAR_PHASES ) * $NUMBER_OF_YEAR_PHASES;
        }
     else
        {
        $which_400_year_cycle_01 = int( $year_input_08 / $NUMBER_OF_YEAR_PHASES ) * $NUMBER_OF_YEAR_PHASES - $NUMBER_OF_YEAR_PHASES;
        }
     }

   return ( $which_400_year_cycle_01 );
   }




###############################################################################
# Usage      : get_number_of_days_in_month( SCALAR, SCALAR )
# Purpose    : get the number of days in a specific month
# Returns    : - number of days in the month if successful
# Parameters : (
#            :  alpha or month integer<1-12>,
#            :  year integer,
#            : )
# Throws     : Throws exception for any invalid input
# Comments   : Handles all years, even negative years (aka BC)
# See Also   : N/A
###############################################################################
sub get_number_of_days_in_month
   {
   my (
       $month_input_04,
       $year_input_02,
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_21 = 2;
   ( @_ ==  $num_input_params_21) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly $num_input_params_21 parameter(s), (month, year).   '@_'.\n\n\n";

   ( ref(\$month_input_04) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the month    '$month_input_04'.\n\n\n";
   ( $month_input_04  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty value for the month    '$month_input_04'.\n\n\n";
   ( is_valid_month($month_input_04) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a valid month    '$month_input_04'.\n\n\n";

   ( ref(\$year_input_02) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the year number    '$year_input_02'.\n\n\n";
   ( $year_input_02  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty value for the year number    '$year_input_02'.\n\n\n";
   ( is_valid_year($year_input_02) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects an integer value, positive, negative or zero, for the year number    '$year_input_02'.\n\n\n";


   my $month_num_06 = set_month_to_month_number($month_input_04);

   # Months with 30 days ( April June September November )
   if ( ( $month_num_06 == 4 )  ||  ( $month_num_06 == 6 )  ||  ( $month_num_06 == 9 )  ||  ( $month_num_06 == 11 ) )
      {
      return ( 30 );
      }
   # February (NON leap year)
   elsif ( ( $month_num_06 == 2 )  &&  (!( is_leap_year($year_input_02) ) )   )
      {
      return ( 28 );
      }
   # February (leap year)
#   elsif ( ( $month_num_06 == 2 )  &&    ( is_leap_year($year_input_02) ) )
   elsif ( $month_num_06 == 2 )
      {
      return ( 29 );
      }
   # Months with 31 days
   else
      {
      return ( 31 );
      }

   }




###############################################################################
# Usage      : get_days_remaining_in_month( SCALAR, SCALAR, SCALAR )
# Purpose    : find out how many days are remaining in the month from the given date
# Returns    : number of days left if successful
# Parameters : (
#            :  alpha or month integer<1-12>,
#            :  day of month integer<1-N>,
#            :  year integer,
#            : )
# Throws     : Throws exception for any invalid input
# Comments   : - Handles all years, even negative years (aka BC)
#            : - if the last day of the month is given, 0 is returned
# See Also   : N/A
###############################################################################
sub get_days_remaining_in_month
   {
   my (
       $month_input_05,
       $day_of_month_input_01,
       $year_input_03,
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_22 = 3;
   ( @_ ==  $num_input_params_22) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly $num_input_params_22 parameter(s), (month, day_of_month, year).   '@_'.\n\n\n";


   ( ref(\$month_input_05) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the month    '$month_input_05'.\n\n\n";
   ( $month_input_05  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty value for the month    '$month_input_05'.\n\n\n";
   ( is_valid_month($month_input_05) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a valid month    '$month_input_05'.\n\n\n";

   ( ref(\$year_input_03) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the year number    '$year_input_03'.\n\n\n";
   ( $year_input_03  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty value for the year number    '$year_input_03'.\n\n\n";
   ( is_valid_year($year_input_03) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects an integer value, positive, negative or zero, for the year number    '$year_input_03'.\n\n\n";

   ( ref(\$day_of_month_input_01) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the day of month    '$day_of_month_input_01'.\n\n\n";
   ( $day_of_month_input_01  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty value for the day of month    '$day_of_month_input_01'.\n\n\n";
   ( is_valid_day_of_month($month_input_05, $day_of_month_input_01, $year_input_03) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects an integer value for the day of month (1-31)    '$day_of_month_input_01'.\n\n\n";


   my $month_num_07 = set_month_to_month_number($month_input_05);

   # Months with 30 days ( April June September November )
   if ( ( $month_num_07 == 4 )  ||  ( $month_num_07 == 6 )  ||  ( $month_num_07 == 9 )  ||  ( $month_num_07 == 11 ) )
      {
      return ( 30 - $day_of_month_input_01 );
      }
   # February (NON leap year)
   elsif ( ( $month_num_07 == 2 )  &&  (!( is_leap_year($year_input_03) ) )   )
      {
      return ( 28 - $day_of_month_input_01 );
      }
   # February (leap year)
#   elsif ( ( $month_num_07 == 2 )  &&    ( is_leap_year($year_input_03) ) )
   elsif ( $month_num_07 == 2 )
      {
      return ( 29 - $day_of_month_input_01 );
      }
   # Months with 31 days
   else
      {
      return ( 31 - $day_of_month_input_01 );
      }

   }




###############################################################################
# Usage      : get_days_remaining_in_year( SCALAR, SCALAR, SCALAR )
# Purpose    : find out how many days are remaining in the year from the given date
# Returns    : number of days left if successful
# Parameters : (
#            :  alpha or month integer<1-12>,
#            :  day of month integer<1-N>,
#            :  year integer,
#            : )
# Throws     : Throws exception for any invalid input
# Comments   : - Handles all years, even negative years (aka BC)
#            : - if the last day of the year is given, 0 is returned
# See Also   : N/A
###############################################################################
sub get_days_remaining_in_year
   {
   my (
       $month_input_06,
       $day_of_month_input_02,
       $year_input_04,
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_23 = 3;
   ( @_ ==  $num_input_params_23) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly $num_input_params_23 parameter(s), (month, day_of_month, year).   '@_'.\n\n\n";


   ( ref(\$month_input_06) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the month    '$month_input_06'.\n\n\n";
   ( $month_input_06  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty value for the month    '$month_input_06'.\n\n\n";
   ( is_valid_month($month_input_06) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a valid month    '$month_input_06'.\n\n\n";

   ( ref(\$year_input_04) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the year number    '$year_input_04'.\n\n\n";
   ( $year_input_04  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty value for the year number    '$year_input_04'.\n\n\n";
   ( is_valid_year($year_input_04) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects an integer value, positive, negative or zero, for the year number    '$year_input_04'.\n\n\n";

   ( ref(\$day_of_month_input_02) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the day of month    '$day_of_month_input_02'.\n\n\n";
   ( $day_of_month_input_02  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty value for the day of month    '$day_of_month_input_02'.\n\n\n";
   ( is_valid_day_of_month($month_input_06, $day_of_month_input_02, $year_input_04) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects an integer value for the day of month (1-31)    '$day_of_month_input_02'.\n\n\n";


   my $month_num_08 = set_month_to_month_number($month_input_06);

   return ( get_num_days_in_year( $year_input_04 ) - number_of_day_within_year( "${month_num_08}/${day_of_month_input_02}/${year_input_04}" ) );
   }




###############################################################################
# Usage      : get_number_of_day_within_400yr_cycle( SCALAR, SCALAR, SCALAR )
# Purpose    : find the number of the day within the standard 400 year cycle
# Returns    : day number if successful
# Parameters : (
#            :  alpha or month integer<1-12>,
#            :  day of month integer<1-N>,
#            :  year integer,
#            : )
# Throws     : Throws exception for any invalid input
# Comments   : - Handles all years, even negative years (aka BC)
#            : - years repeat in a standard 400 year cycle where year 2000 is defined by this program to be phase '0' and year 2399 is then phase '399'
#            : - this would be a very LARGE integer for the 1990's
#            : - Jan 1, 2000 would return '1'
# See Also   : N/A
###############################################################################
sub get_number_of_day_within_400yr_cycle
   {
   my (
       $month_input_07,
       $day_of_month_input_03,
       $year_input_05,
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_24 = 3;
   ( @_ ==  $num_input_params_24) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly $num_input_params_24 parameter(s), (month, day_of_month, year).   '@_'.\n\n\n";


   ( ref(\$month_input_07) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the month    '$month_input_07'.\n\n\n";
   ( $month_input_07  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty value for the month    '$month_input_07'.\n\n\n";
   ( is_valid_month($month_input_07) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a valid month    '$month_input_07'.\n\n\n";

   ( ref(\$year_input_05) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the year number    '$year_input_05'.\n\n\n";
   ( $year_input_05  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty value for the year number    '$year_input_05'.\n\n\n";
   ( is_valid_year($year_input_05) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects an integer value, positive, negative or zero, for the year number    '$year_input_05'.\n\n\n";

   ( ref(\$day_of_month_input_03) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the day of month    '$day_of_month_input_03'.\n\n\n";
   ( $day_of_month_input_03  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty value for the day of month    '$day_of_month_input_03'.\n\n\n";
   ( is_valid_day_of_month($month_input_07, $day_of_month_input_03, $year_input_05) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects an integer value for the day of month (1-31)    '$day_of_month_input_03'.\n\n\n";


   my $month_num_09 = set_month_to_month_number($month_input_07);

   my $year_phase_01 = get_year_phase($year_input_05);
   my $day_num_in_400_year_cycle_00 = 0;
   my $iii_000 = 0;
   for ( $iii_000=0; $iii_000<$year_phase_01; $iii_000++ )
      {
      $day_num_in_400_year_cycle_00 += get_num_days_in_year($iii_000);
      }
   $day_num_in_400_year_cycle_00 += number_of_day_within_year( "${month_num_09}/${day_of_month_input_03}/${iii_000}" );

   return ( $day_num_in_400_year_cycle_00 );

   }




###############################################################################
# Usage      : get_days_remaining_in_400yr_cycle( SCALAR, SCALAR, SCALAR )
# Purpose    : find the number of days remaining from the given date to the end of the current standard 400 year cycle
# Returns    : number of days left if successful
# Parameters : (
#            :  alpha or month integer<1-12>,
#            :  day of month integer<1-N>,
#            :  year integer,
#            : )
# Throws     : Throws exception for any invalid input
# Comments   : - Handles all years, even negative years (aka BC)
#            : - years repeat in a standard 400 year cycle where year 2000 is defined by this program to be phase '0' and year 2399 is then phase '399'
#            : - this would be a very SMALL integer for the 1990's
#            : - Jan 1, 2000 would return '146096'.  There are a total of 146,097 days in the standard 400 year cycle.
# See Also   : N/A
###############################################################################
sub get_days_remaining_in_400yr_cycle
   {
   my (
       $month_input_08,
       $day_of_month_input_04,
       $year_input_06,
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_25 = 3;
   ( @_ ==  $num_input_params_25) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly $num_input_params_25 parameter(s), (month, day_of_month, year).   '@_'.\n\n\n";


   ( ref(\$month_input_08) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the month    '$month_input_08'.\n\n\n";
   ( $month_input_08  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty value for the month    '$month_input_08'.\n\n\n";
   ( is_valid_month($month_input_08) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a valid month    '$month_input_08'.\n\n\n";

   ( ref(\$year_input_06) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the year number    '$year_input_06'.\n\n\n";
   ( $year_input_06  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty value for the year number    '$year_input_06'.\n\n\n";
   ( is_valid_year($year_input_06) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects an integer value, positive, negative or zero, for the year number    '$year_input_06'.\n\n\n";

   ( ref(\$day_of_month_input_04) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the day of month    '$day_of_month_input_04'.\n\n\n";
   ( $day_of_month_input_04  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty value for the day of month    '$day_of_month_input_04'.\n\n\n";
   ( is_valid_day_of_month($month_input_08, $day_of_month_input_04, $year_input_06) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects an integer value for the day of month (1-31)    '$day_of_month_input_04'.\n\n\n";


   my $month_num_10 = set_month_to_month_number($month_input_08);

   return ( $NUMBER_OF_DAYS_IN_400_YEAR_CYCLE - get_number_of_day_within_400yr_cycle( $month_num_10, $day_of_month_input_04, $year_input_06 ) );
   }




###############################################################################
# Usage      : day_number_within_year_to_date( SCALAR, SCALAR )
# Purpose    : converts the number of the day within the year to a date
# Returns    : date if successful
# Parameters : (
#            :  year integer,
#            :  number of day in year <1-365/6>,
#            : )
# Throws     : Throws exception for any invalid input
# Comments   : Handles all years, even negative years (aka BC)
# See Also   : N/A
###############################################################################
sub day_number_within_year_to_date
   {
   my (
       $year_input_07,
       $day_number_in_year_00,
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_26 = 2;
   ( @_ ==  $num_input_params_26) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly $num_input_params_26 parameter(s), (month, day_of_month, year).   '@_'.\n\n\n";

   ( ref(\$year_input_07) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the year number    '$year_input_07'.\n\n\n";
   ( $year_input_07  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty value for the year number    '$year_input_07'.\n\n\n";
   ( is_valid_year($year_input_07) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects an integer value, positive, negative or zero, for the year number    '$year_input_07'.\n\n\n";

   ( ref(\$day_number_in_year_00) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the day number within the year    '$day_number_in_year_00'.\n\n\n";
   ( $day_number_in_year_00  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty value for the day number within the year    '$day_number_in_year_00'.\n\n\n";


   if ( !(is_leap_year($year_input_07)) )
      {
      ( ( $day_number_in_year_00 =~ m/^(\d{1,3})$/ )  &&  ( $1 > 0 )  &&  ( $1 < 366 ) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' The number of the day within a NON leap must be in the range of 1-365    '$day_number_in_year_00'.\n\n\n";
      }
   else
      {
      ( ( $day_number_in_year_00 =~ m/^(\d{1,3})$/ )  &&  ( $1 > 0 )  &&  ( $1 < 367 ) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' The number of the day within a LEAP must be in the range of 1-366    '$day_number_in_year_00'.\n\n\n";
      }


   my $date_from_num_00;

   if ( $day_number_in_year_00 < 32 )
      {
      $date_from_num_00 = "1/" . $day_number_in_year_00 . "/$year_input_07";
      }
   elsif ( !( is_leap_year($year_input_07) ) )
      {
      foreach ($day_number_in_year_00)
         {
         SWITCH:
            {
            if ( $_ <  60 )    { $date_from_num_00 =  "2/" . ($_ -  31) . "/$year_input_07"; last SWITCH; } #      if    ( $_ < (31 + 29) )
            if ( $_ <  91 )    { $date_from_num_00 =  "3/" . ($_ -  59) . "/$year_input_07"; last SWITCH; } #      elsif ( $_ < (31 + 28 + 32) )                                                      $date_from_num_00 = "3/" . ($_ - (31 + 28)) . "/$year_input_07";
            if ( $_ < 121 )    { $date_from_num_00 =  "4/" . ($_ -  90) . "/$year_input_07"; last SWITCH; } #      elsif ( $_ < (31 + 28 + 31 + 31) )                                                 $date_from_num_00 = "4/" . ($_ - (31 + 28 + 31)) . "/$year_input_07";
            if ( $_ < 152 )    { $date_from_num_00 =  "5/" . ($_ - 120) . "/$year_input_07"; last SWITCH; } #      elsif ( $_ < (31 + 28 + 31 + 30 + 32) )                                            $date_from_num_00 = "5/" . ($_ - (31 + 28 + 31 + 30)) . "/$year_input_07";
            if ( $_ < 182 )    { $date_from_num_00 =  "6/" . ($_ - 151) . "/$year_input_07"; last SWITCH; } #      elsif ( $_ < (31 + 28 + 31 + 30 + 31 + 31) )                                       $date_from_num_00 = "6/" . ($_ - (31 + 28 + 31 + 30 + 31)) . "/$year_input_07";
            if ( $_ < 213 )    { $date_from_num_00 =  "7/" . ($_ - 181) . "/$year_input_07"; last SWITCH; } #      elsif ( $_ < (31 + 28 + 31 + 30 + 31 + 30 + 32) )                                  $date_from_num_00 = "7/" . ($_ - (31 + 28 + 31 + 30 + 31 + 30)) . "/$year_input_07";
            if ( $_ < 244 )    { $date_from_num_00 =  "8/" . ($_ - 212) . "/$year_input_07"; last SWITCH; } #      elsif ( $_ < (31 + 28 + 31 + 30 + 31 + 30 + 31 + 32) )                             $date_from_num_00 = "8/" . ($_ - (31 + 28 + 31 + 30 + 31 + 30 + 31)) . "/$year_input_07";
            if ( $_ < 274 )    { $date_from_num_00 =  "9/" . ($_ - 243) . "/$year_input_07"; last SWITCH; } #      elsif ( $_ < (31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 31) )                        $date_from_num_00 = "9/" . ($_ - (31 + 28 + 31 + 30 + 31 + 30 + 31 + 31)) . "/$year_input_07";
            if ( $_ < 305 )    { $date_from_num_00 = "10/" . ($_ - 273) . "/$year_input_07"; last SWITCH; } #      elsif ( $_ < (31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 32) )                   $date_from_num_00 = "10/" . ($_ - (31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30)) . "/$year_input_07";
            if ( $_ < 335 )    { $date_from_num_00 = "11/" . ($_ - 304) . "/$year_input_07"; last SWITCH; } #      elsif ( $_ < (31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 31) )              $date_from_num_00 = "11/" . ($_ - (31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31)) . "/$year_input_07";
                                 $date_from_num_00 = "12/" . ($_ - 334) . "/$year_input_07";                #                                                                                         $date_from_num_00 = "12/" . ($_ - (31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30)) . "/$year_input_07";
            }
         }
      }
   else
      {
      foreach ($day_number_in_year_00)
         {
         SWITCH:
            {
            if ( $_ <  61 )    { $date_from_num_00 =  "2/" . ($_ -  31) . "/$year_input_07"; last SWITCH; } #   if    ( $_ < (31 + 30) )
            if ( $_ <  92 )    { $date_from_num_00 =  "3/" . ($_ -  60) . "/$year_input_07"; last SWITCH; } #   elsif ( $_ < (31 + 29 + 32) )                                              $date_from_num_00 = "3/" . ($_ - (31 + 29)) . "/$year_input_07";
            if ( $_ < 122 )    { $date_from_num_00 =  "4/" . ($_ -  91) . "/$year_input_07"; last SWITCH; } #   elsif ( $_ < (31 + 29 + 31 + 31) )                                         $date_from_num_00 = "4/" . ($_ - (31 + 29 + 31)) . "/$year_input_07";
            if ( $_ < 153 )    { $date_from_num_00 =  "5/" . ($_ - 121) . "/$year_input_07"; last SWITCH; } #   elsif ( $_ < (31 + 29 + 31 + 30 + 32) )                                    $date_from_num_00 = "5/" . ($_ - (31 + 29 + 31 + 30)) . "/$year_input_07";
            if ( $_ < 183 )    { $date_from_num_00 =  "6/" . ($_ - 152) . "/$year_input_07"; last SWITCH; } #   elsif ( $_ < (31 + 29 + 31 + 30 + 31 + 31) )                               $date_from_num_00 = "6/" . ($_ - (31 + 29 + 31 + 30 + 31)) . "/$year_input_07";
            if ( $_ < 214 )    { $date_from_num_00 =  "7/" . ($_ - 182) . "/$year_input_07"; last SWITCH; } #   elsif ( $_ < (31 + 29 + 31 + 30 + 31 + 30 + 32) )                          $date_from_num_00 = "7/" . ($_ - (31 + 29 + 31 + 30 + 31 + 30)) . "/$year_input_07";
            if ( $_ < 245 )    { $date_from_num_00 =  "8/" . ($_ - 213) . "/$year_input_07"; last SWITCH; } #   elsif ( $_ < (31 + 29 + 31 + 30 + 31 + 30 + 31 + 32) )                     $date_from_num_00 = "8/" . ($_ - (31 + 29 + 31 + 30 + 31 + 30 + 31)) . "/$year_input_07";
            if ( $_ < 275 )    { $date_from_num_00 =  "9/" . ($_ - 244) . "/$year_input_07"; last SWITCH; } #   elsif ( $_ < (31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 31) )                $date_from_num_00 = "9/" . ($_ - (31 + 29 + 31 + 30 + 31 + 30 + 31 + 31)) . "/$year_input_07";
            if ( $_ < 306 )    { $date_from_num_00 = "10/" . ($_ - 274) . "/$year_input_07"; last SWITCH; } #   elsif ( $_ < (31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 32) )           $date_from_num_00 = "10/" . ($_ - (31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30)) . "/$year_input_07";
            if ( $_ < 336 )    { $date_from_num_00 = "11/" . ($_ - 305) . "/$year_input_07"; last SWITCH; } #   elsif ( $_ < (31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 31) )      $date_from_num_00 = "11/" . ($_ - (31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31)) . "/$year_input_07";
                                 $date_from_num_00 = "12/" . ($_ - 335) . "/$year_input_07";                #                                                                              $date_from_num_00 = "12/" . ($_ - (31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30)) . "/$year_input_07";
            }
         }
      }

   return ( format_date( $date_from_num_00 ) );
   }




###############################################################################
# Usage      : day_number_within_400_year_cycle_to_date( SCALAR, SCALAR )
# Purpose    : converts the number of the day within the standard 400 year cycle to a date
# Returns    : date if successful
# Parameters : (
#            :  400 year cycle, (i.e.  ... -400, 0, 400, ... 1600, 2000, 2400, ...)
#            :  number of day in the standard 400 year cycle <1-146097>,
#            : )
# Throws     : Throws exception for any invalid input
# Comments   : - Handles all years, even negative years (aka BC)
#            : - years repeat in a standard 400 year cycle where year 2000 is defined by this program to be phase '0' and year 2399 is then phase '399'
# See Also   : N/A
###############################################################################
sub day_number_within_400_year_cycle_to_date
   {
   my (
       $four_hundred_year_cycle_00,
       $day_number_in_400_year_cycle_00,
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_27 = 2;
   ( @_ ==  $num_input_params_27) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly $num_input_params_27 parameter(s), (400 year cycle<-400,0,400,...,2000>, day number within 400 year cycle<1 - 146097> ).   '@_'.\n\n\n";

   ( ref(\$four_hundred_year_cycle_00) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the 400 year cycle<-400,0,400,...,2000>, day number within 400 year cycle<1 - 146097>    '$four_hundred_year_cycle_00'.\n\n\n";
   ( $four_hundred_year_cycle_00  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty value for the 400 year cycle<-400,0,400,...,2000>, day number within 400 year cycle<1 - 146097>    '$four_hundred_year_cycle_00'.\n\n\n";
   ( is_valid_400_year_cycle($four_hundred_year_cycle_00) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects an integer value, positive, negative or zero, for the 400 year cycle<-400,0,400,...,2000>, day number within 400 year cycle<1 - 146097>    '$four_hundred_year_cycle_00'.\n\n\n";

   ( ref(\$day_number_in_400_year_cycle_00) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the day number within the 400 year cycle    '$day_number_in_400_year_cycle_00'.\n\n\n";
   ( $day_number_in_400_year_cycle_00  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty value for the day number within the 400 year cycle    '$day_number_in_400_year_cycle_00'.\n\n\n";
   ( ( $day_number_in_400_year_cycle_00 =~ m/^(\d{1,6})$/ )  &&  ( $1 > 0 )  &&  ( $1 <= $NUMBER_OF_DAYS_IN_400_YEAR_CYCLE ) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects an integer (1 - 146097) for the day number within the 400 year cycle    '$day_number_in_400_year_cycle_00'.\n\n\n";


   my $current_day_count_00 = $day_number_in_400_year_cycle_00;
   my $iii_002;
   for ( $iii_002=0; $iii_002<$NUMBER_OF_YEAR_PHASES; $iii_002++ )
      {
      my $days_in_this_year_00 = get_num_days_in_year($iii_002);
      if ( $current_day_count_00  >  $days_in_this_year_00 )
         {
         $current_day_count_00 -= $days_in_this_year_00;
         }
      else
         {
         last;
         }
      }

   my ( $month_num_11, $day_of_month_11, $year_num_11, $day_of_week_11 ) = date_only_parse(day_number_within_year_to_date($iii_002, $current_day_count_00));
   $year_num_11 += $four_hundred_year_cycle_00;

   my $date_from_num_01 = "${month_num_11}/${day_of_month_11}/${year_num_11}";

   return ( format_date( $date_from_num_01 ) );
   }




###############################################################################
# Usage      : Function is overloaded to accept EITHER a date string OR a date
#            : component.
#            :    1) Date string, <OPTIONAL date format>
#            :       format_date( SCALAR, <SCALAR> )
#            :    2) Month, dayofmonth, year, <OPTIONAL date format>
#            :       format_date( SCALAR, SCALAR, SCALAR, <SCALAR> )
# Purpose    : Formats dates
# Returns    : date string if successful
# Parameters : 1) ( date string in any format, <optional date format> )
#            :           OR
#            : 2) ( month, day of month, year, <optional date format> )
# Throws     : Throws exception for any invalid input
# Comments   : - Handles all years, even negative years (aka BC)
#            : - It does NOT output time, time zone or any other time parameter
#            :   other than a CONSTANT 12noon time when a time component is
#            :   included in the format.
#            : - Format options
#            :    <Default> ->  'mm/dd/yyyy'
#            :    'A'       ->  'Mon Sep 17 12:00:00 2007' (time component is ALWAYS 12 noon)
#            :    'B'       ->  'September 17, 2007'
#            :    'C'       ->  '17 September, 2007'
#            :    'D'       ->  'YYYY-MM-DD'
# See Also   : N/A
###############################################################################
sub format_date
   {


   # Incoming Inspection
   ( ( @_ >  0 )  &&  ( @_ <  5 ) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}'  Should have a date string and an optional format field, or a list of month,dayofmonth,year and an optional format field.   '@_'.\n\n\n";


   my $format_selection_00 = '';
   my ($mmonth_00, $dday_00, $yyear_00, $day_of_week_04);
   # Parsing date string with optional format selection
   if (( @_ ==  1 )  ||  ( @_ ==  2 ) )
      {
      ( ref(\$_[0]) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the date string.    '$_[0]'.\n\n\n";
      ( $_[0]  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the date string    '$_[0]'.\n\n\n";
      ( date_only_parse($_[0]) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' date string, '$_[0]', cannot be parsed.\n\n\n";
      my $date_in_02;
      if ( @_ ==  1 )
         {
         $date_in_02 = $_[0];
         }
      else
         {
         ( ref(\$_[1]) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the desired date format.    '$_[1]'.\n\n\n";
         ( $_[1]  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the desired date format    '$_[1]'.\n\n\n";
         ( $date_in_02, $format_selection_00 ) = @_;
         }
      ($mmonth_00, $dday_00, $yyear_00, $day_of_week_04) = date_only_parse($date_in_02);
      }
   # Individual date components with optional format selection
   else
      {
      ( ref(\$_[0]) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the month    '$_[0]'.\n\n\n";
      ( $_[0]  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty value for the month    '$_[0]'.\n\n\n";
      ( is_valid_month($_[0]) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a valid month    '$_[0]'.\n\n\n";

      ( ref(\$_[2]) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the year number    '$_[2]'.\n\n\n";
      ( $_[2]  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty value for the year number    '$_[2]'.\n\n\n";
      ( is_valid_year($_[2]) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects an integer value, positive, negative or zero, for the year number    '$_[2]'.\n\n\n";

      ( ref(\$_[1]) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the day of month    '$_[1]'.\n\n\n";
      ( $_[1]  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty value for the day of month    '$_[1]'.\n\n\n";
      ( is_valid_day_of_month($_[0], $_[1], $_[2]) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects an integer value for the day of month (1-31)    '$_[1]'.\n\n\n";

      ($mmonth_00, $dday_00, $yyear_00 ) = ( $_[0], $_[1], $_[2] );
      $day_of_week_04 = get_numeric_day_of_week( $mmonth_00, $dday_00, $yyear_00 );
      if ( @_ ==  4 )
         {
         ( ref(\$_[3]) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the desired date format.    '$_[3]'.\n\n\n";
         ( $_[3]  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the desired date format    '$_[3]'.\n\n\n";
         $format_selection_00 = $_[3];
         }
      }

   $mmonth_00 = set_month_to_month_number($mmonth_00);

   my $formatted_date_00;
# '12/30/1999'
   if ( uc($format_selection_00) eq '' ) # default format
      {
      $formatted_date_00 = sprintf "%02d/%02d/%d",  $mmonth_00, $dday_00, $yyear_00;
      }
# 'Sun Feb 29 12:00:00 1604'
   elsif ( uc($format_selection_00) eq 'A' )
      {
      my $day_of_week_abbreviated_00 = set_day_to_day_name_abbrev( $day_of_week_04 );
      my $month_abbreviated_00 = set_month_to_month_name_abbrev( $mmonth_00 );
      $formatted_date_00 = sprintf "%3s %3s %2d 12:00:00 %d", $day_of_week_abbreviated_00, $month_abbreviated_00, $dday_00, $yyear_00;
      }
# 'September 17, 2007'
   elsif ( uc($format_selection_00) eq 'B' )
      {
      my $month_12       = set_month_to_month_name_full( $mmonth_00 );
      $formatted_date_00 = sprintf "%3s %01d, %d", $month_12, $dday_00, $yyear_00;
      }
# '17 September, 2007'
   elsif ( uc($format_selection_00) eq 'C' )
      {
      my $month_14       = set_month_to_month_name_full( $mmonth_00 );
      $formatted_date_00 = sprintf "%01d %3s, %d", $dday_00, $month_14, $yyear_00;
      }
# 'YYYY-MM-DD' (ex: 2007-09-01 <Sep 1, 2007>)
   elsif ( uc($format_selection_00) eq 'D' )
      {
      my $month_15       = set_month_to_month_number( $mmonth_00 );
      $formatted_date_00 = sprintf "%d-%02d-%02d", $yyear_00, $month_15, $dday_00;
      }
   else
      {
      croak "\n\n   ($0)   '${\(caller(0))[3]}' This date format selection, '$format_selection_00', is not recognized.  Refer to documentation for allowable options.\n\n\n";
      }

   return ($formatted_date_00);
   }




###############################################################################
# Usage      : get_first_of_month_day_of_week( SCALAR, SCALAR )
# Purpose    : get the day of the week for the first of the month for a specified month/year combination
# Returns    : - day of the week (1-7) if successful
# Parameters : (
#            :  alpha or month integer<1-12>,
#            :  year integer,
#            : )
# Throws     : Throws exception for any invalid input
# Comments   : - Handles all years, even negative years (aka BC)
#            : - <1 for Mon ... 7 for Sun>
# See Also   : N/A
###############################################################################
sub get_first_of_month_day_of_week
   {
   my (
       $month_input_09,
       $year_in_05,
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_28 = 2;
   ( @_ ==  $num_input_params_28) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly $num_input_params_28 parameter(s), (month, year).   '@_'.\n\n\n";

   ( ref(\$month_input_09) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the month    '$month_input_09'.\n\n\n";
   ( $month_input_09  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty value for the month    '$month_input_09'.\n\n\n";
   ( is_valid_month($month_input_09) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a valid month    '$month_input_09'.\n\n\n";

   ( ref(\$year_in_05) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the year number    '$year_in_05'.\n\n\n";
   ( $year_in_05  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty value for the year number    '$year_in_05'.\n\n\n";
   ( is_valid_year($year_in_05) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects an integer value, positive, negative or zero, for the year number    '$year_in_05'.\n\n\n";


   my $month_num_12 = set_month_to_month_number($month_input_09);
   my $year_phase_02 = get_year_phase( $year_in_05 );
   my $first_of_month_day_of_week_00 = set_day_to_day_number($DAY_OF_WEEK_ON_FIRST_OF_YEAR{$year_phase_02});
   if ( !(is_leap_year($year_in_05) ) )
      {
      foreach ($month_num_12)
         {
         SWITCH:
            {
            if ( $_ ==  2 )    { $first_of_month_day_of_week_00 +=  31; last SWITCH; }
            if ( $_ ==  3 )    { $first_of_month_day_of_week_00 +=  59; last SWITCH; } #   $first_of_month_day_of_week_00 += 31 + 28;
            if ( $_ ==  4 )    { $first_of_month_day_of_week_00 +=  90; last SWITCH; } #   $first_of_month_day_of_week_00 += 31 + 28 + 31;
            if ( $_ ==  5 )    { $first_of_month_day_of_week_00 += 120; last SWITCH; } #   $first_of_month_day_of_week_00 += 31 + 28 + 31 + 30;
            if ( $_ ==  6 )    { $first_of_month_day_of_week_00 += 151; last SWITCH; } #   $first_of_month_day_of_week_00 += 31 + 28 + 31 + 30 + 31;
            if ( $_ ==  7 )    { $first_of_month_day_of_week_00 += 181; last SWITCH; } #   $first_of_month_day_of_week_00 += 31 + 28 + 31 + 30 + 31 + 30;
            if ( $_ ==  8 )    { $first_of_month_day_of_week_00 += 212; last SWITCH; } #   $first_of_month_day_of_week_00 += 31 + 28 + 31 + 30 + 31 + 30 + 31;
            if ( $_ ==  9 )    { $first_of_month_day_of_week_00 += 243; last SWITCH; } #   $first_of_month_day_of_week_00 += 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31;
            if ( $_ == 10 )    { $first_of_month_day_of_week_00 += 273; last SWITCH; } #   $first_of_month_day_of_week_00 += 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30;
            if ( $_ == 11 )    { $first_of_month_day_of_week_00 += 304; last SWITCH; } #   $first_of_month_day_of_week_00 += 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31;
            if ( $_ == 12 )    { $first_of_month_day_of_week_00 += 334; last SWITCH; } #   $first_of_month_day_of_week_00 += 31 + 28 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30;
            }
         }
      }
   else
      {
      foreach ($month_num_12)
         {
         SWITCH:
            {
            if ( $_ ==  2 )    { $first_of_month_day_of_week_00 +=  31; last SWITCH; }
            if ( $_ ==  3 )    { $first_of_month_day_of_week_00 +=  60; last SWITCH; } #  $first_of_month_day_of_week_00 += 31 + 29;
            if ( $_ ==  4 )    { $first_of_month_day_of_week_00 +=  91; last SWITCH; } #  $first_of_month_day_of_week_00 += 31 + 29 + 31;
            if ( $_ ==  5 )    { $first_of_month_day_of_week_00 += 121; last SWITCH; } #  $first_of_month_day_of_week_00 += 31 + 29 + 31 + 30;
            if ( $_ ==  6 )    { $first_of_month_day_of_week_00 += 152; last SWITCH; } #  $first_of_month_day_of_week_00 += 31 + 29 + 31 + 30 + 31;
            if ( $_ ==  7 )    { $first_of_month_day_of_week_00 += 182; last SWITCH; } #  $first_of_month_day_of_week_00 += 31 + 29 + 31 + 30 + 31 + 30;
            if ( $_ ==  8 )    { $first_of_month_day_of_week_00 += 213; last SWITCH; } #  $first_of_month_day_of_week_00 += 31 + 29 + 31 + 30 + 31 + 30 + 31;
            if ( $_ ==  9 )    { $first_of_month_day_of_week_00 += 244; last SWITCH; } #  $first_of_month_day_of_week_00 += 31 + 29 + 31 + 30 + 31 + 30 + 31 + 31;
            if ( $_ == 10 )    { $first_of_month_day_of_week_00 += 274; last SWITCH; } #  $first_of_month_day_of_week_00 += 31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30;
            if ( $_ == 11 )    { $first_of_month_day_of_week_00 += 305; last SWITCH; } #  $first_of_month_day_of_week_00 += 31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31;
            if ( $_ == 12 )    { $first_of_month_day_of_week_00 += 335; last SWITCH; } #  $first_of_month_day_of_week_00 += 31 + 29 + 31 + 30 + 31 + 30 + 31 + 31 + 30 + 31 + 30;
            }
         }
      }


   # Map day of week to 0-6
   $first_of_month_day_of_week_00 %= 7;

   # Map day of week '0' to '7'
   if ( $first_of_month_day_of_week_00 == 0 )
      {
      $first_of_month_day_of_week_00 = 7;
      }

   return ( $first_of_month_day_of_week_00 );
   }




###############################################################################
# Usage      : Function is overloaded to accept one of two date input types
#            :    1) Date string
#            :       get_numeric_day_of_week( SCALAR )
#            :    2) Month, dayofmonth, year
#            :       get_numeric_day_of_week( SCALAR, SCALAR, SCALAR )
# Purpose    : get numeric day of week (1-7) for given date
# Returns    : - day of week number if successful
# Parameters : 1) ( date string in any format )
#            :           OR
#            : 2) ( month, day of month, year )
# Throws     : Throws exception for any invalid input
# Comments   : - Handles all years, even negative years (aka BC)
#            : - <1 for Mon ... 7 for Sun>
# See Also   : N/A
###############################################################################
sub get_numeric_day_of_week
   {


   # Incoming Inspection
   ( ( @_ ==  1 )  ||  ( @_ ==  3 ) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}'  Should have either a date string, or a list of month,dayofmonth,year.   '@_'.\n\n\n";


   my ( $month_input_10, $day_of_month_in_02, $year_in_06, $day_of_week_12 );
   # Parsing date string and is recursive one time into this function
   if ( @_ ==  1 )
      {
      ( ref(\$_[0]) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the date string.    '$_[0]'.\n\n\n";
      ( $_[0]  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the date string    '$_[0]'.\n\n\n";

      ($month_input_10, $day_of_month_in_02, $year_in_06, $day_of_week_12 ) = date_only_parse($_[0]);
      if ( $day_of_week_12 )
         {
         return ( $day_of_week_12 );
         }
      else
         {
         croak "\n\n   ($0)   '${\(caller(0))[3]}' date string, '$_[0]', cannot be parsed.\n\n\n";
         }
      }
   # Individual date components
   else
      {
      ( ref(\$_[0]) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the month    '$_[0]'.\n\n\n";
      ( $_[0]  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty value for the month    '$_[0]'.\n\n\n";
      ( is_valid_month($_[0]) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a valid month    '$_[0]'.\n\n\n";

      ( ref(\$_[2]) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the year number    '$_[2]'.\n\n\n";
      ( $_[2]  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty value for the year number    '$_[2]'.\n\n\n";
      ( is_valid_year($_[2]) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects an integer value, positive, negative or zero, for the year number    '$_[2]'.\n\n\n";

      ( ref(\$_[1]) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the day of month    '$_[1]'.\n\n\n";
      ( $_[1]  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty value for the day of month    '$_[1]'.\n\n\n";
      ( is_valid_day_of_month($_[0], $_[1], $_[2]) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects an integer value for the day of month (1-31)    '$_[1]'.\n\n\n";

      ($month_input_10, $day_of_month_in_02, $year_in_06 ) = ( $_[0], $_[1], $_[2] );
      }


   my $month_num_14 = set_month_to_month_number($month_input_10);
   my $year_phase_03 = get_year_phase( $year_in_06 );

   my $first_of_month_day_of_week_02 = $NUMERIC_DAY_OF_WEEK_ON_FIRST_OF_MONTH{$year_phase_03}{$month_num_14} + $day_of_month_in_02 - 1;
   $first_of_month_day_of_week_02 %= 7;

   # Map day of week to 0-6
   $first_of_month_day_of_week_02 %= 7;

   # Map day of week '0' to '7'
   if ( $first_of_month_day_of_week_02 == 0 )
      {
      $first_of_month_day_of_week_02 = 7;
      }

   return ( $first_of_month_day_of_week_02 );
   }




###############################################################################
# Usage      : get_month_from_string( SCALAR )
# Purpose    : extract month from given date string
# Returns    : month number if successful
# Parameters : date string in any format
# Throws     : Throws exception for any invalid input
# Comments   : - Handles all years, even negative years (aka BC)
#            : - 1 for Jan ... 12 for Dec
# See Also   : N/A
###############################################################################
sub get_month_from_string
   {


   # Incoming Inspection
   ( @_ ==  1 ) or croak "\n\n   ($0)   '${\(caller(0))[3]}'  Should have a date string to be parsed.   '@_'.\n\n\n";

   ( ref(\$_[0]) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the date string.    '$_[0]'.\n\n\n";
   ( $_[0]  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the date string    '$_[0]'.\n\n\n";


   my  ($month_input_15, $day_of_month_15, $year_15, $day_of_week_15) = date_only_parse( $_[0] );
   if ( $month_input_15  eq  '' )
      {
      croak "\n\n   ($0)   '${\(caller(0))[3]}' Cannot extract the date from the input date string    '$_[0]'.\n\n\n";
      }
   else
      {
      return ( $month_input_15 );
      }

   }




###############################################################################
# Usage      : get_dayofmonth_from_string( SCALAR )
# Purpose    : extract day of month from given date string
# Returns    : day of month if successful
# Parameters : date string in any format
# Throws     : Throws exception for any invalid input
# Comments   : - Handles all years, even negative years (aka BC)
# See Also   : N/A
###############################################################################
sub get_dayofmonth_from_string
   {


   # Incoming Inspection
   ( @_ ==  1 ) or croak "\n\n   ($0)   '${\(caller(0))[3]}'  Should have a date string to be parsed.   '@_'.\n\n\n";

   ( ref(\$_[0]) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the date string.    '$_[0]'.\n\n\n";
   ( $_[0]  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the date string    '$_[0]'.\n\n\n";


   my  ($month_input_18, $day_of_month_18, $year_18, $day_of_week_18) = date_only_parse( $_[0] );
   if ( !(defined ($day_of_month_18) ) )
      {
      croak "\n\n   ($0)   '${\(caller(0))[3]}' Cannot extract the date from the input date string    '$_[0]'.\n\n\n";
      }
   else
      {
      return ( $day_of_month_18 );
      }

   }




###############################################################################
# Usage      : get_year_from_string( SCALAR )
# Purpose    : extract year from given date string
# Returns    : year if successful
# Parameters : date string in any format
# Throws     : Throws exception for any invalid input
# Comments   : - Handles all years, even negative years (aka BC)
# See Also   : N/A
###############################################################################
sub get_year_from_string
   {


   # Incoming Inspection
   ( @_ ==  1 ) or croak "\n\n   ($0)   '${\(caller(0))[3]}'  Should have a date string to be parsed.   '@_'.\n\n\n";

   ( ref(\$_[0]) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the date string.    '$_[0]'.\n\n\n";
   ( $_[0]  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the date string    '$_[0]'.\n\n\n";


   my  ($month_input_14, $day_of_month_14, $year_14, $day_of_week_14) = date_only_parse( $_[0] );
   if ( !(defined ($year_14) ) )
      {
      croak "\n\n   ($0)   '${\(caller(0))[3]}' Cannot extract the date from the input date string    '$_[0]'.\n\n\n";
      }
   else
      {
      return ( $year_14 );
      }

   }




###############################################################################
# Usage      : compare_year1_and_year2( SCALAR, SCALAR )
# Purpose    : compares two dates to find which one is the later year, months and days are ignored
# Returns    : -  '1' if the FIRST year is LATER   than the second
#            : - '-1' if the FIRST year is EARLIER than the second
#            : -  '0' if both years are the same
# Parameters : (
#            :   date ONE in any format,
#            :   date TWO in any format
#            : )
# Throws     : Throws exception for any invalid input
# Comments   : N/A
# See Also   : N/A
###############################################################################
sub compare_year1_and_year2
   {
   my (
       $date_one_03,
       $date_two_03
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_30 = 2;
   ( @_ ==  $num_input_params_30) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly $num_input_params_30 parameters ('date1' and date2).   '@_'.\n\n\n";

   ( ref(\$date_one_03) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR first parameter for the first date    '$date_one_03'.\n\n\n";
   ( ref(\$date_two_03) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR second parameter for the second date    '$date_two_03'.\n\n\n";

   ( $date_one_03  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the first date    '$date_one_03'.\n\n\n";
   ( $date_two_03  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the second date    '$date_two_03'.\n\n\n";

   ( date_only_parse($date_one_03) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Cannot extract the date from the input date1 string    '$date_one_03'.\n\n\n";
   ( date_only_parse($date_two_03) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Cannot extract the date from the input date2 string    '$date_two_03'.\n\n\n";


   my ( $date1_month_num_06, $date1_day_of_month_06, $date1_year_num_06, $date1_day_of_week_06 ) = date_only_parse($date_one_03);
   my ( $date2_month_num_06, $date2_day_of_month_06, $date2_year_num_06, $date2_day_of_week_06 ) = date_only_parse($date_two_03);

   if ( $date1_year_num_06  ==  $date2_year_num_06 )
      {
      return ( '0' );
      }
   elsif ( $date1_year_num_06  >  $date2_year_num_06 )
      {
      return ( '1' );
      }
   else
      {
      return ( '-1' );
      }

   }




###############################################################################
# Usage      : year1_to_year2_delta( SCALAR, SCALAR )
# Purpose    : calculates the difference in WHOLE years between two dates (basically it truncates the date difference to whole years)
# Returns    : integer year difference if successful
# Parameters : (
#            :   date ONE in any format,
#            :   date TWO in any format
#            : )
# Throws     : Throws exception for any invalid input
# Comments   : - Difference is positive if date1 > date2
#            : - Difference is negative if date1 < date2
#            : - Examples  Date1 = 4/5/1977 and Date2 = 11/16/1975 equals ONE complete year difference
# See Also   : N/A
###############################################################################
sub year1_to_year2_delta
   {
   my (
       $date_one_04,
       $date_two_04
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_31 = 2;
   ( @_ ==  $num_input_params_31) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly $num_input_params_31 parameters ('date1' and date2).   '@_'.\n\n\n";

   ( ref(\$date_one_04) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR first parameter for the first date    '$date_one_04'.\n\n\n";
   ( ref(\$date_two_04) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR second parameter for the second date    '$date_two_04'.\n\n\n";

   ( $date_one_04  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the first date    '$date_one_04'.\n\n\n";
   ( $date_two_04  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the second date    '$date_two_04'.\n\n\n";

   ( date_only_parse($date_one_04) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Cannot extract the date from the input date1 string    '$date_one_04'.\n\n\n";
   ( date_only_parse($date_two_04) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Cannot extract the date from the input date2 string    '$date_two_04'.\n\n\n";


   my ( $date1_month_num_07, $date1_day_of_month_07, $date1_year_num_07, $date1_day_of_week_07 ) = date_only_parse($date_one_04);
   my ( $date2_month_num_07, $date2_day_of_month_07, $date2_year_num_07, $date2_day_of_week_07 ) = date_only_parse($date_two_04);

   my $year_difference_00;
   if ( $date1_year_num_07  ==  $date2_year_num_07 )
      {
      $year_difference_00 = '0';
      }
   else
      {
      $year_difference_00 = $date1_year_num_07  -  $date2_year_num_07;
      }


   $date1_month_num_07 = set_month_to_month_number($date1_month_num_07);
   $date2_month_num_07 = set_month_to_month_number($date2_month_num_07);


   my $date1_is_leap_year = 'no';
   if ( is_leap_year($date1_year_num_07) )
      {
      $date1_is_leap_year = 'yes';
      }

   my $date2_is_leap_year = 'no';
   if ( is_leap_year($date2_year_num_07) )
      {
      $date2_is_leap_year = 'yes';
      }


   if ( $year_difference_00 > 0 )
      {
      if ( $date1_month_num_07  <  $date2_month_num_07 )
         {
         $year_difference_00--;
         }
      elsif ( ( $date1_month_num_07  ==  $date2_month_num_07 )  &&  ( $date1_day_of_month_07  <  $date2_day_of_month_07  ) )
         {
         $year_difference_00--;
         }

      # Leap Year Adjustments
      #                      whole year    whole year
      #  Date1     Date2     current       fix
      #  28        28        YES           YES
      #  28        28(9)     YES           YES
      #  28        29        no            YES (to be adjusted UP)
      #  28(9)     28        YES           no  (to be adjusted DOWN)
      #  28(9)     28(9)     YES           YES
      #  28(9)     29        no            no
      #  29        28        YES           YES
      #  29        28(9)     YES           YES
      #  29        29        YES           YES
      if ( ( $date1_is_leap_year eq 'no' ) &&  ( $date2_is_leap_year eq 'yes' ) )
         {
         if ( ( $date1_day_of_month_07  ==  28 )  &&  ( $date2_day_of_month_07  ==  29 ) )
            {
            $year_difference_00++;
            }
         }
      elsif ( ( $date1_is_leap_year eq 'yes' ) &&  ( $date2_is_leap_year eq 'no' ) )
         {
         if ( ( $date1_day_of_month_07  ==  28 )  &&  ( $date2_day_of_month_07  ==  28 ) )
            {
            $year_difference_00--;
            }
         }
      }
   elsif ( $year_difference_00 < 0 )
      {
      if ( $date1_month_num_07  >  $date2_month_num_07 )
         {
         $year_difference_00++;
         }
      elsif ( ( $date1_month_num_07  ==  $date2_month_num_07 )  &&  ( $date1_day_of_month_07  >  $date2_day_of_month_07  ) )
         {
         $year_difference_00++;
         }

      # Leap Year Adjustments
      #                      whole year    whole year
      #  Date1     Date2     current       fix
      #  28        28        YES           YES
      #  28        28(9)     YES           no    (to be adjusted UP)
      #  28        29        YES           YES
      #  28(9)     28        YES           YES
      #  28(9)     28(9)     YES           YES
      #  28(9)     29        YES           YES
      #  29        28        no            YES   (to be adjusted DOWN)
      #  29        28(9)     no            no
      #  29        29        YES           YES
      if ( ( $date1_is_leap_year eq 'no' ) &&  ( $date2_is_leap_year eq 'yes' ) )
         {
         if ( ( $date1_day_of_month_07  ==  28 )  &&  ( $date2_day_of_month_07  ==  28 ) )
            {
            $year_difference_00++;
            }
         }
      elsif ( ( $date1_is_leap_year eq 'yes' ) &&  ( $date2_is_leap_year eq 'no' ) )
         {
         if ( ( $date1_day_of_month_07  ==  29 )  &&  ( $date2_day_of_month_07  ==  28 ) )
            {
            $year_difference_00--;
            }
         }
      }

   # Set year difference to string '0' if it is zero
   if ( $year_difference_00 == 0 )
      {
      $year_difference_00 = '0';
      }

   return( $year_difference_00 );
   }




###############################################################################
# Usage      : date_offset_in_years( SCALAR, SCALAR )
# Purpose    : find a date in the future or past offset by the number of YEARS from the given date
# Returns    : - date of the day offset from the given date if successful
# Parameters : (
#            :   date in any format,
#            :   number of WHOLE offset years, positive is future date, negative is past date, zero is current date (no offset)
#            : )
# Throws     : Throws exception for any invalid input
# Comments   : There are two exceptions where the new month/dayofmonth do NOT match the original
#            :   - Feb 29 in a leap year maps to Feb 28 in a NON leap year
#            :   - Feb 28 in a NON leap year maps to Feb 29 in a leap year
# See Also   : N/A
###############################################################################
sub date_offset_in_years
   {
   my (
       $date_in_03,
       $date_delta_years_00
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_32 = 2;
   ( @_ ==  $num_input_params_32) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly $num_input_params_32 parameter(s), a date string followed by the number of offset days.   '@_'.\n\n\n";

   ( ref(\$date_in_03) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the date string    '$date_in_03'.\n\n\n";
   ( $date_in_03  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the date string    '$date_in_03'.\n\n\n";
   ( date_only_parse($date_in_03) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Cannot parse the date from the input date string    '$date_in_03'.\n\n\n";

   ( ref(\$date_delta_years_00) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the number of WHOLE offset years    '$date_delta_years_00'.\n\n\n";
   ( $date_delta_years_00  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty value for the number of WHOLE offset years    '$date_delta_years_00'.\n\n\n";
   ( $date_delta_years_00  =~ m/^\-{0,1}\d+$/ ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects an integer value, positive, negative or zero, for the number of WHOLE offset years    '$date_delta_years_00'.\n\n\n";


   if ( $date_delta_years_00  ==  0 )
      {
      return ( format_date( $date_in_03 ) );
      }


   my ( $date1_month_num_08, $date1_day_of_month_08, $date1_year_num_08, $date1_day_of_week_08 ) = date_only_parse($date_in_03);


   my $offset_year_01 = $date1_year_num_08 + $date_delta_years_00;

   # Handle case where leap year (Feb 29) is to be mapped to a NON leap year (Feb 28)
   my $mapped_to_end_of_month = $date1_day_of_month_08;
   if ( !is_leap_year( $offset_year_01 ) )
      {
      if ( ( $date1_month_num_08  ==  2 )  &&  ( $date1_day_of_month_08  ==  29 ) )
         {
         $mapped_to_end_of_month = 28;
         }
      }

   # Handle case where NON leap year (Feb 28) is to be mapped to a leap year (Feb 29)
   elsif ( !is_leap_year( $date1_year_num_08 ) )
      {
      if ( ( $date1_month_num_08  ==  2 )  &&  ( $date1_day_of_month_08  ==  28 ) )
         {
         $mapped_to_end_of_month = 29;
         }
      }

   return( format_date( $date1_month_num_08, $mapped_to_end_of_month, $offset_year_01 ) );
   }




###############################################################################
# Usage      : number_of_weekdays_in_range( SCALAR, SCALAR )
# Purpose    : calculates the number of weekdays in the range of the two dates
# Returns    : integer number of weekdays if successful
# Parameters : (
#            :   date ONE in any format,
#            :   date TWO in any format
#            : )
# Throws     : Throws exception for any invalid input
# Comments   : - Difference is positive if date1 > date2
#            : - Difference is negative if date1 < date2
#            : - Friday to Saturday counts as ZERO days
#            : - Friday to Sunday   counts as ZERO days
#            : - Friday to Monday   counts as one  day
#            : - Tuesday to previous Wednesday counts as NEGATIVE four days
# See Also   : N/A
###############################################################################
sub number_of_weekdays_in_range
   {
   my (
       $date_one_05,
       $date_two_05
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_33 = 2;
   ( @_ ==  $num_input_params_33) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly $num_input_params_33 parameters ('date1' and date2).   '@_'.\n\n\n";

   ( ref(\$date_one_05) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR first parameter for the first date    '$date_one_05'.\n\n\n";
   ( ref(\$date_two_05) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR second parameter for the second date    '$date_two_05'.\n\n\n";

   ( $date_one_05  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the first date    '$date_one_05'.\n\n\n";
   ( $date_two_05  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the second date    '$date_two_05'.\n\n\n";

   ( date_only_parse($date_one_05) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Cannot extract the date from the input date1 string    '$date_one_05'.\n\n\n";
   ( date_only_parse($date_two_05) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Cannot extract the date from the input date2 string    '$date_two_05'.\n\n\n";


   # Get count of ALL days in range as a starting point
   my $number_of_days_in_range_00 = date1_to_date2_delta( $date_one_05, $date_two_05 );

   # Get the number of weekdays in the range for the WHOLE weeks in the range
   my $number_weekdays_00 = int( abs($number_of_days_in_range_00) / 7 ) * 5;

   # Get the remainder of weekdays in the range that is discarded by the previous variable
   my $week_remainder_00 = abs( $number_of_days_in_range_00 ) % 7;

   my $current_dayofweek_00 = get_numeric_day_of_week($date_two_05);
   # Cycle through the left over days in the range that do not form a WHOLE week and add them in into the total IF they are weekdays
   for ( my $iii_004=0; $iii_004<$week_remainder_00; $iii_004++ )
      {
      if ( $number_of_days_in_range_00 > 0 ) # range is positive
         {
         $current_dayofweek_00++;
         if ( $current_dayofweek_00 > 7 )
            {
            $current_dayofweek_00 -= 7;
            }

         if ( $current_dayofweek_00 < 6 ) # weekdays
            {
            $number_weekdays_00++;
            }
         }
      if ( $number_of_days_in_range_00 < 0 ) # range is negative
         {
         $current_dayofweek_00--;
         if ( $current_dayofweek_00 < 1 )
            {
            $current_dayofweek_00 += 7;
            }

         if ( $current_dayofweek_00 < 6 ) # weekdays
            {
            $number_weekdays_00++;
            }
         }
      }


   # Put correct sign to number of days in range
   if ( $number_of_days_in_range_00 > 0 )
      {
      return( $number_weekdays_00 );
      }
   elsif ( $number_of_days_in_range_00 < 0 )
      {
      return( -$number_weekdays_00 );
      }
   else
      {
      return( '0' );
      }

   }




###############################################################################
# Usage      : date_offset_in_weekdays( SCALAR, SCALAR )
# Purpose    : find a WEEKDAY date in the future or past offset by the number of weekdays from the given starting WEEKDAY date
# Returns    : - date of the WEEKDAY day offset from the given WEEKDAY date if successful
# Parameters : (
#            :   WEEKDAY date in any format,
#            :   number of weekdays offset, positive is future date, negative is past date, zero is current date (no offset)
#            : )
# Throws     : Throws exception for any invalid input INCLUDING weekend dates
# Comments   : This effectively functions as if ALL weekend dates were removed
#            : from the calendar.  This function accepts ONLY weekday dates and
#            : outputs ONLY weekday dates
# See Also   : N/A
###############################################################################
sub date_offset_in_weekdays
   {
   my (
       $date_in_05,
       $date_delta_01
      )
       = @_;


   # Incoming Inspection
   my $num_input_params_36 = 2;
   ( @_ ==  $num_input_params_36) or croak "\n\n   ($0)   '${\(caller(0))[3]}' should have exactly $num_input_params_36 parameter(s), a date string followed by the number of offset days.   '@_'.\n\n\n";

   ( ref(\$date_in_05) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the date string    '$date_in_05'.\n\n\n";
   ( $date_in_05  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty string for the date string    '$date_in_05'.\n\n\n";
   ( date_only_parse($date_in_05) ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Cannot parse the date from the input date string    '$date_in_05'.\n\n\n";

   ( ref(\$date_delta_01) eq 'SCALAR' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a SCALAR parameter for the number of offset days    '$date_delta_01'.\n\n\n";
   ( $date_delta_01  ne  '' ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects a NON-empty value for the number of offset days    '$date_delta_01'.\n\n\n";
   ( $date_delta_01  =~ m/^\-{0,1}\d+$/ ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects an integer value, positive, negative or zero, for the number of offset days    '$date_delta_01'.\n\n\n";


   # Check that starting date is a WEEKDAY
   my $day_of_week_16 = get_numeric_day_of_week($date_in_05);

   ( $day_of_week_16 < 6 ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects the starting date, '$date_in_05', to be a WEEKDAY.  It is incorrectly a ${\(set_day_to_day_name_full($day_of_week_16))}.\n\n\n";

   my $past_future = 1;
   if ( $date_delta_01 < 0 )
      {
      $past_future = -1;
      }

#  1    0    0       7/5                       2    0    0       7/5                       3    0    0       7/5                       4    0    0       7/5                       5    0    0       7/5
#  1    1    1   int(7/5)                      2    1    1   int(7/5)                      3    1    1   int(7/5)                      4    1    1   int(7/5)                      5    1    3   int(7/5) + 2
#  1    2    2   int(7/5)                      2    2    2   int(7/5)                      3    2    2   int(7/5)                      4    2    4   int(7/5) + 2                  5    2    4   int(7/5) + 2
#  1    3    3   int(7/5) - 1                  2    3    3   int(7/5) - 1                  3    3    5   int(7/5) + 1                  4    3    5   int(7/5) + 1                  5    3    5   int(7/5) + 1
#  1    4    4   int(7/5) - 1                  2    4    6   int(7/5) + 1                  3    4    6   int(7/5) + 1                  4    4    6   int(7/5) + 1                  5    4    6   int(7/5) + 1

#  1    0    0           7/5                   2    0    0           7/5                   3    0    0           7/5                   4    0    0           7/5                   5    0    0           7/5     
#  1   -1   -3  -int(abs(7/5)) - 2             2   -1   -1  -int(abs(7/5))                 3   -1   -1  -int(abs(7/5))                 4   -1   -1  -int(abs(7/5))                 5   -1   -1  -int(abs(7/5))
#  1   -2   -4  -int(abs(7/5)) - 2             2   -2   -4  -int(abs(7/5)) - 2             3   -2   -2  -int(abs(7/5))                 4   -2   -2  -int(abs(7/5))                 5   -2   -2  -int(abs(7/5))
#  1   -3   -5  -int(abs(7/5)) - 1             2   -3   -5  -int(abs(7/5)) - 1             3   -3   -5  -int(abs(7/5)) - 1             4   -3   -3  -int(abs(7/5)) + 1             5   -3   -3  -int(abs(7/5)) + 1
#  1   -4   -6  -int(abs(7/5)) - 1             2   -4   -6  -int(abs(7/5)) - 1             3   -4   -6  -int(abs(7/5)) - 1             4   -4   -6  -int(abs(7/5)) - 1             5   -4   -4  -int(abs(7/5)) + 1

   my $weekday_remainder = abs($date_delta_01) % 5;
   my $num_days_effective = 'xxx';
   if (
       ( ( $day_of_week_16  ==  1 )  &&  ( $date_delta_01  >  0 ) )  ||
       ( ( $day_of_week_16  ==  5 )  &&  ( $date_delta_01  <  0 ) )
      )
      {
      foreach ( $weekday_remainder )
         {
         SWITCH:
            {
            if ( $_ <=  2 )   { $num_days_effective = $past_future * int( abs($date_delta_01 * (7/5) ) );                       last SWITCH; }
                                $num_days_effective = $past_future * int( abs($date_delta_01 * (7/5) ) ) - $past_future;
            }
         }
      }
   elsif (
          ( ( $day_of_week_16  ==  2 )  &&  ( $date_delta_01  >  0 ) )  ||
          ( ( $day_of_week_16  ==  4 )  &&  ( $date_delta_01  <  0 ) )
         )
      {
      foreach ( $weekday_remainder )
         {
         SWITCH:
            {
            if ( $_ <=  2 )   { $num_days_effective = $past_future * int( abs($date_delta_01 * (7/5) ) );                       last SWITCH; }
            if ( $_ ==  3 )   { $num_days_effective = $past_future * int( abs($date_delta_01 * (7/5) ) ) - $past_future;        last SWITCH; }
                                $num_days_effective = $past_future * int( abs($date_delta_01 * (7/5) ) ) + $past_future;
            }
         }
      }
   elsif (
          ( ( $day_of_week_16  ==  3 )  &&  ( $date_delta_01  >  0 ) )  ||
          ( ( $day_of_week_16  ==  3 )  &&  ( $date_delta_01  <  0 ) )
         )
      {
      foreach ( $weekday_remainder )
         {
         SWITCH:
            {
            if ( $_ <=  2 )   { $num_days_effective = $past_future * int( abs($date_delta_01 * (7/5) ) );                       last SWITCH; }
                                $num_days_effective = $past_future * int( abs($date_delta_01 * (7/5) ) ) + $past_future;
            }
         }
      }
   elsif (
          ( ( $day_of_week_16  ==  4 )  &&  ( $date_delta_01  >  0 ) )  ||
          ( ( $day_of_week_16  ==  2 )  &&  ( $date_delta_01  <  0 ) )
         )
      {
      foreach ( $weekday_remainder )
         {
         SWITCH:
            {
            if ( $_ <   2 )   { $num_days_effective = $past_future * int( abs($date_delta_01 * (7/5) ) );                       last SWITCH; }
            if ( $_ ==  2 )   { $num_days_effective = $past_future * int( abs($date_delta_01 * (7/5) ) ) + $past_future * 2;    last SWITCH; }
                                $num_days_effective = $past_future * int( abs($date_delta_01 * (7/5) ) ) + $past_future;
            }
         }
      }
   elsif (
          ( ( $day_of_week_16  ==  5 )  &&  ( $date_delta_01  >  0 ) )  ||
          ( ( $day_of_week_16  ==  1 )  &&  ( $date_delta_01  <  0 ) )
         )
      {
      foreach ( $weekday_remainder )
         {
         SWITCH:
            {
            if ( $_ ==  0 )   { $num_days_effective = $past_future * int( abs($date_delta_01 * (7/5) ) );                       last SWITCH; }
            if ( $_ ==  1 )   { $num_days_effective = $past_future * int( abs($date_delta_01 * (7/5) ) ) + $past_future * 2;    last SWITCH; }
            if ( $_ ==  2 )   { $num_days_effective = $past_future * int( abs($date_delta_01 * (7/5) ) ) + $past_future * 2;    last SWITCH; }
                                $num_days_effective = $past_future * int( abs($date_delta_01 * (7/5) ) ) + $past_future;
            }
         }
      }
   else
      {
      $num_days_effective = 0;
      }


   # Check that offset date is a WEEKDAY
   my $weekday_offset_00 = date_offset_in_days($date_in_05, $num_days_effective);
   my $day_of_week_17 = get_numeric_day_of_week($weekday_offset_00);

   ( $day_of_week_17 < 6 ) or croak "\n\n   ($0)   '${\(caller(0))[3]}' Expects the offset date, '$weekday_offset_00', to be a WEEKDAY.  It is incorrectly a ${\(set_day_to_day_name_full($day_of_week_17))}.  This condition should NOT occur.  Something is amiss.\n\n\n";

   return ( $weekday_offset_00 );
   }




}
1;

__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Date::Components - Parses, processes and formats ONLY dates and date components
(time parameters are ignored).

=head1 VERSION

This documentation refers to Date::Components version 0.2.1

=head1 SYNOPSIS


  use Carp              qw(croak);
  use Date::Components  qw(
                           date_only_parse
                           is_valid_year
                           set_day_to_day_name_abbrev
                           format_date
                          );

  # Parse a $date string and extract its components
  my $date = 'Mon Sep 17 08:50:51 2007';
  my ($month, $day, $year, $dayofweek) = date_only_parse($date);

  # Test if $year is valid
  ( is_valid_year( $year ) ) or croak "   Input year, '$year', is not a valid input.\n";

  # Set $dayofweek, whether alpha or numeric, to alpha.
  my $alpha_day = set_day_to_day_name_abbrev( $dayofweek );

  # Re-formats $date to one of several user choices
  my $formatted_date = format_date( $date );








=head1 DESCRIPTION

Date::Components parses dates into components on the front end, formats them on
the back end and enables many operations on whole dates and date components in
between.

This unique module was created to combine a parser, formatter, component
operators and time independence into a single unit.  Independence of time also
enables the widest date range possible (limited by integer size).  Applications
include portfolio management where only dates are relevant.  With the variety
of supported date formats, it can be used as an in-line date re-formatter.
Subroutines providing operations specific to the standard 400 year cycle are
included also.

The module is not object oriented.  Rather, it supplies a variety of
useful functions to analyze, process and format complete dates and the four
date components of I<month>, I<day-of-month>, I<year> and I<day-of-week>.
B<ALL> representations of time and related parameters are ignored, including
hours, minutes, seconds, time zones, daylight savings time, etc.

Leap year standard is used.  According to the Royal Greenwich Observatory, the
calendar year is 365 days long, unless the year is exactly divisible by four,
then an extra day is added to February so the year is 366 days long. If the
year is the last year of a century, e.g., 2000, 2100, 2200, 2300, 2400, then it
is only a leap year if it is exactly divisible by 400. So, 2100 won't be a leap
year but 2000 is. The next century year, exactly divisible by 400, won't occur
until 2400--400 years away.

Subroutines C<is_valid_date>, C<format_date> and C<get_numeric_day_of_week>
are overloaded to accept either a list of date components or a single SCALAR
date string to enable more flexible usage.

Date strings returned by subroutines are always in default format.


=head2 Conventions

  To make the code correspond to standard date representations, day of the week
  and month numbers both start at 1.

  Day numbers are represented as 1-7 corresponding to Mon through Sun.

  Month numbers are represented as 1-12 corresponding to Jan through Dec.


=head2 Subroutine List

=over 4

=item Frontend / Backend

=over 4

=item C<date_only_parse>

=item C<format_date>

=back


=item Validity Check

=over 4

=item C<is_valid_date>

=item C<is_valid_month>

=item C<is_valid_day_of_month>

=item C<is_valid_day_of_week>

=item C<is_valid_year>

=item C<is_valid_400_year_cycle>

=back

=item Component Formatting

=over 4

=item C<set_day_to_day_name_abbrev>

=item C<set_day_to_day_name_full>

=item C<set_day_to_day_number>

=item C<set_month_to_month_name_abbrev>

=item C<set_month_to_month_name_full>

=item C<set_month_to_month_number>

=item C<day_name_to_day_number>

=item C<day_number_to_day_name>

=item C<month_name_to_month_number>

=item C<month_number_to_month_name>

=back

=item Date Operations

=over 4

=item C<compare_date1_and_date2>

=item C<date1_to_date2_delta>

=item C<date_offset_in_days>

=item C<date_offset_in_weekdays>

=item C<compare_year1_and_year2>

=item C<year1_to_year2_delta>

=item C<date_offset_in_years>

=item C<number_of_weekdays_in_range>

=back

=item Inquiries

=over 4

=item C<is_leap_year>

=item C<get_year_phase>

=item C<number_of_day_within_year>

=item C<day_number_within_year_to_date>

=item C<day_number_within_400_year_cycle_to_date>

=item C<get_number_of_day_within_400yr_cycle>

=item C<get_days_remaining_in_400yr_cycle>

=item C<get_num_days_in_year>

=item C<get_days_remaining_in_year>

=item C<get_numeric_day_of_week>

=item C<get_month_from_string>

=item C<get_dayofmonth_from_string>

=item C<get_year_from_string>

=item C<get_number_of_days_in_month>

=item C<get_days_remaining_in_month>

=item C<get_first_of_month_day_of_week>

=item C<calculate_day_of_week_for_first_of_month_in_next_year>

=item C<get_global_year_cycle>

=back

=back

=head2 Parsing and Formatting

Refer to the documentation of the C<date_only_parse> and C<format_date>
routines for specifics.  If other formats are desired, please contact the
author.  Note that ALL years, even negative, are accepted.


=head1 EXPORT

None by default.

=head1 SUBROUTINES

=over 4








=item B<date_only_parse>

=over 8

=item Usage:

 my ($month, $dayofmonth, $year, $dayofweek = date_only_parse( <date string> );

=item Purpose:

 Converts variety of date strings into components for processing

=item Returns:

 - if parse is unsuccessful it returns a list:
         (
           month_integer<1-12>,
           day_of_month_integer<1-N>,
           year_integer,
           numeric_day_of_week<1 for Mon ... 7 for Sun>
         )
 - '' if parameter is a valid string from which a VALID date is NOT recognized


=item Parameters:

 Text string containing date in various formats

=item Throws:

 Throws exception for any invalid input

=item Comments:

 Handles all years, even negative years (aka BC)
 Formats Parsed (case insensitive)
   - 'month_num/day_num/year'
       Single digits for month and day are allowed for parsing.
   - 'Mon Sep 17 08:50:51 2007'
   - 'September 17, 2007'
   - '17 September, 2007'
   - 'YYYY-MM-DD' (ex: 2007-09-01 <Sep 1, 2007>)

=item Examples:

 date_only_parse('2/29/2005');                 # Returns  ''
 date_only_parse('Mon Feb 27 08:50:51 2005');  # Returns  ''
 date_only_parse('13/9/1619');                 # Returns  ''
 date_only_parse('2/29/2004');                 # Returns  (  2, 29,  2004, 7 )
 date_only_parse('Mon Jul 31 08:50:51 1865');  # Returns  (  7, 31,  1865, 1 )
 date_only_parse('2/29/2000');                 # Returns  (  2, 29,  2000, 2 )
 date_only_parse('1876-12-18');                # Returns  ( 12, 18,  1876, 1 )
 date_only_parse('-407-06-03');                # Returns  (  6,  3,  -407, 4 )
 date_only_parse('July 9, 2089');              # Returns  (  7,  9,  2089, 6 )
 date_only_parse('23 March, 30004');           # Returns  (  3, 23, 30004, 2 )

=back








=item B<format_date>

=over 8

=item Usage:

 Function is overloaded to accept EITHER a date string OR a date component.
   1) Date string, <OPTIONAL date format>
      my $date = format_date( SCALAR, <SCALAR> );
   2) Month, dayofmonth, year, <OPTIONAL date format>
      my $date = format_date( SCALAR, SCALAR, SCALAR, <SCALAR> );

=item Purpose:

 Formats dates

=item Returns:

 Date string

=item Parameter(s):

 - ( date string in any format, <optional date format> )
                  OR
 - ( month, day of month, year, <optional date format> )

=item Throws:

 Throws exception for any invalid input

=item Comments:

 - Handles all years, even negative years (aka BC)
 - It does NOT output time, time zone or any other time parameter
   other than a CONSTANT 12noon time when a time component is
   included in the format.
 - Format options
    <Default> ->  'mm/dd/yyyy'
    'A'       ->  'Mon Sep 17 12:00:00 2007' (time component is ALWAYS 12 noon)
    'B'       ->  'September 17, 2007'
    'C'       ->  '17 September, 2007'
    'D'       ->  'YYYY-MM-DD'

=item Examples:

 format_date(7, 4, 1599,  'A');           # Returns  'Sun Jul  4 12:00:00 1599'
 format_date('Mon Sep 17 08:50:51 2007'); # Returns  '09/17/2007'
 format_date('12/31/-401');               # Returns  '12/31/-401'
 format_date('1/4/2001');                 # Returns  '01/04/2001'
 format_date( 2, 29, 1604,  'B');         # Returns  'February 29, 1604'
 format_date( 2, 29, 1604,  'C');         # Returns  '29 February, 1604'
 format_date( 3,  7, 1604,  'D');         # Returns  '1604-03-07'
 format_date('15 January,  -87', 'D');    # Returns  '-87-01-15'

=back








=item B<is_valid_date>

=over 8

=item Usage:

 Function is overloaded to accept one of three date input types
 1) Date string
     my $status = is_valid_date( SCALAR );
 2) Month, dayofmonth, year
     my $status = is_valid_date( SCALAR, SCALAR, SCALAR );
 3) Month, dayofmonth, year, dayofweek
     my $status = is_valid_date( SCALAR, SCALAR, SCALAR, SCALAR );

=item Purpose:

 Checks if date is valid

=item Returns:

 - '1' if date is valid
 - ''  otherwise

=item Parameter(s):

 - ( date string in any format )
           OR
 - ( month, day of month, year )
           OR
 - ( month, day of month, year, dayofweek )

=item Throws:

 No exceptions

=item Comments:

 - Handles all years, even negative years (aka BC)
 - Month can be any of numeric, three character abbreviation or full
 - Day of week can be any of numeric, three character abbreviation or full
 - <1 for Jan ... 12 for Dec>
 - <1 for Mon ... 7 for Sun>

=item Examples:

 is_valid_date   (2, 29, 2005, 7);              # Returns ''
 is_valid_date   ('Jan,  15, 2005, Sat');       # Returns ''
 is_valid_date   ('0/14/1988');                 # Returns ''
 is_valid_date   (6,'0', 47);                   # Returns ''
 is_valid_date   (2, 0, 2005, 7);               # Returns ''
 is_valid_date   ('Jan', 15, 2005, 'Sat');      # Returns  1
 is_valid_date   (8, 15, 1964);                 # Returns  1
 is_valid_date   (3, 5, 2000, 'Sun');           # Returns  1
 is_valid_date   (6, 3, 47);                    # Returns  1
 is_valid_date   ('5/14/1988');                 # Returns  1
 is_valid_date   ('Sun Feb 29 12:00:00 1604');  # Returns  1

=back








=item B<is_valid_month>

=over 8

=item Usage:

 my $status = is_valid_month( $month );

=item Purpose:

 Checks if month is valid

=item Returns:

 - '1' if month is valid
 - ''  otherwise

=item Parameter(s):

 Month in one of three formats ( numeric <1-12>, full name or three character abbreviated )

=item Throws:

 No exceptions

=item Comments:

 <1 for Jan ... 12 for Dec>

=item Examples:

 is_valid_month(' 11 ');        # Returns  ''
 is_valid_month('Feb', 'Mar');  # Returns  ''
 is_valid_month(4);             # Returns   1
 is_valid_month('July');        # Returns   1
 is_valid_month('JAN');         # Returns   1

=back








=item B<is_valid_day_of_month>

=over 8

=item Usage:

 my $status = is_valid_day_of_month( $month, $dayofmonth, $year );

=item Purpose:

 Checks if day of month is valid

=item Returns:

 - '1' if day of month is valid
 - ''  otherwise

=item Parameter(s):

 - Month in one of three formats ( numeric <1-12>, full name or three character abbreviated )
 - Day of month (1-31)
 - Year

=item Throws:

 No exceptions

=item Comments:

 Handles all years, even negative years (aka BC)

=item Examples:

 is_valid_day_of_month( 2,       30,   1555);  # Returns  ''
 is_valid_day_of_month( 8,      '0',   1555);  # Returns  ''
 is_valid_day_of_month( 2,       29,   1559);  # Returns  ''
 is_valid_day_of_month( 2,       28,   1559);  # Returns   1
 is_valid_day_of_month('May',    31,     -3);  # Returns   1
 is_valid_day_of_month('Jul',    31,  50032);  # Returns   1
 is_valid_day_of_month('August', 31,   1888);  # Returns   1

=back








=item B<is_valid_day_of_week>

=over 8

=item Usage:

 my $status = is_valid_day_of_week( $dayofweek );

=item Purpose:

 Checks if day of week is valid

=item Returns:

 - '1' if day of week is valid
 - ''  otherwise

=item Parameter(s):

 Day of week

=item Throws:

 No exceptions

=item Comments:

 <1 for Mon ... 7 for Sun>

=item Examples:

 is_valid_day_of_week('0');       # Returns  ''
 is_valid_day_of_week(' 7');      # Returns  ''
 is_valid_day_of_week('Sat ');    # Returns  ''
 is_valid_day_of_week(7);         # Returns   1
 is_valid_day_of_week('Mon');     # Returns   1
 is_valid_day_of_week('Friday');  # Returns   1
 is_valid_day_of_week('TUE');     # Returns   1

=back








=item B<is_valid_year>

=over 8

=item Usage:

 my $status = is_valid_year( $year );

=item Purpose:

 Checks if year is valid

=item Returns:

 - '1' if year is valid
 - ''  otherwise

=item Parameter(s):

 Year

=item Throws:

 No exceptions

=item Comments:

 Handles all years, even negative years (aka BC)

=item Examples:

 is_valid_year('-1600 BC');      # Returns  ''
 is_valid_year(' 1962 ');        # Returns  ''
 is_valid_year(' 2005');         # Returns  ''
 is_valid_year('2007', '2008');  # Returns  ''
 is_valid_year('-33');           # Returns   1
 is_valid_year(1999);            # Returns   1
 is_valid_year('2642');          # Returns   1

=back








=item B<is_valid_400_year_cycle>

=over 8

=item Usage:

 my $status = is_valid_400_year_cycle( $year_400_cycle );

=item Purpose:

 Checks if year is valid 400 year cycle phase

=item Returns:

 - '1' if year is valid 400 year cycle phase number
 - ''  otherwise

=item Parameter(s):

 400 year cycle

=item Throws:

 No exceptions

=item Comments:

 valid inputs (years) are multiples of 400
  (i.e.  ... -400, 0, 400, ... 1600, 2000, 2400, ...)

=item Examples:

 is_valid_400_year_cycle( -900);  # Returns  ''
 is_valid_400_year_cycle( 1924);  # Returns  ''
 is_valid_400_year_cycle(-1200);  # Returns   1
 is_valid_400_year_cycle(    0);  # Returns   1
 is_valid_400_year_cycle(64000);  # Returns   1

=back








=item B<set_day_to_day_name_abbrev>

=over 8

=item Usage:

 my $dayofweek_alpha = set_day_to_day_name_abbrev( $dayofweek );

=item Purpose:

 Set the incoming day of week to three letter abbreviation

=item Returns:

 Day of week as three character abbreviation

=item Parameter(s):

 Day of week in one of three formats ( numeric <1-7>, full name or three character abbreviated )

=item Throws:

 Throws exception for any invalid input

=item Comments:

 1 for Mon, ..., 7 for Sun

=item Examples:

 set_day_to_day_name_abbrev('Wednesday'); # Returns 'Wed'
 set_day_to_day_name_abbrev('Sat');       # Returns 'Sat'
 set_day_to_day_name_abbrev(5);           # Returns 'Fri'

=back








=item B<set_day_to_day_name_full>

=over 8

=item Usage:

 my $dayofweek_fullname = set_day_to_day_name_full( $dayofweek );

=item Purpose:

 Set the day of week to full name

=item Returns:

 Day of week full name

=item Parameter(s):

 Day of week in one of three formats ( numeric<1-7>, full name or three character abbreviated )

=item Throws:

 Throws exception for any invalid input

=item Comments:

 <1 for Monday ... 7 for Sunday>

=item Examples:

 set_day_to_day_name_full(5);          # Returns  'Friday'
 set_day_to_day_name_full('Tuesday');  # Returns  'Tuesday'
 set_day_to_day_name_full('Sun');      # Returns  'Sunday'

=back








=item B<set_day_to_day_number>

=over 8

=item Usage:

 my $dayofweek_number = set_day_to_day_number( $dayofweek );

=item Purpose:

 Set the incoming day of week to day of week number

=item Returns:

 Numeric day of week (1-7)

=item Parameter(s):

 Day of week in one of three formats ( numeric <1-7>, full name or three character abbreviated )

=item Throws:

 Throws exception for any invalid input

=item Comments:

 1 for Mon, ..., 7 for Sun

=item Examples:

 set_day_to_day_number('Sunday'); # Returns 7
 set_day_to_day_number('Tue');    # Returns 2
 set_day_to_day_number(1);        # Returns 1

=back








=item B<set_month_to_month_name_abbrev>

=over 8

=item Usage:

 my $month_alpha = set_month_to_month_name_abbrev( $month );

=item Purpose:

 Set the incoming month to three letter abbreviation

=item Returns:

 Three character month abbreviation

=item Parameter(s):

 Month in one of three formats ( numeric <1-12>, full name or three character abbreviated )

=item Throws:

 Throws exception for any invalid input

=item Comments:

 Again, the standard three character abbreviation for the month is returned.

=item Examples:

 set_month_to_month_name_abbrev(11);      # Returns 'Nov'
 set_month_to_month_name_abbrev('Dec');   # Returns 'Dec'
 set_month_to_month_name_abbrev('April'); # Returns 'Apr'

=back








=item B<set_month_to_month_name_full>

=over 8

=item Usage:

 my $month_fullname = set_month_to_month_name_full( $month );

=item Purpose:

 Set the incoming month to full name

=item Returns:

 Month full name

=item Parameter(s):

 Month in one of three formats ( numeric<1-12>, full name or three character abbreviated )

=item Throws:

 Throws exception for any invalid input

=item Comments:

 <1 for Jan ... 12 for Dec>

=item Examples:

 set_month_to_month_name_full(11);        # Returns  'November'
 set_month_to_month_name_full('Apr');     # Returns  'April'
 set_month_to_month_name_full('August');  # Returns  'August'

=back








=item B<set_month_to_month_number>

=over 8

=item Usage:

 my $month_num = set_month_to_month_number( $month );

=item Purpose:

 Set the incoming month to month number

=item Returns:

 Numeric month (1-12)

=item Parameter(s):

 Month in one of three formats ( numeric <1-12>, full name or three character abbreviated )

=item Throws:

 Throws exception for any invalid input

=item Examples:

 set_month_to_month_number(3);      # Returns 3
 set_month_to_month_number('Jan');  # Returns 1
 set_month_to_month_number('July'); # Returns 7

=back








=item B<day_name_to_day_number>

=over 8

=item Usage:

 my $numeric_dayofweek = day_name_to_day_number( $day_name );

=item Purpose:

 Convert alpha day of week name to numeric day of week

=item Returns:

 Numeric day of week (1-7)

=item Parameter(s):

 Day of week, full name or three letter abbreviation

=item Throws:

 Throws exception for any invalid input

=item Comments:

 <1 for Mon ... 7 for Sun>

=item Examples:

 day_name_to_day_number('Tue'     ); # Returns 2
 day_name_to_day_number('Thursday'); # Returns 4
 day_name_to_day_number('Sunday'  ); # Returns 7

=back








=item B<day_number_to_day_name>

=over 8

=item Usage:

 my $dayofweek_abbreviated = day_number_to_day_name( $numeric_dayofweek );

=item Purpose:

 Convert numeric number to three letter abbreviation for day of week

=item Returns:

 Abbreviated day of week

=item Parameter(s):

 Numeric day of week (1-7)

=item Throws:

 Throws exception for any invalid input

=item Comments:

 <1 for Mon ... 7 for Sun>

=item Examples:

 day_number_to_day_name(1); # Returns 'Mon'
 day_number_to_day_name(3); # Returns 'Wed'
 day_number_to_day_name(7); # Returns 'Sun'

=back








=item B<month_name_to_month_number>

=over 8

=item Usage:

 my $month_number = month_name_to_month_number( $month_alpha );

=item Purpose:

 Convert alpha month name to month number

=item Returns:

 Numeric month (1-12)

=item Parameter(s):

 Month in alpha format ( full name or three character abbreviated )

=item Throws:

 Throws exception for any invalid input

=item Comments:

 Input month MUST be in alpha format, full or abbreviated

=item Examples:

 month_name_to_month_number('Nov');      # Returns 11
 month_name_to_month_number('February'); # Returns 2

=back








=item B<month_number_to_month_name>

=over 8

=item Usage:

 my $month_alpha = month_number_to_month_name( $month_num );

=item Purpose:

 Convert month number to month alpha

=item Returns:

 Three character month abbreviation

=item Parameter(s):

 Month in numeric format

=item Throws:

 Throws exception for any invalid input

=item Comments:

 Input month MUST be in numeric format (1-12)

=item Examples:

 month_number_to_month_name(9); # Returns 'Sep'

=back








=item B<compare_date1_and_date2>

=over 8

=item Usage:

 my $compare_result = compare_date1_and_date2( $date_1, date_2 );

=item Purpose:

 Compares two dates to find which one is later

=item Returns:

 -  '1' if the FIRST date is LATER   than the second
 - '-1' if the FIRST date is EARLIER than the second
 -  '0' if both dates are the same

=item Parameter(s):

 - Date string one in any format
 - Date string two in any format

=item Throws:

 Throws exception for any invalid input

=back








=item B<date1_to_date2_delta>

=over 8

=item Usage:

 my $date_difference = date1_to_date2_delta( $date_1, date_2 );

=item Purpose:

 Finds the difference in days between the two dates by subtracting the second from the first

=item Returns:

 Number of days difference

=item Parameter(s):

 - Date string one in any format
 - Date string two in any format

=item Throws:

 Throws exception for any invalid input

=item Comments:

 If day ONE is EARLIER than date TWO, a negative number is returned.

=item Examples:

 date1_to_date2_delta('Sat Jan  7 08:50:51   1995', '1/8/1996'); # Returns -366
 date1_to_date2_delta('4/11/2002',                  '4/9/2002'); # Returns 2
 date1_to_date2_delta('12/11/1544',               '12/11/1544'); # Returns 0

=back








=item B<date_offset_in_days>

=over 8

=item Usage:

 my $offset_date = date_offset_in_days( $date, $num_days );

=item Purpose:

 Find a date in the future or past offset by the number of days from the given date

=item Returns:

 Date of the day offset from the given date

=item Parameter(s):

 - Date string in any format
 - Integer number of days, positive or negative

=item Throws:

 Throws exception for any invalid input

=item Comments:

 Positive offset is future date, negative is past date, zero is current date (no offset)

=item Examples:

 date_offset_in_days('1/1/2000',    1);  # Returns '1/2/2000'
 date_offset_in_days('1/21/2000',  -5);  # Returns '1/16/2000'

=back








=item B<date_offset_in_weekdays>

=over 8

=item Usage:

 my $offset_date = date_offset_in_weekdays( $date, $num_days );

=item Purpose:

 Find a WEEKDAY date in the future or past offset by the number of weekdays from the given starting WEEKDAY date

=item Returns:

 Date of the weekday offset from the given weekday date

=item Parameter(s):

 - Weekday date string in any format
 - Integer number of weekdays, positive or negative

=item Throws:

 Throws exception for any invalid input INCLUDING weekend dates

=item Comments:

 This effectively functions as if ALL weekend dates were removed
 from the calendar.  This function accepts ONLY weekday dates and
 outputs ONLY weekday dates

=item Examples:

 date_offset_in_weekdays('Mon Jul 11 08:50:51 1977', -7);  # Returns '06/30/1977'
 date_offset_in_weekdays('Tue Jul 12 08:50:51 1977', -3);  # Returns '07/07/1977'
 date_offset_in_weekdays('Wed Jul 13 08:50:51 1977',  0);  # Returns '07/13/1977'
 date_offset_in_weekdays('Thu Jul 14 08:50:51 1977',  3);  # Returns '07/19/1977'
 date_offset_in_weekdays('Fri Jul 15 08:50:51 1977',  7);  # Returns '07/26/1977'

=back








=item B<compare_year1_and_year2>

=over 8

=item Usage:

 my $compare_result = compare_year1_and_year2( $date_1, date_2 );

=item Purpose:

 Compares two dates to find which one is the later year, months and days are ignored

=item Returns:

 -  '1' if the FIRST year is LATER   than the second
 - '-1' if the FIRST year is EARLIER than the second
 -  '0' if both years are the same

=item Parameter(s):

 - Date string one in any format
 - Date string two in any format

=item Throws:

 Throws exception for any invalid input

=item Comments:

 Again, the month and day-of-month fields in the input parameters are COMPLETELY ignored.

=item Examples:

 # Returns '0',   The years in both dates, 9/23/1967 and 4/7/1967, are the same
 compare_year1_and_year2('9/23/1967',  '4/7/1967');

 # Returns '1',   Year 2004 is greater than year 2003
 compare_year1_and_year2('1/7/2004',   '12/19/2003');

 # Returns '-1',  Year 1387 is less than year 1555
 compare_year1_and_year2('Fri May 18 08:50:51 1387',  'Wed Feb 23 08:50:51 1555');

=back








=item B<year1_to_year2_delta>

=over 8

=item Usage:

 my $years_difference = year1_to_year2_delta( $date_1, date_2 );

=item Purpose:

 Calculates the difference in WHOLE years between two dates (basically it
 truncates the date difference to whole years)

=item Returns:

 Integer year difference

=item Parameter(s):

 - Date string one in any format
 - Date string two in any format

=item Throws:

 Throws exception for any invalid input

=item Comments:

 - Difference is positive if date1 > date2
 - Difference is negative if date1 < date2

=item Examples:

 year1_to_year2_delta('12/25/2007', '4/11/2002'); # Returns 5
 year1_to_year2_delta('6/07/1999',  '6/06/1998'); # Returns 1
 year1_to_year2_delta('2/28/1992',  '2/28/1996'); # Returns -4
 year1_to_year2_delta('2/29/1992',  '2/28/1996'); # Returns -3

=back








=item B<date_offset_in_years>

=over 8

=item Usage:

 my $offset_date = date_offset_in_years( $date, $num_years );

=item Purpose:

 Find a date in the future or past offset by the number of YEARS from the given date

=item Returns:

 Date offset by the number of years

=item Parameter(s):

 - Date string in any format
 - Integer number of years, positive or negative

=item Throws:

 Throws exception for any invalid input

=item Comments:

 There are two exceptions where the new month/dayofmonth do NOT match the original
   - Feb 29 in a leap year maps to Feb 28 in a NON leap year
   - Feb 28 in a NON leap year maps to Feb 29 in a leap year

=item Examples:

 date_offset_in_years('1/4/1841', -2003); # returns  '01/04/-162'

 - Case where leap year day maps to non leap year
 date_offset_in_years('2/29/1604', 107); # returns  '02/28/1711'
 date_offset_in_years('2/29/2096', -53); # returns  '02/28/2043'
 date_offset_in_years('2/29/-8',     0); # returns  '02/29/-8'

 - Case where NON leap year day maps to leap year
 date_offset_in_years('2/28/1781', 443); # returns  '02/29/2224'
 date_offset_in_years('2/28/1919', -91); # returns  '02/29/1828'
 date_offset_in_years('2/28/-77',  173); # returns  '02/29/96'

=back








=item B<number_of_weekdays_in_range>

=over 8

=item Usage:

 my $num_weekdays = number_of_weekdays_in_range( $date_1, date_2 );

=item Purpose:

  Calculates the number of weekdays in the range of the two dates

=item Returns:

 Number of weekdays the range

=item Parameter(s):

 - Date string one in any format
 - Date string two in any format

=item Throws:

 Throws exception for any invalid input

=item Comments:

 - Difference is positive if date1 > date2
 - Difference is negative if date1 < date2
 - Friday to Saturday counts as ZERO days
 - Friday to Sunday   counts as ZERO days
 - Friday to Monday   counts as one  day
 - Tuesday to previous Wednesday counts as NEGATIVE four days

=item Examples:

 number_of_weekdays_in_range('10/22/2007', '10/31/2007'); # Returns -7
 number_of_weekdays_in_range('1/1/-399',   '12/31/-400'); # Returns 1

=back








=item B<is_leap_year>

=over 8

=item Usage:

 my $status = is_leap_year( $year );

=item Purpose:

 Determine if year is a leap year or not

=item Returns:

 - '1' if leap year
 - ''  if NON leap year

=item Parameter(s):

 Year

=item Throws:

 Throws exception for any invalid input

=item Comments:

 Handles all years, even negative years (aka BC)

=item Examples:

 is_leap_year(1900);  # Returns    ''
 is_leap_year(2099);  # Returns    ''
 is_leap_year(  -4);  # Returns 'yes'
 is_leap_year(2004);  # Returns 'yes'

=back








=item B<get_year_phase>

=over 8

=item Usage:

 my $year_phase = get_year_phase( $year );

=item Purpose:

 Get the phase (0-399) of the current year within the standard 400 year cycle

=item Returns:

 Year phase (0-399) for the given year

=item Parameter(s):

 Year

=item Throws:

 Throws exception for any invalid input

=item Comments:

 - Handles all years, even negative years (aka BC)
 - years repeat in a standard 400 year cycle where year 2000 is defined by
   this program to be phase '0' and year 2399 is then phase '399'

=item Examples:

 get_year_phase(1900);  # Returns  300
 get_year_phase(2000);  # Returns    0
 get_year_phase(2001);  # Returns    1
 get_year_phase(  -3);  # Returns  397
 get_year_phase(1999);  # Returns  399

=back








=item B<number_of_day_within_year>

=over 8

=item Usage:

 my $day_number = number_of_day_within_year( $date_string );

=item Purpose:

 Get the day number within the year

=item Returns:

 Day number within year

=item Parameter(s):

 Date string which will be parsed

=item Throws:

 Throws exception for any invalid input

=item Comments:

 Jan 31 ALWAYS returns '31' and Dec 31 returns either '365' or '366' depending upon leap year

=item Examples:

 number_of_day_within_year('3/1/0');      # Returns    61
 number_of_day_within_year('1/1/2000');   # Returns     1
 number_of_day_within_year('12/31/2000'); # Returns   366
 number_of_day_within_year('1/28/2007');  # Returns    28
 number_of_day_within_year('3/1/2007');   # Returns    60

=back








=item B<day_number_within_year_to_date>

=over 8

=item Usage:

 my $date = day_number_within_year_to_date( $year, $day_number );

=item Purpose:

 Converts the number of the day within the year to a date

=item Returns:

 Date

=item Parameter(s):

 - Year
 - Number of day in year <1-365/6>

=item Throws:

 Throws exception for any invalid input

=item Comments:

 Handles all years, even negative years (aka BC)

=item Examples:

 day_number_within_year_to_date(2001, 151); # Returns  5/31/2001
 day_number_within_year_to_date(1443,  60); # Returns   3/1/1443
 day_number_within_year_to_date(  -4, 244); # Returns    8/31/-4
 day_number_within_year_to_date(   0, 306); # Returns     11/1/0

=back








=item B<day_number_within_400_year_cycle_to_date>

=over 8

=item Usage:

 my $date = day_number_within_400_year_cycle_to_date( $year_400_cycle, $number_of_day );

=item Purpose:

 Converts the number of the day within the standard 400 year cycle to a date

=item Returns:

 Date

=item Parameter(s):

 - 400 year cycle, (i.e.  ... -400, 0, 400, ... 1600, 2000, 2400, ...)
 - number of day in the standard 400 year cycle <1-146097>

=item Throws:

 Throws exception for any invalid input

=item Comments:

 - Handles all years, even negative years (aka BC)
 - Years repeat in a standard 400 year cycle where year 2000 is defined by
   this program to be phase '0' and year 2399 is then phase '399'

=item Examples:

 day_number_within_400_year_cycle_to_date(2000, 146097); # Returns  12/31/2399
 day_number_within_400_year_cycle_to_date(2000,      1); # Returns    1/1/2000
 day_number_within_400_year_cycle_to_date(   0,      1); # Returns       1/1/0
 day_number_within_400_year_cycle_to_date(-400, 146097); # Returns    12/31/-1
 day_number_within_400_year_cycle_to_date(2000,  36527); # Returns    1/2/2100
 day_number_within_400_year_cycle_to_date(1600, 130416); # Returns   1/24/1957

=back








=item B<get_number_of_day_within_400yr_cycle>

=over 8

=item Usage:

 my $day_number = get_number_of_day_within_400yr_cycle( $month, $dayofmonth, $year );

=item Purpose:

 Get the number of the day within the standard 400 year cycle

=item Returns:

 Day number within the standard 400 year cycle

=item Parameter(s):

 - Month in one of three formats ( numeric <1-12>, full name or three character abbreviated )
 - Day of month (1-31)
 - Year

=item Throws:

 Throws exception for any invalid input

=item Comments:

 - Handles all years, even negative years (aka BC)
 - Years repeat in a standard 400 year cycle where year 2000 is defined by
   this program to be phase '0' and year 2399 is then phase '399'.
 - This would be a very LARGE integer for the 1990's
 - Jan 1, 2000 would return '1'

=item Examples:

 get_number_of_day_within_400yr_cycle( 2,    1, 2000); # Returns        32
 get_number_of_day_within_400yr_cycle( 1,    1,    0); # Returns         1
 get_number_of_day_within_400yr_cycle(12,   31, -201); # Returns     73049
 get_number_of_day_within_400yr_cycle('Feb', 1, 1999); # Returns    145764

=back








=item B<get_days_remaining_in_400yr_cycle>

=over 8

=item Usage:

 my $num_days = get_days_remaining_in_400yr_cycle( $month, $dayofmonth, $year );

=item Purpose:

 Get the number of days remaining from the given date to the end of
 the current standard 400 year cycle

=item Returns:

 Number of days remaining in 400 year cycle

=item Parameter(s):

 - Month in one of three formats ( numeric <1-12>, full name or three character abbreviated )
 - Day of month (1-31)
 - Year

=item Throws:

 Throws exception for any invalid input

=item Comments:

 - Handles all years, even negative years (aka BC)
 - Years repeat in a standard 400 year cycle where year 2000 is defined by
   this program to be phase '0' and year 2399 is then phase '399'
 - This would be a very SMALL integer for the 1990's
 - Jan 1, 2000 would return '146096'.  There are a total of 146,097 days in
   the standard 400 year cycle.

=item Examples:

 get_days_remaining_in_400yr_cycle('Jan',  1, -400); # Returns  146096
 get_days_remaining_in_400yr_cycle(12,    31, -401); # Returns       0
 get_days_remaining_in_400yr_cycle(12,    30, 1999); # Returns       1
 get_days_remaining_in_400yr_cycle(1,      1, 2000); # Returns  146096
 get_days_remaining_in_400yr_cycle('May',  1, 2100); # Returns  109451

=back








=item B<get_num_days_in_year>

=over 8

=item Usage:

 my $num_days_in_year = get_num_days_in_year( $year );

=item Purpose:

 Get number of days in given year

=item Returns:

 Number of days in given year

=item Parameter(s):

 Year

=item Throws:

 Throws exception for any invalid input

=item Comments:

 Handles all years, even negative years (aka BC)

=item Examples:

 get_num_days_in_year(  -5); # Returns 365
 get_num_days_in_year( 300); # Returns 365
 get_num_days_in_year(1904); # Returns 366
 get_num_days_in_year(2301); # Returns 365

=back








=item B<get_days_remaining_in_year>

=over 8

=item Usage:

 my $num_days = get_days_remaining_in_year( $month, $dayofmonth, $year );

=item Purpose:

 Get the number of days remaining in the year from the given date

=item Returns:

 Number of days remaining in year

=item Parameter(s):

 - Month in one of three formats ( numeric <1-12>, full name or three character abbreviated )
 - Day of month (1-31)
 - Year

=item Throws:

 Throws exception for any invalid input

=item Comments:

 - Handles all years, even negative years (aka BC)
 - if the last day of the year is given, 0 is returned
 - <1 for Jan ... 12 for Dec>
 - <1 for Mon ... 7 for Sun>

=item Examples:

 get_days_remaining_in_year(12,         31,  -88); # Returns    0
 get_days_remaining_in_year('Sep',       2, 1401); # Returns  120
 get_days_remaining_in_year('February',  7, 1865); # Returns  327

=back








=item B<get_numeric_day_of_week>

=over 8

=item Usage:

 Function is overloaded to accept one of two date input types
 1) Date string
     my $day_of_week = get_numeric_day_of_week( SCALAR );
 2) Month, dayofmonth, year
     my $day_of_week = get_numeric_day_of_week( SCALAR, SCALAR, SCALAR );

=item Purpose:

 Get numeric day of week (1-7) for given date

=item Returns:

 Numeric day of week

=item Parameter(s):

 - ( date string in any format )
           OR
 - ( month, day of month, year )

=item Throws:

 Throws exception for any invalid input

=item Comments:

 - Handles all years, even negative years (aka BC)
 - <1 for Jan ... 12 for Dec>
 - <1 for Mon ... 7 for Sun>

=item Examples:

 get_numeric_day_of_week(    2,     29, -2000); # Returns 2
 get_numeric_day_of_week('Dec',     31,  1795); # Returns 4
 get_numeric_day_of_week('January',  1,  2000); # Returns 6
 get_numeric_day_of_week('Sep  23, 1541');      # Returns 2
 get_numeric_day_of_week('June  6, 2001');      # Returns 3

=back








=item B<get_month_from_string>

=over 8

=item Usage:

 my $month_number = get_month_from_string( SCALAR );

=item Purpose:

 Extract month from given date string

=item Returns:

 Month number

=item Parameter(s):

 Date string in any format

=item Throws:

 Throws exception for any invalid input

=item Comments:

 - Handles all years, even negative years (aka BC)
 - <1 for Jan ... 12 for Dec>

=item Examples:

 get_month_from_string('12/31/1795');               # Returns  12
 get_month_from_string('Sat Oct 22 08:50:51 1577'); # Returns  10
 get_month_from_string('June  6, 2001');            # Returns   6
 get_month_from_string('February  28, 1995');       # Returns   2
 get_month_from_string('-1755-08-15');              # Returns   8
 get_month_from_string('19 May, 227');              # Returns   5

=back








=item B<get_dayofmonth_from_string>

=over 8

=item Usage:

 my $day_of_month = get_dayofmonth_from_string( SCALAR );

=item Purpose:

 Extract day of month from given date string

=item Returns:

 Day of month

=item Parameter(s):

 Date string in any format

=item Throws:

 Throws exception for any invalid input

=item Comments:

 - Handles all years, even negative years (aka BC)

=item Examples:

 get_dayofmonth_from_string('12/31/1795');               # Returns  31
 get_dayofmonth_from_string('Sat Oct 22 08:50:51 1577'); # Returns  22
 get_dayofmonth_from_string('June  6, 2001');            # Returns   6
 get_dayofmonth_from_string('February  28, 1995');       # Returns  28
 get_dayofmonth_from_string('-1755-08-15');              # Returns  15
 get_dayofmonth_from_string('19 May, 227');              # Returns  19

=back








=item B<get_year_from_string>

=over 8

=item Usage:

 my $year = get_year_from_string( SCALAR );

=item Purpose:

 Extract year from given date string

=item Returns:

 Year

=item Parameter(s):

 Date string in any format

=item Throws:

 Throws exception for any invalid input

=item Comments:

 - Handles all years, even negative years (aka BC)

=item Examples:

 get_year_from_string('Sat Oct 22 08:50:51 1577'); # Returns  1577
 get_year_from_string('June  6, 2001');            # Returns  2001
 get_year_from_string('February  28, 1995');       # Returns  1995
 get_year_from_string('-1755-08-15');              # Returns -1755
 get_year_from_string('19 May, 227');              # Returns   227
 get_year_from_string('04/27/0');                  # Returns     0

=back








=item B<get_number_of_days_in_month>

=over 8

=item Usage:

 my $num_days = get_number_of_days_in_month( $month, $year );

=item Purpose:

 Get the number of days in a specific month

=item Returns:

 Number of days

=item Parameter(s):

 - Month in one of three formats ( numeric <1-12>, full name or three character abbreviated )
 - Year

=item Throws:

 Throws exception for any invalid input

=item Comments:

 Handles all years, even negative years (aka BC)

=item Examples:

 get_number_of_days_in_month('Apr',1996); # Returns 30
 get_number_of_days_in_month('1',  1011); # Returns 31

=back








=item B<get_days_remaining_in_month>

=over 8

=item Usage:

 my $num_days = get_days_remaining_in_month( $month, $dayofmonth, $year );

=item Purpose:

 Find out how many days are remaining in the month from the given date

=item Returns:

 Number of days left in month

=item Parameter(s):

 - Month in one of three formats ( numeric <1-12>, full name or three character abbreviated )
 - Day of month (1-31)
 - Year

=item Throws:

 Throws exception for any invalid input

=item Comments:

 - Handles all years, even negative years (aka BC)
 - If the last day of the month is given, 0 is returned

=item Examples:

 get_days_remaining_in_month(12,   31,  -88); # Returns  0
 get_days_remaining_in_month('Sep', 2, 1401); # Returns 28

=back








=item B<get_first_of_month_day_of_week>

=over 8

=item Usage:

 my $dayofweek = get_first_of_month_day_of_week( $month, $year );

=item Purpose:

 Get the day of the week for the first of the month for a specified month/year combination

=item Returns:

 Day of week in numeric format

=item Parameter(s):

 - Month in one of three formats ( numeric <1-12>, full name or three character abbreviated )
 - Year

=item Throws:

 Throws exception for any invalid input

=item Comments:

 1 for Mon, ..., 7 for Sun

=item Examples:

 get_first_of_month_day_of_week('Feb',1996); # Returns 4
 get_first_of_month_day_of_week('2',   -57); # Returns 1

=back








=item B<calculate_day_of_week_for_first_of_month_in_next_year>

=over 8

=item Usage:

 my $dayofweek = calculate_day_of_week_for_first_of_month_in_next_year( $number_of_days_in_year_offset, $day_of_week_this_month );

=item Purpose:

 Calculates the day of the week on the first of the month twelve months from the current month

=item Returns:

 The day of week on the first of the month one year from current month if successful.

=item Parameter(s):

 - Number of days from the first of the current month to the first of the month one year ahead

 - Day of the week for the first of the current month

=item Throws:

 Throws exception for any invalid input

=item Examples:

 # Returns '5' representing Friday, where leap year (Feb 29) is in the range

 my $dayofweek_0 = (calculate_day_of_week_for_first_of_month_in_next_year(366, 3);

 # Returns '2' representing Tuesday, where NO leap year is in the range

 my $dayofweek_1 = (calculate_day_of_week_for_first_of_month_in_next_year(365, 'Monday');

=back








=item B<get_global_year_cycle>

=over 8

=item Usage:

 my $cycle_year = get_global_year_cycle( $year );

=item Purpose:

 Get the phase zero year for the given year.

=item Returns:

 The phase zero year containing the given year if successful.

=item Parameter(s):

 Integer representing year, positive or negative

=item Throws:

 Throws exception for any invalid input

=item Comments:

 - Handles all years, even negative years (aka BC)
 - Years repeat in a standard 400 year cycle.  This function
   truncates the incoming year to the nearest multiple of 400 which
   is defined by this program to be phase '0' of the 400 year cycle.
   Thus, all values returned by this function are multiples of 400.

=item Examples:

 get_global_year_cycle( -17); # returns   -400
 get_global_year_cycle(-801); # returns  -1200
 get_global_year_cycle(   1); # returns      0
 get_global_year_cycle(1899); # returns   1600
 get_global_year_cycle(1999); # returns   1600
 get_global_year_cycle(2000); # returns   2000
 get_global_year_cycle(2001); # returns   2000

=back








=back



=head1 DIAGNOSTICS

All functions comprehensively test input parameters BEFORE proceeding.
Functions of the C<is_valid_> type generally return an empty string, C<''>, for
invalid.  Other functions first trap errors due to invalid input, report the
problem and then stop running.

A comprehensive set of tests is included in the distribution.  C<Devel::Cover>
was used to achieve near complete code coverage.  The only code not covered by
the tests, by design, are several else statements to trap unexpected else
conditions.  Use the standard C<make test> to run.


=head1 DEPENDENCIES

   warnings              1.05
   version               0.74
   Carp                  1.04
   Readonly              1.03
   Readonly::XS          1.04
   Test::More            0.74
   Test::Manifest        1.22
   Test::Pod             1.26
   Test::Pod::Coverage   1.08




=head1 BUGS AND LIMITATIONS

All years, positive (AD) and negative (BC) are acceptable up to the integer
size on the host system.  However, this range is B<NOT> historically accurate
before 1582AD.  Thus, even though one can find the day of the week, for example
May 17, -273BC, by projecting backwards from today's standard, the date
is B<NOT> historically valid.  Refer to the the Date::Calc module for further
explanation.

Date strings with truncated years such as '04' for '2004' will B<NOT> parse
correctly.

Note the correct fields within date strings of the various formats.
For example, the date string '4/8/2005' is interpreted as
'April 8, 2005', B<NOT> 'August 4, 2005'.

Startup is slow due to the one-time creation of a small hash table to speed up
subsequent look-ups.

=head1 SEE ALSO

B<Date::Calc>,
B<Date::Simple>,
B<Date::Manip>,
B<Class::Date>

For many others search for B<date> in CPAN


=head1 AUTHOR

David McAllister, E<lt>perldave@gmail.comE<gt>




=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by David McAllister

Date::Components version 0.2.1 

This program is free (or copyleft) software: you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License,
or (at your option) any later version.  This software may be used in any
state or jurisdiction which does not prohibit the limitation or exclusion of
liability for loss or damage caused by negligence, breach of contract or
breach of implied terms, or incidental or consequential damages.




=head1 DISCLAIMER OF WARRANTY

This Program of Date::Components is distributed in the hope that it will be
useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.  You should have received a copy of the GNU
General Public License along with this program.
If not, see http://www.gnu.org/licenses/.




=head1 DISCLAIMER OF LIABILITY

THIS PROGRAM AND SOFTWARE IS PROVIDED TO YOU FOR FREE AND ON AN "AS IS" AND
"WITH ALL FAULTS" BASIS.  YOU EXPRESSLY UNDERSTAND AND AGREE THAT THE AUTHOR OF
THIS PROGRAM AND SOFTWARE (AND ANY VERSION THEREOF) SHALL NOT BE LIABLE TO YOU
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL OR EXEMPLARY
DAMAGES, INCLUDING BUT NOT LIMITED TO, DAMAGES FOR LOSS OF PROFITS, GOODWILL,
USE, DATA OR OTHER INTANGIBLE LOSSES (EVEN IF THE AUTHOR HAS BEEN ADVISED OF
THE POSSIBILITY OF SUCH DAMAGES) RESULTING FROM: (I) THE USE OR THE INABILITY
TO USE THE PROGRAM OR SOFTWARE; (II) THE INABILITY TO USE THE PROGRAM OR
SOFTWARE TO ACCESS CONTENT OR DATA; (III) THE COST OF PROCUREMENT OF SUBSTITUTE
GOODS OR SERVICES; (IV) UNAUTHORIZED ACCESS TO OR ALTERATION OF YOUR
TRANSMISSIONS OR DATA; OR (V) ANY OTHER MATTER RELATING TO THE PROGRAM OR
SOFTWARE.  THE FOREGOING LIMITATIONS SHALL APPLY NOTWITHSTANDING A FAILURE OF
ESSENTIAL PURPOSE OF ANY LIMITED REMEDY AND TO THE FULLEST EXTENT PERMITTED BY
LAW.

NOTHING IN THIS AGREEMENT IS INTENDED TO EXCLUDE OR LIMIT ANY CONDITION,
WARRANTY, RIGHT OR LIABILITY WHICH MAY NOT BE LAWFULLY EXCLUDED OR LIMITED.
SOME JURISDICTIONS DO NOT ALLOW THE EXCLUSION OF CERTAIN WARRANTIES OR
CONDITIONS OR THE LIMITATION OR EXCLUSION OF LIABILITY FOR LOSS OR DAMAGE
CAUSED BY NEGLIGENCE, BREACH OF CONTRACT OR BREACH OF IMPLIED TERMS, OR
INCIDENTAL OR CONSEQUENTIAL DAMAGES.  ACCORDINGLY, ONLY THE ABOVE LIMITATIONS
IN THAT ARE LAWFUL IN YOUR JURISDICTION WILL APPLY TO YOU AND THE AUTHOR'S
LIABILITY WILL BE LIMITED TO THE MAXIMUM EXTENT PERMITTED BY LAW.




=head1 LIMITATION OF LIABILITY

Notwithstanding any damages that you might incur for any reason whatsoever
(including, without limitation, all damages referenced above and all direct or
general damages), your sole and entire remedy for any defect, damage or loss
arising from a failure of the Program and Software to perform is to stop using
it.  The foregoing limitations, exclusions, and disclaimers shall apply to the
maximum extent permitted by applicable law, even if any remedy fails its
essential purpose.




=head1 ACKNOWLEDGMENTS

This module is only possible due to the many countless and selfless people in
the PERL community who have created a robust and thorough foundation to enable
smooth module development.

In particular, the Date::Calc routine was used to validate the leap year
exceptions of century years which are not a multiple of 400.


=cut
