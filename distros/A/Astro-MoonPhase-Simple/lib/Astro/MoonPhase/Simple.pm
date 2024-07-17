package Astro::MoonPhase::Simple;

use 5.006;
use strict;
use warnings;

use DateTime;
use DateTime::Format::ISO8601;
use DateTime::TimeZone;
use Data::Roundtrip qw/perl2dump no-unicode-escape-permanently/;
####
# Note that we require conditionally Geo::Location::TimeZone, see below
####

# the real heavy lifter!!! thank you :
use Astro::MoonPhase;

our $VERSION = '0.03';

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
#              it is a nameplace string, e.g. 'Abidjan'
#        OR    it is a HASHref with keys 'lat' and 'lon'
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
	my $verbosity = exists($params->{'verbosity'}) && defined($params->{'verbosity'}) ? $params->{'verbosity'} : 0;

	if( exists($params->{'date'}) && defined($params->{'date'}) ){
		if( $params->{'date'} !~ /^\d{4}\-(0[1-9]|1[012])\-(0[1-9]|[12][0-9]|3[01])$/ ){
			print STDERR "$whoami (via $parent) : parameter 'date' does not parse YYYY-MM-DD : ".$params->{'date'}."\n";
			return undef
		}
		print STDOUT "$whoami (via $parent) : found parameter 'date' : '".$params->{'date'}."'.\n" if $verbosity > 1;
	} else {
		print STDERR "$whoami (via $parent) : parameter 'date' was not specified.\n";
		return undef
	}
	if( exists($params->{'time'}) && defined($params->{'time'}) ){
		if( $params->{'time'} !~ /^(?:(?:([01]?\d|2[0-3]):)?([0-5]?\d):)?([0-5]?\d)$/ ){
			print STDERR "$whoami (via $parent) : parameter 'time' does not parse hh:mm:ss : ".$params->{'time'}."\n";
			return undef
		}
		print STDOUT "$whoami (via $parent) : found parameter 'time' : '".$params->{'time'}."'.\n" if $verbosity > 1;
	}
	if( exists($params->{'location'}) && defined($params->{'location'}) ){
		if( (ref($params->{'location'})eq'' && ($params->{'location'}=~/^[- a-zA-Z]+$/)) ){
			print STDOUT "$whoami (via $parent) : found parameter 'location' (as a nameplace) : '".$params->{'location'}."'\n" if $verbosity > 1;
		} elsif( (ref($params->{'location'})eq'HASH' && exists($params->{'location'}->{'lon'}) && exists($params->{'location'}->{'lat'})) ){
			print STDOUT "$whoami (via $parent) : found parameter 'location' (as coordinates) : '".perl2dump($params->{'location'})."'\n" if $verbosity > 1;
		} else {
			print STDERR "$whoami (via $parent) : parameter 'location' is not a string of a location name (e.g. London) or it is not a HASHref which contains the two keys 'lon' and 'lat' : ".perl2dump(\$params->{'location'})."\n";
			return undef
		}
	}
	if( exists($params->{'localtimezone'}) && defined($params->{'localtimezone'}) ){
		print STDOUT "$whoami (via $parent) : found parameter 'localtimezone' : '".$params->{'localtimezone'}."'.\n" if $verbosity > 1;
	}

	my $parsed_results = _parse_event($params);
	if( ! defined $parsed_results ){ print STDERR perl2dump($params)."$whoami (via $parent) : error, call to ".'_parse_event()'." has failed for above parameters.\n"; return undef }
	my $epoch = $parsed_results->{'localepoch'};

	print STDOUT _event2str($params)."\n$whoami (via $parent) : deduced epoch as '$epoch' for above parameters, now calling Astro::MoonPhase::phase() ...\n"
	 if $verbosity > 0;

	my (	$MoonPhase,
		$MoonIllum,
		$MoonAge,
		$MoonDist,
		$MoonAng,
		$SunDist,
		$SunAng
	) = Astro::MoonPhase::phase($epoch);

	# the phases are unix epoch for each of the below moon phase names
	# we are printing the date via DateTime on that epoch and adjusting for the timezone
	# the user asked or UTC/or-local-see-below if none was specified.
	# localtime() uses locale timezone or envvar TZ
	# the DateTime as came from $parsed_results{'datetime'} knows the used timezone
	# so we will use that same timezone.
	#'New Moon' => scalar localtime($phases[0]), #<<< don't use this
	my @phases = phasehunt($epoch);
	my @phases_names = ('New Moon', 'First quarter', 'Full moon', 'Last quarter', 'Next New Moon');
	my %phases = map { $phases_names[$_] => DateTime->from_epoch(epoch => $phases[$_], time_zone => $parsed_results->{'datetime'}->time_zone())->strftime('%a %b %d %T %Y') } 0..$#phases;

	my $outstr = "Moon age: $MoonAge days\n";
	$outstr .= "Moon phase: " . sprintf("%.1f", 100.0*$MoonPhase) . " % of cycle (birth-to-death)\n";
	$outstr .= "Moon's illuminated fraction: " . sprintf("%.1f", 100.0*$MoonIllum) . " % of full disc\n";
	$outstr .= "important moon phases around specified date ".$params->{'date'}.":\n";

	$outstr .= sprintf("  %-14s= %s\n", $phases_names[$_], $phases{$phases_names[$_]}) for 0..$#phases;

	my %ret = (
		'MoonPhase' => $MoonPhase,
		'MoonPhase%' => 100.0*$MoonPhase,
		'MoonIllum' => $MoonIllum,
		'MoonIllum%' => 100.0*$MoonIllum,
		'MoonAge' => $MoonAge,
		'MoonDist' => $MoonDist,
		'MoonAng' => $MoonAng,
		'SunDist' => $SunDist,
		'SunAng' => $SunAng,
		'phases' => \%phases,
		'asString' => $outstr,
	);

	return \%ret;
}

