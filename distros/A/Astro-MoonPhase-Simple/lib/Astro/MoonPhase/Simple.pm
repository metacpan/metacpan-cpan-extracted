package Astro::MoonPhase::Simple;

use 5.006;
use strict;
use warnings;

use DateTime;
use DateTime::Format::ISO8601;
use DateTime::TimeZone;
use Try::Tiny;
use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;

# the real heavy lifter!!! :
use Astro::MoonPhase;

our $VERSION = '0.01';

use Exporter 'import';
our (@EXPORT, @EXPORT_OK);

BEGIN {
	@EXPORT_OK = ('calculate_moon_phase');
	# nothing exported by default:
	@EXPORT = ('calculate_moon_phase');
} # end BEGIN

# The input is a HASHref consisting of
#   date : the date of when you want to calculate the moon phase, YYYY-MM-DD
#   time : optional time in hh:mm:ss
#   timezone : optional timezone as a TZ identifier e.g. Africa/Abidjan
#   location : optionally deduce timezone from location if above timezone is absent,
#              it is a string with this format: longitude,latitude (e.g. -10.3,3.09191)
#   verbosity: optionally specify a positive integer to increase verbosity, default is zero for no verbose messages (only errors and warnings)
# Returns:
#   a hash with results including 'asString' which contains a string description of the results.
#   or undef on failure
sub	calculate_moon_phase {
	my $params = $_[0];
	my $parent = ( caller(1) )[3] || "N/A";
	my $whoami = ( caller(0) )[3];

	if( ! defined($params) || ref($params) ne 'HASH' ){
		print STDERR "$whoami (via $parent) : parameters in the form of a HASHref are required.";
		return undef
	}
	if( exists($params->{'date'}) && defined($params->{'date'}) ){
		if( $params->{'date'} !~ /^\d{4}\-(0[1-9]|1[012])\-(0[1-9]|[12][0-9]|3[01])$/ ){
			print STDERR "$whoami (via $parent) : parameter 'date' does not parse YYYY-MM-DD : ".$params->{'date'}."\n";
			return undef
		}
	} else {
		print STDERR "$whoami (via $parent) : parameter 'date' was not specified.\n";
		return undef
	}
	if( exists($params->{'time'}) && defined($params->{'time'}) ){
		if( $params->{'time'} !~ /^(?:(?:([01]?\d|2[0-3]):)?([0-5]?\d):)?([0-5]?\d)$/ ){
			print STDERR "$whoami (via $parent) : parameter 'time' does not parse hh:mm:ss : ".$params->{'time'}."\n";
			return undef
		}
	}
	if( exists($params->{'location'}) && defined($params->{'location'}) ){
		if( ref($params->{'location'})ne'HASH' || ! exists($params->{'location'}->{'lon'}) || ! exists($params->{'location'}->{'lat'}) ){
			print STDERR "$whoami (via $parent) : parameter 'location' is not a HASHref or it does not contain the two keys 'lon' and 'lat'.\n";
			return undef
		}
	}

	my $verbosity = exists($params->{'verbosity'}) && defined($params->{'verbosity'}) ? $params->{'verbosity'} : 0;

	my $parsed_results = _parse_event($params);
	if( ! defined $parsed_results ){ print STDERR perl2dump($params)."$whoami (via $parent) : error, call to ".'_parse_event()'." has failed for above parameters.\n"; return undef }
	my $epoch = $parsed_results->{'epoch'};

	print STDOUT _event2str($params) . "\n" if $verbosity > 0;

	my (	$MoonPhase,
		$MoonIllum,
		$MoonAge,
		$MoonDist,
		$MoonAng,
		$SunDist,
		$SunAng
	) = Astro::MoonPhase::phase($epoch);

	my $outstr = "Moon age: $MoonAge days\n";
	$outstr .= "Moon phase: " . sprintf("%.1f", 100.0*$MoonPhase) . " % of cycle (birth-to-death)\n";
	$outstr .= "Moon's illuminated fraction: " . sprintf("%.1f", 100.0*$MoonIllum) . " % of full disc\n";
	$outstr .= "important moon phases around specified date ".$params->{'date'}.":\n";
	my @phases = phasehunt($epoch);
	$outstr .= "  New Moon      = ". scalar(localtime($phases[0])). "\n";
	$outstr .= "  First quarter = ". scalar(localtime($phases[1])). "\n";
	$outstr .= "  Full moon     = ". scalar(localtime($phases[2])). "\n";
	$outstr .= "  Last quarter  = ". scalar(localtime($phases[3])). "\n";
	$outstr .= "  New Moon      = ". scalar(localtime($phases[4])). "\n";

	return {
		'MoonPhase' => $MoonPhase,
		'MoonPhase%' => 100.0*$MoonPhase,
		'MoonIllum' => $MoonIllum,
		'MoonIllum%' => 100.0*$MoonIllum,
		'MoonAge' => $MoonAge,
		'MoonDist' => $MoonDist,
		'MoonAng' => $MoonAng,
		'SunDist' => $SunDist,
		'SunAng' => $SunAng,
		'phases' => {
			'New Moon' => scalar localtime($phases[0]),
			'First quarter' => scalar localtime($phases[1]),
			'Full moon' => scalar localtime($phases[2]),
			'Last quarter' => scalar localtime($phases[3]),
			'Next New Moon' => scalar localtime($phases[4]),
		},
		'asString' => $outstr,
	}
}

