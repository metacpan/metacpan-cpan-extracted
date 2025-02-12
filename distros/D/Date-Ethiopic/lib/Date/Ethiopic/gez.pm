package Date::Ethiopic::gez;
use base ( "Date::Ethiopic" );
use utf8;

BEGIN
{
	use strict;
	use warnings;
	use vars qw(
		@Days
		@Months
		@ShortDays
		@ShortMonths
	);

	$VERSION = "0.16";

	@Days =(
		[ "አኀዱ",	"Ahadu"  ],
		[ "ሰኑይ",	"Senuy"  ],
		[ "ሠሉስ",	"Sellus" ],
		[ "ራብዕ",	"Rabi"   ],
		[ "ኃምስ",	"Hamis"  ],
		[ "ዓርበ",	"Arbe"   ],
		[ "ቀዳም",	"Kedam"  ]
	);
	@Months =(
		[ "ከረመ",	"Kereme"  ],
		[ "ጠቀመ",	"Tekeme"  ],
		[ "ኀደረ",	"Hedere"  ],
		[ "ኀሠሠ",	"Hesese"  ],
		[ "ጠሐረ",	"Tehere"  ],  # ጥሕረ
		[ "ከተተ",	"Ketete"  ],
		[ "መገበ",	"Megebe"  ],
		[ "አኀዘ",	"Aheze"   ],
		[ "ግንባት",	"Genbat"  ],
		[ "ሠንየ",	"Senye"   ],
		[ "ሐመለ",	"Hemele"  ],
		[ "ነሐሰ",	"Nehese"  ],
		[ "ጳጕሜን",	"Pagumen" ]
	);
	@ShortDays =(
		[ "አኀዱ",	"Aha" ],  # እኁድ
		[ "ሰኑይ",	"Sen" ],  # ዕብራ
		[ "ሠሉስ",	"Sel" ],  # ምንትው
		[ "ራብዕ",	"Rab" ],  # ረቡዕ
		[ "ኃምስ",	"Ham" ],
		[ "ዓርበ",	"Arb" ],
		[ "ቀዳም",	"Ked" ]   # ቀዳሚት
	);
	@ShortMonths =(
		[ "ከረመ",	"Ker" ],
		[ "ጠቀመ",	"Tek" ],
		[ "ኀደረ",	"Hed" ],
		[ "ኀሠሠ",	"Hes" ],
		[ "ጠሐረ",	"Teh" ],
		[ "ከተተ",	"Ket" ],
		[ "መገበ",	"Meg" ],
		[ "አኀዘ",	"Ahe" ],
		[ "ግንባ",	"Gen" ],
		[ "ሠንየ",	"Sen" ],
		[ "ሐመለ",	"Hem" ],
		[ "ነሐሰ",	"Neh" ],
		[ "ጳጕሜ",	"Pag" ]
	);
}


sub _daysep
{
	($_[0]->{_trans}) ? " Ken " : " ቀን ";
}


sub _sep
{
	($_[0]->{_trans}) ? ", " : "፥ ";
}


sub am
{
	# this is tigrinya
	#
	($_[0]->{_trans}) ? "Neguho se'ate" : "ንጉሆ ሰዓተ";
}


sub pm
{
	# this is tigrinya
	#
	($_[0]->{_trans}) ? "dehir se'at" : "ድሕር ሰዓት";
}


sub name
{
	($_[0]->{_trans}) ? "Ge'ez" : "ግዕዝ";
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

Date::Ethiopic::gez - Ge'ez Calendar Data for L<Date::Ethiopic>.

=head1 DESCRIPTION

The Date::Ethiopic::gez module is a base class for L<Date::Ethiopic::ER::gez>
and L<Date::Ethiopic::ET::gez> and is not intended for independent use.  The
translations for AM and PM are actually Tigrinya.


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

=head1 SEE ALSO

L<Date::Ethiopic::ER::gez>    L<Date::Ethiopic::ET::gez>

=cut
