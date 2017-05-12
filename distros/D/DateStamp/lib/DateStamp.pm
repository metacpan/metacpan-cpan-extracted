package DateStamp;

# | PACKAGE | DateStamp
# | AUTHOR  | Todd Wylie
# | EMAIL   | perldev@monkeybytes.org
# | ID      | $Id: DateStamp.pm 6 2006-01-13 23:00:39Z Todd Wylie $

use version; $VERSION = qv('1.0.4');
use warnings;
use strict;
use Carp;

# --------------------------------------------------------------------------
# N E W  (class CONSTRUCTOR)
# ==========================================================================
# USAGE      : DateStamp->new();
# PURPOSE    : constructor for DATE class
# RETURNS    : object handle
# PARAMETERS : none
# THROWS     : none
# COMMENTS   : Loads the date object with values from localtime function;
#            : does some cleaning-up of the values, too.
# SEE ALSO   : return_year
#            : return_month
#            : return_day
#            : return_time
#            : return_date
# --------------------------------------------------------------------------
sub new {
    my $class = shift;
    
    # Retrieve date & time from localtime function.
    my (
        $seconds,
        $minutes,
        $hour,
        $month_day,
        $month,
        $year,
        $week_day,
        $year_day,
        $daylight_savings_time,
        ) = localtime();

    # Convert time values to desired format.
    $year  += 1900;
    $month += 1;
    $hour      = $hour      =~ /[10-24]/ ? $hour      : '0' . $hour;
    $month     = $month     =~ /1[012]/  ? $month     : '0' . $month;
    $month_day = $month_day =~ /\d\d/    ? $month_day : '0' . $month_day;
    $seconds   = $seconds   =~ /\d\d/    ? $seconds   : '0' . $seconds;
    $minutes   = $minutes   =~ /\d\d/    ? $minutes   : '0' . $minutes;

    # Day, month, time lookup tables.
    my %day_alpha = (
                     '0' => 'Sunday',
                     '1' => 'Monday',
                     '2' => 'Tuesday',
                     '3' => 'Wednesday',
                     '4' => 'Thursday',
                     '5' => 'Friday',
                     '6' => 'Saturday',
                     );
    
    my %month_alpha = (
                       '01' => 'January',
                       '02' => 'February',
                       '03' => 'March',
                       '04' => 'April',
                       '05' => 'May',
                       '06' => 'June',
                       '07' => 'July',
                       '08' => 'August',
                       '09' => 'September',
                       '10' => 'October',
                       '11' => 'November',
                       '12' => 'December',
                       );
    
    my %time = (
                '01' => ['1',  'a.m.'],
                '02' => ['2',  'a.m.'],
                '03' => ['3',  'a.m.'],
                '04' => ['4',  'a.m.'],
                '05' => ['5',  'a.m.'],
                '06' => ['6',  'a.m.'],
                '07' => ['7',  'a.m.'],
                '08' => ['8',  'a.m.'],
                '09' => ['9',  'a.m.'],
                '10' => ['10', 'a.m.'],
                '11' => ['11', 'a.m.'],
                '12' => ['12', 'p.m.'],
                '13' => ['1',  'p.m.'],
                '14' => ['2',  'p.m.'],
                '15' => ['3',  'p.m.'],
                '16' => ['4',  'p.m.'],
                '17' => ['5',  'p.m.'],
                '18' => ['6',  'p.m.'],
                '19' => ['7',  'p.m.'],
                '20' => ['8',  'p.m.'],
                '21' => ['9',  'p.m.'],
                '22' => ['10', 'p.m.'],
                '23' => ['11', 'p.m.'],
                '24' => ['12', 'a.m.'],
                '00' => ['12', 'a.m.'],
                );
    
    # Abbreviate day/month.
    my $day_abbrev   = substr($day_alpha{$week_day}, 0,3);
    my $month_abbrev = substr($month_alpha{$month},  0,3);
    
    # Update the date object and return.
    my $self = {
        _seconds      => $seconds,
        _minutes      => $minutes,
        _hour         => $hour,
        _month_day    => $month_day,
        _month        => $month,
        _year         => $year,
        _week_day     => $week_day,
        _year_day     => $year_day,
        _day_alpha    => $day_alpha{$week_day},
        _day_abbrev   => $day_abbrev,
        _month_alpha  => $month_alpha{$month},
        _month_abbrev => $month_abbrev,
        _time_12      => [ $time{$hour}[0], $time{$hour}[1] ],
    };
    bless($self, $class);
    return($self);
}

