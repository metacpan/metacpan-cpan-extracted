package Date::Holidays::DE;

use strict;
use warnings;

# Stock modules
use Time::Local;
use POSIX qw(strftime);

# Prerequisite
use Date::Calc qw(Add_Delta_Days Easter_Sunday Day_of_Week This_Year);

require Exporter;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(holidays);
our $VERSION   = '2.02';

sub holidays{
	my %parameters = (
		YEAR     => This_Year(),
		WHERE    => ['common'],
		FORMAT   => "%s",
		WEEKENDS => 1,
		@_,
		);

	# Easter is the key to everything
	my ($year, $month, $day) = Easter_Sunday($parameters{'YEAR'});

	# Aliases for holidays
	#
	# neuj  = Neujahr
	# hl3k  = Dreikoenigstag
	# romo  = Rosenmontag
	# fadi  = Faschingsdienstag
	# asmi  = Aschermittwoch
	# frau  = Internationaler Frauentag
	# grdo  = Gruendonnerstag
	# karf  = Karfreitag
	# kars  = Karsamstag
	# osts  = Ostersonntag
	# ostm  = Ostermontag
	# pfis  = Pfingstsonntag
	# pfim  = Pfingstmontag
	# himm  = Himmelfahrtstag
	# fron  = Fronleichnam
	# 1mai  = Maifeiertag
	# 17ju  = Tag der deutschen Einheit (>= 1954, <= 1990)
	# frie  = Augsburger Friedensfest
	# mari  = Mariae Himmelfahrt
	# 3okt  = Tag der deutschen Einheit (>= 1990)
	# refo  = Reformationstag
	# alhe  = Allerheiligen
	# buss  = Buss- und Bettag
	# votr  = Volkstrauertag
	# toso  = Totensonntag
	# adv1  = 1. Advent
	# adv2  = 2. Advent
	# adv3  = 3. Advent
	# adv4  = 4. Advent
	# heil  = Heiligabend
	# wei1  = 1. Weihnachtstag
	# wei2  = 2. Weihnachtstag
	# silv  = Silvester

	# Aliases for German federal states
	# See http://www.bmi.bund.de/cae/servlet/contentblob/150560/publicationFile/13610/feiertage_de.pdf
	#
	# bw = Baden-Wuerttemberg
	# by = Freistaat Bayern
	# be = Berlin
	# bb = Brandenburg
	# hb = Freie Hansestadt Bremen
	# hh = Freie und Hansestadt Hamburg
	# he = Hessen
	# mv = Mecklenburg-Vorpommern
	# ni = Niedersachsen
	# nw = Nordrhein-Westfalen
	# rp = Rheinland-Pfalz
	# sl = Saarland
	# sn = Freistaat Sachsen
	# st = Sachsen-Anhalt
	# sh = Schleswig-Holstein
	# th = Freistaat Thueringen
	

	# Sort out who has which holidays
	#
	my %holidays;
	# Common holidays througout Germany
	# 17ju/3okt are added to the list later, during date calculation
	@{$holidays{'common'}} = qw(neuj karf ostm 1mai
		pfim himm wei1 wei2);

	# 500th reformation day in 2017 will be a common federal holiday
	# Deep link to Wikipedia as of today, 2016-01-06:
	# https://de.wikipedia.org/w/index.php?title=Reformationstag&oldid=148889526#Bundesweiter_Feiertag_2017_.28einmalig.29
	if (2017 == $year){
		push @{$holidays{'common'}}, 'refo';
	}

	# Now the extra holidays for the federal states.
	# As if things weren't bad enough, some holidays are only valid
	# in certain parts of single states. These will have to be
	# specified through the ADD parameter.

	# Extras for Baden-Wuerttemberg
	@{$holidays{'bw'}} = qw(hl3k fron alhe);

	# Extras for Bayern
	@{$holidays{'by'}} = qw(hl3k fron alhe);

	# Extras for Berlin
	@{$holidays{'be'}} = qw();
	if ($year >= 2019) {
		push @{$holidays{'be'}}, qw(frau);
	}

	# Extras for Brandenburg
	@{$holidays{'bb'}} = qw(osts pfis refo);

	# Extras for Bremen
	@{$holidays{'hb'}} = qw();
	if ($year >= 2018) {
		push @{$holidays{'hb'}}, qw(refo);
	}

	# Extras for Hamburg
	@{$holidays{'hh'}} = qw();
	if ($year >= 2018) {
		push @{$holidays{'hh'}}, qw(refo);
	}

	# Extras for Hessen
	@{$holidays{'he'}} = qw(fron);

	# Extras for Meck-Pomm
	@{$holidays{'mv'}} = qw(refo);

	# Extras for Niedersachsen
	@{$holidays{'ni'}} = qw();
	if ($year >= 2018) {
		push @{$holidays{'ni'}}, qw(refo);
	}

	# Extras for Nordrhein-Westfalen
	@{$holidays{'nw'}} = qw(fron alhe);

	# Extras for Rheinland-Pfalz
	@{$holidays{'rp'}} = qw(fron alhe);

	# Extras for Saarland
	@{$holidays{'sl'}} = qw(fron mari alhe);

	# Extras for Sachsen
	@{$holidays{'sn'}} = qw(refo buss);

	# Extras for Sachsen-Anhalt
	@{$holidays{'st'}} = qw(hl3k refo);

	# Extras for Schleswig-Holstein
	@{$holidays{'sh'}} = qw();
	if ($year >= 2018) {
		push @{$holidays{'sh'}}, qw(refo);
	}

	# Extras for Thueringen
	@{$holidays{'th'}} = qw(refo);

	# Fixed-date holidays
	#
	my %holiday;
	# New year's day Jan 1
	$holiday{'neuj'} = _date2timestamp($year,  1,  1);

	# Heilige 3 Koenige Jan 6
	$holiday{'hl3k'} = _date2timestamp($year,  1,  6);

	# International Womens Day
	$holiday{'frau'} = _date2timestamp($year,  3,  8);

	# First of May
	$holiday{'1mai'} = _date2timestamp($year,  5,  1);

	# Christmas eve and Christmas Dec 24-26
	$holiday{'heil'} = _date2timestamp($year, 12, 24);
	$holiday{'wei1'} = _date2timestamp($year, 12, 25);
	$holiday{'wei2'} = _date2timestamp($year, 12, 26);

	# Augsburger Friedensfest
	$holiday{'frie'} = _date2timestamp($year,  8,  8);

	# Assumption day Aug 15
	$holiday{'mari'} = _date2timestamp($year,  8, 15);

	# Reunion day Jun 17 (1954-1990)
	if (($year <= 1990) and ($year >= 1954)){
		$holiday{'17ju'} = _date2timestamp($year, 6,  17);
		push @{$holidays{'common'}}, '17ju';
	}

	# Reunion day Oct 3 (since 1990)
	if ($year >= 1990){
		$holiday{'3okt'} = _date2timestamp($year, 10,  3);
		push @{$holidays{'common'}}, '3okt';
	}
	
	# Reformation day Oct 31
	$holiday{'refo'} = _date2timestamp($year, 10, 31);

	# All Hallows Nov 1
	$holiday{'alhe'} = _date2timestamp($year, 11,  1);

	# New Years Eve Dec 31
	$holiday{'silv'} = _date2timestamp($year, 12, 31);

	# Holidays relative to Easter
	#
	# Fat Thursday = Easter Sunday minus 52 days
	my ($j_weib, $m_weib, $t_weib) =
		Date::Calc::Add_Delta_Days($year, $month, $day, -52);
	$holiday{'weib'} = _date2timestamp($j_weib, $m_weib, $t_weib);

	# Carnival Monday = Easter Sunday minus 48 days
	my ($j_romo, $m_romo, $t_romo) =
		Date::Calc::Add_Delta_Days($year, $month, $day, -48);
	$holiday{'romo'} = _date2timestamp($j_romo, $m_romo, $t_romo);

	# Shrove Tuesday = Easter Sunday minus 47 days
	my ($j_fadi, $m_fadi, $t_fadi) =
		Date::Calc::Add_Delta_Days($year, $month, $day, -47);
	$holiday{'fadi'} = _date2timestamp($j_fadi, $m_fadi, $t_fadi);

	#  Ash Wednesday = Easter Sunday minus 46 days
	my ($j_asmi, $m_asmi, $t_asmi) =
		Date::Calc::Add_Delta_Days($year, $month, $day, -46);
	$holiday{'asmi'} = _date2timestamp($j_asmi, $m_asmi, $t_asmi);

	# Maundy Thursday = Easter Sunday minus 3 days
	my ($j_grdo, $m_grdo, $t_grdo) =
		Date::Calc::Add_Delta_Days($year, $month, $day, -3);
	$holiday{'grdo'} = _date2timestamp($j_grdo, $m_grdo, $t_grdo);

	# Good Friday = Easter Sunday minus 2 days
	my ($j_karf, $m_karf, $t_karf) =
		Date::Calc::Add_Delta_Days($year, $month, $day, -2);
	$holiday{'karf'} = _date2timestamp($j_karf, $m_karf, $t_karf);

	# Holy Saturday = Easter Sunday minus 1 day
	my ($j_kars, $m_kars, $t_kars) =
		Date::Calc::Add_Delta_Days($year, $month, $day, -1);
	$holiday{'kars'} = _date2timestamp($j_kars, $m_kars, $t_kars);

	# Easter Sunday is just that
	$holiday{'osts'} = _date2timestamp($year, $month, $day);

	# Easter Monday = Easter Sunday plus 1 day
	my ($j_ostm, $m_ostm, $t_ostm) =
		Date::Calc::Add_Delta_Days($year, $month, $day, 1);
	$holiday{'ostm'} = _date2timestamp($j_ostm, $m_ostm, $t_ostm);

	# Whit Sunday = Easter Sunday plus 49 days
	my ($j_pfis, $m_pfis, $t_pfis) =
		Date::Calc::Add_Delta_Days($year, $month, $day, 49);
	$holiday{'pfis'} = _date2timestamp($j_pfis, $m_pfis, $t_pfis);

	# Whit Monday = Easter Sunday plus 50 days
	my ($j_pfim, $m_pfim, $t_pfim) =
		Date::Calc::Add_Delta_Days($year, $month, $day, 50);
	$holiday{'pfim'} = _date2timestamp($j_pfim, $m_pfim, $t_pfim);

	# Ascension Day = Easter Sunday plus 39 days
	my ($j_himm, $m_himm, $t_himm) =
		Date::Calc::Add_Delta_Days($year, $month, $day, 39);
	$holiday{'himm'} = _date2timestamp($j_himm, $m_himm, $t_himm);

	# Corpus Christi = Easter Sunday plus 60 days
	my ($j_fron, $m_fron, $t_fron) =
		Date::Calc::Add_Delta_Days($year, $month, $day, 60);
	$holiday{'fron'} = _date2timestamp($j_fron, $m_fron, $t_fron);

	# Only one holiday is relative to Christmas
	#
	# Penance day = Sunday before christmas minus 32 days
	# Find sunday before christmas 
	my $tempdate;
	for ($tempdate = 24; $tempdate > 16; $tempdate--){
		my $dow = Day_of_Week($year, 12, $tempdate);
		# 7 is Sunday
		last if (7 == $dow);
		# $tempdate now holds the last sunday before christmas.
	}
	# subtract 32 days from the Dec day stored in $tempdate
	my ($j_buss, $m_buss, $t_buss) =
		Date::Calc::Add_Delta_Days($year, 12, $tempdate, -32);
	$holiday{'buss'} = _date2timestamp($j_buss, $m_buss, $t_buss);

	# store the sundays in advent and the two sundays before
	my $sc=0;
	foreach my $name ("adv4", "adv3", "adv2", "adv1", "toso", "votr") {
		$holiday{$name} = _date2timestamp(
			Date::Calc::Add_Delta_Days($year, 12, $tempdate, 7*$sc--)
		);
	}

	# Build list for returning
	#
	my %holidaylist;
	# See what holidays shall be printed
	my $wantall = 0;
	foreach (@{$parameters{'WHERE'}}){
		if ($_ eq 'all'){
			$wantall = 1;
		}
	}
	if (1 == $wantall){
		# All holidays if 'all' is in the WHERE parameter list.
		%holidaylist = %holiday;
	}else{
		# Only specified regions
		foreach my $scope (@{$parameters{'WHERE'}}){ 
			foreach my $alias(@{$holidays{$scope}}){
				$holidaylist{$alias} = $holiday{$alias};
			}
		}
	}
	# Add the most obscure holidays that were requested through
	# the ADD parameter
	if ($parameters{'ADD'}){
		foreach my $add(@{$parameters{'ADD'}}){
			$holidaylist{$add} = $holiday{$add};
		}
	}

	# If WEEKENDS => 0 was passed, weed out holidays on weekends
	#
	unless (1 == $parameters{'WEEKENDS'}){
		# Walk the list of holidays
		foreach my $alias(keys(%holidaylist)){
			# Get day of week. Since we're no longer
			# in Date::Calc's world, use localtime()
			my $dow = (localtime($holiday{$alias}))[6];
			# dow 6 = Saturday, dow 0 = Sunday
			if ((6 == $dow) or (0 == $dow)){
				# Kick this day from the list
				delete $holidaylist{$alias};
			}
		}
	}

	# Sort values stored in the hash for returning
	#
	my @returnlist;
	foreach(sort{$holidaylist{$a}<=>$holidaylist{$b}}(keys(%holidaylist))){
		# Not all platforms have strftime(%s).
		# Therefore, inject seconds manually into format string.
		my $formatstring = $parameters{'FORMAT'};
		$formatstring =~ s/%{0}%s/$holidaylist{$_}/g;
		# Inject the holiday's alias name into the format string
		# if it was requested by adding %#.
		$formatstring =~ s/%{0}%#/$_/;
		push @returnlist,
			strftime($formatstring, localtime($holidaylist{$_}));
	}
	return \@returnlist;
}

