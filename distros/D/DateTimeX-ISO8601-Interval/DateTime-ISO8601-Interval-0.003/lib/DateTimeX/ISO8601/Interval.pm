package DateTimeX::ISO8601::Interval;
BEGIN {
  $DateTimeX::ISO8601::Interval::AUTHORITY = 'cpan:BPHILLIPS';
}
$DateTimeX::ISO8601::Interval::VERSION = '0.003';
# ABSTRACT: Provides a means of parsing and manipulating ISO-8601 intervals and durations.

use strict;
use warnings;
use DateTime::Format::ISO8601;
use DateTime::Duration;
use Params::Validate qw(:all);
use Carp qw(croak);
use overload (
	'""' => sub { shift->format }
);

my $REPEAT    = qr{R(\d*)};
my $UNIT      = qr{(?:\d+)};
my $DURATION  = qr[
		P
		(?:
			(?:(${UNIT})Y)?
			(?:(${UNIT})M)?
			(?:(${UNIT})W)?
			(?:(${UNIT})D)?
		)
		(?:
			T
			(?:(${UNIT})H)?
			(?:(${UNIT})M)?
			(?:(${UNIT})S)?
		)?
	]x;

sub _determine_precision {
	my($date, $duration) = @_;
	return $date =~ m{T} ? 'time' : ($duration && !$duration->clock_duration->is_zero ? 'time' : 'date');
}


sub parse {
	my $class    = shift;
	my $interval = shift;
	my %args     = @_;

	my $input = $interval or croak "Nothing found to parse";

	if($interval =~ s{^R(\d*)/}{}){
		$args{repeat} = $1 ne '' ? $1 : -1;
	}
	my $parser = DateTime::Format::ISO8601->new;
	if($interval =~ s{^$DURATION/}{}){
		$args{duration} = _duration_from_matches([$1,$2,$3,$4,$5,$6,$7], %args);
		$args{precision} = _determine_precision($interval, $args{duration});
		$args{end} = $parser->parse_datetime($interval);
	} elsif($interval =~ s{/$DURATION$}{}){
		$args{duration} = _duration_from_matches([$1,$2,$3,$4,$5,$6,$7], %args);
		$args{precision} = _determine_precision($interval, $args{duration});
		$args{start} = $parser->parse_datetime($interval);
	} elsif($interval =~ m{^$DURATION$}){
		$args{duration} = _duration_from_matches([$1,$2,$3,$4,$5,$6,$7], %args);
	} elsif($interval =~ m{^(.+?)(?:--|/)(.+?)$}){
		$args{start} = $parser->parse_datetime($1);
		$parser->set_base_datetime(object => $args{start});
		my $end = substr($1,0,length($2) * -1) . $2;
		$args{precision} = _determine_precision($end);
		$args{end}   = $parser->parse_datetime($end);
	}
	if(!$args{start} && !$args{end} && !$args{duration}){
		croak "Invalid interval: $input";
	}
	if($args{time_zone}){
		if(DateTime::TimeZone->is_valid_name($args{time_zone})){
			for my $d (grep { defined } @args{'start','end'}) {
				$d->set_time_zone($args{time_zone})
			}
		} else {
			croak "Invalid time_zone: $args{time_zone}";
		}
	}
	delete @args{grep { !defined $args{$_} } keys %args};
	return $class->new(%args);
}

sub _duration_from_matches {
	my $matches = shift;
	my %args    = @_;
	my @positions = qw(years months weeks days hours minutes seconds);
	my %params;
	for my $i(0..$#positions) {
		$params{$positions[$i]} = $matches->[$i] if $matches->[$i];
	}
	return DateTime::Duration->new(%params, end_of_month => $args{end_of_month} || 'limit');
}


