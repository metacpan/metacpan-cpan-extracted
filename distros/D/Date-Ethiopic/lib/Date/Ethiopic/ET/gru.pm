package Date::Ethiopic::ET::gru;
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
		[ "ውርሰንበት",	"Wirsenbet"   ],
		[ "ውጠት",	"Witet"       ],
		[ "መናግ",	"Menag"       ],
		[ "ኧሮብ",	"Erob"        ],
		[ "ሐሙስ",	"Hemus"       ],
		[ "ዓዳረ",	"Adare"       ],
		[ "ቅዳምሰንበት",	"Qidamsenbet" ]
	);
	@ShortDays =(
		[ "ውርሰ",	"Wir" ],
		[ "ውጠት",	"Wit" ],
		[ "መናግ",	"Men" ],
		[ "ኧሮብ",	"Ero" ],
		[ "ሐሙስ",	"Hem" ],
		[ "ዓዳረ",	"Ada" ],
		[ "ቅዳም",	"Qid" ]
	);
}


sub _daysep
{
	($_[0]->{_trans}) ? " Malit " : " ማልት ";
}


sub name
{
	($_[0]->{_trans}) ? "Sodo" : "ሶዶ";
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

Date::Ethiopic::ET::gru - Sodo Calendar Date for L<Date::Ethiopic>.

=head1 SYNOPSIS

 use Date::Ethiopic::ET::gru;
 #
 #  typical instantiation:
 #
 my $gru = new Date::Ethiopic::ET::gru ( ical => '19950629' );

 #
 # Print Sodo day and month names:
 #
 print "  Day   Name: ", $gru->day_name, "\n";
 print "  Month Name: ", $gru->month_name, "\n";

 #
 # POSIX long date format:
 #
 print "  Long  Date: ", $gru->long_date, "\n";
 print "  Long  Date: ", $gru->long_date('ethio'), "\n";

 #
 # POSIX full date format:
 #
 print "  Full  Date: ", $gru->full_date, "\n";
 #
 # Convert all numbers into Ethiopic:
 #
 print "  Full  Date: ", $gru->full_date('ethio'), "\n";

 #
 # Turn transcription on:
 #
 $gru->useTranscription ( 1 );
 print "  Full  Date: ", $gru->full_date, "\n";

 #
 # Turn transcription off:
 #
 $gru->useTranscription ( 0 );
 print "  Full  Date: ", $gru->full_date, "\n";

=head1 DESCRIPTION

The Date::Ethiopic::ET::gru module provides methods for accessing date information
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
