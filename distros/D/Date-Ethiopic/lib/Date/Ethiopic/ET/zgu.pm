package Date::Ethiopic::ET::zgu;
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

	$VERSION = "0.15";

	@Days =(
		[ "ግድርሰንበት",	"Gidrisenbet" ],
		[ "ውጠት",	"Witet"       ],
		[ "መገርገቢያ",	"Jegergebiya" ],
		[ "ሐርሴ",	"Hersie"      ],
		[ "ከምስ",	"Kemis"       ],
		[ "ጅማት",	"Jimat"       ],
		[ "አሰንበት",	"Asenbet"     ]
	);
	@Months =(
		[ "እዳር",	"Idar"    ], # ህዳር
		[ "መሼ", 	"Meshie"  ],
		[ "እንቶጎት",	"Intogot" ],
		[ "መንገሥ",	"Menges"  ],
		[ "ወቶ", 	"Weto"    ],
		[ "ማዜ", 	"Mazie"   ],
		[ "አስሬ",	"Asrie"   ],
		[ "ሰኜ", 	"Segnie"  ],
		[ "አምሌ",	"Amlie"   ], # ሐምሌ
		[ "ናሴ", 	"Nasie"   ],
		[ "መስሮ",	"Meshro"  ],
		[ "ጥቅምት",	"Tekemt"  ],
		[ "ቃግሜ",	"Kagmie"  ]  # ቃቅሜ
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
		[ "እዳር",	"Ida" ],
		[ "መሼ ",	"Mes" ],
		[ "እንቶ",	"Int" ],
		[ "መንገ",	"Men" ],
		[ "ወቶ ",	"Wet" ],
		[ "ማዜ ",	"Maz" ],
		[ "አስሬ",	"Asr" ],
		[ "ሰኜ ",	"Seg" ],
		[ "አምሌ",	"Aml" ],
		[ "ናሴ", 	"Nas" ],
		[ "መስሮ",	"Mes" ],
		[ "ጥቅም",	"Tek" ],
		[ "ቃግሜ",	"Kag" ]
	);
}


sub _daysep
{
	($_[0]->{_trans}) ? " Malit " : " ማልት ";
}


sub name
{
	($_[0]->{_trans}) ? "Siltie" : "ስልጤ";
}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__



=head1 NAME

Date::Ethiopic::ET::zgu - Siltie Calendar Data for L<Date::Ethiopic>.

=head1 SYNOPSIS

 use Date::Ethiopic::ET::zgu;
 #
 #  typical instantiation:
 #
 my $zgu = new Date::Ethiopic::ET::zgu ( ical => '19950629' );

 #
 # Print Siltie day and month names:
 #
 print "  Day   Name: ", $zgu->day_name, "\n";
 print "  Month Name: ", $zgu->month_name, "\n";

 #
 # POSIX long date format:
 #
 print "  Long  Date: ", $zgu->long_date, "\n";
 print "  Long  Date: ", $zgu->long_date('ethio'), "\n";

 #
 # POSIX full date format:
 #
 print "  Full  Date: ", $zgu->full_date, "\n";
 #
 # Convert all numbers into Ethiopic:
 #
 print "  Full  Date: ", $zgu->full_date('ethio'), "\n";

 #
 # Turn transcription on:
 #
 $zgu->useTranscription ( 1 );
 print "  Full  Date: ", $zgu->full_date, "\n";

 #
 # Turn transcription off:
 #
 $zgu->useTranscription ( 0 );
 print "  Full  Date: ", $zgu->full_date, "\n";

=head1 DESCRIPTION

The Date::Ethiopic::ET::zgu module provides methods for accessing date information
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
