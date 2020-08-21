package DateTime::Format::ISO8601::Format;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-21'; # DATE
our $DIST = 'DateTime-Format-ISO8601-Format'; # DIST
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

sub new {
    my ($class, %args) = @_;

    my $self = {};

    if (defined(my $time_zone = delete $args{time_zone})) {
        $self->{time_zone} = do {
            if (ref $time_zone) {
                $time_zone;
            } else {
                require DateTime::TimeZone;
                DateTime::TimeZone->new(name => $time_zone);
            }
        };
    }
    $self->{second_precision} = delete $args{second_precision};
    if (keys %args) {
        die "Unknown attribute(s): ".join(", ", sort keys %args);
    }

    bless $self, $class;
}

sub _format_date_or_time_or_datetime {
    my ($self, $which, $dt) = @_;

    if ($self->{time_zone}) {
        $dt = $dt->clone->set_time_zone($self->{time_zone});
    }

    my ($s_date, $s_time);

    if ($which eq 'date' || $which eq 'datetime') {
        $s_date = $dt->ymd('-');
    }

    if ($which eq 'time' || $which eq 'datetime') {
        $s_time = $dt->hms(':');
        if (($dt->nanosecond &&
                 !defined($self->{second_precision}) ||
                 $self->{second_precision})) {
            my $s_secfrac;
            if (!defined($self->{second_precision})) {
                $s_secfrac = sprintf("%s", $dt->nanosecond / 1e9);
            } else {
                $s_secfrac .= sprintf("%.$self->{second_precision}f",
                                      $dt->nanosecond / 1e9);
            }
            $s_time .= substr($s_secfrac, 1); # remove the "0" part
        }
        my $tz = $dt->time_zone;
        if ($tz->is_floating) {
            # do nothing, no time zone designation
        } elsif ($tz->is_utc) {
            $s_time .= "Z";
        } else {
            my $offset_secs = $tz->offset_for_datetime($dt);
            my $sign = $offset_secs >= 0 ? "+" : "-";
            my $h = int(abs($offset_secs) / 3600);
            my $m = int((abs($offset_secs) - $h*3600) / 60);
            $s_time .= sprintf "%s%02d:%02d", $sign, $h, $m;
        }
    }

    if ($which eq 'date') {
        return $s_date;
    } elsif ($which eq 'time') {
        return $s_time;
    } elsif ($which eq 'datetime') {
        return $s_date . 'T' . $s_time;
    } else {
        die "BUG: Unknown which '$which'"; # shouldn't happen
    }
}

sub format_date {
    my ($self, $dt) = @_;
    $self->_format_date_or_time_or_datetime('date', $dt);
}

sub format_time {
    my ($self, $dt) = @_;
    $self->_format_date_or_time_or_datetime('time', $dt);
}

sub format_datetime {
    my ($self, $dt) = @_;
    $self->_format_date_or_time_or_datetime('datetime', $dt);
}

1;
# ABSTRACT: Format DateTime object as ISO8601 date/time string

__END__

=pod

=encoding UTF-8

=head1 NAME

DateTime::Format::ISO8601::Format - Format DateTime object as ISO8601 date/time string

=head1 VERSION

This document describes version 0.004 of DateTime::Format::ISO8601::Format (from Perl distribution DateTime-Format-ISO8601-Format), released on 2020-08-21.

=head1 SYNOPSIS

 use DateTime::Format::ISO8601::Format;

 my $format = DateTime::Format::ISO8601::Format->new(
     # time_zone => '...',    # optional, default is DateTime object's time zone
     # second_precision => 3, # optional, default is undef
 );

 my $dt_floating      = DateTime->new(year=>2018, month=>6, day=>23, hour=>19, minute=>2, second=>3);
 my $dt_floating_frac = DateTime->new(year=>2018, month=>6, day=>23, hour=>19, minute=>2, second=>3, nanosecond=>0.456e9);
 my $dt_utc           = DateTime->new(year=>2018, month=>6, day=>23, hour=>19, minute=>2, second=>3, time_zone=>'UTC');
 my $dt_sometz        = DateTime->new(year=>2018, month=>6, day=>23, hour=>19, minute=>2, second=>3, time_zone=>'Asia/Jakarta');

