package Date::Ethiopic::ET;
use utf8;

BEGIN
{
	require 5.000;

	use strict;
	use warnings;
	use vars qw(
		@Days
		@Months
		@ShortDays
		@ShortMonths

		%EthiopianHolidays
		%EthiopianHolidaysTranscribed
	);

	$VERSION = "0.15";

	#
	# Legal Holidays, this will be localized later.
	# Some verification is also needed.
	#
	# double check how leap year impacts christmas, my memory
	# is that is moves backwars 29->28 following leap year
	# such that it fixes on Jan. 7.
	#
	%EthiopianHolidays =(
		"እንቍጣጣሽ"		=>   [1,1],  #  መስከረም   1
		"የመስቀል በዓል"		=>  [17,1],  #  መስከረም  17
		"ገና"			=>  [29,4],  #  ታኅሣሥ   29/28 ?
		"ጥምቀት"			=>  [11,5],  #  ጥር     11
		"አድዋ ድል መታሰቢያ"		=>  [23,6],  #  የካቲት   23
		"የስቅለት በዓል"		=> ['?',8],  #  ሚያዝያ -Final Friday
		"የትንሣኤ በዓል"		=> ['?',8],  #  ሚያዝያ -Final Sunday
		"የዓለም ላባደሮች ቀን"		=>  [23,8],  #  May     1
		"የኢትዮጵያ አርበኞች ቀን"	=>  [27,8],  #  ሚያዝያ   27
		"ደርግ የወደቀበት"		=>  [20,9]   #  ግንቦት   20
	);
	%EthiopianHolidaysTranscribed =(
	);
	@Days =(
		[ "እሑድ",	"Ehud"     ],
		[ "ሰኞ", 	"Sanyo"    ],
		[ "ማክሰኞ",	"Maksanyo" ],
		[ "ረቡዕ",	"Rub"      ],
		[ "ሐሙስ",	"Hamus"    ],
		[ "ዓርብ",	"Arb"      ],
		[ "ቅዳሜ",	"Kidame"   ]
	);
	@Months =(
		[ "መስከረም",	"Meskerem" ],
		[ "ጥቅምት",	"Tekemt"   ],
		[ "ኅዳር",	"Hedar"    ],
		[ "ታኅሣሥ",	"Tahsas"   ],
		[ "ጥር", 	"Ter"      ],
		[ "የካቲት",	"Yekatit"  ],
		[ "መጋቢት",	"Megabit"  ],
		[ "ሚያዝያ",	"Miazia"   ],
		[ "ግንቦት",	"Genbot"   ],
		[ "ሰኔ", 	"Sene"     ],
		[ "ሐምሌ",	"Hamle"    ],
		[ "ነሐሴ",	"Nehasse"  ],
		[ "ጳጉሜን",	"Pagumen"  ]
	);
	@ShortDays =(
		[ "እሑድ",	"Ehu" ],
		[ "ሰኞ ",	"San" ],
		[ "ማክሰ",	"Mak" ],
		[ "ረቡዕ",	"Rub" ],
		[ "ሐሙስ",	"Ham" ],
		[ "ዓርብ",	"Arb" ],
		[ "ቅዳሜ",	"Kid" ]
	);
	@ShortMonths =(
		[ "መስከ",	"Mes" ],
		[ "ጥቅም",	"Tek" ],
		[ "ኅዳር",	"Hed" ],
		[ "ታኅሣ",	"Tah" ],
		[ "ጥር ",	"Ter" ],
		[ "የካቲ",	"Yek" ],
		[ "መጋቢ",	"Meg" ],
		[ "ሚያዝ",	"Mia" ],
		[ "ግንቦ",	"Gen" ],
		[ "ሰኔ ",	"Sen" ],
		[ "ሐምሌ",	"Ham" ],
		[ "ነሐሴ",	"Neh" ],
		[ "ጳጉሜ",	"Pag" ]
	);
}


sub _sep
{
	($_[0]->{_trans}) ? ", " : "፣ ";
}


sub am
{
	"AM";
}


sub pm
{
	"PM";
}


sub bc
{
	($_[0]->{_trans}) ? "A/A" : "ዓ/ዓ";
}


sub ad
{
	($_[0]->{_trans}) ? "A/M" : "ዓ/ም";
}


sub day_name
{
my ( $self, $day ) = @_;

	$day ||= $self->_EthiopicToAbsolute;

	$day %= 7;

	$Days[$day][$self->{_trans}];
}


sub short_day_name
{
my ( $self, $day ) = @_;

	$day ||= $self->_EthiopicToAbsolute;

	$day %= 7;

	$ShortDays[$day][$self->{_trans}];
}


sub month_name
{
my ( $self, $month ) = @_;

	$month ||= $self->month;

	$month -= 1;
	
	$Months[$month][$self->{_trans}];
}


sub short_month_name
{
my ( $self, $month ) = @_;

	$month ||= $self->month;

	$month -= 1;
	
	$ShortMonths[$month][$self->{_trans}];
}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__



=head1 NAME

Date::Ethiopic::ET - Ethiopian Calendar Data for L<Date::Ethiopic>.

=head1 DESCRIPTION

The Date::Ethiopic::ET module is a base class for modules under
the Date::Ethiopic::ET namespace, it is not intended for independent use.

=head1 CREDITS

Yeha: L<http://yeha.sourceforge.net>

=head1 REQUIRES

Date::Ethiopic, which is distributed in the same package with
this file.

=head1 BUGS

The use of "use utf8" will break for older versions of Perl.  Feel free
to comment out this line.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2003-2025, Daniel Yacob C<< <dyacob@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
