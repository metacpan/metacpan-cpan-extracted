package Date::Ethiopic::ET::gez;
use base ( "Date::Ethiopic::gez", "Date::Ethiopic::ET" );
use strict;
use warnings;

$VERSION = "0.15";



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__



=head1 NAME

Date::Ethiopic::ET::gez - Ge'ez Calendar Data for L<Date::Ethiopic>.

=head1 SYNOPSIS

 use Date::Ethiopic::ET::gez;
 #
 #  typical instantiation:
 #
 my $gez = new Date::Ethiopic::ET::gez ( ical => '19950629' );

 #
 # Print Ge'ez day and month names:
 #
 print "  Day   Name: ", $gez->day_name, "\n";
 print "  Month Name: ", $gez->month_name, "\n";

 #
 # POSIX long date format:
 #
 print "  Long  Date: ", $gez->long_date, "\n";
 print "  Long  Date: ", $gez->long_date('ethio'), "\n";

 #
 # POSIX full date format:
 #
 print "  Full  Date: ", $gez->full_date, "\n";
 #
 # Convert all numbers into Ethiopic:
 #
 print "  Full  Date: ", $gez->full_date('ethio'), "\n";

 #
 # Turn transcription on:
 #
 $gez->useTranscription ( 1 );
 print "  Full  Date: ", $gez->full_date, "\n";

 #
 # Turn transcription off:
 #
 $gez->useTranscription ( 0 );
 print "  Full  Date: ", $gez->full_date, "\n";

=head1 DESCRIPTION

The Date::Ethiopic::ET::gez module provides methods for accessing date information
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