sub new {
	my $class = shift;
	my %args = validate(
		@_,
		{
			precision  => { default  => 'time' },
			start      => { optional => 1, isa => 'DateTime' },
			end        => { optional => 1, isa => 'DateTime' },
			duration   => { optional => 1, isa => 'DateTime::Duration' },
			time_zone  => { optional => 1, type => SCALAR | OBJECT },
			abbreviate => { optional => 1, type => BOOLEAN, default => 0 },
			repeat => {
				optional => 1,
				type     => SCALAR,
				regex    => qr{^(-1|\d+)$},
				default  => 0
			}
		}
	);

	if(!$args{duration} && (!$args{start} || !$args{end})){
		croak "Either a duration or a start or end parameter must be specified";
	}

	if($args{time_zone}){
		if(!ref($args{time_zone})){
			if(DateTime::TimeZone->is_valid_name($args{time_zone})){
				$args{time_zone} = DateTime::TimeZone->new( name => $args{time_zone} );
			} else {
				croak "Invalid time_zone: $args{time_zone}";
			}
		} elsif(!eval { $args{time_zone}->isa('DateTime::TimeZone') }){
			croak "Invalid time_zone: $args{time_zone}";
		}
	}

	return bless \%args, $class;
}


sub start {
	my $self = shift;
	my($input) = validate_pos(@_, { type => SCALAR | OBJECT, optional => 1 });

	if($input && !ref($input)){
		$self->{precision} = _determine_precision($input);
		my $parser = DateTime::Format::ISO8601->new;
		$input = $parser->parse_datetime($input) or croak "invalid start date: $input";
		if($self->{time_zone}){
			$input->set_time_zone($self->{time_zone});
		}
	}

	if($input) {
		$self->{start} = $input;
		delete $self->{duration} if($self->{end});
	}

	return $self->{start} || ($self->{end} ? ($self->{end} - $self->{duration}) : undef);
}


sub end {
	my $self = shift;

	my($input) = validate_pos(@_, { type => SCALAR | OBJECT, optional => 1 });

	if($input){
		if(!ref($input)){
			$self->{precision} = _determine_precision($input);
			my $parser = DateTime::Format::ISO8601->new;
			$input = $parser->parse_datetime($input) or croak "invalid end date: $input";
			if($self->{time_zone}){
				$input->set_time_zone($self->{time_zone});
			}
		} else {
			$self->{precision} = 'time';
		}
	}

	if($input) {
		$self->{end} = $input;
		delete $self->{duration} if($self->{start});
	}

	if(my $end = $self->{end}) {
		$end = $end->clone;
		if($self->{precision} eq 'date') {
			# if only specifying a date in an interval (i.e. 2013-12-01), the date/time equivalent
			# is actually considered the full day (i.e. 2013-12-01T24:00:00)
			$end += DateTime::Duration->new(days => 1); 
		}
		return $end;
	} else {
		return $self->start + $self->duration;
	}
}


sub duration {
	my $self = shift;
	my($duration) = validate_pos(@_, { isa => 'DateTime::Duration', optional => 1 });
	if($duration){
		if($self->{start} && $self->{end}){
			croak "An explicit interval (with both start and end dates defined) can not have its duration changed";
		} else {
			$self->{duration} = $duration;
		}
	}
	return $self->{duration} if $self->{duration};
	my $dur = $self->{end} - $self->start;
	if($self->{precision} eq 'date'){
		$dur += DateTime::Duration->new(days => 1);
	}
	return $dur;
}


sub repeat {
	my $self = shift;

	my($repeat) = validate_pos(@_, { type => SCALAR, regex => qr{^(-1|\d+)$}, optional => 1 });

	if(defined $repeat){
		$self->{repeat} = $_[0];
	}
	return $self->{repeat};
}


sub iterator {
	my $self = shift;
	my %args = @_;

	my $counter = delete($args{skip}) || 0;
	croak "Invalid 'skip' parameter (must be >= 0 if specified)" if $counter < 0;

	my $start = ($self->start || $args{after}) or croak "This interval has no starting point";
	my $duration = $self->duration;

	if(my $after = delete($args{after})){
		croak "Invalid 'after' parameter (must be a finite DateTime object)" unless ( eval { $after->isa('DateTime') && $after->is_finite } );
		$counter++ while($start + ($duration * $counter) < $after);
	}

	my $until = delete($args{until});
	if($until){
		croak "Invalid 'until' paramter (must be a DateTime object)" unless eval { $until->isa('DateTime') };
		undef $until if $until->is_infinite; # ignore an infinite DateTime
	}

	my $repeat = $self->repeat || 1;

	my $class = ref $self;

	return sub {
		my $steps = shift || 1;
		$counter += ($steps - 1);
		return if $repeat >= 0 && $counter >= $repeat;

		my $this = $start + ($duration * $counter++);
		my $next = $start + ($duration * $counter);

		my $next_interval = $class->new( start => $this, end => $next );
		if($until && $next_interval->contains($until)){
			$repeat = 0; # this is the last one...
			$next_interval = undef;
		}
		return $next_interval;
	};
}


