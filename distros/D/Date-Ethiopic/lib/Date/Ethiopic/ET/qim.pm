package Date::Ethiopic::ET::qim;
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
		[ "ህየሲንቢት",	"Hyesinbit"   ],
		[ "ሲኑ", 	"Sinu"        ],
		[ "ሲልዝ",	"Silz"        ],
		[ "ኦርቭ",	"Orv"         ],
		[ "ክሊዚያ",	"Cliziya"     ],
		[ "ኦርቮ",	"Orvo"        ],
		[ "ቅዳንሲንቢት",	"Kidansinbit" ]
	);
	@Months =(
		[ "ሚስክሩም",	"Miskrum"   ],
		[ "ጥቅምት",	"Tekemt"    ],
		[ "ህዳር",	"Hedar"     ],
		[ "ታህሳስ",	"Tahsas"    ],
		[ "ጥር", 	"Ter"       ],
		[ "የካቲት",	"Yekatit"   ],
		[ "መጋቢት",	"Megabit"   ],
		[ "ሚያዝያ",	"Miazia"    ],
		[ "ግንቦት",	"Genbot"    ],
		[ "ሰኔ", 	"Sene"      ],
		[ "ሀመል",	"Hamel"     ],
		[ "ናሀሽ",	"Nahash"    ],
		[ "ጳጉሜን",	"Pagumeyen" ]
	);
	@ShortDays =(
		[ "ህየሲ",	"Hye" ],
		[ "ሲኑ ",	"Sin" ],
		[ "ሲልዝ",	"Sil" ],
		[ "ኦርቭ",	"Orv" ],
		[ "ክሊዚ",	"Cli" ],
		[ "ኦርቮ",	"Orv" ],
		[ "ቅዳን",	"Kid" ]
	);
	@ShortMonths =(
		[ "ሚስክ",	"Mis" ],
		[ "ጥቅም",	"Tek" ],
		[ "ህዳር",	"Hed" ],
		[ "ታህሳ",	"Tah" ],
		[ "ጥር ",	"Ter" ],
		[ "የካቲ",	"Yek" ],
		[ "መጋቢ",	"Meg" ],
		[ "ሚያዝ",	"Mia" ],
		[ "ግንቦ",	"Gen" ],
		[ "ሰኔ ",	"Sen" ],
		[ "ሀመል",	"Ham" ],
		[ "ናሀሽ",	"Nah" ],
		[ "ጳጉሜ",	"Pag" ]
	);
}


sub _daysep
{
	($_[0]->{_trans}) ? " Gira " : " ጊረ ";
}


sub am
{
	($_[0]->{_trans}) ? "Keshin" : "ቅሽን";
}


sub pm
{
	($_[0]->{_trans}) ? "Leatiza" : "ለአቲዛ";
}

sub name
{

	($_[0]->{_trans}) ? "Agaw" : "ህምራ";
}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__



=head1 NAME

Date::Ethiopic::ET::qim - Agaw Calendar Data for L<Date::Ethiopic>.

=head1 SYNOPSIS

 use Date::Ethiopic::ET::qim;
 #
 #  typical instantiation:
 #
 my $qim = new Date::Ethiopic::ET::qim ( ical => '19950629' );

 #
 # Print Agaw day and month names:
 #
 print "  Day   Name: ", $qim->day_name, "\n";
 print "  Month Name: ", $qim->month_name, "\n";

 #
 # POSIX long date format:
 #
 print "  Long  Date: ", $qim->long_date, "\n";
 print "  Long  Date: ", $qim->long_date('ethio'), "\n";

 #
 # POSIX full date format:
 #
 print "  Full  Date: ", $qim->full_date, "\n";
 #
 # Convert all numbers into Ethiopic:
 #
 print "  Full  Date: ", $qim->full_date('ethio'), "\n";

 #
 # Turn transcription on:
 #
 $qim->useTranscription ( 1 );
 print "  Full  Date: ", $qim->full_date, "\n";

 #
 # Turn transcription off:
 #
 $qim->useTranscription ( 0 );
 print "  Full  Date: ", $qim->full_date, "\n";

=head1 DESCRIPTION

The Date::Ethiopic::ET::qim module provides methods for accessing date information
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