sub _event2str {
	my $params = shift;

	if( ! exists $params->{_is_parsed} ){
		return "event has not been parsed, just dumping it:\n".perl2dump($params);
	}
	my $str =
	   "Moon phase on ".$params->{datetime}
	 . " (".$params->{datetime}->epoch." seconds unix-epoch)"
	 . " timezone: ".$params->{datetime}->time_zone->name
	;
	if( exists $params->{location} ){
		if( ref($params->{location}) eq 'HASH' ){
			$str .= " (lat: ".$params->{location}->{lat}.", lon: ".$params->{location}->{lon}.")"
		} else { $str .= "(".$params->{location}.")" }
	}
	return $str
}

sub _parse_event {
	my $_params = shift;

	# we are returning our input plus some more ...
	my $params = { %$_params };

	my $verbosity = exists($params->{'verbosity'}) && defined($params->{'verbosity'}) ? $params->{'verbosity'} : 0;

	if( ! exists $params->{date} ){ die "date field is missing from event." }

	my $datestr = $params->{date};

	my $timestr = "00:00:01";
	if( exists $params->{time} ){
		$timestr = $params->{time};
		print "event2epoch(): setting time to '$timestr' ...\n"
			if $verbosity > 0;
		die "time '$timestr' is not valid, it must be in the form 'hh:mm:ss'."
			unless $timestr =~ /^\d{2}:\d{2}:\d{2}$/;
	} else { $params->{time} = $timestr }

	my $isostr = $datestr . 'T' . $timestr;
	my $dt = DateTime::Format::ISO8601->parse_datetime($isostr);
	die "failed to parse date '$isostr', check date and time fields."
		unless defined $dt;
	$params->{datetime} = $dt;

	my $tzstr = 'UTC';
	if( exists $params->{timezone} ){
		$tzstr = $params->{timezone};
		print "event2epoch(): found a timezone via 'timezone' field as '$tzstr' (that does not mean it is valid) ...\n"
			if $verbosity > 0;
	} elsif( exists $params->{location} ){
		my $loc = $params->{location};
		if( (ref($loc) eq '') && ($loc =~ /^[a-zA-Z]$/) ){
			# we have a location string
			my @alltzs = DateTime::TimeZone->all_names;
			my $tzstr;
			for (@alltzs){ if( $_ =~ /$loc/i  ){ $tzstr = $_; last } }
			die "event's location can not be converted to a timezone, consider specifying the 'timezone' directly or setting 'location' coordinates with: \[lat,lon\]."
				unless $tzstr;
			print "event2epoch(): setting timezone via 'location' name to '$timestr' ...\n"
				if $verbosity > 0;
		} elsif( (ref($loc) eq 'HASH') && (exists $loc->{lat}) && (exists $loc->{lon}) ){
			# we have a [lat,lon] array for location
			require Geo::Location::TimeZone;
			my $gltzobj = Geo::Location::TimeZone->new();
			$tzstr = $gltzobj->lookup(lat => $loc->{lat}, lon => $loc->{lon});
			if( ! $tzstr ){ die "timezone lookup from location coordinates lat:".$loc->{lat}.", lon:".$loc->{lon}." has failed." }
			print "event2epoch(): setting timezone via 'location' coordinates lat:".$loc->{lat}.", lon:".$loc->{lon}." ...\n"
				if $verbosity > 0
		}
	}
	if( $tzstr ){
		print "event2epoch(): deduced timezone to '$tzstr' and setting it ...\n"
			if $verbosity > 0;
		try {
			$dt->set_time_zone($tzstr)
		} catch {
			die "$_\n failed to set the timezone '$tzstr', is it valid?"
		}
	}

	$params->{_is_parsed} = 1;
	$params->{epoch} = $dt->epoch;
	# this is our input hash with added fields, the most important is 'epoch'
	# of the input date/time/timezone
	return $params
}