sub _date2timestamp{
	# Turn Date::Calc's y/m/d format into a UNIX timestamp
	my ($y, $m, $d) = @_;
	my $timestamp = timelocal(0,0,0,$d,($m-1),$y);
	return $timestamp;
}

1;
__END__

=head1 NAME

Date::Holidays::DE - Determine German holidays

=head1 SYNOPSIS

  use Date::Holidays::DE qw(holidays);
  my $feiertage_ref = holidays();
  my @feiertage     = @$feiertage_ref;

=head1 DESCRIPTION

This module exports a single function named B<holidays()> which returns a list of 
German holidays in a given year. 

=head1 KNOWN HOLIDAYS

The module knows about the following holidays:

  neuj  Neujahr                     New Year's day
  hl3k  Hl. 3 Koenige               Epiphany
  weib  Weiberfastnacht             Fat Thursday
  romo  Rosenmontag                 Carnival monday
  fadi  Faschingsdienstag           Shrove tuesday
  asmi  Aschermittwoch              Ash wednesday
  frau  Internationaler Frauentag   International Women's day
  grdo  Gruendonnerstag             Maundy Thursday
  karf  Karfreitag                  Good friday
  kars  Karsamstag                  Holy Saturday
  osts  Ostersonntag                Easter sunday
  ostm  Ostermontag                 Easter monday
  pfis  Pfingstsonntag              Whit sunday
  pfim  Pfingstmontag               Whit monday
  himm  Himmelfahrtstag             Ascension day
  fron  Fronleichnam                Corpus christi
  1mai  Maifeiertag                 Labor day, German style 
  17ju  Tag der deutschen Einheit   Reunion day (>= 1954, <= 1990)
  frie  Augsburger Friedensfest     Augsburg peace day
  mari  Mariae Himmelfahrt          Assumption day
  3okt  Tag der deutschen Einheit   Reunion day (>= 1990)
  refo  Reformationstag             Reformation day
  alhe  Allerheiligen               All hallows day
  buss  Buss- und Bettag            Penance day
  votr  Volkstrauertag              Remembrance Day, German Style
  toso  Totensonntag                Sunday in commemoration of the dead
  adv1  1. Advent                   1st sunday in advent
  adv2  2. Advent                   2nd sunday in advent
  adv3  3. Advent                   3rd sunday in advent
  adv4  4. Advent                   4th sunday in advent
  heil  Heiligabend                 Christmas eve
  wei1  1. Weihnachtstag            Christmas
  wei2  2. Weihnachtstag            Christmas
  silv  Silvester                   New year's eve

