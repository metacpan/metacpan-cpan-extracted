#$Header: /cvsroot/date-passover/lib/Date/Passover.pm,v 1.10 2002/08/30 00:06:51 rbowen Exp $
package Date::Passover;
use Date::GoldenNumber;
use Date::DayOfWeek;
use Date::ICal;
use Carp;
use strict;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = (qw'$Revision: 1.12 $')[1];
	@ISA         = qw (Exporter);
	@EXPORT      = qw (passover roshhashanah);
	@EXPORT_OK   = qw ();
	%EXPORT_TAGS = ();
}

=head1 NAME

Date::Passover - When is Passover? When is Rosh Hashanah?

=head1 SYNOPSIS

  use Date::Passover;

  ($month, $day ) = roshhashanah( 1997 );
  $date_ical_obj = roshhashahah( 1997 );

  ( $month, $day ) = passover( 1997 );
  $date_ical_obj = passover( 1997 );

=head1 DESCRIPTION

Calculate the date of Passover or Rosh Hashanah for any given year.

=head1 BUGS

None yet, but I expect I'll take care of that pretty soon.

=head1 SUPPORT

Email the author, or post to the datetime@perl.org mailing list.

=head1 AUTHOR

	Rich Bowen
	CPAN ID: RBOW
	rbowen@rcbowen.com
	http://www.rcbowen.com

=head1 COPYRIGHT

Copyright (c) 2001 Rich Bowen. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

 perl(1)
 Date::ICal
 Date::Easter
 Reefknot ( http://reefknot.org/ )

=cut

sub passover {
    my $year = shift;
    my $date = roshhashanah($year);

    my $m;
    if ($date->month == 9) {
        $m = $date->day;
    } else {
        $m = 30 + $date->day;
    }

    my $passover = Date::ICal->new( month=>3, day=>21, year =>$year );
    $passover ->add( day => $m );


    if (wantarray) {
        return ($passover->month, $passover->day);
    } else {
        return $passover;
    }
}

sub roshhashanah{
    my $year = shift;

    # For the moment, we are limited to 1900 - 2099
    if ( $year < 1900 || $year > 2099 ) {
        carp "Can't calculate Rosh Hashanah for dates before 1900 or
        after 2099. Please check back in a version or two";
    }
    
    my $g = golden( $year );
    my $y = $year - 1900;

    my $day = 6.057778996 + 1.554241797*((12 * $g )%19) + 0.25*($y%4)
        - 0.003177794*$y;

    # Do we have to postpone?
    # Warning: Many magic numbers
    my $dow = dayofweek( $day, 9, $year );
    if ( $dow == 0 || $dow == 3 || $dow == 5 ) {
        $day ++;
    } elsif ( ( $dow == 1 ) && ( ($day - (int($day))) >= 23269/25920 )
        && ( ( (12 * $g )%19 ) > 11 ) ) {
        $day ++;
    } elsif ( ( $dow == 2 ) && ( $day - (int($day)) >= 1367/2160 )
        && ( ( (12*$g) % 19) > 6 )) {
        $day += 2;
    }

    $day = int($day);
    my $month = 9;
    if ( $day > 30 ) {
        $day -= 30;
        $month++;
    }

    if (wantarray) {
        return ( $month, int($day) );
    } else {
        return Date::ICal->new( month => $month, day => $day, year =>
            $year);
    }
}


1;


