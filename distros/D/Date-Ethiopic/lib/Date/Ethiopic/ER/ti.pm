package Date::Ethiopic::ER::ti;
use base ( "Date::Ethiopic::ti", "Date::Ethiopic::ER" );
use strict;
use warnings;

$VERSION = "0.16";



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__



=head1 NAME

Date::Ethiopic::ER::ti - Tigrinya Calendar Data for L<Date::Ethiopic>.

=head1 SYNOPSIS

 use Date::Ethiopic::ER::ti;
 #
 #  typical instantiation:
 #
 my $ti = new Date::Ethiopic::ER::ti ( ical => '19950629' );

 #
 # Print Tigrinya day and month names:
 #
 print "  Day   Name: ", $ti->day_name, "\n";
 print "  Month Name: ", $ti->month_name, "\n";

 #
 # POSIX long date format:
 #
 print "  Long  Date: ", $ti->long_date, "\n";
 print "  Long  Date: ", $ti->long_date('ethio'), "\n";

 #
 # POSIX full date format:
 #
 print "  Full  Date: ", $ti->full_date, "\n";
 #
 # Convert all numbers into Ethiopic:
 #
 print "  Full  Date: ", $ti->full_date('ethio'), "\n";

 #
 # Turn transcription on:
 #
 $ti->useTranscription ( 1 );
 print "  Full  Date: ", $ti->full_date, "\n";

 #
 # Turn transcription off:
 #
 $ti->useTranscription ( 0 );
 print "  Full  Date: ", $ti->full_date, "\n";

=head1 DESCRIPTION

The Date::Ethiopic::ER::ti module provides methods for accessing date information
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
__END__
