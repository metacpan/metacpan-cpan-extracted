package DateTime::Format::Epoch;

use 5.00503; #qr
use strict;

use vars qw($VERSION);

$VERSION = '0.16';

use DateTime 0.22;
use DateTime::LeapSecond;

use Math::BigInt 'lib' => 'GMP,Pari,FastCalc';
use Params::Validate qw/validate BOOLEAN OBJECT/;

sub _floor {
    my $x  = shift;
    my $ix = int $x;
    if ($ix <= $x) {
        return $ix;
    } else {
        return $ix - 1;
    }
}

my %units_per_second = (
        seconds     => 1,
        milliseconds => 1000,
        microseconds => 1e6,
        nanoseconds => 1e9,
   );

sub new {
	my $class = shift;
    my %p = validate( @_,
                      { epoch => {type  => OBJECT, 
                                  can   => 'utc_rd_values'},
                        unit  => {callbacks =>
                                     {'valid unit' =>
                                      sub { exists $units_per_second{$_[0]}
                                            or $_[0] > 0 }},
                                  default => 'seconds'},
                        type  => {regex => qr/^(?:int|float|bigint)$/,
                                  default => 0},
                        local_epoch => {type => BOOLEAN,
                                        default => 0},
                        dhms  => {type => BOOLEAN,
                                  default => 0},
                        skip_leap_seconds => {type => BOOLEAN,
                                              default => 1},
                        start_at => {default => 0},
                      } );

    $p{epoch} = $p{epoch}->clone if $p{epoch}->can('clone');

    $p{unit} = $units_per_second{$p{unit}} || $p{unit};
    $p{unit} = 1 if $p{dhms};

    if (!$p{type}) {
        $p{type} = ($p{unit} > 1e6 ? 'bigint' : 'int');
    }

    ($p{epoch_rd_days}, $p{epoch_rd_secs}) = $p{epoch}->utc_rd_values;
    $p{epoch_class} = ref $p{epoch};

    if (!$p{skip_leap_seconds}) {
        $p{leap_secs} =
            DateTime::LeapSecond::leap_seconds( $p{epoch_rd_days} );
    }

    my $self = bless \%p, $class;
	return $self;
}

sub format_datetime {
    my ($self, $dt) = @_;

    unless (ref $self) {
        $self = $self->new;
    }

    $dt = $dt->clone->set_time_zone('floating')
        if  $self->{local_epoch} &&
            $self->{epoch}->can('time_zone') &&
            $self->{epoch}->time_zone->is_floating &&
            $dt->can('time_zone') &&
            !$dt->time_zone->is_floating;

    my ($rd_days, $rd_secs) = $dt->utc_rd_values;
    my $delta_days = $rd_days - $self->{epoch_rd_days};
    my $delta_secs = $rd_secs - $self->{epoch_rd_secs};

    my $secs = $delta_days * 86_400 + $delta_secs;

    if (!$self->{skip_leap_seconds}) {
        $secs += DateTime::LeapSecond::leap_seconds( $rd_days )
                 - $self->{leap_secs};
    }

    if ($self->{type} eq 'bigint') {
        if ($secs > 2_147_483_647) {
          $secs = "$secs"; #https://rt.cpan.org/Ticket/Display.html?id=103517
        }
        $secs = Math::BigInt->new($secs);
    }

    $secs *= $self->{unit};

    if ($dt->can('nanosecond')) {
        my $fraction = $dt->nanosecond / 1e9 * $self->{unit};
        if ($self->{type} eq 'float') {
            $secs += $fraction;
        } else {
            $secs += int $fraction;
        }
    }

    $secs += $self->{start_at};

    if ($self->{dhms}) {
        my $mins = int($secs / 60);
        $secs -= $mins * 60;
        my $hours = int($mins / 60);
        $mins -= $hours * 60;
        my $days = int($hours / 24);
        $hours -= $days * 24;

        return $days, $hours, $mins, $secs;
    }

    return $secs;
}