Please refer to the module source for detailed information about how every 
holiday is calculated. Too much detail would be far beyond the scope of this 
document, but it's not particularly hard once you've found the date for
Easter.

=head1 USAGE

=head2 OUTPUT FORMAT

The list returned by B<holidays()> consists of UNIX-Style timestamps in seconds 
since The Epoch. You may pass a B<strftime()> style format string to get the 
dates in any format you desire:

  my $feiertage_ref = holidays(FORMAT=>"%d.%m.%Y");

Here are a few examples to get you started:

  FORMAT=>"%d.%m.%Y"              25.12.2001
  FORMAT=>"%Y%m%d"                20011225
  FORMAT=>"%a, %B %d"             Tuesday, December 25

Please consult the manual page of B<strftime()> for a complete list of available
format definitions.

There is, however, one "proprietary" extension to the formats of B<strftime()>:
The format definition I<%#> will print the internal abbreviation used for each
holiday. 

  FORMAT=>"%#:%d.%m"              wei1:25.12.

As the module doesn't want to deal with i18n 
issues, you'll have to find your own way to translate the aliases into your 
local language. See the I<example/feiertage.pl> script included in the
distribution to get the idea. This was added in version 0.6. 

=head2 LOCAL HOLIDAYS

The module also knows about different regulations throughout Germany.

