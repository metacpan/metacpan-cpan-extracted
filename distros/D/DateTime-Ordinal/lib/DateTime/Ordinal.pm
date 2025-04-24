package DateTime::Ordinal;

use 5.006;
use strict;
use warnings;

use parent 'DateTime';
use POSIX qw( floor );
our $VERSION = '0.07';

our (%strftime_patterns, %sub_format, @ORDINALS, @NTT);
BEGIN {
	for my $sub (qw/
		month
		mon
		month_0
		mon_0
		day_of_month
		day
		mday
 		weekday_of_month
 		quarter
		day_of_month_0
		day_0
		mday_0
		day_of_week
		wday
		dow
		day_of_week_0
		wday_0
		dow_0
		local_day_of_week
 		day_of_quarter
		doq
		day_of_quarter_0
		doq_0
		day_of_year
		doy
		day_of_year_0
		doy_0
		hour
		hour_1
 		hour_12
		hour_12_0
 		minute
		min
		second
		sec
		nanosecond
 		millisecond
		microsecond
		leap_seconds
		week
		year
		week_year
		week_number
		week_of_month
	/) {
		no strict 'refs';
		*{"${sub}"} = sub {
			_sub($sub, @_);
		};
	}
	%strftime_patterns = (
		'a' => sub { $_[0]->day_abbr },
		'A' => sub { $_[0]->day_name },
		'b' => sub { $_[0]->month_abbr },
		'B' => sub { $_[0]->month_name },
		'c' => sub {
			$_[0]->format_cldr( $_[0]->{locale}->datetime_format_default() );
		},
		'C' => sub {
			my $y = int( $_[0]->year / 100 );
			return $_[1] ? _ordinal($y) : $y;
		},
		'd' => sub { $_[1] ? $_[0]->day_of_month($_[1]) : sprintf( '%02d', $_[0]->day_of_month ) },
		'D' => sub { $_[0]->strftime('%m/%d/%y') },
		'e' => sub { $_[1] ? $_[0]->day_of_month($_[1]) : sprintf( '%2d', $_[0]->day_of_month ) },
		'F' => sub { $_[0]->strftime('%Y-%m-%d') },
		'g' => sub {
			my $w = substr( $_[0]->week_year, -2 );
			return $_[1] ? _ordinal($w) : $w;
		},
		'G' => sub { $_[0]->week_year($_[1]) },
		'H' => sub { $_[1] ? $_[0]->hour($_[1]) : sprintf( '%02d', $_[0]->hour ) },
		'I' => sub { $_[1] ? $_[0]->hour_12($_[1]) :  sprintf( '%02d', $_[0]->hour_12 ) },
		'j' => sub { $_[1] ? $_[0]->day_of_year($_[1]) : sprintf( '%03d', $_[0]->day_of_year ) },
		'k' => sub { $_[1] ? $_[0]->hour($_[1]) : sprintf( '%2d', $_[0]->hour ) },
		'l' => sub { $_[1] ? $_[0]->hour_12($_[1]) :  sprintf( '%2d', $_[0]->hour_12 ) },
		'm' => sub { $_[1] ? $_[0]->month($_[1]) : sprintf( '%02d', $_[0]->month ) },
		'M' => sub { $_[1] ? $_[0]->minute($_[1]) : sprintf( '%02d', $_[0]->minute ) },
		'n' => sub {"\n"},  # should this be OS-sensitive?
		'N' => \&_format_nanosecs,
		'p' => sub { $_[0]->am_or_pm() },
		'P' => sub { lc $_[0]->am_or_pm() },
		'r' => sub { $_[0]->strftime('%I:%M:%S %p') },
		'R' => sub { $_[0]->strftime('%H:%M') },
		's' => sub { $_[0]->epoch },
		'S' => sub { sprintf( '%02d', $_[0]->second ) },
		't' => sub {"\t"},
		'T' => sub { $_[0]->strftime('%H:%M:%S') },
		'u' => sub { $_[0]->day_of_week($_[1]) },
		'U' => sub {
			my $sun = $_[0]->day_of_year - ( $_[0]->day_of_week + 7 ) % 7;
			return sprintf( '%02d', int( ( $sun + 6 ) / 7 ) );
		},
		'V' => sub { sprintf( '%02d', $_[0]->week_number ) },
		'w' => sub {
			my $dow = $_[0]->day_of_week;
			my $w = $dow % 7;
			return $_[1] ? _ordinal($w) : $w;
		},
		'W' => sub {
			my $mon = $_[0]->day_of_year - ( $_[0]->day_of_week + 6 ) % 7;
			return sprintf( '%02d', int( ( $mon + 6 ) / 7 ) );
		},
		'x' => sub {
			$_[0]->format_cldr( $_[0]->{locale}->date_format_default() );
		},
		'X' => sub {
			$_[0]->format_cldr( $_[0]->{locale}->time_format_default() );
		},
		'y' => sub {
			my $y = sprintf( '%02d', substr( $_[0]->year, -2 ) );
			return $_[1] ? _ordinal($y) : $y;
		},
		'Y' => sub { $_[0]->year($_[1]) },
		'z' => sub { DateTime::TimeZone->offset_as_string( $_[0]->offset ) },
		'Z' => sub { $_[0]->{tz}->short_name_for_datetime( $_[0] ) },
		'%' => sub {'%'},
	);
	$strftime_patterns{h} = $strftime_patterns{b};
	@ORDINALS = qw/th st nd rd/;
	@NTT = (
		[
			'',
			['one', 'first'],
			['two', 'second'],
			['three', 'third'],
			['four', 'fourth'],
			['five', 'fifth'],
			['six', 'sixth'],
			['seven', 'seventh'],
			['eight', 'eighth'],
			['nine', 'ninth'],
			['ten', 'tenth'],
			['eleven', 'eleventh'],
			['twelve', 'twelfth'],
			['thirteen', 'thirteenth'],
			['fourteen', 'fourteenth'],
			['fifthteen', 'fifthteenth'],
			['sixteen', 'sixteenth'],
			['seventeen', 'seventeenth'],
			['eighteen', 'eighteenth'],
			['nineteen', 'nineteenth'],
		],
		[
			'',
			'',
			['twenty', 'twentieth'],
			['thirty', 'thirtieth'],
			['forty', 'fortieth'],
			['fifty', 'fiftieth'],
			['sixty', 'sixtieth'],
			['seventy', 'seventieth'],
			['eighty', 'eightieth'],
			['ninety', 'nintieth']
		],
		'hundred',
		'thousand',
		'million',
		'billion',
		'trillion',
		'quadrillion',
		'quintillion',
		'sextillion',
		'septillion',
		'octillion'
	);
	%sub_format = (
		f => sub { _num2text(shift) },
		o => sub { _ordinal(shift) },
		of => sub { _num2text(shift, 1) },
		oe => sub { _ordinal(shift, 1) }
	);
}

