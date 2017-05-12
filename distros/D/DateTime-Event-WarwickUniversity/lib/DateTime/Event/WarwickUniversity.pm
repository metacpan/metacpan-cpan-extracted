package DateTime::Event::WarwickUniversity;

=head1 NAME

DateTime::Event::WarwickUniversity - Warwick University academic calendar events

=head1 SYNOPSIS

  use DateTime::Event::WarwickUniversity;

  my $dt = DateTime->new(day => 7, month => 5, year => 2005);

  # 2005-09-26
  my $dt_gr = DateTime::Event::Warwick->new_year_for_gregorian_year($dt);

  # 2004-09-28
  my $dt_ac = DateTime::Event::Warwick->new_year_for_academic_year($dt);

=head1 DESCRIPTION

DateTime::Event::WarwickUniversity is used to work with the academic calendar
of the University of Warwick.

=cut

use 5.008004;
use strict;
use warnings;
use Carp;
use Scalar::Util qw/blessed/;

our $VERSION = '0.05';

# http://web.archive.org/web/19980114233111/warwick.ac.uk/info/dates.html
# http://web.archive.org/web/20001101110549/www.warwick.ac.uk/info/calendar/section1/1.01.html
# http://www2.warwick.ac.uk/insite/info/gov/calendar/section1/termdates/
# http://www2.warwick.ac.uk/services/gov/calendar/section1/termdates

my %new_year = (
	1996 => ['09', '30'],
	1997 => ['09', '29'],
	1998 => ['10', '05'],
	1999 => ['10', '04'],
	2000 => ['10', '02'],
	2001 => ['10', '01'],
	2002 => ['09', '30'],
	2003 => ['09', '29'],
	2004 => ['09', '28'],
	2005 => ['09', '26'],
	2006 => ['10', '02'],
	2007 => ['10', '01'],
	2008 => ['09', '29'],
	2009 => ['10', '05'],
	2010 => ['10', '04'],
	2011 => ['10', '03'],
	2012 => ['10', '01'],
	2013 => ['09', '30'],
	2014 => ['09', '29'],
	2015 => ['10', '05'],
	2016 => ['10', '03'],
	2017 => ['10', '02'],
);

my $min_year = 1996;
my $max_year = 2017;

=head1 METHODS

=head2 new_year_for_gregorian_year

Takes as argument a single L<DateTime> object.

Returns a L<DateTime> object representing the first day of the academic
calendar that begins in the same Gregorian year as the input.

=cut

sub new_year_for_gregorian_year {
	my ($class, $dt) = @_;

	croak("Input must be DateTime object")
		unless ( defined($dt) && blessed($dt) && $dt->isa('DateTime') );

	my $dt_new_year = _new_year_dt_from_gregorian_year($dt->year);

	# Want to preserve input class/timezone/locale and don't want to alter
	# input object, so use:
	# new_year = input + ( new_year - input )

	my $user_tz = $dt->time_zone;
	my $clone = $dt->clone->set_time_zone('floating');

	my $dt_dur = $dt_new_year->subtract_datetime_absolute( $clone );

	return $clone->add_duration( $dt_dur )->set_time_zone($user_tz);
}

=head2 new_year_for_academic_year

Takes as argument a single L<DateTime> object.

Returns a L<DateTime> object representing the first day of the same academic
year as the input.

=cut

sub new_year_for_academic_year {
	my ($class, $dt) = @_;

	croak("Input must be DateTime object")
		unless ( defined($dt) && blessed($dt) && $dt->isa('DateTime') );
	
	my $user_tz = $dt->time_zone;
	my $clone = $dt->clone->set_time_zone('floating');

	my $dt_new_year = _new_year_dt_from_gregorian_year($clone->year);
	my $dt_dur = $dt_new_year->subtract_datetime_absolute( $clone );

	if ($dt_dur->is_positive) {
		$dt_new_year = _new_year_dt_from_gregorian_year($clone->year - 1);
		$dt_dur = $dt_new_year->subtract_datetime_absolute( $clone );
	}

	return $clone->add_duration( $dt_dur )->set_time_zone($user_tz);
}

# _new_year_dt_from_gregorian_year
#
# Not part of public API. Takes a string containing a year, and returns a
# DateTime object representing the first day of the academic calendar that
# began in that Gregorian year.

sub _new_year_dt_from_gregorian_year {
	my $year = shift;

	croak("Input outside supported range.")
		if ( $year < $min_year || $year > $max_year );

	my $date = $new_year{$year};

	return DateTime->new(
		year	=> $year,
		month	=> $date->[0],
		day	=> $date->[1],
	);
}

1;
__END__

=head1 SEE ALSO

L<DateTime>, L<DateTime::Calendar::WarwickUniversity>

=head1 AUTHOR

Tim Retout E<lt>tim@retout.co.ukE<gt>

=head1 COPYRIGHT

Copyright (C) 2006, 2007, 2008 by Tim Retout

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.


=cut
