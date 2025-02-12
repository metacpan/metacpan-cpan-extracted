package Date::Ethiopic::ET::har;
use base ( "Date::Ethiopic::ET", "Date::Ethiopic" );
use utf8;

BEGIN
{
	use strict;
	use warnings;
	use vars qw(
		@Days
		@ShortDays
	);

	$VERSION = "0.16";

	@Days =(
		[ "አልሓድ",	"Alhad"  ],
		[ "ኢስኒን",	"Isnin"  ],
		[ "ሰላሣ",	"Selasa" ],
		[ "አርብአ",	"Arbaa"  ],
		[ "ከሚስ",	"Khamis" ],
		[ "ጁምአ",	"Juma"   ],
		[ "ሰብቲ",	"Sebti"  ]
	);
	@ShortDays =(
		[ "አልሓ",	"Alh" ],
		[ "ኢስኒ",	"Isn" ],
		[ "ሰላሣ",	"Sel" ],
		[ "አርብ",	"Arb" ],
		[ "ከሚስ",	"Kha" ],
		[ "ጁምአ",	"Jum" ],
		[ "ሰብቲ",	"Seb" ]
	);
}


sub _daysep
{
	($_[0]->{_trans}) ? " Ayam " : " አያም ";
}


sub am
{
	($_[0]->{_trans}) ? "soza" : "ሶዛ";
}


sub pm
{
	($_[0]->{_trans}) ? "salat baher" : "ሳላት ባሕር";
}


sub name
{
	($_[0]->{_trans}) ? "Harari" : "አደርኛ";
}


sub month_name
{
my ($self) = shift;

	$self->SUPER::month_name ( @_ );
}


sub short_month_name
{
my ($self) = shift;

	$self->SUPER::short_month_name ( @_ );
}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__



=head1 NAME

Date::Ethiopic::ET::har - Harari Calendar Data for L<Date::Ethiopic>.

=head1 SYNOPSIS

 use Date::Ethiopic::ET::har;
 #
 #  typical instantiation:
 #
 my $har = new Date::Ethiopic::ET::har ( ical => '19950629' );

 #
 # Print Harari day and month names:
 #
 print "  Day   Name: ", $har->day_name, "\n";
 print "  Month Name: ", $har->month_name, "\n";

 #
 # POSIX long date format:
 #
 print "  Long  Date: ", $har->long_date, "\n";
 print "  Long  Date: ", $har->long_date('ethio'), "\n";

 #
 # POSIX full date format:
 #
 print "  Full  Date: ", $har->full_date, "\n";
 #
 # Convert all numbers into Ethiopic:
 #
 print "  Full  Date: ", $har->full_date('ethio'), "\n";

 #
 # Turn transcription on:
 #
 $har->useTranscription ( 1 );
 print "  Full  Date: ", $har->full_date, "\n";

 #
 # Turn transcription off:
 #
 $har->useTranscription ( 0 );
 print "  Full  Date: ", $har->full_date, "\n";

=head1 DESCRIPTION

The Date::Ethiopic::ET::har module provides methods for accessing date information
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
