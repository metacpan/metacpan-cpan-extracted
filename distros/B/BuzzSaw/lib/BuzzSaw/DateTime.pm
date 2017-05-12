package BuzzSaw::DateTime;
use strict;
use warnings;

# $Id: DateTime.pm.in 21586 2012-08-14 10:37:59Z squinney@INF.ED.AC.UK $
# $Source:$
# $Revision: 21586 $
# $HeadURL: https://svn.lcfg.org/svn/source/tags/BuzzSaw/BuzzSaw_0_12_0/lib/BuzzSaw/DateTime.pm.in $
# $Date: 2012-08-14 11:37:59 +0100 (Tue, 14 Aug 2012) $

our $VERSION = '0.12.0';

use base 'DateTime';

use Date::Parse ();
use DateTime::Duration ();

sub from_date_string {
    my ( $class, $date_string ) = @_;

    my $now = $class->now();

    # Ensure we are using the current local timezone
    $now->set_time_zone('local');

    # NOTE: When making changes to this code consider VERY carefully
    # what is going on with the timezone.

    my $dt;
    if ( $date_string eq 'now' ) {
        $dt = $now;
    } elsif ( $date_string eq 'today' ) {
        $dt = $now->truncate( to => 'day' );
        $dt->set_second(1);
    } elsif ( $date_string eq 'recent' ) {
        my $dur = DateTime::Duration->new( minutes => 10 );
        $dt = $now - $dur;
    } elsif ( $date_string eq 'yesterday' ) {
        $dt = $now->truncate( to => 'day' );
        $dt->set_second(1);
        my $dur = DateTime::Duration->new( days => 1 );
        $dt = $now - $dur;
    } elsif ( $date_string =~ m/^this-(week|month|year)$/ ) {
        $dt = $now->truncate( to => $1 );
        $dt->set_second(1);
    } elsif ( $date_string eq 'week-ago' ) {
        my $dur = DateTime::Duration->new( days => 7 );
        $dt = $now - $dur;
    } elsif ( $date_string =~ m/^\d+$/ ) {
        $dt = $class->from_epoch( epoch => $date_string );
        $dt->set_time_zone('local');
    } else { # throw it at Date::Parse
        my ( $ss, $mm, $hh, $day, $month, $year, $zone )
          = Date::Parse::strptime($date_string);
        $zone //= 'local';
        $month += 1; # Date::Parse counts from zero
        $year  += 1900;

        $dt = $class->new( second    => int($ss),
                           minute    => $mm,
                           hour      => $hh,
                           day       => $day,
                           month     => $month,
                           year      => $year,
                           time_zone => $zone );

    }

    return $dt;
}

1;

__END__

=head1 NAME

BuzzSaw::DateTime - A class which provides additional functionality to DateTime

=head1 VERSION

This documentation refers to BuzzSaw::Filter version 0.12.0

=head1 SYNOPSIS

use BuzzSaw::DateTime;

my $dt = BuzzSaw::DateTime->from_date_string( "this-week" );

=head1 DESCRIPTION

This module extends the DateTime module to provide an extra
constructor method. This method provides the ability to parse dates in
a variety of formats and styles to create a new DateTime object. In
particular, this module supports the date specifier strings used by
the Linux Audit Framework.

The BuzzSaw project provides a suite of tools for processing log file
entries. Entries in files are parsed and filtered into a set of events
of interest which are stored in a database. A report generation
framework is also available which makes it easy to generate regular
reports regarding the events discovered.

=head1 SUBROUTINES/METHODS

This class provides one additional method beyond those provided by the
DateTime module.

=over

=item from_date_string( $str )

This method will return a new object based on one of the following
strings:

=over

=item C<now>

Right now.

=item C<today>

1 second after midnight on this day.

=item C<recent>

10 minutes ago.

=item C<yesterday>

1 second after midnight on the previous day.

=item C<this-week>

1 second after midnight on the first day of the week.

=item C<this-month>

1 second after midnight on the first day of the month.

=item C<this-year>

1 second after midnight on the first day of the year.

=item C<week-ago>

Seven days ago.

=item seconds from unix epoch

A string which is purely digits will be treated as being the number of
seconds since the unix epoch.

=item variously formatted date/time strings

Anything else that does not match something which has already been
mentioned above is passed to the L<Date::Parse> C<strptime>
function. This should work if the string is well formatted, if not you
might get something very weird returned.

=back

=back

=head1 DEPENDENCIES

L<DateTime>, L<DateTime::Duration>, L<Date::Parse>

=head1 SEE ALSO

L<BuzzSaw>

=head1 PLATFORMS

This is the list of platforms on which we have tested this
software. We expect this software to work on any Unix-like platform
which is supported by Perl.

ScientificLinux6

=head1 BUGS AND LIMITATIONS

Please report any bugs or problems (or praise!) to bugs@lcfg.org,
feedback and patches are also always very welcome.

=head1 AUTHOR

    Stephen Quinney <squinney@inf.ed.ac.uk>

=head1 LICENSE AND COPYRIGHT

    Copyright (C) 2012 University of Edinburgh. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the terms of the GPL, version 2 or later.

=cut
