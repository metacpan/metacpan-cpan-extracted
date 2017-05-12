package Apache::ASP::Date;

# This package code was taken from HTTP::Date, written by Gisle Aas
# Copyright 1995-1997, Gisle Aas
# This library is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require 5.002;
require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(time2str str2time);
@EXPORT_OK = qw(time2iso time2isoz);

use Time::Local ();

use strict;
use vars qw(@DoW @MoY %MoY);

#@DoW = qw(Sunday Monday Tuesday Wednesday Thursday Friday Saturday);
@DoW = qw(Sun Mon Tue Wed Thu Fri Sat);
@MoY = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
# Build %MoY hash
my $i = 0;
foreach(@MoY) {
   $MoY{lc $_} = $i++;
}

my($current_month, $current_year) = (localtime)[4, 5];


sub time2str (;$)
{
   my $time = shift;
   $time = time unless defined $time;
   my ($sec, $min, $hour, $mday, $mon, $year, $wday) = gmtime($time);
   sprintf("%s, %02d %s %04d %02d:%02d:%02d GMT",
	   $DoW[$wday],
	   $mday, $MoY[$mon], $year+1900,
	   $hour, $min, $sec);
}



sub str2time ($;$)
{
   local($_) = shift;
   return undef unless defined;
   my($default_zone) = @_;

   # Remove useless weekday, if it exists
   s/^\s*(?:sun|mon|tue|wed|thu|fri|sat)\w*,?\s*//i;

   my($day, $mon, $yr, $hr, $min, $sec, $tz, $aorp);
   my $offset = 0;  # used when compensating for timezone

 PARSEDATE: {
      # Then we are able to check for most of the formats with this regexp
      ($day,$mon,$yr,$hr,$min,$sec,$tz) =
	/^\s*
	 (\d\d?)               # day
	    (?:\s+|[-\/])
	 (\w+)                 # month
	    (?:\s+|[-\/])
	 (\d+)                 # year
	 (?:
	       (?:\s+|:)       # separator before clock
	    (\d\d?):(\d\d)     # hour:min
	    (?::(\d\d))?       # optional seconds
	 )?                    # optional clock
	    \s*
	 ([-+]?\d{2,4}|GMT|gmt)? # timezone
	    \s*$
	/x
	  and last PARSEDATE;

      # Try the ctime and asctime format
      ($mon, $day, $hr, $min, $sec, $tz, $yr) =
	/^\s*                  # allow intial whitespace
	 (\w{1,3})             # month
	    \s+
	 (\d\d?)               # day
	    \s+
	 (\d\d?):(\d\d)        # hour:min
	 (?::(\d\d))?          # optional seconds
	    \s+
	 (?:(GMT|gmt)\s+)?     # optional GMT timezone
	 (\d+)                 # year
	    \s*$               # allow trailing whitespace
	/x
	  and last PARSEDATE;

      # Then the Unix 'ls -l' date format
      ($mon, $day, $yr, $hr, $min, $sec) =
	/^\s*
	 (\w{3})               # month
	    \s+
	 (\d\d?)               # day
	    \s+
	 (?:
	    (\d\d\d\d) |       # year
	    (\d{1,2}):(\d{2})  # hour:min
            (?::(\d\d))?       # optional seconds
	 )
	 \s*$
       /x
	 and last PARSEDATE;

      # ISO 8601 format '1996-02-29 12:00:00 -0100' and variants
      ($yr, $mon, $day, $hr, $min, $sec, $tz) =
	/^\s*
	  (\d{4})              # year
	     [-\/]?
	  (\d\d?)              # numerical month
	     [-\/]?
	  (\d\d?)              # day
	 (?:
	       (?:\s+|:|T|-)   # separator before clock
	    (\d\d?):?(\d\d)    # hour:min
	    (?::?(\d\d))?      # optional seconds
	 )?                    # optional clock
	    \s*
	 ([-+]?\d\d?:?(:?\d\d)?
	  |Z|z)?               # timezone  (Z is "zero meridian", i.e. GMT)
	    \s*$
	/x
	  and last PARSEDATE;

      # Windows 'dir' 11-12-96  03:52PM
      ($mon, $day, $yr, $hr, $min, $aorp) =
        /^\s*
          (\d{2})                # numerical month
             -
          (\d{2})                # day
             -
          (\d{2})                # year
             \s+
          (\d\d?):(\d\d)([apAP][mM])  # hour:min AM or PM
             \s*$
        /x
          and last PARSEDATE;

      # If it is not recognized by now we give up
      return undef;
   }

   # Translate month name to number
   if ($mon =~ /^\d+$/) {
     # numeric month
     return undef if $mon < 1 || $mon > 12;
     $mon--;
   } else {
     $mon = lc $mon;
     return undef unless exists $MoY{$mon};
     $mon = $MoY{$mon};
   }

   # If the year is missing, we assume some date before the current,
   # because these date are mostly present on "ls -l" listings.
   unless (defined $yr) {
	$yr = $current_year;
	$yr-- if $mon > $current_month;
    }

   # Then we check if the year is acceptable
   return undef if $yr > 99 && $yr < 1900;  # We ignore these years
   $yr += 100 if $yr < 50;  # a stupid thing to do???
   $yr -= 1900 if $yr >= 1900;
   # The $yr is now relative to 1900 (as expected by timelocal())

   # timelocal() seems to go into an infinite loop if it is given out
   # of range parameters.  Let's check the year at least.

   # Epoch counter maxes out in year 2038, assuming "time_t" is 32 bit
   return undef if $yr > 138;
   return undef if $yr <  70;  # 1970 is Unix epoch

   # Compensate for AM/PM
   if ($aorp) {
       $aorp = uc $aorp;
       $hr = 0 if $hr == 12 && $aorp eq 'AM';
       $hr += 12 if $aorp eq 'PM' && $hr != 12;
   }

   # Make sure things are defined
   for ($sec, $min, $hr) {  $_ = 0 unless defined   }

   # Should we compensate for the timezone?
   $tz = $default_zone unless defined $tz;
   return eval {Time::Local::timelocal($sec, $min, $hr, $day, $mon, $yr)}
     unless defined $tz;

   # We can calculate offset for numerical time zones
   if ($tz =~ /^([-+])?(\d\d?):?(\d\d)?$/) {
       $offset = 3600 * $2;
       $offset += 60 * $3 if $3;
       $offset *= -1 if $1 && $1 ne '-';
   }
   eval{Time::Local::timegm($sec, $min, $hr, $day, $mon, $yr) + $offset};
}



# And then some bloat because I happen to like the ISO 8601 time
# format.

sub time2iso (;$)
{
   my $time = shift;
   $time = time unless defined $time;
   my($sec,$min,$hour,$mday,$mon,$year) = localtime($time);
   sprintf("%04d-%02d-%02d %02d:%02d:%02d",
	   $year+1900, $mon+1, $mday, $hour, $min, $sec);
}


sub time2isoz (;$)
{
    my $time = shift;
    $time = time unless defined $time;
    my($sec,$min,$hour,$mday,$mon,$year) = gmtime($time);
    sprintf("%04d-%02d-%02d %02d:%02d:%02dZ",
            $year+1900, $mon+1, $mday, $hour, $min, $sec);
}

1;
