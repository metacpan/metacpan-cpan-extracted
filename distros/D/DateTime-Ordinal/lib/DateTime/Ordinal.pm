package DateTime::Ordinal;

use 5.006;
use strict;
use warnings;

use base 'DateTime';

our $VERSION = '0.01';

our %strftime_patterns;
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
			return $_[1] ? _cardinal($y) : $y;
		},
		'd' => sub { $_[1] ? $_[0]->day_of_month($_[1]) : sprintf( '%02d', $_[0]->day_of_month ) },
		'D' => sub { $_[0]->strftime('%m/%d/%y') },
		'e' => sub { $_[1] ? $_[0]->day_of_month($_[1]) : sprintf( '%2d', $_[0]->day_of_month ) },
		'F' => sub { $_[0]->strftime('%Y-%m-%d') },
		'g' => sub {
			my $w = substr( $_[0]->week_year, -2 );
			return $_[1] ? _cardinal($w) : $w;
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
}

sub quarter_0 { _sub('quarter_0', $_[0], $_[1], 4); }

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

sub _sub {
	my ($orig, $self, $ordinal, $default) = @_;
	$orig = "SUPER::$orig";
	my $val = $self->$orig || $default || 0;
	return $ordinal && $val ? _ordinal($val) : $val;
}

sub _ordinal {
	return $_[1] ? '' : $_[0] . [qw/th st nd rd/]->[$_[0] =~ m{(?<!1)([123])$} ? $1 : 0];
}

1; # End of DateTime::Ordinal

__END__

=head1 NAME

DateTime::Ordinal - The great new DateTime::Ordinal!

=head1 VERSION

Version 0.01

=cut

=head1 SYNOPSIS

Quick summary of what the module does.

	use DateTime::Ordinal;

	my $dt = DateTime::Ordinal->new(
		year       => 3000,
		month      => 4,
		day        => 1,
		hour       => 2,
		minute     => 3,
		second     => 4,
	);

	$dt->day	# 1
	$dt->day(1)	# 1st

	$dt->hour	# 2
	$dt->hour(1)	# 2nd

	$dt->minute	# 3
	$dt->minute(1)	# 3rd

	$dt->second	# 4
	$dt->second(1) 	# 4th

	$dt->strftime("It's the %M(o) minute of the %H(o) hour on the %j(o) day into the %m(0) month within the %Y(o) year");
	# "It's the 3rd minute of the 2nd hour on the 1st day into the 4th month within the 3000th year");

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

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/DateTime-Ordinal>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/DateTime-Ordinal>

=item * Search CPAN

L<https://metacpan.org/release/DateTime-Ordinal>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2019 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

