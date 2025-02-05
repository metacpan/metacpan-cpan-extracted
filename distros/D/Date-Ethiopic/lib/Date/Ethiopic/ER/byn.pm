package Date::Ethiopic::ER::byn;
use base ( "Date::Ethiopic::ER", "Date::Ethiopic" );
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
		[ "ሰንበር ቅዳዅ",	"Senber Kidakwu"   ],
		[ "ሰኑ", 	"Senu"             ],
		[ "ሰሊጝ",	"Selling"          ],
		[ "ለጓ ወሪ ለብዋ",	"Legwa Weri Lebwa" ],
		[ "ኣምድ",	"Amid"             ],
		[ "ኣርብ",	"Arb"              ],
		[ "ሰንበር ሽጓዅ",	"Senber Shigwakwu" ]
	);
	@Months =(
		[ "ያኸኒ መሳቅለሪ",		"Yakheni Mesakleri"  ],
		[ "መተሉ",		"Metelu"             ],
		[ "ምኪኤል መሽወሪ",		"Michael Meshweri"   ],
		[ "ተሕሳስሪ",		"Tahsasri"           ],
		[ "ልደትሪ",		"Lidetri"            ],
		[ "ካብኽብቲ",		"Kebakhibti"         ],
		[ "ክብላ",		"Kibla"              ],
		[ "ፋጅኺሪ",		"Fajkhiri"           ],
		[ "ክቢቅሪ",		"Kibikri"            ],
		[ "ምኪኤል ት(ጝዋ)ኒሪ",	"Michael Tingwaniri" ],
		[ "ኰርኩ",		"Kwerku"             ],
		[ "ማርያም ትሪ",		"Mariam Tiri"        ],
		[ "ጓቁመ",		"Gwakume"            ]
	);
	@ShortDays =(
		[ "ሰ/ቅ",	"S/K" ],
		[ "ሰኑ ",	"Sen" ],
		[ "ሰሊጝ",	"Sel" ],
		[ "ለጓ ",	"Leg" ],
		[ "ኣምድ",	"Ami" ],
		[ "ኣርብ",	"Arb" ],
		[ "ሰ/ሽ",	"S/S" ]
	);
	@ShortMonths =(
		[ "ያኸኒ",	"Yak" ],
		[ "መተሉ",	"Met" ],
		[ "ም/መ",	"M/M" ],
		[ "ተሕሳ",	"Tah" ],
		[ "ልደት",	"Lid" ],
		[ "ካብኽ",	"Keb" ],
		[ "ክብላ",	"Kib" ],
		[ "ፋጅኺ",	"Faj" ],
		[ "ክቢቅ",	"Kbk" ],
		[ "ም/ት",	"M/T" ],
		[ "ኰርኩ",	"Kwe" ],
		[ "ማርያ",	"Mar" ],
		[ "ጓቁመ",	"Gwa" ]
	);
}


sub _daysep
{
	($_[0]->{_trans}) ? " Girga " : " ግርጋ ";
}


sub am
{
	($_[0]->{_trans}) ? "fj" : "ፍጅ";
}


sub pm
{
	($_[0]->{_trans}) ? "fd" : "ፍድ";
}


sub name
{
	($_[0]->{_trans}) ? "Blin" : "ብሊን";
}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__



=head1 NAME

Date::Ethiopic::ER::byn - Blin Calendar Data for L<Date::Ethiopic>.

=head1 SYNOPSIS

 use Date::Ethiopic::ER::byn;
 #
 #  typical instantiation:
 #
 my $byn = new Date::Ethiopic::ER::byn ( ical => '19950629' );

 #
 # Print Blin day and month names:
 #
 print "  Day   Name: ", $byn->day_name, "\n";
 print "  Month Name: ", $byn->month_name, "\n";

 #
 # POSIX long date format:
 #
 print "  Long  Date: ", $byn->long_date, "\n";
 print "  Long  Date: ", $byn->long_date('ethio'), "\n";

 #
 # POSIX full date format:
 #
 print "  Full  Date: ", $byn->full_date, "\n";
 #
 # Convert all numbers into Ethiopic:
 #
 print "  Full  Date: ", $byn->full_date('ethio'), "\n";

 #
 # Turn transcription on:
 #
 $byn->useTranscription ( 1 );
 print "  Full  Date: ", $byn->full_date, "\n";

 #
 # Turn transcription off:
 #
 $byn->useTranscription ( 0 );
 print "  Full  Date: ", $byn->full_date, "\n";

=head1 DESCRIPTION

The Date::Ethiopic::ER::byn module provides methods for accessing date information
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
