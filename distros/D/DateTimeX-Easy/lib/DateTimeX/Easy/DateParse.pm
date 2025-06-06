package #
DateTimeX::Easy::DateParse;

# Yar, stolen directly. Just needed to change 'local' to 'floating'

# Copyright (C) 2005-6  Joshua Hoblitt
#
# $Id: DateParse.pm 3517 2006-09-17 23:10:10Z jhoblitt $


# ABSTRACT: DateParse fork for datetimex::easy
use strict;

use vars qw($VERSION);
$VERSION = '0.04';

# VERSION

use DateTime;
use DateTime::TimeZone;
use Date::Parse qw( strptime );
use Time::Zone qw( tz_offset );

=over

=item parse_datetime

=back

=cut

sub parse_datetime {
    my ($class, $date, $zone) = @_;

    # str2time() calls strptime() internally so it's more efficent to use
    # strptime() directly.  However, the extra validation done by using
    # DateTime->new() instad of DateTime->from_epoch() may make it into a net
    # loss.  In the end, it turns out that strptime()'s offset information is
    # needed anyways.

# CHANGED! Do not assume 'local' timezone by default!
    my @t = strptime( $date, "floating");
#    my @t = strptime( $date, $zone );

    return undef unless @t;

    my ($ss, $mm, $hh, $day, $month, $year, $offset) = @t;

    my %p;
    if ( $ss ) {
        my $fraction = $ss - int( $ss );
        $p{ nanosecond } = $fraction * 1e9 if $fraction;
        $p{ second } = int $ss;
    }
    $p{ minute }    = $mm if $mm;
    $p{ hour }      = $hh if $hh;
    $p{ day }       = $day if $day;
    $p{ month }     = $month + 1 if $month;
    $p{ year }      = $year ? $year + 1900 : DateTime->now->year;

    # unless there is an explict ZONE, Date::Parse seems to parse date only
    # formats, eg. "1995-01-24", as being in the 'local' timezone.
    unless ( defined $zone || defined $offset ) {
# CHANGED! Do not assume 'local' timezone by default!
        return DateTime->new(
            %p,
            time_zone   => 'floating',
        );
#            time_zone   => 'local',
    }

    if ( $zone ) {
        if ( DateTime::TimeZone->is_valid_name( $zone ) ) {
            return DateTime->new(
                %p,
                time_zone   => $zone,
            );
        } else {
            # attempt to convert Time::Zone tz's into an offset
            return DateTime->new(
                %p,
                time_zone   =>
                    # not an Olson timezone, no DST info
                    DateTime::TimeZone::offset_as_string( tz_offset( $zone ) ),
            );
        }
    }

    return DateTime->new(
        %p,
        time_zone   =>
            # not an Olson timezone, no DST info
            DateTime::TimeZone::offset_as_string( $offset ),
    );
}

1;

__END__
