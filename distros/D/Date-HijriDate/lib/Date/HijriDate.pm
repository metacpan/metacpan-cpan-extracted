#=Copyright Infomation
#==========================================================
#Module Name       : Date::HijriDate
#Program Author   : Dr. Ahmed Amin Elsheshtawy, Ph.D. Physics, E.E.
#Home Page           : http://www.islamware.com, http://www.mewsoft.com
#Contact Email      : support@islamware.com, support@mewsoft.com
#Copyrights © 2013 IslamWare. All rights reserved.
#==========================================================
package Date::HijriDate;

use strict;
use POSIX;

require Exporter;
our @ISA = 'Exporter';
our @EXPORT = qw(hijri_date hijri_now hijri_time);

our $VERSION = '1.01';

our %weekday = (
								'en' => ["Ahad","Ithnin","Thulatha","Arbaa","Khams","Jumuah","Sabt"],

								'ar' => ["الأحد","الأثنين","الثلاثاء","الأربعاء","الخميس","الجمعة","السبت"]
							);

our %month = (
								'en' => ["Muharram","Safar","Rabi'ul Awwal","Rabi'ul Akhir", "Jumadal Ula","Jumadal Akhira",
												"Rajab","Sha'ban", "Ramadan","Shawwal","Dhul Qa'ada","Dhul Hijja"],

								'ar' => ["محرم","صفر","ربيع الأول","ربيع الثاني", "جمادي الأول","جمادي الثاني",
												"رجب","شعبان", "رمضان","شوال","ذو القعدة","ذو الحجة"]
							);
#=========================================================#
	#Arithmetical calendar type 	  
	#Ic [‛15’, civil] 	  				 
	#Ia [‛15’, astronomical] 	  				 
	#IIc [‛16’, civil] 	  				 
	#IIa [‛16’, astronomical = “MS HijriCalendar”] 	  				 
	#IIIc [Fātimid, civil] 	  				 
	#IIIa [Fātimid, astronomical] 	  				 
	#IVc [Habash al-Hāsib, civil] 	  				 
	#IVa [Habash al-Hāsib, astronomical]

#	generalized modulo function (n mod m) also valid for negative values of n
sub  gmod {
my ($n, $m) = @_;
	return (($n % $m) + $m) % $m;
}

sub hijri_time {
my ($time, $caltype, $lang) = @_;
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $dst) = localtime($time);
	return hijri_date($mday, $mon, $year+1900, $caltype, $lang);
}

sub hijri_now {
my ($caltype, $lang) = @_;
	my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $dst) = localtime(time);
	return hijri_date($mday, $mon, $year+1900, $caltype, $lang);
}

