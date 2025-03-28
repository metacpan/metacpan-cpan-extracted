

use Test::More no_plan;
use utf8;

BEGIN { use_ok("Date::Holidays::NZ") }

*rev_regions = *Date::Holidays::NZ::rev_regions;

# rev_regions
is(rev_regions("Auckland"), 2, "rev_regions(Good)");
is(rev_regions("auCkLaNd"), 2, "rev_regions(Good)");
eval { rev_regions("Orkland") };
isnt($@, "", "rev_regions(Bad)");

*nz_region_name = *Date::Holidays::NZ::nz_region_name;

# nz_region_name
is(nz_region_name("Auckland"), "Auckland", "nz_region_name(Name)");
is(nz_region_name("auckland"), "Auckland", "nz_region_name(Name)");
is(nz_region_name("Canterbury (South)"), "Canterbury (South)",
   "nz_region_code(Cant)");
is(nz_region_name(2), "Auckland", "nz_region_name(Num)");
eval { nz_region_name(10) };
isnt($@, "", "nz_region_name(Bad Num)");
eval { nz_region_name("Orkland") };
isnt($@, "", "nz_region_name(Bad Name)");

*nz_region_code = *Date::Holidays::NZ::nz_region_code;

# nz_region_code
is(nz_region_code("Auckland"), 2, "nz_region_code(Name)");
is(nz_region_code("auckland"), 2, "nz_region_code(Name)");
is(nz_region_code("Canterbury (South)"), -13, "nz_region_code(Cant)");
is(nz_region_code(2), 2, "nz_region_code(Num)");
eval { nz_region_code(10) };
isnt($@, "", "nz_region_code(Bad Num)");
eval { nz_region_code("Orkland") };
isnt($@, "", "nz_region_code(Bad Name)");

# nz_regional_day
*nz_regional_day = *Date::Holidays::NZ::nz_regional_day;

my $AD = "Anniversary Day";
my @tests = ( 1 => "Auckland $AD",
	      "Auckland" => "Auckland $AD",
	      "Gisborne" => "Auckland $AD",
	      "Canterbury" => "Christchurch Show Day",
	      "Canterbury (South)" => "Dominion Day",
	      "Manawatū-Whanganui" => "Wellington $AD",
	      9 => "Wellington $AD",
	      "Chatham Islands" => "Chatham Islands $AD",
	      99 => "Chatham Islands $AD",
	    );

for ( my $i = 0; $i <= $#tests; $i += 2 ) {
    is(nz_regional_day($tests[$i]), $tests[$i+1],
       "nz_regional_day('$tests[$i]')");
}

# interpret_date
*interpret_date = *Date::Holidays::NZ::interpret_date;
@tests = ("2005,easter" => "0327",
	  "2005,easter+1day" => "0328",
	  "2005,easter+1day" => "0328",
	  "2005,closest monday to 0129" => "0131",
	  "2004,closest monday to 0129" => "0126",
	  "2003,closest monday to 0129" => "0127",
	  "2006,closest monday to 0129" => "0130",
	  "2007,closest monday to 0129" => "0129",
	  "2008,closest monday to 0129" => "0128",
	  "2010,closest monday to 0129" => "0201",
	  "2005,3rd saturday in january" => "0115",
	  "2005,3rd saturday in january + 1day" => "0116",
	  "2003,4th Monday in October" => "1027",
	 );
for ( my $i = 0; $i <= $#tests; $i += 2 ) {
    my ($year, $spec) = ($tests[$i] =~ m/^(\d{4}),(.*)$/)
	or die;
    is(interpret_date($year, $spec), $tests[$i+1],
       "interpret_date(year, '$spec')");
}

# with a matrix like this in the test suite, why bother with the code?
# Because I'm a masochist, that's why.  and besides, something's got
# to generate it.
@tests = split /
/, <<DATA;
New Year's Day 2003-01-01 2004-01-01 2005-01-03 2006-01-03 2007-01-01 2008-01-01 2009-01-01
Day after New Year's Day 2003-01-02 2004-01-02 2005-01-04 2006-01-02 2007-01-02 2008-01-02 2009-01-02
Waitangi Day 2003-02-06 2004-02-06 2005-02-06 2006-02-06 2007-02-06 2008-02-06 2009-02-06 2014-02-06 2015-02-06 2016-02-08
Good Friday 2003-04-18 2004-04-09 2005-03-25 2006-04-14 2007-04-06 2008-03-21 2009-04-10
Easter Monday 2003-04-21 2004-04-12 2005-03-28 2006-04-17 2007-04-09 2008-03-24 2009-04-13
Anzac Day 2003-04-25 2004-04-25 2005-04-25 2006-04-25 2007-04-25 2008-04-25 2009-04-25 2014-04-25 2015-04-27
Queen's Birthday 2003-06-02 2004-06-07 2005-06-06 2006-06-05 2007-06-04 2008-06-02 2009-06-01
Labour Day 2003-10-27 2004-10-25 2005-10-24 2006-10-23 2007-10-22 2008-10-27 2009-10-26
Christmas Day 2003-12-25 2004-12-27 2005-12-27 2006-12-25 2007-12-25 2008-12-25 2009-12-25
Boxing Day 2003-12-26 2004-12-28 2005-12-26 2006-12-26 2007-12-26 2008-12-26 2009-12-28
Matariki 2022-06-24 2023-07-14 2024-06-28 2025-06-20 2026-07-10 2027-06-25 2028-07-14 2029-07-06 2030-06-21 2031-07-11
DATA

