##############################################################################
#
#  Data::Tools perl module
#  2013-2018 (c) Vladi Belperchinov-Shabanski "Cade"
#  http://cade.datamax.bg
#  <cade@bis.bg> <cade@biscom.net> <cade@datamax.bg> <cade@cpan.org>
#
#  GPL
#
##############################################################################
package Data::Tools::Time;
use strict;
use Exporter;
use Carp;
use Data::Tools;

our $VERSION = '1.19';

our @ISA    = qw( Exporter );
our @EXPORT = qw(

                unix_time_diff_in_words
                unix_time_diff_in_words_relative
    
                julian_date_diff_in_words
                julian_date_diff_in_words_relative

                );

our %EXPORT_TAGS = (
                   
                   'all'  => \@EXPORT,
                   'none' => [],
                   
                   );

##############################################################################

sub unix_time_diff_in_words
{
  my $utd = abs( int( shift() ) ); # absolute difference in seconds

  if( $utd < 1 )
    {
    return "now";
    }
  if( $utd < 60   ) # less than 1 minute
    {
    my $ss = str_countable( $utd, "second", "seconds" );
    return "$utd $ss";
    };
  if( $utd < 60*60 ) # less than 1 hour
    {
    my $m  = int( $utd / 60 );
    my $ms = str_countable( $m, "minute", "minutes" );
    return "$m $ms";
    };
  if( $utd < 2*24*60*60 ) # less than 2 days (48 hours)
    {
    my $h = int( $utd / ( 60 * 60 ) );
    my $m = int( $utd % ( 60 * 60 ) / 60 );
    my $hs = str_countable( $h, "hour",   "hours"   );
    my $ms = str_countable( $m, "minute", "minutes" );
    return "$h $hs, $m $ms";
    };
  if( $utd < 7*24*60*60 ) # less than 1 week (168 hours)
    {
    my $d  = int( $utd / ( 24 * 60 * 60 ) );
    my $h  = int( $utd % ( 24 * 60 * 60 ) / ( 60 * 60 ) );
    my $ds = str_countable( $d, "day",    "days"    );
    my $hs = str_countable( $h, "hour",   "hours"   );
    return "$d $ds, $h $hs";
    };
  if( $utd < 60*24*60*60 ) # less than 2 months
    {
    my $d  = int( $utd / ( 24 * 60 * 60 ) );
    my $ds = str_countable( $d, "day",    "days"    );
    return "$d $ds";
    };
  if( 42 ) # more than 2 months
    {
    my $m  = int( $utd / ( 30*24*60*60 ) ); # "month" is approximated to 30 days
    my $ms = str_countable( $m, "month", "months" );
    return "$m $ms";
    }
}

sub unix_time_diff_in_words_relative
{
  my $utd = int( shift() ); # relative difference in seconds

  my $uts = unix_time_diff_in_words( $utd );

  if( $utd < 0 )
    {
    return "in $uts";
    }
  elsif( $utd > 0 )
    {
    return "before $uts";
    }
  else
    {
    return $uts;
    }
}

##############################################################################

sub julian_date_diff_in_words
{
  my $jdd  = abs( int( shift() ) ); # absolute difference in days

  if( $jdd < 90 )
    {
    my $d  = int( $jdd );
    my $ds = str_countable( $d, "day", "days" );
    return "$d $ds";
    }
  if( 42 )
    {
    my $m  = int( $jdd / 30 );
    my $ms = str_countable( $m, "month", "months" );
    return "$m $ms";
    };
}

sub julian_date_diff_in_words_relative
{
  my $jdd = int( shift() ); # relative difference in days

  if( $jdd == 0 )
    {
    return "today";
    }
  if( $jdd == -1 )
    {
    return "tomorrow";
    }
  if( $jdd == +1 )
    {
    return "yesterday";
    }

  my $jds = julian_date_diff_in_words( $jdd );
  if( $jdd < 0 )
    {
    return "in $jds";
    }
  elsif( $jdd > 0 )
    {
    return "before $jds";
    }
  else
    {
    return $jds;
    }
}

##############################################################################

=pod


=head1 NAME

  Data::Tools::Time provides set of basic functions for time processing.

=head1 SYNOPSIS

  use Data::Tools::Time qw( :all );  # import all functions
  use Data::Tools::Time;             # the same as :all :) 
  use Data::Tools::Time qw( :none ); # do not import anything

  # --------------------------------------------------------------------------

  my $time_diff_str     = unix_time_diff_in_words( $time1 - $time2 );
  my $time_diff_str_rel = unix_time_diff_in_words_relative( $time1 - $time2 );

  # --------------------------------------------------------------------------
    
  my $date_diff_str     = julian_date_diff_in_words( $date1 - $date2 );
  my $date_diff_str_rel = julian_date_diff_in_words_relative( $date1 - $date2 );

  # --------------------------------------------------------------------------

=head1 FUNCTIONS

=head2 unix_time_diff_in_words( $unix_time_diff )

Returns human-friendly text for the given time difference (in seconds).
This function returns absolute difference text, for relative 
(before/after/ago/in) see unix_time_diff_in_words_relative().

=head2 unix_time_diff_in_words_relative( $unix_time_diff )

Same as unix_time_diff_in_words() but returns relative text
(i.e. with before/after/ago/in)

=head2 julian_date_diff_in_words( $julian_date_diff );

Returns human-friendly text for the given date difference (in days).
This function returns absolute difference text, for relative 
(before/after/ago/in) see julian_day_diff_in_words_relative().

=head2 julian_date_diff_in_words_relative( $julian_date_diff );

Same as julian_date_diff_in_words() but returns relative text
(i.e. with before/after/ago/in)

=head1 TODO

  * support for language-dependent wording (before/ago)
  * support for user-defined thresholds (48 hours, 2 months, etc.)

=head1 REQUIRED MODULES

Data::Tools::Time uses only:

  * Data::Tools (from the same package)

=head1 TEXT TRANSLATION NOTES

time/date difference wording functions does not have translation functions
and return only english text. This is intentional since the goal is to keep
the translation mess away but still allow simple (yet bit strange) 
way to translate the result strings with regexp and language hash:
  
  my $time_diff_str_rel = unix_time_diff_in_words_relative( $time1 - $time2 );
  
  my %TRANS = (
              'now'       => 'sega',
              'today'     => 'dnes',
              'tomorrow'  => 'utre',
              'yesterday' => 'vchera',
              'in'        => 'sled',
              'before'    => 'predi',
              'year'      => 'godina',
              'years'     => 'godini',
              'month'     => 'mesec',
              'months'    => 'meseca',
              'day'       => 'den',
              'days'      => 'dni',
              'hour'      => 'chas',
              'hours'     => 'chasa',
              'minute'    => 'minuta',
              'minutes'   => 'minuti',
              'second'    => 'sekunda',
              'seconds'   => 'sekundi',
              );
              
  $time_diff_str_rel =~ s/([a-z]+)/$TRANS{ lc $1 } || $1/ge;

I know this is no good for longer sentences but works fine in this case.

=head1 GITHUB REPOSITORY

  git@github.com:cade-vs/perl-data-tools.git
  
  git clone git://github.com/cade-vs/perl-data-tools.git
  
=head1 AUTHOR

  Vladi Belperchinov-Shabanski "Cade"

  <cade@bis.bg> <cade@biscom.net> <cade@datamax.bg> <cade@cpan.org>

  http://cade.datamax.bg


=cut

##############################################################################
1;