=pod

=head1 NAME

Astro::MoonPhase::Simple - Calculate the phase of the Moon on a given time without too much blah blah

=head1 VERSION

Version 0.01


=head1 SYNOPSIS

This package provides a single subroutine to calculate the phase of the moon
on a given time. The results are returned as a hash.

The heavy lifting is done by L<Astro::MoonPhase>. All this package does
is to wrap the functionality of L<Astro::MoonPhase> adding some parameter
checking.

    use Astro::MoonPhase::Simple;

    my $res = calculate_moon_phase({
      'date' => '1974-07-14',
      'timezone' => 'Asia/Nicosia',
    });
    print "moon is ".$res->{'MoonPhase%'}."% full\n";
    print "moon is illuminated by ".$res->{'MoonIllum%'}."%\n";

    print $res->{'asString'};

    # alternatively provide a location instead of a timezone
    # to deduce the timezone
    my $res = calculate_moon_phase({
      'date' => '1974-07-14',
      'time' => '04:00',
      'location' => {lat=>49.180000, lon=>-0.370000}
    });

    ...

=head1 EXPORT

=over 2

=item * C<calculate_moon_phase()>

=back

=head1 SUBROUTINES

=head2 calculate_moon_phase

This is the main and only subroutine which is
exported by default. It expects a HASH reference
as its input parameter containing C<date>, in the
form "YYYY-MM-DD", and optionally C<time>, in
the form "hh:mm:ss". The timezone the date is pertaining
to can be specified using key "timezone", in the form
of a TZ identifier, e.g. "Africa/Abidjan". Alternatively,
specify the location, as a HASHref of C<{lon, lat}>,
the moon is observed from and this
will deduce the timezone, albeit not always as accurately
as with specifying a "timezone" explicitly.

On failure it returns C<undef>.
On success it returns a HASHref with keys:

=over 2

=item * C<MoonPhase> : the moon phase (terminator phase angle) as a number between 0 and 1. New Moon (dark) being 0 and Full Moon (bright) being 1.

=item * C<MoonPhase%> : the above as a percentage.

=item * C<MoonIllum> : the illuminated fraction of the moon's disc as a number between 0 and 1. New Moon (dark) being 0 and Full Moon (bright) being 1.

=item * C<MoonIllum%> : the above as a percentage.

=item * C<MoonAge> : the fractional number of days since the Moon's birth (new moon), at specified date.

=item * C<MoonDist> : the distance of the Moon from the centre of the Earth (kilometers).

=item * C<MoonAng> : the angular diameter subtended by the Moon as seen by an observer at the centre of the Earth

=item * C<SunDist> : Moon's distance from the Sun (kilometers).

=item * C<SunAng> : the angular size of Sun (degrees).

=item * C<phases> : a HASHref containing the date and time for the various Moon phases (at specified date). It contains keys C<New Moon, First quarter, Full moon, Last quarter, Next New Moon>

=item * C<asString> : a string representation of the above.

=back

=head1 SCRIPT

The script C<moon-phase-calculator.pl> is provided for doing
the calculations via the command line.

Example usage: C<moon-phase-calculator.pl --date 1974-07-14 --timezone 'Asia/Nicosia'>

=head1 SEE ALSO

This package summarises L<https://perlmonks.org/?node_id=11137299|this post> over at PerlMonks.org

There are some more goodies in that post e.g. PerlMonk Aldebaran does the
same for planets.

I can't iterate enough that this module wraps the functionality of L<Astro::MoonPhase>.
L<Astro::MoonPhase> does all the heavy lifting.

=head1 AUTHOR

Andreas Hadjiprocopis, C<< <bliako at cpan.org> >>

=head1 DEDICATIONS

Marathon Almaz

=head1 BUGS

Please report any bugs or feature requests to C<bug-astro-moonphase-simple at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Astro-MoonPhase-Simple>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Astro::MoonPhase::Simple


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Astro-MoonPhase-Simple>

=item * Search CPAN

L<https://metacpan.org/release/Astro-MoonPhase-Simple>

=back


=head1 ACKNOWLEDGEMENTS

The authors of L<Astro::MoonPhase> takes all the credit.


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Andreas Hadjiprocopis.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Astro::MoonPhase::Simple