BEGIN { eval 'use YAML';
	if ($@) {
	    eval 'use Data::Dumper';
	    *Dump = *Dumper;
	} };

for my $year (2003 .. 2031) {
    my $hols = nz_holidays($year);
    # diag Dump{ $year => $hols};
}

for my $test ( @tests ) {
    my ($holiday, $test) = ($test =~ m/^(.*?)\s(20[0123].*)$/);

    for my $date ( split /\s+/, $test ) {
	my ($year, $mon, $dom) = split /-/, $date;
	my $hols = nz_holidays($year);

	if ( my $holname = $hols->{$mon.$dom} ) {
	    if ( $holname ne $holiday ) {
		if ( $holiday . " Holiday" ne $holname ) {
		    fail("$year-$mon-$dom should be $holiday, not $holname");
		} else {
		    pass("$year-$mon-$dom is $holname - CARRIED");
		}
	    } else {
		pass("$year-$mon-$dom is $holname");
	    }
	}
	else {
	    fail("$year-$mon-$dom should be $holiday");
	}
    }
}

@tests = split /
/, <<DATA;
Auckland  	Monday 27 January  	Monday 26 January  	Monday 31 January Monday 30 January  	Monday 29 January  	Monday 28 January  	Monday 26 January
Taranaki 	Monday 10 March 	Monday 8 March 	Monday 14 March Monday 13 March 	Monday 12 March 	Monday 10 March 	Monday 9 March
Hawke's Bay 	Friday 24 October 	Friday 22 October 	Friday 21 October Friday 20 October 	Friday 19 October 	Friday 24 October 	Friday 23 October
Wellington 	Monday 20 January 	Monday 19 January 	Monday 24 January Monday 23 January 	Monday 22 January 	Monday 21 January 	Monday 19 January
Marlborough 	Monday 3 November 	Monday 1 November 	Monday 31 October Monday 30 October 	Monday 29 October 	Monday 3 November 	Monday 2 November
Nelson 	Monday 3 February 	Monday 2 February 	Monday 31 January Monday 30 January 	Monday 29 January 	Monday 4 February 	Monday 2 February
Canterbury 	Friday 14 November 	Friday 12 November 	Friday 11 November Friday 17 November 	Friday 16 November 	Friday 14 November 	Friday 13 November
Canterbury (South) 	Monday 22 September 	Monday 27 September 	Monday 26 September Monday 25 September 	Monday 24 September 	Monday 22 September 	Monday 28 September
West Coast 	Monday 1 December 	Monday 29 November 	Monday 28 November 	 Monday 4 December 	Monday 3 December 	Monday 1 December 	Monday 30 November
Otago  Monday 24 March 	Monday 22 March 	Monday 21 March Monday 20 March 	Monday 26 March 	Tuesday 25 March 	Monday 23 March
Southland 	Monday 20 January 	Monday 19 January 	Monday 17 January Monday 16 January 	Monday 15 January 	Monday 14 January 	Monday 19 January
Chatham Islands 	Monday 1 December 	Monday 29 November 	Monday 28 November Monday 27 November 	Monday 3 December 	Monday 1 December 	Monday 30 November
DATA

use Date::Manip qw(ParseDate UnixDate);

for my $test ( @tests ) {
    my ($region, $dates) = ($test =~ m/^(.*?)\s+(\w+day.*)$/);
    my @dates = split /\s+/, $dates;
    my $year = 2003;
    while ( @dates ) {
	my ($dow, $d, $m) = splice @dates, 0, 3;
	my $when = ParseDate("$d $m $year") or die;
	my @ymd = ($year, UnixDate($when, "%m"), $d);
	my $holname = is_nz_holiday(@ymd, $region);
	my $pass = $holname && ! is_nz_holiday(@ymd);
	$holname ||= nz_regional_day($region);
	ok($pass, "@ymd - only $region has $holname this day");
	diag("$holname falls on ".nz_holiday_date($year, $holname)." in $year, not ".UnixDate($when, "%m%d"))
	    unless $pass;
	$year++;
    }
}

is(nz_holiday_date(2008, "Otago $AD"), "0325", "nz_holiday_date(regional)");
is(nz_holiday_date(2035, "Otago $AD"), "0326", "nz_holiday_date(regional)");
is(nz_holiday_date(2004, "Westland $AD"), "1129", "nz_holiday_date(regional)");
is(nz_holiday_date(2035, "Easter Monday"), "0326", "nz_holiday_date(national)");
is(nz_holiday_date(2004, "Christmas Day"), "1227", "nz_holiday_date(national, overflow)");

is(nz_holiday_date(2004, "Birthday of the Reigning Sovereign"),
   "0607", "nz_holiday_date(alias)");

