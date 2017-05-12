#!/usr/bin/perl

package Date::Parser::Date;

use strict;
use warnings;

use Time::Local;

require Date::Format;

our $VERSION = 0.4;

sub new {
    my ($class, %opts) = @_;

    my $self = bless {}, $class;
    $self->{year} = $opts{year};
    $self->{month} = $opts{month};
    $self->{day} = $opts{day};
    $self->{hour} = $opts{hour};
    $self->{min} = $opts{min};
    $self->{sec} = $opts{sec};
    $self->{unixtime} = $opts{unixtime};

    if (defined $self->unixtime && (!defined $self->{year} ||
            !defined $self->{month} || !defined $self->{day} ||
            !defined $self->{hour}  || !defined $self->{min} ||
            !defined $self->{sec})) {
        $self->_populate_from_unixtime;
    }

    if (defined $self->{year} && defined $self->{month} &&
        defined $self->{day} && defined $self->{hour} &&
        defined $self->{min} && defined $self->{sec}) {
        $self->{unixtime} = $self->_get_unixtime;
    }

    # use existing time or set it to noon
    if (defined $self->{year} && defined $self->{month} &&
        defined $self->{day} && (!defined $self->{hour} ||
            !defined $self->{min} || !defined $self->{sec})) {
        $self->{hour} = 11 unless (defined $self->{hour});
        $self->{min} = 0 unless (defined $self->{min});
        $self->{sec} = 0 unless (defined $self->{sec});
        $self->{unixtime} = $self->_get_unixtime;
    }

    # if only time is defined, set for today.. just expect hour:min at least
    if ((!defined $self->{year} || !defined $self->{month} || !defined $self->{day})
        && defined $self->{hour} && defined $self->{min}) {
        $self->{year} = Date::Format::time2str("%Y", time);
        $self->{month} = Date::Format::time2str("%L", time);
        $self->{day} = Date::Parser::_strip_zero(time2str("%d", time));
        $self->{sec} = 0 unless (defined $self->{sec});
        $self->{unixtime} = $self->_get_unixtime;
    }

    unless (defined $self->{unixtime}) {
        warn "couldn't resolve date";
        return;
    }

    return $self;
}

sub _populate_from_unixtime {
    my ($self) = @_;

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
        localtime($self->{unixtime});

    $self->{year} = $year + 1900;
    $self->{month} = $mon;
    $self->{day} = $mday;
    $self->{hour} = $hour;
    $self->{min} = $min;
    $self->{sec} = $sec;

    return $self;
}

sub time2str {
    my ($self, $format) = @_;

    Date::Format::time2str($format, $self->unixtime);
}

sub unixtime {
    my ($self) = @_;
    
    $self->{unixtime} ||= $self->_get_unixtime;
}

sub calc {
    my ($self, $other) = @_;

    my $unixtime;
    if ($self->cmp($other) == 0) {
        $unixtime = $self->unixtime;
    } elsif ($self->cmp($other) == -1) {
        $unixtime = $self->unixtime + (($other->unixtime - $self->unixtime) / 2);
        $unixtime = int($unixtime);
    } elsif ($self->cmp($other) == 1) {
        $unixtime = $self->unixtime - (($self->unixtime - $other->unixtime) / 2);
        $unixtime = int($unixtime);
    }

    my $new = Date::Parser::Date->new(unixtime => int($unixtime));

    return $new;
}

sub cmp {
    my ($self, $other) = @_;

    return -1 if ($self->unixtime < $other->unixtime);
    return 0 if ($self->unixtime == $other->unixtime);
    return 1 if ($self->unixtime > $other->unixtime);
}

sub _get_unixtime {
    my ($self) = @_;

    my $unixtime;
    eval { $unixtime = timelocal($self->{sec}, $self->{min}, $self->{hour}, $self->{day}, $self->{month}, $self->{year}) };

    return $unixtime;
}

sub assign {
    my ($self, $key, $value) = @_;

    $self->{$key} = $value;

    return $self;
}

1;

__END__
=pod

=encoding UTF-8

=head1 NAME

Date::Parser::Date - Simple date object

=head1 VERSION

Version 0.4

=head1 SYNOPSIS

  my $date = Date::Parser::Date->new(
      year => $year,
      month => $month,
      day => $day,
      hour => $hour,
      min => $min,
      sec => $sec,
  );
  # or Date::Parser::Date->new(unixtime => $unixtime);

=head1 DESCRIPTION

A simple date object.

=head1 METHODS

=head2 new(%opts)

The constructor. Attempts to construct sensible date and time values based on a simple algorithm.
See L</"CONSTRUCTOR_PARAMETERS">.

If unixtime is passed, it is used and other values are populated.

If year, month, day, hour, min and sec are provided, populates unixtime.

If only year, month and day are provided, uses all possible time values provided, and excepts
noon otherwise - then populates unixtime.

If only hour and min (and optionally sec) are defined, sets date for today. Afterwards, unixtime is populated.

=head2 time2str($format)

Returns Date::Format::time2str($format, $self->unixtime).

=head2 unixtime

Returns date in unixtime.

=head2 calc($date)

Expects Date::Parser::Date-object. Returns a new Date::Parser::Date-object
representing the time between self and given $date.

=head2 cmp($date)

Expects Date::Parser::Date-object. Compares dates.
Returns -1 if this object is before $date, 0 if dates match
and 1 if this object is after $date.

=head2 assign($key, $value)

Sets/overwrites a parameter $key with $value.

=head1 CONSTRUCTOR PARAMETERS

The constructor accepts following parameters:

=head2 unixtime

Seconds since 1.1.1970, e.g. 1295784779

=head2 year

Integer year, e.g. 2 or 2011

=head2 month

Integer month (from 0-11).

=head2 day

Integer day of the month (from 1-31).

=head2 hour

Integer hour in 24-hour format (from 0-23).

=head2 min

Integer minute (from 0-59).

=head2 sec

Integer second (from 0-59).

=head1 CAVEATS

This module doesn't verify the sanity of values given e.g. year => -102932.124

=head1 AUTHOR

Heikki Mehtänen, C<< <heikki@mehtanen.fi> >>

=head1 COPYRIGHT & LICENSE

Copyright 2011 Heikki Mehtänen, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