sub quarter_0 { _sub('quarter_0', $_[0], $_[1], 4); }

sub import {
	my ($package, %args) = @_;
	set_sub_format($args{sub_format}) if ($args{sub_format});
}

sub set_sub_format { %sub_format = (%sub_format, %{$_[0]}); }

sub strftime {
	my $self = shift;

	# make a copy or caller's scalars get munged
	my @patterns = @_;
	my @r;
	foreach my $p (@patterns) {
		$p =~ s/
			(?:
				%\{(\w+)\}(?:\s*\(([\w\d]+)\))*	  # method name like %{day_name}
				|
				%([%a-zA-Z])(?:\s*\(([\w\d]+)\))*	  # single character specifier like %d
				|
				%(\d+)N		  # special case for %N
			)
			/
			( $1
				? ( $self->can($1) ? $self->$1($2) : "\%{$1}" )
				: $3
					? ( $strftime_patterns{$3} ? $strftime_patterns{$3}->($self, $4) : "\%$2" )
					: $5
						? $strftime_patterns{N}->($self, $5)
						: ''  # this won't happen
			)
		/sgex;
		return $p unless wantarray;
		push @r, $p;
	}

	return @r;
}

sub strptime {
	require DateTime::Format::Strptime;
	DateTime::Ordinal->from_object(object => DateTime::Format::Strptime->new(
		on_error => 'croak',
		pattern => $_[1],
		($_[3] ? %{$_[3]} : ())
	)->parse_datetime($_[2])); 
}

sub _sub {
	my ($orig, $self, $ordinal, $default) = @_;
	$orig = "SUPER::$orig";
	my $val = $self->$orig || $default || 0;
	return $sub_format{$ordinal || ''} && $val ? $sub_format{$ordinal}->($val, $self) : $val;
}

sub _ordinal {
	return ($_[1] ? '' : $_[0]) . $ORDINALS[$_[0] =~ m{(?<!1)([123])$} ? $1 : 0];
}
 
sub _format_nanosecs {
    my $self = shift;
    my $precision = @_ ? shift : 9;
 
    my $divide_by = 10**( 9 - $precision );
 
    return sprintf(
        '%0' . $precision . 'u',
        floor( $self->{rd_nanosecs} / $divide_by )
    );
}