# test 2022 and 2023 using government website as source data
is(nz_holiday_date(2022, "New Year's Day"), "0103", "nz_holiday_date(national)");
is(nz_holiday_date(2022, "Day after New Year's Day"), "0104", "nz_holiday_date(national)");
is(nz_holiday_date(2022, "Waitangi Day"), "0207", "nz_holiday_date(national)");
is(nz_holiday_date(2022, "Good Friday"), "0415", "nz_holiday_date(national)");
is(nz_holiday_date(2022, "Easter Monday"), "0418", "nz_holiday_date(national)");
is(nz_holiday_date(2022, "Anzac Day"), "0425", "nz_holiday_date(national)");
is(nz_holiday_date(2022, "Queen's Birthday"), "0606", "nz_holiday_date(national)");
is(nz_holiday_date(2022, "Matariki"), "0624", "nz_holiday_date(national)");
is(nz_holiday_date(2022, "Labour Day"), "1024", "nz_holiday_date(national)");
is(nz_holiday_date(2022, "Christmas Day"), "1227", "nz_holiday_date(national)");
is(nz_holiday_date(2022, "Boxing Day"), "1226", "nz_holiday_date(national)");
is(nz_holiday_date(2022, "Auckland $AD"), "0131", "nz_holiday_date(regional)");
is(nz_holiday_date(2022, "Dominion Day"), "0926", "nz_holiday_date(regional)");
is(nz_holiday_date(2022, "Christchurch Show Day"), "1111", "nz_holiday_date(regional)");
is(nz_holiday_date(2022, "Chatham Islands $AD"), "1128", "nz_holiday_date(regional)");
is(nz_holiday_date(2022, "Hawke's Bay $AD"), "1021", "nz_holiday_date(regional)");
is(nz_holiday_date(2022, "Marlborough $AD"), "1031", "nz_holiday_date(regional)");
is(nz_holiday_date(2022, "Nelson $AD"), "0131", "nz_holiday_date(regional)");
is(nz_holiday_date(2022, "Otago $AD"), "0321", "nz_holiday_date(regional)");
is(nz_holiday_date(2022, "Southland $AD"), "0419", "nz_holiday_date(regional)");
is(nz_holiday_date(2022, "Taranaki $AD"), "0314", "nz_holiday_date(regional)");
is(nz_holiday_date(2022, "Wellington $AD"), "0124", "nz_holiday_date(regional)");
is(nz_holiday_date(2022, "Westland $AD"), "1128", "nz_holiday_date(regional)");

is(nz_holiday_date(2023, "New Year's Day"), "0103", "nz_holiday_date(national)");
is(nz_holiday_date(2023, "Day after New Year's Day"), "0102", "nz_holiday_date(national)");
is(nz_holiday_date(2023, "Waitangi Day"), "0206", "nz_holiday_date(national)");
is(nz_holiday_date(2023, "Good Friday"), "0407", "nz_holiday_date(national)");
is(nz_holiday_date(2023, "Easter Monday"), "0410", "nz_holiday_date(national)");
is(nz_holiday_date(2023, "Anzac Day"), "0425", "nz_holiday_date(national)");
is(nz_holiday_date(2023, "Queen's Birthday"), "0605", "nz_holiday_date(national)");
is(nz_holiday_date(2023, "Matariki"), "0714", "nz_holiday_date(national)");
is(nz_holiday_date(2023, "Labour Day"), "1023", "nz_holiday_date(national)");
is(nz_holiday_date(2023, "Christmas Day"), "1225", "nz_holiday_date(national)");
is(nz_holiday_date(2023, "Boxing Day"), "1226", "nz_holiday_date(national)");
is(nz_holiday_date(2023, "Auckland $AD"), "0130", "nz_holiday_date(regional)");
is(nz_holiday_date(2023, "Dominion Day"), "0925", "nz_holiday_date(regional)");
is(nz_holiday_date(2023, "Christchurch Show Day"), "1117", "nz_holiday_date(regional)");
is(nz_holiday_date(2023, "Chatham Islands $AD"), "1127", "nz_holiday_date(regional)");
is(nz_holiday_date(2023, "Hawke's Bay $AD"), "1020", "nz_holiday_date(regional)");
is(nz_holiday_date(2023, "Marlborough $AD"), "1030", "nz_holiday_date(regional)");
is(nz_holiday_date(2023, "Nelson $AD"), "0130", "nz_holiday_date(regional)");
is(nz_holiday_date(2023, "Otago $AD"), "0320", "nz_holiday_date(regional)");
is(nz_holiday_date(2023, "Southland $AD"), "0411", "nz_holiday_date(regional)");
is(nz_holiday_date(2023, "Taranaki $AD"), "0313", "nz_holiday_date(regional)");
is(nz_holiday_date(2023, "Wellington $AD"), "0123", "nz_holiday_date(regional)");
is(nz_holiday_date(2023, "Westland $AD"), "1204", "nz_holiday_date(regional)");

#is(nz_holiday_date(2023, ""), "", "nz_holiday_date(regional)");
#is(nz_holiday_date(2023, ""), "", "nz_holiday_date(national)");
