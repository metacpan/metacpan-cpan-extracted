package Date::Holidays::LT;

use strict;
use warnings;
use POSIX qw(strftime);
use Date::Easter;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(is_lt_holiday);

our $VERSION = '0.01';

sub is_lt_holiday {
	my ($year, $month, $day) = @_;

	if    ($day ==  1 and $month ==  1) { return "New Year's Day"; }
	elsif ($day == 16 and $month ==  2) { return "Day of Re-establishment of the State of Lithuania"; }
	elsif ($day == 11 and $month ==  3) { return "Day of Restitution of Independence of Lithuania"; }
	elsif ($day ==  1 and $month ==  5) { return "International Labor Day"; }
	elsif ($day == 24 and $month ==  6) { return "Day of Dew"; }  # "Rasos", "Joninės"
	# "Lietuvos karaliaus Mindaugo karūnavimo diena":
	elsif ($day ==  6 and $month ==  7) { return "Statehood Day"; } 
	elsif ($day == 15 and $month ==  8) { return "Herbal Day"; } # "Žolinės"
	elsif ($day ==  1 and $month == 11) { return "All Saints' Day"; }  # "Visų šventųjų diena"
	elsif ($day == 24 and $month == 12) { return "Christmas eve"; }
	elsif ($day == 25 and $month == 12) { return "Christmas"; }
	elsif ($day == 26 and $month == 12) { return "Christmas"; }
	else {
		my ($easter_month, $easter_day) = Date::Easter::easter($year);
		my $wday = strftime("%w", 0, 0, 0, $day, $month-1, $year-1900);

		if ($day == $easter_day and $month == $easter_month) { 
			return "Easter";
		} 
		elsif ($day == ($easter_day + 1) and $month == $easter_month) {
			return "Easter";
		}

		if ($wday == 0 and $day <= 7 and $month == 5) { 
			return "Mother's day";  # first sunday of May
		} 
		if ($wday == 0 and $day <= 7 and $month == 6) { 
			return "Father's day";  # first sunday of June
		}
	}
}

1;

__END__

=head1 NAME

Date::Holidays::LT - Determine Lithuanian holidays

=head1 SYNOPSIS

use Date::Holidays::LT;
my ($year, $month, $day) = (localtime)[5, 4, 3];
$year  += 1900;
$month += 1;
print "Let's party!" if is_lt_holiday($year, $month, $day);

=head1 DESCRIPTION

is_lt_holiday method return true value when the day is holiday.

There are 15 holidays in Lithuania:

=over 4

=item * New Year's Day

=item * Day of Re-establishment of the State of Lithuania

=item * Day of Restitution of Independence of Lithuania

=item * Easter day one

=item * Easter day two

=item * International Labor Day

=item *	Mother's day

=item *	Father's day

=item * Day of Dew : "Rasos", "Joninės"

=item * Statehood Day : "Lietuvos karaliaus Mindaugo karūnavimo diena"

=item * Herbal Day : "Žolinės"

=item * All Saints' Day

=item * Christmas eve

=item * Christmas day one

=item * Christmas day two

=back

Easter is computed with Date::Easter module.

=head1 SUBROUTINES

=head2 is_lt_holiday($year, $month, $day)

Returns the name of the holiday in english that falls on the given day, or undef if there is none.

=head1 REQUESTS & BUGS

Please report any requests, suggestions or bugs via the RT bug-tracking system at http://rt.cpan.org/ or email to bug-Date-Holidays-LT\@rt.cpan.org. 

http://rt.cpan.org/NoAuth/Bugs.html?Dist=Date-Holidays-LT is the RT queue for Date::Holidays::LT.  Please check to see if your bug has already been reported. 

=head1 PREREQUISITES

This script requires the C<Date::Easter> module.  Makes use of the B<POSIX> 
module from the standard Perl distribution.

=head1 COPYRIGHT

Copyright 2012

Saulius Petrauskas, saulius@cpan.org

This software may be freely copied and distributed under the same
terms and conditions as Perl.

=head1 SEE ALSO

perl(1), Date::Holidays::FR, Date::Holidays::DE.

=cut
