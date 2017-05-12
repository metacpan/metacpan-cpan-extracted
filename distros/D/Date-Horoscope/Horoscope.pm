package Date::Horoscope;

use Data::Dumper;
use Date::Manip;


use strict qw(vars subs);
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;

@ISA = qw(Exporter AutoLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '2.2';

# year is irrelevant for our purposes

%Date::Horoscope::horoscope = (
	      'aries' => {
		  'position' => 1,
		  'start' => '3/21/92', 
		  'end'   => '4/20/92',
	      },
	      'taurus' => {
		  'position' => 2,
		  'start' => '4/21/92', 
		  'end'   => '5/20/92',
	      },
	      'gemini' => {
		  'position' => 3,
		  'start' => '5/21/92', 
		  'end'   => '6/21/92',
	      },
	      'cancer' => {
		  'position' => 4,
		  'start' => '6/22/92', 
		  'end'   => '7/22/92',
	      },
	      'leo' => {
		  'position' => 5,
		  'start' => '7/23/92', 
		  'end'   => '8/23/92',
	      },
	      'virgo' => {
		  'position' => 6,
		  'start' => '8/24/92', 
		  'end'   => '9/22/92',
	      },
	      'libra' => {
		  'position' => 7,
		  'start' => '9/23/92', 
		  'end'   => '10/22/92',
	      },
	      'scorpio' => {
		  'position' => 8,
		  'start' => '10/23/92', 
		  'end'   => '11/21/92',
	      },
	      'sagittarius' => {
		  'position' => 9,
		  'start' => '11/22/92', 
		  'end'   => '12/21/92',
	      },
	      'capricorn' => {
		  'position' => 10,
		  'start' => '1/1/92',   # NOT TRUE BUT NECESSARY
		  'end'   => '1/19/92',
	      },
	      'aquarius' => {
		  'position' => 11,
		  'start' => '1/20/92', 
		  'end'   => '2/18/92',
	      },
	      'pisces' => {
		  'position' => 12,
		  'start' => '2/19/92', 
		  'end'   => '3/20/92',
	      }
	      );



# day_month_logic:
# -----------------------------------------------------------------------
# Return a one if the day/month combo is greater than the day/month combo
# it was subtracted from. Return 0 if equal and -1 if less.

sub day_month_logic {
    my ($M,$D)=@_;

    #warn "day_month_logic: $M, $D";

    ($M  < 0)  &&              return -1;
    ($M  > 0)  &&              return  1;
    ($M == 0)  && ($D == 0) && return  0;
    ($M == 0)  && ($D  > 0) && return  1;
    ($M == 0)  && ($D  < 0) && return -1;
}


sub locate {
    my $input_date = $_[0];

    #warn "input_date: $input_date";

    my %input_date;
    $input_date{month} = &UnixDate($input_date, '%m');
    $input_date{day}   = &UnixDate($input_date, '%d');    
    $input_date{year}  = 1992;

    #warn "Y-M-D: $input_date{year}-$input_date{month}-$input_date{day}";

    return 'capricorn' if $input_date{month}==12 && $input_date{day} >=22 && $input_date{day} <=31;

    
    $input_date{new} = "$input_date{year}-$input_date{month}-$input_date{day}";
    #warn "<1>input_date{new} = $input_date{new}";
    $input_date{new} =~ s/\s+//g;


    #warn "<2>input_date{new} = $input_date{new}";

    my @sorted_keys = 
	sort {
	    $Date::Horoscope::horoscope{$a}{position} 
	    <=> 
	    $Date::Horoscope::horoscope{$b}{position}
	} (keys %Date::Horoscope::horoscope);


    # this returns something like 'taurus', 'sagittarius', etc.
    for my $h (@sorted_keys) {

        # start and end dates of this zodiac sign... year irrelevant
	my $start = &ParseDate($Date::Horoscope::horoscope{$h}{start}); 
	my $end   = &ParseDate($Date::Horoscope::horoscope{$h}{end});
	my $input = &ParseDate($input_date{new});



	my $S=&Date_Cmp($start,$input);
	my $E=&Date_Cmp($input,$end);

	#warn sprintf("H: %s S: %d E: %d", $h, $S, $E);
	#warn sprintf ("start: %s end: %s input: %s", $start, $end, $input);

	return $h if (
		      ((!$S) || (!$E)) ||
		      (($S < 0) && ($E < 0))
		      );
	    
    }
}
    


# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

Date::Horoscope - Date operations based on the horoscope calendar

=head1 SYNOPSIS

#!/usr/bin/perl

use Date::Horoscope;
use Date::Manip;

$date='1969-05-11';

$zodiac_sign_name =  Date::Horoscope::locate($date);
$zodiac_sign_posn = $Date::Horoscope::horoscope{Date::Horoscope::locate($date)}->{position},$/;


=head1 DESCRIPTION

This module was written to help with zodiac processing.
It returns an all-lowercase zodiac sign name based on a given
date parseable by Date::Manip. 
You can take this string and use it as a key to %horoscope to get a
position in the zodiac cycle.

=head1 API

=head2 locate

Provide any date parseable by Date::Manip and it turns an all-lowercase zodiac
name.

=head2 %horoscope

This hash contains the position, and start and end dates for a zodiac sign.
The zodiac starts with Aries as far as I know. Some idiot didn't think
taurus was number 1.

=head1 OTHER

I cannot say how tickled I am that RCS changes my <scalar>Date code into
as RCS string for me.

=head1 AUTHOR

T.M. Brannon

Many thanks to Stephen McCamant for his detection of missing Pisces on 
Leap Year. Fixed now!

=head1 SEE ALSO

Date::Manip

=cut