sub contains {
	my $self = shift;
	my($date) = validate_pos(@_, { type => SCALAR | OBJECT });
	croak "Unable to determine if this interval contains $date without an explicit start or end date" if !$self->{start} && !$self->{end};

	if(!ref($date)){
		my $parser = DateTime::Format::ISO8601->new;
		$date = $parser->parse_datetime($date);
		if(my $tz = $self->{time_zone}){
			$date->set_time_zone($tz);
		}
	}
	croak "Expecting a DateTime object" unless eval { $date->isa('DateTime') };
	if($self->{time_zone} && $date->time_zone->is_floating){
		$date = $date->clone;
		$date->set_time_zone($self->{time_zone});
	}
	return $self->start <= $date && $self->end > $date;
}


sub abbreviate {
	my $self = shift;
	$self->{abbreviate} = @_ ? $_[0] : 1;
	return $self;
}


sub format {
	my $self = shift;
	my %args = validate(
		@_,
		{
			abbreviate => {
				optional => 1,
				default  => $self->{abbreviate} || 0,
				type     => BOOLEAN
			}
		}
	);

	my @interval;

	if($self->{repeat}){
		if($self->{repeat} > 0){
			push @interval, 'R' . $self->{repeat};
		} else {
			push @interval, 'R';
		}
	}

	my $format = $self->{precision} eq 'date' ? 'yyyy-MM-dd' : 'yyyy-MM-ddTHH:mm:ss';
	my($start, $end) = @{$self}{'start','end'};
	if($self->{precision} ne 'date' && grep {$_ && $_->millisecond > 0} ($start, $end)){
		$format .= '.SSS';
	}
	if(defined $start){
		push @interval, $start->format_cldr($format) . $self->_timezone_offset($start);
	} else {
		push @interval, $self->_duration_stringify;
	}

	if(defined $end){
		my $formatted_end = $end->format_cldr($format) . $self->_timezone_offset($end);
		if($start && $args{abbreviate}) {
			my @parts = split(/(\D+)/, $formatted_end);
			my $same = '';
			foreach my $p(@parts) {
				if($p =~ /^\D+$/){
					$same .= $p;
				} elsif( index($interval[-1], "$same$p") == 0){
					$same .= $p;
				} else {
					last
				}
			}
			$formatted_end = substr($formatted_end, length($same));
		}
		push @interval, $formatted_end;
	} elsif( defined $start ){ # only use duration as "end" if start was defined
		push @interval, $self->_duration_stringify;
	}

	return join '/', @interval;
}


sub set_time_zone {
	my $self = shift;
	my $tz   = shift or croak "no time_zone specified";
	if(!eval { $tz->isa('DateTime::TimeZone') } && DateTime::TimeZone->is_valid_name($tz)){
		$tz = DateTime::TimeZone->new( name => $tz );
	}
	if(!ref($tz)){
		croak "invalid time zone: $tz";
	}

	$self->{time_zone} = $tz;

	foreach my $f(grep { exists $self->{$_} && $self->{$_} } qw(start end)){
		$self->{$f}->set_time_zone($tz);
	}
	return $self;
}

sub _timezone_offset {
	my $self = shift;
	my $date = shift;
	return '' if $self->{precision} eq 'date';
	return '' if $date->time_zone->is_floating;
	return 'Z' if $date->time_zone->is_utc;
	return $date->format_cldr('Z');
}