# --------------------------------------------------------------------------
# R E T U R N   Y E A R  (method)
# ==========================================================================
# USAGE      : $date->return_year(length=>'long')
# PURPOSE    : Returns year of type '05' or '2005'.
# RETURNS    : Scalar.
# PARAMETERS : length=>'short'
#            : length=>'long'
# THROWS     : Croaks on bad/missing arguments.
# COMMENTS   : Only numeric format available.
# SEE ALSO   : n/a
# --------------------------------------------------------------------------
sub return_year {
    my ($class, %args) = @_;
    my $year;
    if ($args{length} eq "short") {
        $year = substr($class->{_year}, -2);
    }
    elsif ($args{length} eq "long") {
        $year = $class->{_year};
    }
    else {
        croak "DateStamp reports: Bad/missing \"length\" argument.\n";
    }
    return($year);
}

# --------------------------------------------------------------------------
# R E T U R N   M O N T H  (method)
# ==========================================================================
# USAGE      : $date->return_month(format=>'alpha', length=>'long')
# PURPOSE    : Returns month of type '10', 'Oct', 'October'.
# RETURNS    : Scalar.
# PARAMETERS : format=>'alpha'
#            : format=>'numeric'
#            : length=>'short'
#            : length=>'long'
# THROWS     : Croaks on bad/missing arguments.
# COMMENTS   : Alpha can return short/long format.
# SEE ALSO   : n/a
# --------------------------------------------------------------------------
sub return_month {
    my ($class, %args) = @_;
    my $month;
    if ($args{format} eq "alpha") {
        if ($args{length} eq "short") {
            $month = $class->{_month_abbrev};
        }
        elsif ($args{length} eq "long") {
            $month = $class->{_month_alpha};
        }
        else {
            croak "DateStamp reports: Bad/missing \"length\" argument.\n";
        }
    }
    elsif($args{format} eq "numeric") {
        $month = $class->{_month};
    }
    else {
        croak "DateStamp reports: Bad/missing \"format\" argument.\n";
    }
    return($month);
}

# --------------------------------------------------------------------------
# R E T U R N  D A Y  (method)
# ==========================================================================
# USAGE      : $date->return_day(format=>'alpha', length=>'long')
# PURPOSE    : Returns day of type 'Friday', 'Fri', '24'.
# RETURNS    : Scalar.
# PARAMETERS : format=>'alpha'
#            : format=>'numeric'
#            : length=>'short'
#            : length=>'long'
# THROWS     : Croaks on bad/missing arguments.
# COMMENTS   : Alpha can return short/long format.
# SEE ALSO   : n/a
# --------------------------------------------------------------------------
sub return_day {
    my ($class, %args) = @_;
    my $day;
    if ($args{format} eq "alpha") {
        if ($args{length} eq "short") {
            $day = $class->{_day_abbrev};
        }
        elsif ($args{length} eq "long") {
            $day = $class->{_day_alpha};
        }
        else {
            croak "DateStamp reports: Bad/missing \"length\" argument.\n";
        }
    }
    elsif($args{format} eq "numeric") {
        $day = $class->{_month_day};
    }
    else {
        croak "DateStamp reports: Bad/missing \"format\" argument.\n";
    }
    return($day);
}