sub hijri_date {
my ($day, $month, $year, $caltype, $lang) = @_;
my (%ret);
	
	# $month: 0-11
	# $year: yyyy
	# $caltype: 0= Julian, 1=Gregorian
	
	$caltype += 0;

	if (!exists $weekday{$lang}) {
		$lang = 'en';
	}

	my $m = $month + 1;
	my $y = $year;

	# append January and February to the previous year (i.e. regard March as
	# the first month of the year in order to simplify leapday corrections)

	if ($m < 3) {
		$y -= 1;
		$m += 12;
	}

	# determine offset between Julian and Gregorian calendar 
	my $jgc;
	if ($y < 1583) {$jgc = 0};

	if ($y == 1582) {
		if ($m > 10) {$jgc = 10;}
		if ($m == 10 && $day < 5 ) {$jgc = 0;}
		if ($m == 10 && $day > 14) {$jgc = 10;}
		if ($m == 10 && $day > 4 && $day < 15) {
			if ($caltype == 0) {
				$jgc = 10;
				$day += 10;
			}
			if ($caltype == 1) {
				$jgc = 0;
				$day -= 10;
			}
		}
	}

	if ($y > 1582) {
		$a   = floor($y/100);
		$jgc = $a - floor($a/4) - 2;
	}

	# compute Chronological Julian Day Number (CJDN)
  
	my $cjdn = floor(365.25*($y + 4716)) + floor(30.6001*($m+1)) + $day - $jgc - 1524;

	# output calendar type (0 = Julian; 1 = Gregorian)
  
	if ($cjdn < 2299161) {
		$jgc = 0;
		$ret{caltype} = 0;
	}

	if ($cjdn > 2299160) {
		$ret{caltype} = 1;
		$a = floor(($cjdn - 1867216.25)/36524.25);
		$jgc = $a - floor($a/4) + 1;
	}
  
	$b = $cjdn + $jgc + 1524;
	my $c = floor(($b - 122.1)/365.25);
	my $d = floor(365.25*$c);
	$month = floor(($b - $d)/30.6001);
	$day = ($b - $d) - floor(30.6001*$month);

	if ($month > 13) {
		$c += 1;
		$month -= 12;
	}

	$month -= 1;
	$year = $c - 4716;

	# output Western calendar date
	$ret{day} = $day;
	$ret{month} = $month - 1;
	$ret{year} = $year;

	# compute weekday
	my $wd = gmod($cjdn+1, 7) + 1;

	#output Julian Day Number and weekday
	$ret{julday} = $cjdn;
	$ret{wkday} = $wd - 1;
	$ret{itoday} = $weekday{$lang}->[$wd - 1];
	
	# set mean length and epochs (astronomical & civilian) of the tabular Islamic year  
	
	my $iyear = 10631/30;
	my $epochastro = 1948084;
	my $epochcivil = 1948085;

	# compute and output Islamic calendar date (type I)
  
	my $shift1 = 8.01/60; # rets in years 2, 5, 7, 10, 13, 15, 18, 21, 24, 26 & 29 as leap years
  
	my $z = $cjdn - $epochcivil;
	my $cyc = floor($z/10631);
	$z = $z - 10631*$cyc;
	my $j = floor(($z - $shift1)/$iyear);
	my $iy = 30*$cyc + $j;
	$z = $z - floor($j*$iyear + $shift1);
	my $im = floor(($z + 28.5001)/29.5);
	if ($im == 13) {$im = 12;}
	my $id = $z - floor(29.5001*$im - 29);

	$ret{iday1} = $id;
	$ret{imonth1} = $im - 1;
	$ret{iyear1}  = $iy;
	$ret{iname1}  = $month{$lang}->[$im - 1];
	   
	$z = $cjdn - $epochastro;
	$cyc = floor($z/10631);
	$z = $z - 10631*$cyc;
	$j = floor(($z - $shift1)/$iyear);
	$iy = 30*$cyc + $j;
	$z = $z - floor($j*$iyear + $shift1);
	$im = floor(($z + 28.5001)/29.5);
	if ($im == 13) {$im = 12;}
	$id = $z - floor(29.5001*$im - 29);

	$ret{iday2} = $id;
	$ret{imonth2} = $im - 1;
	$ret{iyear2} = $iy;
	$ret{iname2}  = $month{$lang}->[$im - 1];

	#compute and output Islamic calendar date (type II)   

	my $shift2 = 6.01/60; # rets in years 2, 5, 7, 10, 13, 16, 18, 21, 24, 26 & 29 as leap years

	$z = $cjdn - $epochcivil;
	$cyc = floor($z/10631);
	$z = $z - 10631*$cyc;
	$j = floor(($z - $shift2)/$iyear);
	$iy = 30*$cyc + $j;
	$z = $z - floor($j*$iyear + $shift2);
	$im = floor(($z+28.5001)/29.5);
	if ($im == 13) {$im = 12;}
	$id = $z - floor(29.5001*$im - 29);

	$ret{iday3} = $id;
	$ret{imonth3} = $im - 1;
	$ret{iyear3} = $iy;
	$ret{iname3}  = $month{$lang}->[$im - 1];
  
	$z = $cjdn - $epochastro;
	$cyc = floor($z/10631);
	$z = $z - 10631*$cyc;
	$j = floor(($z - $shift2)/$iyear);
	$iy = 30*$cyc + $j;
	$z = $z - floor($j*$iyear + $shift2);
	$im = floor(($z + 28.5001)/29.5);
	if ($im == 13) {$im = 12;}
	$id = $z - floor(29.5001*$im - 29);

	$ret{iday4} = $id;
	$ret{imonth4} = $im - 1;
	$ret{iyear4} = $iy;
	$ret{iname4}  = $month{$lang}->[$im - 1];

	# compute and output Islamic calendar date (type III)   

	my $shift3 = 0.01/60; # rets in years 2, 5, 8, 10, 13, 16, 19, 21, 24, 27 & 29 as leap years

	$z = $cjdn - $epochcivil;
	$cyc = floor($z/10631);
	$z = $z - 10631*$cyc;
	$j = floor(($z - $shift3)/$iyear);
	$iy = 30*$cyc + $j;
	$z = $z - floor($j*$iyear + $shift3);
	$im = floor(($z + 28.5001)/29.5);
	if ($im == 13) {$im = 12;}
	$id = $z - floor(29.5001*$im-29);

	$ret{iday5} = $id;
	$ret{imonth5} = $im - 1;
	$ret{iyear5} = $iy;
	$ret{iname5}  = $month{$lang}->[$im - 1];
  
	$z = $cjdn - $epochastro;
	$cyc = floor($z/10631);
	$z = $z - 10631*$cyc;
	$j = floor(($z - $shift3)/$iyear);
	$iy = 30*$cyc + $j;
	$z = $z - floor($j*$iyear + $shift3);
	$im = floor(($z + 28.5001)/29.5);
	if ($im == 13) {$im = 12;}
	$id = $z - floor(29.5001*$im - 29);

  	$ret{iday6} = $id;
	$ret{imonth6} = $im - 1;
	$ret{iyear6} = $iy;
	$ret{iname6}  = $month{$lang}->[$im - 1];

	# compute and output Islamic calendar date (type IV)   
  
	my $shift4 = -2.01/60;	# rets in years 2, 5, 8, 11, 13, 16, 19, 21, 24, 27 & 30 as leap years

	$z = $cjdn - $epochcivil;
	$cyc = floor($z/10631);
	$z = $z - 10631*$cyc;
	$j = floor(($z - $shift4)/$iyear);
	$iy = 30*$cyc + $j;
	$z = $z - floor($j*$iyear + $shift4);
	$im = floor(($z+28.5001)/29.5);
	if ($im == 13) {$im = 12;}
	$id = $z - floor(29.5001*$im - 29);

	$ret{iday7} = $id;
	$ret{imonth7} = $im - 1;
	$ret{iyear7} = $iy;
	$ret{iname7}  = $month{$lang}->[$im - 1];

	$z = $cjdn - $epochastro;
	$cyc = floor($z/10631);
	$z = $z - 10631*$cyc;
	$j = floor(($z - $shift4)/$iyear);
	$iy = 30*$cyc + $j;
	$z = $z - floor($j*$iyear + $shift4);
	$im = floor(($z+28.5001)/29.5);
	if ($im == 13) {$im = 12;}
	$id = $z - floor(29.5001*$im - 29);

	$ret{iday8} = $id;
	$ret{imonth8} = $im - 1;
	$ret{iyear8} = $iy;
	$ret{iname8}  = $month{$lang}->[$im - 1];
	
	return %ret;
}
#=========================================================#
1;

