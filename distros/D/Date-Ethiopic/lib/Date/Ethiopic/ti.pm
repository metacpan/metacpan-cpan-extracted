package Date::Ethiopic::ti;
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

	#@OldDays =(
	#	"ሰንበት",
	#	"ሰኑይ",
	#	"ሠሉስ",
	#	"ረቡዕ",
	#	"ኃሙስ",
	#	"ዓርቢ",
	#	"ቀዳም"
	#);
	@Days =(
		[ "ሰንበት",	"Sennebet" ],
		[ "ሰኑይ",	"Senoi"    ],
		[ "ሰሉስ",	"Sellus"   ],
		[ "ረቡዕ",	"Rebu"     ],
		[ "ሓሙስ",	"Hamus"    ],
		[ "ዓርቢ",	"Arbi"     ],
		[ "ቀዳም",	"Kidam"    ]
	);
	@Months =(
		[ "መስከረም",	"Meskerem" ],
		[ "ጥቅምቲ",	"Tekemti"  ],
		[ "ሕዳር",	"Hedar"    ],
		[ "ታሕሳስ",	"Tahsas"   ],
		[ "ጥሪ", 	"Teri"     ],
		[ "ለካቲት",	"Lekatit"  ],
		[ "መጋቢት",	"Megabit"  ],
		[ "ሚያዝያ",	"Miazia"   ],
		[ "ግንቦት",	"Genbot"   ],
		[ "ሰነ", 	"Sene"     ],
		[ "ሓምለ",	"Hamle"    ],
		[ "ነሓሰ",	"Nehasse"  ],
		[ "ጳጉሜን",	"Pagumen"  ]
	);
	@ShortDays =(
		[ "ሰንበ",	"Snb" ],
		[ "ሰኑይ",	"Sno" ],
		[ "ሰሉስ",	"Sel" ],
		[ "ረቡዕ",	"Reb" ],
		[ "ሓሙስ",	"Ham" ],
		[ "ዓርቢ",	"Arb" ],
		[ "ቀዳም",	"Kid" ]
	);
	@ShortMonths =(
		[ "መስከ",	"Mes" ],
		[ "ጥቅም",	"Tek" ],
		[ "ሕዳር",	"Hed" ],
		[ "ታሕሳ",	"Tah" ],
		[ "ጥሪ ",	"Ter" ],
		[ "ለካቲ",	"Lek" ],
		[ "መጋቢ",	"Meg" ],
		[ "ሚያዝ",	"Mia" ],
		[ "ግንቦ",	"Gen" ],
		[ "ሰነ ",	"Sen" ],
		[ "ሓምለ",	"Ham" ],
		[ "ነሓሰ",	"Neh" ],
		[ "ጳጉሜ",	"Pag" ]
	);
}


sub _daysep
{
	($_[0]->{_trans}) ? " Me'alti " : " መዓልቲ "; # ዕለት
}


sub am
{
	($_[0]->{_trans}) ? "Neguho se'ate" : "ንጉሆ ሰዓተ";
}


sub pm
{
	($_[0]->{_trans}) ? "dehir se'at" : "ድሕር ሰዓት";
}


sub name
{
	($_[0]->{_trans}) ? "Tigrinya" : "ትግርኛ";
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

Date::Ethiopic::ti - Tigrinya Calendar Data for L<Date::Ethiopic>.

=head1 DESCRIPTION

The Date::Ethiopic::ti module is a base class for L<Date::Ethiopic::ER::ti>
and L<Date::Ethiopic::ET::ti> and is not intended for independent use.


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

L<Date::Ethiopic::ER::ti>    L<Date::Ethiopic::ET::ti>

=cut