sub _event2str {
	my $params = shift;

	if( ! exists $params->{datetime} ){
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

# it expects a HASHref of input parameters which contain:
#   date : the date of when you want to calculate the moon phase, YYYY-MM-DD
#   time : optional time in hh:mm:ss
#   localtimezone : optional LOCAL timezone for making the corrections to the UTC-based epoch
#   
#   timezone : optional timezone as a TZ identifier e.g. Africa/Abidjan
#   location : optionally deduce timezone from location if above timezone is absent,
#              it is a nameplace string, e.g. 'Abidjan'
#        OR    it is a HASHref with keys 'lat' and 'lon'
#   verbosity: optionally specify a positive integer to increase verbosity, default is zero for no verbose messages (only errors and warnings)
# On failure it returns undef
# On success it returns the input parameters HASH complemented with
# various calculated things, most useful of which is 'localepoch' (based on timezone and time, date of the input params)
# and also the DateTime object for calculating the above 'localepoch' under key: 'datetime'
sub _parse_event {
	my $_params = shift;

	# we are returning our input plus some more ...
	my $params = { %$_params };

	my $verbosity = exists($params->{'verbosity'}) && defined($params->{'verbosity'}) ? $params->{'verbosity'} : 0;

	if( ! exists $params->{date} ){ print STDERR "_parse_event() : 'date' field is missing from params.\n"; return undef }

	my $datestr = $params->{date};

	my $timestr = "00:00:01";
	if( exists $params->{time} ){
		$timestr = $params->{time};
		print "_parse_event(): setting time to '$timestr' ...\n"
			if $verbosity > 0;
		if( $timestr !~ /^\d{2}:\d{2}:\d{2}$/ ){ print STDERR "_parse_event() : time '$timestr' is not valid, it must be in the form 'hh:mm:ss'.\n"; return undef }
	} else { $params->{time} = $timestr }

	# create the DateTime object but on UTC timezone,
	# then we calculate the epoch (which is always UTC-based)
	# then we add the timezone offset to that epoch
	my $isostr = $datestr . 'T' . $timestr;
	my $dt = eval { DateTime::Format::ISO8601->parse_datetime($isostr) };
	if( ! defined($dt) || $@ ){ print STDERR "_parse_event() : failed to parse date '$isostr', check date and time fields.\n"; return undef }
	$params->{datetime} = $dt;

	# our local timezone:
	$params->{localtimezone} = DateTime::TimeZone->new( name => "local")->name();

	# this is the default timezone if user did not specify one
	# DateTime::TimeZone->new( name => "local")->name();
	# will print the local timezone if you want to set that
	# but if you use local timezone then make sure that in the tests
	# you always specify a location/timezone else some will fail!!!!!!!
	# see https://rt.cpan.org/Ticket/Display.html?id=154400
	# by using UTC, as default we are saying that if no location was specified
	# then the user-specified times are in UTC
	# but if we use that the tests break if test machine's local timezone is different
	$dt->set_time_zone('UTC');
	#$dt->set_time_zone($params->{localtimezone}); # make sure the tests don't break
	#print "_parse_event(): found local timezone to be '".$params->{localtimezone}."' (this can be overriden by user) ...\n"
	#	if $verbosity > 2;

	my $tzstr = undef;
	if( exists $params->{timezone} ){
		$tzstr = $params->{timezone};
		print "_parse_event(): found a timezone via 'timezone' field as '$tzstr' (that does not mean it is valid) ...\n"
			if $verbosity > 0;
	} elsif( exists $params->{location} ){
		my $loc = $params->{location};
		if( (ref($loc) eq '') && ($loc =~ /^[- a-zA-Z]+$/) ){
			# we have a location NAME string (like 'London')
			my @alltzs = grep { m#/${loc}$#i } DateTime::TimeZone->all_names;
			if( scalar(@alltzs) == 0 ){ print STDERR "_parse_event(): error, the timezone of specified nameplace '$loc' can not be deduced from the TZ identifiers. You can specify coordinates of the location or the timezone explicitly.\n"; return undef }
			elsif( scalar(@alltzs) > 1 ){ print STDERR "_parse_event(): warning more than one timezones matched location nameplace '$loc': @alltzs. The first timezone will be used. If this is incorrect please specify the timezone explicitly, via the 'timezone' parameter.\n"; }
			$tzstr = $alltzs[0];
			print STDOUT "_parse_event(): setting timezone via 'location' nameplace to '$tzstr' ...\n"
				if $verbosity > 0;
		} elsif( (ref($loc) eq 'HASH') && (exists $loc->{lat}) && (exists $loc->{lon}) ){
			# we have a [lat,lon] array for location
			require Geo::Location::TimeZone;
			my $gltzobj = Geo::Location::TimeZone->new();
			$tzstr = $gltzobj->lookup(lat => $loc->{lat}, lon => $loc->{lon});
			if( ! $tzstr ){ print STDERR "_parse_event() : timezone lookup from location coordinates lat:".$loc->{lat}.", lon:".$loc->{lon}." has failed.\n"; return undef }
			print STDOUT "_parse_event(): setting timezone via 'location' coordinates lat:".$loc->{lat}.", lon:".$loc->{lon}." ...\n"
				if $verbosity > 0
		}
	}
	my $localepoch = $dt->epoch; # this is UTC-based but the specified date+time has perhaps a timezone ...

	if( defined $tzstr ){
		# the DateTime object now has the specified timezone
		# but its epoch will still be UTC-based (as always) ...
		# our "localepoch" is adjusted though, see below,
		$dt->set_time_zone($tzstr);

		# we have a timezone, find the offset and add it to the epoch
		print "_parse_event(): deduced timezone to '$tzstr' and adjusting epoch to it ...\n"
			if $verbosity > 0;
		my $tzobj = eval { DateTime::TimeZone->new( name => $tzstr ) };
		if( ! defined($tzobj) || $@ ){
			print STDERR "_parse_event(): failed to set the timezone '$tzstr', is it valid? : $@\n";
			return undef;
		}
		my $offset = $tzobj->offset_for_datetime($dt);
		# we should not change the DateTime, just our own 'localepoch' 
		#$dt->add(seconds => $offset);
		$localepoch += $offset;
		print STDOUT "_parse_event(): adjusted epoch for timezone '$tzstr' to $localepoch (offset of $offset).\n"
			if $verbosity > 0;
	}
	print STDOUT "DateTime: $dt\n(timezone: ".$dt->time_zone().")\n_parse_event(): above is the DateTime object for the moon phase calculations, with adjusted timezone.\n"
		if $verbosity > 0;
	$params->{localepoch} = $dt->epoch;
	# this is our input hash with added fields, the most important is 'localepoch'
	# of the input date/time/timezone
	return $params
}



=pod

=head1 NAME

Astro::MoonPhase::Simple - Calculate the phase of the Moon on a given time without too much blah blah

=head1 VERSION

Version 0.03


=head1 SYNOPSIS

This package provides a single subroutine to calculate the phase of the moon
on a given time. The results are returned as a hash.

The heavy lifting is done by L<Astro::MoonPhase>. All this package does
is to wrap the functionality of L<Astro::MoonPhase> adding some parameter
checking.

    use Astro::MoonPhase::Simple;

    my $res = calculate_moon_phase({
      'date' => '1974-07-15',
      'timezone' => 'Asia/Nicosia',
    });
    print "moon is ".$res->{'MoonPhase%'}."% full\n";
    print "moon is illuminated by ".$res->{'MoonIllum%'}."%\n";

    print $res->{'asString'};

    # alternatively provide location coordinates
    # (instead of timezone) to deduce the timezone
    my $res = calculate_moon_phase({
      'date' => '1974-07-15',
      'time' => '04:00',
      'location' => {lat=>49.180000, lon=>-0.370000}
    });

    # alternatively provide a nameplace instead of a timezone
    # to deduce the timezone
    my $res = calculate_moon_phase({
      'date' => '1974-07-15',
      'time' => '04:00',
      'location' => 'Nicosia',
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

Warning: if the caller does not specify a C<timezone> or C<location>
then the specified C<time> will be assumed to be B<UTC time> and not
at the local timezone of the host.

L<Astro::MoonPhase> calculates the moon phase
given an I<epoch>. Which is the number of seconds
since 1970-01-01 B<on a UTC timezone>. This epoch
is corrected to a "I<localepoch>" by adding to it
the specific timezone offset. For example, if you
specified the timezone to be "China/Beijing" and
the local time (at the specified timezone) to be 23:00.
It means UTC time is 15:00. The epoch will be calculated
on UTC time. However, we add C<23:00-15:00=8:00> hours to
that epoch to make it "I<localepoch>" and this is
what we pass on to L<Astro::MoonPhase> to calculate
the moon phase.

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

This package summarises the post and
discussion L<this post|https://perlmonks.org/?node_id=11137299>
over at PerlMonks.org

There are some more goodies in that post e.g. PerlMonk Aldebaran provides
code for tracking the planets and at different altitudes.

I can't iterate enough that this module wraps the
functionality of L<Astro::MoonPhase>.
L<Astro::MoonPhase> does all the heavy lifting.

=head1 CAVEATS

In L<calculate_moon_phase>, if the caller does not specify a C<timezone> or C<location>
then the specified C<time> will be assumed to be B<UTC time> and not
at the local timezone of the host.


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

The authors of L<Astro::MoonPhase> take all the credit.


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by Andreas Hadjiprocopis.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1; # End of Astro::MoonPhase::Simple