When calling B<holidays()>, the resulting list by default contains the list of 
Germany-wide holidays.

You can specify one ore more of the following federal states to get the list of 
holidays local to that state:

  bw  Baden-Wuerttemberg
  by  Freistaat Bayern
  be  Berlin
  bb  Brandenburg
  hb  Freie Hansestadt Bremen
  hh  Freie und Hansestadt Hamburg
  he  Hessen
  mv  Mecklenburg-Vorpommern
  ni  Niedersachsen
  nw  Nordrhein-Westfalen
  rp  Rheinland-Pfalz
  sl  Saarland
  sn  Freistaat Sachsen
  st  Sachsen-Anhalt
  sh  Schleswig-Holstein
  th  Freistaat Thueringen

For example,

  my $feiertage_ref = holidays(WHERE=>['by', 'bw']);

returns the list of holidays local to Bayern or Baden-Wuerttemberg.

To get the list of local holidays along with the default list of common
German holidays, use the following:

  my $feiertage_ref = holidays(WHERE=>['common', 'bw']);

returns the list of common German holidays merged with the list of holidays
specific to Baden-Wuerttemberg.

You can also request a list containing all holidays this module knows about:

  my $feiertage_ref = holidays(WHERE=>['all']);

will return a list of all known holidays. This was added in version 0.6.

