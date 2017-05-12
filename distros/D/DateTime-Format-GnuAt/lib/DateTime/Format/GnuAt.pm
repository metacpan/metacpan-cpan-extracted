package DateTime::Format::GnuAt;

our $VERSION = '0.03';

use strict;
use warnings;
use Carp;
use DateTime;

my @periods = qw(minute min hour day week month year);
my $period_re = join '|', @periods;
$period_re = qr/(?:$period_re)/i;

sub _period {
    my $period = lc shift;
    return ($period eq 'min' ? 'minutes' : $period.'s');
}

my (%month, %wday);
my @months = qw(january february march april may june july august
                september october november december);
@month{map substr($_, 0, 3), @months} = (1..12);

my @wdays = qw(monday tuesday wednesday thursday friday saturday sunday);
@wday{map substr($_, 0, 3), @wdays} = (1..7);

sub _make_alternation_re {
    my $re = join '|',
        map {
            substr($_, 0, 3) . (length > 3 ? '(?:' . substr($_, 3) . ')?' : '')
        } @_;
    return qr/(?:$re)\b/i;
}

my $month_re = _make_alternation_re(@months);
my $wday_re  = _make_alternation_re(@wdays );

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
}

sub _reset {
    my ($self, $opts) = @_;
    %{$self} = ();
    my $now = delete $opts->{now};
    $self->{now} = (defined $now ? $now->clone : DateTime->now(time_zone => 'local'));
    $self->{now}->set(second => 0);
}

sub parse_datetime {
    my ($self, $spec, %opts) = @_;

    $self->_reset(\%opts);

    for ($spec) {
        local ($@, $SIG{__DIE__});
        eval {
            /^\s*/gc;

            if ($self->_parse_spec_base()) {
                /\G\s*/gc;
                $self->_parse_inc_or_dec;
            }
            /\G\s*/gc;
            /\G\S/gc and die "unparsed rubbish";

            $self->{date}->set_time_zone('UTC');
        };
        $self->{error} = $@;
        return $self->{date} unless $@;
    }

    croak "unable to parse datetime specification '$spec'";
}

sub _parse_spec_base {
    my $self = shift;
    if ($self->_parse_date) {
        return 1;
    }
    elsif ($self->_parse_time) {
        my $pos = pos;
        unless (/\G\s+/gc and $self->_parse_date) {
            pos = $pos;
            my $base = $self->{now};
            my $base_hour = $base->hour;
            my $base_min = $base->min;
            if ( ( $base_hour > $self->{hour} ) or
                 ( ( $base_hour == $self->{hour} ) and
                   ( $base_min >= $self->{min} ) ) ) {
                $base = $base->add(days => 1);
            }
            $self->{date} = $base;
        }

        $self->{date}->set(hour => $self->{hour},
                           minute => $self->{min},
                           second => 0);


        return 1;
    }
    return
}

sub _parse_date {
    my $self = shift;

    my $now = $self->{now};

    if (/\G($month_re)\s+(\d\d?)(?:(?:\s+|\s*,\s*)(\d\d(?:\d\d)?))?/gco) {
        # month_name day_number
        # month_name day_number year_number
        # month_name day_number ',' year_number
        @{$self}{qw(month_name day year)} = ($1, $2, $3);
    }
    elsif (/\G(?:next\s+)?($wday_re)/gcio) {
        # day_of_week
        $self->{wday_name} = $1;
        my $wday = $self->{wday} = $wday{lc substr $1, 0, 3};
        my $delta = $wday - $now->day_of_week;
        $delta += 7 if $delta <= 0;
        $self->{date} = $now->add(days => $delta);
        return 1;
    }
    elsif (/\Gtoday\b/gci) {
        # TODAY
        $self->{today} = 1;
        $self->{date} = $now;
        return 1;
    }
    elsif (/\Gtomorrow\b/gci) {
        # TOMORROW
        $self->{tomorrow} = 1;
        $self->{date} = $now->add(days => 1);
        return 1;
    }
    elsif (/\G(\d\d?)\.(\d\d?)\.(\d\d(?:\d\d)?)\b/gc) {
        # DOTTEDDATE (dd.mm.[cc]yy)
        @{$self}{qw(day month year)} = ($1, $2, $3);
    }
    elsif (/\G(\d\d(?:\d\d)?)-(\d\d?)-(\d\d?)\b/gc) {
        # HYPHENDATE ([cc]yy-mm-dd)
        @{$self}{qw(year month day)} = ($1, $2, $3);
    }
    elsif (/\Gnow\b/gci) {
        # NOW
        $self->{is_now} = 1;
        $self->{date} = $now;
        return 1;
    }
    elsif (/\G(\d\d?)\s+($month_re)(?:\s+(\d\d(?:\d\d)?))?/gco) {
        # day_number month_name
        # day_number month_name year_number
        @{$self}{qw(day month_name year)} = ($1, $2, $3);
    }
    elsif (/\G(\d\d?)\/(\d\d?)\/(\d\d(?:\d\d)?)\b/gc) {
        # month_number '/' day_number '/' year_number
        @{$self}{qw(month day year)} = ($1, $2, $3);
    }
    elsif (/\G(\d\d?)(\d\d)(\d\d(?:\d\d)?)\b/gc) {
        # concatenated_date (m[m]dd[cc]yy)
        @{$self}{qw(month day year)} = ($1, $2, $3);
    }
    elsif (/\Gnext\s+($period_re)\b/gcio) {
        # NEXT inc_dec_period
        $self->{next_period} = $1;
        $self->{date} = $now->add(_period($1) => 1);
        return 1;
    }
    else {
        return;
    }

    $self->{month} //= $month{lc substr $self->{month_name}, 0, 3};

    if (defined (my $year = $self->{year})) {
        if (length $year <= 2) {
            $self->{year4} = $year + ($year < 70 ? 2000 : 1900);
        }
        else {
            $self->{year4} = $year;
        }
    }
    else {
        my $now_day = $now->day;
        my $now_month = $now->month;
        $self->{year4} = $now->year;
        $self->{year4}++ if ( ($now_month > $self->{month}) or
                              ( ($now_month == $self->{month}) and
                                ($now_day > $self->{day}) ) );
    }

    $self->{date} = DateTime->new(year => $self->{year4},
                                  month => $self->{month},
                                  day => $self->{day},
                                  hour => $now->hour,
                                  minute => $now->minute,
                                  time_zone => $now->time_zone);

    return 1;


}

