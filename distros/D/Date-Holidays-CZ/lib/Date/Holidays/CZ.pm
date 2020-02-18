package Date::Holidays::CZ;

use 5.010;

use strict;
use warnings;

use Date::Calc 5.0 qw(Add_Delta_Days Easter_Sunday Day_of_Week This_Year);
use Exporter qw( import );
use POSIX qw(strftime);
use Time::Local;

=encoding utf8

=head1 NAME

Date::Holidays::CZ - Determine Czech holidays



=head1 SYNOPSIS

  use Date::Holidays::CZ qw(holidays);
  my $svatky_ref = holidays();
  my @svatky     = @$svatky_ref;



=head1 DESCRIPTION

This module exports a single function named B<holidays()> which returns a list of 
Czech holidays in a given year. 

=cut

our @EXPORT_OK = qw( holidays );



=head1 VERSION

Version 0.20

=cut

our $VERSION   = '0.20';



=head1 KNOWN HOLIDAYS

=head2 Czech names

The module knows about the following holidays (official names):

  obss Den obnovy samostatného českého státu
  velk Velikonoční pátek
  veln Velikonoční neděle
  velp Velikonoční pondělí
  svpr Svátek práce
  devi Den vítězství
  cyme Den slovanských věrozvěstů Cyrila a Metoděje
  mhus Den upálení mistra Jana Husa
  wenc Den české státnosti
  vzcs Den vzniku samostatného československého státu
  bojs Den boje za svobodu a demokracii
  sted Štědrý den 
  van1 1. svátek vánoční
  van2 2. svátek vánoční

=head2 English names

The module knows about the following holidays (English names):

  obss Restoration Day of the Independent Czech State
  velk Good Friday
  veln Easter Sunday
  velp Easter Monday
  svpr Labor Day
  dvit Liberation Day
  cyme Saints Cyril and Methodius Day
  mhus Jan Hus Day
  wenc Feast of St. Wenceslas (Czech Statehood Day)
  vzcs Independent Czechoslovak State Day
  bojs Struggle for Freedom and Democracy Day
  sted Christmas Eve
  van1 Christmas Day
  van2 Feast of St. Stephen



=head1 USAGE

=head2 OUTPUT FORMAT

The list returned by B<holidays()> consists of UNIX-Style timestamps in seconds 
since The Epoch. You may pass a B<strftime()> style format string to get the 
dates in any format you desire:

  my $svatky_ref = holidays(FORMAT=>"%d.%m.%Y");

Here are a few examples to get you started:

  FORMAT=>"%d.%m.%Y"              25.12.2001
  FORMAT=>"%Y%m%d"                20011225
  FORMAT=>"%a, %B %d"             Tuesday, December 25

Please consult the manual page of B<strftime()> for a complete list of available
format definitions.

There is, however, one "proprietary" extension to the formats of B<strftime()>:
The format definition I<%#> will print the internal abbreviation used for each
holiday. 

  FORMAT=>"%#: %d.%m"             van1: 25.12.

As the module doesn't want to deal with i18n 
issues, you'll have to find your own way to translate the aliases into your 
local language. See the I<example/svatky.pl> script included in the
distribution to get the idea.



=head2 SPECIFYING THE YEAR

By default, B<holidays()> returns the holidays for the current year. Specify
a year as follows:

  my $svatky_ref = holidays(YEAR=>2004);



=head2 HOLIDAYS ON WEEKENDS

By default, B<holidays()> includes Holidays that occur on weekends in its 
listing.

To disable this behaviour, set the I<WEEKENDS> option to 0:

  my $svatky_ref = holidays(WEEKENDS=>0);



=head1 COMPLETE EXAMPLE

Get all holidays in 2004, except those that occur on weekends.
Return the date list in human readable format:

  my $svatky_ref = holidays( FORMAT   => "%a, %d.%m.%Y",
                             WEEKENDS => 0,
                             YEAR     => 2004,
                           );


=head1 PREREQUISITES

Uses L<Date::Calc> for all calculations. Makes use of the L<POSIX> and 
L<Time::Local> modules from the standard Perl distribution.


=head1 FUNCTIONS


=head2 holidays

Returns a list of Czech holidays in a given year.

=cut

