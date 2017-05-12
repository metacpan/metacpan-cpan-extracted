package DateTime::Calendar::CopticEthiopic;
use base (DateTime);

BEGIN
{
	require 5.000;

	use strict;
	use vars qw(
		$VERSION

		$true
		$false

		@GregorianDaysPerMonth

		$n
	);

	$VERSION = "0.13";

	($false,$true) = (0,1);

	@GregorianDaysPerMonth = ( 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 );
}


#
#
#  Calender System Conversion Methods Below Here:
#
#
sub _AbsoluteToEthiopic 
{
my ( $self, $absolute ) = @_;

	my  $year = quotient ( 4 * ( $absolute - $self->epoch ) + 1463, 1461 );
	my $month = 1 + quotient ( $absolute - $self->_EthiopicToAbsolute ( 1, 1, $year ), 30 );
	my   $day = ( $absolute - $self->_EthiopicToAbsolute ( 1, $month, $year ) + 1 );

	( $day, $month, $year );
}


sub fromGregorian
{
my $self = shift;

	die ( "Bogus Ethiopic Date!!" ) if ( $self->_isBogusGregorianDate ( @_ ) );

	$self->_AbsoluteToEthiopic ( $self->_GregorianToAbsolute ( @_ ) );
}


sub gregorian
{
my $self = shift;

	$self->_AbsoluteToGregorian ( $self->_EthiopicToAbsolute ( @_ ) );
}


sub _isBogusEthiopicDate 
{
my $self = shift;

	my($day, $month, $year) = (@_) ? @_ : ($self->day, $self->month, $self->year);

	( !( 1 <= $day && $day <= 30 )
		|| !(  1 <= $month && $month <= 13 )
		|| ( $month ==  13 && $day > 6 )
		|| ( $month ==  13 && $day == 6 && !$self->isLeapYear )
	)
	?
	$true : $false;

}


sub _isBogusGregorianDate 
{
my $self = shift;

	my($day, $month, $year) = (@_) ? @_ : ($self->day, $self->month, $self->year);

	( !( 1 <= $month && $month <= 12 )
		|| !( 1 <= $day  && $day  <= $GregorianDaysPerMonth[$month-1] )
		|| ( $day == 29  && $month == 2 && !$self->_isGregorianLeapYear($year) )
	)
	?
	$true : $false;

}


sub _EthiopicToAbsolute
{
my $self = shift;
my ( $date, $month, $year ) = ( @_ ) ? @_ : ($self->day,$self->month,$self->year);

	( $self->epoch - 1 + 365 * ( $year - 1 ) + quotient ( $year, 4 ) + 30 * ( $month - 1 ) + $date );
}


sub _GregorianYear
{
my ( $a ) = @_;

	my $b = $a - 1;
	my $c = quotient ( $b, 146097 );
	my $d =      mod ( $b, 146097 );
	my $e = quotient ( $d, 36524  );
	my $f =      mod ( $d, 36524  );
	my $g = quotient ( $f, 1461   );
	my $h =      mod ( $f, 1461   );
	my $i = quotient ( $h, 365    );
	my $j = ( 400 * $c ) + ( 100 * $e ) + ( 4 * $g ) + $i;

	( ( $e == 4 ) || ( $i == 4 ) )
	  ? $j
	  : ( $j + 1 )
	;
}


sub _AbsoluteToGregorian
{
my ( $self, $absolute ) = @_;

	my $year = _GregorianYear ( $absolute );

	my $priorDays = ( $absolute - $self->_GregorianToAbsolute ( 1, 1, $year ) );

	my $correction 
	= ( $absolute < $self->_GregorianToAbsolute ( 1, 3, $year ) )
	  ? 0
	  : ( $self->_isGregorianLeapYear ( $year ) )
	    ? 1
	    : 2
	;

	my $month = quotient ( ( ( 12 * ( $priorDays + $correction ) + 373 ) / 367 ), 1 );
	my $day = $absolute - $self->_GregorianToAbsolute ( 1, $month, $year ) + 1;

	( $day, $month, $year );
}


sub _GregorianToAbsolute
{
my $self = shift;
my ( $date, $month, $year ) = ( @_ ) ? @_ : ($self->day,$self->month,$self->year);

	my $correction 
	= ( $month <= 2 )
	  ? 0
	  : ( $self->_isGregorianLeapYear ( $year ) )
	    ? -1
	    : -2
	;

	my $absolute =(
		365 * ( $year - 1 )
		    + quotient ( $year - 1, 4   )
		    - quotient ( $year - 1, 100 )
		    + quotient ( $year - 1, 400 )
		    + ( 367 * $month - 362 ) / 12
			+ $correction + $date
	);

	quotient ( $absolute, 1 );
}


sub _isGregorianLeapYear
{
shift;

	(
		( ( $_[0] % 4 ) != 0 )
		|| ( ( $_[0] % 400 ) == 100 )
		|| ( ( $_[0] % 400 ) == 200 )
		|| ( ( $_[0] % 400 ) == 300 )
	)
	  ? 0
	  : 1
	;
}


#
# argument is an ethiopic year
#
sub isLeapYear
{
my $self = shift;
my ( $year ) = ( @_ ) ? shift : $self->year;

	( ( $year + 1 ) % 4 ) ? 0 : 1 ;
}