=head1 NAME

Date::HijriDate - Hijri Islamic Dates Calendar 

=head1 SYNOPSIS

	use Date::HijriDate;

	my $day = 8;			# day of the month
	my $month = 11;			# month 0..11
	my $year = 2013;		# yyyy format
	my $caltype = 1;		# (0 = Julian; 1 = Gregorian)
	my $lang = "en";		# available languages: en, ar
	my %ret;
	
	# get Hijri date for specific Gregorian day
	#%ret = hijri_date($day, $month, $year, $caltype, $lang);
	
	# get current time in Hijri
	#%ret = hijri_now($caltype, $lang);

	# get Hijri time for the specific time stamp
	%ret = hijri_time(time, $caltype, $lang);

	# Western date
	$ret{month}++; # returned month 0..11
	print "Western date: $ret{day}-$ret{month}-$ret{year}\n";
	
	#Arithmetical calendar type 	  	day 	month 	year (AH) 	 
	print "'Arithmetical calendar type'	day	month	'year (AH)'	'month name'\n";
	
	# all returned month 0..11

	#Method 1 civil, astronomical
	$ret{imonth1}++; $ret{imonth2}++;
  	print "Ic [15, civil] $ret{iday1}-$ret{imonth1}-$ret{iyear1}  $ret{iname1}\n";
	print "Ia [15, astronomical] $ret{iday2}-$ret{imonth2}-$ret{iyear2}  $ret{iname2}\n";
	
	#Method 2 civil, astronomical
	$ret{imonth3}++; $ret{imonth4}++;
	print "IIc [16, civil] $ret{iday3}-$ret{imonth3}-$ret{iyear3}  $ret{iname3}\n";
	print "IIa [16, astronomical='MS HijriCalendar'] $ret{iday4}-$ret{imonth4}-$ret{iyear4}  $ret{iname4}\n";
	
	#Method 3 civil, astronomical
	$ret{imonth5}++; $ret{imonth6}++;
	print "IIIc [Fātimid, civil] $ret{iday5}-$ret{imonth5}-$ret{iyear5}  $ret{iname5}\n";
	print "IIIa [Fātimid, astronomical] $ret{iday6}-$ret{imonth6}-$ret{iyear6}  $ret{iname6}\n";
	
	#Method 4 civil, astronomical
	$ret{imonth7}++; $ret{imonth8}++;
	print "IVc [Habash al-Hāsib, civil] $ret{iday7}-$ret{imonth7}-$ret{iyear7}  $ret{iname7}\n";
	print "IVa [Habash al-Hāsib, astronomical] $ret{iday8}-$ret{imonth8}-$ret{iyear8}  $ret{iname8}\n";
	
	print "Julian day: $ret{julday}\n";
	print "Weekday number 0..7, 0=Sunday: $ret{wkday}\n";
	print "Hijri day name: $ret{itoday}\n";
	print "Calender type: ". (($ret{caltype} == 1)? "Gregorian" : "Julian") . "\n";
	print "\n\n";

	# print all dates information for all 8 calculation methods
	foreach my $k(sort keys %ret) {
		print "$k = $ret{$k}\n";
	}
	
	# output

	Western date: 9-12-2013
	'Arithmetical calendar type'	day-month-'year (AH)'	'month name'	
	Ic [15, civil]		5-2-1435	Safar
	Ia [15, astronomical]	6-2-1435	Safar
	IIc [16, civil]	5-2-1435	Safar
	IIa [16, astronomical='MS HijriCalendar']	6-2-1435	Safar
	IIIc [Fātimid, civil]	5-2-1435	Safar
	IIIa [Fātimid, astronomical]	6-2-1435	Safar
	IVc [Habash al-Hāsib, civil]	5-2-1435	Safar
	IVa [Habash al-Hāsib, astronomical]	6-2-1435	Safar
	Julian day:	2456636
	Weekday number 0..7, 0=Sunday:	1
	Hijri day name:	Ithnin
	Calender type:		Gregorian