sub _num2text {
	my ($ns, $l, $o, @n2t) = ('', 3, ($_[1] ? -1 : 0), reverse(split('', $_[0])));
	my $hundred = sub {
		my ($string, $ord, @trip) = ('', @_, 0, 0, 0);
		if ($trip[1] > 1) {
			for (0, 1) {
				$string = sprintf(
					"%s%s",
					$NTT[$_][$trip[$_]][$string ? 0 : $ord],
					($string ? '-' . $string : '')
				) if $trip[$_];
			}
		} elsif ($trip[0] || $trip[1]) { $string = $NTT[0][$trip[1] . $trip[0]][$ord]; }
		$string = sprintf(
			"%s %s%s",
			$NTT[0][$trip[2]][0],
			$NTT[2],
			($string ? ' and ' . $string : ($ord != 0 ? 'th' : ''))
		) if $trip[2];
		return $string;
	};
	$ns = $hundred->($o, splice(@n2t, 0, 3));
	while (@n2t) {
		my $h = $hundred->(0, splice(@n2t, 0, 3));
		$ns = sprintf(
			"%s %s%s",
			$h,
			$NTT[$l],
			($ns
				? ($ns =~ m/and/
					? ', '
					: ' and '
				) . $ns
				: ($o == 0
					? ''
					:'th'
				)
			)
		) if $h;
		$l++;
	}
	return $ns;
}

1; # End of DateTime::Ordinal

__END__

=head1 NAME

DateTime::Ordinal - The great new DateTime::Ordinal!

=head1 VERSION

Version 0.07

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

	use DateTime::Ordinal;

	my $dt = DateTime::Ordinal->new(
		year	=> 3000,
		month 	=> 4,
		day	=> 1,
		hour	=> 2,
		minute	=> 3,
		second	=> 4,
	);

	$dt->day		# 1
	$dt->day('o')		# 1st
	$dt->day('f')		# one
	$dt->day('of')		# first

	$dt->hour		# 2
	$dt->hour('o')		# 2nd
	$dt->hour('f')  	# two
	$dt->hour('of') 	# second

	$dt->minute		# 3
	$dt->minute('o')	# 3rd
	$dt->minute('f')	# three
	$dt->minute('of')	# third

	$dt->second		# 4
	$dt->second('o')	# 4th
	$dt->second('f')	# four
	$dt->second('of')	# fourth

	$dt->strftime("It's the %M(of) minute of the %H(o) hour on day %d(f) in the %m(of) month within the year %Y(f)");
	# "It's the third minute of the 2nd hour on day one in the fourth month within the year three thousand");

	...

	use Lingua::ITA::Numbers
	use DateTime::Ordinal (
		sub_format => {
			f => sub {
				my $number = Lingua::ITA::Numbers->new(shift);
				return $number->get_string;
			}
		}
	);

	my $dt = DateTime::Ordinal->new(
		hour	=> 1,
		minute	=> 2,
		second	=> 3,
		locale  => 'it'
	);

	$dt->hour('f')  	# uno
	$dt->minute('f')	# due
	$dt->second('f')	# tre

=head1 SUBROUTINES/METHODS

=cut

=head2 strftime

=cut

=head2 month

=cut

=head2 mon

=cut

=head2 month_0

=cut

=head2 mon_0

=cut

=head2 day_of_month

=cut

=head2 day

=cut

=head2 mday

=cut

=head2 weekday_of_month

=cut

=head2 quarter

=cut

=head2 day_of_month_0

=cut

=head2 day_0

=cut

=head2 mday_0

=cut

=head2 day_of_week

=cut

=head2 wday

=cut

=head2 dow

=cut

=head2 day_of_week_0

=cut

=head2 wday_0

=cut

=head2 dow_0

=cut

=head2 local_day_of_week

=cut

=head2 day_of_quarter

=cut

=head2 doq

=cut

=head2 day_of_quarter_0

=cut

=head2 doq_0

=cut

=head2 day_of_year

=cut

=head2 doy

=cut

=head2 day_of_year_0

=cut

=head2 doy_0

=cut

=head2 hour

=cut

=head2 hour_1

=cut

=head2 hour_12

=cut

=head2 hour_12_0

=cut

=head2 minute

=cut

=head2 min

=cut

=head2 second

=cut

=head2 sec

=cut

=head2 nanosecond

=cut

=head2 millisecond

=cut

=head2 microsecond

=cut

=head2 leap_seconds

=cut

=head2 week

=cut

=head2 year

=cut

=head2 week_year

=cut

=head2 week_number

=cut

=head2 week_of_month

=cut

=head2 strptime

=cut

=head1 AUTHOR

LNATION, C<< <thisusedtobeanemail at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-datetime-ordinal at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=DateTime-Ordinal>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

	perldoc DateTime::Ordinal


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=DateTime-Ordinal>

=item * Search CPAN

L<https://metacpan.org/release/DateTime-Ordinal>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019->2025 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