sub _parse_time {
    my $self = shift;

    if (/\G(\d\d)(\d\d)\b/gc) {
        # hr24clock_hr_min (hhmm)
        @{$self}{qw(hour min)} = ($1, $2);
    }
    elsif (/\G(([012]?[0-9])(?:[:'h,.](\d\d))?(?:\s*([ap]m))?\b)/gci) {
        # time_hour am_pm
        # time_hour_min
	# time_hour_min am_pm
        @{$self}{qw(hour min am_pm)} = ($2, ($3 // 0), $4);

        if (defined $4) {
            my $hour = $2;
            if ($hour > 11) {
                $hour > 12 and return;
                $hour = 0;
            }
            $hour += 12 if lc($4) eq 'pm';
            $self->{hour} = $hour;
        }
    }
    elsif (/\Gnoon\b/gc) {
        @{$self}{qw(hour min noon)} = (12, 0, 1);
    }
    elsif (/\Gmidnight\b/gc) {
        @{$self}{qw(hour min midnight)} = (0, 0, 1);
    }
    elsif (/\Gteatime\b/gc) {
        @{$self}{qw(hour min teatime)} = (16, 0, 1);
    }
    else {
        return
    }

    if (/\G\s*(utc)\b/gci) {
        $self->{tz} = uc $1;
        $self->{now}->set_time_zone($self->{tz});
    }

    return 1;
}

sub _parse_inc_or_dec {
    my $self = shift;

    if (/\G([+-])\s*(\d+)\s*($period_re)s?\b/gci) {
        @{$self}{qw(increment increment_period)} = ("$1$2", $3);
        my $method = ($1 eq '+' ? 'add' : 'subtract');
        $self->{date} = $self->{date}->$method(_period($3) => $2);

        return 1;
    }
    return;
}

1;
__END__

=head1 NAME

DateTime::Format::GnuAt - Parse time specifications as Debian 'at' command.

=head1 SYNOPSIS

  use DateTime::Format::GnuAt;

  $parser = DateTime::Format::GnuAt->new;
  $dt = $parser->parse_datetime("today");
  $dt = $parser->parse_datetime("next week + 3 days");


=head1 DESCRIPTION

This module implements the same parser rules as Debian 'at' command
(which is also the 'at' used by most non Debian based Linux
distributions).

From the C<at> manual page:

=over

C<at> allows fairly complex time specifications, extending the POSIX.2
standard.  It accepts times of the form C<HH:MM> to run a job at a
specific time of day. (If that time is already past, the next day is
assumed.) You may also specify C<minight>, C<noon>, or C<teatime>
(4pm) and you can have a time-of-day suffixed with C<AM> or C<PM> for
running in the morning or the evening.  You can also say what day the
job will be run, by giving a date in the form C<month-name day> with
an optional C<year>, or giving a date of the form C<MMDD[CC]YY>,
C<MM/DD/[CC]YY>, C<DD.MM.[CC]YY> or C<[CC]YY-MM-DD>. The specification
of a date must follow the specification of the time of day. You can
also give times like C<now + count time-units>, where the time-units
can be C<minutes>, C<hours>, C<days>, or C<weeks> and you can tell at
to run the job today by suffixing the time with C<today> and to run
the job tomorrow by suffixing the time with C<tomorrow>.

For example, to run a job at 4pm three days from now, you would do
C<at 4pm + 3 days>, to run a job at 10:00am on July 31, you would do
C<at 10am Jul 31> and to run a job at 1am tomorrow, you would do C<at
1am tomorrow>.

The definition of the time specification can be found in
C</usr/share/doc/at/timespec>.

=back

=head2 API

The module provides the following methods:

=over 4

=item my $p = DateTime::Format::GnuAt->new;

Returns a new date-time parser object.

=item my $datetime = $p->parse_datetime($string)

=item my $datetime = $p->parse_datetime($string, %opts)

Parses the given string and returns a DateTime object. On failure it
croaks.

The following options can also be passed to the method as a list of
C<$key => $value> pairs after the date-time specification:

=over 4

=item now => $datetime

A DateTime object to be used as the current "now".

This allows to parse the date-time specifications relative to a custom
date.

It can also be used to set the default time-zone (by default C<local>
is used).

=back

=back

=head1 SEE ALSO

L<DateTime>.

=head1 AUTHOR

Salvador FandiE<ntilde>o, E<lt>sfandino@yahoo.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Qindel FormaciE<oacute>n y Servicios, S.L.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.14.2 or,
at your option, any later version of Perl 5 you may have available.

The Perl code in this module has been written from scratch, though the
source code of the Debian C<at> command was used for inspiration and
to determine undocumented behavior.

And excerpt from the L<at(1)> man page has also been copied here.

The test suite is an adaptation of the C<parsetime.pl> script also
distributed in the C<at> package.

The C<reference> directory contains the original C files and their
copyright conditions.

=cut