Formatting dates:

 say $format->format_date($dt_floating);      # => 2018-06-23
 say $format->format_date($dt_floating_frac); # => 2018-06-23
 say $format->format_date($dt_utc);           # => 2018-06-23
 say $format->format_date($dt_sometz);        # => 2018-06-23

 # effect of setting time_zone attribute to 'Asia/Jakarta' (which has the offset +07:00):

 say $format->format_date($dt_floating);      # => 2018-06-23
 say $format->format_date($dt_floating_frac); # => 2018-06-23
 say $format->format_date($dt_utc);           # => 2018-06-24
 say $format->format_date($dt_sometz);        # => 2018-06-23

Formatting times:

 say $format->format_time($dt_floating);      # => 19:02:03
 say $format->format_time($dt_floating_frac); # => 19:02:03.456
 say $format->format_time($dt_utc);           # => 19:02:03Z
 say $format->format_time($dt_sometz);        # => 19:02:03+07:00

 # effect of setting time_zone attribute to 'Asia/Jakarta' (which has the offset of +07:00):

 say $format->format_time($dt_floating);      # => 19:02:03+07:00
 say $format->format_time($dt_floating_frac); # => 19:02:03.456+07:00
 say $format->format_time($dt_utc);           # => 02:02:03+07:00
 say $format->format_time($dt_sometz);        # => 19:02:03+07:00

 # effect of setting second_precision to 3

 say $format->format_time($dt_floating);      # => 19:02:03.000
 say $format->format_time($dt_floating_frac); # => 19:02:03.456
 say $format->format_time($dt_utc);           # => 19:02:03.000Z
 say $format->format_time($dt_sometz);        # => 19:02:03.000+07:00

Formatting date+time:

 say $format->format_datetime($dt_floating);      # => 2018-06-23T19:02:03
 say $format->format_datetime($dt_floating_frac); # => 2018-06-23T19:02:03.456
 say $format->format_datetime($dt_utc);           # => 2018-06-23T19:02:03Z
 say $format->format_datetime($dt_sometz);        # => 2018-06-23T19:02:03+07:00

=head1 DESCRIPTION

This module formats L<DateTime> objects as ISO8601 date/time strings. It
complements L<DateTime::Format::ISO8601>.

=head1 ATTRIBUTES

=head2 time_zone

Optional. Used to force the time zone of DateTime objects to be formatted.
Either string containing time zone name (e.g. "Asia/Jakarta", "UTC") or
L<DateTime::TimeZone> object. Will be converted to DateTime::TimeZone
internally.

The default is to use the DateTime object's time zone.

DateTime object with floating time zone will not have the time zone designation
in the ISO8601 string, e.g.:

 19:02:03
 2018-06-23T19:02:03

DateTime object with UTC time zone will have the "Z" time zone designation:

 19:02:03Z
 2018-06-23T19:02:03Z

DateTime object with other time zones will have the "+hh:mm" time zone
designation:

 19:02:03+07:00
 2018-06-23T19:02:03+07:00

=head2 second_precision

Optional. A non-negative integer. Used to control formatting (number of
decimals) of the second fraction. The default is to only show fraction when they
exist, with whatever precision C<sprintf("%s")> outputs.

=head1 METHODS

=head2 new

Usage:

 DateTime::Format::ISO8601::Format->new(%attrs) => obj

=head2 format_date

Usage:

 $format->format_date($dt) => str

=head2 format_time

Usage:

 $format->format_time($dt) => str

=head2 format_datetime

Usage:

 $format->format_datetime($dt) => str

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/DateTime-Format-ISO8601-Format>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-DateTime-Format-ISO8601-Format>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=DateTime-Format-ISO8601-Format>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<DateTime::Format::ISO8601>. Before v0.12, DateTime::Format::ISO8601 does not
feature a C<format_datetime()> method, so DateTime::Format::ISO8601::Format
supplies that functionality. After v0.12, DateTime::Format::ISO8601 already has
C<format_datetime()>, but currently DateTime::Format::ISO8601::Format's version
is faster and there's C<format_date> and C<format_time> as well. So I'm keeping
this module for now.

L<DateTime::Format::Duration::ISO8601> to parse and format ISO8601 durations.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