=head2 ADDITIONAL HOLIDAYS

There are a number of holidays that aren't really holidays, e.g. New Year's Eve 
and Christmas Eve. These aren't contained in the I<common> set of holidays 
returned by the B<holidays()> function. The aforementioned I<silv> and I<heil> 
are probably the most likely ones that you'll need. If you live in Koeln, you'll
probably want to include I<romo> and I<fadi>, too. ;-)

As if things weren't bad enough already, there even are Holidays that aren't 
valid in an entire state. This refers to I<fron>, I<alhe> and I<mari> in 
particular.

If you want one or several of them to appear in the output from B<holidays()>, 
use the following:

  my $feiertage_ref = holidays(ADD=>['heil', 'silv']);

=head2 SPECIFYING THE YEAR

By default, B<holidays()> returns the holidays for the current year. Specify
a year as follows:

  my $feiertage_ref = holidays(YEAR=>2004);

=head2 HOLIDAYS ON WEEKENDS

By default, B<holidays()> includes Holidays that occur on weekends in its 
listing.

To disable this behaviour, set the I<WEEKENDS> option to 0:

  my $feiertage_ref = holidays(WEEKENDS=>0);

=head1 COMPLETE EXAMPLE

Get all holidays for Germany and Bayern in 2004, count New Year's Eve and 
Christmas Eve as Holidays. Also, we live in a catholic region where Assumption
day is a holiday, too. Exclude weekends and return the date list in human
readable format:

  my $feiertage_ref = holidays( WHERE    => ['common', 'he'],
                                FORMAT   => "%a, %d.%m.%Y",
                                WEEKENDS => 0,
                                YEAR     => 2004,
                                ADD      => ['heil', 'silv', 'mari']);

=head1 PREREQUISITES

Uses B<Date::Calc 5.0> for all calculations. Makes use of the B<POSIX> and 
B<Time::Local> modules from the standard Perl distribution.

=head1 BUGS & SUGGESTIONS

If you run into a miscalculation, need some sort of feature or an additional
holiday, or if you know of any new changes to our funky holiday situation, 
please drop the author a note.

Patches are welcome. If you can, please fork the project on I<github> to
submit your change:

  http://github.com/mschmitt/Date-Holidays-DE

I<Tag der Deutschen Einheit> was moved from June 17th to October 3rd in 1990
and is therefore listed twice when calculating holidays for 1990. This is 
not a bug. Awareness for this was introduced in Version 1.1.

=head1 OFFICIAL HOLIDAY INFORMATION

The German Federal Ministry of the Interior used to publish a comprehensive
list of holiday dates. This does currently not appear to be the case.

=head1 LIMITATIONS

B<Date::Calc> works with year, month and day numbers exclusively. Even though
this module uses B<Date::Calc> for all calculations, it represents the calculated
holidays as UNIX timestamps (seconds since The Epoch) to allow for more
flexible formatting. This limits the range of years to work on to 
the years from 1972 to 2037. 

Historic regulations for I<Buss- und Bettag> are still not implemented.

B<Date::Holidays::DE> is not configurable. Holiday changes don't come over
night and a new module release can be rolled out within a single day.

=head1 AUTHOR

Martin Schmitt E<lt>mas at scsy dot deE<gt>

=head1 SEE ALSO

L<perl>, L<Date::Calc>.

=cut