sub quotient
{
	$_ = $_[0] / $_[1];

	s/\.(.*)//;

	$_;
}


sub mod 
{
	( $_[0] - $_[1] * quotient ( $_[0], $_[1] ) );
}


sub toGregorian
{
my $self = shift;

	my ($day,$month,$year) = $self->gregorian;

	new DateTime ( day => $day, month => $month, year => $year );
}


#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__



=head1 NAME

DateTime::Calendar::CopticEthiopic - DateTime Module for the Coptic/Ethiopic Calendar System.

=head1 SYNOPSIS

 use DateTime::Calendar::CopticEthiopic;
 #
 #  typical instantiation:
 #
 my $ethio = new DateTime::Calendar::CopticEthiopic ( day => 29, month => 6, year => 1995 );
 $ethio    = new DateTime::Calendar::CopticEthiopic ( ical => '19950629' );  # the same

 #
 # Get Gregorian Date:
 #
 my ($d,$m,$y) = $ethio->gregorian;

 #
 #  instantiate with a Gregorian date, date will be converted.
 #
 $ethio = new DateTime::Calendar::CopticEthiopic ( ical => '20030308', calscale => 'gregorian' );

 #
 #  instantiate with a DateTime::ICal object, assumed to be in Gregorian
 #
 my $grego = new DateTime::ICal ( ical => '20030308' );
 $ethio = new DateTime::Calendar::CopticEthiopic ( $grego );

 #
 #  get a DateTime::ICal object in the Gregorian calendar system
 #
 $grego = $ethio->toGregorian;  


=head1 DESCRIPTION

The DateTime::Calendar::CopticEthiopic module provides a base class for
DateTime::Calendar::Coptic and DateTime::Calendar::Ethiopic and handles
conversions to and from the Gregorian calendar system.

=head2 Limitations

In the Gregorian system the rule for adding a 29th day to February during
leap year follows as per;  February will have a 29th day:

(((((every 4 years) except every 100 years) except every 400 years) except every 2,000) except (maybe every 16,000 years))

The Coptic/Ethiopic calendar gets an extra day at the end of the 13th month on leap
year (which occurs the year before Gregorian leap year).
It is not known however if the Coptic/Ethiopic calendar follows the 2,000 year rule.
If it does NOT follow the 2,000 year rule the consequence would be that the
difference between the two calendar systems will increase by a single day.
Hence if you reckon your birthday in the Coptic/Ethiopic system, that date in
Gregorian may change in five years.  The algorithm here here assumes that
the Coptic/Ethiopic system will follow the 2,000 year rule.

This may however become a moot point when we consider:


=head2 The Impending Calamity at the End of Time

Well, it is more of a major reset.  Recent reports from reliable sources
indicate that every
1,000 years the Coptic/Ethiopic calendar goes thru a major upheaval whereby
the calendar gets resyncronized with either September 1st or possibly
even October 1st.  Accordingly Nehasse would then either end on the 25th
day or Pagumen would be extend to 25 days.  Noone will know their birthday
any more, Christmas or any other date that ever once had meaning.  Chaos
will indeed rule the world.

Unless everyone gets little calendar converting applets running on their wrist
watches, that would rule.  But before you start coding applets for future
embeded systems, lets get this clarified.  Consider that the Gregorian
calendar system is less than 500 years old, so this couldn't have happend
a 1,000 years ago, perhaps with the Julian calendar.  Since the Coptic/Ethiopic
calendar is still in sync with the Coptic, the Copts must have gone thru
the same upheaval.

We are following this story closely, stay tuned to these man pages
for updates as they come in.


=head1 CREDITS

=over

=item Calendrical Calculations: L<http://www.calendarists.com/>

=item Bahra Hasab: L<http://www.hmml.org/events/>

=item LibEth: L<http://libeth.sourceforge.net/>

=item Ethiopica: L<http://ethiopica.sourceforge.net/>

=item Saint Gebriel Ethiopian Orthodox Church of Seattle: L<http://www.st-gebriel.org/>

=item Aklile Birhan Wold Kirkos, Metsaheit Tibeb, Neged Publishers, Addis Ababa, 1955 (1948 EC).

=back

=head1 REQUIRES

This module is intended as a base class for other classes and is not
intended for use on its own.

=head1 COPYRIGHT

The conversion algorithms are derived from the original work in Emacs
Lisp by Reingold, Dershowitz and Clamen which later grew into the
excellent reference Calendrical Calculations.  The Emacs package carries
the following message:

 ;; The Following Lisp code is from ``Calendrical
 ;; Calculations'' by Nachum Dershowitz and Edward
 ;; M. Reingold, Software---Practice & Experience, vol. 20,
 ;; no. 9 (September, 1990), pp. 899--928 and from
 ;; ``Calendrical Calculations, II: Three Historical
 ;; Calendars'' by Edward M.  Reingold, Nachum Dershowitz,
 ;; and Stewart M. Clamen, Software---Practice & Experience,
 ;; vol. 23, no. 4 (April, 1993), pp. 383--404.

 ;; This code is in the public domain, but any use of it
 ;; should publically acknowledge its source.

Otherwise, this module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=head1 BUGS

None presently known.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 SEE ALSO

Ethiopica L<http://ethiopica.sourceforge.net>

=cut