sub _duration_stringify {
	my $str = '';
	my $self = shift;
	my $d = $self->duration;
	$str .= 'P';
	foreach my $f(qw(years months weeks days)){
		my $number = $d->$f or next;
		my $unit = uc substr($f,0,1);
		$str .= $number . $unit;
	}
	my $has_time = 0;
	foreach my $f(qw(hours minutes seconds)){
		my $number = $d->$f or next;
		my $unit = uc substr($f,0,1);
		$str .= 'T' unless $has_time++;
		$str .= $number . $unit;
	}
	return $str;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DateTimeX::ISO8601::Interval - Provides a means of parsing and manipulating ISO-8601 intervals and durations.

=head1 VERSION

version 0.003

=head1 SYNOPSIS

	my $interval = DateTimeX::ISO8601::Interval->parse("2013-12-01/15");
	$interval->contains('2013-12-07'); # true
	$interval->contains('2013-12-16'); # false

	my $repeating_interval = DateTimeX::ISO8601::Interval->parse("R12/2013-12-01/P1M");
	my $iterator = $repeating_interval->iterator;
	while(my $month_interval = $iterator->()){
		# $month_interval is jan, feb, mar, ..., dec
	}

=head1 DESCRIPTION

This module provides parsing and iteration functionality for C<ISO 8601>
date/time intervals. The C<ISO 8601> standard provides a succinct way of
representing an interval of time (including the option for the interval
to repeate).

According to Wikipedia, there are four ways to represent an interval:

=over 4

=item

Start and end, such as "2007-03-01T13:00:00Z/2008-05-11T15:30:00Z"

=item

Start and duration, such as "2007-03-01T13:00:00Z/P1Y2M10DT2H30M"

=item

Duration and end, such as "P1Y2M10DT2H30M/2008-05-11T15:30:00Z"

=item

Duration only, such as "P1Y2M10DT2H30M", with additional context information

=back

=head1 METHODS

=head2 parse

This class method will parse the first argument provided as an C<ISO 8601> formatted
date/time interval.  All remaining arguments will be passed through to C</new>. Example
intervals are show above in the L</SYNOPSIS> and L</DESCRIPTION>.

=head2 new

The constructor takes a number of arguments and can be used instead of L</parse> to create
a DateTimeX::ISO8601::Interval object.  Those arguments are:

=over 4

=item * start - L<DateTime> object, must be specified if C<duration> is not specified

=item * end - L<DateTime> object, must be specified if C<duration> is not specified

=item * duration - L<DateTime::Duration> object, must be specified if either C<start> or C<end> is missing

=item * time_zone - string or L<DateTime::TimeZone> object, will be set on underlying L<DateTime>
objects if L</start> or L</end> values must be parsed.

=item * abbreviate - boolean, enable (or disable) abbreviation.  Defaults to C<0>

=item * repeat - integer, specify the number of times this interval should
be repeated. A value of C<-1> indicates an unbounded nubmer of
repeats. Defaults to C<0>.

=back

=head2 start

Returns a L<DateTime> object representing the beginning of this
interval. B<Note:> if the interval doesn't include a time component,
the start time will actually be C<00:00:00.000> of the following day
(since the interval covers the entire day). Intervals B<include> the
C<start> value (in contrast to the C<end> value).

This interval can be changed by providing a new L<DateTime> object as
an argument to this method. If this interval has an explicit L</"end">
date specified, any existing relative L</"duration"> will be cleared.

=head2 end

Returns a L<DateTime> object representing the end of this interval. This
value is B<exclusive> meaning that the interval ends at exactly this time
and does not include this point in time. For instance, an interval that
is one hour long might begin at C<09:38:43> and end at C<10:38:43>. The
C<10:38:43> instant is not a part of this interval. Stated another way,
C<$interval-E<gt>contains($interval-E<gt>end)> always returns false.

This interval can be changed by providing a new L<DateTime> object as
an argument to this method. If this interval has an explicit L</"start">
date specified, any existing relative L</"duration"> will be cleared.

B<Note:> if the interval doesn't include a time component, the end
time will actually be C<00:00:00.000> of the following day (since the
interval covers the entire day). If L<DateTime> supported a time of day
like C<24:00:00.000> that would be used instead.

=head2 duration

Returns a L<DateTime::Duration> object representing this interval.

=head2 repeat

Returns the number of times this interval should repeat. This value
can be changed by providing a new value.  A C<repeat> value of C<0>
means that the interval is not repeated. A C<repeat> value of C<-1>
means that the interval should be repeated indefinitely.

=head2 iterator

Provides an iterator (as a code ref) that returns new
L<DateTimeX::ISO8601::Interval> objects for each repitition as defined
by this interval object. Once all the intervals have been returned, the
iterator will return C<undef> for each subsequent call.

A few arguments may be specified to modify the behavior of the iterator:

=over 4

=item * skip - specify the number of intervals to skip for the first
call to the iterator

=item * after - skip all intervals that are before this L<DateTime>
object if this L<DateTimeX::ISO8601::Interval> is defined only by a
duration (having neither an explicit start or end date) this parameter
will be used as the start date.

=item * until - specify a specific L<DateTime> to stop returning new
intervals.  Similar to L</end>, this attribute is B<exclusive>.  That is,
once the iterator reaches a point where the interval being returned
L</contains> this value, an C<undef> is returned and the iterator stops
returning new intervals.

=back

The iterator returned optionally accepts a single argument that can be used to indicate the
number of iterations to skip on that call.  For instance:

	my $monthly = DateTimeX::ISO8601::Interval->parse('R12/2013-01-01/P1M');
	my $iterator = $monthly->iterator;
	while(my $month = $iterator->(2)) {
		# $month would be Feb, Apr, Jun, etc
	}

=head2 contains

Returns a boolean indicating whether the provided date (either an C<ISO
8601> formatted string or a L<DateTime> object) is between the L</"start">
or L</"end"> dates as defined by this interval.

=head2 abbreviate

Enables abbreviated formatting where duplicate portions of the interval
are eliminated in the second half of the formatted string. To disable,
call C<$interval->abbreviate(0)>.  See the L</format> method for more information

=head2 format

Returns the string representation of this object.  You may optionally
specify C<abbreviate =E<gt> 1> to abbreviate the interval if possible.  For
instance, C<2013-12-01/2013-12-10> can be abbreviated to C<2013-12-01/10>.
If the interval does not appear to be eligible for abbreviation, it will be
returned in its full form.

=head2 set_time_zone

Sets the time_zone on the underlying L<DateTime> objects contained in
this interval (see L<DateTime/set_time_zone>). Also stores the time zone
in C<$self> for future use by L</contains>.

=head1 CAVEATS

=head3 Partial dates and date/times

The C<ISO 8601> spec is very complex.  This module relies on
L<DateTime::Format::ISO8601> for parsing the necessary date strings and
should work well in most cases but some specific aspects of C<ISO 8601>
are not well supported, specifically as it relates to partial
representations of dates.

For example, C<2013-01/12> should last from January through December
of 2013.  This is parsed correctly but since L<DateTime> defaults
un-specified portions of a date to the first valid value, the
actual interval ends up being from 2013-01-01 through 2013-12-01.
Similarly, C<2013/2014> should last from the beginning of the year
2013 through the entire year of 2014. The interval is actually parsed
as C<2013-01-01/2014-01-01>.

Because of the above, it is recommended that you only use full date
and date/time representations with this module (i.e. C<yyyy-MM-dd>
or C<yyyy-MM-ddTHH:mm::ss>).

=head3 Representing dates with L<DateTime> objects

The L<DateTime> set of modules is very robust and a great way of
handling date/times in Perl. However, one of the ambiguities is
that there is no way of representing a date without an explicit time
as well. This is significant when parsing an interval that specifies
only dates. For instance: C<2013-12-01/2013-12-07> should represent an
interval lasting from C<2013-12-01> through the end of C<2013-12-07>.
To accomplish this, the end date is adjusted by one day such that
C<$interval-E<gt>end> returns the L<DateTime> object that represents the
time the interval ends: C<2013-12-08T00:00:00>

=head3 Decimal representation of durations

The C<ISO 8601> standard allows for durations to be specified using
decimal notation (i.e. P0.5Y == P6M).  While this works somewhat using
L<DateTime::Duration> it's not robust enough to provide any support for
this portion of the standard.

=head3 Round-tripping intervals

The C<ISO 8601> standard allows for intervals to be abbreviated such that
C<2013-12-01/05> is equivalent to C<2013-12-01/2013-12-05>.  Abbreviated
intervals should be parsed correctly but by default, when string-ified,
they are output in their expanded form. If you would like an abbreviated
form (if any abbreviation is determined to be possibile) you can use
the L</abbreviate> method. Even so, the abbreviated form is not
guaranteed to be identical to what was provided on input.

=head1 AUTHOR

Brian Phillips <bphillips@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Brian Phillips and Shutterstock, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
