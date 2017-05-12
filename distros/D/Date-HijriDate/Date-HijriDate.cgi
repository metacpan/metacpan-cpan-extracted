#=Copyright Infomation
#==========================================================
#Module Name      : Date::HijriDate
#Program Author   : Dr. Ahmed Amin Elsheshtawy, Ph.D. Physics, E.E.
#Home Page          : http://www.islamware.com, http://www.mewsoft.com
#Contact Email      : support@islamware.com, support@mewsoft.com
#Copyrights © 2013 IslamWare. All rights reserved.
#==========================================================

	#print "Content-type: text/html;charset=utf-8\n\n";
	$|=1; 
	
	use Date::HijriDate;

	my $day = 8;				# day of the month
	my $month = 11;			# month 0..11
	my $year = 2013;		# yyyy format
	my $caltype = 1;			# (0 = Julian; 1 = Gregorian)
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
	print "'Arithmetical calendar type'	day		month		'year (AH)'	'month name'	\n";
	
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
#=========================================================#
#=========================================================#