sub holidays{
	my %parameters = (
		YEAR     => This_Year(),
		FORMAT   => "%s",
		WEEKENDS => 1,
		@_,
		);

	# Easter is the key to everything
	my ($year, $month, $day) = Easter_Sunday($parameters{'YEAR'});

	# Aliases for holidays
        #
        #  obss Restoration Day of the Independent Czech State
        #  velk Good Friday
        #  veln Easter Sunday
        #  velp Easter Monday
        #  svpr Labor Day
        #  dvit Liberation Day
        #  cyme Saints Cyril and Methodius Day
        #  mhus Jan Hus Day
        #  wenc Feast of St. Wenceslas (Czech Statehood Day)
        #  vzcs Independent Czechoslovak State Day
        #  bojs Struggle for Freedom and Democracy Day
        #  sted Christmas Eve
        #  van1 Christmas Day
        #  van2 Feast of St. Stephen
	#

        #
	# Sort out who has which holidays
	#
	my %holidays;
	# Common holidays throughout the Czech Republic
	@{$holidays{'common'}} = qw( obss velk veln velp svpr dvit
            cyme mhus wenc vzcs bojs sted van1 van2 );

        #
	# Fixed-date holidays
	#
	my %holiday;
	# Jan 1
	$holiday{'obss'} = _date2timestamp($year,  1,  1);

	# May 1
	$holiday{'svpr'} = _date2timestamp($year,  5,  1);

        # Liberation Day
	$holiday{'dvit'} = _date2timestamp($year,  5,  8);

        # Saints Cyril and Methodius Day
	$holiday{'cyme'} = _date2timestamp($year,  7,  5);

        # Jan Hus Day
	$holiday{'mhus'} = _date2timestamp($year,  7,  6);

        # Feast of St. Wenceslas (Czech Statehood Day)
	$holiday{'wenc'} = _date2timestamp($year,  9, 28);

        # Independent Czechoslovak State Day
	$holiday{'vzcs'} = _date2timestamp($year, 10, 28);

        # Struggle for Freedom and Democracy Day
	$holiday{'bojs'} = _date2timestamp($year, 11, 17);

	# Christmas eve and Christmas Dec 25-26
	$holiday{'sted'} = _date2timestamp($year, 12, 24);
	$holiday{'van1'} = _date2timestamp($year, 12, 25);
	$holiday{'van2'} = _date2timestamp($year, 12, 26);

        #
	# Holidays relative to Easter
	#

	# Easter Sunday is just that
	$holiday{'veln'} = _date2timestamp($year, $month, $day);

	# Easter Monday = Easter Sunday plus 1 day
	my ($y_velp, $m_velp, $d_velp) =
		Date::Calc::Add_Delta_Days($year, $month, $day, 1);
	$holiday{'velp'} = _date2timestamp($y_velp, $m_velp, $d_velp);

        # Good Friday = Easter Sunday minus 2 days
        if ($year >= 2016) {
            my ($y_velk, $m_velk, $d_velk) =
                Date::Calc::Add_Delta_Days($year, $month, $day, -2);
            $holiday{'velk'} = _date2timestamp($y_velk, $m_velk, $d_velk);
        }

        #
	# Build list for returning
	#
	my %holidaylist = %holiday;

        #
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

        #
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


=head1 BUGS & SUGGESTIONS

If you run into a miscalculation, need some sort of feature or an additional
holiday, or if you know of any new changes to our funky holiday situation, 
please drop the author a note.

Patches are welcome. If you can, please fork the project on I<github> to
submit your change:

  http://github.com/smithfarm/Date-Holidays-CZ



=head1 OFFICIAL HOLIDAY INFORMATION

The authority for Czech holidays is the Parliament of the Czech Republic,
which sets the holidays by decree of law.

The official list of list of Czech holidays is available at:

  http://www.mpsv.cz/cs/74



=head1 LIMITATIONS

B<Date::Calc> works with year, month and day numbers exclusively. Even though
this module uses B<Date::Calc> for all calculations, it represents the calculated
holidays as UNIX timestamps (seconds since The Epoch) to allow for more
flexible formatting. This limits the range of years to work on to 
the years from 1972 to 2037. 

B<Date::Holidays::CZ> is not configurable. Holiday changes don't come overnight 
and a new module release can be rolled out within a single day.



=head1 AUTHOR

Nathan Cutler <ncutler@suse.com>



=head1 LICENSE

The code in this module is based heavily on Date::Holidays::DE version 0.16 by
Martin Schmitt. That code is governed by the following license:

    Copyright (c) 2012, Martin Schmitt <mas at scsy dot de>, 
    including patches contributed by Marc Andre Selig, Oliver Paukstadt,
    Tobias Leich and Christian Loos
  
    Permission to use, copy, modify, and/or distribute this software for any
    purpose with or without fee is hereby granted, provided that the above
    copyright notice and this permission notice appear in all copies.
  
    THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
    WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
    MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
    ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
    WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
    ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
    OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

All modifications to the original Date::Holidays::DE code, as well as all new
code, are governed by the following:

    Copyright (c) 2015-2020, SUSE LLC
    All rights reserved.
  
    This is free software, licensed under:
  
      The (three-clause) BSD License
  
    The BSD License
  
    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are
    met:
  
      * Redistributions of source code must retain the above copyright
        notice, this list of conditions and the following disclaimer.
  
      * Redistributions in binary form must reproduce the above copyright
        notice, this list of conditions and the following disclaimer in the
        documentation and/or other materials provided with the distribution. 
  
      * Neither the name of SUSE LLC nor the names of its contributors may 
        be used to endorse or promote products derived from this software 
        without specific prior written permission. 
  
    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
    IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
    TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
    PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER 
    OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
    EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
    PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
    PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
    LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
    NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.



=head1 SEE ALSO

L<perl>, L<Date::Calc>.

=cut

1;