sub parse_datetime {
    my ($self, $str) = @_;

    unless (ref $self) {
        $self = $self->new;
    }

    if ($self->{dhms}) {
        my (undef, $d, $h, $m, $s) = @_;
        $str = (($d * 24 + $h) * 60 + $m) + $s;
    }

    $str -= $self->{start_at};

    my $delta_days = _floor( $str / (86_400 * $self->{unit}) );
    $str -= $delta_days * 86_400 * $self->{unit};

    # $str cannot be negative now, so int() instead of _floor()
    my $delta_secs = int( $str / $self->{unit} );
    $str -= $delta_secs * $self->{unit};

    my $delta_nano = $str / $self->{unit} * 1e9;

    my $rd_days = $self->{epoch_rd_days} + $delta_days;
    my $rd_secs = $self->{epoch_rd_secs} + $delta_secs;

    if (!$self->{skip_leap_seconds}) {
        $rd_secs -= DateTime::LeapSecond::leap_seconds( $rd_days )
                 - $self->{leap_secs};
        if ($rd_secs >= DateTime::LeapSecond::day_length( $rd_days )) {
            $rd_secs -= DateTime::LeapSecond::day_length( $rd_days );
            $rd_days++;
        } elsif ($rd_secs < 0) {
            $rd_days--;
            $rd_secs += DateTime::LeapSecond::day_length( $rd_days );
        }
    } else {
        if ($rd_secs >= 86400) {
            $rd_secs -= 86400;
            $rd_days++;
        }
    }

    $rd_days = $rd_days->numify if UNIVERSAL::isa($rd_days, 'Math::BigInt');
    $rd_secs = $rd_secs->numify if UNIVERSAL::isa($rd_secs, 'Math::BigInt');

    my $temp_dt = bless { rd_days => $rd_days, rd_secs => $rd_secs},
                        'DateTime::Format::Epoch::_DateTime';

    my $dt = $self->{epoch_class}->from_object( object => $temp_dt );

    if (!$self->{local_epoch}) {
        $dt->set_time_zone( 'UTC' ) if $dt->can('set_time_zone');
    }

    return $dt;
}

sub DateTime::Format::Epoch::_DateTime::utc_rd_values {
    my $self = shift;

    return $self->{rd_days}, $self->{rd_secs};
}

1;
__END__

=head1 NAME

DateTime::Format::Epoch - Convert DateTimes to/from epoch seconds

=head1 SYNOPSIS

  use DateTime::Format::Epoch;

  my $dt = DateTime->new( year => 1970, month => 1, day => 1 );
  my $formatter = DateTime::Format::Epoch->new(
                      epoch          => $dt,
                      unit           => 'seconds',
                      type           => 'int',    # or 'float', 'bigint'
                      skip_leap_seconds => 1,
                      start_at       => 0,
                      local_epoch    => undef,
                  );

  my $dt2 = $formatter->parse_datetime( 1051488000 );
   # 2003-04-28T00:00:00

  $formatter->format_datetime($dt2);
   # 1051488000

=head1 DESCRIPTION

This module can convert a DateTime object (or any object that can be
converted to a DateTime object) to the number of seconds since a given
epoch.  It can also do the reverse.

=head1 METHODS

=over 4

=item * new( ... )

Constructor of the formatter/parser object. It can take the following
parameters: "epoch", "unit", "type", "skip_leap_seconds", "start_at",
"local_epoch" and "dhms".

The epoch parameter is the only required parameter. It should be a
DateTime object (or at least, it has to be convertible to a DateTime
object). This datetime is the starting point of the day count, and is
usually numbered 0. If you want to start at a different value, you can
use the start_at parameter.

The unit parameter can be "seconds", "milliseconds, "microseconds" or
"nanoseconds". The default is "seconds". If you need any other unit,
you must specify the number of units per second. If you specify a number
of units per second below 1, the unit will be longer than a second.  In
this way, you can count days: unit => 1/86_400.

The type parameter specifies the type of the return value. It can be
"int" (returns integer value), "float" (returns floating point value),
or "bigint" (returns Math::BigInt value). The default is either "int"
(if the unit is "seconds"), or "bigint" (if the unit is nanoseconds).

The default behaviour of this module is to skip leap seconds. This is
what (most versions of?) UNIX do. If you want to include leap seconds,
set skip_leap_seconds to false.

Some operating systems use an epoch defined in the local timezone of the
computer. If you want to use such an epoch in this module, you have two
options. The first is to submit a DateTime object with the appropriate
timezone. The second option is to set the local_epoch parameter to a
true value. In this case, you should submit an epoch with a floating
timezone. The exact epoch used in C<format_datetime> will then depend on
the timezone of the object you pass to C<format_datetime>.

Most often, the time since an epoch is given in seconds. In some
circumstances however it is expressed as a number of days, hours, minutes
and seconds. This is done by NASA, for the so called Mission Elapsed
Time. For example, 2/03:45:18 MET means it has been 2 days, 3 hours, 45
minutes, and 18 seconds since liftoff. If you set the dhms parameter to
true, format_datetime returns a four element list, containing the number
of days, hours, minutes and seconds, and parse_datetime accepts the same
four element list.

=item * format_datetime($datetime)

Given a DateTime object, this method returns the number of seconds since
the epoch.

=item * parse_datetime($secs)

Given a number of seconds, this method returns the corresponding
DateTime object.

=back

=head1 BUGS

I think there's a problem when you define a count that does not skip
leap seconds, and uses the local timezone. Don't do that.

=head1 SUPPORT

Support for this module is provided via the datetime@perl.org email
list. See http://lists.perl.org/ for more details.

=head1 AUTHOR

Eugene van der Pijll <pijll@gmx.net>

=head1 COPYRIGHT

Copyright (c) 2003-2006 Eugene van der Pijll.  All rights reserved.
This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SEE ALSO

L<DateTime>

datetime@perl.org mailing list

=cut
