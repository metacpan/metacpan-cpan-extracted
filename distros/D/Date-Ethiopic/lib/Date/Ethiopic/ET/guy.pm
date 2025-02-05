package Date::Ethiopic::ET::guy;
use base ( "Date::Ethiopic::ET", "Date::Ethiopic" );
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

	$VERSION = "0.14";

	@Days =(
		[ "ውርሰምበት",	"Wirsenbet"    ],
		[ "ውጠት",	"Witet"        ],
		[ "ወጠት መረጋ",	"Witet Merega" ], # መገርገብያ
		[ "ኧሮ", 	"Ero"          ], # ኧረው
		[ "አ(ምወ)ስ",	"Amwes"        ], # ኸሚስ  amWes but mWe isn't in Unicode
		[ "ጅማት",	"Jimat"        ], # አዳረ
		[ "ቀጣ ሰምበት",	"Ketta Sembet" ]
	);
	@Months =(
		[ "ይዳር",	"Yidar"    ],
		[ "መሸ", 	"Mesh"     ],
		[ "ጥርር",	"Terir"    ], # እንተጐጐት
		[ "መንገስ",	"Menges"   ],
		[ "ወቶ", 	"Weto"     ],
		[ "ማንዝያ",	"Manziya"  ],
		[ "ግር(ምወ)ት",	"Germwet"  ], # (mWe) is not in unicode
		[ "ሰርየ",	"Serye"    ],
		[ "ናሴ", 	"Nasie"    ],
		[ "አምሬ",	"Amro"     ],
		[ "መስኸሮ",	"Meskhero" ],
		[ "ጥቅምት",	"Tekemt"   ],
		[ "",    	""         ]
	);
	@ShortDays =(
		[ "ግድር",	"Gid" ],
		[ "ውጠት",	"Wit" ],
		[ "መገር",	"Jeg" ],
		[ "ሐርሴ",	"Her" ],
		[ "ከምስ",	"Kem" ],
		[ "ጅማት",	"Jim" ],
		[ "አሰን",	"Ase" ]
	);
	@ShortMonths =(
		[ "ይዳር",	"Yid" ],
		[ "መሸ ",	"Msh" ],
		[ "ጥርር",	"Ter" ],
		[ "መንገ",	"Men" ],
		[ "ወቶ ",	"Wet" ],
		[ "ማንዝ",	"Man" ],
		[ "ግርም",	"Ger" ],
		[ "ሰርየ",	"Ser" ],
		[ "ናሴ ",	"Nas" ],
		[ "አምሬ",	"Amr" ],
		[ "መስኸ",	"Mes" ],
		[ "ጥቅም",	"Tek" ],
		[ "",   	""    ]
	);
}


sub _daysep
{
	($_[0]->{_trans}) ? " Kere " : " ከረ ";
}


sub name
{
	($_[0]->{_trans}) ? "Sebatbeit" : "ሰባትቤት";
}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__



=head1 NAME

Date::Ethiopic::ET::guy - Sebatbeit Calendar Data for L<Date::Ethiopic>.

=head1 SYNOPSIS

 use Date::Ethiopic::ET::guy;
 #
 #  typical instantiation:
 #
 my $guy = new Date::Ethiopic::ET::guy ( ical => '19950629' );

 #
 # Print Sebatbeit day and month names:
 #
 print "  Day   Name: ", $guy->day_name, "\n";
 print "  Month Name: ", $guy->month_name, "\n";

 #
 # POSIX long date format:
 #
 print "  Long  Date: ", $guy->long_date, "\n";
 print "  Long  Date: ", $guy->long_date('ethio'), "\n";

 #
 # POSIX full date format:
 #
 print "  Full  Date: ", $guy->full_date, "\n";
 #
 # Convert all numbers into Ethiopic:
 #
 print "  Full  Date: ", $guy->full_date('ethio'), "\n";

 #
 # Turn transcription on:
 #
 $guy->useTranscription ( 1 );
 print "  Full  Date: ", $guy->full_date, "\n";

 #
 # Turn transcription off:
 #
 $guy->useTranscription ( 0 );
 print "  Full  Date: ", $guy->full_date, "\n";

=head1 DESCRIPTION

The Date::Ethiopic::ET::guy module provides methods for accessing date information
in the Ethiopic calendar system.  The module will also convert dates to
and from the Gregorian system.


=head1 CREDITS

Yeha: L<http://yeha.sourceforge.net>

=head1 REQUIRES

Date::Ethiopic, which is distributed in the same package with
this file.

=head1 BUGS

None presently known.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2003-2025, Daniel Yacob C<< <dyacob@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 SEE ALSO

The Yeha Project: L<http://yeha.sourceforge.net>

=cut