=head1 DESCRIPTION

This module calculates Islamic Hijri calender dates using civil and astronomical 8 methods.

	Arithmetical calendar type:
	Ic [15, civil]
	Ia [15, astronomical]
	IIc [16, civil]
	IIa [16, astronomical = "MS HijriCalendar"]
	IIIc [Fātimid, civil]
	IIIa [Fātimid, astronomical]
	IVc [Habash al-Hāsib, civil]
	IVa [Habash al-Hāsib, astronomical]

Exports three methods hijri_time, hijri_now, and hijri_date.
All methods return date information in a single hash.

	%ret = hijri_time($time, $caltype, $lang);
	$time: unix time stamp;
	$caltype: 0 = Julian, 1 = Gregorian
	$lang: en, ar only currently supported for weekday and month names.
	
	%ret = hijri_now($caltype, $lang)
	return current Hijri time

	%ret = hijri_date($day, $month, $year, $caltype, $lang)
	return Hijri date for a given western date.
	$month: 0..11
	$year: yyyy format

=head1 SEE ALSO

L<Religion::Islam::Qibla>
L<Religion::Islam::Quran>
L<Religion::Islam::PrayTime>
L<Religion::Islam::PrayerTimes>

=head1 AUTHOR

Ahmed Amin Elsheshtawy,  <support@islamware.com> <support@mewsoft.com>
Website: http://www.islamware.com   http://www.mewsoft.com

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Dr. Ahmed Amin Elsheshtawy webmaster@islamware.com,
L<http://www.islamware.com> 
L<http://www.mewsoft.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