# --------------------------------------------------------------------------
# R E T U R N  T I M E S T A M P  (method)
# ==========================================================================
# USAGE      : $date->return_time(format=>'12', length=>'short')
# PURPOSE    : Returns timestamp of types:
#            : 5:30 p.m.
#            : 5:30:20 p.m.
#            : 17:30
#            : 17:30:20
#            : Fri Nov 25 04:15:00 2005
# RETURNS    : Scalar.
# PARAMETERS : format=>'alpha'
#            : format=>'numeric'
#            : format=>'localtime'
#            : length=>'short'
#            : length=>'long'
# THROWS     : Croaks on bad/missing arguments.
# COMMENTS   : Converts from 12-hour to 24-hour format.
# SEE ALSO   : n/a
# --------------------------------------------------------------------------
sub return_time {
    my ($class, %args) = @_;
    my $timestamp;
    # Localtime format (Sun Nov 27 00:13:56 2005):
    if ($args{format} eq "localtime") {
        my $day   = $class->return_day( format=>'alpha', length=>'short' );
        my $month = $class->return_month( format=>'alpha', length=>'short' );
        my $mday  = $class->{_month_day};
        my $time  = $class->return_time( format=>'24', length=>'long' );
        my $year  = $class->{_year};
        my @timestamp = ($day, $month, $mday, $time, $year);
        $timestamp    = join(" ", @timestamp);
    }
    # 12 hour format (12:56 a.m. or 12:56:32 a.m.):
    elsif ($args{format} eq "12") {
        if ($args{length} eq "short") {
            $timestamp = ${$class->{_time_12}}[0] . ":" . $class->{_minutes} . " " . ${$class->{_time_12}}[1];
        }
        elsif ($args{length} eq "long") {
            $timestamp = ${$class->{_time_12}}[0] . ":" . $class->{_minutes} . ":" . $class->{_seconds} . " " . ${$class->{_time_12}}[1];
        }
        else {
            croak "DateStamp reports: Bad/missing \"length\" argument.\n";
        }
    }
    # 24 hour format (00:56 or 00:56:32):
    elsif ($args{format} eq "24") {
        if ($args{length} eq "short") {
            $timestamp = $class->{_hour} . ":" . $class->{_minutes};
        }
        elsif ($args{length} eq "long") {
            $timestamp = $class->{_hour} . ":" . $class->{_minutes} . ":" . $class->{_seconds};
        }
        else {
            croak "DateStamp reports: Bad/missing \"length\" argument.\n";
        }
    }
    else {
        croak "DateStamp reports: Bad/missing \"format\" argument.\n";
    }
    return($timestamp);
}

# --------------------------------------------------------------------------
# R E T U R N  D A T E  (method)
# ==========================================================================
# USAGE      : $date->return_date(format=>'mmddyyyy', glue=>'/')
# PURPOSE    : Returns various common date formats for user:
#            : 20050331 or 2005-03-31
#            : 03312005 or 03-31-2005
#            : March 31, 2005
#            : Mar 31, 2005
#            : Thursday, March 31, 2005
#            : March 31
#            : Mar 31
# RETURNS    : Scalar.
# PARAMETERS : format=>'yyyymmdd'
#            : format=>'mmddyyyy'
#            : format=>'month-day-year'
#            : format=>'mon-day-year'
#            : format=>'weekday-month-day-year'
#            : format=>'month-day'
#            : format=>'mon-day'
# THROWS     : Croaks on bad/missing arguments.
# COMMENTS   : The formats provided are not meant to be exhaustive. All of
#            : the provided formats were built using DateStamp methods. 
#            : Further formats are left as an exercise to the user.
# SEE ALSO   : return_year
#            : return_month
#            : return_day
#            : return_time
# --------------------------------------------------------------------------
sub return_date {
    my ($class, %args) = @_;
    my $date;

    # YYYYMMDD format (20050331 or 2005-03-31):
    if ($args{format} eq "yyyymmdd") {
        my $year  = $class->return_year(  length=>'long'    );
        my $month = $class->return_month( format=>'numeric' );
        my $day   = $class->return_day(   format=>'numeric' );
        if ($args{glue}) {
            my @dates = ($year, $month, $day);
            $date = join("$args{glue}", @dates);
        }
        else {
            $date = $year . $month . $day;
        }
    }

    # MMDDYYYY format (03312005 or 03-31-2005):
    elsif ($args{format} eq "mmddyyyy") {
        my $year  = $class->return_year(  length=>'long'    );
        my $month = $class->return_month( format=>'numeric' );
        my $day   = $class->return_day(   format=>'numeric' );
        if ($args{glue}) {
            my @dates = ($month, $day, $year);
            $date = join("$args{glue}", @dates);
        }
        else {
            $date = $month . $day . $year;
        }
    }
    
    # Month-day-year format (March 31, 2005):
    elsif ($args{format} eq "month-day-year") {
        my $month = $class->return_month( format=>'alpha', length=>'long' );
        my $day   = $class->return_day(   format=>'numeric'               );
        my $year  = $class->return_year(  length=>'long'                  );
        $date     = $month . " " . $day . ", " . $year;
    }
    
    # Mon-day-year format (Mar 31, 2005):
    elsif ($args{format} eq "mon-day-year") {
        my $month = $class->return_month( format=>'alpha', length=>'short' );
        my $day   = $class->return_day(   format=>'numeric'                );
        my $year  = $class->return_year(  length=>'long'                   );
        $date     = $month . " " . $day . ", " . $year;
    }
    
    # Weekday-month-day-year format (Thursday, March 31, 2005):
    elsif ($args{format} eq "weekday-month-day-year") {
        my $weekday =  $class->return_day(  format=>'alpha', length=>'long' );
        my $month   = $class->return_month( format=>'alpha', length=>'long' );
        my $day     = $class->return_day(   format=>'numeric'               );
        my $year    = $class->return_year(  length=>'long'                  );
        $date       = $weekday . ", " . $month . " " . $day . ", " . $year;
    }

    # Month-day format (March 31):
    elsif ($args{format} eq "month-day") {
        my $month = $class->return_month( format=>'alpha', length=>'long' );
        my $day   = $class->return_day(   format=>'numeric'               );
        $date     = $month . " " . $day;
    }
    
    # Mon-day format (Mar 31):
    elsif ($args{format} eq "mon-day") {
        my $month = $class->return_month( format=>'alpha', length=>'short' );
        my $day   = $class->return_day(   format=>'numeric'                );
        $date     = $month . " " . $day;
    }

    else {
        croak "DateStamp reports: Bad/missing \"format\" argument.\n";
    }
    return($date);
}

1; # End of module.

__END__


# --------------------------------------------------------------------------
# P O D : (area below reserved for documentation)  
# ==========================================================================


=head1 NAME

DateStamp - A simple OO interface to current system time and date.


=head1 VERSION

This document describes DateStamp version 1.0.4


=head1 SYNOPSIS

    use DateStamp;
    my $date_obj = DateStamp->new();
    my $year = $date_obj->return_year(length=>'long'); # $year = 2005
    my $day  = $date_obj->return_day(format=>'numeric');# day = 27
    my $time = $date_obj->return_time(format=>'12', length=>'short'); # $time = 5:12 p.m.
    my $date = $date_obj->return_date(format=>'yyyymmdd'); # $date = 20051127


=head1 DESCRIPTION

This module provides a simple OO interface to current system time and date information. The module provides not only access to individual components of localtime, but also several frequently used date format combinations (e.g., localtime, yyyymmdd, mm-dd-yyyy, month-day-year). See return_date under INTERFACE section for full list of date formats.  


=head1 INTERFACE

The following methods are supported:

=head2 new

new: Class constructor; no arguments are sent to this method. The new method must be called everytime a snapshot of the current system time/date is desired.

 my $date_obj = DateStamp->new();

=head2 return_year

return_year: This method will return the numeric value of the current year. Two possible return formats are available: short & long.

 $date_obj->return_year(length=>'short');  # 05
 $date_obj->return_year(length=>'long');   # 2005

=head2 return_month

return_month: This method will return either an alpha or numeric value for the current month in a variety of formats.

 $date_obj->return_month(format=>'alpha', length=>'short');  # Nov 
 $date_obj->return_month(format=>'alpha', length=>'long');   # November
 $date_obj->return_month(format=>'numeric');                 # 11

=head2 return_day

return_day: This method will return either an alpha or numeric value for the current day in a variety of formats.

 $date_obj->return_day(format=>'alpha', length=>'short');  # Sun
 $date_obj->return_day(format=>'alpha', length=>'long');   # Sunday
 $date_obj->return_day(format=>'numeric');                 # 27

=head2 return_time

return_time: This method will return a variety of time formats. The time in this sense is literally a "timestamp", in that it captures the time at the moment the date object is created--and *not* when the method is called.

 $date_obj->return_time(format=>'12', length=>'short');  # 12:56 a.m.
 $date_obj->return_time(format=>'12', length=>'long' );  # 12:56:32 a.m.
 $date_obj->return_time(format=>'24', length=>'short');  # 00:56
 $date_obj->return_time(format=>'24', length=>'long' );  # 00:56:32
 $date_obj->return_time(format=>'localtime'          );  # Sun Nov 27 00:13:56 2005 

=head2 return_date

return_date: This method provides serveral frequently used, pre-compiled date combinations. The combinations are not meant to be exhaustive, as other combinations can be arrived at by combining the aforementioned month/day/year/timestamp methods. Both the "yyyymmdd" & "mmddyyyy" formats accept a "glue" argument, placing a provided symbol between month, day, and year.

 $date_obj->return_date(format=>'yyyymmdd');                # 20051127 
 $date_obj->return_date(format=>'yyyymmdd', glue=>'-');     # 2005-11-27 
 $date_obj->return_date(format=>'mmddyyyy');                # 11272005
 $date_obj->return_date(format=>'mmddyyyy', glue=>'/');     # 11/27/2005
 $date_obj->return_date(format=>'month-day-year');          # November 27, 2005
 $date_obj->return_date(format=>'mon-day-year');            # Nov 27, 2005 
 $date_obj->return_date(format=>'weekday-month-day-year');  # Monday, November 27, 2005
 $date_obj->return_date(format=>'month-day');               # November 27
 $date_obj->return_date(format=>'mon-day');                 # Nov 27


=head1 DIAGNOSTICS

A user may encounter error messages associated with this module if required method arguments are malformed or missing.

=over

=item C<< DateStamp reports: Bad/missing "format" argument. >>

[A user has invoked a method that requires a "format" argument of type valid for the method called. Check spelling, case (lower-case required), and argument types associated with the method in question.]

=item C<< DateStamp reports: Bad/missing "length" argument. >>

[A user has invoked a method that requires a "length" argument of type valid for the method called. Check spelling, case (lower-case required), and argument types associated with the method in question.]

=back


=head1 CONFIGURATION AND ENVIRONMENT

DateStamp requires no configuration files or environment variables.


=head1 DEPENDENCIES

This module calls a few others: strict; warnings; Carp; version.


=head1 INCOMPATIBILITIES

None reported.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-date-current@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 SEE ALSO

There are several heavy-weight date/time modules in CPAN. Try a search for DateTime or Date in CPAN for a list of alternatives.


=head1 ACKNOWLEDGMENTS

Yup, this is my first CPAN module; I wanted to contribute something very simple to start with. Thanks to Andy Lester for his presentation I<"The A-Z Guide To Becoming a CPAN Author"> at the St. Louis Perl Monger chapter meeting in November, 2005. His insight helped greatly in illuminating some dark areas of my skill-set. Andy's talk also galvanized me to finally contribute something to CPAN after 8 years of perl programming.


=head1 AUTHOR

Todd Wylie  

C<< <perldev@monkeybytes.org> >>  

L<< http://www.monkeybytes.org >>


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2005, Todd Wylie C<< <perldev@monkeybytes.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See perlartistic.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=head1 NOTE

This software was written using the latest version of GNU Emacs, the
extensible, real-time text editor. Please see
L<http://www.gnu.org/software/emacs> for more information and download
sources.
